# apps/android-godot

Godot 4.3 Android-first клиент. Стиль: **Bashkir Anime Sarcastic Fantasy 2D** (DEC-007/008).

## Прототип боя (VIS-00b)

Сцена: `scenes/battle/BattlePrototype.tscn`

Состав:
- Браксор (front) + Никсара (back)
- Камнегрыз + Теневолк
- Многослойный фон, AnimatedSprite2D клипы (idle/attack/hit/personality/ultimate)
- HUD: WAVE/timer/pause/x1–x3/Auto + портреты игрока с энергией ульта

### Локальный запуск (desktop preview)

```bash
godot --path apps/android-godot --resolution 1080x1920 \
  --rendering-driver opengl3 --rendering-method gl_compatibility
```

На CI/Xvfb без Vulkan используйте `opengl3` + software GL (`LIBGL_ALWAYS_SOFTWARE=1`).

PWA не разрабатывается (DEC-003).
