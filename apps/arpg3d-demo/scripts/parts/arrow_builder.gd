extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Separate design piece: normal wooden arrow.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "ArrowVisual"
	# Shaft along +Z (flight direction)
	MeshKit.cylinder(root, "Shaft", 0.02, 0.7, Color(0.55, 0.38, 0.2), Vector3(0, 0, 0), Vector3(90, 0, 0))
	MeshKit.prism(root, "Head", Vector3(0.08, 0.14, 0.08), Color(0.65, 0.65, 0.7), Vector3(0, 0, 0.4), Vector3(90, 0, 0))
	MeshKit.box(root, "FletchA", Vector3(0.02, 0.1, 0.12), Color(0.75, 0.2, 0.18), Vector3(0.05, 0, -0.28))
	MeshKit.box(root, "FletchB", Vector3(0.02, 0.1, 0.12), Color(0.75, 0.2, 0.18), Vector3(-0.05, 0, -0.28))
	return root
