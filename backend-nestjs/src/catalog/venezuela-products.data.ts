import type { CatalogProduct } from './catalog.types';

/** Bebidas venezolanas y regionales — nombres y descripciones en español. */
export const VENEZUELAN_BEVERAGES: CatalogProduct[] = [
  {
    externalId: 've-polar',
    sku: 'VE-BEB-001',
    name: 'Refresco Polar 2L',
    brand: 'Polar',
    description: 'Refresco de cola venezolano, sabor clásico. Ideal para compartir en familia.',
    price: 1.85,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/soft-drinks/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-frescolita',
    sku: 'VE-BEB-002',
    name: 'Frescolita 1.5L',
    brand: 'Frescolita',
    description: 'Bebida gaseosa sabor único, muy popular en Venezuela. Burbujas refrescantes.',
    price: 1.65,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/soft-drinks/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-cocacola',
    sku: 'VE-BEB-003',
    name: 'Coca-Cola Original 1.5L',
    brand: 'Coca-Cola',
    description: 'Refresco de cola original. Perfecto para acompañar comidas y reuniones.',
    price: 2.1,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/soft-drinks/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-minalba',
    sku: 'VE-BEB-004',
    name: 'Agua Minalba 1.5L',
    brand: 'Minalba',
    description: 'Agua mineral sin gas, pureza garantizada. Hidratación para todo el día.',
    price: 0.95,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/water/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-pampero',
    sku: 'VE-BEB-005',
    name: 'Agua Pampero 500 ml',
    brand: 'Pampero',
    description: 'Agua purificada en presentación personal. Fácil de llevar.',
    price: 0.55,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/water/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-jugo-naranja',
    sku: 'VE-BEB-006',
    name: 'Jugo de naranja 1L',
    brand: 'MaraPlus',
    description: 'Néctar de naranja natural, rico en vitamina C. Sabor cítrico refrescante.',
    price: 2.4,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/juice/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-leche',
    sku: 'VE-BEB-007',
    name: 'Leche entera pasteurizada 1L',
    brand: 'Lácteos Los Andes',
    description: 'Leche fresca entera, fuente de calcio y proteínas. Ideal para el desayuno.',
    price: 2.8,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/milk/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-cafe',
    sku: 'VE-BEB-008',
    name: 'Café molido tradicional 250g',
    brand: 'Café Madrid',
    description: 'Café venezolano de tueste medio. Aroma intenso para la cafetera de todos los días.',
    price: 4.5,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/nescafe-coffee/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-yukery',
    sku: 'VE-BEB-009',
    name: 'Yukery Parchita 1L',
    brand: 'Yukery',
    description: 'Bebida de parchita (maracuyá) lista para servir. Sabor tropical venezolano.',
    price: 2.2,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/juice/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-sprite',
    sku: 'VE-BEB-010',
    name: 'Sprite Lima-Limón 2L',
    brand: 'Sprite',
    description: 'Refresco sin cafeína, sabor lima-limón. Refrescante y burbujeante.',
    price: 1.9,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/soft-drinks/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-malta',
    sku: 'VE-BEB-011',
    name: 'Malta Regional 1.5L',
    brand: 'Regional',
    description: 'Bebida de malta no alcohólica, energizante y nutritiva. Clásico venezolano.',
    price: 1.75,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/soft-drinks/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 've-te',
    sku: 'VE-BEB-012',
    name: 'Té negro surtido x25 bolsitas',
    brand: 'Tetley',
    description: 'Té negro en bolsitas individuales. Perfecto para la merienda.',
    price: 3.2,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/nescafe-coffee/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
];

/** Panadería venezolana — nombres y descripciones en español. */
export const VENEZUELAN_BAKERY: CatalogProduct[] = [
  {
    externalId: 've-pan-canilla',
    sku: 'VE-PAN-001',
    name: 'Pan canilla tradicional',
    brand: 'MaraPlus Panadería',
    description: 'Pan crujiente por fuera y suave por dentro. Horneado diario en nuestras sucursales.',
    price: 0.85,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-cachito',
    sku: 'VE-PAN-002',
    name: 'Cachito de jamón x2',
    brand: 'MaraPlus Panadería',
    description: 'Clásico desayuno venezolano. Masa hojaldrada rellena de jamón ahumado.',
    price: 2.5,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-golfeado',
    sku: 'VE-PAN-003',
    name: 'Golfeado con queso',
    brand: 'MaraPlus Panadería',
    description: 'Rollito dulce con anís, papelón y queso blanco rallado. Especialidad venezolana.',
    price: 1.2,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1486427944299-195ffd3e8b07?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-pan-molde',
    sku: 'VE-PAN-004',
    name: 'Pan de molde blanco',
    brand: 'Bimbo',
    description: 'Pan de molde suave, ideal para sándwiches y tostadas en el hogar.',
    price: 2.9,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-pan-integral',
    sku: 'VE-PAN-005',
    name: 'Pan integral 100%',
    brand: 'Bimbo',
    description: 'Pan integral alto en fibra. Opción saludable para el desayuno.',
    price: 3.4,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-media-noche',
    sku: 'VE-PAN-006',
    name: 'Pan de medianoche x4',
    brand: 'MaraPlus Panadería',
    description: 'Pan dulce esponjoso, perfecto para hamburguesas gourmet o perros calientes.',
    price: 2.1,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-croissant',
    sku: 'VE-PAN-007',
    name: 'Croissant de mantequilla x2',
    brand: 'MaraPlus Panadería',
    description: 'Croissants hojaldrados recién horneados. Crujientes por fuera, suaves por dentro.',
    price: 2.8,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-queso-crema',
    sku: 'VE-PAN-008',
    name: 'Pan de queso andino x6',
    brand: 'MaraPlus Panadería',
    description: 'Bollitos de queso esponjosos. Snack salado ideal para la tarde.',
    price: 3.5,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1607958996338-0106a0873d78?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-torta',
    sku: 'VE-PAN-009',
    name: 'Torta tres leches porción',
    brand: 'MaraPlus Repostería',
    description: 'Porción individual de torta tres leches. Postre cremoso y tradicional.',
    price: 3.0,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1578985545062-69928b1d9587?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 've-galletas',
    sku: 'VE-PAN-010',
    name: 'Galletas María 200g',
    brand: 'María',
    description: 'Galletas clásicas para el café o la leche. Sabor tradicional.',
    price: 1.4,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1558961363-fa8aad1c9fd0?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
];

export function getVenezuelanBeveragesForSeed(limit = 12): CatalogProduct[] {
  return VENEZUELAN_BEVERAGES.slice(0, limit);
}

export function getVenezuelanBakeryForSeed(limit = 10): CatalogProduct[] {
  return VENEZUELAN_BAKERY.slice(0, limit);
}

export function searchVenezuelanBeverages(query: string, limit = 10): CatalogProduct[] {
  const normalized = query.trim().toLowerCase();
  const pool = normalized
    ? VENEZUELAN_BEVERAGES.filter((item) => {
        const haystack = `${item.name} ${item.brand ?? ''} ${item.description}`.toLowerCase();
        return normalized.split(/\s+/).every((term) => haystack.includes(term));
      })
    : VENEZUELAN_BEVERAGES;
  return pool.slice(0, limit);
}

export function searchVenezuelanBakery(query: string, limit = 10): CatalogProduct[] {
  const normalized = query.trim().toLowerCase();
  const pool = normalized
    ? VENEZUELAN_BAKERY.filter((item) => {
        const haystack = `${item.name} ${item.brand ?? ''} ${item.description}`.toLowerCase();
        return normalized.split(/\s+/).every((term) => haystack.includes(term));
      })
    : VENEZUELAN_BAKERY;
  return pool.slice(0, limit);
}
