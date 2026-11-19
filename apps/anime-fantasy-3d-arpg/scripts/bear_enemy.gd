extends CharacterBody3D

const FreezeVfxBuilder = preload("res://scripts/parts/freeze_vfx_builder.gd")
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

signal frozen_changed(active: bool)
signal died
signal hit_received(hp_left: float, is_ice: bool)

@export var model_path: String = "res://assets/models/bear.glb"
@export var max_hp: float = 420.0
@export var move_speed: float = 1.55
@export var attack_damage: float = 12.0
@export var attack_range: float = 2.1
@export var attack_cooldown: float = 1.35
@export var model_scale: float = 1.15
@export var model_yaw_offset_deg: float = 180.0

var hp: float = 520.0
var target: Node3D = null
var frozen: bool = false
var freeze_left: float = 0.0
var _atk_cd: float = 0.0
var _alive: bool = true
var _freeze_vfx: Node3D = null
var _visual: Node3D = null

func _ready() -> void:
	hp = max_hp
	collision_layer = 2
	collision_mask = 1
	_visual = Node3D.new()
	_visual.name = "Visual"
	add_child(_visual)
	var col := CollisionShape3D.new()
	var cap := CapsuleShape3D.new()
	cap.radius = 0.7
	cap.height = 1.4
	col.shape = cap
	col.position = Vector3(0, 0.95, 0)
	add_child(col)
	_load_model()

func _load_model() -> void:
	var inst := _load_gltf(model_path)
	if inst:
		inst.name = "Model"
		inst.scale = Vector3.ONE * model_scale
		inst.rotation_degrees.y = model_yaw_offset_deg
		_visual.add_child(inst)
		_solidify_materials(inst)
	else:
		MeshKit.capsule(_visual, "Body", 0.55, 1.3, Color(0.35, 0.22, 0.12), Vector3(0, 0.9, 0))
		MeshKit.sphere(_visual, "Head", 0.38, Color(0.32, 0.2, 0.1), Vector3(0, 1.45, 0.45))

func _solidify_materials(root: Node) -> void:
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
					if m.albedo_texture == null and c.r > 0.9 and c.g > 0.9 and c.b > 0.9:
						c = Color(0.4, 0.26, 0.14, 1.0)
					m.albedo_color = c
					mi.set_surface_override_material(i, m)
	for c in root.get_children():
		_solidify_materials(c)

func _load_gltf(path: String) -> Node3D:
	var abs_path := path
	if path.begins_with("res://"):
		abs_path = ProjectSettings.globalize_path(path)
	if abs_path == "" or not FileAccess.file_exists(abs_path):
		return null
	var doc := GLTFDocument.new()
	var state := GLTFState.new()
	var err := doc.append_from_file(abs_path, state)
	if err != OK:
		return null
	return doc.generate_scene(state) as Node3D

func _physics_process(delta: float) -> void:
	if not _alive:
		velocity = Vector3.ZERO
		move_and_slide()
		return
	if freeze_left > 0.0:
		freeze_left -= delta
		velocity = Vector3.ZERO
		move_and_slide()
		if freeze_left <= 0.0:
			_set_frozen(false)
		return
	_atk_cd = maxf(0.0, _atk_cd - delta)
	# Prefer nearest living archer
	_retarget()
	if target == null or not is_instance_valid(target) or not target.has_method("is_combat_alive") or not target.call("is_combat_alive"):
		velocity = Vector3.ZERO
		move_and_slide()
		return
	var to := target.global_position - global_position
	to.y = 0.0
	var dist := to.length()
	if dist > 0.05:
		look_at(global_position + to.normalized(), Vector3.UP)
	if dist > attack_range:
		velocity = to.normalized() * move_speed
	else:
		velocity = Vector3.ZERO
		if _atk_cd <= 0.0:
			_atk_cd = attack_cooldown
			if target.has_method("receive_hit"):
				target.call("receive_hit", attack_damage, false, global_position)
	move_and_slide()

func _retarget() -> void:
	var best: Node3D = null
	var best_d := 1e9
	for n in get_tree().get_nodes_in_group("archers"):
		if n is Node3D and n.has_method("is_combat_alive") and n.call("is_combat_alive"):
			var d: float = global_position.distance_to((n as Node3D).global_position)
			if d < best_d:
				best_d = d
				best = n as Node3D
	if best:
		target = best

func receive_hit(amount: float, is_ice: bool, hit_pos: Vector3) -> void:
	if not _alive:
		return
	hp -= amount
	hit_received.emit(hp, is_ice)
	_flash_hit()
	if is_ice:
		_apply_freeze(2.2)
		_spawn_ice_burst(hit_pos)
	if hp <= 0.0:
		_alive = false
		hp = 0.0
		_set_frozen(false)
		died.emit()
		var tw := create_tween()
		tw.tween_property(_visual, "scale", Vector3(1.15, 0.12, 1.15), 0.5)
		tw.tween_callback(queue_free)

func _apply_freeze(duration: float) -> void:
	freeze_left = maxf(freeze_left, duration)
	_set_frozen(true)

func _set_frozen(active: bool) -> void:
	if frozen == active:
		return
	frozen = active
	frozen_changed.emit(active)
	if active:
		if _freeze_vfx == null:
			_freeze_vfx = FreezeVfxBuilder.build()
			add_child(_freeze_vfx)
	else:
		if _freeze_vfx:
			_freeze_vfx.queue_free()
			_freeze_vfx = null

func _flash_hit() -> void:
	var tw := create_tween()
	tw.tween_property(_visual, "scale", Vector3(1.08, 1.08, 1.08) * model_scale, 0.05)
	tw.tween_property(_visual, "scale", Vector3.ONE * model_scale, 0.12)

func _spawn_ice_burst(pos: Vector3) -> void:
	var fx := FreezeVfxBuilder.build_impact_burst()
	get_parent().add_child(fx)
	fx.global_position = pos
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector3(2.6, 2.6, 2.6), 0.4)
	tw.tween_callback(fx.queue_free)

func is_combat_alive() -> bool:
	return _alive
