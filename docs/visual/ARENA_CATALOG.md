# ARENA_CATALOG.md

## VIS-00 — три концепта одного боевого поля (стоп на выбор)

Одинаковая задача: вертикаль 9:16, формация 5v5 (2+3), HUD ультимейтов, читаемость персонажей.

| ID | Стиль | Файл | Статус |
|----|-------|------|--------|
| `arena.concept.a` | A — живописная иллюстрация | `assets/source/concepts/battle/battle_concept_a.jpg` | generated → **review** |
| `arena.concept.b` | B — яркое фэнтези, сильный контраст | `assets/source/concepts/battle/battle_concept_b.jpg` | generated → **review** |
| `arena.concept.c` | C — атмосферное muted | `assets/source/concepts/battle/battle_concept_c.jpg` | generated → **review** |

После выбора владельца: зафиксировать DEC и строить 8 арен в том же визуальном языке (Godot Android).

## 8 тематических арен (план после approve)

| ID | Название | Мотивы |
|----|----------|--------|
| `arena.ufa_citadel` | Уфимская Цитадель | стены, медные крыши, вечер |
| `arena.belaya_valley` | Долина Белой | Агидель, луга, туман |
| `arena.sterlitamak_shikhans` | Стерлитамакские Шиханы | холмы, камень |
| `arena.beloretsk_pass` | Белорецкий Перевал | горы, хвоя, ветер |
| `arena.sibay_rift` | Сибайский Разлом | руда, кристаллы |
| `arena.shurale_woods` | Лес Шурале | кривые деревья, светлячки |
| `arena.ubyr_mire` | Болота Убыра | вода, туман |
| `arena.ancient_seal_ruins` | Руины Древней Печати | кольца, руны |

Каждая: far/mid/ground/near, spawn points, VFX zones, parallax, low-quality preset, thumbnail. Камера фиксированная. Передний план не перекрывает бойцов.
