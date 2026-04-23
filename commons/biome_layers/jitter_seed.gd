# jitter_seed.gd
# Seq 7: randomness. FIRST random. Proto-critters wander as random walkers.
# randf() is legal from this layer onward.
#
# RENDERING: one MultiMeshInstance3D for all walkers, updated per-frame.

extends Node3D

var _mmi: MultiMeshInstance3D = null
var _walkers: Array = []  # {home: Vector3, velocity: Vector3, pos: Vector3, jitter: float}
var _rng: RandomNumberGenerator = null


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var count: int = int(params.get("walker_count", 12))
	var speed: float = float(params.get("walker_speed", 0.8))
	var jitter: float = float(params.get("jitter", 0.15))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	_rng = RandomNumberGenerator.new()
	_rng.seed = int(ctx.get("rng_seed", 0))

	var bounds: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size + 8.0
	var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 1.0

	var mesh := SphereMesh.new()
	mesh.radius = 0.12
	mesh.height = 0.24
	mesh.radial_segments = 6
	mesh.rings = 4
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.9
	mesh.surface_set_material(0, mat)

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh
	mm.instance_count = count

	for i in count:
		var angle: float = _rng.randf() * TAU
		var r: float = _rng.randf_range(exclude, bounds)
		var home: Vector3 = grid_center + Vector3(cos(angle) * r, 1.2, sin(angle) * r)
		var col: Color = Color.from_hsv(_rng.randf(), 0.4, 0.95)
		var vel: Vector3 = Vector3(_rng.randf() - 0.5, 0, _rng.randf() - 0.5).normalized() * speed
		_walkers.append({"home": home, "velocity": vel, "pos": home, "jitter": jitter})
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, home))
		mm.set_instance_color(i, col)

	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Walkers"
	_mmi.multimesh = mm
	_mmi.custom_aabb = AABB(Vector3(-30, -2, -30), Vector3(60, 8, 60))
	_mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_mmi)


func _process(delta: float) -> void:
	if _rng == null or _mmi == null:
		return
	var mm := _mmi.multimesh
	for i in _walkers.size():
		var w: Dictionary = _walkers[i]
		# Random walk with home tether
		w.velocity += Vector3(_rng.randf() - 0.5, 0, _rng.randf() - 0.5) * w.jitter
		if w.velocity.length() > 1.5:
			w.velocity = w.velocity.normalized() * 1.5
		w.pos += w.velocity * delta
		var pull: Vector3 = (w.home - w.pos) * 0.3
		w.velocity += pull * delta
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY, w.pos))
