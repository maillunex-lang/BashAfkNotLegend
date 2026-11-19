extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Separate design piece: longbow held by archer.

static func build() -> Node3D:
	var bow := Node3D.new()
	bow.name = "Bow"

	# Upper limb
	MeshKit.cylinder(bow, "LimbUpper", 0.035, 0.85, Color(0.42, 0.28, 0.14), Vector3(0, 0.42, 0), Vector3(0, 0, 18))
	# Lower limb
	MeshKit.cylinder(bow, "LimbLower", 0.035, 0.85, Color(0.42, 0.28, 0.14), Vector3(0, -0.42, 0), Vector3(0, 0, -18))
	# Grip
	MeshKit.cylinder(bow, "Grip", 0.05, 0.22, Color(0.2, 0.14, 0.08), Vector3(0, 0, 0))
	# String
	MeshKit.cylinder(bow, "String", 0.01, 1.55, Color(0.85, 0.82, 0.75), Vector3(0.18, 0, 0))
	# Tip ornaments
	MeshKit.sphere(bow, "TipTop", 0.045, Color(0.7, 0.55, 0.2), Vector3(-0.05, 0.82, 0))
	MeshKit.sphere(bow, "TipBot", 0.045, Color(0.7, 0.55, 0.2), Vector3(-0.05, -0.82, 0))

	return bow
