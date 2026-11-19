extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "Arena"
	# Snowy clearing
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(40, 40)
	ground.mesh = plane
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.32, 0.38, 0.34)
	gm.roughness = 0.97
	ground.material_override = gm
	root.add_child(ground)

	# Soft snow ring
	MeshKit.cylinder(root, "SnowRing", 7.5, 0.08, Color(0.45, 0.52, 0.48), Vector3(0, 0.02, 0), Vector3.ZERO)

	# Standing stones
	for i in range(8):
		var a := float(i) * TAU / 8.0
		var h := 1.4 + float(i % 3) * 0.35
		MeshKit.box(root, "Stone%d" % i, Vector3(0.55, h, 0.4), Color(0.45, 0.52, 0.58),
			Vector3(cos(a) * 9.5, h * 0.5, sin(a) * 9.5), Vector3(0, rad_to_deg(a), 0))

	# Distant pines (simple cones)
	for i in range(14):
		var a := float(i) * TAU / 14.0 + 0.2
		var d := 12.0 + float(i % 4) * 1.4
		var pine := Node3D.new()
		pine.name = "Pine%d" % i
		pine.position = Vector3(cos(a) * d, 0, sin(a) * d)
		MeshKit.cylinder(pine, "Trunk", 0.18, 1.2, Color(0.28, 0.18, 0.1), Vector3(0, 0.6, 0))
		MeshKit.sphere(pine, "Canopy", 1.1, Color(0.15, 0.32, 0.28), Vector3(0, 2.0, 0))
		MeshKit.sphere(pine, "Canopy2", 0.85, Color(0.18, 0.38, 0.32), Vector3(0, 2.7, 0))
		root.add_child(pine)

	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorBody"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(40, 0.2, 40)
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	floor_body.add_child(col)
	root.add_child(floor_body)
	return root
