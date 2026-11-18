# ROAD.md — Навигатор статусов

Статусы: `NOT_STARTED` | `IN_PROGRESS` | `BLOCKED` | `DONE`  
`DONE` только при наличии доказательств (тесты/логи/артефакты), не по факту написания кода.

Источник концепции: [GAME.md](GAME.md)  
Контекст агента: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md)  
Решения: [DECISIONS.md](DECISIONS.md)

## Сводка этапов

| ID | Этап | Статус | Зависимости | Док | Доказательство |
|----|------|--------|-------------|-----|----------------|
| 00 | Проектирование и фундамент | `IN_PROGRESS` | — | этот файл + пакет docs | Документы в репо; блокирующие вопросы в DECISIONS |
| 01 | Герои и коллекция | `NOT_STARTED` | 00 | [docs/stages/01-heroes.md](docs/stages/01-heroes.md) | — |
| 02 | Боевая система | `NOT_STARTED` | 01 | [docs/stages/02-combat.md](docs/stages/02-combat.md) | — |
| 03 | Карта и кампания | `NOT_STARTED` | 02 | [docs/stages/03-world-map.md](docs/stages/03-world-map.md) | — |
| 04 | Онлайн, чаты и ИИ | `NOT_STARTED` | 03 | [docs/stages/04-online-ai.md](docs/stages/04-online-ai.md) | — |
| 05 | Гильдии и территориальные войны | `NOT_STARTED` | 04 | [docs/stages/05-guilds.md](docs/stages/05-guilds.md) | — |
| 06 | VIP, гача, магазин и сезон | `NOT_STARTED` | 01–05 (частично параллельно после 01) | [docs/stages/06-monetization.md](docs/stages/06-monetization.md) | — |
| 07 | Релиз и эксплуатация | `NOT_STARTED` | 01–06 | [docs/stages/07-release.md](docs/stages/07-release.md) | — |

Порядок разработки утверждён как **TECH-005 B** (по системам). Вертикальные срезы — критерии проверки, не замена порядка.

## Этап 00 — детализация

| Подзадача | Статус | Ссылка |
|-----------|--------|--------|
| Аудит GAME.md / мастер-промпта | `DONE` | [GAME.md](GAME.md), [CURSOR_MASTER_PROMPT.md](CURSOR_MASTER_PROMPT.md) |
| Каркас репозитория | `DONE` | `apps/`, `services/`, `packages/`, `infra/`, `tests/`, `assets/` |
| PROJECT_CONTEXT / ROAD / DECISIONS | `DONE` | соответствующие md |
| ARCHITECTURE + ADR | `DONE` | [ARCHITECTURE.md](ARCHITECTURE.md) |
| API_CONTRACT | `DONE` | [API_CONTRACT.md](API_CONTRACT.md) |
| CONTENT_SCHEMA | `DONE` | [CONTENT_SCHEMA.md](CONTENT_SCHEMA.md) |
| ECONOMY | `DONE` | [ECONOMY.md](ECONOMY.md) |
| AI_PLAYERS | `DONE` | [AI_PLAYERS.md](AI_PLAYERS.md) |
| QA_PLAN | `DONE` | [QA_PLAN.md](QA_PLAN.md) |
| docs/stages 01–07 | `DONE` | [docs/stages/](docs/stages/) |
| Блокирующие вопросы (согласование) | `BLOCKED` | [DECISIONS.md](DECISIONS.md) § Blocking |
| Локальный Docker Compose + тестовая БД | `NOT_STARTED` | ждёт согласования стека / секретов |
| Валидация OpenAPI/JSON Schema артефактами | `NOT_STARTED` | контракты описаны текстом; генерация SDK позже |
| Массовая разработка игровых систем | `NOT_STARTED` | сознательно отложена |

**Критерий закрытия 00:** пользователь согласовал блокирующие вопросы; контракты валидны как артефакты; тестовая БД поднимается и сбрасывается локально.

## Зависимости систем (высокий уровень)

```text
00 foundation
 └── 01 heroes/content
      ├── 02 combat (нужны схемы героев/навыков)
      │    └── 03 world/campaign/AFK loop
      │         └── 04 online + AI players
      │              └── 05 guilds + territory wars
      └── 06 monetization (гача/VIP после схем героев; платежи — после юр. решений)
           └── 07 release ops
```

## Ссылки на контракты

- Архитектура: [ARCHITECTURE.md](ARCHITECTURE.md)
- API: [API_CONTRACT.md](API_CONTRACT.md)
- Контент: [CONTENT_SCHEMA.md](CONTENT_SCHEMA.md)
- Экономика: [ECONOMY.md](ECONOMY.md)
- ИИ: [AI_PLAYERS.md](AI_PLAYERS.md)
- QA: [QA_PLAN.md](QA_PLAN.md)
