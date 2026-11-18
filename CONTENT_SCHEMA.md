# CONTENT_SCHEMA.md — Контент и схемы данных

Версия схемы контента: **0.1-draft**. Машиночитаемые JSON Schema — в `packages/content/schemas` после старта реализации.

Утверждено GDD: 6 фракций, 6 классов, 30 героев на релизе, 6 слотов экипировки, отряд 2+3.  
Предварительно (не факт): 2–3 обычных навыка + ультимейт — уточняется балансом.

## 1. Стабильные перечисления

### Фракции (HERO-001 C)

| id | Название |
|----|----------|
| `ural_wardens` | Стражи Урала |
| `forest_spirits` | Лесные духи |
| `dark_creatures` | Тёмные создания |
| `skyborn` | Небожители |
| `ancients` | Древние |
| `renegades` | Отступники |

### Классы (HERO-002 C)

| id | Роль |
|----|------|
| `tank` | Танк |
| `warrior` | Воин |
| `assassin` | Убийца |
| `mage` | Маг |
| `healer` | Целитель |
| `support` | Поддержка/контроль |

### Редкость (черновик)

`R` | `SR` | `SSR` — точные названия/пороги гачи после симуляций (HERO-003 B).

## 2. Герой (каталог контента)

Обязательные поля каталога (на героя):

| Поле | Тип | Правила |
|------|-----|---------|
| `id` | string | Стабильный, `hero.<slug>` |
| `name` | localized string | Оригинальное фэнтезийное имя (не башкирское/русское личное) |
| `faction_id` | enum | Одна из 6 |
| `class_id` | enum | Один из 6 |
| `rarity` | enum | |
| `base_stats` | object | hp, atk, def, spd, … |
| `growth` | object | Рост по уровню/рангу |
| `basic_attack_id` | skill ref | |
| `skill_ids` | skill ref[] | Предв. 2–3 |
| `ultimate_id` | skill ref | |
| `synergy_tags` | string[] | Для BATTLE-005 C |
| `counter_tags` | string[] | Контрпики |
| `quotes` | localized[] | Саркастичный тон, TONE-001 B |
| `portrait_asset` | asset id | |
| `sprite_set_id` | asset id | Покадровые анимации |
| `is_fiction_note` | string? | Если мотив близок к фольклору — пометка вымысла |

На релизе: **ровно 30** валидных героев, по 5 на фракцию (HERO-004 B). Этап 01 начинает с нескольких тестовых.

### Инстанс героя игрока

| Поле | Описание |
|------|----------|
| `instance_id` | UUID |
| `hero_id` | ref каталога |
| `level` | int |
| `rank` | int |
| `shards` | int |
| `equipment` | 6 слотов |
| `talents` | map |
| `awakening` | int/flags |

## 3. Навыки и эффекты

```text
Skill {
  id, name, type: basic|active|ultimate,
  energy_cost, cooldown_ticks?,
  targeting: self|ally|allies|enemy|enemies|row|...,
  effects: Effect[]
}

Effect {
  kind: damage|heal|shield|buff|debuff|control|summon|special,
  formula_id | flat params,
  duration_ticks?,
  tags[]
}
```

Правила:

- Нет ссылок на несуществующие skill/effect/asset.
- Ультимейт: энергия + опциональный ручной trigger (BATTLE-002 C).
- Синергии описываются данными (фракция/класс/позиция/скилл-теги), считаются сервером.

## 4. Экипировка (AFK-003 C)

- 6 слотов (предложение имён до утверждения баланса): `weapon`, `armor`, `helm`, `boots`, `accessory`, `relic`.
- Редкости, заточка, комплекты, уникальные эффекты — таблицы контента.
- Эффекты комплектов не должны создавать циклические эксплойты с резонансом (AFK-002 C).

## 5. Резонанс (AFK-002 C)

- 5 основных прокачиваемых героев.
- Остальные синхронизируют уровень через слоты резонанса.
- Запрещены циклы «A бустит B → B бустит A» через экип/таланты; валидатор схемы + серверные инварианты.

## 6. Карта и кампания

```text
CampaignChapter { id, order, title, node_ids[] }
CampaignNode { id, region_id, type, battle_ref?, unlock_rules, rewards }
Region { id, geo_label, art_asset, activities[], bosses[] }
Dialogue { id, speakers[], lines[], tone_tags[], fiction_flags[] }
```

- География узнаваема, художественно адаптирована (MAP-001 C).
- Примеры узлов из GAME.md не считать финальными до BQ-09 / сценарной библии.
- Сюжет: печать → последствия → виновник → фракции → угроза → сезон (STORY-001 C).

## 7. Диалоги и культурная проверка

- Каждая реплика с мифологическим мотивом: `source_inspiration?` + `fiction: true` при авторском переосмыслении.
- Юмор не обесценивает реальные традиции (TONE-001 B).
- Локализация: ключи строк; язык v1 — BQ-04.

## 8. Ассеты

| Тип | Требование |
|-----|------------|
| Портрет | Стабильный id, размерные пресеты |
| Sprite set | Кадры idle/attack/skill/ult/hit/death (+ иные по нужде) |
| VFX | Бюджет для слабых Android |
| Map layers | Фон / parallax / интерактивные точки |
| Manifest | path, hash, size, content_version |

Исполняемый код не доставляется через asset pipeline (TECH-004 C).

## 9. Валидация

Пайплайн (этап 01+):

1. JSON Schema validate.
2. Referential integrity (skills, assets, factions).
3. Ровно 5 героев на фракцию в релизе-наборе.
4. Нет orphan assets в export-наборе боя.
5. Контент публикуется атомарно с `content_version`.

Клиенты и сервер отклоняют несовместимые версии (`CONTENT_VERSION_MISMATCH`).
