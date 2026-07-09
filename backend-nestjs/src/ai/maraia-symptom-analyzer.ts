import { Logger } from '@nestjs/common';

export type MaraiaAnalysisIntent =
  | 'greeting'
  | 'off_topic'
  | 'recommend_products'
  | 'follow_up'
  | 'vague_symptom'
  | 'add_to_cart';

export type MaraiaMessageAnalysis = {
  intent: MaraiaAnalysisIntent;
  symptomSummary: string | null;
  careAdvice: string | null;
  /** Términos en español para buscar en name/description de la BDD */
  dbSearchTerms: string[];
  includeHydration: boolean;
  shouldShowProducts: boolean;
  isTopicChange: boolean;
};

interface ChatMessage {
  role: 'user' | 'model';
  text: string;
}

const logger = new Logger('MaraiaSymptomAnalyzer');

function buildAnalyzerPrompt(
  message: string,
  history: ChatMessage[],
  productsAlreadyShown: boolean,
): string {
  const historyText = history
    .slice(-6)
    .map((h) => `${h.role === 'user' ? 'Usuario' : 'Maraia'}: ${h.text.slice(0, 400)}`)
    .join('\n');

  return `Eres el módulo de análisis de Maraia (farmacia MaraPlus, Venezuela).
Analiza el ÚLTIMO mensaje del usuario en contexto del chat.

Historial reciente:
${historyText || '(sin historial)'}

Último mensaje: "${message}"
¿Ya se mostraron productos con botón de carrito antes?: ${productsAlreadyShown ? 'sí' : 'no'}

Devuelve JSON con:
- intent:
  - "recommend_products" → síntoma/malestar NUEVO o cambio de tema; hay que buscar medicamentos en la BDD y mostrar productos
  - "follow_up" → pregunta sobre cómo tomar, qué hacer, dosis, etc. del MISMO caso (sin síntoma nuevo)
  - "off_topic" → no es salud (cocina, tareas, deportes, etc.)
  - "greeting" → solo saludo
  - "vague_symptom" → "me siento mal" sin ningún detalle
  - "add_to_cart" → pide agregar al carrito o ver productos otra vez
- symptomSummary: frase corta del malestar actual (null si no aplica)
- careAdvice: 1-2 oraciones de orientación general segura (null si no aplica)
- dbSearchTerms: 4-10 términos en ESPAÑOL para buscar en catálogo farmacéutico (principios activos, clases: paracetamol, ibuprofeno, loratadina, omeprazol, etc.). Infiérelos del síntoma aunque sea raro o poco común.
- includeHydration: true si conviene agua/jugos (fiebre, deshidratación, resfriado)
- shouldShowProducts: true si debe mostrar tarjetas de productos ahora
- isTopicChange: true SOLO si ya se mostraron productos antes Y el síntoma es distinto al del historial

REGLAS:
- NO necesitas casos predefinidos: interpreta cualquier síntoma y elige términos de búsqueda adecuados.
- Si hay síntoma nuevo aunque ya se hayan mostrado productos → recommend_products + isTopicChange true.
- Si pregunta "qué hago" o "cómo tomar" del mismo caso → follow_up, shouldShowProducts false.
- Solo salud y farmacia. Rechaza lo demás con off_topic.`;
}

export async function analyzeMessageWithGemini(
  apiKey: string,
  message: string,
  history: ChatMessage[],
  productsAlreadyShown: boolean,
): Promise<MaraiaMessageAnalysis | null> {
  try {
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
        contents: [{ role: 'user', parts: [{ text: buildAnalyzerPrompt(message, history, productsAlreadyShown) }] }],
        generationConfig: {
          temperature: 0.2,
          maxOutputTokens: 600,
          responseMimeType: 'application/json',
          responseSchema: {
            type: 'OBJECT',
            properties: {
              intent: {
                type: 'STRING',
                enum: [
                  'greeting',
                  'off_topic',
                  'recommend_products',
                  'follow_up',
                  'vague_symptom',
                  'add_to_cart',
                ],
              },
              symptomSummary: { type: 'STRING', nullable: true },
              careAdvice: { type: 'STRING', nullable: true },
              dbSearchTerms: { type: 'ARRAY', items: { type: 'STRING' } },
              includeHydration: { type: 'BOOLEAN' },
              shouldShowProducts: { type: 'BOOLEAN' },
              isTopicChange: { type: 'BOOLEAN' },
            },
            required: [
              'intent',
              'dbSearchTerms',
              'includeHydration',
              'shouldShowProducts',
              'isTopicChange',
            ],
          },
        },
      }),
    });

    if (!response.ok) {
      logger.warn(`Analyzer Gemini ${response.status}: ${await response.text()}`);
      return null;
    }

    const data = await response.json();
    const raw = data.candidates?.[0]?.content?.parts?.[0]?.text as string | undefined;
    if (!raw) return null;

    const parsed = JSON.parse(raw) as MaraiaMessageAnalysis;
    parsed.dbSearchTerms = (parsed.dbSearchTerms ?? [])
      .map((t) => t.trim().toLowerCase())
      .filter(Boolean)
      .slice(0, 10);

    if (parsed.intent === 'recommend_products' && parsed.dbSearchTerms.length === 0) {
      parsed.dbSearchTerms = ['analgesico', 'paracetamol'];
    }

    return parsed;
  } catch (error) {
    logger.warn('Analyzer Gemini error', error);
    return null;
  }
}

/** Fallback sin IA: términos genéricos + playbooks mínimos */
export function analyzeMessageFallback(
  message: string,
  history: ChatMessage[],
  productsAlreadyShown: boolean,
  playbookSearchTerms: string[],
  intent: string,
  topicChanged: boolean,
): MaraiaMessageAnalysis {
  const isFollowUp = intent === 'follow_up';

  return {
    intent: isFollowUp
      ? 'follow_up'
      : intent === 'off_topic'
        ? 'off_topic'
        : intent === 'greeting'
          ? 'greeting'
          : intent === 'vague_symptom'
            ? 'vague_symptom'
            : intent === 'add_to_cart'
              ? 'add_to_cart'
              : 'recommend_products',
    symptomSummary: message.slice(0, 120),
    careAdvice: null,
    dbSearchTerms:
      playbookSearchTerms.length > 0
        ? playbookSearchTerms
        : ['paracetamol', 'ibuprofeno', 'analgesico'],
    includeHydration: /fiebre|sed|deshidrat|gripe|resfriado/i.test(message),
    shouldShowProducts:
      !isFollowUp &&
      (intent === 'new_symptom' ||
        intent === 'add_to_cart' ||
        intent === 'product_preference'),
    isTopicChange: topicChanged,
  };
}
