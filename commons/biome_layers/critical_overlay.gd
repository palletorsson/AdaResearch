# critical_overlay.gd
# Seq 18: post foundations crisis. A translucent grid overlay hints at
# bias visualization — the critical layer over the living world.

extends Node3D


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var opacity: float = float(params.get("opacity", 0.25))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	# Translucent warm-tinted dome above the map — "bias heatmap" stand-in.
	var dome := MeshInstance3D.new()
	var m := SphereMesh.new()
	m.radius = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.9 + 8.0
	m.height = m.radius * 1.2
	m.radial_segments = 24
	m.rings = 12
	m.is_hemisphere = true
	dome.mesh = m
	dome.position = grid_center + Vector3(0, 0.0, 0)

	var mat := StandardMaterial3D.new()
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode = BaseMaterial3D.CULL_FRONT  # render inside of dome
	var col := Color(1.0, 0.4, 0.3, opacity)
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.3
	dome.material_override = mat
	add_child(dome)
