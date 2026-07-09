/** Guías de recomendación por síntoma — términos de búsqueda en la BDD real. */
export const MARAIA_SYMPTOM_PLAYBOOKS: Record<
  string,
  {
    keywords: string[];
    /** Términos para buscar medicamentos en name/description de la BDD */
    searchTerms: string[];
    categorySlugs?: string[];
    supportSearchTerms?: string[];
    supportCategorySlugs?: string[];
    consejo: string;
    skus: string[];
    alternativas?: Record<string, string[]>;
    escalarMedico?: boolean;
  }
> = {
  fiebre: {
    keywords: ['fiebre', 'calentura', 'temperatura alta', 'estoy caliente', 'como fiebre', 'tengo calor'],
    searchTerms: [
      'paracetamol',
      'acetaminofen',
      'ibuprofeno',
      'antipiretico',
      'antipirético',
      'dipirona',
      'metamizol',
    ],
    categorySlugs: ['farmacia'],
    supportSearchTerms: ['agua', 'jugo', 'hidrat'],
    supportCategorySlugs: ['alimentos-bebidas'],
    consejo:
      'Con fiebre leve es clave hidratarse, descansar y monitorear la temperatura. Si supera 38.5°C por más de 48 h o hay dificultad para respirar, consulta a un médico.',
    skus: ['FAR-001', 'VE-BEB-004', 'VE-BEB-006', 'VE-BEB-005'],
    alternativas: {
      analgésico: ['FAR-001', 'VE-FAR-006'],
    },
  },
  dolor_cabeza: {
    keywords: ['dolor de cabeza', 'cefalea', 'me duele la cabeza', 'migraña', 'migrana'],
    searchTerms: [
      'paracetamol',
      'acetaminofen',
      'ibuprofeno',
      'aspirina',
      'acetilsalicilico',
      'naproxeno',
      'ketorolaco',
      'analgesico',
    ],
    categorySlugs: ['farmacia'],
    consejo:
      'Para dolor de cabeza leve, un analgésico puede ayudar junto con hidratación y descanso en un lugar tranquilo.',
    skus: ['FAR-001', 'FAR-002', 'FAR-003'],
    alternativas: {
      ibuprofeno: ['FAR-002', 'FAR-003'],
    },
  },
  resfriado: {
    keywords: ['resfriado', 'gripe', 'congestion', 'moqueo', 'tos', 'catarro'],
    searchTerms: [
      'loratadina',
      'cetirizina',
      'desloratadina',
      'vitamina c',
      'paracetamol',
      'guaifenesina',
      'antitusivo',
      'antialergico',
    ],
    categorySlugs: ['farmacia'],
    supportSearchTerms: ['jugo', 'miel', 'te'],
    supportCategorySlugs: ['alimentos-bebidas'],
    consejo:
      'Reposo, líquidos calientes y vitamina C suelen ayudar en resfriados leves. Evita automedicarte con antibióticos.',
    skus: ['VE-FAR-004', 'VE-FAR-009', 'VE-BEB-006', 'VE-BEB-012'],
  },
  dolor_muscular: {
    keywords: [
      'dolor muscular',
      'muscular',
      'contractura',
      'espalda',
      'cuello',
      'pierna',
      'piernas',
      'rodilla',
      'tobillo',
      'muslo',
      'pantorrilla',
      'brazo',
      'hombro',
      'articulacion',
      'articulación',
      'me duele la pierna',
      'me duele el brazo',
      'me duele la espalda',
      'me duele la rodilla',
      'dolor en la pierna',
      'dolor en el brazo',
    ],
    searchTerms: [
      'ibuprofeno',
      'diclofenaco',
      'naproxeno',
      'ketorolaco',
      'paracetamol',
      'antiinflamatorio',
      'relajante muscular',
    ],
    categorySlugs: ['farmacia'],
    consejo:
      'Calor local, estiramientos suaves y un antiinflamatorio pueden aliviar el dolor muscular leve.',
    skus: ['FAR-002', 'FAR-003', 'VE-FAR-006'],
    alternativas: {
      ibuprofeno: ['FAR-002', 'FAR-003'],
    },
  },
  acidez: {
    keywords: ['acidez', 'agruras', 'reflujo', 'estomago', 'estómago', 'gastritis'],
    searchTerms: ['omeprazol', 'pantoprazol', 'ranitidina', 'antiacido', 'antiácido', 'protector gastrico'],
    categorySlugs: ['farmacia'],
    consejo:
      'Evita comidas grasosas y muy picantes. Un protector gástrico puede ayudar si el malestar persiste.',
    skus: ['VE-FAR-003'],
  },
  alergia: {
    keywords: ['alergia', 'estornudo', 'rinitis', 'picazon', 'picazón', 'ojos llorosos'],
    searchTerms: ['loratadina', 'cetirizina', 'desloratadina', 'bilastina', 'antialergico', 'antihistaminico'],
    categorySlugs: ['farmacia'],
    consejo: 'Un antialérgico puede aliviar síntomas leves. Identifica y evita el desencadenante si es posible.',
    skus: ['VE-FAR-004'],
  },
  dolor_oido: {
    keywords: [
      'dolor de oido',
      'dolor de oído',
      'me duele el oido',
      'me duele el oído',
      'duele el oido',
      'duele el oído',
      'dolor en el oido',
      'dolor en el oído',
      'otalgia',
      'oido me duele',
      'oído me duele',
      'zumbido en el oido',
      'oido tapado',
      'oído tapado',
    ],
    searchTerms: [
      'ibuprofeno',
      'paracetamol',
      'acetaminofen',
      'diclofenaco',
      'ketorolaco',
      'naproxeno',
      'analgesico',
      'antiinflamatorio',
    ],
    categorySlugs: ['farmacia'],
    consejo:
      'El dolor de oído leve puede deberse a congestión o irritación. Un analgésico puede aliviar mientras descansas. Si hay fiebre alta, supuración o el dolor es muy fuerte, consulta a un médico — podría ser infección.',
    skus: ['FAR-001', 'FAR-002', 'VE-FAR-006', 'VE-FAR-010'],
    alternativas: {
      ibuprofeno: ['FAR-002', 'FAR-003'],
    },
    escalarMedico: true,
  },
  malestar: {
    keywords: [
      'malestar',
      'me siento mal',
      'incomodidad',
      'no me siento bien',
      'siento mal',
      'andamos mal',
      'cuerpo mal',
    ],
    searchTerms: [
      'paracetamol',
      'acetaminofen',
      'ibuprofeno',
      'analgesico',
      'antiinflamatorio',
    ],
    categorySlugs: ['farmacia'],
    supportSearchTerms: ['agua'],
    supportCategorySlugs: ['alimentos-bebidas'],
    consejo:
      'Con malestar general, hidratarte y descansar ayuda. Un analgésico de venta libre puede aliviar si hay dolor asociado.',
    skus: ['FAR-001', 'FAR-002', 'VE-BEB-004', 'VE-BEB-005'],
    alternativas: {
      ibuprofeno: ['FAR-002', 'FAR-003'],
    },
  },
  deshidratacion: {
    keywords: ['sed', 'deshidrat', 'hidrat', 'agua', 'liquido', 'líquido'],
    searchTerms: ['suero', 'rehidrat', 'electrolito'],
    categorySlugs: ['farmacia'],
    supportSearchTerms: ['agua', 'jugo', 'isotónica', 'isotonica'],
    supportCategorySlugs: ['alimentos-bebidas'],
    consejo: 'Bebe agua o jugos de forma constante. La hidratación acelera la recuperación.',
    skus: ['VE-BEB-004', 'VE-BEB-005', 'VE-BEB-006', 'VE-BEB-009'],
  },
};

