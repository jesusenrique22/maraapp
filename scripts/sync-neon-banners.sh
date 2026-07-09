#!/usr/bin/env bash
# Actualiza banners MaraPuntos en Neon (producción).
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
  await prisma.banner.deleteMany({
    where: {
      placement: BannerPlacement.HOME_HERO,
      title: '15% en tu primera compra',
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

  const existing = await prisma.banner.findFirst({
    where: { placement: BannerPlacement.HOME_HERO, sortOrder: 0 },
  });

  if (existing) {
    await prisma.banner.update({ where: { id: existing.id }, data: maraPuntos });
    console.log('✅ Banner MaraPuntos actualizado:', existing.id);
  } else {
    const created = await prisma.banner.create({ data: maraPuntos });
    console.log('✅ Banner MaraPuntos creado:', created.id);
  }

  await prisma.\$disconnect();
})();
"

echo "Listo."
