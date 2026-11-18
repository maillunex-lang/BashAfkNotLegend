extends Node2D
class_name Fighter

## Facing model (BATTLE-POLISH-002):
## source_facing  = direction on the source PNG
## desired_facing = direction we want in battle (usually toward target)
## battle_side    = which half of the field this fighter occupies (LEFT/RIGHT)
## flip_h         = (source_facing != desired_facing)  — applied ONLY on the sprite

signal died(fighter)
signal energy_changed(fighter, value, max_value)
signal hp_changed(fighter, value, max_value)
signal ult_ready(fighter)
signal dealt_hit(fighter, target, amount, is_crit)
signal animation_finished(fighter, anim_name)

enum Style { TANK, ASSASSIN, BRUTE, BEAST }
enum Facing { LEFT, RIGHT }
enum BattleSide { LEFT, RIGHT }

@export var fighter_id: String = ""
@export var display_name: String = ""
@export var team: String = "player" # player | enemy — identity only, NOT facing
@export var is_front_row: bool = true
@export var max_hp: float = 1000.0
@export var max_energy: float = 100.0
@export var attack_power: float = 120.0
@export var sprite_folder: String = ""
@export var style: Style = Style.TANK
@export var preferred_range: float = 110.0
@export var move_speed: float = 48.0
@export var personal_space: float = 70.0
@export var source_facing: Facing = Facing.RIGHT
@export var battle_side: BattleSide = BattleSide.LEFT
@export var show_facing_debug: bool = true

var hp: float
var energy: float = 40.0
var alive: bool = true
var busy: bool = false
var desired_facing: Facing = Facing.RIGHT
var current_target: Fighter = null
var home_y: float = 0.0
var attack_cd: float = 0.0
var skill_cd: float = 0.0
var foot_offset_y: float = 0.0 # feet at node origin for YSort
var reserved_slot: Vector2 = Vector2.ZERO
var has_reserved_slot: bool = false
var knockback_vel: Vector2 = Vector2.ZERO

@onready var body: Node2D = $Body
@onready var sprite: AnimatedSprite2D = $Body/AnimatedSprite2D
@onready var shadow: Polygon2D = $Shadow
@onready var ui: Node2D = $UI
@onready var hp_bar: ProgressBar = $UI/HPBar
@onready var name_label: Label = $UI/NameLabel
@onready var vfx: Sprite2D = $Body/VFX

func _ready() -> void:
	hp = max_hp
	home_y = global_position.y
	desired_facing = Facing.RIGHT if battle_side == BattleSide.LEFT else Facing.LEFT
	# Never flip the Body node — only the sprite. Prevents double-mirror + UI flip.
	body.scale = Vector2.ONE
	scale = Vector2.ONE
	sprite.flip_h = false
	_build_frames()
	_apply_facing()
	_update_bars()
	name_label.text = display_name
	play_anim("idle")
	vfx.visible = false
	if show_facing_debug:
		_ensure_dir_arrow()
	_update_depth()

func _process(_delta: float) -> void:
	_update_depth()
	# Keep UI upright / unflipped regardless of sprite.flip_h
	ui.scale = Vector2.ONE
	ui.global_rotation = 0.0
	body.scale = Vector2.ONE # hard guard against accidental parent flips
	_apply_facing()
	_sync_dir_arrow()
	if knockback_vel.length() > 0.5:
		global_position += knockback_vel * _delta
		knockback_vel = knockback_vel.lerp(Vector2.ZERO, clampf(6.0 * _delta, 0.0, 1.0))

func foot_y() -> float:
	return global_position.y + foot_offset_y

