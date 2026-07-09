import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { InventoryService } from '../inventory/inventory.service';
import { PrismaService } from '../prisma/prisma.service';
import {
  buildMaraiaSystemPrompt,
  sanitizeMaraiaResponse,
} from './maraia-prompt.builder';
import {
  detectMaraiaIntent,
  historyAlreadyRecommendedProducts,
  isOffTopicRequest,
  isTopicChange,
  isWhatToDoQuestion,
} from './maraia-intent';
import {
  buildCareGuidanceResponse,
  buildConversationContext,
  buildDosageGuidanceResponse,
  buildOffTopicResponse,
  buildPlaybookResponse,
  buildPreferenceResponse,
  buildSmartRecommendationResponse,
  buildVagueSymptomsPrompt,
} from './maraia-recommendations';
import {
  detectSymptomPlaybook,
  inferSymptomPlaybookKey,
  MARAIA_SYMPTOM_PLAYBOOKS,
  resolvePlaybookKey,
} from './maraia-playbooks';
import {
  searchFeaturedPharmacyCatalog,
  searchProductsByTerms,
  searchProductsForSymptoms,
} from './maraia-catalog-search';
import {
  analyzeMessageFallback,
  analyzeMessageWithGemini,
  type MaraiaMessageAnalysis,
} from './maraia-symptom-analyzer';
import { buildGeminiGenerateContentUrl } from './gemini.config';

interface ChatMessage {
  role: 'user' | 'model';
  text: string;
}

@Injectable()
export class AiService {
  private readonly logger = new Logger(AiService.name);

  constructor(
    private readonly configService: ConfigService,
    private readonly prisma: PrismaService,
    private readonly inventory: InventoryService,
  ) {}

