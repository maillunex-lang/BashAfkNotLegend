# QA_PLAN.md — Стратегия качества

Связано с критериями [GAME.md](GAME.md) §7 и приёмками этапов в `docs/stages/`.

## 1. Пирамида

| Уровень | Где | Фокус |
|---------|-----|-------|
| Unit | `services/game-server`, packages | Формулы боя, экономика, валидаторы схем, pity |
| Integration | `tests/integration` | API + Postgres, идемпотентность, гильдии |
| Contract | `packages/contracts` | OpenAPI/Schema совместимость клиентов |
| E2E | `tests/e2e` | Сквозные сценарии на PWA (+ позже Godot export) |
| Load | `tests/load` | AI scheduler, chat, battles на лимитах VPS |
| Device | ручные/полуавтомат | Android 6 ГБ RAM, iPhone Safari PWA |

`DONE` в ROAD только при доказательствах прогона.

## 2. Обязательные инварианты (регрессия всегда)

1. Один аккаунт → одинаковый прогресс на обоих клиентах.
2. Повтор claim/purchase/pull с тем же ключом не дублирует ресурсы.
3. Одинаковый seed + вход → одинаковый battle result.
4. Skip / x3 не меняют серверный исход.
5. Контент без битых ссылок; 30 героев валидны на релизе.
6. Гача соответствует опубликованным таблицам (стат-тест).
7. AFK cap/VIP корректны при TZ change и offline.
8. ИИ помечены; антиспам; нет PvP combat-чита.
9. Гильдия ≤30; территория — один владелец на epoch.
10. Reconnect без потери прогресса.
11. Admin mutations audited + rollback path.
12. Перед релизом: real devices + load + DB restore.

## 3. По этапам (минимальный набор)

### 00 Foundation
- Документы связаны из ROAD.
- (После реализации) compose up → migrate → reset DB script.

### 01 Heroes
- Schema reject invalid hero.
- Rank-up/equip persist; idempotent.
- Один и тот же герой в read-model для будущего Godot/PWA stub.

### 02 Combat
- Golden seed fixtures.
- Ult command validation.
- Synergy unit tests.
- Perf smoke на слабом профиле (метрики, без обещания FPS).

### 03 World
- Region unlock gates.
- AFK claim independent of device clock.
- Loop: login → battle → reward → upgrade → next node.

### 04 Online/AI
- Session resume.
- AI marker.
- Phrase cooldown.
- Rate limit chat.

### 05 Guilds
- 31st member rejected.
- Territory ownership atomic.
- Diplomacy expiry + history.
- AI map share cap.

### 06 Monetization
- Statistical gacha tests.
- Payment idempotency + refund accounting (когда включено).
- Free VIP XP path proof.
- No pay-only combat power asserts.

### 07 Release
- APK install; PWA install on iPhone.
- Asset manifest download/cache.
- Backup restore drill.
- Rollback checklist executed in staging (после разрешения).

## 4. Инструменты (предложение)

- Go: `go test`, race detector на критичных пакетах.
- Contract: spectral/openapi-generator или аналог.
- E2E PWA: Playwright.
- Load: k6 или vegeta.
- Godot: scene smoke + позже device farm/manual.
- CI: на каждый push в main — unit + integration (когда появятся).

## 5. Доказательства в ROAD

Для перевода статуса в `DONE` указывать:

- команда прогона;
- дата;
- ссылка на лог/артефакт (`tests/…`, CI run URL);
- известные пробелы (если есть) — иначе не `DONE`.

## 6. Риски качества (этап 00)

| Риск | Митигация |
|------|-----------|
| Дрейф двух клиентов | Общий battle protocol + generated SDK |
| Недерминизм боя | Фикстуры seed, запрет time.Now в sim без clock port |
| Safari PWA сюрпризы | Ранние device checks на 04/07, не только desktop |
| ИИ нагрузка | Budget + feature flags + load tests |
| Монетизация/юридика | Feature flag payments; BQ-02/03 |
