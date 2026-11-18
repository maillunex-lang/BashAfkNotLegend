extends Node2D
class_name Fighter

signal died(fighter)
signal energy_changed(fighter, value, max_value)
signal hp_changed(fighter, value, max_value)
signal ult_ready(fighter)
signal animation_finished(fighter, anim_name)

@export var fighter_id: String = ""
@export var display_name: String = ""
@export var team: String = "player" # player | enemy
@export var is_front_row: bool = true
@export var max_hp: float = 1000.0
@export var max_energy: float = 100.0
@export var attack_power: float = 120.0
@export var sprite_folder: String = ""

var hp: float
var energy: float = 35.0
var alive: bool = true
var busy: bool = false

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var hp_bar: ProgressBar = $HPBar
@onready var name_label: Label = $NameLabel
@onready var vfx: Sprite2D = $VFX

func _ready() -> void:
	hp = max_hp
	_build_frames()
	_update_bars()
	name_label.text = display_name
	play_anim("idle")
	vfx.visible = false

func _build_frames() -> void:
	var frames := SpriteFrames.new()
	var base := "res://assets/sprites/%s/" % sprite_folder
	var mapping := {
		"idle": ["idle.png"],
		"attack": ["attack.png", "idle.png"],
		"hit": ["hit.png", "idle.png"] if ResourceLoader.exists(base + "hit.png") else ["idle.png"],
		"personality": ["personality.png", "idle.png"] if ResourceLoader.exists(base + "personality.png") else ["idle.png"],
		"ultimate": ["attack.png", "personality.png", "idle.png"] if ResourceLoader.exists(base + "personality.png") else ["attack.png", "idle.png"],
		"death": ["hit.png"] if ResourceLoader.exists(base + "hit.png") else ["idle.png"],
	}
	# Enemies may lack personality/hit — fall back.
	for anim in mapping.keys():
		frames.add_animation(anim)
		frames.set_animation_loop(anim, anim == "idle")
		frames.set_animation_speed(anim, 6.0 if anim != "idle" else 3.0)
		for file_name in mapping[anim]:
			var path: String = str(base) + str(file_name)
			if not ResourceLoader.exists(path):
				path = str(base) + "idle.png"
			var tex: Texture2D = load(path) as Texture2D
			frames.add_frame(anim, tex)
	sprite.sprite_frames = frames
	sprite.animation_finished.connect(_on_sprite_anim_finished)

func play_anim(anim_name: String) -> void:
	if sprite.sprite_frames and sprite.sprite_frames.has_animation(anim_name):
		sprite.play(anim_name)

func _on_sprite_anim_finished() -> void:
	var finished: String = sprite.animation
	if alive and finished != "idle" and finished != "death":
		play_anim("idle")
	busy = false
	animation_finished.emit(self, finished)

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

func apply_damage(amount: float) -> void:
	if not alive:
		return
	hp = max(0.0, hp - amount)
	_update_bars()
	if hp <= 0.0:
		alive = false
		busy = true
		modulate = Color(0.45, 0.45, 0.55, 0.85)
		play_anim("death")
		died.emit(self)
	else:
		busy = true
		play_anim("hit")

func flash_vfx(color: Color = Color(1.0, 0.85, 0.3, 0.9)) -> void:
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
	vfx.scale = Vector2(0.8, 0.8)
	var tw := create_tween()
	tw.tween_property(vfx, "scale", Vector2(1.8, 1.8), 0.15)
	tw.parallel().tween_property(vfx, "modulate:a", 0.0, 0.35)
	tw.tween_callback(func():
		vfx.visible = false
		vfx.scale = Vector2.ONE
		vfx.modulate.a = 1.0
	)
