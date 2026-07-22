import type { MARAIA_SYMPTOM_PLAYBOOKS } from './maraia-playbooks';
import { inferSymptomPlaybookKey } from './maraia-playbooks';

export type MaraiaCatalogProduct = {
  id: string;
  sku: string;
  name: string;
  description: string | null;
  price: number;
  discountPercent: number | null;
  categoryName: string;
  inStock: boolean;
};

const SKU_BENEFIT: Record<string, string> = {
  'FAR-001': 'Ayuda a bajar la fiebre y aliviar molestias generales.',
  'FAR-002': 'Antiinflamatorio dosis estándar de 400mg.',
  'FAR-003': 'Mayor concentración 800mg — más económico por dosis en oferta.',
  'VE-BEB-004': 'Hidratación constante, esencial con fiebre.',
  'VE-BEB-005': 'Agua purificada en presentación personal.',
  'VE-BEB-006': 'Líquidos + vitamina C para recuperarte.',
  'VE-FAR-004': 'Alivia estornudos, rinitis y alergias leves.',
  'VE-FAR-006': 'Antiinflamatorio para dolor e inflamación.',
  'VE-FAR-009': 'Refuerzo de vitamina C para el sistema inmune.',
  'VE-FAR-003': 'Protege el estómago y alivia acidez.',
  'VE-FAR-010': 'Analgésico de acción rápida para dolor moderado.',
};

function finalPrice(p: MaraiaCatalogProduct): number {
  return p.discountPercent ? p.price * (1 - p.discountPercent / 100) : p.price;
}

function cartTag(p: MaraiaCatalogProduct | undefined): string {
  return p?.inStock ? `[AGREGAR_CARRITO:${p.id}]` : '';
}

function findProduct(catalog: MaraiaCatalogProduct[], sku: string) {
  return catalog.find((p) => p.sku === sku && p.inStock);
}

function productBenefit(p: MaraiaCatalogProduct): string {
  if (!p.description) return 'Disponible en nuestra farmacia.';
  const short = p.description
    .replace(/\s+/g, ' ')
    .split('.')
    .slice(0, 2)
    .join('.')
    .trim();
  return short.length > 120 ? `${short.slice(0, 117)}...` : short;
}

export function buildActiveSymptomContext(
  history: { role: string; text: string }[],
  message: string,
): string {
  if (inferSymptomPlaybookKey(message)) {
    return message.toLowerCase();
  }
  const userTexts = history.filter((h) => h.role === 'user').map((h) => h.text);
  return [...userTexts.slice(-1), message].join(' ').toLowerCase();
}

export function buildPlaybookResponse(
  playbook: (typeof MARAIA_SYMPTOM_PLAYBOOKS)[string],
  catalog: MaraiaCatalogProduct[],
  userMessage: string,
  topicChanged = false,
): string | null {
  const msg = userMessage.toLowerCase();
  const prefers800 = /800|ochocientos/.test(msg);
  const prefers400 = /400|cuatrocientos/.test(msg);

  let products = catalog.filter((p) => p.inStock);

  // Preferencia ibuprofeno 400 vs 800 si hay varios en el catálogo buscado
  if (playbook.alternativas?.ibuprofeno && (prefers800 || prefers400)) {
    const ibu = products.filter((p) => /ibuprofeno/i.test(`${p.name} ${p.description ?? ''}`));
    const sorted = ibu.sort((a, b) => {
      const a800 = /800/.test(a.name);
      const b800 = /800/.test(b.name);
      if (prefers800) return a800 === b800 ? 0 : a800 ? -1 : 1;
      return a800 === b800 ? 0 : a800 ? 1 : -1;
    });
    if (sorted.length > 0) {
      const rest = products.filter((p) => !ibu.includes(p));
      products = [...sorted.slice(0, 2), ...rest];
    }
  }

  products = products.slice(0, 4);

  if (products.length === 0) {
    return null;
  }

  const lines = topicChanged
    ? [
        'Entendido, cambiamos de tema. *(Orientación general — no reemplaza consulta médica.)*',
        '',
        playbook.consejo,
        '',
        '**Revisé nuestro catálogo para lo que me cuentas ahora:**',
      ]
    : [
        'Entiendo cómo te sientes. *(Orientación general — no reemplaza consulta médica.)*',
        '',
        playbook.consejo,
        '',
        '**Revisé nuestro catálogo y esto te puede servir:**',
      ];

  for (const p of products) {
    lines.push(`• **${p.name}** — ${productBenefit(p)} **$${finalPrice(p).toFixed(2)}**`);
  }

  const ibuProducts = products.filter((p) =>
    /ibuprofeno/i.test(`${p.name} ${p.description ?? ''}`),
  );
  if (playbook.alternativas?.ibuprofeno && ibuProducts.length >= 2 && !prefers800 && !prefers400) {
    lines.push('', '💡 *¿Prefieres ibuprofeno 400mg o 800mg? Dímelo y te ayudo a elegir.*');
  }

  lines.push('', 'Toca **Añadir al carrito** en los que quieras — tú decides:');

  const tags = products.map((p) => cartTag(p)).filter(Boolean).join('\n');

  return `${lines.join('\n')}\n\n${tags}`;
}

