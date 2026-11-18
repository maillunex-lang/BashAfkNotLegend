# ROAD.md — Навигатор статусов

Статусы: `NOT_STARTED` | `IN_PROGRESS` | `BLOCKED` | `DONE`  
`DONE` только при наличии доказательств (тесты/логи/артефакты), не по факту написания кода.

Источник концепции: [GAME.md](GAME.md)  
Visual-first: [VISUAL_FIRST_CURSOR.md](VISUAL_FIRST_CURSOR.md), [docs/visual/VISUAL_ROAD.md](docs/visual/VISUAL_ROAD.md)  
Контекст: [PROJECT_CONTEXT.md](PROJECT_CONTEXT.md) · Решения: [DECISIONS.md](DECISIONS.md)

## Порядок платформ (DEC-003) — приоритет над прежним порядком клиентов

| Фаза | Платформа | Статус | Правило |
|------|-----------|--------|---------|
| **A** | **Android Godot 4** | `IN_PROGRESS` (visual) | Главный приоритет: UI, ассеты, механики, APK, тесты на ≥6 ГБ RAM |
| **B** | **iPhone React/Phaser PWA** | `BLOCKED` | Только после готового Android + **отдельное разрешение** владельца |
| Shared | Go server + contracts + content | `NOT_STARTED` | Общие API/баланс/аккаунты; ассеты проектируются переиспользуемыми для будущей PWA |

Архитектура TECH-001 B (два клиента) **сохраняется** как целевая. Сейчас **не** разрабатывать PWA и не тратить время на iPhone-клиент.

## Сводка: визуальный трек (перед массовыми механиками)

| ID | Этап | Статус | Платформа | Док |
|----|------|--------|-----------|-----|
| VIS-00 | Арт-библия **Anime Fantasy 2D** + эталоны | `DONE` (V1) | DEC-012 VISUAL-APPROVAL-001 | [docs/visual/ART_BIBLE.md](docs/visual/ART_BIBLE.md) |
| VIS-00e | Бой E + Браксор/Никсара anime | `DONE` | Approved + правки DEC-008 | concepts/ |
| VIS-00b | Godot prototype 2v2 + screenshot/video | `DONE` (на review) | Evidence в artifacts | `apps/android-godot/` |
| BATTLE-POLISH-002 | Facing/slots/YSort/speed x1 | `DONE` | Formation 2+3 + facing | `apps/android-godot/` |
| PLAY-LOOP-001 | Меню → отряд → коллекция → 5v5 бой | `DONE` | offline GameState | `scenes/ui/*` + Battle spawn |
| VIS-APPROVAL-001 | Универсальная система анимаций/направлений | `DONE` (foundation) | flip + AbilityCatalog + Formation | DEC-012 |
| MASS-01 | 8 героев (Урал+Лес) | `DONE` | packed | `content/hero_roster_batch01.json` |
| MASS-02 | 8 героев (Тёмные+Небожители) | `DONE` | packed | `content/hero_roster_batch02.json` |
| MASS-03 | 8 героев (Фаэлис+Древние+Отступники) | `DONE` | packed | `content/hero_roster_batch03.json` |
| MASS-04 | финал 30 (Равенкор, Мелтрис, Флинтар) | `DONE` | packed 30/30 | `content/hero_roster_batch04.json` |
| VIS-01…09 | UI → герои → бои → карта → бестиарий → … | `NOT_STARTED` | Godot Android Showcase | [VISUAL_ROAD.md](docs/visual/VISUAL_ROAD.md) |

**После VISUAL-APPROVAL-001 (DEC-012):** графика/анимации V1 утверждены. Приоритет — универсальная система facing/анимаций и поэтапные партии ассетов с проверкой направления. Не бесконечно полировать одного героя. PWA не разрабатывается.

## Сводка: механики (TECH-005 B) — после visual gate на Android

| ID | Этап | Статус | Зависимости | Док |
|----|------|--------|-------------|-----|
| 00 | Проектирование и фундамент | `IN_PROGRESS` | — | пакет docs |
| 01 | Герои и коллекция | `NOT_STARTED` | 00 + VIS gate | [docs/stages/01-heroes.md](docs/stages/01-heroes.md) |
| 02 | Боевая система | `NOT_STARTED` | 01 | [docs/stages/02-combat.md](docs/stages/02-combat.md) |
| 03 | Карта и кампания | `NOT_STARTED` | 02 | [docs/stages/03-world-map.md](docs/stages/03-world-map.md) |
| 04 | Онлайн, чаты и ИИ | `NOT_STARTED` | 03 | [docs/stages/04-online-ai.md](docs/stages/04-online-ai.md) |
| 05 | Гильдии и территориальные войны | `NOT_STARTED` | 04 | [docs/stages/05-guilds.md](docs/stages/05-guilds.md) |
| 06 | VIP, гача, магазин и сезон | `NOT_STARTED` | 01+ | [docs/stages/06-monetization.md](docs/stages/06-monetization.md) |
| 07 | Релиз Android (APK, ops) | `NOT_STARTED` | 01–06 Android | [docs/stages/07-release.md](docs/stages/07-release.md) |
| 08 | **PWA iPhone** (будущий) | `BLOCKED` | Android done + явное разрешение | `apps/ios-pwa/` placeholder only |

Утверждённые механики GDD **не удаляются и не переписываются**. Меняется только порядок платформ и visual-first приоритет.

## Этап 00 — детализация

| Подзадача | Статус | Ссылка |
|-----------|--------|--------|
| Аудит GDD / docs foundation | `DONE` | GAME.md + пакет контрактов |
| Visual-first + Android-first зафиксированы | `DONE` | DEC-003, VISUAL_ROAD |
| VIS-00 арт-библия Anime Fantasy | `DONE` (V1) | DEC-012 VISUAL-APPROVAL-001 |
| Браксор/Никсара anime | `DONE` (V1) | approved combat sprites; swappable later |
| CharacterData / VisualDef split | `DONE` | + AbilityCatalog, BattleFormation |
| Hero roster stubs batch01 | `IN_PROGRESS` | `content/hero_roster_batch01.json` (2 art + 2 stub) |
| Sprite import / facing QA | `DONE` | `tools/check_facing_batch.gd`, `check_sprite_import.gd` |
| Блокирующие BQ (сервер/платежи и т.д.) | `BLOCKED` | DECISIONS — не блокируют арт VIS-00 |
| PWA реализация | `BLOCKED` | ждёт разрешения |
| Docker / игровой серверный код | `NOT_STARTED` | после visual samples + следующих инструкций |

## Зависимости (высокий уровень)

```text
VIS-00 approve ──► VIS-01…09 на Godot Android
                      │
                      ▼
                 Mechanics 01→07 на Android + Go
                      │
                      ▼
                 APK ready / tested
                      │
                      ▼  (только с разрешением)
                 Phase B: React/Phaser PWA (reuse assets + same API)
```
