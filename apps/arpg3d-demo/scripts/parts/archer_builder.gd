extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")
const BowBuilder = preload("res://scripts/parts/bow_builder.gd")

## Separate design piece: archer body assembled from primitives.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "ArcherVisual"

	var cloak := Color(0.18, 0.28, 0.42)
	var leather := Color(0.35, 0.24, 0.15)
	var skin := Color(0.86, 0.68, 0.52)
	var hair := Color(0.2, 0.12, 0.08)

	# Legs
	MeshKit.capsule(root, "LegL", 0.11, 0.55, leather, Vector3(-0.12, 0.45, 0))
	MeshKit.capsule(root, "LegR", 0.11, 0.55, leather, Vector3(0.12, 0.45, 0))
	# Boots
	MeshKit.box(root, "BootL", Vector3(0.18, 0.12, 0.28), Color(0.15, 0.1, 0.07), Vector3(-0.12, 0.08, 0.05))
	MeshKit.box(root, "BootR", Vector3(0.18, 0.12, 0.28), Color(0.15, 0.1, 0.07), Vector3(0.12, 0.08, 0.05))
	# Torso / cloak
	MeshKit.capsule(root, "Torso", 0.22, 0.7, cloak, Vector3(0, 1.05, 0))
	MeshKit.box(root, "Belt", Vector3(0.5, 0.08, 0.28), Color(0.55, 0.42, 0.18), Vector3(0, 0.78, 0))
	# Arms
	MeshKit.capsule(root, "ArmL", 0.08, 0.48, cloak, Vector3(-0.32, 1.1, 0))
	MeshKit.capsule(root, "ArmR", 0.08, 0.48, skin, Vector3(0.34, 1.05, 0.05))
	# Head
	MeshKit.sphere(root, "Head", 0.18, skin, Vector3(0, 1.55, 0))
	MeshKit.sphere(root, "Hair", 0.19, hair, Vector3(0, 1.62, -0.02))
	# Quiver
	MeshKit.cylinder(root, "Quiver", 0.09, 0.55, Color(0.28, 0.18, 0.1), Vector3(-0.28, 1.15, -0.2), Vector3(15, 0, 20))
	for i in range(3):
		MeshKit.cylinder(root, "QuiverArrow_%d" % i, 0.015, 0.5, Color(0.7, 0.7, 0.65), Vector3(-0.28 + i * 0.03, 1.4, -0.22), Vector3(12, 0, 18))

	# Bow mount (right hand)
	var bow_mount := Node3D.new()
	bow_mount.name = "BowMount"
	bow_mount.position = Vector3(0.42, 1.05, 0.12)
	bow_mount.rotation_degrees = Vector3(0, 0, -8)
	root.add_child(bow_mount)
	bow_mount.add_child(BowBuilder.build())

	return root
