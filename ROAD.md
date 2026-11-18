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
| VIS-00 | Арт-библия **Anime Fantasy 2D** + эталоны | `IN_PROGRESS` | Android-first art | [docs/visual/ART_BIBLE.md](docs/visual/ART_BIBLE.md) |
| VIS-00e | Бой E + Браксор/Никсара anime | `IN_PROGRESS` | **Approve 3 кадров** | `assets/source/concepts/` |
| VIS-00b | Godot: 2 аним. героя + HUD + запись | `NOT_STARTED` | После approve E | apps/android-godot |
| VIS-01…09 | UI → герои → бои → карта → бестиарий → … | `NOT_STARTED` | Godot Android Showcase | [VISUAL_ROAD.md](docs/visual/VISUAL_ROAD.md) |

**Стоп-гейт сейчас (DEC-007):** утвердить стиль Anime Fantasy + 3 кадра (бой E, Браксор anime, Никсара anime). Side-view layout (DEC-005) сохранён. Массовая генерация и Godot — после approve. PWA не разрабатывается.

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
| VIS-00 арт-библия Anime Fantasy | `IN_PROGRESS` | DEC-007; эталоны E на review |
| Браксор/Никсара anime | `IN_PROGRESS` | review; v1 realistic archived |
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
