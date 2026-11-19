extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Separate design piece: ice arrow + crystal trail accents.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "IceArrowVisual"
	var ice := Color(0.55, 0.85, 1.0)
	var core := Color(0.75, 0.95, 1.0)

	MeshKit.cylinder(root, "Shaft", 0.025, 0.72, ice, Vector3(0, 0, 0), Vector3(90, 0, 0), Color(0.4, 0.8, 1.0), 2.5)
	MeshKit.prism(root, "CrystalHead", Vector3(0.12, 0.2, 0.12), core, Vector3(0, 0, 0.42), Vector3(90, 0, 0), Color(0.5, 0.9, 1.0), 4.0)
	MeshKit.sphere(root, "CoreGlow", 0.07, core, Vector3(0, 0, 0.1), Color(0.3, 0.75, 1.0), 5.0)
	for i in range(4):
		var a := float(i) * TAU / 4.0
		MeshKit.prism(root, "Shard_%d" % i, Vector3(0.05, 0.12, 0.05), ice, Vector3(cos(a) * 0.08, sin(a) * 0.08, -0.05), Vector3(40, 0, float(i) * 45), Color(0.4, 0.85, 1.0), 2.0)
	return root
