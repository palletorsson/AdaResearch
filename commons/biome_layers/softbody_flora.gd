# softbody_flora.gd
# Seq 13: softbodies. Squishy mushrooms/flowers — stems + caps that pulse with a
# time-driven scale wobble, standing in for true softbody sim.
#
# BATCHED: all stems share one MultiMeshInstance3D, all caps another (2 draw calls
# total, not 2 per plant), and the wobble runs in a GPU vertex shader keyed off
# per-instance custom data — no per-frame CPU _process. Same pattern as the tree
# branch-merge and ca_surface MultiMesh consolidation.

extends Node3D

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")
const CAP_SHADER = preload("res://commons/biome_layers/softbody_cap.gdshader")


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var stiffness: float = float(params.get("stiffness", 0.6))
	var pressure: float = float(params.get("pressure", 1.1))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = float(ctx.get("cube_size", 1.0))

	var rng := RandomNumberGenerator.new()
	rng.seed = int(ctx.get("rng_seed", 0)) + 13

	# Gather placements. Paint layers (opt-in) place by their field; otherwise the
	# default ring footprint. mushroom is paint-only. See doc/PAINT_LAYERS.md.
	var entries: Array = []   # [{pos: Vector3, mush: bool}]
	if DistributionField.has_layer_for(ctx, "flower"):
		for pos in DistributionField.placements_for(ctx, "flower"):
			entries.append({"pos": pos, "mush": false})
	else:
		var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.75 + 4.0
		var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 1.0
		for i in 14:
			var angle: float = rng.randf() * TAU
			var r: float = rng.randf_range(exclude, radius)
			entries.append({"pos": grid_center + Vector3(cos(angle) * r, 0.0, sin(angle) * r), "mush": false})

	if DistributionField.has_layer_for(ctx, "mushroom"):
		for pos in DistributionField.placements_for(ctx, "mushroom"):
			entries.append({"pos": pos, "mush": true})

	if entries.is_empty():
		return
	_build_batched(entries, rng, stiffness, pressure)


## Build the two MultiMeshes (stems + caps) for every flora at once.
func _build_batched(entries: Array, rng: RandomNumberGenerator, stiffness: float, pressure: float) -> void:
	var n: int = entries.size()

	# Stems — one unit-radius tapered cylinder, scaled in Y per instance.
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.08
	stem_mesh.height = 1.0
	stem_mesh.radial_segments = 6
	var stem_mm := MultiMesh.new()
	stem_mm.transform_format = MultiMesh.TRANSFORM_3D
	stem_mm.use_colors = true                 # must precede instance_count
	stem_mm.mesh = stem_mesh
	stem_mm.instance_count = n

	# Caps — one unit sphere; per-instance transform sets radius/dome-flatten, the
	# wobble shader pulses it, instance custom data carries (phase, stiff, press).
	var cap_mesh := SphereMesh.new()
	cap_mesh.radius = 1.0
	cap_mesh.height = 2.0
	cap_mesh.radial_segments = 8
	cap_mesh.rings = 6
	var cap_mm := MultiMesh.new()
	cap_mm.transform_format = MultiMesh.TRANSFORM_3D
	cap_mm.use_colors = true                  # must precede instance_count
	cap_mm.use_custom_data = true             # must precede instance_count
	cap_mm.mesh = cap_mesh
	cap_mm.instance_count = n

	for i in n:
		var e: Dictionary = entries[i]
		var pos: Vector3 = e["pos"]
		var mush: bool = e["mush"]
		var stem_h: float = 0.5 if mush else 0.6

		stem_mm.set_instance_transform(i, Transform3D(
			Basis().scaled(Vector3(1.0, stem_h, 1.0)), pos + Vector3(0.0, stem_h * 0.5, 0.0)))
		stem_mm.set_instance_color(i, Color(0.92, 0.90, 0.84) if mush else Color(0.85, 0.82, 0.7))

		var cap_r: float = 0.26 if mush else 0.22
		var cap_half_h: float = (0.26 if mush else 0.36) * 0.5   # SphereMesh height → unit-sphere Y scale
		var cap_y: float = stem_h + (0.04 if mush else 0.1)
		cap_mm.set_instance_transform(i, Transform3D(
			Basis().scaled(Vector3(cap_r, cap_half_h, cap_r)), pos + Vector3(0.0, cap_y, 0.0)))

		var col: Color
		if mush:
			col = Color(0.74, 0.18, 0.16) if rng.randf() < 0.25 else Color.from_hsv(0.07 + rng.randf() * 0.04, 0.45, 0.55 + rng.randf() * 0.2)
		else:
			col = Color.from_hsv(rng.randf(), 0.5, 0.95)
		cap_mm.set_instance_color(i, col)
		# (phase, stiffness, pressure, _) → the wobble shader.
		cap_mm.set_instance_custom_data(i, Color(rng.randf() * TAU, stiffness, pressure, 0.0))

	var stems := MultiMeshInstance3D.new()
	stems.name = "FloraStems"
	stems.multimesh = stem_mm
	var stem_mat := StandardMaterial3D.new()
	stem_mat.vertex_color_use_as_albedo = true
	stems.material_override = stem_mat
	add_child(stems)

	var caps := MultiMeshInstance3D.new()
	caps.name = "FloraCaps"
	caps.multimesh = cap_mm
	var cap_mat := ShaderMaterial.new()
	cap_mat.shader = CAP_SHADER
	caps.material_override = cap_mat
	add_child(caps)

	print("  [softbody_flora] %d flora → 2 draw calls (was %d), GPU wobble" % [n, n * 2])