func _update_depth() -> void:
	# YSort on parent uses position.y; also set z_index from foot for non-YSort parents.
	z_as_relative = true
	z_index = 0
	# Shadow / body stay with fighter; UI drawn above all fighters.
	ui.z_as_relative = false
	ui.z_index = 4000
	shadow.z_as_relative = true
	shadow.z_index = -1

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	var base := "res://assets/sprites/%s/" % sprite_folder
	var mapping := {
		"idle": _existing(base, ["idle.png"]),
		"walk": _existing(base, ["walk_0.png", "walk_1.png", "walk_1b.png", "walk_2.png", "walk_1.png"]),
		"run": _existing(base, ["walk_0.png", "walk_1.png", "dash.png", "walk_2.png", "walk_1.png", "walk_0.png"]),
		"attack1": _existing(base, ["attack_0.png", "attack_1.png", "attack_1b.png", "attack_2.png", "attack_2b.png", "attack_3.png", "idle.png"]),
		"attack2": _existing(base, ["attack_0.png", "attack_2.png", "attack_2b.png", "attack_3.png", "idle.png"]),
		"skill1": _existing(base, ["block.png", "attack_1.png", "attack_2.png", "idle.png"]),
		"skill2": _existing(base, ["dash.png", "attack_2.png", "attack_1.png", "attack_2b.png", "idle.png"]),
		"ultimate": _existing(base, ["ultimate_0.png", "ultimate_1.png", "ultimate_2.png", "attack_2.png", "personality.png", "idle.png"]),
		"hit": _existing(base, ["hit.png", "idle.png"]),
		"stagger": _existing(base, ["stagger.png", "hit.png", "idle.png"]),
		"death": _existing(base, ["hit.png", "stagger.png"]),
		"victory": _existing(base, ["victory.png", "personality.png", "idle.png"]),
		"block": _existing(base, ["block.png", "idle.png"]),
		"personality": _existing(base, ["personality.png", "idle.png"]),
	}
	for anim in mapping.keys():
		var list: Array = mapping[anim]
		if list.is_empty():
			list = ["idle.png"]
		frames.add_animation(anim)
		var loop: bool = anim == "idle" or anim == "walk" or anim == "run"
		frames.set_animation_loop(anim, loop)
		# Readable x1 timings — not hyperspeed FPS
		var spd := 6.0
		match anim:
			"idle": spd = 3.0
			"walk":
				match style:
					Style.TANK, Style.BRUTE: spd = 4.5
					Style.ASSASSIN, Style.BEAST: spd = 7.0
					_: spd = 5.5
			"run":
				match style:
					Style.ASSASSIN, Style.BEAST: spd = 9.0
					_: spd = 6.5
			"attack1", "attack2": spd = 6.0
			"skill1", "skill2": spd = 5.5
			"ultimate": spd = 5.0
			"hit": spd = 5.0
			"stagger": spd = 4.5
			"death": spd = 3.5
			"victory", "block", "personality": spd = 4.0
		frames.set_animation_speed(anim, spd)
		for file_name in list:
			var path: String = base + str(file_name)
			if not ResourceLoader.exists(path):
				path = base + "idle.png"
			var tex: Texture2D = load(path) as Texture2D
			frames.add_frame(anim, tex)
	sprite.sprite_frames = frames
	if not sprite.animation_finished.is_connected(_on_sprite_anim_finished):
		sprite.animation_finished.connect(_on_sprite_anim_finished)

func _existing(base: String, files: Array) -> Array:
	var out: Array = []
	for f in files:
		if ResourceLoader.exists(base + str(f)):
			out.append(f)
	if out.is_empty() and ResourceLoader.exists(base + "idle.png"):
		out.append("idle.png")
	return out

