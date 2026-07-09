#!/usr/bin/env bash
# Elimina banners MaraPuntos de Neon (producción).
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
const { PrismaClient } = require('@prisma/client');
const prisma = new PrismaClient();

(async () => {
  const deleted = await prisma.banner.deleteMany({
    where: {
      title: { contains: 'MaraPuntos', mode: 'insensitive' },
    },
  });
  console.log('✅ Banners MaraPuntos eliminados:', deleted.count);
  await prisma.\$disconnect();
})();
"

echo "Listo."
