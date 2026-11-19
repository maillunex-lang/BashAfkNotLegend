extends CharacterBody3D

const EnemyBuilder = preload("res://scripts/parts/enemy_builder.gd")
const FreezeVfxBuilder = preload("res://scripts/parts/freeze_vfx_builder.gd")
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

signal frozen_changed(active: bool)
signal died

@export var max_hp: float = 320.0
@export var move_speed: float = 2.1
@export var attack_damage: float = 10.0
@export var attack_range: float = 1.7
@export var attack_cooldown: float = 1.1

var hp: float = 160.0
var target: Node3D = null
var frozen: bool = false
var freeze_left: float = 0.0
var _atk_cd: float = 0.0
var _alive: bool = true
var _freeze_vfx: Node3D = null

@onready var visual_root: Node3D = $Visual

func _ready() -> void:
	hp = max_hp
	collision_layer = 2
	collision_mask = 1
	if visual_root.get_child_count() == 0:
		visual_root.add_child(EnemyBuilder.build())

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

func receive_hit(amount: float, is_ice: bool, hit_pos: Vector3) -> void:
	if not _alive:
		return
	hp -= amount
	_flash_hit()
	if is_ice:
		_apply_freeze(2.4)
		_spawn_ice_burst(hit_pos)
	if hp <= 0.0:
		_alive = false
		hp = 0.0
		_set_frozen(false)
		died.emit()
		var tw := create_tween()
		tw.tween_property(visual_root, "scale", Vector3(1.1, 0.15, 1.1), 0.45)
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
			_freeze_vfx.position = Vector3(0, 0, 0)
	else:
		if _freeze_vfx:
			_freeze_vfx.queue_free()
			_freeze_vfx = null

func _flash_hit() -> void:
	var tw := create_tween()
	tw.tween_property(visual_root, "scale", Vector3(1.08, 1.08, 1.08), 0.05)
	tw.tween_property(visual_root, "scale", Vector3.ONE, 0.1)

func _spawn_ice_burst(pos: Vector3) -> void:
	var fx := Node3D.new()
	get_parent().add_child(fx)
	fx.global_position = pos
	MeshKit.sphere(fx, "Nova", 0.5, Color(0.55, 0.9, 1.0), Vector3.ZERO, Color(0.35, 0.8, 1.0), 5.0)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector3(2.2, 2.2, 2.2), 0.35)
	tw.tween_callback(fx.queue_free)

func is_combat_alive() -> bool:
	return _alive
