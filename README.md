# 🧱 bot_infrastructure

**bot_infrastructure** — инфраструктурный проект для развёртывания и поддержки окружения бота.
Поднимает контейнеры с **PostgreSQL** (с расширением `pgvector`) и **Redis** (с ACL-пользователями), управляет сетью и окружением, интегрируется с CI/CD.

---

## 🚀 Возможности

- Автоматический запуск и настройка PostgreSQL (с `pgvector`) и Redis
- Управление через `docker compose` и `Makefile`
- Автоматическое создание пользователей/баз PostgreSQL и ACL-пользователей Redis из `.env.infrastructure`
- Конфигурация через `.env.infrastructure`
- CI/CD на GitHub Actions с раздельным деплоем на dev- и prod-сервер
- Безопасное хранение секретов через `GitHub Secrets` и `GitHub Environments`

---

## 🧩 Требования

- **Linux** (сервер или локальная среда разработки)
- **Docker** ≥ 20.x
- **Docker Compose** ≥ 2.x
- **make** — используется как для локальной разработки, так и на сервере при деплое через CI/CD
- Доступ по **SSH** для деплоя
- Настроенные GitHub Secrets и Environments (см. раздел [CI/CD](#-cicd))

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
# Настройки базы данных PostgreSQL
DB_ROOT_USER=admin_user
DB_ROOT_PASSWORD=StrongPassword
DB_ROOT_DATABASE=common_db

# Настройки базы данных Redis
REDIS_ROOT_USER=admin_user
REDIS_ROOT_PASSWORD=StrongPassword

# Пользователи и базы для сервисов проекта (списки через запятую, позиционно связаны между собой)
DB_USERS=service_user,service_user2
DB_PASSWORDS=service_password,service_password2
DB_DATABASES=service_db,service_db2

# ACL-пользователи Redis для сервисов проекта
REDIS_USERS=service_user,service_user2
REDIS_PASSWORDS=service_password,service_password2
```

> ⚠️ `.env.infrastructure` и `redis.pass.conf` — секретные файлы, они исключены из git (`.gitignore`). Не коммить их.

### 3. Поднять инфраструктуру

Через `Makefile` (рекомендуемый способ — поднимает контейнеры, генерирует `redis.pass.conf` и создаёт пользователей/базы одной командой):
```bash
make infra-all
```

Либо по шагам:
```bash
make infra-up      # поднять Postgres + Redis
make create-redis  # сгенерировать redis.pass.conf из .env.infrastructure
make create-envs   # создать пользователей и базы PostgreSQL/Redis из .env.infrastructure
```

Остановить инфраструктуру:
```bash
make infra-down
```

Полный список команд:
```bash
make help
```

### Проверка и логи
```bash
docker ps
docker compose -f docker-compose.infrastructure.yaml --env-file .env.infrastructure ps
docker compose -f docker-compose.infrastructure.yaml --env-file .env.infrastructure logs -f
```

---

## 🧠 Структура проекта

```
bot_infrastructure/
├── .github/workflows/
│   └── ci.yml                         # GitHub Actions: infra-check + деплой на dev/prod
├── scripts/
│   ├── create_postgres_users.sh       # Создание пользователей/баз PostgreSQL из .env.infrastructure
│   └── create_redis_pass.sh           # Генерация redis.pass.conf (ACL-пользователи) из .env.infrastructure
├── docker-compose.infrastructure.yaml # Контейнеры Postgres + Redis
├── Dockerfile                         # Образ Redis с envsubst для подстановки паролей в redis.conf
├── makefile                           # Команды infra-up/infra-down/infra-all/create-envs/create-redis
├── redis.conf                         # Конфигурация Redis (ACL root-пользователя + include ACL-файла)
├── redis.pass.conf.example            # Пример ACL-файла Redis (сам файл — секрет, в git не попадает)
├── .env.infrastructure.example        # Пример переменных окружения
├── LICENSE
└── README.md
```

---

## 🔄 CI/CD

Workflow [`ci.yml`](.github/workflows/ci.yml) запускается на push в `main`/`develop` и на pull request-ах, состоит из трёх джобов:

| Джоб | Когда | Что делает |
|---|---|---|
| `infra-check` | push в `main`/`develop`, любой PR | Валидирует `docker-compose.infrastructure.yaml`, собирает образы, поднимает контейнеры и проверяет их health |
| `deploy_dev_server` | push/merge в `develop` | По SSH деплоит инфраструктуру на dev-сервер (vpn-boriska.ru), environment `develop` |
| `deploy_prod_server` | push/merge в `main` | По SSH деплоит инфраструктуру на prod-сервер (help-blocks.ru), environment `production` |

### Ветвление

- Работа ведётся в `develop` → push поднимает/обновляет инфраструктуру на dev-сервере.
- После проверки на dev — merge `develop` → `main` → инфраструктура обновляется на проде.

### Секреты (GitHub → Settings → Environments)

Каждое окружение (`production`, `develop`) настраивается отдельно — так деплой на dev физически не может задеть prod-сервер, даже если что-то пойдёт не так с ветками.

**Environment `production`:**
- `SSH_PRIVATE_KEY`, `SERVER_IP`, `SERVER_USER` — доступ к prod-серверу

**Environment `develop`:**
- `SSH_PRIVATE_KEY2`, `SERVER_IP2`, `SERVER_USER2` — доступ к dev-серверу

**Общие для обоих окружений** (можно задать разные значения на каждое окружение, либо оставить одни repo-level secrets на оба — тогда dev и prod будут использовать одинаковые креды БД/Redis):
- `DB_ROOT_USER`, `DB_ROOT_PASSWORD`, `DB_ROOT_DATABASE`
- `REDIS_ROOT_USER`, `REDIS_ROOT_PASSWORD`
- `DB_USERS`, `DB_PASSWORDS`, `DB_DATABASES`
- `REDIS_USERS`, `REDIS_PASSWORDS`

На сервере, куда идёт деплой (и dev, и prod), должны быть установлены `docker`, `docker compose` и `make`, а репозиторий должен быть заранее склонирован в путь `/opt/bot_infrastructure`.

---

## 🧰 Отладка

- Проверить состояние контейнеров:
  ```bash
  docker ps
  docker compose -f docker-compose.infrastructure.yaml ps
  ```

- Просмотреть логи сервисов:
  ```bash
  docker compose -f docker-compose.infrastructure.yaml logs -f
  ```

- Проверить подключение по SSH:
  ```bash
  ssh user@host
  ```

- Пересоздать пользователей/базы вручную (например, после смены паролей в `.env.infrastructure`):
  ```bash
  make create-redis
  make create-envs
  ```

---

## 📄 Лицензия

Проект распространяется под лицензией MIT (см. `LICENSE`).
