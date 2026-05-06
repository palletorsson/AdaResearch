# noise_dust.gd
# Seq 8: noise. FIRST noise — but NOT ground. Sparse floating motes of space
# dust carrying DNA, drifting on a noise field. Critters from later sequences
# will consume them. The biome starts to get nutrients, not terrain.
#
# RENDERING: two MultiMeshInstance3D — one for the dust cubes, one for the
# DNA spheres. ~180 motes in 2 draw calls instead of 360 MeshInstance3Ds.
# Per-frame drift updates the instance buffer.

extends Node3D

var _dust_mmi: MultiMeshInstance3D = null
var _dna_mmi: MultiMeshInstance3D = null
var _entries: Array = []  # each: {home: Vector3, phase: float}
var _noise: FastNoiseLite = null
var _drift_speed: float = 0.4
var _bounds: float = 16.0
var _center: Vector3 = Vector3.ZERO


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	var mote_count: int = int(params.get("mote_count", 180))
	_bounds = float(params.get("bounds", 16.0))
	_drift_speed = float(params.get("drift_speed", 0.4))
	var noise_scale: float = float(params.get("noise_scale", 0.12))
	var dna_color: Color = _parse_color(str(params.get("dna_color", "#8fe3ff")))
	var dust_color: Color = _parse_color(str(params.get("dust_color", "#c2c2d0")))

	_center = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)
	var exclude: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size * 0.5 + 0.5

	_noise = FastNoiseLite.new()
	_noise.seed = int(ctx.get("rng_seed", 0))
	_noise.noise_type = FastNoiseLite.TYPE_SIMPLEX
	_noise.frequency = noise_scale

	var rng := RandomNumberGenerator.new()
	rng.seed = _noise.seed + 1

	var transforms: Array[Transform3D] = []
	for i in mote_count:
		var angle: float = rng.randf() * TAU
		var r: float = rng.randf_range(exclude, _bounds)
		var y: float = rng.randf_range(0.5, _bounds * 0.7)
		var home: Vector3 = _center + Vector3(cos(angle) * r, y, sin(angle) * r)
		transforms.append(Transform3D(Basis.IDENTITY, home))
		_entries.append({"home": home, "phase": rng.randf() * TAU})

	_dust_mmi = _build_multimesh("DustCubes", _dust_mesh(dust_color, 0.4), transforms)
	_dna_mmi  = _build_multimesh("DnaSpheres", _dna_mesh(dna_color, 1.5), transforms)


func _process(_delta: float) -> void:
	if _noise == null or _dust_mmi == null or _dna_mmi == null:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var mm_dust := _dust_mmi.multimesh
	var mm_dna := _dna_mmi.multimesh
	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var home: Vector3 = entry.home
		var nx: float = _noise.get_noise_3d(home.x, home.y, t * 0.3)
		var nz: float = _noise.get_noise_3d(home.x + 100.0, home.y, t * 0.3)
		var ny: float = sin(t * 0.4 + entry.phase) * 0.3
		var pos: Vector3 = home + Vector3(nx, ny, nz) * _drift_speed
		var tr := Transform3D(Basis.IDENTITY, pos)
		mm_dust.set_instance_transform(i, tr)
		mm_dna.set_instance_transform(i, tr)


func _build_multimesh(node_name: String, mesh: Mesh, transforms: Array[Transform3D]) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.mesh = mesh
	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
	var mmi := MultiMeshInstance3D.new()
	mmi.name = node_name
	mmi.multimesh = mm
	mmi.custom_aabb = AABB(Vector3(-30, -10, -30), Vector3(60, 30, 60))
	mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(mmi)
	return mmi


func _dust_mesh(col: Color, emission: float) -> Mesh:
	var m := BoxMesh.new()
	m.size = Vector3(0.05, 0.05, 0.05)
	m.surface_set_material(0, _unshaded_mat(col, emission))
	return m


func _dna_mesh(col: Color, emission: float) -> Mesh:
	var m := SphereMesh.new()
	m.radius = 0.025
	m.height = 0.05
	m.radial_segments = 5
	m.rings = 3
	m.surface_set_material(0, _unshaded_mat(col, emission))
	return m


func _unshaded_mat(col: Color, emission: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = col
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = emission
	return mat


func _parse_color(hex: String) -> Color:
	if hex.begins_with("#") and hex.length() == 7:
		return Color(hex)
	return Color.WHITE
