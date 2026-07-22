/**
 * Sincroniza solo las 7 sedes Farma Express (sin re-seed completo CIMA).
 * Uso: node scripts/sync-farmaexpress-branches.js
 * Lee DATABASE_URL de .env.neon o .env
 */
const { PrismaClient } = require('@prisma/client');
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

const branches = [
  {
    name: 'Farma Express C-2',
    slug: 'sede-c2',
    address: 'Circunvalación 2, sector San Miguel (antiguo Bingo Royal)',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0101',
    whatsapp: '+58 414-555-0101',
    openingHours: 'Abierto 24 horas',
    isMain: true,
    isActive: true,
    sortOrder: 1,
    latitude: 10.6425,
    longitude: -71.6128,
  },
  {
    name: 'Farma Express La 72',
    slug: 'sede-la-72',
    address: 'Calle 72 con Av. 12-10',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0102',
    whatsapp: '+58 414-555-0102',
    openingHours: 'Abierto 24 horas',
    isMain: false,
    isActive: true,
    sortOrder: 2,
    latitude: 10.6668,
    longitude: -71.6055,
  },
  {
    name: 'Farma Express El Milagro',
    slug: 'sede-el-milagro',
    address: 'Av. 2 El Milagro (CC Caribe Zulia)',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0103',
    whatsapp: '+58 414-555-0103',
    openingHours: 'Abierto 24 horas',
    isMain: false,
    isActive: true,
    sortOrder: 3,
    latitude: 10.6752,
    longitude: -71.6335,
  },
  {
    name: 'Farma Express La Limpia',
    slug: 'sede-la-limpia',
    address: 'Av. La Limpia',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0104',
    whatsapp: '+58 414-555-0104',
    openingHours: 'Abierto 24 horas',
    isMain: false,
    isActive: true,
    sortOrder: 4,
    latitude: 10.6541,
    longitude: -71.6248,
  },
  {
    name: 'Farma Express Delicias',
    slug: 'sede-delicias',
    address: 'Av. Delicias',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0105',
    whatsapp: '+58 414-555-0105',
    openingHours: 'Abierto 24 horas',
    isMain: false,
    isActive: true,
    sortOrder: 5,
    latitude: 10.6612,
    longitude: -71.6189,
  },
  {
    name: 'Farma Express Fuerzas Armadas',
    slug: 'sede-fuerzas-armadas',
    address: 'Av. Fuerzas Armadas',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0106',
    whatsapp: '+58 414-555-0106',
    openingHours: 'Abierto 24 horas',
    isMain: false,
    isActive: true,
    sortOrder: 6,
    latitude: 10.6705,
    longitude: -71.6212,
  },
  {
    name: 'Farma Express Ciudad Chinita',
    slug: 'sede-ciudad-chinita',
    address: 'Centro de la ciudad',
    city: 'Maracaibo',
    state: 'Zulia',
    phone: '+58 261-555-0107',
    whatsapp: '+58 414-555-0107',
    openingHours: 'Abierto 24 horas',
    isMain: false,
    isActive: true,
    sortOrder: 7,
    latitude: 10.657,
    longitude: -71.6045,
  },
];

async function main() {
  const slugs = branches.map((b) => b.slug);
  for (const branch of branches) {
    await prisma.branch.upsert({
      where: { slug: branch.slug },
      update: branch,
      create: branch,
    });
    console.log('✓', branch.name);
  }

  const deactivated = await prisma.branch.updateMany({
    where: { slug: { notIn: slugs } },
    data: { isActive: false, isMain: false },
  });
  console.log(`Desactivadas otras sedes: ${deactivated.count}`);

  const active = await prisma.branch.findMany({
    where: { isActive: true },
    orderBy: { sortOrder: 'asc' },
    select: { name: true, address: true, isMain: true },
  });
  console.table(active);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
