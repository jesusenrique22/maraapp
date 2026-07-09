#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BACKEND_DIR="$ROOT_DIR/backend-nestjs"

echo "==> MaraPlus: levantando PostgreSQL (Docker, puerto 5433)..."
docker compose -f "$ROOT_DIR/docker-compose.yml" up -d

echo "==> Esperando que PostgreSQL esté listo..."
until docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres pg_isready -U maraplus -d maraplus >/dev/null 2>&1; do
  sleep 1
done

if [ ! -f "$BACKEND_DIR/.env" ]; then
  cp "$BACKEND_DIR/.env.example" "$BACKEND_DIR/.env"
  echo "==> Creado backend-nestjs/.env desde .env.example"
fi

echo "==> Aplicando migraciones y seed..."
cd "$BACKEND_DIR"
npm run prisma:generate
npx prisma migrate deploy
npm run prisma:seed

echo ""
echo "Listo. Para iniciar la API:"
echo "  cd backend-nestjs && npm run start:dev"
echo ""
echo "Verificar conexión:"
echo "  curl http://localhost:3000/health"
