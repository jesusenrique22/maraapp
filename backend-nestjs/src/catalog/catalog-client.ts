import {
  localizeBakeryTitle,
  localizeDummyJsonBeverage,
} from './catalog-localization';
import {
  getVenezuelanBakeryForSeed,
  getVenezuelanBeveragesForSeed,
  searchVenezuelanBakery,
  searchVenezuelanBeverages,
} from './venezuela-products.data';
import type { CatalogProduct, CatalogSearchResult } from './catalog.types';

const WALMART_HOST = 'real-time-walmart-data.p.rapidapi.com';
const DUMMYJSON_GROCERIES = 'https://dummyjson.com/products/category/groceries?limit=0';
const UPCITEMDB_SEARCH = 'https://api.upcitemdb.com/prod/trial/search';

const BEVERAGE_KEYWORDS = [
  'water',
  'juice',
  'soft drink',
  'soda',
  'milk',
  'coffee',
  'drink',
  'cola',
  'tea',
  'agua',
  'jugo',
  'refresco',
  'leche',
  'café',
];

const BAKERY_KEYWORDS = [
  'bread',
  'bun',
  'bagel',
  'croissant',
  'muffin',
  'roll',
  'tortilla',
  'pan',
  'pastry',
  'cake',
  'donut',
  'doughnut',
];

const NON_FOOD_BLOCKLIST = [
  'mug',
  'plush',
  'collectible',
  'machine',
  'ceramic',
  'tote',
  'bean bag',
  'cap and bow',
  'bottle 8.5 oz with cooler',
  'maker electric',
];

function slugify(value: string): string {
  return value
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-|-$/g, '')
    .slice(0, 48);
}

function parsePrice(value: unknown): number | null {
  if (typeof value === 'number' && Number.isFinite(value)) {
    return Math.round(value * 100) / 100;
  }
  if (typeof value === 'string') {
    const parsed = Number.parseFloat(value.replace(/[^0-9.]/g, ''));
    return Number.isFinite(parsed) ? Math.round(parsed * 100) / 100 : null;
  }
  return null;
}

function capitalizeTitle(title: string): string {
  const trimmed = title.trim();
  if (!trimmed) return trimmed;
  return trimmed.charAt(0).toUpperCase() + trimmed.slice(1);
}

function includesKeyword(haystack: string, keyword: string): boolean {
  const escaped = keyword.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
  return new RegExp(`\\b${escaped}\\b`, 'i').test(haystack);
}

function isBeverageProduct(title: string, tags: string[] = []): boolean {
  if (tags.some((tag) => tag.toLowerCase() === 'beverages')) {
    return true;
  }
  const haystack = `${title} ${tags.join(' ')}`.toLowerCase();
  return BEVERAGE_KEYWORDS.some((keyword) => includesKeyword(haystack, keyword));
}

function isLikelyFoodProduct(title: string, category?: string): boolean {
  const haystack = `${title} ${category ?? ''}`.toLowerCase();
  if (NON_FOOD_BLOCKLIST.some((term) => haystack.includes(term))) {
    return false;
  }
  return BAKERY_KEYWORDS.some((keyword) => includesKeyword(haystack, keyword));
}

function mapDummyJsonProduct(raw: Record<string, unknown>): CatalogProduct | null {
  const title = raw.title as string | undefined;
  const id = raw.id;
  const tags = Array.isArray(raw.tags) ? (raw.tags as string[]) : [];
  const thumbnail = raw.thumbnail as string | undefined;
  const images = Array.isArray(raw.images) ? (raw.images as string[]) : [];
  const imageUrl = thumbnail ?? images[0];
  const price = parsePrice(raw.price);
  const sku = (raw.sku as string | undefined) ?? `DJ-${id}`;

  if (!title || !imageUrl || price == null || !isBeverageProduct(title, tags)) {
    return null;
  }

  const localized = localizeDummyJsonBeverage(
    title,
    raw.description as string | undefined,
  );

  return {
    externalId: String(id),
    sku: `DJ-${sku}`,
    name: localized.name,
    brand: localized.brand,
    description: localized.description,
    price,
    currency: 'USD',
    imageUrl,
    category: 'beverages',
    source: 'dummyjson',
  };
}

