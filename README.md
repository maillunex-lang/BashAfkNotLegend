# Башкирия: Герои без легенд

Онлайн AFK Idle RPG. Android — Godot 4, iPhone — отдельная React/Phaser PWA, сервер — Go + PostgreSQL.

**Источник истины по концепции:** [`GAME.md`](GAME.md)  
**Мастер-промпт для ИИ:** [`CURSOR_MASTER_PROMPT.md`](CURSOR_MASTER_PROMPT.md)  
**Навигатор статусов:** [`ROAD.md`](ROAD.md)  
**Контекст для нового агента:** [`PROJECT_CONTEXT.md`](PROJECT_CONTEXT.md)

## Статус

Этап **00. Проектирование и фундамент** — документация и каркас репозитория. Массовая разработка игровых систем не начата до согласования блокирующих вопросов в [`DECISIONS.md`](DECISIONS.md).

## Структура репозитория

```text
apps/android-godot/   # Godot 4 Android-клиент
apps/ios-pwa/         # React + Phaser PWA
apps/admin/           # React/TypeScript админка
services/game-server/ # Go REST/WS + доменная логика
packages/contracts/   # OpenAPI / JSON Schema
packages/content/     # Версионированный игровой контент
infra/docker/         # Локальный Docker Compose
infra/migrations/     # SQL-миграции
infra/deploy/         # Скрипты деплоя (только после явного разрешения)
tests/                # Интеграционные, E2E, нагрузочные
assets/source/        # Исходники иллюстраций/анимаций
assets/exports/       # Оптимизированные атласы и манифесты
docs/stages/          # Детальные планы этапов 01–07
```

## Документация

| Файл | Назначение |
|------|------------|
| [ARCHITECTURE.md](ARCHITECTURE.md) | Системная схема и ADR |
| [API_CONTRACT.md](API_CONTRACT.md) | REST/WS, версии, события, ошибки |
| [CONTENT_SCHEMA.md](CONTENT_SCHEMA.md) | Герои, навыки, предметы, карты, диалоги |
| [ECONOMY.md](ECONOMY.md) | Валюты, AFK, гача, VIP, награды |
| [AI_PLAYERS.md](AI_PLAYERS.md) | Поведение ИИ, память, чат, дипломатия |
| [QA_PLAN.md](QA_PLAN.md) | Unit, integration, E2E, load, device |
| [DECISIONS.md](DECISIONS.md) | Журнал решений и блокирующие вопросы |
| [docs/stages/](docs/stages/) | Чеклисты этапов разработки |

## Безопасный локальный запуск

Пока инфраструктура этапа 00 не реализована, запуск сервисов недоступен.

Планируемый локальный стек (после утверждения и реализации):

```bash
# из корня репозитория
docker compose -f infra/docker/docker-compose.yml up -d
# миграции: infra/migrations
# сервер: services/game-server
# PWA: apps/ios-pwa
# Godot: открыть apps/android-godot в Godot 4
```

Секреты — только через переменные окружения / секретное хранилище. Не коммитить `.env` с реальными ключами.

## Неприкосновенные решения (кратко)

- Два клиента: Godot 4 (Android) и отдельная React/Phaser PWA (iPhone); не Godot Web.
- Авторитетный Go-сервер; клиенты не являются источником истины по бою/RNG/валютам.
- ИИ-чат = библиотека фраз без LLM; ИИ помечены как виртуальные игроки.
- Гильдия до 30 участников; ИИ-гильдии с дипломатией.
- Порядок разработки по системам: герои → бои → карта → онлайн → гильдии → монетизация → релиз.

Полный реестр: [`GAME.md`](GAME.md) §2.

## Правила для контрибьюторов и ИИ

1. Не менять утверждённые решения из `GAME.md` без явного согласования.
2. Не деплоить на VPS и не трогать продакшен без отдельного разрешения.
3. Новые решения фиксировать в `DECISIONS.md`, статусы — в `ROAD.md`.
4. Не отмечать этап `DONE` без прогоненных тестов и доказательств в `ROAD.md`.
