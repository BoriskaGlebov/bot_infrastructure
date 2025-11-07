# 🧱 bot_infrastructure

**bot_infrastructure** — инфраструктурный проект для развёртывания и поддержки окружения бота.  
Поднимает контейнеры с **PostgreSQL** и **Redis**, управляет сетью и окружением, интегрируется с CI/CD.

---

## 🚀 Возможности

- Автоматический запуск и настройка PostgreSQL и Redis  
- Простое управление через `docker compose`  
- Конфигурация через `.env.infrastructure`  
- Интеграция с GitHub Actions для CI/CD  
- Безопасное хранение секретов через `GitHub Secrets`

---

## 🧩 Требования

- **Linux** (сервер или локальная среда разработки)
- **Docker** ≥ 20.x  
- **Docker Compose** ≥ 2.x  
- Доступ по **SSH** для деплоя  
- Настроенные GitHub Secrets и Environment Variables

---

## ⚙️ Установка и запуск

### 1. Клонировать репозиторий
```bash

git clone git@github.com:BoriskaGlebov/bot_infrastructure.git
cd bot_infrastructure
```

### 2. Настроить переменные окружения
Создай `.env.infrastructure` на основе примера:
```bash

cp .env.infrastructure.example .env.infrastructure
```

Заполни параметры:
```env
# PostgreSQL
DB_ROOT_USER=admin_user
DB_ROOT_PASSWORD=StrongPassword
DB_ROOT_DATABASE=bot_db

# Redis
REDIS_ROOT_USER=admin_user
REDIS_ROOT_PASSWORD=StrongPassword
```

---

### 3. Запуск инфраструктуры локально
```bash

docker compose -f docker-compose.infrastructure.yaml --env-file .env.infrastructure up -d
```

Проверить контейнеры:
```bash

docker ps
docker compose -f docker-compose.infrastructure.yaml --env-file .env.infrastructure ps
```

Посмотреть логи:
```bash

docker compose -f docker-compose.infrastructure.yaml --env-file .env.infrastructure logs -f
```

Остановить:
```bash

docker compose -f docker-compose.infrastructure.yaml --env-file .env.infrastructure down
```

---

## 🧠 Структура проекта

```
bot_infrastructure/
├── .github/workflows/                 # GitHub Actions (CI/CD)
│   └── ci.yml
├── docker-compose.infrastructure.yaml # Инфраструктурные контейнеры
├── .env.infrastructure                # Переменные окружения
├── .env.infrastructure.example        # Пример переменных
├── redis.conf                         # Конфигурация Redis
├── LICENSE                            # Лицензия проекта
├── README.md                          # Этот файл
└── scripts/                           # Скрипты деплоя и утилиты
```

---

## 🔄 CI/CD

GitHub Actions выполняет:
- **infra-check** — проверка синтаксиса YAML и Docker Compose  
- **deploy** — деплой на сервер через SSH

---

## 🧰 Отладка

- Проверить состояние контейнеров:  
  ```bash
  docker ps
  docker compose ps
  ```

- Просмотреть логи сервисов:  
  ```bash
  docker compose logs -f
  ```

- Проверить подключение по SSH:  
  ```bash
  ssh user@host
  ```

---

## 📄 Лицензия

Проект распространяется под лицензией MIT (см. `LICENSE`).

---


