# -------------------- Основные переменные --------------------
DC ?= docker compose

INFRA_FILE = docker-compose.infrastructure.yaml
INFRA_ENV_FILE = .env.infrastructure
CREATE_POSTGRES_SCRIPT = scripts/create_postgres_users.sh
CREATE_REDIS_SCRIPT = scripts/create_redis_pass.sh
PROJECT_ENV_FILE = .env.infrastructure
# ===================== Основные команды =====================

.PHONY: infra-up infra-down

help:
	@echo ""
	@echo "🧭 Доступные команды Makefile:"
	@echo "────────────────────────────────────────────"
	@echo "  infra-up             — поднять инфраструктуру (Postgres + Redis)"
	@echo "  infra-down           — остановить инфраструктуру"
	@echo ""
	@echo "────────────────────────────────────────────"
	@echo "  Infra file: $(INFRA_FILE)"
	@echo ""


# ===================== Infrastructure =====================

infra-up:
	@echo "🚀 Поднимаем инфраструктуру (Postgres + Redis)..."
	$(DC) -f $(INFRA_FILE) --env-file $(INFRA_ENV_FILE) up -d --build
	@echo "✅ Инфраструктура готова!"

infra-down:
	@echo "🛑 Останавливаем инфраструктуру..."
	$(DC) -f $(INFRA_FILE) --env-file $(INFRA_ENV_FILE) down

# ===================== Create users and DB =====================

create-envs:
	@echo "🛠 Создаём пользователей и базы из $(PROJECT_ENV_FILE)..."
	bash $(CREATE_POSTGRES_SCRIPT) $(PROJECT_ENV_FILE)
	@echo "✅ Пользователи и базы созданы!"
create-redis:
	@echo "🛠 Создаём redis.pass.conf"
	bash $(CREATE_REDIS_SCRIPT) $(PROJECT_ENV_FILE)
	@echo "✅ Пользователи и базы созданы!"

# ===================== Combined =====================

infra-all:
	@echo  "Создать конфиг паролей redis"
	make create-redis
	@echo "Запусск контекнеров"
	make infra-up
	@echo "⏳ Ждём, пока контейнеры станут готовыми..."
	@sleep 10
	@echo "🛠 Создаём пользователей и базы..."
	make create-envs
	@echo "🎉 Инфраструктура поднята и env создан!"

