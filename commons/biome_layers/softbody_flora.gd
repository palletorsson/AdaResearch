# softbody_flora.gd
# Seq 13: softbodies. Squishy mushrooms/flowers — spheres that pulse with
# time-driven scale distortion, standing in for true softbody sim.

extends Node3D

const DistributionField = preload("res://commons/biome_layers/distribution_field.gd")

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

	# Paint layers (opt-in): a "flower" distribution authored on the map places
	# by that field; otherwise the default ring footprint. See doc/PAINT_LAYERS.md.
	var positions: Array = []
	if DistributionField.has_layer_for(ctx, "flower"):
		positions = DistributionField.placements_for(ctx, "flower")
	else:
		var radius: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.75 + 4.0
		var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 1.0
		for i in 14:
			var angle: float = rng.randf() * TAU
			var r: float = rng.randf_range(exclude, radius)
			positions.append(grid_center + Vector3(cos(angle) * r, 0.0, sin(angle) * r))

	for pos in positions:
		_spawn_flora(pos, rng, stiffness, pressure, false)

	# Paint-only "mushroom" tier — same softbody form, earthy domed caps.
	# Same engine, different element. See doc/PAINT_LAYERS.md.
	if DistributionField.has_layer_for(ctx, "mushroom"):
		for pos in DistributionField.placements_for(ctx, "mushroom"):
			_spawn_flora(pos, rng, stiffness, pressure, true)


## One softbody stem+cap at `pos`. `is_mushroom` → flatter earthy/toadstool cap
## (vs the bright flower cap). Registers it for the _process wobble.
func _spawn_flora(pos: Vector3, rng: RandomNumberGenerator, stiffness: float, pressure: float, is_mushroom: bool) -> void:
	var root := Node3D.new()
	root.position = pos
	add_child(root)

	# Stem
	var stem := MeshInstance3D.new()
	var sm := CylinderMesh.new()
	sm.top_radius = 0.05
	sm.bottom_radius = 0.08
	sm.height = 0.5 if is_mushroom else 0.6
	sm.radial_segments = 6
	stem.mesh = sm
	stem.position.y = sm.height * 0.5
	_apply_mat(stem, Color(0.92, 0.90, 0.84) if is_mushroom else Color(0.85, 0.82, 0.7))
	root.add_child(stem)

	# Cap (the "soft" part)
	var cap := MeshInstance3D.new()
	var cm := SphereMesh.new()
	cm.radius = 0.26 if is_mushroom else 0.22
	cm.height = 0.26 if is_mushroom else 0.36   # flatter dome for mushrooms
	cm.radial_segments = 8
	cm.rings = 6
	cap.mesh = cm
	cap.position.y = sm.height + (0.04 if is_mushroom else 0.1)
	var col: Color
	if is_mushroom:
		# Earthy caps — brown/tan, with the odd toadstool red.
		col = Color(0.74, 0.18, 0.16) if rng.randf() < 0.25 else Color.from_hsv(0.07 + rng.randf() * 0.04, 0.45, 0.55 + rng.randf() * 0.2)
	else:
		col = Color.from_hsv(rng.randf(), 0.5, 0.95)
	_apply_mat(cap, col)
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
