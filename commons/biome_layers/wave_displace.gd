# wave_displace.gd
# Seq 6: wavefunctions. Position becomes a wave function.
# Four radial lines of cubes riding y = amp * sin(k*s - ω*t). Pure trig.
#
# RENDERING: single MultiMeshInstance3D — all 160 cubes in one draw call.
# Per-frame animation done via set_instance_transform() which only touches
# the instance buffer, not the scene graph. VR-safe: surface material,
# expanded custom_aabb.

extends Node3D

var _mmi: MultiMeshInstance3D = null
var _entries: Array = []  # each: {s: float, dir: Vector3}
var _k: float = 0.0
var _omega: float = 0.0
var _amp: float = 0.0
var _center: Vector3 = Vector3.ZERO


func apply(ctx: Dictionary) -> void:
	var params: Dictionary = ctx.get("params", {})
	_amp = float(params.get("amplitude", 0.6))
	var wavelength: float = float(params.get("wavelength", 6.0))
	_k = TAU / wavelength
	_omega = float(params.get("speed", 1.5))

	var grid_center: Vector3 = ctx.get("grid_center", Vector3.ZERO)
	var grid_dims: Vector3i = ctx.get("grid_dims", Vector3i(10, 1, 10))
	var cube_size: float = ctx.get("cube_size", 1.0)

	_center = grid_center
	var bounds: float = maxf(float(grid_dims.x), float(grid_dims.z)) * cube_size + 12.0
	var count: int = 40

	# Build one cube mesh shared across all instances. Colour gradient baked
	# into vertex colors via use_colors so each cube can still look distinct.
	var mesh := BoxMesh.new()
	mesh.size = Vector3(0.12, 0.12, 0.12)
	mesh.surface_set_material(0, _wave_material())

	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.mesh = mesh

	# Collect transforms + per-instance colors
	var transforms: Array[Transform3D] = []
	var colors: Array[Color] = []
	for line in 4:
		var theta: float = float(line) * PI * 0.5 + PI * 0.25
		var dir := Vector3(cos(theta), 0, sin(theta))
		for i in count:
			var s: float = lerp(cube_size * 2.0, bounds, float(i) / float(count - 1))
			var pos: Vector3 = _center + dir * s + Vector3(0, 2.5, 0)
			transforms.append(Transform3D(Basis.IDENTITY, pos))
			var t_norm: float = float(i) / float(count)
			colors.append(Color.from_hsv(0.55 + t_norm * 0.15, 0.5, 0.95))
			_entries.append({"s": s, "dir": dir})

	mm.instance_count = transforms.size()
	for i in transforms.size():
		mm.set_instance_transform(i, transforms[i])
		mm.set_instance_color(i, colors[i])

	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Wave"
	_mmi.multimesh = mm
	_mmi.custom_aabb = AABB(Vector3(-40, -4, -40), Vector3(80, 20, 80))
	_mmi.gi_mode = GeometryInstance3D.GI_MODE_DISABLED
	add_child(_mmi)


func _process(_delta: float) -> void:
	if _mmi == null or _mmi.multimesh == null:
		return
	var t: float = Time.get_ticks_msec() / 1000.0
	var mm := _mmi.multimesh
	for i in _entries.size():
		var entry: Dictionary = _entries[i]
		var s: float = entry.s
		var dir: Vector3 = entry.dir
		var y: float = _amp * sin(_k * s - _omega * t)
		mm.set_instance_transform(i, Transform3D(Basis.IDENTITY,
			_center + dir * s + Vector3(0, 2.5 + y, 0)))


func _wave_material() -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	# Emission pulls from vertex color too so animation keeps the gradient.
	mat.emission = Color(1, 1, 1)
	mat.emission_energy_multiplier = 0.8
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat
