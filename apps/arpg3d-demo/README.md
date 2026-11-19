# ARPG 3D Archer Demo (standalone)

Отдельный Godot 4.3 демо-проект **без привязки** к «Башкирия».

## Что внутри

Каждый 3D-элемент собран отдельным билдером:

| Часть | Скрипт |
|-------|--------|
| Арена | `scripts/parts/arena_builder.gd` |
| Лучник | `scripts/parts/archer_builder.gd` |
| Лук | `scripts/parts/bow_builder.gd` |
| Обычная стрела | `scripts/parts/arrow_builder.gd` |
| Ледяная стрела | `scripts/parts/ice_arrow_builder.gd` |
| Враг | `scripts/parts/enemy_builder.gd` |
| Freeze VFX | `scripts/parts/freeze_vfx_builder.gd` |

Бой: лучник стреляет автоматически; **каждый 3-й выстрел** — ледяная стрела со спецэффектом и заморозкой врага.

## Запуск

```bash
godot --path apps/arpg3d-demo \
  --display-driver x11 --rendering-driver opengl3 --rendering-method gl_compatibility \
  --resolution 1280x720
```

Демо с автовыходом:

```bash
ARPG_DEMO_QUIT=1 ARPG_DEMO_SECONDS=14 \
  ARPG_SCREENSHOT_PATH=/tmp/arpg3d.png \
  godot --path apps/arpg3d-demo --resolution 1280x720 \
  --rendering-driver opengl3 --rendering-method gl_compatibility
```