/** Recomendación genérica desde BDD (sin playbook fijo por caso). */
export function buildSmartRecommendationResponse(
  products: MaraiaCatalogProduct[],
  options: {
    careAdvice?: string | null;
    symptomSummary?: string | null;
    topicChanged?: boolean;
  },
): string | null {
  const inStock = products.filter((p) => p.inStock).slice(0, 4);
  if (inStock.length === 0) return null;

  const intro = options.topicChanged
    ? 'Entendido, cambiamos de tema.'
    : 'Entiendo cómo te sientes.';

  const lines = [
    `${intro} *(Orientación general — no reemplaza consulta médica.)*`,
    '',
  ];

  if (options.symptomSummary) {
    lines.push(`Por lo que me cuentas — *${options.symptomSummary}* — revisé nuestro inventario.`);
    lines.push('');
  }

  if (options.careAdvice) {
    lines.push(options.careAdvice);
    lines.push('');
  }

  lines.push('**Esto tenemos en Farma Express y te puede servir:**');

  for (const p of inStock) {
    lines.push(`• **${p.name}** — ${productBenefit(p)} **$${finalPrice(p).toFixed(2)}**`);
  }

  lines.push('', 'Toca **Añadir al carrito** en los que quieras — tú decides:');

  const tags = inStock.map((p) => cartTag(p)).filter(Boolean).join('\n');
  return `${lines.join('\n')}\n\n${tags}`;
}

export function buildConversationContext(
  history: { role: string; text: string }[],
  message: string,
): string {
  const userTexts = history.filter((h) => h.role === 'user').map((h) => h.text);
  return [...userTexts, message].join(' ').toLowerCase();
}

export function buildVagueSymptomsPrompt(): string {
  return 'Lamento que te sientas mal. Para recomendarte productos de nuestra farmacia, cuéntame un poco más:\n\n• ¿Tienes **fiebre** o temperatura alta?\n• ¿**Dolor de cabeza** o cuerpo?\n• ¿**Resfriado**, tos o congestión?\n• ¿**Acidez** o dolor de estómago?\n\nCon eso te muestro lo que tenemos en Farma Express con botón para agregar al carrito.';
}

export function buildOffTopicResponse(): string {
  return 'Soy **Expressia**, asistente de **salud** de Farma Express. Solo puedo ayudarte con:\n\n• Síntomas y malestares leves\n• Cómo usar medicamentos de venta libre\n• Productos de nuestra farmacia y tienda\n\nNo puedo ayudarte con recetas de cocina, tareas, clima u otros temas. **¿Qué síntoma o malestar tienes?**\n\n*Orientación general — no reemplaza consulta médica.*';
}

