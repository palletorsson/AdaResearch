# softbody_flora.gd
# Seq 13: softbodies. Squishy mushrooms/flowers — spheres that pulse with
# time-driven scale distortion, standing in for true softbody sim.

extends Node3D

var _flora: Array = []


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var stiffness: float = float(params.get("stiffness", 0.6))
	var pressure: float = float(params.get("pressure", 1.1))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0)) + 13

	var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.75 + 4.0
	var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 1.0
	var count: int = 14

	for i in count:
		var angle: float = rng.randf() * TAU
		var r: float = rng.randf_range(exclude, radius)
		var pos: Vector3 = grid_center + Vector3(cos(angle) * r, 0.0, sin(angle) * r)

		var root := Node3D.new()
		root.position = pos
		add_child(root)

		# Stem
		var stem := MeshInstance3D.new()
		var sm := CylinderMesh.new()
		sm.top_radius = 0.05
		sm.bottom_radius = 0.08
		sm.height = 0.6
		sm.radial_segments = 6
		stem.mesh = sm
		stem.position.y = 0.3
		_apply_mat(stem, Color(0.85, 0.82, 0.7))
		root.add_child(stem)

		# Cap (the "soft" part)
		var cap := MeshInstance3D.new()
		var cm := SphereMesh.new()
		cm.radius = 0.22
		cm.height = 0.36
		cm.radial_segments = 8
		cm.rings = 6
		cap.mesh = cm
		cap.position.y = 0.7
		var hue: float = rng.randf()
		_apply_mat(cap, Color.from_hsv(hue, 0.5, 0.95))
		root.add_child(cap)

		_flora.append({
			"cap": cap,
			"phase": rng.randf() * TAU,
			"stiffness": stiffness,
			"pressure": pressure,
			"base_scale": cap.scale,
		})


func _process(_delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	for f in _flora:
		var cap: MeshInstance3D = f.cap
		if not is_instance_valid(cap):
			continue
		var wobble: float = sin(t * (1.5 + f.stiffness) + f.phase) * 0.08
		cap.scale = f.base_scale * Vector3(
			f.pressure + wobble,
			f.pressure - wobble * 0.5,
			f.pressure + wobble
		)


func _apply_mat(mi: MeshInstance3D, col: Color) -> void:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.3
	mi.material_override = mat
