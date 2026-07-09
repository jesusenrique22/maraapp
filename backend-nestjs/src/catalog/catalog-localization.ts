/** Traducciones al español para productos que vienen en inglés de APIs externas. */
const DUMMYJSON_BEVERAGE_ES: Record<
  string,
  { name: string; description: string; brand?: string }
> = {
  Water: {
    name: 'Agua mineral 1.5L',
    brand: 'Minalba',
    description: 'Agua purificada sin gas. Hidratación esencial para el día a día.',
  },
  Juice: {
    name: 'Jugo de naranja 1L',
    brand: 'MaraPlus',
    description: 'Jugo natural refrescante, rico en vitamina C.',
  },
  'Soft Drinks': {
    name: 'Refresco de cola 2L',
    brand: 'Polar',
    description: 'Bebida gaseosa sabor cola. Ideal para compartir en familia.',
  },
  Milk: {
    name: 'Leche entera pasteurizada 1L',
    brand: 'Lácteos Los Andes',
    description: 'Leche fresca entera, fuente de calcio y proteínas.',
  },
  'Nescafe Coffee': {
    name: 'Café soluble 200g',
    brand: 'Nescafé',
    description: 'Café instantáneo de preparación rápida. Sabor intenso.',
  },
};

const BAKERY_TITLE_PATTERNS: Array<{ pattern: RegExp; name: string; description: string }> = [
  {
    pattern: /white bread/i,
    name: 'Pan de molde blanco',
    description: 'Pan de molde suave, ideal para sándwiches y tostadas.',
  },
  {
    pattern: /whole (grain|wheat)/i,
    name: 'Pan integral',
    description: 'Pan integral alto en fibra, opción saludable.',
  },
  {
    pattern: /hot dog bun/i,
    name: 'Pan de perro caliente x8',
    description: 'Panes alargados suaves para perros calientes.',
  },
  {
    pattern: /hamburger (roll|bun)/i,
    name: 'Pan de hamburguesa x6',
    description: 'Panes redondos esponjosos para hamburguesas.',
  },
  {
    pattern: /bagel/i,
    name: 'Bagels surtidos x6',
    description: 'Bagels clásicos, perfectos para el desayuno.',
  },
  {
    pattern: /croissant/i,
    name: 'Croissant de mantequilla',
    description: 'Croissant hojaldrado recién horneado.',
  },
  {
    pattern: /muffin/i,
    name: 'Muffins surtidos x4',
    description: 'Muffins esponjosos, ideales para la merienda.',
  },
  {
    pattern: /gluten.?free.*bread/i,
    name: 'Pan sin gluten',
    description: 'Pan especial para dietas libres de gluten.',
  },
];

export function localizeDummyJsonBeverage(
  englishTitle: string,
  fallbackDescription?: string,
): { name: string; description: string; brand: string | null } {
  const mapped = DUMMYJSON_BEVERAGE_ES[englishTitle];
  if (mapped) {
    return {
      name: mapped.name,
      description: mapped.description,
      brand: mapped.brand ?? null,
    };
  }
  return {
    name: englishTitle,
    description: fallbackDescription ?? `Bebida: ${englishTitle}.`,
    brand: null,
  };
}

export function localizeBakeryTitle(englishTitle: string): {
  name: string;
  description: string;
} {
  for (const rule of BAKERY_TITLE_PATTERNS) {
    if (rule.pattern.test(englishTitle)) {
      return { name: rule.name, description: rule.description };
    }
  }

  const short =
    englishTitle.length > 70 ? `${englishTitle.slice(0, 67).trim()}...` : englishTitle;

  return {
    name: short.charAt(0).toUpperCase() + short.slice(1).toLowerCase(),
    description: 'Producto de panadería comercial, listo para llevar.',
  };
}
