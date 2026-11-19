extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Large readable teal/gold fantasy bow for showcase.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "FantasyBow"
	var teal := Color(0.1, 0.55, 0.58)
	var gold := Color(0.95, 0.75, 0.28)
	var ice := Color(0.45, 0.92, 1.0)
	MeshKit.cylinder(root, "Grip", 0.04, 0.18, Color(0.18, 0.12, 0.08), Vector3.ZERO)
	for i in range(7):
		var t := (float(i) + 0.5) / 7.0
		var z := lerpf(0.1, 0.95, t)
		var x := -0.08 * t * t * 5.0
		var r := lerpf(0.032, 0.016, t)
		MeshKit.cylinder(root, "U%d" % i, r, 0.16, teal, Vector3(x, 0, z), Vector3(10, 0, -22 * t), ice, 1.2)
		MeshKit.cylinder(root, "L%d" % i, r, 0.16, teal, Vector3(x, 0, -z), Vector3(-10, 0, 22 * t), ice, 1.2)
	MeshKit.sphere(root, "Gem", 0.045, ice, Vector3(0.04, 0, 0), ice, 5.0)
	MeshKit.cylinder(root, "RingU", 0.05, 0.03, gold, Vector3(0, 0, 0.28))
	MeshKit.cylinder(root, "RingL", 0.05, 0.03, gold, Vector3(0, 0, -0.28))
	MeshKit.sphere(root, "TipU", 0.04, gold, Vector3(-0.28, 0, 0.95), ice, 2.0)
	MeshKit.sphere(root, "TipL", 0.04, gold, Vector3(-0.28, 0, -0.95), ice, 2.0)
	MeshKit.cylinder(root, "String", 0.008, 1.85, Color(0.9, 0.98, 1.0), Vector3(0.2, 0, 0), Vector3.ZERO, ice, 2.5)
	root.scale = Vector3(1.35, 1.35, 1.35)
	return root
