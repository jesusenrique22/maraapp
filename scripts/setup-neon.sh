#!/usr/bin/env bash
# Configura Farma Express en Neon.
#
# Uso:
#   1. En Neon → Connect → copia las URLs
#   2. Crea backend-nestjs/.env.neon con:
#        DATABASE_URL="postgresql://...?sslmode=require"   # Pooled
#        DIRECT_URL="postgresql://...?sslmode=require"     # Direct
#   3. ./scripts/setup-neon.sh

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
ENV_NEON="$ROOT/backend-nestjs/.env.neon"
BACKEND="$ROOT/backend-nestjs"

if [[ ! -f "$ENV_NEON" ]]; then
  echo "❌ Falta $ENV_NEON"
  echo ""
  echo "En Neon:"
  echo "  1. Abre el proyecto"
  echo "  2. Botón «Connect»"
  echo "  3. Copia «Pooled connection» → DATABASE_URL"
  echo "  4. Copia «Direct connection»  → DIRECT_URL"
  echo ""
  echo "Crea el archivo:"
  echo "  cp backend-nestjs/.env.neon.example backend-nestjs/.env.neon"
  echo "  nano backend-nestjs/.env.neon"
  exit 1
fi

set -a
# shellcheck disable=SC1090
source "$ENV_NEON"
set +a

if [[ -z "${DATABASE_URL:-}" || -z "${DIRECT_URL:-}" ]]; then
  echo "❌ DATABASE_URL y DIRECT_URL son obligatorios en .env.neon"
  exit 1
fi

echo "▶ Probando conexión a Neon..."
cd "$BACKEND"

if ! npx prisma db execute --stdin <<< "SELECT 1;" >/dev/null 2>&1; then
  echo "▶ Conectando (primera vez)..."
fi

echo "▶ Aplicando migraciones..."
DATABASE_URL="$DATABASE_URL" DIRECT_URL="$DIRECT_URL" npx prisma migrate deploy

echo "▶ Sembrando catálogo, admin y datos iniciales..."
DATABASE_URL="$DATABASE_URL" DIRECT_URL="$DIRECT_URL" npx prisma db seed

echo ""
echo "✅ Farma Express listo en Neon"
echo ""
echo "Pega estas mismas URLs en Render → farmaexpress-api → Environment:"
echo "  DATABASE_URL  = (Pooled connection)"
echo "  DIRECT_URL    = (Direct connection)"
echo ""
echo "Admin: admin@farmaexpress.com / (tu ADMIN_PASSWORD del seed)"