function mapUpcItemDbProduct(raw: Record<string, unknown>, index: number): CatalogProduct | null {
  const title = raw.title as string | undefined;
  const category = raw.category as string | undefined;
  const images = Array.isArray(raw.images) ? (raw.images as string[]) : [];
  const imageUrl = images[0];
  const ean = String(raw.ean ?? raw.upc ?? raw.gtin ?? `item-${index}`);
  const brand = (raw.brand as string | undefined) ?? null;

  if (!title || !imageUrl || !isLikelyFoodProduct(title, category)) {
    return null;
  }

  const offers = Array.isArray(raw.offers) ? (raw.offers as Record<string, unknown>[]) : [];
  const offerPrice = offers
    .map((offer) => parsePrice(offer.price))
    .find((value): value is number => value != null);

  const price =
    offerPrice ??
    parsePrice(raw.lowest_recorded_price) ??
    parsePrice(raw.highest_recorded_price) ??
    Math.round((Math.random() * 4 + 2.5) * 100) / 100;

  const localized = localizeBakeryTitle(title);

  return {
    externalId: ean,
    sku: `UPC-${ean}`,
    name: localized.name,
    brand,
    description: brand
      ? `${localized.description} Marca: ${brand}.`
      : localized.description,
    price,
    currency: 'USD',
    imageUrl,
    category: 'bakery',
    source: 'upcitemdb',
  };
}

function mapWalmartProduct(
  raw: Record<string, unknown>,
  index: number,
  category: 'beverages' | 'bakery',
): CatalogProduct | null {
  const title =
    (raw.title as string | undefined) ??
    (raw.name as string | undefined) ??
    (raw.product_name as string | undefined);

  const imageUrl =
    (raw.primary_image as string | undefined) ??
    (raw.image as string | undefined) ??
    (raw.thumbnail as string | undefined) ??
    (raw.image_url as string | undefined);

  const price =
    parsePrice(raw.price) ??
    parsePrice((raw.price as Record<string, unknown> | undefined)?.current) ??
    parsePrice((raw.price as Record<string, unknown> | undefined)?.currentPrice);

  if (!title || !imageUrl || price == null) {
    return null;
  }

  const externalId = String(
    raw.us_item_id ?? raw.product_id ?? raw.id ?? `${slugify(title)}-${index}`,
  );

  const brand =
    (raw.brand as string | undefined) ??
    (raw.manufacturer as string | undefined) ??
    title.split(' ')[0] ??
    null;

  return {
    externalId,
    sku: `WM-${externalId}`,
    name: capitalizeTitle(title),
    brand,
    description: brand
      ? `Marca: ${brand}. Producto comercial de supermercado.`
      : 'Producto comercial de supermercado.',
    price,
    currency: 'USD',
    imageUrl,
    category,
    source: 'walmart',
  };
}

function extractWalmartProducts(payload: unknown): Record<string, unknown>[] {
  if (!payload || typeof payload !== 'object') {
    return [];
  }

  const root = payload as Record<string, unknown>;
  const data = root.data;

  if (Array.isArray(data)) {
    return data as Record<string, unknown>[];
  }

  if (data && typeof data === 'object') {
    const dataObj = data as Record<string, unknown>;
    for (const candidate of [dataObj.products, dataObj.items, dataObj.results]) {
      if (Array.isArray(candidate)) {
        return candidate as Record<string, unknown>[];
      }
    }
  }

  if (Array.isArray(root.products)) {
    return root.products as Record<string, unknown>[];
  }

  return [];
}

export async function searchBeveragesFromDummyJson(limit = 10): Promise<CatalogProduct[]> {
  const response = await fetch(DUMMYJSON_GROCERIES);
  if (!response.ok) {
    throw new Error(`DummyJSON respondió ${response.status}`);
  }

  const payload = (await response.json()) as { products?: Record<string, unknown>[] };
  return (payload.products ?? [])
    .map((item) => mapDummyJsonProduct(item))
    .filter((item): item is CatalogProduct => item != null)
    .slice(0, limit);
}

export async function searchBakeryFromUpcItemDb(
  query: string,
  limit = 10,
): Promise<CatalogProduct[]> {
  const url = new URL(UPCITEMDB_SEARCH);
  url.searchParams.set('s', query.trim() || 'white bread');

  const response = await fetch(url);
  if (!response.ok) {
    throw new Error(`UPCitemdb respondió ${response.status}`);
  }

  const payload = (await response.json()) as {
    code?: string;
    message?: string;
    items?: Record<string, unknown>[];
  };

  if (payload.code === 'TOO_FAST') {
    throw new Error('UPCitemdb: límite de velocidad, intenta de nuevo en unos segundos');
  }

  const seen = new Set<string>();
  const products: CatalogProduct[] = [];

  for (const [index, item] of (payload.items ?? []).entries()) {
    const mapped = mapUpcItemDbProduct(item, index);
    if (!mapped || seen.has(mapped.sku)) continue;
    seen.add(mapped.sku);
    products.push(mapped);
    if (products.length >= limit) break;
  }

  return products;
}

