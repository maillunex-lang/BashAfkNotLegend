extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Separate design piece: battle arena floor + props.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "Arena"

	# Ground plane
	var ground := MeshInstance3D.new()
	ground.name = "Ground"
	var plane := PlaneMesh.new()
	plane.size = Vector2(28, 28)
	ground.mesh = plane
	ground.material_override = MeshKit.mat(Color(0.22, 0.28, 0.24))
	root.add_child(ground)

	# Stone ring
	for i in range(12):
		var ang := float(i) * TAU / 12.0
		var x := cos(ang) * 9.5
		var z := sin(ang) * 9.5
		MeshKit.box(root, "Pillar_%d" % i, Vector3(0.55, 2.4, 0.55), Color(0.35, 0.34, 0.32), Vector3(x, 1.2, z))

	# Center dais
	MeshKit.cylinder(root, "Dais", 3.2, 0.25, Color(0.3, 0.33, 0.36), Vector3(0, 0.12, 0))
	MeshKit.cylinder(root, "DaisRim", 3.5, 0.08, Color(0.45, 0.4, 0.28), Vector3(0, 0.04, 0))

	# Torches
	for side in [-1, 1]:
		var torch := Node3D.new()
		torch.name = "Torch_%s" % ("L" if side < 0 else "R")
		torch.position = Vector3(side * 5.5, 0, -4.5)
		root.add_child(torch)
		MeshKit.cylinder(torch, "Pole", 0.08, 1.6, Color(0.25, 0.18, 0.12), Vector3(0, 0.8, 0))
		MeshKit.sphere(torch, "Flame", 0.22, Color(1.0, 0.55, 0.15), Vector3(0, 1.7, 0), Color(1.0, 0.45, 0.05), 4.0)

	# Soft fill light bounce plates (visual only)
	MeshKit.box(root, "ShadowCatcher", Vector3(20, 0.02, 20), Color(0.12, 0.14, 0.13, 0.35), Vector3(0, 0.01, 0))

	return root
