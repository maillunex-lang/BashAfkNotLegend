# apps/android-godot

Godot 4.3 Android-first клиент. Стиль: **Bashkir Anime Sarcastic Fantasy 2D** (DEC-007/008).

## Играбельный цикл (offline)

`MainMenu` → **Кампания** (`WorldMap`) / стычка / отряд / коллекция → бой → результат.

- Глава 1: `content/campaign_chapter01.json` (Уфа→Сибай, примеры из GAME.md).
- Победа на узле: золото + AFK rate; save в `user://bash_save_v1.json`.
- AFK claim — **offline mock** (серверное время — после BQ).
- Autoload `GameState`; бой спавнит `Fighter.tscn` из registry.
- 30 героев CHARACTER_BIBLE packed; V1 не ремейкались.

### Локальный запуск (desktop preview)

```bash
godot --path apps/android-godot --resolution 1080x1920 \
  --rendering-driver opengl3 --rendering-method gl_compatibility
```

Прямой бой (CI/demo):

```bash
BASH_DEMO_QUIT=1 BASH_DEMO_SECONDS=12 BASH_SCREENSHOT_PATH=/tmp/battle.png \
  godot --path apps/android-godot res://scenes/battle/BattlePrototype.tscn \
  --resolution 1080x1920 --rendering-driver opengl3 --rendering-method gl_compatibility
```

На CI/Xvfb без Vulkan: `opengl3` + `LIBGL_ALWAYS_SOFTWARE=1`.

### Данные персонажа (VISUAL-APPROVAL-001)

- `CharacterData` — логика/баланс/ID способностей  
- `CharacterVisualDef` — спрайты, `source_facing`, attach points  
- `AbilityCatalog` — ID → kit/анимации/VFX (**без** путей PNG)  
- QA: `godot --headless -s res://tools/check_facing_batch.gd`  
- Import QA: `godot --headless -s res://tools/check_sprite_import.gd`  
- Rosters: `content/hero_roster_batch01…04.json`  
- Formation: `BattleFormation` (2 front + 3 back, both sides)  
- PvP side-swap: `BASH_SWAP_SIDES=1` или `tools/run_pvp_swap_demo.sh`

PWA не разрабатывается (DEC-003).