const CARE_STEPS_BY_SYMPTOM: Record<string, string[]> = {
  fiebre: [
    '1. **Hidrátate** — agua o jugos a sorbos constantes durante el día.',
    '2. **Descansa** — evita esfuerzo físico hasta que baje la fiebre.',
    '3. **Ropa ligera** — ayuda a que el cuerpo disipe el calor.',
    '4. **Antipirético** — si ya te mostré acetaminofén, tómalo según el empaque (generalmente cada 6-8 h).',
    '5. **Controla la temperatura** — paños húmedos si está muy alta.',
    '6. **Consulta médico** si supera 38.5°C por más de 48 h o hay dificultad para respirar.',
  ],
  dolor_cabeza: [
    '1. **Descansa** en un lugar tranquilo y con poca luz.',
    '2. **Hidrátate** — a veces el dolor de cabeza empeora con deshidratación.',
    '3. **Analgésico** — acetaminofén o ibuprofeno según lo que te recomendé, con alimentos si es ibuprofeno.',
    '4. **Evita pantallas** y estrés mientras dure el dolor.',
    '5. **Consulta médico** si es muy intenso, repentino o no cede en 24-48 h.',
  ],
  resfriado: [
    '1. **Reposo** — deja que tu cuerpo se recupere.',
    '2. **Líquidos calientes** — caldos, infusiones, agua.',
    '3. **Antialérgico o vitamina C** — si te los recomendé, sigue el empaque.',
    '4. **Evita automedicarte con antibióticos** — no sirven para virus comunes.',
    '5. **Consulta médico** si la fiebre es alta o los síntomas empeoran después de 5-7 días.',
  ],
  dolor_muscular: [
    '1. **Reposo** del músculo afectado.',
    '2. **Calor local** — compresa tibia 15-20 min.',
    '3. **Antiinflamatorio** — según lo recomendado, con alimentos.',
    '4. **Estiramientos suaves** cuando baje el dolor agudo.',
    '5. **Consulta médico** si el dolor es muy fuerte o no mejora.',
  ],
  acidez: [
    '1. **Evita** comidas grasosas, picantes y café en exceso.',
    '2. **Comidas ligeras** y porciones pequeñas.',
    '3. **Omeprazol o antiácido** — según lo que te recomendé, en ayunas si es omeprazol.',
    '4. **No te acuestes** justo después de comer.',
    '5. **Consulta médico** si el dolor es fuerte o hay sangrado.',
  ],
  alergia: [
    '1. **Evita el desencadenante** si lo identificas (polvo, polen, etc.).',
    '2. **Antialérgico** — loratadina u otro recomendado, 1 vez al día.',
    '3. **Lava manos y rostro** si estuviste expuesto.',
    '4. **Consulta médico** si hay dificultad para respirar o hinchazón en la cara.',
  ],
  deshidratacion: [
    '1. **Bebe agua** a sorbos constantes, no de golpe.',
    '2. **Jugos o caldos** si no toleras mucha agua sola.',
    '3. **Evita alcohol** y bebidas muy azucaradas.',
    '4. **Consulta médico** si hay vómito persistente o no orinas.',
  ],
  dolor_oido: [
    '1. **Descansa** y evita mojar el oído o usar audífonos apretados.',
    '2. **Analgésico** — acetaminofén o ibuprofeno según lo recomendado, con alimentos si es ibuprofeno.',
    '3. **No introduzcas objetos** en el oído (cotonetes, etc.).',
    '4. **Calor seco externo** — compresa tibia cerca (no dentro) del oído puede aliviar.',
    '5. **Consulta médico** si hay fiebre alta, supuración, zumbido fuerte o el dolor no cede en 24-48 h.',
  ],
  malestar: [
    '1. **Descansa** y evita esfuerzo.',
    '2. **Hidrátate** con agua a sorbos.',
    '3. **Analgésico** si hay dolor — según lo que te recomendé.',
    '4. **Consulta médico** si el malestar empeora o dura varios días.',
  ],
};

/** Qué hacer ahora — sin repetir productos ni carrito. */
export function buildCareGuidanceResponse(
  conversationContext: string,
  history?: { role: string; text: string }[],
  userMessage?: string,
): string | null {
  const ctx =
    history && userMessage
      ? buildActiveSymptomContext(history, userMessage)
      : conversationContext.toLowerCase();

  let symptomKey: string | null = null;
  if (/fiebre|calentura|temperatura/.test(ctx)) symptomKey = 'fiebre';
  else if (/dolor de cabeza|cefalea|migra/.test(ctx)) symptomKey = 'dolor_cabeza';
  else if (/resfriado|gripe|tos|congesti/.test(ctx)) symptomKey = 'resfriado';
  else if (/dolor muscular|contractura|espalda/.test(ctx)) symptomKey = 'dolor_muscular';
  else if (/acidez|agruras|reflujo|est[oó]mago/.test(ctx)) symptomKey = 'acidez';
  else if (/alergia|estornudo|rinitis/.test(ctx)) symptomKey = 'alergia';
  else if (/sed|deshidrat|hidrat/.test(ctx)) symptomKey = 'deshidratacion';
  else if (/oido|o[ií]do|otalgia/.test(ctx)) symptomKey = 'dolor_oido';
  else if (/malestar|me siento mal/.test(ctx)) symptomKey = 'malestar';

  if (!symptomKey) return null;

  const steps = CARE_STEPS_BY_SYMPTOM[symptomKey];
  if (!steps) return null;

  return [
    'Te explico **qué hacer ahora** con lo que ya hablamos:',
    '',
    '*(Orientación general — no reemplaza consulta médica.)*',
    '',
    ...steps,
    '',
    'Los productos que te mostré arriba siguen disponibles con el botón **Añadir**. ¿Quieres que te explique **cómo tomar** alguno en específico?',
  ].join('\n');
}

