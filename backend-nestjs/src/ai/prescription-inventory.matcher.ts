import type { PrismaService } from '../prisma/prisma.service';
import type { InventoryService } from '../inventory/inventory.service';
import { searchProductsByTerms } from './maraia-catalog-search';
import { normalizeForMatch } from './maraia-playbooks';
import type {
  ExtractedPrescriptionMedication,
  PrescriptionInventoryProduct,
  PrescriptionMatchStatus,
  PrescriptionScanItemResult,
} from './prescription-scan.types';

function finalPrice(price: number, discountPercent: number | null): number {
  return discountPercent ? price * (1 - discountPercent / 100) : price;
}

function buildSearchTerms(med: ExtractedPrescriptionMedication): string[] {
  const terms = new Set<string>();
  const addTokens = (text: string | null | undefined) => {
    if (!text) return;
    text
      .toLowerCase()
      .split(/[\s,;/()+]+/)
      .map((t) => t.trim())
      .filter((t) => t.length >= 4)
      .forEach((t) => terms.add(t));
  };

  addTokens(med.activeIngredient);
  addTokens(med.medicationName);

  if (terms.size === 0 && med.medicationName) {
    terms.add(med.medicationName.toLowerCase().slice(0, 20));
  }

  return [...terms].slice(0, 8);
}

function scoreNameMatch(extracted: string, productName: string): number {
  const a = normalizeForMatch(extracted);
  const b = normalizeForMatch(productName);
  if (!a || !b) return 0;
  if (a === b) return 100;
  if (b.includes(a) || a.includes(b)) return 85;
  const aTokens = a.split(/\s+/).filter((t) => t.length >= 4);
  const hits = aTokens.filter((t) => b.includes(t)).length;
  return hits * 20;
}

function classifyMatch(
  med: ExtractedPrescriptionMedication,
  products: PrescriptionInventoryProduct[],
): PrescriptionMatchStatus {
  if (products.length === 0) return 'not_found';

  const bestScore = Math.max(
    ...products.map((p) =>
      Math.max(
        scoreNameMatch(med.medicationName, p.name),
        med.activeIngredient
          ? scoreNameMatch(med.activeIngredient, p.name + ' ' + (p.description ?? ''))
          : 0,
      ),
    ),
  );

  if (bestScore >= 80) return 'exact';
  if (bestScore >= 35) return 'similar';
  return products.length > 0 ? 'similar' : 'not_found';
}

async function loadProductDetails(
  prisma: PrismaService,
  inventory: InventoryService,
  ids: string[],
): Promise<PrescriptionInventoryProduct[]> {
  if (ids.length === 0) return [];

  const rows = await prisma.product.findMany({
    where: { id: { in: ids }, isActive: true },
    include: { category: true },
  });

  const stockMap = await inventory.getTotalStockMap(rows.map((p) => p.id));

  return rows.map((p) => {
    const stock = stockMap.get(p.id) ?? 0;
    const price = Number(p.price);
    return {
      id: p.id,
      sku: p.sku,
      name: p.name,
      description: p.description,
      price,
      finalPrice: finalPrice(price, p.discountPercent),
      inStock: stock > 0,
      stock,
      categoryName: p.category?.name ?? 'Farmacia',
      imageUrl: p.imageUrl,
    };
  });
}

export async function matchPrescriptionToInventory(
  prisma: PrismaService,
  inventory: InventoryService,
  medications: ExtractedPrescriptionMedication[],
): Promise<PrescriptionScanItemResult[]> {
  const results: PrescriptionScanItemResult[] = [];

  for (const med of medications) {
    const terms = buildSearchTerms(med);
    const catalogMatches = await searchProductsByTerms(prisma, inventory, terms, {
      limit: 12,
    });

    const ranked = [...catalogMatches]
      .map((p) => ({
        p,
        score: scoreNameMatch(med.medicationName, p.name),
      }))
      .sort((a, b) => b.score - a.score);

    const topIds = ranked.slice(0, 4).map((r) => r.p.id);
    const products = await loadProductDetails(prisma, inventory, topIds);

    const inStockFirst = [
      ...products.filter((p) => p.inStock),
      ...products.filter((p) => !p.inStock),
    ].slice(0, 4);

    results.push({
      extracted: med,
      matchStatus: classifyMatch(med, inStockFirst),
      products: inStockFirst,
    });
  }

  return results;
}
