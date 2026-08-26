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
set -a
source "$ENV_FILE"
set +a

SECRETS_FILE="${PROJECT_ROOT}/redis.pass.conf"
echo "Создаём $SECRETS_FILE..."
# Создаем новый файл с нуля и сразу ограничиваем права,
# т.к. файл содержит пароли в открытом виде
: > "$SECRETS_FILE"
chmod 600 "$SECRETS_FILE"

IDENT_RE='^[A-Za-z_][A-Za-z0-9_]*$'

# Обычные пользователи
IFS=',' read -r -a REDIS_USERS_ARR <<< "$REDIS_USERS"
IFS=',' read -r -a REDIS_PASSWORDS_ARR <<< "$REDIS_PASSWORDS"

for i in "${!REDIS_USERS_ARR[@]}"; do
    RUSER="${REDIS_USERS_ARR[$i]}"
    RPASS="${REDIS_PASSWORDS_ARR[$i]}"

    if [[ ! "$RUSER" =~ $IDENT_RE || "$RPASS" =~ [[:space:]] ]]; then
        echo "❌ Недопустимое имя пользователя или пароль (содержит пробел): $RUSER"
        exit 1
    fi

    echo "user $RUSER on >$RPASS ~* +@all" >> "$SECRETS_FILE"
done

echo "✅ $SECRETS_FILE создан."
