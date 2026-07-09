import type { CatalogProduct } from './catalog.types';

/** Respaldo local de bebidas (imágenes DummyJSON CDN, sin Open Food Facts). */
export const BEVERAGE_FALLBACK_CATALOG: CatalogProduct[] = [
  {
    externalId: 'dj-water',
    sku: 'DJ-GRO-WATER',
    name: 'Agua mineral 1.5L',
    brand: 'MaraPlus',
    description: 'Agua purificada, ideal para hidratación diaria.',
    price: 0.99,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/water/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 'dj-juice',
    sku: 'DJ-GRO-JUICE',
    name: 'Jugo de naranja 1L',
    brand: 'MaraPlus',
    description: 'Jugo natural refrescante, rico en vitamina C.',
    price: 3.99,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/juice/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 'dj-soda',
    sku: 'DJ-GRO-SODA',
    name: 'Refresco cola 2L',
    brand: 'MaraPlus',
    description: 'Bebida carbonatada sabor cola.',
    price: 1.99,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/soft-drinks/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 'dj-milk',
    sku: 'DJ-GRO-MILK',
    name: 'Leche entera 1L',
    brand: 'MaraPlus',
    description: 'Leche fresca pasteurizada.',
    price: 3.49,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/milk/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
  {
    externalId: 'dj-coffee',
    sku: 'DJ-GRO-COFFEE',
    name: 'Café instantáneo 200g',
    brand: 'Nescafé',
    description: 'Café soluble de rápida preparación.',
    price: 7.99,
    currency: 'USD',
    imageUrl: 'https://cdn.dummyjson.com/product-images/groceries/nescafe-coffee/thumbnail.webp',
    category: 'beverages',
    source: 'fallback',
  },
];

export function searchFallbackBeverages(query: string, limit = 10): CatalogProduct[] {
  const normalized = query.trim().toLowerCase();
  const pool = normalized
    ? BEVERAGE_FALLBACK_CATALOG.filter((item) => {
        const haystack = `${item.name} ${item.brand ?? ''} ${item.description}`.toLowerCase();
        return normalized.split(/\s+/).every((term) => haystack.includes(term));
      })
    : BEVERAGE_FALLBACK_CATALOG;

  return pool.slice(0, limit);
}
