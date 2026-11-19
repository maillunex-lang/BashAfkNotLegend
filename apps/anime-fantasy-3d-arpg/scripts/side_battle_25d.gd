extends Node3D

## 2.5D side-view battle (AFK Arena–like): 3D GLBs on an XY lane, camera fixed from +Z.

const SideStage = preload("res://scripts/parts/side_stage_builder.gd")
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
var _shot_log: String = "Бой начинается…"
var _cam_base := Vector3(0.6, 2.15, 9.2)

func _ready() -> void:
	world.add_child(SideStage.build())
	_setup_lighting()
	_spawn()
	_setup_side_camera()
	title_label.text = "2.5D · Два лучника vs Медведь (вид сбоку)"
	_refresh_hud()

	var demo_s := float(OS.get_environment("ARPG_DEMO_SECONDS"))
	if demo_s <= 0.0:
		demo_s = 16.0
	if OS.get_environment("ARPG_DEMO_QUIT") == "1":
		await get_tree().create_timer(demo_s).timeout
		_take_screenshot()
		await get_tree().create_timer(0.25).timeout
		get_tree().quit()

func _setup_lighting() -> void:
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	# Key light from front-side so silhouettes read in profile
	sun.rotation_degrees = Vector3(-35, 25, 0)
	sun.light_energy = 0.85
	sun.shadow_enabled = true
	add_child(sun)

	var rim := DirectionalLight3D.new()
	rim.name = "Rim"
	rim.rotation_degrees = Vector3(-20, -140, 0)
	rim.light_color = Color(0.55, 0.75, 1.0)
	rim.light_energy = 0.35
	add_child(rim)

	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.3, 0.45, 0.6)
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	e.ambient_light_color = Color(0.42, 0.5, 0.58)
	e.ambient_light_energy = 0.4
	e.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	e.tonemap_exposure = 0.9
	e.glow_enabled = false
	env.environment = e
	add_child(env)

func _setup_side_camera() -> void:
	# Perspective side cam — AFK Arena feel (slight elevation, locked Z)
	camera.projection = Camera3D.PROJECTION_PERSPECTIVE
	camera.fov = 42.0
	camera.current = true
	camera.position = _cam_base
	camera.look_at(Vector3(0.8, 1.15, 0), Vector3.UP)

func _spawn() -> void:
	# Right side: bear facing left (-X)
	bear = BearEnemy.new()
	bear.name = "Bear"
	bear.move_speed = 0.55  # slow lane advance
	bear.attack_range = 2.4
	bear.model_yaw_offset_deg = 90.0  # profile toward -X after look_at
	bear.model_scale = 1.05
	world.add_child(bear)
	bear.global_position = Vector3(5.2, 0, 0)
	bear.rotation_degrees.y = -90.0  # face left
	bear.set_meta("side_lock_yaw", -90.0)
	bear.frozen_changed.connect(_on_frozen)
	bear.died.connect(_on_bear_died)
	bear.hit_received.connect(_on_bear_hit)

	# Left side: two archers stacked slightly in Z for depth, facing +X
	archer_a = _make_archer("ArcherTeal", "res://assets/models/archer_with_bow.glb",
		Vector3(-4.6, 0, 0.35), 0.9, 0.45, 1.0)
	archer_b = _make_archer("ArcherElf", "res://assets/models/archer2_with_bow.glb",
		Vector3(-5.4, 0, -0.35), 1.05, 0.85, 1.0)
	archer_b.play_shot_anim = true
	_orient_bows_for_side_cam()

func _make_archer(p_name: String, path: String, pos: Vector3, interval: float, delay: float, scl: float) -> CharacterBody3D:
	var a: CharacterBody3D = ArcherUnit.new()
	a.name = p_name
	a.model_path = path
	a.fire_interval = interval
	a.fire_delay = delay
	a.model_scale = scl
	a.model_yaw_offset_deg = 0.0
	world.add_child(a)
	a.add_to_group("archers")
	a.global_position = pos
	a.rotation_degrees.y = 90.0  # face +X (right)
	a.target = bear
	a.shot_fired.connect(_on_shot)
	# Lock sideways facing: disable free look_at yaw drift in 2.5D
	a.set_meta("side_lock_yaw", 90.0)
	return a

