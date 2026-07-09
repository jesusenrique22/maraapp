import type { ConfigService } from '@nestjs/config';

const DEFAULT_GEMINI_MODEL = 'gemini-2.0-flash';
const DEFAULT_GEMINI_SCAN_MODEL = 'gemini-3.5-flash';

/** Maraia (chat). Variable: GEMINI_API_KEY */
export function resolveGeminiChatApiKey(
  config: ConfigService,
): string | undefined {
  return config.get<string>('GEMINI_API_KEY')?.trim() || undefined;
}

/** Escáner de recetas. Variable: GEMINI_SCAN_API_KEY (fallback: GEMINI_API_KEY) */
export function resolveGeminiScanApiKey(
  config: ConfigService,
): string | undefined {
  const scanKey = config.get<string>('GEMINI_SCAN_API_KEY')?.trim();
  if (scanKey) return scanKey;
  return resolveGeminiChatApiKey(config);
}

/** Modelo Gemini para Maraia (chat). Override con GEMINI_MODEL */
export function getGeminiModel(): string {
  const configured = process.env.GEMINI_MODEL?.trim();
  return configured && configured.length > 0 ? configured : DEFAULT_GEMINI_MODEL;
}

/** Modelo Gemini para escáner de recetas. Override con GEMINI_SCAN_MODEL */
export function getGeminiScanModel(): string {
  const configured = process.env.GEMINI_SCAN_MODEL?.trim();
  return configured && configured.length > 0
    ? configured
    : DEFAULT_GEMINI_SCAN_MODEL;
}

export function buildGeminiGenerateContentUrl(
  apiKey: string,
  model = getGeminiModel(),
): string {
  return `https://generativelanguage.googleapis.com/v1beta/models/${model}:generateContent?key=${apiKey}`;
}

export type GeminiApiFailure = {
  status: number;
  message: string;
};

export async function readGeminiApiFailure(
  response: Response,
): Promise<GeminiApiFailure> {
  let message = `Gemini respondió ${response.status}`;

  try {
    const body = (await response.json()) as {
      error?: { message?: string; code?: number };
    };
    if (body.error?.message) {
      message = body.error.message;
    }
  } catch {
    // ignore parse errors
  }

  return { status: response.status, message };
}

export function userFacingGeminiError(failure: GeminiApiFailure): string {
  const lower = failure.message.toLowerCase();

  if (failure.status === 429 || lower.includes('quota')) {
    return 'La IA está temporalmente sin cupo. Intenta de nuevo en unos minutos.';
  }

  if (failure.status === 503 || lower.includes('high demand')) {
    return 'La IA está saturada en este momento. Intenta de nuevo en unos segundos.';
  }

  if (
    failure.status === 404 ||
    lower.includes('no longer available') ||
    lower.includes('not found')
  ) {
    return 'El modelo de IA del escáner ya no está disponible. Actualiza GEMINI_SCAN_MODEL en el servidor.';
  }

  if (failure.status === 400 && lower.includes('api key')) {
    return 'GEMINI_SCAN_API_KEY inválida. Revisa la clave del escáner en Google AI Studio.';
  }

  return 'No pudimos analizar la imagen con IA. Intenta de nuevo con una foto más nítida.';
}
