extends Area3D

const ArrowBuilder = preload("res://scripts/parts/arrow_builder.gd")
const IceArrowBuilder = preload("res://scripts/parts/ice_arrow_builder.gd")
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

var velocity: Vector3 = Vector3.ZERO
var damage: float = 18.0
var is_ice: bool = false
var lifetime: float = 3.0
var _alive: bool = true
var _owner_team: String = "player"

func setup(from: Vector3, dir: Vector3, ice: bool) -> void:
	global_position = from
	is_ice = ice
	damage = 28.0 if ice else 16.0
	velocity = dir.normalized() * (15.0 if ice else 17.5)
	if dir.length() > 0.01:
		look_at(global_position + dir.normalized(), Vector3.UP)
	monitoring = true
	monitorable = false
	collision_layer = 0
	collision_mask = 2 # enemies
	var visual: Node3D = IceArrowBuilder.build() if ice else ArrowBuilder.build()
	add_child(visual)
	var shape := CollisionShape3D.new()
	var sphere := SphereShape3D.new()
	sphere.radius = 0.22
	shape.shape = sphere
	add_child(shape)
	body_entered.connect(_on_body)

func _physics_process(delta: float) -> void:
	if not _alive:
		return
	global_position += velocity * delta
	lifetime -= delta
	if lifetime <= 0.0:
		queue_free()

func _on_body(body: Node3D) -> void:
	if not _alive:
		return
	var target: Node = body
	if not target.has_method("receive_hit"):
		if target.get_parent() and target.get_parent().has_method("receive_hit"):
			target = target.get_parent()
		else:
			return
	_alive = false
	target.call("receive_hit", damage, is_ice, global_position)
	_spawn_impact(get_parent())
	queue_free()

func _spawn_impact(parent: Node) -> void:
	if parent == null:
		return
	var fx := Node3D.new()
	fx.name = "ImpactFx"
	parent.add_child(fx)
	fx.global_position = global_position
	if is_ice:
		MeshKit.sphere(fx, "Burst", 0.35, Color(0.6, 0.9, 1.0), Vector3.ZERO, Color(0.4, 0.85, 1.0), 6.0)
		for i in range(6):
			var a := float(i) * TAU / 6.0
			MeshKit.prism(fx, "Shard%d" % i, Vector3(0.08, 0.25, 0.08), Color(0.7, 0.95, 1.0), Vector3(cos(a) * 0.2, 0.1, sin(a) * 0.2), Vector3(20, 0, float(i) * 30.0), Color(0.5, 0.9, 1.0), 3.0)
	else:
		MeshKit.sphere(fx, "Sparks", 0.15, Color(1.0, 0.85, 0.4), Vector3.ZERO, Color(1.0, 0.7, 0.2), 3.0)
	var tw := fx.create_tween()
	tw.tween_property(fx, "scale", Vector3(1.9, 1.9, 1.9), 0.28)
	tw.tween_callback(fx.queue_free)
