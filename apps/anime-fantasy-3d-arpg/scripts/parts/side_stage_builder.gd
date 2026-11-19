extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## AFK Arena–style side stage: ground strip + layered backdrop (XY combat plane).

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "SideStage"

	# Ground strip along X
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var box := BoxMesh.new()
	box.size = Vector3(28, 0.15, 4.5)
	ground.mesh = box
	ground.position = Vector3(0, -0.075, 0)
	var gm := StandardMaterial3D.new()
	gm.albedo_color = Color(0.22, 0.28, 0.24)
	gm.roughness = 0.95
	ground.material_override = gm
	root.add_child(ground)

	# Battle lane highlight
	MeshKit.box(root, "Lane", Vector3(22, 0.04, 2.2), Color(0.32, 0.4, 0.36), Vector3(0, 0.02, 0))

	# Back wall / sky plate (behind combat, -Z)
	var backdrop := MeshInstance3D.new()
	backdrop.name = "Backdrop"
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 12)
	backdrop.mesh = plane
	backdrop.rotation_degrees = Vector3(90, 0, 0)
	backdrop.position = Vector3(0, 4.5, -3.2)
	var bm := StandardMaterial3D.new()
	bm.albedo_color = Color(0.35, 0.52, 0.68)
	bm.roughness = 1.0
	backdrop.material_override = bm
	root.add_child(backdrop)

	# Soft gradient band mid-backdrop
	MeshKit.box(root, "HorizonBand", Vector3(30, 1.8, 0.08), Color(0.55, 0.7, 0.82), Vector3(0, 2.2, -3.05))

	# Silhouette trees / pillars behind (depth layers)
	for i in range(9):
		var x := -10.0 + float(i) * 2.5
		var trunk_h := 1.6 + float(i % 3) * 0.35
		MeshKit.cylinder(root, "TreeTrunk%d" % i, 0.16, trunk_h, Color(0.25, 0.16, 0.1),
			Vector3(x, trunk_h * 0.5, -2.4 - float(i % 2) * 0.35))
		MeshKit.sphere(root, "TreeTop%d" % i, 0.85 + float(i % 2) * 0.15,
			Color(0.12, 0.28, 0.24), Vector3(x, trunk_h + 0.55, -2.4 - float(i % 2) * 0.35))

	for i in range(5):
		var x := -8.0 + float(i) * 4.0
		MeshKit.box(root, "Pillar%d" % i, Vector3(0.45, 2.8 + float(i % 2), 0.35),
			Color(0.4, 0.48, 0.55), Vector3(x, 1.5, -2.9))

	# Floor collider
	var floor_body := StaticBody3D.new()
	floor_body.name = "FloorBody"
	var col := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(28, 0.2, 4.5)
	col.shape = shape
	col.position = Vector3(0, -0.1, 0)
	floor_body.add_child(col)
	root.add_child(floor_body)
	return root
