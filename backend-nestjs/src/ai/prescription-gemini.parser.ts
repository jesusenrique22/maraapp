import { Logger } from '@nestjs/common';
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

export async function parsePrescriptionImageWithGemini(
  apiKey: string,
  imageBuffer: Buffer,
  mimeType: string,
): Promise<PrescriptionVisionResult | null> {
  try {
    const base64 = imageBuffer.toString('base64');
    const url = `https://generativelanguage.googleapis.com/v1beta/models/gemini-2.5-flash:generateContent?key=${apiKey}`;

    const response = await fetch(url, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify({
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
      }),
    });

    if (!response.ok) {
      logger.warn(`Gemini vision ${response.status}: ${await response.text()}`);
      return null;
    }

    const data = await response.json();
    const raw = data.candidates?.[0]?.content?.parts?.[0]?.text as string | undefined;
    if (!raw) return null;

    const parsed = JSON.parse(raw) as PrescriptionVisionResult;
    parsed.medications = (parsed.medications ?? []).filter(
      (m) => m.medicationName?.trim().length > 0,
    );
    parsed.confidence = Math.min(1, Math.max(0, Number(parsed.confidence) || 0));

    return parsed;
  } catch (error) {
    logger.error('Error parsing prescription image', error);
    return null;
  }
}