/** SKUs prioritarios siempre visibles para Maraia (farmacia + tienda VE). */
export const MARAIA_PRIORITY_SKUS = [
  'FAR-001',
  'FAR-002',
  'FAR-003',
  'VE-FAR-001',
  'VE-FAR-002',
  'VE-FAR-003',
  'VE-FAR-004',
  'VE-FAR-006',
  'VE-FAR-009',
  'VE-FAR-010',
  'VE-BEB-001',
  'VE-BEB-002',
  'VE-BEB-003',
  'VE-BEB-004',
  'VE-BEB-005',
  'VE-BEB-006',
  'VE-BEB-009',
  'VE-PAN-001',
  'VE-PAN-002',
  'ALI-002',
];

function normalizeForMatch(text: string): string {
  return text
    .toLowerCase()
    .normalize('NFD')
    .replace(/[\u0300-\u036f]/g, '');
}

export { normalizeForMatch };

const PLAYBOOK_ORDER = [
  'dolor_oido',
  'fiebre',
  'dolor_cabeza',
  'resfriado',
  'dolor_muscular',
  'acidez',
  'alergia',
  'malestar',
  'deshidratacion',
];

export function detectSymptomPlaybookKey(
  message: string,
  conversationContext?: string,
): string | null {
  const normalized = normalizeForMatch(conversationContext ?? message);

  for (const key of PLAYBOOK_ORDER) {
    const playbook = MARAIA_SYMPTOM_PLAYBOOKS[key];
    if (playbook.keywords.some((kw) => normalized.includes(normalizeForMatch(kw)))) {
      return key;
    }
  }
  return null;
}

