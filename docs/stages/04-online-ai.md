# Этап 04 — Онлайн, чаты и ИИ-игроки

Статус ROAD: `NOT_STARTED`  
Зависит от: 03 (и закрытие BQ-05/06/08)

## Цель

Единый аккаунт/сессии/каналы; чат+модерация; арена/рейтинги; AI-профили с памятью и библиотекой фраз; пакетная симуляция; телеметрия и rate limits.

## Утверждённые требования

ONLINE-001 C … ONLINE-005 C, ONLINE-003 A (без LLM)  
Ссылки: [GAME.md](../../GAME.md) §2 этап 06, [AI_PLAYERS.md](../../AI_PLAYERS.md)

## Зависимости

Auth; battle snapshots; кошелёк; content phrases.

## UX

- Индикатор канала; чат с rate limit
- Арена: выбор цели, replay
- ИИ всегда с маркером
- Reconnect без потери

## Модель данных

sessions, channels, chat_messages, arena_ratings, ai_profiles, ai_memory, phrase_pack.

## API / события

[API_CONTRACT.md](../../API_CONTRACT.md) §7 + WS chat/presence

## Безопасность

Moderation hooks; rate limits; AI без скрытых PvP buff; токены/сессии.

## Edge cases

Двойной login; spam; пустая библиотека фраз; AI attack quota; channel move mid-chat.

## Производительность

AI batch budget (BQ-08); chat fanout limits; WS connection caps.

## Задачи

- [ ] Channel model
- [ ] Chat + moderation + history
- [ ] Arena async + rating (после BQ-06)
- [ ] AI profiles + scheduler
- [ ] Phrase library seed (сотни → тысячи)
- [ ] Telemetry dashboards (базовые метрики)
- [ ] Sync test двух клиентов одного аккаунта

## Тесты

QA_PLAN §3.04

## Критерии приёмки

Синхронный прогресс; reconnect OK; ИИ обозначены; фразы без спама; разные стратегии без читов; нагрузка VPS ограничена.

## Риски

Перегруз планировщика; «мертвый» чат или спам; смешение AI/human рейтингов.

## Открытые вопросы

BQ-05, BQ-06, BQ-08, BQ-04.