export function responseMissingProducts(text: string): boolean {
  return !/\[AGREGAR_CARRITO:[^\]]+\]/.test(text);
}

const DOSAGE_BY_SKU: Record<string, string> = {
  'FAR-001':
    '**Acetaminofén 500mg** — Adultos: 1-2 tabletas cada 6-8 horas según necesidad, con agua. No superar 8 tabletas (4 g) en 24 h. Evita alcohol mientras lo tomes.',
  'FAR-002':
    '**Ibuprofeno 400mg** — Adultos: 1 tableta cada 6-8 h con alimentos o leche para cuidar el estómago. No exceder lo indicado en el empaque.',
  'FAR-003':
    '**Ibuprofeno 800mg** — Adultos: 1 tableta cada 8-12 h con alimentos. Es de mayor concentración; no combines con otro antiinflamatorio.',
  'VE-BEB-004':
    '**Agua Minalba 1.5L** — Tómala a sorbos frecuentes durante el día. Con fiebre, intenta 8-10 vasos de líquido en total (agua, caldos, jugos).',
  'VE-BEB-005':
    '**Agua Pampero 500ml** — Ideal para llevar y tomar de forma constante. No esperes a tener mucha sed.',
  'VE-BEB-006':
    '**Jugo de naranja 1L** — 1-2 vasos al día como complemento de líquidos y vitamina C. Puedes diluirlo con agua si prefieres.',
  'VE-FAR-004':
    '**Loratadina 10mg** — Usualmente 1 tableta al día. No dupliques la dosis si te saltaste una toma.',
  'VE-FAR-006':
    '**Diclofenaco 100mg** — Generalmente 1 tableta al día con comida. No mezclar con ibuprofeno u otro AINE sin indicación médica.',
  'VE-FAR-003':
    '**Omeprazol 20mg** — Suele tomarse 1 cápsula en ayunas, 30 min antes del desayuno.',
  'VE-FAR-009':
    '**Vitamina C 1g** — 1 tableta efervescente al día, disuelta en agua. No sustituye una alimentación balanceada.',
  'VE-FAR-010':
    '**Ketorolaco 10mg** — Uso sublingual para dolor moderado, por tiempo limitado. Sigue estrictamente el empaque; no combines con otros AINE.',
};

