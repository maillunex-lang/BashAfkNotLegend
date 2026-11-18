# ARCHITECTURE.md — Системная схема и ADR

Связано: [GAME.md](GAME.md) §6, [API_CONTRACT.md](API_CONTRACT.md), [ROAD.md](ROAD.md)

## 1. Контекст

Два клиента (Godot Android + React/Phaser PWA) и админка работают против одного авторитетного Go-сервера. Клиенты визуализируют и собирают ввод; сервер владеет состоянием, RNG, боем, экономикой, ИИ и гильдиями.

## 2. Логическая схема

```text
┌─────────────────┐   ┌─────────────────┐   ┌─────────────────┐
│ Godot 4 Android │   │ React+Phaser PWA│   │ Admin (React/TS)│
└────────┬────────┘   └────────┬────────┘   └────────┬────────┘
         │ HTTPS REST + WS     │                     │ Admin API
         └──────────┬──────────┘                     │ (RBAC)
                    ▼                                ▼
         ┌──────────────────────────────────────────────────┐
         │              game-server (Go)                    │
         │  auth · players · heroes · inventory · economy   │
         │  battle sim · AFK · chat · AI scheduler          │
         │  guild/war scheduler · gacha · content gate      │
         └───────────────┬──────────────────┬───────────────┘
                         │                  │
                         ▼                  ▼
                  PostgreSQL         Asset store (Caddy/CDN)
                  (state of truth)   versioned manifest/hash
```

## 3. Границы систем

| Система | Владелец истины | Клиентская роль |
|---------|-----------------|-----------------|
| Аккаунт / сессия | Server | Хранение токена, re-auth |
| Герои / инвентарь / экипировка | Server | UI, локальный кэш read-model |
| Бой | Server simulator + battle log | Playback событий, ввод ультимейта |
| AFK / задания / награды | Server timers | Claim UI; не локальный расчёт |
| Чат | Server + moderation | Отправка/отображение |
| ИИ-игроки / ИИ-гильдии | Server scheduler | Только отображение помеченных сущностей |
| Гача / VIP / платежи | Server | Запрос покупки / отображение |
| Контент (баланс, тексты) | Server published version | Загрузка по version/hash |
| Ассеты | Manifest на сервере/CDN | Докачка и кэш |

## 4. Компоненты репозитория

| Путь | Роль |
|------|------|
| `services/game-server` | HTTP/WS API, домен, симуляторы, воркеры |
| `packages/contracts` | OpenAPI + JSON Schema → генерация SDK |
| `packages/content` | Версионированные JSON/YAML контента |
| `infra/migrations` | SQL schema evolution |
| `infra/docker` | Локальный Postgres + сервер (+ опц. Caddy) |
| `apps/android-godot` | Android UI + battle presentation |
| `apps/ios-pwa` | PWA UI + Phaser battle presentation |
| `apps/admin` | RBAC tools + visual studio |
| `tests` | Integration / E2E / load |

## 5. Данные и согласованность

- **Идентификаторы:** UUID (или ULID) для сущностей игрока; стабильные string ID для контента (`hero.ural_warden_01`).
- **Идемпотентность:** claim AFK, purchase, gacha pull, battle submit используют `Idempotency-Key` / уникальные operation id.
- **Транзакции:** выдача наград и списание валют — в одной DB-транзакции; владение территорией — атомарный update с epoch/version.
- **События боя:** append-only battle log; клиенты не «досчитывают» исход.
- **Контент:** `content_version` + checksum; клиент отказывается запускать бой при несовместимой версии правил.

## 6. Безопасность (черновик схемы)

- TLS everywhere; refresh/access tokens; admin RBAC + audit log.
- Rate limits: auth, chat, gacha, battle start, admin write.
- Anti-cheat: серверный бой; валидация ультимейта по тику/энергии; отклонение клиентских «результатов».
- Секреты через env; никаких ключей в git.
- Обновление ассетов: только данные/ресурсы по manifest; исполняемый код Android — новый APK (TECH-004 C).
- PWA: HTTPS, SW cache isolation, не исполнять удалённый произвольный JS как «патч игры» без review-процесса.

## 7. Наблюдаемость и эксплуатация

- Health: `/healthz`, `/readyz` (DB connectivity).
- Метрики: CPU/RAM, latency API, длина очереди AI/war scheduler, ошибки боя, claim AFK.
- Логи: structured JSON; correlation id на запрос; без PII в открытом виде где возможно.
- Бэкапы Postgres + проверенный restore (этап 07).
- Деплой только после явного разрешения владельца.

## 8. ADR

### ADR-001 — Два клиента, один сервер
- Статус: Accepted (TECH-001 B, TECH-002 A)
- Решение: Godot Android + React/Phaser PWA; общий API.
- Следствие: единый battle event protocol; дублирование UI-логики минимизировать контрактами/SDK.

### ADR-002 — Авторитетный Go battle simulator
- Статус: Accepted (BATTLE-*, TECH-002 A)
- Решение: детерминированный симулятор на сервере; клиенты playback.
- Следствие: одинаковый seed → одинаковый исход; skip не меняет результат.

### ADR-003 — ИИ без LLM
- Статус: Accepted (ONLINE-003 A)
- Решение: библиотека фраз + правила + планировщик.
- Следствие: контент-пайплайн для тысяч реплик; антиспам обязателен.

### ADR-004 — Разработка по системам
- Статус: Accepted (TECH-005 B)
- Решение: порядок 01→07 по системам; E2E-срезы как приёмка.
- Следствие: не начинать гильдии/монетизацию до базовых героев/боя без согласования.

### ADR-005 — Документация до массового кода
- Статус: Accepted (DEC-002)
- Решение: этап 00 закрывает контракты и блокеры до широкой реализации.
- Следствие: каталоги кода могут существовать пустыми/с README до старта 01.

### ADR-006 — Локальный Compose как эталон среды
- Статус: Proposed (реализация после BQ / разрешения на код фундамента)
- Решение: `infra/docker` поднимает Postgres (+ сервис); миграции идемпотентно накатываются; тестовая БД сбрасывается скриптом.
- Следствие: CI и разработчики используют один compose-файл.
