extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Readable ice comet for the dual-archer showcase.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "IceArrowVisual"
	var ice := Color(0.45, 0.88, 1.0)
	var core := Color(0.9, 0.98, 1.0)
	MeshKit.cylinder(root, "Shaft", 0.07, 1.4, ice, Vector3(0, 0, 0), Vector3(90, 0, 0), Color(0.25, 0.75, 1.0), 2.2)
	MeshKit.prism(root, "CrystalHead", Vector3(0.24, 0.42, 0.24), core, Vector3(0, 0, 0.85), Vector3(90, 0, 0), Color(0.4, 0.92, 1.0), 3.0)
	MeshKit.sphere(root, "CoreGlow", 0.16, core, Vector3(0, 0, 0.15), Color(0.3, 0.8, 1.0), 2.8)
	MeshKit.sphere(root, "Halo", 0.22, Color(0.55, 0.9, 1.0, 0.35), Vector3(0, 0, 0.05), Color(0.4, 0.85, 1.0), 1.2)
	for i in range(5):
		var a := float(i) * TAU / 5.0
		MeshKit.prism(root, "Shard_%d" % i, Vector3(0.06, 0.16, 0.06), ice,
			Vector3(cos(a) * 0.12, sin(a) * 0.12, -0.08),
			Vector3(35, 0, float(i) * 40.0), Color(0.4, 0.9, 1.0), 3.5)
	return root


static func build_trail_particles() -> GPUParticles3D:
	var p := GPUParticles3D.new()
	p.name = "IceTrail"
	p.amount = 40
	p.lifetime = 0.55
	p.randomness = 0.35
	p.visibility_aabb = AABB(Vector3(-3, -3, -3), Vector3(6, 6, 6))
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 0, -1)
	mat.spread = 20.0
	mat.initial_velocity_min = 0.5
	mat.initial_velocity_max = 1.4
	mat.gravity = Vector3(0, -0.1, 0)
	mat.scale_min = 0.12
	mat.scale_max = 0.28
	mat.color = Color(0.7, 0.95, 1.0, 0.9)
	p.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.08
	draw.height = 0.16
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.75, 0.95, 1.0, 0.75)
	dm.emission_enabled = true
	dm.emission = Color(0.4, 0.85, 1.0)
	dm.emission_energy_multiplier = 5.0
	dm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.material = dm
	p.draw_pass_1 = draw
	p.emitting = true
	return p


static func build_ribbon() -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "TrailRibbon"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.03
	mesh.bottom_radius = 0.1
	mesh.height = 1.6
	mi.mesh = mesh
	mi.rotation_degrees = Vector3(90, 0, 0)
	mi.position = Vector3(0, 0, -0.95)
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.9, 1.0, 0.55)
	m.emission_enabled = true
	m.emission = Color(0.35, 0.8, 1.0)
	m.emission_energy_multiplier = 4.5
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mi.material_override = m
	return mi
