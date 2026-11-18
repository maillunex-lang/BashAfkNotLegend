# API_CONTRACT.md — REST / WebSocket

Версия контракта: **0.1-draft** (этап 00). Машиночитаемый OpenAPI появится в `packages/contracts` после закрытия BQ-01 и старта фундамента.

Базовый префикс REST: `/v1`  
WebSocket: `/v1/ws`  
Формат: JSON, UTF-8  
Время: RFC3339 UTC  
Ошибки: единый envelope (ниже)

Связано: [ARCHITECTURE.md](ARCHITECTURE.md), [CONTENT_SCHEMA.md](CONTENT_SCHEMA.md)

## 1. Общие заголовки

| Header | Назначение |
|--------|------------|
| `Authorization: Bearer <access>` | Игровые и админ API |
| `X-Client-Platform: android\|ios-pwa\|admin` | Телеметрия / политики |
| `X-Client-Version: semver` | Совместимость |
| `X-Content-Version: string` | Версия правил/контента у клиента |
| `Idempotency-Key: uuid` | Мутации наград/платежей/гачи/claim |
| `X-Request-Id: uuid` | Корреляция логов |

## 2. Envelope ошибок

```json
{
  "error": {
    "code": "BATTLE_ULT_NOT_READY",
    "message": "Ultimate not available at this tick",
    "details": { "hero_id": "...", "tick": 42 },
    "request_id": "..."
  }
}
```

| HTTP | Типичные code |
|------|----------------|
| 400 | `VALIDATION_FAILED`, `SCHEMA_INVALID` |
| 401 | `UNAUTHORIZED` |
| 403 | `FORBIDDEN`, `RBAC_DENIED` |
| 404 | `NOT_FOUND` |
| 409 | `CONFLICT`, `IDEMPOTENCY_REPLAY`, `GUILD_FULL`, `TERRITORY_OWNED` |
| 429 | `RATE_LIMITED` |
| 500 | `INTERNAL` |
| 503 | `CONTENT_VERSION_MISMATCH`, `MAINTENANCE` |

## 3. Auth (черновик — ждёт BQ-01)

| Method | Path | Описание |
|--------|------|----------|
| POST | `/v1/auth/register` | Создание аккаунта (если password flow) |
| POST | `/v1/auth/login` | Выдача access/refresh |
| POST | `/v1/auth/refresh` | Обновление токена |
| POST | `/v1/auth/logout` | Инвалидация сессии |
| GET | `/v1/me` | Профиль, канал, VIP, флаги |

Гостевой bind / OAuth — добавить после выбора BQ-01.

## 4. Player state & heroes

| Method | Path | Описание |
|--------|------|----------|
| GET | `/v1/me/state` | Сводка: валюты, AFK pending, флаги онбординга |
| GET | `/v1/heroes` | Коллекция игрока |
| GET | `/v1/heroes/{instanceId}` | Карточка героя |
| POST | `/v1/heroes/{instanceId}/rank-up` | Ранг (серверные затраты) |
| POST | `/v1/heroes/{instanceId}/equip` | Экипировка слота |
| GET | `/v1/roster` | Активный отряд 5 слотов (2+3) |
| PUT | `/v1/roster` | Установка состава + позиций |
| GET | `/v1/inventory` | Предметы / осколки |
| GET | `/v1/resonance` | 5 основных + слоты синхронизации |

Все мутации валидируют схемы контента; повтор с тем же Idempotency-Key не дублирует ресурсы.

## 5. Battle

| Method | Path | Описание |
|--------|------|----------|
| POST | `/v1/battles` | Старт боя (campaign/tower/pvp/…); возвращает `battle_id`, `seed`, snapshot |
| GET | `/v1/battles/{id}` | Метаданные + статус |
| GET | `/v1/battles/{id}/log` | Полный event log для playback |
| POST | `/v1/battles/{id}/commands` | Ручной ультимейт / переключатель auto-ult (валидация тика) |
| POST | `/v1/battles/{id}/skip` | Skip только если разрешён; результат = серверная симуляция |

### Battle event protocol (общий для Godot и Phaser)

События — упорядоченный поток:

```json
{ "seq": 1, "tick": 0, "type": "battle_start", "payload": { } }
{ "seq": 2, "tick": 12, "type": "skill_cast", "payload": { "actor": "...", "skill_id": "...", "targets": [] } }
{ "seq": 3, "tick": 12, "type": "damage", "payload": { "target": "...", "amount": 120, "flags": ["crit"] } }
{ "seq": 4, "tick": 200, "type": "battle_end", "payload": { "result": "win", "rewards_op": "..." } }
```

Клиент **не** пересчитывает HP как источник истины; может интерполировать VFX, но итог берёт из `battle_end`.

Скорости x1/x2/x3 — только клиентский playback rate.

## 6. World / AFK / progression

| Method | Path | Описание |
|--------|------|----------|
| GET | `/v1/campaign` | Главы, узлы, прогресс |
| POST | `/v1/campaign/nodes/{nodeId}/enter` | Вход в узел → может создать battle |
| GET | `/v1/map/regions` | Открытые регионы и активности |
| GET | `/v1/afk` | Накопленное (серверное время) |
| POST | `/v1/afk/claim` | Идемпотентная выдача |
| GET | `/v1/quests` | Daily/weekly |
| POST | `/v1/quests/{id}/claim` | Claim награды |

AFK не зависит от часов устройства (AFK-001 C / GAME §5).

## 7. Online / chat / PvP

| Method | Path | Описание |
|--------|------|----------|
| GET | `/v1/channels` | Доступные каналы |
| POST | `/v1/chat/messages` | Отправка (rate limit + moderation) |
| GET | `/v1/chat/history` | История канала/гильдии |
| GET | `/v1/arena/status` | Сезон, рейтинг |
| POST | `/v1/arena/attack` | Асинхронная атака по снимку защиты |
| GET | `/v1/arena/history` | Результаты |

ИИ-участники всегда с `is_ai: true` и отображаемым маркером.

## 8. Guilds & wars

| Method | Path | Описание |
|--------|------|----------|
| POST | `/v1/guilds` | Создать |
| POST | `/v1/guilds/{id}/join` | Вступить / принять заявку |
| POST | `/v1/guilds/{id}/leave` | Выход + cooldown |
| GET | `/v1/guilds/{id}` | Профиль, роли, ≤30 members |
| GET | `/v1/territories` | Карта районов |
| POST | `/v1/wars/{id}/actions` | Действия в окне атаки |
| GET | `/v1/diplomacy` | Договоры/союзы/история |

`GUILD_FULL` при попытке 31-го участника. Смена владельца территории — атомарно с `epoch`.

## 9. Economy / VIP / gacha / shop

| Method | Path | Описание |
|--------|------|----------|
| GET | `/v1/wallet` | Валюты |
| GET | `/v1/gacha/banners` | Баннеры + публичные вероятности |
| POST | `/v1/gacha/pull` | Серверный RNG + pity |
| GET | `/v1/gacha/history` | Аудит призывов |
| GET | `/v1/vip` | Уровень, XP, привилегии |
| GET | `/v1/shop` | Офферы |
| POST | `/v1/shop/purchase` | Идемпотентная покупка (после BQ-02/03) |
| GET | `/v1/battlepass` | Сезонный пропуск |

До согласования платежей эндпоинты shop могут быть stub + feature flag.

## 10. Content & assets

| Method | Path | Описание |
|--------|------|----------|
| GET | `/v1/content/manifest` | content_version, schemas, hashes |
| GET | `/v1/assets/manifest` | Список ассетов + hash + URL |

## 11. Admin API (отдельный mount)

Префикс: `/admin/v1`  
Auth: admin roles (RBAC). Все мутации пишут audit.

Черновые ресурсы: players, ai profiles, guilds, balance tables, VIP, shop, map, events, assets publish, content rollback.

## 12. WebSocket события

Подписка после auth frame:

| event | Назначение |
|-------|------------|
| `chat.message` | Новое сообщение |
| `battle.command_ack` | Подтверждение ультимейта |
| `afk.updated` | Изменение pending (опционально) |
| `guild.member` | Изменения состава |
| `war.phase` | Смена фазы войны |
| `presence.kick` | Принудительный logout |

Переподключение: клиент запрашивает snapshot REST + догоняет seq где применимо; прогресс не теряется (критерий качества №10).

## 13. Версионирование

- Ломающие изменения API → `/v2` или согласованный deprecation window.
- Правила боя версионируются `ruleset_version` внутри battle snapshot.
- SDK клиентов генерируются из `packages/contracts`, не копируются вручную.