func play_anim(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		if sprite.animation != anim_name or not sprite.is_playing():
			sprite.play(anim_name)

func _on_sprite_anim_finished() -> void:
	var finished: String = sprite.animation
	if alive and finished not in ["idle", "walk", "run", "death"]:
		play_anim("idle")
	if finished != "walk" and finished != "run":
		busy = false
	animation_finished.emit(self, finished)

func face_towards(target_pos: Vector2) -> void:
	# Face the side where the target actually is (PvP-safe).
	var dx := target_pos.x - global_position.x
	if absf(dx) < 8.0:
		# Ambiguous — keep facing toward opposite battle side default
		desired_facing = Facing.RIGHT if battle_side == BattleSide.LEFT else Facing.LEFT
	else:
		desired_facing = Facing.RIGHT if dx > 0.0 else Facing.LEFT
	_apply_facing()
	_sync_dir_arrow()

func set_desired_facing(facing: Facing) -> void:
	desired_facing = facing
	_apply_facing()
	_sync_dir_arrow()

func facing_right() -> bool:
	return desired_facing == Facing.RIGHT

func facing_sign() -> float:
	return 1.0 if desired_facing == Facing.RIGHT else -1.0

func _apply_facing() -> void:
	# flip_h = (source_facing != desired_facing). Apply on sprite ONLY.
	# Body/UI/Shadow stay at scale.x = +1 to prevent double-mirror.
	body.scale = Vector2.ONE
	var need_flip: bool = source_facing != desired_facing
	sprite.flip_h = need_flip
	# Hard assert: never also scale-flip the body
	if absf(body.scale.x + 1.0) < 0.01:
		push_warning("Fighter %s: body.scale.x was -1 (double flip risk); reset" % fighter_id)
		body.scale.x = 1.0
	if vfx:
		vfx.flip_h = false

func _ensure_dir_arrow() -> void:
	if ui.get_node_or_null("DirArrow") != null:
		return
	var lbl := Label.new()
	lbl.name = "DirArrow"
	lbl.add_theme_font_size_override("font_size", 40)
	lbl.add_theme_color_override("font_color", Color(0.95, 0.76, 0.42))
	lbl.add_theme_color_override("font_outline_color", Color(0.09, 0.15, 0.2))
	lbl.add_theme_constant_override("outline_size", 5)
	ui.add_child(lbl)
	_sync_dir_arrow()

func _sync_dir_arrow() -> void:
	var arrow := ui.get_node_or_null("DirArrow") as Label
	if arrow == null:
		return
	arrow.text = "→" if desired_facing == Facing.RIGHT else "←"
	# Place arrow outside character toward facing direction
	arrow.position = Vector2(78 if desired_facing == Facing.RIGHT else -100, -155)

func debug_facing_report() -> String:
	return "%s src=%s want=%s side=%s flip_h=%s body.sx=%.1f" % [
		fighter_id,
		"R" if source_facing == Facing.RIGHT else "L",
		"R" if desired_facing == Facing.RIGHT else "L",
		"L" if battle_side == BattleSide.LEFT else "R",
		str(sprite.flip_h),
		body.scale.x,
	]

func _update_bars() -> void:
	hp_bar.max_value = max_hp
	hp_bar.value = max(hp, 0.0)
	hp_changed.emit(self, hp, max_hp)
	energy_changed.emit(self, energy, max_energy)

func gain_energy(amount: float) -> void:
	if not alive:
		return
	energy = min(max_energy, energy + amount)
	_update_bars()
	if energy >= max_energy:
		ult_ready.emit(self)

func can_ult() -> bool:
	return alive and energy >= max_energy and not busy

func apply_damage(amount: float, is_crit: bool = false, knock_dir: float = 0.0) -> void:
	if not alive:
		return
	hp = max(0.0, hp - amount)
	_update_bars()
	flash_vfx(Color(1.0, 0.35, 0.3, 0.9) if not is_crit else Color(1.0, 0.85, 0.2, 1.0))
	if absf(knock_dir) > 0.01:
		knockback_vel = Vector2(knock_dir * (28.0 if is_crit else 16.0), 0.0)
	if hp <= 0.0:
		alive = false
		busy = true
		modulate = Color(0.5, 0.5, 0.6, 0.85)
		play_anim("death")
		died.emit(self)
	else:
		if not busy:
			play_anim("hit" if not is_crit else "stagger")

func flash_vfx(color: Color = Color(1.0, 0.85, 0.3, 0.9), scale_to: float = 1.8) -> void:
	if vfx.texture == null:
		var img := Image.create(64, 64, false, Image.FORMAT_RGBA8)
		img.fill(Color(1, 1, 1, 0))
		for y in range(64):
			for x in range(64):
				var dx := x - 32.0
				var dy := y - 32.0
				if dx * dx + dy * dy <= 30.0 * 30.0:
					img.set_pixel(x, y, Color(1, 1, 1, 1))
		vfx.texture = ImageTexture.create_from_image(img)
	vfx.visible = true
	vfx.modulate = color
	vfx.scale = Vector2(0.7, 0.7)
	var tw := create_tween()
	tw.tween_property(vfx, "scale", Vector2(scale_to, scale_to), 0.14)
	tw.parallel().tween_property(vfx, "modulate:a", 0.0, 0.32)
	tw.tween_callback(func():
		vfx.visible = false
		vfx.scale = Vector2.ONE
		vfx.modulate.a = 1.0
	)

func distance_to_fighter(other: Fighter) -> float:
	return global_position.distance_to(other.global_position)

# --- Compatibility shim ---
func lock_team_facing() -> void:
	desired_facing = Facing.RIGHT if battle_side == BattleSide.LEFT else Facing.LEFT
	_apply_facing()
	_sync_dir_arrow()
