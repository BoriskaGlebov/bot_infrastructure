#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFRA_ENV_FILE="${PROJECT_ROOT}/.env.infrastructure"

if [ ! -f "$INFRA_ENV_FILE" ]; then
  echo "❌ Не найден $INFRA_ENV_FILE"
  exit 1
fi

export $(grep -v '^#' "$INFRA_ENV_FILE" | xargs)

# -------------------- Проверка контейнеров --------------------
for container in postgres_db redis_cache; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "❌ Контейнер $container не запущен."
    exit 1
  fi
done

# -------------------- PostgreSQL --------------------
IFS=',' read -r -a DB_USERS_ARR <<< "$DB_USERS"
IFS=',' read -r -a DB_PASSWORDS_ARR <<< "$DB_PASSWORDS"
IFS=',' read -r -a DB_DATABASES_ARR <<< "$DB_DATABASES"

for i in "${!DB_USERS_ARR[@]}"; do
  USER="${DB_USERS_ARR[$i]}"
  PASS="${DB_PASSWORDS_ARR[$i]}"
  DB="${DB_DATABASES_ARR[$i]}"

  echo "🚀 Создаём PostgreSQL пользователя $USER и базу $DB..."
  docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -c "
  DO \$\$
  BEGIN
    IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$USER') THEN
      CREATE ROLE $USER LOGIN PASSWORD '$PASS';
    END IF;
  END
  \$\$;"

  EXISTS=$(docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB';")
  if [ "$EXISTS" != "1" ]; then
      docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -c "CREATE DATABASE $DB OWNER $USER;"
  fi

  docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB" -c "GRANT ALL PRIVILEGES ON DATABASE $DB TO $USER;"
done

echo "✅ PostgreSQL пользователи и базы готовы."

# -------------------- Redis --------------------
IFS=',' read -r -a REDIS_USERS_ARR <<< "$REDIS_USERS"
IFS=',' read -r -a REDIS_PASSWORDS_ARR <<< "$REDIS_PASSWORDS"

REDIS_URI_ROOT="redis://$REDIS_ROOT_USER:$REDIS_ROOT_PASSWORD@localhost:6379"

for i in "${!REDIS_USERS_ARR[@]}"; do
  RUSER="${REDIS_USERS_ARR[$i]}"
  RPASS="${REDIS_PASSWORDS_ARR[$i]}"

  echo "🚀 Создаём Redis пользователя $RUSER..."
  docker exec -i redis_cache redis-cli -u "$REDIS_URI_ROOT" ACL SETUSER "$RUSER" on ">${RPASS}" ~* +@all

  REDIS_URI_USER="redis://$RUSER:$RPASS@localhost:6379"
  if docker exec -i redis_cache redis-cli -u "$REDIS_URI_USER" ping | grep -q PONG; then
    echo "✅ Redis пользователь $RUSER успешно создан."
  else
    echo "⚠️ Не удалось проверить Redis пользователя $RUSER."
  fi
done

echo "🎉 Все пользователи и базы успешно созданы!"
