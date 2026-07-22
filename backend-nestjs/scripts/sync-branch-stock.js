/**
 * Redistribuye stock de sucursales viejas/inactivas hacia las 7 sedes Farma Express activas.
 * Uso: node scripts/sync-branch-stock.js
 */
const { PrismaClient, InventoryMovementType } = require('@prisma/client');
const fs = require('fs');
const path = require('path');

function loadEnvFile(filePath) {
  if (!fs.existsSync(filePath)) return;
  const text = fs.readFileSync(filePath, 'utf8');
  for (const line of text.split('\n')) {
    const trimmed = line.trim();
    if (!trimmed || trimmed.startsWith('#')) continue;
    const eq = trimmed.indexOf('=');
    if (eq < 0) continue;
    const key = trimmed.slice(0, eq).trim();
    let value = trimmed.slice(eq + 1).trim();
    if (
      (value.startsWith('"') && value.endsWith('"')) ||
      (value.startsWith("'") && value.endsWith("'"))
    ) {
      value = value.slice(1, -1);
    }
    if (!process.env[key]) process.env[key] = value;
  }
}

const root = path.join(__dirname, '..');
loadEnvFile(path.join(root, '.env.neon'));
loadEnvFile(path.join(root, '.env'));

const prisma = new PrismaClient();

function movementDelta(type, quantity) {
  switch (type) {
    case 'ENTRY':
      return quantity;
    case 'EXIT':
    case 'SALE':
    case 'WASTE':
      return -Math.abs(quantity);
    case 'ADJUSTMENT':
      return quantity;
    default:
      return 0;
  }
}

async function main() {
  const activeBranches = await prisma.branch.findMany({
    where: { isActive: true },
    orderBy: { sortOrder: 'asc' },
  });
  if (!activeBranches.length) {
    throw new Error('No hay sucursales activas');
  }

  const activeIds = new Set(activeBranches.map((b) => b.id));
  const already = await prisma.inventoryMovement.count({
    where: {
      reference: 'SEED-REBALANCE-2026',
      branchId: { in: [...activeIds] },
    },
  });
  if (already > 0) {
    console.log(`Ya hay ${already} movimientos SEED-REBALANCE-2026; no duplico.`);
    return;
  }

  const movements = await prisma.inventoryMovement.findMany({
    where: {
      OR: [
        { branchId: null },
        { branchId: { notIn: [...activeIds] } },
      ],
    },
    select: { productId: true, type: true, quantity: true },
  });

  const stockByProduct = new Map();
  for (const m of movements) {
    const cur = stockByProduct.get(m.productId) ?? 0;
    stockByProduct.set(
      m.productId,
      cur + movementDelta(m.type, m.quantity),
    );
  }

  const admin = await prisma.user.findFirst({
    where: { role: 'ADMIN' },
    select: { id: true },
  });

  const toCreate = [];
  for (const [productId, total] of stockByProduct.entries()) {
    const base = Math.max(0, Math.floor(total));
    if (base <= 0) continue;

    for (const [index, branch] of activeBranches.entries()) {
      // Principal lleva el stock completo; el resto un stock operativo
      const qty = branch.isMain
        ? base
        : Math.max(8, Math.floor(base * (0.55 - index * 0.04)));
      if (qty <= 0) continue;
      toCreate.push({
        productId,
        branchId: branch.id,
        type: InventoryMovementType.ENTRY,
        quantity: qty,
        userId: admin?.id,
        reference: 'SEED-REBALANCE-2026',
        notes: `Rebalance stock → ${branch.slug}`,
      });
    }
  }

  console.log(
    `Creando ${toCreate.length} movimientos para ${activeBranches.length} sedes…`,
  );
  for (let i = 0; i < toCreate.length; i += 2000) {
    const batch = toCreate.slice(i, i + 2000);
    await prisma.inventoryMovement.createMany({ data: batch });
    console.log(`  ${Math.min(i + 2000, toCreate.length)}/${toCreate.length}`);
  }

  // Smoke: stock de sede principal en un producto featured
  const main = activeBranches.find((b) => b.isMain) ?? activeBranches[0];
  const sample = await prisma.product.findFirst({
    where: { isActive: true, isFeatured: true },
    select: { id: true, name: true },
  });
  if (sample) {
    const sampleMoves = await prisma.inventoryMovement.findMany({
      where: { productId: sample.id, branchId: main.id },
      select: { type: true, quantity: true },
    });
    const stock = sampleMoves.reduce(
      (t, m) => t + movementDelta(m.type, m.quantity),
      0,
    );
    console.log(`OK ${main.slug}: "${sample.name}" stock=${stock}`);
  }
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
