#!/usr/bin/env bash
set -euo pipefail

# -------------------- Пути --------------------
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFRA_ENV_FILE="${PROJECT_ROOT}/.env.infrastructure"

# -------------------- Проверка .env --------------------
if [ ! -f "$INFRA_ENV_FILE" ]; then
  echo "Не найден $INFRA_ENV_FILE"
  exit 1
fi

export $(grep -v '^#' "$INFRA_ENV_FILE" | xargs)

PROJECT_ENV_FILE=${1:-"${PROJECT_ROOT}/.env"}
if [ ! -f "$PROJECT_ENV_FILE" ]; then
  echo "Файл $PROJECT_ENV_FILE не найден."
  exit 1
fi

export $(grep -v '^#' "$PROJECT_ENV_FILE" | xargs)

# -------------------- Проверка контейнеров --------------------
if ! docker ps --format '{{.Names}}' | grep -q '^postgres_db$'; then
  echo "Контейнер postgres_db не запущен. Запусти инфраструктуру командой:"
  echo "   docker compose up -d postgres"
  exit 1
fi

if ! docker ps --format '{{.Names}}' | grep -q '^redis_cache$'; then
  echo "Контейнер redis_cache не запущен. Запусти инфраструктуру командой:"
  echo "   docker compose up -d redis"
  exit 1
fi

# -------------------- PostgreSQL --------------------
echo "Создаём PostgreSQL пользователя..."
docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -c "
DO \$\$
BEGIN
   IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$DB_USER') THEN
      CREATE ROLE $DB_USER LOGIN PASSWORD '$DB_PASSWORD';
   END IF;
END
\$\$;
"

# Проверяем, существует ли база
EXISTS=$(docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB_DATABASE';")
if [ "$EXISTS" != "1" ]; then
    echo "🚀 Создаём PostgreSQL базу..."
    docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -c "CREATE DATABASE $DB_DATABASE OWNER $DB_USER;"
else
    echo "База $DB_DATABASE уже существует, пропускаем создание."
fi

# GRANT привилегии
docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_DATABASE" -c "GRANT ALL PRIVILEGES ON DATABASE $DB_DATABASE TO $DB_USER;"

echo "PostgreSQL: пользователь и база созданы."

# -------------------- Redis --------------------
REDIS_URI_ROOT="redis://$REDIS_ROOT_USER:$REDIS_ROOT_PASSWORD@localhost:6379"
REDIS_URI_USER="redis://$REDIS_USER:$REDIS_PASSWORD@localhost:6379"

echo "Создаём Redis пользователя через root URI..."
docker exec -i redis_cache redis-cli -u "$REDIS_URI_ROOT" ACL SETUSER "$REDIS_USER" on ">${REDIS_PASSWORD}" +@all

# Проверка нового пользователя через URI
if docker exec -i redis_cache redis-cli -u "$REDIS_URI_USER" ping | grep -q PONG; then
    echo "Redis: пользователь ${REDIS_USER} успешно создан и работает."
else
    echo "Redis: не удалось создать пользователя ${REDIS_USER}."
fi

echo "Все пользователи и базы созданы!"
