import { Prisma } from '@prisma/client';
import type { PrismaService } from '../prisma/prisma.service';
import type { InventoryService } from '../inventory/inventory.service';
import type { MaraiaCatalogProduct } from './maraia-recommendations';
import {
  MARAIA_SYMPTOM_PLAYBOOKS,
  detectSymptomPlaybookKey,
  normalizeForMatch,
} from './maraia-playbooks';

const EXCLUDE_NAME_PATTERNS = [
  'inyectable',
  'infusion',
  'infusión',
  'perfusion',
  'perfusión',
  'intravenos',
  'hospitalario',
  'polvo para',
  'solucion para',
  'solución para',
];

const PREFER_DESCRIPTION_PATTERNS = ['sin receta', 'comprimidos', 'cápsulas', 'capsulas', 'jarabe'];

type DbProductRow = {
  id: string;
  sku: string;
  name: string;
  description: string | null;
  price: Prisma.Decimal;
  discountPercent: number | null;
  isFeatured: boolean;
  category: { name: string; slug: string } | null;
};

function extractActiveIngredient(description: string | null): string {
  if (!description) return '';
  const match = description.match(/Principio Activo:\s*([^.]+)/i);
  const raw = match?.[1] ?? description.slice(0, 60);
  return normalizeForMatch(raw);
}

function isExcludedProduct(name: string, description: string | null): boolean {
  const text = normalizeForMatch(`${name} ${description ?? ''}`);
  return EXCLUDE_NAME_PATTERNS.some((p) => text.includes(normalizeForMatch(p)));
}

function scoreProduct(
  product: DbProductRow,
  terms: string[],
  prioritySkus: Set<string>,
  stock: number,
): number {
  if (stock <= 0) return -1;

  const name = normalizeForMatch(product.name);
  const desc = normalizeForMatch(product.description ?? '');
  let score = 0;

  for (const term of terms) {
    const t = normalizeForMatch(term);
    if (name.includes(t)) score += 12;
    if (desc.includes(t)) score += 6;
  }

  if (prioritySkus.has(product.sku)) score += 25;
  if (product.isFeatured) score += 3;
  if (product.sku.startsWith('VE-FAR-') || product.sku.startsWith('FAR-')) score += 5;
  if (product.category?.slug === 'farmacia') score += 2;

  for (const pref of PREFER_DESCRIPTION_PATTERNS) {
    if (desc.includes(normalizeForMatch(pref))) score += 2;
  }

  if (desc.includes('sujeto a prescripcion') || desc.includes('prescripcion medica')) {
    score -= 4;
  }

  return score;
}

async function queryProductsByTerms(
  prisma: PrismaService,
  terms: string[],
  categorySlugs: string[],
  take = 120,
): Promise<DbProductRow[]> {
  if (terms.length === 0) return [];

  const uniqueTerms = [...new Set(terms.map((t) => t.trim()).filter(Boolean))].slice(0, 12);

  return prisma.product.findMany({
    where: {
      isActive: true,
      category: { isActive: true, slug: { in: categorySlugs } },
      OR: uniqueTerms.flatMap((term) => [
        { name: { contains: term, mode: 'insensitive' as const } },
        { description: { contains: term, mode: 'insensitive' as const } },
      ]),
    },
    include: { category: true },
    take,
    orderBy: [{ isFeatured: 'desc' }, { name: 'asc' }],
  });
}

function rankAndDedup(
  rows: DbProductRow[],
  stockMap: Map<string, number>,
  terms: string[],
  prioritySkus: string[],
  limit: number,
): DbProductRow[] {
  const prioritySet = new Set(prioritySkus);
  const seenIngredients = new Set<string>();
  const scored = rows
    .filter((p) => !isExcludedProduct(p.name, p.description))
    .map((p) => ({
      product: p,
      score: scoreProduct(p, terms, prioritySet, stockMap.get(p.id) ?? 0),
    }))
    .filter((x) => x.score > 0)
    .sort((a, b) => b.score - a.score);

  const picked: DbProductRow[] = [];

  for (const { product } of scored) {
    const ingredient = extractActiveIngredient(product.description);
    const dedupKey = ingredient || normalizeForMatch(product.name).slice(0, 40);
    if (seenIngredients.has(dedupKey)) continue;
    seenIngredients.add(dedupKey);
    picked.push(product);
    if (picked.length >= limit) break;
  }

  return picked;
}

function toCatalogProduct(p: DbProductRow, stock: number): MaraiaCatalogProduct {
  return {
    id: p.id,
    sku: p.sku,
    name: p.name,
    description: p.description,
    price: Number(p.price),
    discountPercent: p.discountPercent,
    categoryName: p.category?.name ?? 'General',
    inStock: stock > 0,
  };
}

