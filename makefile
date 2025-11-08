# -------------------- Основные переменные --------------------
DC ?= docker compose

INFRA_FILE = docker-compose.infrastructure.yaml
INFRA_ENV_FILE = .env.infrastructure
CREATE_SCRIPT = scripts/create_project_envs.sh
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
	bash $(CREATE_SCRIPT) $(PROJECT_ENV_FILE)
	@echo "✅ Пользователи и базы созданы!"

# ===================== Combined =====================

infra-all: infra-up
	@echo "⏳ Ждём, пока контейнеры станут готовыми..."
	@sleep 10
	@echo "🛠 Создаём пользователей и базы..."
	bash $(CREATE_SCRIPT) $(PROJECT_ENV_FILE)
	@echo "🎉 Инфраструктура поднята и env создан!"

