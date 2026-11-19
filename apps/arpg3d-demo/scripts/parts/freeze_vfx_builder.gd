extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Separate design piece: ice cage / freeze aura around enemy.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "FreezeVfx"
	var ice := Color(0.65, 0.9, 1.0, 0.85)
	MeshKit.cylinder(root, "Ring", 0.7, 0.08, ice, Vector3(0, 0.05, 0), Vector3.ZERO, Color(0.4, 0.85, 1.0), 2.0)
	for i in range(6):
		var ang := float(i) * TAU / 6.0
		MeshKit.prism(root, "Spike_%d" % i, Vector3(0.18, 0.9, 0.18), ice, Vector3(cos(ang) * 0.55, 0.55, sin(ang) * 0.55), Vector3(0, rad_to_deg(ang), 0), Color(0.45, 0.9, 1.0), 3.0)
	MeshKit.sphere(root, "Aura", 0.85, Color(0.5, 0.85, 1.0, 0.25), Vector3(0, 1.0, 0), Color(0.35, 0.8, 1.0), 1.5)
	return root
