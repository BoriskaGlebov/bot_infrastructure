#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "$SCRIPT_DIR")"
ENV_FILE="${PROJECT_ROOT}/.env.infrastructure"

if [ ! -f "$ENV_FILE" ]; then
    echo "❌ Файл $ENV_FILE не найден"
    exit 1
fi

# Загружаем переменные окружения
export $(grep -v '^#' "$ENV_FILE" | xargs)

SECRETS_FILE="redis.pass.conf"
echo "Создаём $SECRETS_FILE..."

# Начальные ACL
echo "user default off" > "$SECRETS_FILE"
echo "user $REDIS_ROOT_USER on >$REDIS_ROOT_PASSWORD allcommands allkeys" >> "$SECRETS_FILE"

# Обычные пользователи
IFS=',' read -r -a REDIS_USERS_ARR <<< "$REDIS_USERS"
IFS=',' read -r -a REDIS_PASSWORDS_ARR <<< "$REDIS_PASSWORDS"

for i in "${!REDIS_USERS_ARR[@]}"; do
    RUSER="${REDIS_USERS_ARR[$i]}"
    RPASS="${REDIS_PASSWORDS_ARR[$i]}"
    echo "user $RUSER on >$RPASS ~* +@all" >> "$SECRETS_FILE"
done

echo "✅ $SECRETS_FILE создан."
