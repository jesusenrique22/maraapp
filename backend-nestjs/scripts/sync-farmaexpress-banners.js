/**
 * Actualiza banners Farma Express (colores variados + Cashea).
 * Uso: node scripts/sync-farmaexpress-banners.js
 */
const { PrismaClient, BannerPlacement } = require('@prisma/client');

const prisma = new PrismaClient();

const banners = [
  {
    title: 'Paga con Cashea en Farma Express',
    subtitle: 'Llévalo hoy · Inicial + cuotas sin interés',
    imageUrl:
      'https://images.unsplash.com/photo-1556742049-0cfed4f6a45d?w=900&auto=format&fit=crop',
    backgroundColor: '#FAFF00',
    textColor: '#000000',
    badgeText: 'CASHEA',
    buttonText: 'Ver cómo funciona',
    placement: BannerPlacement.HOME_HERO,
    sortOrder: 0,
    isActive: true,
  },
  {
    title: 'Medic Plus: consulta online',
    subtitle: 'Videollamada y receta digital · 24 horas',
    imageUrl:
      'https://images.unsplash.com/photo-1576091160399-112ba8d25d1d?w=900&auto=format&fit=crop',
    backgroundColor: '#0A1628',
    textColor: '#FFFFFF',
    badgeText: 'MEDIC PLUS',
    buttonText: 'Consultar ahora',
    placement: BannerPlacement.HOME_HERO,
    sortOrder: 1,
    isActive: true,
  },
  {
    title: 'Club FarmaExpress',
    subtitle: 'Gana puntos en cada compra',
    imageUrl:
      'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=900&auto=format&fit=crop',
    backgroundColor: '#7C3AED',
    textColor: '#FFFFFF',
    badgeText: 'CLUB',
    buttonText: 'Ver programa',
    placement: BannerPlacement.HOME_HERO,
    sortOrder: 2,
    isActive: true,
  },
  {
    title: 'Panadería fresca cada mañana',
    subtitle: 'Horneado diario · Stock en vivo',
    imageUrl:
      'https://images.unsplash.com/photo-1486427944299-195ffd3e8b07?w=900&auto=format&fit=crop',
    backgroundColor: '#C2410C',
    textColor: '#FFFFFF',
    badgeText: 'FRESCO',
    buttonText: 'Ver panadería',
    placement: BannerPlacement.HOME_HERO,
    sortOrder: 3,
    isActive: true,
  },
  {
    title: 'Todo en un solo lugar',
    subtitle: 'Farmacia, panadería, charcutería y bodegón · 24h',
    imageUrl:
      'https://images.unsplash.com/photo-1631549916762-40c9c2789f56?w=600&auto=format&fit=crop',
    backgroundColor: '#0F766E',
    textColor: '#FFFFFF',
    badgeText: '24 HORAS',
    buttonText: 'Explorar',
    placement: BannerPlacement.HOME_STRIP,
    sortOrder: 1,
    isActive: true,
  },
  {
    title: 'Elige cuidarte, elige ahorrar',
    subtitle: 'Hasta 20% en farmacia',
    imageUrl:
      'https://images.unsplash.com/photo-1587854692152-cbe660dbde88?w=600&auto=format&fit=crop',
    backgroundColor: '#1D4ED8',
    textColor: '#FFFFFF',
    badgeText: 'OFERTA',
    buttonText: 'Ver farmacia',
    placement: BannerPlacement.HOME_STRIP,
    sortOrder: 2,
    isActive: true,
  },
];

async function main() {
  for (const banner of banners) {
    const existing = await prisma.banner.findFirst({
      where: { placement: banner.placement, sortOrder: banner.sortOrder },
    });
    if (existing) {
      await prisma.banner.update({ where: { id: existing.id }, data: banner });
      console.log('updated', banner.title);
    } else {
      await prisma.banner.create({ data: banner });
      console.log('created', banner.title);
    }
  }

  // Desactivar banners naranja viejos / prueba que no están en el set
  const keepTitles = new Set(banners.map((b) => b.title));
  const all = await prisma.banner.findMany();
  for (const b of all) {
    if (!keepTitles.has(b.title) && b.isActive) {
      // Mantener activos solo si no son naranja-only leftovers
      if (
        b.backgroundColor?.toUpperCase() === '#FF6A00' ||
        b.backgroundColor?.toUpperCase() === '#E85A00' ||
        /prueba|marapuntos|marapadel|mara plus/i.test(b.title)
      ) {
        await prisma.banner.update({
          where: { id: b.id },
          data: { isActive: false },
        });
        console.log('deactivated', b.title);
      }
    }
  }
}

main()
  .then(() => prisma.$disconnect())
  .catch(async (e) => {
    console.error(e);
    await prisma.$disconnect();
    process.exit(1);
  });
