import { Logger } from '@nestjs/common';
import {
  buildGeminiGenerateContentUrl,
  getGeminiScanModelCandidates,
  isRetryableGeminiFailure,
  isUnavailableGeminiModel,
  readGeminiApiFailure,
  type GeminiApiFailure,
} from './gemini.config';
import type { PrescriptionVisionResult } from './prescription-scan.types';

const logger = new Logger('PrescriptionGeminiParser');

const EXTRACTION_PROMPT = `Eres un extractor de recetas médicas para una farmacia en Venezuela (MaraPlus).
Analiza la imagen y extrae SOLO medicamentos legibles.

REGLAS:
- Responde en español.
- Si un campo no es legible, usa null.
- medicationName: nombre comercial o genérico tal como aparece.
- activeIngredient: principio activo si aparece (ej. ibuprofeno, paracetamol).
- No inventes medicamentos que no se vean en la imagen.
- confidence: 0.0 a 1.0 según legibilidad general de la receta.`;

const sleep = (ms: number) => new Promise((resolve) => setTimeout(resolve, ms));

function buildVisionRequestBody(base64: string, mimeType: string) {
  return {
    contents: [
      {
        role: 'user',
        parts: [
          { text: EXTRACTION_PROMPT },
          { inlineData: { mimeType, data: base64 } },
        ],
      },
    ],
    generationConfig: {
      temperature: 0.1,
      maxOutputTokens: 2048,
      responseMimeType: 'application/json',
      responseSchema: {
        type: 'OBJECT',
        properties: {
          patientName: { type: 'STRING', nullable: true },
          doctorName: { type: 'STRING', nullable: true },
          prescriptionDate: { type: 'STRING', nullable: true },
          generalNotes: { type: 'STRING', nullable: true },
          confidence: { type: 'NUMBER' },
          medications: {
            type: 'ARRAY',
            items: {
              type: 'OBJECT',
              properties: {
                rawText: { type: 'STRING' },
                medicationName: { type: 'STRING' },
                activeIngredient: { type: 'STRING', nullable: true },
                dosage: { type: 'STRING', nullable: true },
                frequency: { type: 'STRING', nullable: true },
                duration: { type: 'STRING', nullable: true },
                quantity: { type: 'STRING', nullable: true },
              },
              required: ['rawText', 'medicationName'],
            },
          },
        },
        required: ['medications', 'confidence'],
      },
    },
  };
}

async function callGeminiVision(
  apiKey: string,
  model: string,
  base64: string,
  mimeType: string,
): Promise<
  | { ok: true; data: PrescriptionVisionResult }
  | { ok: false; failure: GeminiApiFailure }
> {
  const url = buildGeminiGenerateContentUrl(apiKey, model);
  const response = await fetch(url, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(buildVisionRequestBody(base64, mimeType)),
  });

  if (!response.ok) {
    const failure = await readGeminiApiFailure(response);
    return { ok: false, failure };
  }

  const data = await response.json();
  const raw = data.candidates?.[0]?.content?.parts?.[0]?.text as string | undefined;
  if (!raw) {
    return {
      ok: false,
      failure: { status: 502, message: 'Gemini no devolvió contenido' },
    };
  }

  const parsed = JSON.parse(raw) as PrescriptionVisionResult;
  parsed.medications = (parsed.medications ?? []).filter(
    (m) => m.medicationName?.trim().length > 0,
  );
  parsed.confidence = Math.min(1, Math.max(0, Number(parsed.confidence) || 0));

  return { ok: true, data: parsed };
}

export async function parsePrescriptionImageWithGemini(
  apiKey: string,
  imageBuffer: Buffer,
  mimeType: string,
): Promise<
  | { ok: true; data: PrescriptionVisionResult }
  | { ok: false; failure?: GeminiApiFailure }
> {
  try {
    const base64 = imageBuffer.toString('base64');
    const models = getGeminiScanModelCandidates();
    let lastFailure: GeminiApiFailure | undefined;

    for (const model of models) {
      for (let attempt = 0; attempt < 2; attempt++) {
        if (attempt > 0) await sleep(1200);

        const result = await callGeminiVision(apiKey, model, base64, mimeType);
        if (result.ok) {
          if (model !== models[0]) {
            logger.log(`Escáner OK con modelo respaldo: ${model}`);
          }
          return result;
        }

        lastFailure = result.failure;
        logger.warn(
          `Gemini vision [${model}] intento ${attempt + 1}: ${result.failure.status} ${result.failure.message}`,
        );

        if (isUnavailableGeminiModel(result.failure)) {
          break;
        }

        if (!isRetryableGeminiFailure(result.failure)) {
          return { ok: false, failure: result.failure };
        }
      }
    }

    return { ok: false, failure: lastFailure };
  } catch (error) {
    logger.error('Error parsing prescription image', error);
    return { ok: false };
  }
}
