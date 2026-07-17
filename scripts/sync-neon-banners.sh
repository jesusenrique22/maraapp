#!/usr/bin/env bash
# Sincroniza banners MaraPuntos + MaraPadel en Neon.
set -euo pipefail
ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_NEON="$ROOT/backend-nestjs/.env.neon"
BACKEND="$ROOT/backend-nestjs"

if [[ ! -f "$ENV_NEON" ]]; then
  echo "❌ Falta $ENV_NEON"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_NEON"
set +a

export DATABASE_URL DIRECT_URL

cd "$BACKEND"
npx ts-node --transpile-only -e "
const { PrismaClient, BannerPlacement } = require('@prisma/client');
const prisma = new PrismaClient();

(async () => {
  // Quitar strip de delivery gratis.
  await prisma.banner.deleteMany({
    where: {
      placement: BannerPlacement.HOME_STRIP,
      title: { contains: 'Delivery', mode: 'insensitive' },
    },
  });

  const maraPuntos = {
    title: 'MaraPuntos: gana con cada compra',
    subtitle: 'Próximamente · Suma puntos y canjéalos',
    imageUrl:
      'https://images.unsplash.com/photo-1607083206869-4c7672e72a8a?w=900&auto=format&fit=crop',
    backgroundColor: '#7C3AED',
    textColor: '#FFFFFF',
    badgeText: 'PRÓXIMAMENTE',
    buttonText: 'Conocer más',
    placement: BannerPlacement.HOME_HERO,
    sortOrder: 0,
    isActive: true,
  };

  const padel = {
    title: 'MaraPadel · Reserva tu cancha',
    subtitle: 'Agenda tu partido · Próximamente en la app',
    imageUrl:
      'https://images.unsplash.com/photo-1554068865-24cecd4e34b8?w=600&auto=format&fit=crop',
    backgroundColor: '#0284C7',
    textColor: '#FFFFFF',
    badgeText: 'PRÓXIMAMENTE',
    buttonText: 'Agendar',
    placement: BannerPlacement.HOME_STRIP,
    sortOrder: 1,
    isActive: true,
  };

  for (const data of [maraPuntos, padel]) {
    const existing = await prisma.banner.findFirst({
      where: { placement: data.placement, sortOrder: data.sortOrder },
    });
    if (existing) {
      await prisma.banner.update({ where: { id: existing.id }, data });
      console.log('✅ Actualizado:', data.title);
    } else {
      await prisma.banner.create({ data });
      console.log('✅ Creado:', data.title);
    }
  }

  await prisma.\$disconnect();
})();
"

echo "Listo."
