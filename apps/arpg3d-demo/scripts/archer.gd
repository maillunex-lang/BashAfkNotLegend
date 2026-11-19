extends CharacterBody3D

const ArcherBuilder = preload("res://scripts/parts/archer_builder.gd")
const ArrowScr = preload("res://scripts/arrow.gd")

signal shot_fired(shot_index: int, is_ice: bool)

@export var fire_interval: float = 0.75
@export var max_hp: float = 120.0

var hp: float = 120.0
var shot_count: int = 0
var target: Node3D = null
var _cooldown: float = 0.4
var _alive: bool = true

@onready var visual_root: Node3D = $Visual
@onready var muzzle: Marker3D = $Muzzle

func _ready() -> void:
	hp = max_hp
	collision_layer = 1
	collision_mask = 1
	if visual_root.get_child_count() == 0:
		visual_root.add_child(ArcherBuilder.build())

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	if target and is_instance_valid(target):
		var look := target.global_position
		look.y = global_position.y
		if look.distance_to(global_position) > 0.05:
			look_at(look, Vector3.UP)
	_cooldown -= delta
	if _cooldown <= 0.0 and target and is_instance_valid(target) and target.has_method("is_combat_alive") and target.call("is_combat_alive"):
		_fire()

func _fire() -> void:
	shot_count += 1
	var is_ice := (shot_count % 3) == 0
	_cooldown = fire_interval * (1.15 if is_ice else 1.0)
	var origin := muzzle.global_position
	var aim := target.global_position + Vector3(0, 1.1, 0)
	var dir := (aim - origin).normalized()
	var arrow = ArrowScr.new()
	get_parent().add_child(arrow)
	arrow.setup(origin, dir, is_ice)
	shot_fired.emit(shot_count, is_ice)
	_draw_bow_pulse(is_ice)

func _draw_bow_pulse(is_ice: bool) -> void:
	var bow: Node3D = visual_root.find_child("Bow", true, false) as Node3D
	if bow == null:
		return
	var base: Vector3 = bow.scale
	var tw := create_tween()
	tw.tween_property(bow, "scale", base * (1.18 if is_ice else 1.08), 0.08)
	tw.tween_property(bow, "scale", base, 0.12)

func receive_hit(amount: float, _is_ice: bool, _pos: Vector3) -> void:
	if not _alive:
		return
	hp -= amount
	if hp <= 0.0:
		_alive = false
		hp = 0.0

func is_combat_alive() -> bool:
	return _alive
