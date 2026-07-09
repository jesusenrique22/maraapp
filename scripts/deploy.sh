#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
cd "$ROOT"

ENV_FILE="${1:-.env.production}"

if [[ ! -f "$ENV_FILE" ]]; then
  echo "❌ No existe $ENV_FILE"
  echo "   cp .env.production.example .env.production"
  echo "   Edita PUBLIC_URL, POSTGRES_PASSWORD y JWT_SECRET"
  exit 1
fi

echo "▶ Construyendo MaraPlus (web + API + PostgreSQL)..."
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml build

echo "▶ Levantando servicios..."
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml up -d

echo "▶ Esperando API..."
sleep 8

echo "▶ Sembrando datos iniciales (admin + catálogo)..."
docker compose --env-file "$ENV_FILE" -f docker-compose.prod.yml exec -T api npx prisma db seed || true

PORT="$(grep -E '^WEB_PORT=' "$ENV_FILE" | cut -d= -f2- || echo 80)"
PUBLIC="$(grep -E '^PUBLIC_URL=' "$ENV_FILE" | cut -d= -f2- || echo "http://localhost:${PORT}")"

echo ""
echo "✅ MaraPlus en línea"
echo "   App:   ${PUBLIC:-http://localhost:$PORT}"
echo "   Admin: ${PUBLIC:-http://localhost:$PORT}/medic-plus/login"
echo ""
echo "Logs: docker compose --env-file $ENV_FILE -f docker-compose.prod.yml logs -f"
