#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
INFRA_ENV_FILE="${PROJECT_ROOT}/.env.infrastructure"

if [ ! -f "$INFRA_ENV_FILE" ]; then
  echo "❌ Не найден $INFRA_ENV_FILE"
  exit 1
fi

set -a
source "$INFRA_ENV_FILE"
set +a

# -------------------- Проверка контейнеров --------------------
for container in postgres_db redis_cache; do
  if ! docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
    echo "❌ Контейнер $container не запущен."
    exit 1
  fi
done

IDENT_RE='^[A-Za-z_][A-Za-z0-9_]*$'

# -------------------- PostgreSQL --------------------
IFS=',' read -r -a DB_USERS_ARR <<< "$DB_USERS"
IFS=',' read -r -a DB_PASSWORDS_ARR <<< "$DB_PASSWORDS"
IFS=',' read -r -a DB_DATABASES_ARR <<< "$DB_DATABASES"

for i in "${!DB_USERS_ARR[@]}"; do
  USER="${DB_USERS_ARR[$i]}"
  PASS="${DB_PASSWORDS_ARR[$i]}"
  DB="${DB_DATABASES_ARR[$i]}"

  if [[ ! "$USER" =~ $IDENT_RE || ! "$DB" =~ $IDENT_RE ]]; then
    echo "❌ Недопустимое имя пользователя/базы: $USER / $DB"
    exit 1
  fi

  # Экранируем одинарные кавычки в пароле для безопасной подстановки в SQL-литерал
  PASS_ESCAPED="${PASS//\'/\'\'}"

  echo "Создаём PostgreSQL пользователя $USER и базу $DB..."
  # SQL с паролем передаём через stdin (heredoc), а не через -c,
  # чтобы пароль не светился в выводе `ps`/`docker top`
  docker exec -i postgres_db psql -v ON_ERROR_STOP=1 -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" <<SQL
DO \$do\$
BEGIN
  IF NOT EXISTS (SELECT FROM pg_roles WHERE rolname = '$USER') THEN
    CREATE ROLE "$USER" LOGIN PASSWORD '$PASS_ESCAPED';
  END IF;
END
\$do\$;
SQL

  EXISTS=$(docker exec -i postgres_db psql -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -tAc "SELECT 1 FROM pg_database WHERE datname='$DB';")
  if [ "$EXISTS" != "1" ]; then
      docker exec -i postgres_db psql -v ON_ERROR_STOP=1 -U "$DB_ROOT_USER" -d "$DB_ROOT_DATABASE" -c "CREATE DATABASE \"$DB\" OWNER \"$USER\";"
  fi

  docker exec -i postgres_db psql -v ON_ERROR_STOP=1 -U "$DB_ROOT_USER" -d "$DB" -c "GRANT ALL PRIVILEGES ON DATABASE \"$DB\" TO \"$USER\";"
  docker exec -i postgres_db psql -v ON_ERROR_STOP=1 -U "$DB_ROOT_USER" -d "$DB" -c "CREATE EXTENSION IF NOT EXISTS vector;"
done

echo "✅ PostgreSQL пользователи и базы готовы."