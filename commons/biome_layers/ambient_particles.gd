extends Node3D
## ambient_particles.gd — the sparse drift layer (replaces the abstract forms).
##
## Where the old automated biome put the "Kusama" abstract forms — floating_primitives
## and its transform stack (animated_primitives, color_tint, force_field, lattice_snap,
## wave_displace) — this puts a FAR sparser ambient particle field: a handful of soft
## motes drifting slowly in the void above the map. It holds the same position (the
## volume over the grid) but reads as atmosphere, not a counted lattice. Present from
## seq 1 and accrues forward, so the living kingdoms (plants, creatures) bloom amid it.
##
## An accrual layer: BiomeAccrualManager instantiates a Node3D, sets this script, and
## calls apply(ctx). It is skipped on `ground_only` maps (the accrual manager filters
## any non-ground layer there). See biome_contributions.json + doc/PAINT_LAYERS.md.

func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube: float = float(ctx.get("cube_size", 1.0))
	var center: Vector3 = ctx.get("grid_center",
		Vector3(float(dims.x) * cube * 0.5, 0.0, float(dims.z) * cube * 0.5))
	var budget: float = float(ctx.get("budget_scale", 1.0))

	var span_x: float = maxf(1.0, float(dims.x) * cube)
	var span_z: float = maxf(1.0, float(dims.z) * cube)
	# Sparse — a fraction of the old dot lattice. Scales gently with map area, then
	# by the population budget. Floored so tiny maps still get a few motes.
	var base_count: int = int(params.get("count", 26))
	var area_factor: float = clampf(sqrt(span_x * span_z) / 16.0, 0.5, 2.0)
	var count: int = maxi(4, int(round(float(base_count) * area_factor * clampf(budget, 0.2, 1.0))))

	var y_min: float = float(params.get("y_min", 1.4))
	var y_max: float = float(params.get("y_max", maxf(y_min + 1.5, float(dims.y) * cube + 4.0)))
	var drift: float = float(params.get("drift_speed", 0.18))
	var mote_size: float = float(params.get("size", 0.07))
	var col: Color = _parse_color(params.get("color", "#bfe3ff"))
	var energy: float = float(params.get("emission_energy", 1.4))

	var p := GPUParticles3D.new()
	p.name = "AmbientParticles"
	p.amount = count
	p.lifetime = float(params.get("lifetime", 9.0))
	p.preprocess = p.lifetime            # populate the field immediately (start mid-life)
	p.fixed_fps = 30
	p.position = Vector3(center.x, (y_min + y_max) * 0.5, center.z)
	# Cover the whole volume so Godot doesn't frustum-cull the field when the
	# camera doesn't include the emitter centroid (known sparse-field gotcha).
	var half := Vector3(span_x * 0.5, (y_max - y_min) * 0.5, span_z * 0.5)
	p.visibility_aabb = AABB(-half, half * 2.0)

	var pm := ParticleProcessMaterial.new()
	pm.emission_shape = ParticleProcessMaterial.EMISSION_SHAPE_BOX
	pm.emission_box_extents = half
	pm.gravity = Vector3.ZERO
	pm.direction = Vector3(0, 1, 0)
	pm.spread = 180.0                    # drift in every direction
	pm.initial_velocity_min = drift * 0.35
	pm.initial_velocity_max = drift
	pm.damping_min = 0.0
	pm.damping_max = 0.12
	pm.scale_min = 0.6
	pm.scale_max = 1.4
	p.process_material = pm

	# Soft additive billboard mote.
	var quad := QuadMesh.new()
	quad.size = Vector2(mote_size, mote_size)
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.blend_mode = BaseMaterial3D.BLEND_MODE_ADD
	mat.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
	mat.billboard_keep_scale = true
	mat.albedo_color = Color(col.r, col.g, col.b, 0.85)
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = energy
	quad.material = mat
	p.draw_pass_1 = quad

	add_child(p)
	print("  [ambient_particles] %d sparse motes over %.0f×%.0f, y=%.1f–%.1f" % [
		count, span_x, span_z, y_min, y_max])


func _parse_color(v) -> Color:
	if v is Color:
		return v
	if v is String and not String(v).is_empty():
		return Color(String(v))
	if v is Array and (v as Array).size() >= 3:
		return Color(float(v[0]), float(v[1]), float(v[2]))
	return Color(0.75, 0.89, 1.0)
