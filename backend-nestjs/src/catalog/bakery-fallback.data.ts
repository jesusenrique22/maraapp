import type { CatalogProduct } from './catalog.types';

/** Respaldo local de panadería con imágenes Unsplash estables. */
export const BAKERY_FALLBACK_CATALOG: CatalogProduct[] = [
  {
    externalId: 'bak-white-bread',
    sku: 'PAN-API-001',
    name: 'Pan de molde blanco',
    brand: 'Bimbo',
    description: 'Pan de molde suave, ideal para sándwiches.',
    price: 3.28,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1509440159596-0249088772ff?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 'bak-whole-wheat',
    sku: 'PAN-API-002',
    name: 'Pan integral 100%',
    brand: 'Nature\'s Own',
    description: 'Pan integral alto en fibra.',
    price: 3.79,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1549931319-a545dcf3bc73?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 'bak-croissant',
    sku: 'PAN-API-003',
    name: 'Croissants mantequilla x4',
    brand: 'Artisan',
    description: 'Croissants horneados del día, hojaldrados y crujientes.',
    price: 4.5,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1555507036-ab1f4038808a?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 'bak-bagels',
    sku: 'PAN-API-004',
    name: 'Bagels sésamo x6',
    brand: 'Thomas\'',
    description: 'Bagels clásicos con semillas de sésamo.',
    price: 4.25,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1486427944299-195ffd3e8b07?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
  {
    externalId: 'bak-muffin',
    sku: 'PAN-API-005',
    name: 'Muffins de arándanos x4',
    brand: 'Farma Express',
    description: 'Muffins esponjosos con arándanos frescos.',
    price: 5.99,
    currency: 'USD',
    imageUrl:
      'https://images.unsplash.com/photo-1607958996338-0106a0873d78?w=600&auto=format&fit=crop',
    category: 'bakery',
    source: 'fallback',
  },
];

export function searchFallbackBakery(query: string, limit = 10): CatalogProduct[] {
  const normalized = query.trim().toLowerCase();
  const pool = normalized
    ? BAKERY_FALLBACK_CATALOG.filter((item) => {
        const haystack = `${item.name} ${item.brand ?? ''} ${item.description}`.toLowerCase();
        return normalized.split(/\s+/).every((term) => haystack.includes(term));
      })
    : BAKERY_FALLBACK_CATALOG;

  return pool.slice(0, limit);
}

export function getDefaultSeedBakery(limit = 5): CatalogProduct[] {
  return BAKERY_FALLBACK_CATALOG.slice(0, limit);
}
