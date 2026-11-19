extends Node3D

const IceArrowBuilder = preload("res://scripts/parts/ice_arrow_builder.gd")
const FreezeVfxBuilder = preload("res://scripts/parts/freeze_vfx_builder.gd")

var velocity: Vector3 = Vector3.ZERO
var damage: float = 32.0
var lifetime: float = 4.0
var _alive: bool = true
var _target: Node3D = null
var _hit_radius: float = 1.1

func setup(from: Vector3, dir: Vector3, target: Node3D = null) -> void:
	global_position = from
	_target = target
	velocity = dir.normalized() * 6.5
	if dir.length_squared() > 0.0001:
		# Avoid look_at singularity
		var up := Vector3.UP
		if absf(dir.normalized().dot(up)) > 0.95:
			up = Vector3.RIGHT
		look_at(global_position + dir.normalized(), up)
	add_child(IceArrowBuilder.build())
	add_child(IceArrowBuilder.build_ribbon())
	var trail := IceArrowBuilder.build_trail_particles()
	trail.position = Vector3(0, 0, -0.55)
	add_child(trail)
	var light := OmniLight3D.new()
	light.light_color = Color(0.55, 0.92, 1.0)
	light.light_energy = 1.6
	light.omni_range = 3.5
	add_child(light)

func _process(delta: float) -> void:
	if not _alive:
		return
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()
		return
	# Manual hit test — more reliable than Area3D for this demo
	if _target and is_instance_valid(_target) and _target.has_method("is_combat_alive") and _target.call("is_combat_alive"):
		var aim := _target.global_position + Vector3(0, 1.0, 0)
		if global_position.distance_to(aim) <= _hit_radius:
			_hit(_target)

func _hit(target: Node) -> void:
	if not _alive:
		return
	_alive = false
	if target.has_method("receive_hit"):
		target.call("receive_hit", damage, true, global_position)
	_spawn_impact(get_parent())
	queue_free()

func _spawn_impact(parent: Node) -> void:
	if parent == null:
		return
	var fx := FreezeVfxBuilder.build_impact_burst()
	parent.add_child(fx)
	fx.global_position = global_position
	var light := OmniLight3D.new()
	light.light_color = Color(0.6, 0.95, 1.0)
	light.light_energy = 5.0
	light.omni_range = 5.0
	fx.add_child(light)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector3(2.2, 2.2, 2.2), 0.35)
	tw.parallel().tween_property(light, "light_energy", 0.0, 0.4)
	tw.tween_callback(fx.queue_free)