export async function searchBeveragesFromWalmart(
  query: string,
  apiKey: string,
  limit = 10,
): Promise<CatalogProduct[]> {
  const url = new URL('https://real-time-walmart-data.p.rapidapi.com/search');
  url.searchParams.set('query', query);
  url.searchParams.set('page', '1');
  url.searchParams.set('sort_by', 'best_match');
  url.searchParams.set('limit', String(Math.min(limit, 20)));

  const response = await fetch(url, {
    headers: {
      'X-RapidAPI-Key': apiKey,
      'X-RapidAPI-Host': WALMART_HOST,
    },
  });

  if (!response.ok) {
    throw new Error(`Walmart API respondió ${response.status}`);
  }

  const payload = await response.json();
  const status = (payload as { status?: string }).status;
  if (status === 'ERROR') {
    const message = (payload as { error?: { message?: string } }).error?.message;
    throw new Error(message ?? 'Error desconocido en Walmart API');
  }

  return extractWalmartProducts(payload)
    .map((item, index) => mapWalmartProduct(item, index, 'beverages'))
    .filter((item): item is CatalogProduct => item != null)
    .slice(0, limit);
}

export async function searchBeverages(
  query: string,
  options?: { apiKey?: string; limit?: number },
): Promise<CatalogSearchResult> {
  const limit = options?.limit ?? 10;
  const normalizedQuery = query.trim();

  const venezuelan = searchVenezuelanBeverages(normalizedQuery, limit);
  if (venezuelan.length > 0) {
    return {
      query: normalizedQuery || 'all',
      source: 'fallback',
      products: venezuelan,
    };
  }

  if (options?.apiKey && normalizedQuery) {
    try {
      const products = await searchBeveragesFromWalmart(normalizedQuery, options.apiKey, limit);
      if (products.length > 0) {
        return { query: normalizedQuery, source: 'walmart', products };
      }
    } catch {
      // Walmart opcional; seguimos con DummyJSON.
    }
  }

  try {
    const allDrinks = await searchBeveragesFromDummyJson(50);
    const filtered = normalizedQuery
      ? allDrinks.filter((item) => {
          const haystack = `${item.name} ${item.brand ?? ''} ${item.description}`.toLowerCase();
          return normalizedQuery
            .toLowerCase()
            .split(/\s+/)
            .every((term) => haystack.includes(term));
        })
      : allDrinks;

    const products = (filtered.length > 0 ? filtered : allDrinks).slice(0, limit);
    if (products.length > 0) {
      return {
        query: normalizedQuery || 'all',
        source: 'dummyjson',
        products,
      };
    }
  } catch {
    // Caemos al catálogo local.
  }

  const products = getVenezuelanBeveragesForSeed(limit);
  return { query: normalizedQuery || 'all', source: 'fallback', products };
}

export async function searchBakery(
  query: string,
  options?: { limit?: number },
): Promise<CatalogSearchResult> {
  const limit = options?.limit ?? 10;
  const normalizedQuery = query.trim();

  const venezuelan = searchVenezuelanBakery(normalizedQuery, limit);
  if (venezuelan.length > 0) {
    return {
      query: normalizedQuery || 'all',
      source: 'fallback',
      products: venezuelan,
    };
  }

  try {
    const products = await searchBakeryFromUpcItemDb(normalizedQuery || 'white bread', limit);
    if (products.length > 0) {
      return { query: normalizedQuery || 'white bread', source: 'upcitemdb', products };
    }
  } catch {
    // Caemos al catálogo local.
  }

  const products = getVenezuelanBakeryForSeed(limit);
  return { query: normalizedQuery || 'all', source: 'fallback', products };
}

export function getDefaultSeedBeverages(limit = 12): CatalogProduct[] {
  return getVenezuelanBeveragesForSeed(limit);
}

export function getDefaultSeedBakery(limit = 10): CatalogProduct[] {
  return getVenezuelanBakeryForSeed(limit);
}