export function detectSymptomPlaybook(
  message: string,
  conversationContext?: string,
): (typeof MARAIA_SYMPTOM_PLAYBOOKS)[string] | null {
  const key = detectSymptomPlaybookKey(message, conversationContext);
  return key ? MARAIA_SYMPTOM_PLAYBOOKS[key] : null;
}

/** Detecta síntoma en el mensaje actual aunque no coincida keyword exacta. */
export function inferSymptomPlaybookKey(message: string): string | null {
  const direct = detectSymptomPlaybookKey(message, message);
  if (direct) return direct;

  const n = normalizeForMatch(message);
  if (!/duele|dolor|molestia|malestar|fiebre|tos|gripe|resfriado|acidez|alergia/.test(n)) {
    return null;
  }
  if (/oido|otalgia/.test(n)) return 'dolor_oido';
  if (/cabeza|cefalea|migrana/.test(n)) return 'dolor_cabeza';
  if (/estomago|panza|barriga|acidez|agrura|reflujo/.test(n)) return 'acidez';
  if (/fiebre|calentura|temperatura/.test(n)) return 'fiebre';
  if (/resfriado|gripe|tos|congestion|moqueo/.test(n)) return 'resfriado';
  if (/alergia|estornudo|rinitis/.test(n)) return 'alergia';
  if (/me duele|dolor en|dolor de|contractura|muscular|pierna|espalda|rodilla/.test(n)) {
    return 'dolor_muscular';
  }
  if (/malestar|me siento mal|incomodidad/.test(n)) return 'malestar';
  return null;
}

export function resolvePlaybookKey(message: string, conversationContext: string): string | null {
  return inferSymptomPlaybookKey(message) ?? detectSymptomPlaybookKey('', conversationContext);
}

export function collectPlaybookSkus(message: string, conversationContext?: string): string[] {
  const normalized = normalizeForMatch(conversationContext ?? message);
  const skus = new Set<string>(MARAIA_PRIORITY_SKUS);

  for (const playbook of Object.values(MARAIA_SYMPTOM_PLAYBOOKS)) {
    if (playbook.keywords.some((kw) => normalized.includes(normalizeForMatch(kw)))) {
      playbook.skus.forEach((sku) => skus.add(sku));
      if (playbook.alternativas) {
        Object.values(playbook.alternativas).flat().forEach((sku) => skus.add(sku));
      }
    }
  }

  // Preferencias explícitas del usuario
  if (/800|ibu.*800/.test(normalized)) {
    skus.add('FAR-003');
  }
  if (/400|ibu.*400/.test(normalized)) {
    skus.add('FAR-002');
  }
  if (/acetaminof|paracetamol|tylenol/.test(normalized)) {
    skus.add('FAR-001');
  }

  return [...skus];
}
