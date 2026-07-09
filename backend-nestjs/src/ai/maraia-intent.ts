/** Detecta la intención del mensaje para no repetir el mismo playbook. */

import {
  detectSymptomPlaybook,
  detectSymptomPlaybookKey,
  inferSymptomPlaybookKey,
  MARAIA_SYMPTOM_PLAYBOOKS,
} from './maraia-playbooks';

export type MaraiaIntent =
  | 'new_symptom'
  | 'follow_up'
  | 'product_preference'
  | 'add_to_cart'
  | 'greeting'
  | 'vague_symptom'
  | 'off_topic'
  | 'general';

const FOLLOW_UP_PATTERNS = [
  /como deber[ií]a tomar/i,
  /c[oó]mo debo tomar/i,
  /c[oó]mo me tomo/i,
  /c[oó]mo tomar/i,
  /cada cu[aá]nto/i,
  /cu[aá]ntas veces/i,
  /cu[aá]nto debo/i,
  /dosis/i,
  /dosificaci[oó]n/i,
  /instrucciones/i,
  /modo de uso/i,
  /para qu[eé] sirve cada/i,
  /qu[eé] hago/i,
  /\bq+\s*hago\b/i,
  /\by ahora\b/i,
  /\bahora qu[eé]\b/i,
  /qu[eé] sigue/i,
  /siguiente paso/i,
  /expl[ií]came/i,
  /explic[aá]me/i,
  /pero c[oó]mo/i,
  /y el agua/i,
  /y la pastilla/i,
  /y las pastillas/i,
  /cada cosa/i,
  /de esos/i,
  /de esas/i,
  /los que me/i,
  /cu[aá]ndo tomar/i,
  /antes o despu[eé]s/i,
  /en ayunas/i,
  /puedo mezclar/i,
  /me ayudas con eso/i,
  /ok entonces/i,
  /vale entonces/i,
];

const WHAT_TO_DO_PATTERNS = [
  /\bq+\s*hago\b/i,
  /qu[eé] hago/i,
  /y ahora/i,
  /qu[eé] sigue/i,
  /siguiente paso/i,
  /c[oó]mo procedo/i,
  /qu[eé] me recomiendas hacer/i,
];

/** Usuario pide productos/medicamentos explícitamente. */
const PRODUCT_REQUEST_PATTERNS = [
  /qu[eé] puedo tomar/i,
  /qu[eé] me (recomiendas|sugieres|conviene|sirve)/i,
  /qu[eé] (medicamento|pastilla|producto|compro)/i,
  /algo para (el|la|los|las|mi)?/i,
  /tienen algo para/i,
  /qu[eé] hay en (la )?farmacia/i,
  /recomi[eé]ndame algo/i,
  /qu[eé] venden/i,
  /dame algo para/i,
  /necesito algo para/i,
];

const PREFERENCE_PATTERNS = [
  /prefiero/i,
  /quiero el de/i,
  /no quiero el de/i,
  /mejor el/i,
  /en vez de/i,
  /en lugar de/i,
  /\b800\b|\bochocientos\b/i,
  /\b400\b|\bcuatrocientos\b/i,
];

const ADD_CART_PATTERNS = [
  /agr[eé]galo/i,
  /agreg[aá]melo/i,
  /ponlo en el carrito/i,
  /al carrito/i,
  /ll[eé]valo/i,
  /s[ií],?\s*(agr[eé]ga|quiero|dame)/i,
  /mu[eé]strame (los )?productos/i,
  /vuelve a mostrar/i,
  /otra vez los productos/i,
];

/** Temas que Maraia NUNCA debe atender. */
const OFF_TOPIC_PATTERNS = [
  /receta de (torta|pastel|bizcocho|galleta|pan\b|comida|cena|almuerzo|postre)/i,
  /c[oó]mo (hacer|preparar|cocinar) (una )?(torta|pastel|bizcocho|galleta|comida)/i,
  /ingredientes para/i,
  /\btorta\b|\bpastel\b|\bbizcocho\b/i,
  /\bcocina\b|\bcocinar\b|\bhorno\b/i,
  /\bf[uú]tbol\b|\bbeisbol\b|\bbeisbol\b|\bdeportes\b/i,
  /\bchiste\b|\bmeme\b|\bpol[ií]tica\b/i,
  /\bclima\b|\btiempo\b.*\b(lluvia|sol)\b/i,
  /\bprogramar\b|\bc[oó]digo\b|\bpython\b|\bjavascript\b/i,
  /\btarea\b|\bmatem[aá]tica\b|\bhistoria de\b/i,
  /\bpel[ií]cula\b|\bserie\b|\bm[uú]sica\b|\bvideojuego/i,
  /\bcuenta un chiste/i,
  /traduce|traducir|ingl[eé]s|franc[eé]s/i,
];

const HEALTH_TOPIC_PATTERNS = [
  /\bfiebre\b|\bcalentura\b|\btemperatura\b/i,
  /dolor|duele|molestia|malestar|s[ií]ntoma/i,
  /medic|farmaci|pastilla|tableta|c[aá]psula|jarabe/i,
  /resfriado|gripe|tos|congesti[oó]n|alergia|acidez|agrura|oido|o[ií]do/i,
  /ibuprofeno|acetaminof[eé]n|paracetamol|omeprazol|loratadina/i,
  /salud|enferm|consulta m[eé]dica|doctor|m[eé]dico/i,
  /hidrat|deshidrat|vitamina|antibi[oó]tico/i,
  /embaraz|embarazo|n[aá]usea|v[oó]mito|diarrea/i,
  /maraplus|carrito|producto/i,
];

export function isFollowUpQuestion(message: string): boolean {
  return FOLLOW_UP_PATTERNS.some((p) => p.test(message));
}

