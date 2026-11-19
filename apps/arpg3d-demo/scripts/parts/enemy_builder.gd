extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Separate design piece: melee brute enemy.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "EnemyVisual"

	var hide := Color(0.45, 0.18, 0.16)
	var bone := Color(0.82, 0.78, 0.68)
	var iron := Color(0.35, 0.36, 0.4)

	MeshKit.capsule(root, "LegL", 0.14, 0.6, hide, Vector3(-0.15, 0.48, 0))
	MeshKit.capsule(root, "LegR", 0.14, 0.6, hide, Vector3(0.15, 0.48, 0))
	MeshKit.capsule(root, "Torso", 0.3, 0.85, hide, Vector3(0, 1.15, 0))
	MeshKit.sphere(root, "Head", 0.24, Color(0.55, 0.22, 0.18), Vector3(0, 1.75, 0.05))
	MeshKit.sphere(root, "HornL", 0.06, bone, Vector3(-0.16, 1.95, 0))
	MeshKit.sphere(root, "HornR", 0.06, bone, Vector3(0.16, 1.95, 0))
	MeshKit.box(root, "PauldronL", Vector3(0.28, 0.18, 0.35), iron, Vector3(-0.38, 1.35, 0))
	MeshKit.box(root, "PauldronR", Vector3(0.28, 0.18, 0.35), iron, Vector3(0.38, 1.35, 0))
	# Cleaver
	var weapon := Node3D.new()
	weapon.name = "Cleaver"
	weapon.position = Vector3(0.55, 1.1, 0.1)
	weapon.rotation_degrees = Vector3(0, 0, -25)
	root.add_child(weapon)
	MeshKit.cylinder(weapon, "Handle", 0.04, 0.55, Color(0.25, 0.15, 0.1), Vector3(0, 0, 0))
	MeshKit.box(weapon, "Blade", Vector3(0.08, 0.7, 0.22), Color(0.55, 0.58, 0.62), Vector3(0, 0.55, 0))

	return root