  private stripActionTags(text: string): string {
    return text
      .replace(/\[AGREGAR_CARRITO:[^\]]+\]/g, '')
      .replace(/\[AGENDAR_CITA:[^\]]+\]/g, '')
      .replace(/\n{3,}/g, '\n\n')
      .trim();
  }

  private async loadDoctors() {
    const doctors = await this.prisma.user.findMany({
      where: { role: 'DOCTOR', isActive: true },
      include: { doctorProfile: true },
    });
    return doctors.map((d) => ({
      id: d.id,
      name: d.name,
      specialty: d.doctorProfile?.specialty ?? 'Medicina General',
    }));
  }

  private wrapCatalog(products: Awaited<ReturnType<typeof searchProductsByTerms>>) {
    return {
      products,
      validProductIds: new Set(products.filter((p) => p.inStock).map((p) => p.id)),
    };
  }

  private async analyzeMessage(
    message: string,
    history: ChatMessage[],
    productsAlreadyShown: boolean,
    conversationContext: string,
  ): Promise<MaraiaMessageAnalysis> {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');
    if (apiKey) {
      const ai = await analyzeMessageWithGemini(apiKey, message, history, productsAlreadyShown);
      if (ai) return ai;
    }

    const playbookKey = resolvePlaybookKey(message, conversationContext);
    const playbook = playbookKey ? MARAIA_SYMPTOM_PLAYBOOKS[playbookKey] : null;
    const legacyIntent = detectMaraiaIntent(
      message,
      history,
      inferSymptomPlaybookKey(message) != null,
      conversationContext,
    );

    return analyzeMessageFallback(
      message,
      history,
      productsAlreadyShown,
      playbook?.searchTerms ?? [],
      legacyIntent,
      isTopicChange(message, history),
    );
  }

  async generateResponse(message: string, history: ChatMessage[]): Promise<string> {
    const conversationContext = buildConversationContext(history, message);
    const alreadyRecommended = historyAlreadyRecommendedProducts(history);

    if (isOffTopicRequest(message, conversationContext)) {
      return buildOffTopicResponse();
    }

    const analysis = await this.analyzeMessage(
      message,
      history,
      alreadyRecommended,
      conversationContext,
    );

    if (analysis.intent === 'off_topic') return buildOffTopicResponse();
    if (analysis.intent === 'greeting') {
      return '¡Hola! Soy **Maraia**, tu asistente de salud en **MaraPlus**. 🩺\n\nCuéntame qué sientes — cualquier síntoma — y busco en nuestro catálogo qué medicamentos te pueden servir.\n\n*Orientación general — no reemplaza consulta médica.*';
    }
    if (analysis.intent === 'vague_symptom') return buildVagueSymptomsPrompt();

    const products = await searchProductsByTerms(
      this.prisma,
      this.inventory,
      analysis.dbSearchTerms,
      { limit: 40, includeHydration: analysis.includeHydration },
    );

    const doctors = await this.loadDoctors();
    const catalog = {
      ...(await this.wrapCatalog(products)),
      doctors,
      validDoctorIds: new Set(doctors.map((d) => d.id)),
    };

    if (
      (analysis.intent === 'recommend_products' || analysis.intent === 'add_to_cart') &&
      analysis.shouldShowProducts
    ) {
      const smart = buildSmartRecommendationResponse(products, {
        careAdvice: analysis.careAdvice,
        symptomSummary: analysis.symptomSummary,
        topicChanged: analysis.isTopicChange && alreadyRecommended,
      });
      if (smart) return smart;

      // Fallback playbook si la búsqueda IA no devolvió stock
      const playbookKey = resolvePlaybookKey(message, conversationContext);
      const playbook = playbookKey ? MARAIA_SYMPTOM_PLAYBOOKS[playbookKey] : null;
      if (playbook) {
        const legacyProducts = await searchProductsForSymptoms(
          this.prisma,
          this.inventory,
          conversationContext,
          { playbookKey, limit: 40 },
        );
        const legacy = buildPlaybookResponse(
          playbook,
          legacyProducts,
          message,
          analysis.isTopicChange,
        );
        if (legacy) return legacy;
      }
    }

    if (analysis.intent === 'follow_up' || (alreadyRecommended && !analysis.shouldShowProducts)) {
      if (isWhatToDoQuestion(message)) {
        const care = buildCareGuidanceResponse(conversationContext, history, message);
        if (care) return care;
      }
      const dosage = buildDosageGuidanceResponse(
        products.length > 0 ? products : catalog.products,
        conversationContext,
        message,
        history,
      );
      if (dosage) return dosage;
      const care = buildCareGuidanceResponse(conversationContext, history, message);
      if (care) return care;
    }

    if (/prefiero|800|400|ochocientos|cuatrocientos/i.test(message)) {
      const pref = buildPreferenceResponse(products, message);
      if (pref) return pref;
    }

    return this.callGemini(message, history, catalog, {
      isFollowUp: analysis.intent === 'follow_up' || alreadyRecommended,
      productsAlreadyShown: alreadyRecommended && !analysis.shouldShowProducts,
      fallback: this.getMockResponse(message, history, products),
    });
  }

  private async callGemini(
    message: string,
    history: ChatMessage[],
    catalog: {
      products: Awaited<ReturnType<typeof searchProductsByTerms>>;
      doctors: Awaited<ReturnType<AiService['loadDoctors']>>;
      validProductIds: Set<string>;
      validDoctorIds: Set<string>;
    },
    options: {
      isFollowUp?: boolean;
      productsAlreadyShown?: boolean;
      fallback: string | Promise<string>;
    },
  ): Promise<string> {
    const apiKey = this.configService.get<string>('GEMINI_API_KEY');

    if (!apiKey) {
      return Promise.resolve(options.fallback);
    }

    try {
      const systemInstructionText = buildMaraiaSystemPrompt(
        catalog.products,
        catalog.doctors,
        message,
        {
          isFollowUp: options.isFollowUp,
          productsAlreadyShown: options.productsAlreadyShown,
        },
      );

      const contents = history.map((item) => ({
        role: item.role === 'model' ? 'model' : 'user',
        parts: [{ text: this.stripActionTags(item.text) }],
      }));

      contents.push({ role: 'user', parts: [{ text: message }] });

      const url = buildGeminiGenerateContentUrl(apiKey);

      const response = await fetch(url, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json' },
        body: JSON.stringify({
          systemInstruction: { parts: [{ text: systemInstructionText }] },
          contents,
          generationConfig: {
            temperature: options.isFollowUp ? 0.4 : 0.3,
            topP: 0.85,
            maxOutputTokens: 900,
          },
        }),
      });

      if (!response.ok) {
        const errorText = await response.text();
        this.logger.error(`Gemini ${response.status}: ${errorText}`);
        return Promise.resolve(options.fallback);
      }

      const data = await response.json();
      const text = data.candidates?.[0]?.content?.parts?.[0]?.text as
        | string
        | undefined;

      if (!text) {
        return Promise.resolve(options.fallback);
      }

      return sanitizeMaraiaResponse(
        text,
        catalog.validProductIds,
        catalog.validDoctorIds,
        { stripProducts: options.productsAlreadyShown },
      );
    } catch (error) {
      this.logger.error('Error Gemini:', error);
      return Promise.resolve(options.fallback);
    }
  }

  private async getMockResponse(
    message: string,
    history: ChatMessage[],
    products: Awaited<ReturnType<typeof searchProductsByTerms>>,
  ): Promise<string> {
    const conversationContext = buildConversationContext(history, message);

    if (isOffTopicRequest(message, conversationContext)) {
      return buildOffTopicResponse();
    }

    const smart = buildSmartRecommendationResponse(products, {
      symptomSummary: message.slice(0, 80),
    });
    if (smart) return smart;

    const playbook = detectSymptomPlaybook(message, message);
    if (playbook) {
      const response = buildPlaybookResponse(playbook, products, message);
      if (response) return response;
    }

    return buildVagueSymptomsPrompt();
  }
}
