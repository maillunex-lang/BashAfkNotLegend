extends CharacterBody3D

const IceArrowScr = preload("res://scripts/ice_arrow.gd")
const BowBuilder = preload("res://scripts/parts/bow_builder.gd")

signal shot_fired(archer_name: String, shot_index: int)

@export var model_path: String = ""
@export var fire_interval: float = 1.05
@export var fire_delay: float = 0.0
@export var max_hp: float = 140.0
@export var play_shot_anim: bool = false
@export var model_yaw_offset_deg: float = 0.0
@export var model_scale: float = 1.0

var hp: float = 140.0
var shot_count: int = 0
var target: Node3D = null
var _cooldown: float = 0.5
var _alive: bool = true
var _muzzle: Node3D = null
var _visual: Node3D = null
var _anim_player: AnimationPlayer = null

func _ready() -> void:
	hp = max_hp
	collision_layer = 1
	collision_mask = 1
	_cooldown = fire_delay
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.35
	cap.height = 1.5
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	add_child(col)
	_load_model()

func _load_model() -> void:
	var inst := _load_gltf(model_path)
	if inst == null:
		push_warning("Missing model: " + model_path)
	else:
		inst.name = "Model"
		inst.scale = Vector3.ONE * model_scale
		inst.rotation_degrees.y = model_yaw_offset_deg
		_visual.add_child(inst)
		_anim_player = _find_anim_player(inst)
		_fix_gltf_materials(inst)
	# Always attach a large readable bow + reliable muzzle (bone sockets are flaky via runtime GLTF).
	_attach_showcase_bow()
	if play_shot_anim and _anim_player:
		_play_shot_loop()

func _attach_showcase_bow() -> void:
	var bow := BowBuilder.build()
	bow.name = "FantasyBow"
	# Character-local left hand; large and in front so camera always sees it
	bow.position = Vector3(0.55, 1.15, 0.35)
	bow.rotation_degrees = Vector3(12, -25, -15)
	bow.scale = Vector3(1.6, 1.6, 1.6)
	add_child(bow)  # not under _visual so look_at on body keeps bow with character
	_muzzle = Marker3D.new()
	_muzzle.name = "Muzzle"
	_muzzle.position = Vector3(0.2, 1.35, 0.75)
	add_child(_muzzle)

func _fix_gltf_materials(root: Node) -> void:
	# Keep textures; only kill emission / accidental alpha that blows out Compatibility.
	if root is MeshInstance3D:
		var mi := root as MeshInstance3D
		mi.material_override = null
		if mi.mesh:
			for i in range(mi.mesh.get_surface_count()):
				var am = mi.mesh.surface_get_material(i)
				if am is StandardMaterial3D:
					var m := (am as StandardMaterial3D).duplicate() as StandardMaterial3D
					m.emission_enabled = false
					m.emission_energy_multiplier = 0.0
					m.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED
					var c := m.albedo_color
					c.a = 1.0
					# Avoid pure-white blowout if texture failed to bind
					if m.albedo_texture == null and c.r > 0.92 and c.g > 0.92 and c.b > 0.92:
						c = Color(0.55, 0.6, 0.65, 1.0)
					m.albedo_color = c
					mi.set_surface_override_material(i, m)
	for c in root.get_children():
		_fix_gltf_materials(c)

func _load_gltf(path: String) -> Node3D:
	# Runtime load — avoids hanging Godot editor import on large GLBs.
	var abs_path := path
	if path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	if abs_path == "" or not FileAccess.file_exists(abs_path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(abs_path, state)
	if err != OK:
		push_warning("GLTF load failed %s err=%s" % [abs_path, str(err)])
		return null
	var root = doc.generate_scene(state)
	return root as Node3D

func _find_named(root: Node, name: String) -> Node3D:
	if root.name == name and root is Node3D:
		return root as Node3D
	for c in root.get_children():
		var found := _find_named(c, name)
		if found:
			return found
	return null

func _find_anim_player(root: Node) -> AnimationPlayer:
	if root is AnimationPlayer:
		return root as AnimationPlayer
	for c in root.get_children():
		var found := _find_anim_player(c)
		if found:
			return found
	return null

func _play_shot_loop() -> void:
	if _anim_player == null:
		return
	var names := _anim_player.get_animation_list()
	var pick := ""
	for n in names:
		var low := String(n).to_lower()
		if "archery" in low or "shot" in low or "attack" in low:
			pick = n
			break
	if pick == "" and names.size() > 0:
		pick = names[0]
	if pick != "":
		_anim_player.play(pick)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if target and is_instance_valid(target):
		var look := target.global_position
		look.y = global_position.y
		if look.distance_to(global_position) > 0.08:
			look_at(look, Vector3.UP)
	_cooldown -= delta
	if _cooldown <= 0.0 and target and is_instance_valid(target) \
			and target.has_method("is_combat_alive") and target.call("is_combat_alive"):
		_fire()

func _fire() -> void:
	shot_count += 1
	_cooldown = fire_interval
	if play_shot_anim and _anim_player:
		_play_shot_loop()
	var forward := -global_transform.basis.z
	var origin := global_position + Vector3(0, 1.3, 0) + forward * 0.7
	if _muzzle:
		origin = _muzzle.global_position
	var aim := target.global_position + Vector3(0, 1.2, 0)
	var dir := (aim - origin).normalized()
	var arrow = IceArrowScr.new()
	get_parent().add_child(arrow)
	arrow.setup(origin, dir, target)
	shot_fired.emit(name, shot_count)
	var bow := find_child("FantasyBow", true, false) as Node3D
	if bow:
		var base := bow.scale
		var tw := create_tween()
		tw.tween_property(bow, "scale", base * 1.2, 0.08)
		tw.tween_property(bow, "scale", base, 0.14)
	# Muzzle flash (add to tree before setting global_position)
	var flash := OmniLight3D.new()
	flash.light_color = Color(0.6, 0.95, 1.0)
	flash.light_energy = 2.5
	flash.omni_range = 2.5
	get_parent().add_child(flash)
	flash.global_position = origin
	var ftw := flash.create_tween()
	ftw.tween_property(flash, "light_energy", 0.0, 0.25)
	ftw.tween_callback(flash.queue_free)
func receive_hit(amount: float, _is_ice: bool, _pos: Vector3) -> void:
	if not _alive:
		return
	hp -= amount
	if hp <= 0.0:
		_alive = false
		hp = 0.0

func is_combat_alive() -> bool:
	return _alive