/** Busca en la BDD con términos libres (generados por IA o fallback). */
export async function searchProductsByTerms(
  prisma: PrismaService,
  inventory: InventoryService,
  searchTerms: string[],
  options?: { limit?: number; includeHydration?: boolean },
): Promise<MaraiaCatalogProduct[]> {
  const limit = options?.limit ?? 40;
  const terms = searchTerms.filter(Boolean);
  if (terms.length === 0) return [];

  const pharmacySlugs = ['farmacia'];
  const supportTerms = options?.includeHydration ? ['agua', 'jugo', 'hidrat'] : [];
  const supportSlugs = options?.includeHydration ? ['alimentos-bebidas'] : [];

  const [pharmacyRows, supportRows] = await Promise.all([
    queryProductsByTerms(prisma, terms, pharmacySlugs),
    supportTerms.length > 0
      ? queryProductsByTerms(prisma, supportTerms, supportSlugs, 40)
      : Promise.resolve([]),
  ]);

  const merged = new Map<string, DbProductRow>();
  for (const row of [...pharmacyRows, ...supportRows]) {
    merged.set(row.id, row);
  }

  const allRows = [...merged.values()];
  const stockMap = await inventory.getTotalStockMap(allRows.map((p) => p.id));

  const maxPharmacy = supportTerms.length > 0 ? 3 : limit;
  const rankedPharmacy = rankAndDedup(
    allRows.filter((p) => pharmacySlugs.includes(p.category?.slug ?? '')),
    stockMap,
    terms,
    [],
    maxPharmacy,
  );

  const rankedSupport =
    supportTerms.length > 0
      ? rankAndDedup(
          allRows.filter((p) => supportSlugs.includes(p.category?.slug ?? '')),
          stockMap,
          supportTerms,
          [],
          Math.min(2, limit - rankedPharmacy.length),
        )
      : [];

  return [...rankedPharmacy, ...rankedSupport]
    .slice(0, limit)
    .map((p) => toCatalogProduct(p, stockMap.get(p.id) ?? 0));
}

/** Busca en la BDD productos relevantes según playbook (fallback). */
export async function searchProductsForSymptoms(
  prisma: PrismaService,
  inventory: InventoryService,
  conversationContext: string,
  options?: { limit?: number; playbookKey?: string | null },
): Promise<MaraiaCatalogProduct[]> {
  const limit = options?.limit ?? 40;
  const playbookKey = options?.playbookKey ?? detectSymptomPlaybookKey('', conversationContext);
  const playbook = playbookKey ? MARAIA_SYMPTOM_PLAYBOOKS[playbookKey] : null;

  const searchTerms = playbook?.searchTerms ?? ['analgesico', 'paracetamol', 'ibuprofeno'];
  const pharmacySlugs = playbook?.categorySlugs ?? ['farmacia'];
  const supportTerms = playbook?.supportSearchTerms ?? [];
  const supportSlugs = playbook?.supportCategorySlugs ?? [];
  const prioritySkus = playbook?.skus ?? [];

  const [pharmacyRows, supportRows, priorityRows] = await Promise.all([
    queryProductsByTerms(prisma, searchTerms, pharmacySlugs),
    supportTerms.length > 0
      ? queryProductsByTerms(prisma, supportTerms, supportSlugs, 40)
      : Promise.resolve([]),
    prioritySkus.length > 0
      ? prisma.product.findMany({
          where: { isActive: true, sku: { in: prioritySkus } },
          include: { category: true },
        })
      : Promise.resolve([]),
  ]);

  const merged = new Map<string, DbProductRow>();
  for (const row of [...priorityRows, ...pharmacyRows, ...supportRows]) {
    merged.set(row.id, row);
  }

  const allRows = [...merged.values()];
  const stockMap = await inventory.getTotalStockMap(allRows.map((p) => p.id));

  const maxPharmacy = supportTerms.length > 0 ? 3 : limit;
  const rankedPharmacy = rankAndDedup(
    allRows.filter((p) => pharmacySlugs.includes(p.category?.slug ?? '')),
    stockMap,
    searchTerms,
    prioritySkus,
    maxPharmacy,
  );

  const rankedSupport =
    supportTerms.length > 0
      ? rankAndDedup(
          allRows.filter((p) => supportSlugs.includes(p.category?.slug ?? '')),
          stockMap,
          supportTerms,
          [],
          Math.min(2, limit - rankedPharmacy.length),
        )
      : [];

  const finalRows = [...rankedPharmacy, ...rankedSupport].slice(0, limit);

  return finalRows.map((p) => toCatalogProduct(p, stockMap.get(p.id) ?? 0));
}

/** Catálogo reducido para Gemini cuando no hay síntoma claro. */
export async function searchFeaturedPharmacyCatalog(
  prisma: PrismaService,
  inventory: InventoryService,
  limit = 25,
): Promise<MaraiaCatalogProduct[]> {
  const rows = await prisma.product.findMany({
    where: {
      isActive: true,
      isFeatured: true,
      category: { slug: 'farmacia', isActive: true },
    },
    include: { category: true },
    take: limit,
    orderBy: { name: 'asc' },
  });

  const stockMap = await inventory.getTotalStockMap(rows.map((p) => p.id));
  return rows.map((p) => toCatalogProduct(p, stockMap.get(p.id) ?? 0));
}
