extends Node2D
class_name Fighter

signal died(fighter)
signal energy_changed(fighter, value, max_value)
signal hp_changed(fighter, value, max_value)
signal ult_ready(fighter)
signal dealt_hit(fighter, target, amount, is_crit)
signal animation_finished(fighter, anim_name)

enum Style { TANK, ASSASSIN, BRUTE, BEAST }

@export var fighter_id: String = ""
@export var display_name: String = ""
@export var team: String = "player" # player | enemy
@export var is_front_row: bool = true
@export var max_hp: float = 1000.0
@export var max_energy: float = 100.0
@export var attack_power: float = 120.0
@export var sprite_folder: String = ""
@export var style: Style = Style.TANK
@export var preferred_range: float = 110.0
@export var move_speed: float = 90.0
@export var faces_right_by_default: bool = true

var hp: float
var energy: float = 40.0
var alive: bool = true
var busy: bool = false
var facing_right: bool = true
var current_target: Fighter = null
var home_y: float = 0.0
var attack_cd: float = 0.0
var skill_cd: float = 0.0
var foot_offset_y: float = 110.0

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
	facing_right = faces_right_by_default
	_build_frames()
	_apply_facing()
	_update_bars()
	name_label.text = display_name
	play_anim("idle")
	vfx.visible = false
	_update_depth()

func _process(_delta: float) -> void:
	_update_depth()
	# Keep UI upright regardless of body flip
	ui.scale.x = 1.0
	ui.global_rotation = 0.0
	# Hard lock every frame: allies → right, enemies → left
	lock_team_facing()

func _update_depth() -> void:
	# Foot Y drives draw order: lower on screen = closer to camera = higher z
	z_index = int(global_position.y)

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	var base := "res://assets/sprites/%s/" % sprite_folder
	var mapping := {
		"idle": _existing(base, ["idle.png"]),
		"walk": _existing(base, ["walk_0.png", "walk_1.png", "walk_1b.png", "walk_2.png", "walk_1.png"]),
		"run": _existing(base, ["walk_0.png", "walk_1.png", "dash.png", "walk_2.png", "walk_1.png"]),
		"attack1": _existing(base, ["attack_0.png", "attack_1.png", "attack_1b.png", "attack_2.png", "attack_2b.png", "attack_3.png", "idle.png"]),
		"attack2": _existing(base, ["attack_0.png", "attack_2.png", "attack_2b.png", "attack_3.png", "idle.png"]),
		"skill1": _existing(base, ["block.png", "attack_1.png", "attack_2.png", "idle.png"]),
		"skill2": _existing(base, ["dash.png", "attack_2.png", "attack_1.png", "idle.png"]),
		"ultimate": _existing(base, ["ultimate_0.png", "ultimate_1.png", "ultimate_2.png", "attack_2.png", "personality.png", "idle.png"]),
		"hit": _existing(base, ["hit.png", "idle.png"]),
		"stagger": _existing(base, ["stagger.png", "hit.png", "idle.png"]),
		"death": _existing(base, ["hit.png", "stagger.png"]),
		"victory": _existing(base, ["victory.png", "personality.png", "idle.png"]),
		"block": _existing(base, ["block.png", "idle.png"]),
		"personality": _existing(base, ["personality.png", "idle.png"]),
	}
	# Style-specific fallbacks when dash/block missing
	for anim in mapping.keys():
		var list: Array = mapping[anim]
		if list.is_empty():
			list = ["idle.png"]
		frames.add_animation(anim)
		var loop: bool = anim == "idle" or anim == "walk" or anim == "run"
		frames.set_animation_loop(anim, loop)
		var spd := 8.0
		match anim:
			"idle": spd = 4.0
			"walk": spd = 7.0 if style != Style.ASSASSIN else 10.0
			"run": spd = 12.0
			"attack1", "attack2": spd = 10.0
			"ultimate": spd = 9.0
			"hit", "stagger": spd = 8.0
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

func face_towards(_target_pos: Vector2) -> void:
	# Battle rule (DEC-009): allies ALWAYS face right, enemies ALWAYS face left.
	# Do not flip when units clump/overshoot — that caused Braxor to look left mid-fight.
	var should_right: bool = team == "player"
	if should_right != facing_right:
		facing_right = should_right
		_apply_facing()
	else:
		_apply_facing()
	_sync_dir_arrow()

func lock_team_facing() -> void:
	facing_right = team == "player"
	_apply_facing()
	_sync_dir_arrow()

func _apply_facing() -> void:
	# Art authored direction vs desired facing. Flip body only; UI stays upright.
	var authored_right := faces_right_by_default
	var flip := facing_right != authored_right
	body.scale.x = -1.0 if flip else 1.0

func _sync_dir_arrow() -> void:
	var arrow := ui.get_node_or_null("DirArrow") as Label
	if arrow == null:
		return
	arrow.text = "→" if facing_right else "←"
	arrow.position = Vector2(72 if facing_right else -92, -160)

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

func apply_damage(amount: float, is_crit: bool = false) -> void:
	if not alive:
		return
	hp = max(0.0, hp - amount)
	_update_bars()
	flash_vfx(Color(1.0, 0.35, 0.3, 0.9) if not is_crit else Color(1.0, 0.85, 0.2, 1.0))
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
	tw.tween_property(vfx, "scale", Vector2(scale_to, scale_to), 0.12)
	tw.parallel().tween_property(vfx, "modulate:a", 0.0, 0.28)
	tw.tween_callback(func():
		vfx.visible = false
		vfx.scale = Vector2.ONE
		vfx.modulate.a = 1.0
	)

func distance_to_fighter(other: Fighter) -> float:
	return global_position.distance_to(other.global_position)
