extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PressureDomeRoom

## @identity
## name: "Strain, pressure & elasticity"
## tier: large
## lineage: a balloon, made room-sized — internal pressure pushing the skin out, elastic
##   strain in the skin pulling it back, the two forces meeting at an equilibrium radius.
## essence: A room-scale pressurised soft dome, ~3m, that you stand under. Internal pressure
##   inflates it outward; the elastic membrane resists, storing strain. The dome breathes:
##   pressure rises and it swells, strain catches up and it relaxes. You are inside the
##   argument between push and pull that decides how big a soft thing becomes.
## truth: "PRESSURE PUSHES OUT, STRAIN PULLS BACK — THE SKIN FINDS THE BALANCE"
## applications: balloons, cells, airbags, pneumatic robots — shape held by a pressure budget.

@export var radius: float = 2.6
@export var rings: int = 14
@export var segs: int = 28
@export var pressure: float = 1.0
@export var floor_size: float = 7.0
@export var floor_col: Color = Color(0.13, 0.14, 0.17)
@export var skin_col: Color = Color(0.55, 0.80, 0.95)
@export var strut_col: Color = Color(0.30, 0.45, 0.60)
@export var label_col: Color = Color(0.86, 0.92, 0.98)

var _t: float = 0.0
var _dome: MeshInstance3D = null
var _dome_mat: StandardMaterial3D = null
var _base_verts: PackedVector3Array = PackedVector3Array()
var _base_normals: PackedVector3Array = PackedVector3Array()
var _indices: PackedInt32Array = PackedInt32Array()
var _readout: Label3D = null


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("radius"):
		radius = clampf(float(config["radius"]), 1.5, 3.4)
	if config.has("pressure"):
		pressure = clampf(float(config["pressure"]), 0.4, 1.6)
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("skin_col"):
		skin_col = _parse_color(config["skin_col"], skin_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_dome = null
	_dome_mat = null
	_base_verts = PackedVector3Array()
	_base_normals = PackedVector3Array()
	_indices = PackedInt32Array()
	_readout = null
	_build()


func _build_dome_arrays() -> void:
	# A hemisphere of vertices (a dome you stand under) — top cap + ring grid.
	_base_verts = PackedVector3Array()
	_base_normals = PackedVector3Array()
	_indices = PackedInt32Array()
	for r in range(rings + 1):
		var phi: float = (float(r) / float(rings)) * (PI * 0.5)  # 0 at top, PI/2 at floor
		var y: float = cos(phi)
		var rr: float = sin(phi)
		for s in range(segs + 1):
			var theta: float = (float(s) / float(segs)) * TAU
			var dir := Vector3(rr * cos(theta), y, rr * sin(theta))
			_base_verts.append(dir)         # unit hemisphere; scaled at render
			_base_normals.append(dir)
	var stride: int = segs + 1
	for r in range(rings):
		for s in range(segs):
			var i0: int = r * stride + s
			var i1: int = r * stride + s + 1
			var i2: int = (r + 1) * stride + s + 1
			var i3: int = (r + 1) * stride + s
			_indices.append_array([i0, i1, i2, i0, i2, i3])


func _dome_mesh(rad: float) -> ArrayMesh:
	var verts := PackedVector3Array()
	verts.resize(_base_verts.size())
	for i in _base_verts.size():
		# Per-vertex elastic wobble — strain ripples across the skin.
		var d: Vector3 = _base_verts[i]
		var ripple: float = 1.0 + 0.03 * sin(d.x * 5.0 + _t * 1.4) * cos(d.z * 5.0 - _t * 1.1)
		verts[i] = d * rad * ripple
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = _base_normals
	arrays[Mesh.ARRAY_INDEX] = _indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am


func _build() -> void:
	# Room floor
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), _matte_mat(floor_col, 0.95, 0.1)))
	# A ring of base struts the skin is anchored to (the rim of the balloon)
	var anchor_n: int = 10
	for i in range(anchor_n):
		var a: float = (float(i) / float(anchor_n)) * TAU
		var p := Vector3(cos(a) * radius, 0.0, sin(a) * radius)
		add_child(_cylinder(p + Vector3(0.0, 0.12, 0.0), 0.05, 0.24, _matte_mat(strut_col, 0.7)))

	_build_dome_arrays()

	_dome_mat = StandardMaterial3D.new()
	_dome_mat.albedo_color = Color(skin_col.r, skin_col.g, skin_col.b, 0.42)
	_dome_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_dome_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	_dome_mat.roughness = 0.25
	_dome_mat.emission_enabled = true
	_dome_mat.emission = skin_col
	_dome_mat.emission_energy_multiplier = 0.4 if emissive else 0.0

	_dome = MeshInstance3D.new()
	_dome.mesh = _dome_mesh(radius * pressure)
	_dome.material_override = _dome_mat
	add_child(_dome)

	# A small glowing pressure core at the centre (the source of the push)
	add_child(_sphere(Vector3(0.0, 0.4, 0.0), 0.18, _glow_mat(Color(0.98, 0.82, 0.40), 2.2)))

	_readout = _billboard_label(_readout_text(radius * pressure), Vector3(0.0, 3.6, 0.0), 30, label_col)
	add_child(_readout)


func _readout_text(r: float) -> String:
	return "PRESSURE PUSHES OUT, STRAIN PULLS BACK  ·  r=%.2fm" % r


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# The dome breathes: pressure oscillates, the equilibrium radius follows.
	var p: float = pressure * (1.0 + 0.06 * sin(_t * 0.6))
	var r: float = radius * p
	if _dome != null:
		_dome.mesh = _dome_mesh(r)
	if _readout != null:
		_readout.text = _readout_text(r)
