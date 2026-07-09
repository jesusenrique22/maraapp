#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

echo "==> 1/3 PostgreSQL (Docker)..."
docker compose -f "$ROOT_DIR/docker-compose.yml" up -d

echo "==> Esperando PostgreSQL..."
until docker compose -f "$ROOT_DIR/docker-compose.yml" exec -T postgres pg_isready -U maraplus -d maraplus >/dev/null 2>&1; do
  sleep 1
done
echo "    OK: maraplus-postgres en puerto 5433"

echo ""
echo "==> 2/3 Verificando API (puerto 3000)..."
if curl -sf http://127.0.0.1:3000/health >/dev/null 2>&1; then
  echo "    OK: API ya está corriendo"
else
  echo "    AVISO: La API NO está corriendo."
  echo "    Abre otra terminal y ejecuta:"
  echo "      cd backend-nestjs && npm run start:dev"
fi

echo ""
echo "==> 3/3 Flutter"
echo "    En otra terminal:"
echo "      cd frontend_flutter && flutter run -d chrome"
echo ""
echo "    IMPORTANTE: usa el contenedor 'maraplus-postgres', NO corras"
echo "    postgres manual desde Docker Desktop (necesita POSTGRES_PASSWORD)."
echo ""
echo "    Prueba rápida API:"
echo "      curl http://127.0.0.1:3000/products"