func _orient_bows_for_side_cam() -> void:
	# Character faces +X; camera looks from +Z — put bow silhouette in XY.
	for a in [archer_a, archer_b]:
		if not is_instance_valid(a):
			continue
		var bow := a.find_child("FantasyBow", true, false) as Node3D
		if bow == null:
			continue
		bow.position = Vector3(0.05, 1.15, 0.12)
		bow.rotation_degrees = Vector3(90, 0, -8)
		bow.scale = Vector3(1.7, 1.7, 1.7)
		var muzzle := a.find_child("Muzzle", true, false) as Node3D
		if muzzle:
			muzzle.position = Vector3(0.55, 1.35, 0.0)

func _process(delta: float) -> void:
	_time += delta
	_lock_side_poses()
	_side_camera_idle()
	_refresh_hud()

func _lock_side_poses() -> void:
	# Keep everyone on the Z≈0 lane and facing along X (AFK profile)
	for n in [archer_a, archer_b]:
		if is_instance_valid(n):
			n.rotation_degrees.y = 90.0
			# Soft Z lock — keep depth separation but no combat drift
			var z0: float = n.get_meta("lane_z") if n.has_meta("lane_z") else n.global_position.z
			if not n.has_meta("lane_z"):
				n.set_meta("lane_z", n.global_position.z)
			n.global_position.z = lerpf(n.global_position.z, z0, 0.2)
	if is_instance_valid(bear):
		bear.rotation_degrees.y = -90.0
		bear.global_position.z = lerpf(bear.global_position.z, 0.0, 0.15)

func _side_camera_idle() -> void:
	# Tiny AFK-style camera breathe / focus follow on X
	var focus_x := 0.5
	if is_instance_valid(bear) and is_instance_valid(archer_a):
		focus_x = (archer_a.global_position.x + bear.global_position.x) * 0.5
	var bob := sin(_time * 0.7) * 0.06
	var punch := 0.0
	if is_instance_valid(bear) and bear.frozen:
		punch = 0.12
	camera.position = Vector3(focus_x * 0.15 + 0.4, 2.1 + bob, 9.0)
	camera.look_at(Vector3(focus_x, 1.2 + punch * 0.2, 0), Vector3.UP)

func _on_shot(archer_name: String, shot_index: int) -> void:
	_shot_log = "%s · ледяной выстрел #%d" % [archer_name, shot_index]

func _on_frozen(active: bool) -> void:
	if active:
		_shot_log = "Медведь ЗАМОРОЖЕН"

func _on_bear_hit(hp_left: float, is_ice: bool) -> void:
	if is_ice:
		_shot_log = "Попадание льдом · HP %d" % int(hp_left)

func _on_bear_died() -> void:
	_shot_log = "Медведь повержен"

func _refresh_hud() -> void:
	var a_hp := int(archer_a.hp) if is_instance_valid(archer_a) else 0
	var b_hp := int(archer_b.hp) if is_instance_valid(archer_b) else 0
	var e_hp := int(bear.hp) if is_instance_valid(bear) else 0
	var freeze := " · FREEZE" if (is_instance_valid(bear) and bear.frozen) else ""
	hud_label.text = "Тил %d  |  Эльф %d  |  Медведь %d%s\n%s" % [a_hp, b_hp, e_hp, freeze, _shot_log]

func _take_screenshot() -> void:
	await RenderingServer.frame_post_draw
	var img := get_viewport().get_texture().get_image()
	var path := OS.get_environment("ARPG_SCREENSHOT_PATH")
	if path == "":
		path = "/opt/cursor/artifacts/side_25d_battle.png"
	img.save_png(path)
	print("[25D] screenshot ", path)
