# Этап 02 — Боевая система

Статус ROAD: `NOT_STARTED`  
Зависит от: 01

## Цель

Детерминированный Go-симулятор 5v5 (2+3), энергия/ультимейты, эффекты, server battle logs, визуализация спрайтами в Godot и Phaser, скорости x1/x2/x3, разрешённый skip.

## Утверждённые требования

BATTLE-001 B … BATTLE-005 C, BATTLE-003 A (только 2D спрайты), TECH-002 A  
Ссылки: [GAME.md](../../GAME.md) §2 этап 04, §5 бой

## Зависимости

Схемы героев/навыков; roster API; content_version/ruleset_version.

## UX

- Расстановка до боя (если режим позволяет)
- Автобой + toggle ручных ультимейтов
- Кнопки скорости; skip когда разрешён
- Playback событий без расхождения с сервером

## Модель данных

`battles`, `battle_events` (или blob log), `defense_snapshots` (заготовка под PvP).  
Вход симулятора: seed, ruleset, две команды со статами/эффектами.

## API / события

[API_CONTRACT.md](../../API_CONTRACT.md) §5 — start, log, commands, skip; event protocol общий.

## Безопасность

Команды ультимейта валидируются по tick/energy; клиентский «результат» игнорируется; PvP skip не меняет симуляцию.

## Edge cases

Ничья/таймаут; смерть до ульта; simultaneous cast order; reconnect mid-battle; несовместимый ruleset.

## Производительность

Симулятор CPU-bound: бенч на N боёв/сек; клиент — атласы, pooling, VFX budget (BQ-10).

## Задачи

- [ ] Спека тика/очереди/энергии
- [ ] Реализация simulator + golden fixtures
- [ ] API battle + log storage
- [ ] Phaser playback
- [ ] Godot playback
- [ ] Synergy tests
- [ ] Skip/speed policy
- [ ] Perf smoke Android profile

## Тесты

QA_PLAN §3.02 + seed replay identity.

## Критерии приёмки

Одинаковый seed → одинаковый исход; оба клиента из одного протокола; ручной ульт валидируется; синергии покрыты тестами; есть замер нагрузки на слабом Android.

## Риски

Рассинхрон визуала и log; скрытый nondeterminism (map iteration, float); перерасход RAM на спрайтах.

## Открытые вопросы

BQ-10; точная длительность тика; политика ничьей.