/** Respuesta inteligente cuando preguntan cómo tomar / dosis (sin repetir catálogo). */
export function buildDosageGuidanceResponse(
  catalog: MaraiaCatalogProduct[],
  conversationContext: string,
  userMessage: string,
  history?: { role: string; text: string }[],
): string | null {
  const ctx = history
    ? buildActiveSymptomContext(history, userMessage)
    : conversationContext.toLowerCase();

  // Priorizar productos que ya se mostraron en el chat
  const priorIds = history
    ? history
        .flatMap((h) =>
          h.role === 'model'
            ? [...h.text.matchAll(/\[AGREGAR_CARRITO:([^\]]+)\]/g)].map((m) =>
                m[1].trim(),
              )
            : [],
        )
    : [];

  let matched: MaraiaCatalogProduct[] = [];

  if (priorIds.length > 0) {
    matched = priorIds
      .map((id) => catalog.find((p) => p.id === id && p.inStock))
      .filter((p): p is MaraiaCatalogProduct => p != null);
  }

  if (matched.length === 0) {
    let skus: string[] = [];
    if (/fiebre|calentura|temperatura/.test(ctx)) {
      skus = ['FAR-001', 'VE-BEB-004', 'VE-BEB-006', 'VE-BEB-005'];
    } else if (/dolor de cabeza|cefalea|ibuprofeno|\bibu\b/.test(ctx)) {
      skus = ['FAR-002', 'FAR-003', 'FAR-001'];
    } else if (/resfriado|gripe|tos|congesti[oó]n/.test(ctx)) {
      skus = ['VE-FAR-004', 'VE-FAR-009', 'VE-BEB-006'];
    } else if (/acidez|agruras|est[oó]mago/.test(ctx)) {
      skus = ['VE-FAR-003'];
    } else if (/dolor muscular|contractura|espalda/.test(ctx)) {
      skus = ['FAR-002', 'FAR-003', 'VE-FAR-006'];
    } else if (/oido|o[ií]do|otalgia/.test(ctx)) {
      skus = ['FAR-001', 'FAR-002', 'VE-FAR-006', 'VE-FAR-010'];
    } else if (/malestar|me siento mal/.test(ctx)) {
      skus = ['FAR-001', 'FAR-002', 'VE-BEB-004', 'VE-BEB-005'];
    }

    matched = catalog.filter(
      (p) => p.inStock && (skus.includes(p.sku) || DOSAGE_BY_SKU[p.sku]),
    );
  }

  if (matched.length === 0) {
    return null;
  }

  const lines = [
    '¡Buena pregunta! Te explico **cómo usar cada producto** que te mencioné:',
    '',
    '*(Orientación general — lee siempre el empaque y consulta a un médico o farmacéutico si tienes condiciones especiales, embarazo u otros medicamentos.)*',
    '',
  ];

  const seen = new Set<string>();
  for (const p of matched) {
    if (seen.has(p.sku)) continue;
    seen.add(p.sku);
    const guide =
      DOSAGE_BY_SKU[p.sku] ??
      `**${p.name}** — Sigue las indicaciones del empaque o consulta al farmacéutico.`;
    lines.push(`• ${guide}`);
  }

  if (/fiebre|calentura|temperatura/.test(ctx)) {
    lines.push(
      '',
      '**Consejos generales con fiebre:**',
      '• Alterna reposo e hidratación constante.',
      '• No mezcles acetaminofén con alcohol.',
      '• Si la fiebre no cede en 48 h o supera 38.5°C, consulta a un médico.',
    );
  }

  lines.push(
    '',
    '¿Quieres que te agregue alguno al carrito o tienes otra duda sobre alguno?',
  );

  // Solo re-mostrar botones si el usuario lo pide explícitamente
  if (/agr[eé]ga|carrito|comprar|llevar/.test(userMessage.toLowerCase())) {
    const tags = matched
      .slice(0, 4)
      .map((p) => cartTag(p))
      .filter(Boolean)
      .join('\n');
    if (tags) lines.push('', tags);
  }

  return lines.join('\n');
}

/** Recomendación cuando el usuario cambia preferencia (400 vs 800). */
export function buildPreferenceResponse(
  catalog: MaraiaCatalogProduct[],
  userMessage: string,
): string | null {
  const msg = userMessage.toLowerCase();
  const wants800 = /800|ochocientos/.test(msg);
  const wants400 = /400|cuatrocientos/.test(msg);

  if (!wants800 && !wants400) return null;

  const p400 = catalog.find((p) => p.sku === 'FAR-002' && p.inStock);
  const p800 = catalog.find((p) => p.sku === 'FAR-003' && p.inStock);
  const chosen = wants800 ? p800 : p400;
  const other = wants800 ? p400 : p800;

  if (!chosen) return null;

  const lines = [
    `Perfecto, entonces te recomiendo **${chosen.name}** ($${finalPrice(chosen).toFixed(2)}).`,
    wants800
      ? 'Es de **800mg**: mayor concentración, usualmente 1 tableta cada 8-12 h **con alimentos**.'
      : 'Es de **400mg**: dosis estándar, 1 tableta cada 6-8 h **con alimentos**.',
  ];

  if (other) {
    lines.push(
      '',
      `También tenemos **${other.name}** ($${finalPrice(other).toFixed(2)}) si cambias de opinión.`,
    );
  }

  lines.push('', '¿Te lo agrego al carrito?');

  const tags = [cartTag(chosen), other ? cartTag(other) : ''].filter(Boolean).join('\n');
  return `${lines.join('\n')}\n\n${tags}`;
}
