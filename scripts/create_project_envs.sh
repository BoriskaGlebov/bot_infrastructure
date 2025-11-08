#!/usr/bin/env bash
set -euo pipefail

# Определяем пути
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
SQL_FILE="${PROJECT_ROOT}/sql/create_project.sql"
INFRA_ENV_FILE="${PROJECT_ROOT}/.env.infrastructure"

# Проверяем наличие инфраструктурного .env
if [ ! -f "$INFRA_ENV_FILE" ]; then
  echo "❌ Не найден $INFRA_ENV_FILE"
  exit 1
fi

# Загружаем root-переменные инфраструктуры
export $(grep -v '^#' "$INFRA_ENV_FILE" | xargs)

# Загружаем .env проекта (из аргумента)
PROJECT_ENV_FILE=${1:-"${PROJECT_ROOT}/.env"}
if [ ! -f "$PROJECT_ENV_FILE" ]; then
  echo "❌ Файл $PROJECT_ENV_FILE не найден."
  exit 1
fi

export $(grep -v '^#' "$PROJECT_ENV_FILE" | xargs)

# Проверяем наличие контейнера postgres_db
if ! docker ps --format '{{.Names}}' | grep -q '^postgres_db$'; then
  echo "❌ Контейнер postgres_db не запущен. Запусти инфраструктуру командой:"
  echo "   docker compose up -d postgres"
  exit 1
fi

echo "🚀 Создаём PostgreSQL пользователя и базу..."
envsubst < "$SQL_FILE" | docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE"

echo "✅ PostgreSQL: пользователь и база созданы."


REDIS_URI_ROOT="redis://$REDIS_ROOT_USER:$REDIS_ROOT_PASSWORD@localhost:6379"
REDIS_URI_USER="redis://$REDIS_USER:$REDIS_PASSWORD@localhost:6379"

echo "🚀 Создаём Redis пользователя через root URI..."
docker exec -i redis_cache redis-cli -u "$REDIS_URI_ROOT" \
    ACL SETUSER "$REDIS_USER" on ">${REDIS_PASSWORD}" +@all

# Проверка нового пользователя через URI
if docker exec -i redis_cache redis-cli -u "$REDIS_URI_USER" ping | grep -q PONG; then
    echo "✅ Redis: пользователь ${REDIS_USER} успешно создан и работает."
else
    echo "❌ Redis: не удалось создать пользователя ${REDIS_USER}."
fi

