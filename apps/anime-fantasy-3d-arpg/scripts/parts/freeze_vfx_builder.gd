extends RefCounted
const MeshKit = preload("res://scripts/parts/mesh_kit.gd")

## Ice cage / freeze aura around the bear.

static func build() -> Node3D:
	var root := Node3D.new()
	root.name = "FreezeVfx"
	var ice := Color(0.65, 0.92, 1.0, 0.85)
	MeshKit.cylinder(root, "Ring", 0.95, 0.1, ice, Vector3(0, 0.06, 0), Vector3.ZERO, Color(0.4, 0.85, 1.0), 2.5)
	for i in range(8):
		var ang := float(i) * TAU / 8.0
		MeshKit.prism(root, "Spike_%d" % i, Vector3(0.2, 1.15, 0.2), ice,
			Vector3(cos(ang) * 0.7, 0.65, sin(ang) * 0.7),
			Vector3(0, rad_to_deg(ang), 0), Color(0.45, 0.9, 1.0), 3.5)
	MeshKit.sphere(root, "Aura", 1.1, Color(0.5, 0.85, 1.0, 0.22), Vector3(0, 1.0, 0), Color(0.35, 0.8, 1.0), 1.8)
	return root


static func build_impact_burst() -> Node3D:
	var root := Node3D.new()
	root.name = "IceImpact"
	MeshKit.sphere(root, "Nova", 0.45, Color(0.6, 0.92, 1.0), Vector3.ZERO, Color(0.35, 0.85, 1.0), 6.0)
	for i in range(10):
		var a := float(i) * TAU / 10.0
		var elev := 0.15 + float(i % 3) * 0.12
		MeshKit.prism(root, "Shard%d" % i, Vector3(0.07, 0.32, 0.07), Color(0.75, 0.96, 1.0),
			Vector3(cos(a) * 0.25, elev, sin(a) * 0.25),
			Vector3(25, float(i) * 36.0, 15), Color(0.5, 0.9, 1.0), 4.0)
	var p := GPUParticles3D.new()
	p.name = "ImpactSparks"
	p.amount = 36
	p.lifetime = 0.55
	p.one_shot = true
	p.explosiveness = 0.95
	p.emitting = true
	var mat := ParticleProcessMaterial.new()
	mat.direction = Vector3(0, 1, 0)
	mat.spread = 80.0
	mat.initial_velocity_min = 2.5
	mat.initial_velocity_max = 5.5
	mat.gravity = Vector3(0, -4.0, 0)
	mat.scale_min = 0.06
	mat.scale_max = 0.18
	mat.color = Color(0.75, 0.95, 1.0)
	p.process_material = mat
	var draw := SphereMesh.new()
	draw.radius = 0.05
	draw.height = 0.1
	var dm := StandardMaterial3D.new()
	dm.albedo_color = Color(0.8, 0.97, 1.0)
	dm.emission_enabled = true
	dm.emission = Color(0.45, 0.9, 1.0)
	dm.emission_energy_multiplier = 5.0
	dm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	draw.material = dm
	p.draw_pass_1 = draw
	root.add_child(p)
	return root
