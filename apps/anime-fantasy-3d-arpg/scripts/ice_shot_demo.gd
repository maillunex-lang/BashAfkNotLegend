extends Node3D

## Dual archers vs bear — ice arrow combat showcase.

const ArenaBuilder = preload("res://scripts/parts/arena_builder.gd")
const ArcherUnit = preload("res://scripts/archer_unit.gd")
const BearEnemy = preload("res://scripts/bear_enemy.gd")

@onready var world: Node3D = $World
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var hud_label: Label = $UI/Hud
@onready var title_label: Label = $UI/Title

var archer_a: CharacterBody3D
var archer_b: CharacterBody3D
var bear: CharacterBody3D
var _time: float = 0.0
var _shot_log: String = "Готовятся к залпу…"
var _ended: bool = false

func _ready() -> void:
	world.add_child(ArenaBuilder.build())

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-48, 40, 0)
	sun.light_energy = 0.7
	sun.shadow_enabled = true
	add_child(sun)

	var fill := OmniLight3D.new()
	fill.name = "Fill"
	fill.light_color = Color(0.65, 0.8, 1.0)
	fill.light_energy = 0.55
	fill.omni_range = 18.0
	fill.position = Vector3(-3, 4, -2)
	add_child(fill)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.28, 0.4, 0.52)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.4, 0.5, 0.58)
	e.ambient_light_energy = 0.35
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.85
	e.glow_enabled = false
	env.environment = e
	add_child(env)

	_spawn()
	title_label.text = "Anime Fantasy 3D · Два лучника vs Медведь"
	_refresh_hud()

	var demo_s := float(OS.get_environment("ARPG_DEMO_SECONDS"))
	if demo_s <= 0.0:
		demo_s = 16.0
	if OS.get_environment("ARPG_DEMO_QUIT") == "1":
		await get_tree().create_timer(demo_s).timeout
		_take_screenshot()
		await get_tree().create_timer(0.3).timeout
		get_tree().quit()

func _spawn() -> void:
	bear = BearEnemy.new()
	bear.name = "Bear"
	world.add_child(bear)
	bear.global_position = Vector3(5.5, 0, 0.4)
	bear.frozen_changed.connect(_on_frozen)
	bear.died.connect(_on_bear_died)
	bear.hit_received.connect(_on_bear_hit)

	archer_a = ArcherUnit.new()
	archer_a.name = "ArcherTeal"
	archer_a.model_path = "res://assets/models/archer_with_bow.glb"
	archer_a.fire_interval = 1.0
	archer_a.fire_delay = 0.35
	archer_a.model_yaw_offset_deg = 0.0
	archer_a.model_scale = 1.0
	world.add_child(archer_a)
	archer_a.add_to_group("archers")
	archer_a.global_position = Vector3(-5.2, 0, -1.1)
	archer_a.target = bear
	archer_a.shot_fired.connect(_on_shot)

	archer_b = ArcherUnit.new()
	archer_b.name = "ArcherElf"
	archer_b.model_path = "res://assets/models/archer2_with_bow.glb"
	archer_b.fire_interval = 1.15
	archer_b.fire_delay = 0.85
	archer_b.play_shot_anim = true
	# Mixamo faces +Z; battle look_at faces bear on +X so may need yaw tweak
	archer_b.model_yaw_offset_deg = 0.0
	archer_b.model_scale = 1.0
	world.add_child(archer_b)
	archer_b.add_to_group("archers")
	archer_b.global_position = Vector3(-4.6, 0, 1.6)
	archer_b.target = bear
	archer_b.shot_fired.connect(_on_shot)

func _process(delta: float) -> void:
	_time += delta
	_orbit_camera()
	_refresh_hud()

func _orbit_camera() -> void:
	var focus := Vector3(0, 1.3, 0)
	var pts: Array[Vector3] = []
	if is_instance_valid(archer_a):
		pts.append(archer_a.global_position)
	if is_instance_valid(archer_b):
		pts.append(archer_b.global_position)
	if is_instance_valid(bear):
		pts.append(bear.global_position)
	if pts.size() > 0:
		var acc := Vector3.ZERO
		for p in pts:
			acc += p
		focus = acc / float(pts.size()) + Vector3(0, 1.25, 0)
	var ang := _time * 0.15 + 0.55
	var dist := 7.8
	var cam_pos := focus + Vector3(sin(ang) * dist, 3.4, cos(ang) * dist)
	camera.global_position = cam_pos
	camera.look_at(focus, Vector3.UP)

func _on_shot(archer_name: String, shot_index: int) -> void:
	_shot_log = "%s · ледяной выстрел #%d" % [archer_name, shot_index]

func _on_frozen(active: bool) -> void:
	if active:
		_shot_log = "Медведь ЗАМОРОЖЕН"

func _on_bear_hit(hp_left: float, is_ice: bool) -> void:
	if is_ice:
		_shot_log = "Попадание льдом · HP медведя %d" % int(hp_left)

func _on_bear_died() -> void:
	_shot_log = "Медведь повержен"
	_ended = true

func _refresh_hud() -> void:
	var a_hp := int(archer_a.hp) if is_instance_valid(archer_a) else 0
	var b_hp := int(archer_b.hp) if is_instance_valid(archer_b) else 0
	var e_hp := int(bear.hp) if is_instance_valid(bear) else 0
	var freeze := " · FREEZE" if (is_instance_valid(bear) and bear.frozen) else ""
	hud_label.text = "Тил %d HP   |   Эльф %d HP   |   Медведь %d HP%s\n%s" % [a_hp, b_hp, e_hp, freeze, _shot_log]

func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := OS.get_environment("ARPG_SCREENSHOT_PATH")
	if path == "":
		path = "/opt/cursor/artifacts/anime_dual_archer_ice.png"
	img.save_png(path)
	print("[ANIME-ARPG] screenshot ", path)