export function isWhatToDoQuestion(message: string): boolean {
  return WHAT_TO_DO_PATTERNS.some((p) => p.test(message));
}

export function isProductPreference(message: string): boolean {
  return PREFERENCE_PATTERNS.some((p) => p.test(message));
}

export function isProductRequest(message: string): boolean {
  return PRODUCT_REQUEST_PATTERNS.some((p) => p.test(message));
}

export function isAddToCartIntent(message: string): boolean {
  return ADD_CART_PATTERNS.some((p) => p.test(message));
}

export function isOffTopicRequest(
  message: string,
  conversationContext: string,
): boolean {
  const combined = `${message} ${conversationContext}`;

  // "receta médica" / receta de medicamento sí es válido
  if (/receta m[eé]dica|receta del m[eé]dico|necesito receta/i.test(message)) {
    return false;
  }

  if (OFF_TOPIC_PATTERNS.some((p) => p.test(message))) {
    return true;
  }

  // Torta/pastel sin contexto de salud
  if (
    /\b(torta|pastel|bizcocho)\b/i.test(message) &&
    !HEALTH_TOPIC_PATTERNS.some((p) => p.test(combined))
  ) {
    return true;
  }

  return false;
}

export function isHealthRelatedMessage(
  message: string,
  conversationContext: string,
): boolean {
  const combined = `${message} ${conversationContext}`;
  if (detectSymptomPlaybook(message, message)) return true;
  if (detectSymptomPlaybook('', conversationContext)) return true;
  return HEALTH_TOPIC_PATTERNS.some((p) => p.test(combined));
}

export function historyAlreadyRecommendedProducts(
  history: { role: string; text: string }[],
): boolean {
  return history.some(
    (h) =>
      h.role === 'model' &&
      (/\[AGREGAR_CARRITO:/.test(h.text) ||
        /En MaraPlus tenemos disponible/i.test(h.text) ||
        /Revis[eé] nuestro cat[aá]logo/i.test(h.text)),
  );
}

export function getPreviousSymptomKey(
  history: { role: string; text: string }[],
): string | null {
  const userMessages = history.filter((h) => h.role === 'user').map((h) => h.text);
  for (let i = userMessages.length - 1; i >= 0; i--) {
    const key = inferSymptomPlaybookKey(userMessages[i]);
    if (key) return key;
  }
  return null;
}

export function isTopicChange(
  message: string,
  history: { role: string; text: string }[],
): boolean {
  if (!historyAlreadyRecommendedProducts(history)) return false;
  const currentKey = inferSymptomPlaybookKey(message);
  if (!currentKey) return false;
  const previousKey = getPreviousSymptomKey(history);
  return previousKey != null && previousKey !== currentKey;
}

export function isNewSymptomStatement(message: string): boolean {
  return inferSymptomPlaybookKey(message) != null;
}

export function extractRecommendedProductIds(
  history: { role: string; text: string }[],
): string[] {
  const ids = new Set<string>();
  for (const h of history) {
    if (h.role !== 'model') continue;
    for (const match of h.text.matchAll(/\[AGREGAR_CARRITO:([^\]]+)\]/g)) {
      ids.add(match[1].trim());
    }
  }
  return [...ids];
}

export function detectMaraiaIntent(
  message: string,
  history: { role: string; text: string }[],
  hasSymptomInCurrentMessage: boolean,
  conversationContext?: string,
): MaraiaIntent {
  const msg = message.toLowerCase().trim();
  const ctx =
    conversationContext ??
    [...history.filter((h) => h.role === 'user').map((h) => h.text), message]
      .join(' ')
      .toLowerCase();

  if (/^hola|buenos|buenas|hey|buen d[ií]a/.test(msg)) {
    return 'greeting';
  }

  if (isOffTopicRequest(message, ctx)) {
    return 'off_topic';
  }

  const alreadyRecommended = historyAlreadyRecommendedProducts(history);

  // Cambio de tema: nuevo síntoma → nueva recomendación desde la BDD
  if (isTopicChange(message, history) || (isNewSymptomStatement(message) && alreadyRecommended && !isFollowUpQuestion(message))) {
    return 'new_symptom';
  }

  // Pide productos y ya hay síntoma en el contexto → mostrar catálogo de una vez
  if (
    !alreadyRecommended &&
    isProductRequest(message) &&
    detectSymptomPlaybook('', ctx)
  ) {
    return 'new_symptom';
  }

  if (isFollowUpQuestion(message)) {
    return 'follow_up';
  }

  // Tras mostrar productos, mensajes cortos = seguimiento (si NO es síntoma nuevo)
  if (
    alreadyRecommended &&
    !isNewSymptomStatement(message) &&
    !isAddToCartIntent(message) &&
    !isProductPreference(message) &&
    msg.length <= 40
  ) {
    return 'follow_up';
  }

  if (isAddToCartIntent(message)) {
    return 'add_to_cart';
  }

  if (isProductPreference(message)) {
    return 'product_preference';
  }

  if (
    /me siento mal|me siento muy mal|no me siento bien|estoy mal|me siento enferm/i.test(
      message,
    ) &&
    !hasSymptomInCurrentMessage
  ) {
    return 'vague_symptom';
  }

  if (hasSymptomInCurrentMessage && !alreadyRecommended) {
    return 'new_symptom';
  }

  if (isNewSymptomStatement(message) && alreadyRecommended) {
    return 'new_symptom';
  }

  if (alreadyRecommended && isHealthRelatedMessage(message, ctx) && !isNewSymptomStatement(message)) {
    return 'follow_up';
  }

  if (!isHealthRelatedMessage(message, ctx) && !alreadyRecommended) {
    return 'off_topic';
  }

  return 'general';
}
