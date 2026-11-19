extends Node3D

## Standalone ARPG 3D demo: archer vs enemy, every 3rd shot = ice arrow.

const ArenaBuilderScr := preload("res://scripts/parts/arena_builder.gd")
const ArcherScr := preload("res://scripts/archer.gd")
const EnemyScr := preload("res://scripts/enemy.gd")

@onready var world: Node3D = $World
@onready var camera: Camera3D = $CameraRig/Camera3D
@onready var hud_label: Label = $UI/Hud
@onready var title_label: Label = $UI/Title

var archer: CharacterBody3D
var enemy: CharacterBody3D
var _time: float = 0.0
var _ended: bool = false
var _shot_log: String = ""

func _ready() -> void:
	world.add_child(ArenaBuilderScr.build())

	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42, 35, 0)
	sun.light_energy = 1.35
	sun.shadow_enabled = true
	add_child(sun)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.35, 0.48, 0.62)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.45, 0.55, 0.65)
	e.ambient_light_energy = 0.55
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.environment = e
	add_child(env)

	_spawn_combatants()
	title_label.text = "ARPG 3D · Лучник"
	_refresh_hud()

	var demo_s := float(OS.get_environment("ARPG_DEMO_SECONDS"))
	if demo_s <= 0.0:
		demo_s = 14.0
	if OS.get_environment("ARPG_DEMO_QUIT") == "1":
		await get_tree().create_timer(demo_s).timeout
		_take_screenshot()
		await get_tree().create_timer(0.25).timeout
		get_tree().quit()

func _spawn_combatants() -> void:
	archer = ArcherScr.new()
	archer.name = "Archer"
	var a_vis := Node3D.new()
	a_vis.name = "Visual"
	archer.add_child(a_vis)
	var muzzle := Marker3D.new()
	muzzle.name = "Muzzle"
	muzzle.position = Vector3(0.55, 1.15, 0.35)
	archer.add_child(muzzle)
	var a_col := CollisionShape3D.new()
	var a_cap := CapsuleShape3D.new()
	a_cap.radius = 0.35
	a_cap.height = 1.6
	a_col.shape = a_cap
	a_col.position = Vector3(0, 0.9, 0)
	archer.add_child(a_col)
	world.add_child(archer)
	archer.global_position = Vector3(-4.5, 0, 0)
	archer.shot_fired.connect(_on_shot)

	enemy = EnemyScr.new()
	enemy.name = "Enemy"
	var e_vis := Node3D.new()
	e_vis.name = "Visual"
	enemy.add_child(e_vis)
	var e_col := CollisionShape3D.new()
	var e_cap := CapsuleShape3D.new()
	e_cap.radius = 0.45
	e_cap.height = 1.7
	e_col.shape = e_cap
	e_col.position = Vector3(0, 0.95, 0)
	enemy.add_child(e_col)
	world.add_child(enemy)
	enemy.global_position = Vector3(6.2, 0, 0.6)
	enemy.frozen_changed.connect(_on_frozen)
	enemy.died.connect(_on_enemy_died)

	archer.target = enemy
	enemy.target = archer

func _process(delta: float) -> void:
	_time += delta
	_orbit_camera()
	_refresh_hud()

func _orbit_camera() -> void:
	var focus := Vector3(0, 1.2, 0)
	if is_instance_valid(archer) and is_instance_valid(enemy):
		focus = (archer.global_position + enemy.global_position) * 0.5 + Vector3(0, 1.1, 0)
	elif is_instance_valid(archer):
		focus = archer.global_position + Vector3(0, 1.2, 0)
	var ang := _time * 0.22
	var dist := 9.5
	var cam_pos := focus + Vector3(sin(ang) * dist, 4.8, cos(ang) * dist)
	camera.global_position = cam_pos
	camera.look_at(focus, Vector3.UP)

func _on_shot(shot_index: int, is_ice: bool) -> void:
	if is_ice:
		_shot_log = "Выстрел %d · ЛЕДЯНАЯ СТРЕЛА" % shot_index
	else:
		_shot_log = "Выстрел %d · обычная стрела" % shot_index

func _on_frozen(active: bool) -> void:
	if active:
		_shot_log = "Враг ЗАМОРОЖЕН"

func _on_enemy_died() -> void:
	_shot_log = "Враг повержен"
	_ended = true

func _refresh_hud() -> void:
	var a_hp := 0
	var e_hp := 0
	var freeze := ""
	if is_instance_valid(archer):
		a_hp = int(archer.hp)
	if is_instance_valid(enemy):
		e_hp = int(enemy.hp)
		if enemy.frozen:
			freeze = " · FREEZE"
	hud_label.text = "Лучник HP %d   |   Враг HP %d%s\n%s\nКаждый 3-й выстрел — ледяная стрела" % [a_hp, e_hp, freeze, _shot_log]

func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := OS.get_environment("ARPG_SCREENSHOT_PATH")
	if path == "":
		path = "/opt/cursor/artifacts/arpg3d_battle.png"
	img.save_png(path)
	print("[ARPG3D] screenshot ", path)
