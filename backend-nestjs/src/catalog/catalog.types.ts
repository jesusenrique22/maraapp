export type CatalogCategory = 'beverages' | 'bakery';

export type CatalogSource =
  | 'dummyjson'
  | 'upcitemdb'
  | 'walmart'
  | 'fallback';

export interface CatalogProduct {
  externalId: string;
  sku: string;
  name: string;
  brand: string | null;
  description: string;
  price: number;
  currency: string;
  imageUrl: string;
  category: CatalogCategory;
  source: CatalogSource;
}

export interface CatalogSearchResult {
  query: string;
  source: CatalogSource;
  products: CatalogProduct[];
}
