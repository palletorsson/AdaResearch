extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MaxQBasinRoom

## @identity
## name: "Settling: gradient descent toward max Q"
## tier: large
## lineage: two wells side by side — the deepest minimum is not the most alive one. A narrow
##   pit traps a single frozen shape; a broad shallow basin holds a thing that keeps moving.
## essence: A room with two basins you walk between. The DEAD well is deep and narrow: a rigid
##   body falls in and locks to one shape, never to stir again — lowest energy, zero life. The
##   ALIVE well is shallow and wide: a soft body lives there, jostled by every nudge, forever
##   re-finding a slightly different rest. Max Q is not the bottom of the deepest pit; it is the
##   liveliest minimum — the basin roomy enough to keep settling without ever being done.
## truth: "MAX Q IS THE LIVELIEST MINIMUM, NOT THE DEEPEST" — width beats depth for life
## applications: ecology, learning, design — robust, adaptive states over brittle optimal ones.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var floor_size: float = 7.0
@export var dead_x: float = -2.0
@export var alive_x: float = 2.0
@export var floor_col: Color = Color(0.12, 0.13, 0.16)
@export var dead_col: Color = Color(0.40, 0.42, 0.50)
@export var alive_col: Color = Color(0.50, 0.95, 0.65)
@export var live_body_col: Color = Color(0.55, 0.95, 0.70)
@export var label_col: Color = Color(0.86, 0.92, 0.98)

var _t: float = 0.0
var _sim = null
var _live_mm: MultiMesh = null
var _live_holder: Node3D = null
var _alive_center: Vector3 = Vector3.ZERO


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("floor_size"):
		floor_size = float(config["floor_size"])
	if config.has("alive_col"):
		alive_col = _parse_color(config["alive_col"], alive_col)
	if config.has("dead_col"):
		dead_col = _parse_color(config["dead_col"], dead_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sim = null
	_live_mm = null
	_live_holder = null
	_build()


func _well_mesh(center: Vector3, rim_radius: float, depth: float, narrow: bool, col: Color) -> MeshInstance3D:
	# A funnel of stacked rings — a basin in the floor. narrow = steep pit, wide = gentle bowl.
	var segs: int = 30
	var bands: int = 9
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	for b in range(bands + 1):
		var f: float = float(b) / float(bands)             # 0 rim -> 1 bottom
		var rr: float = rim_radius * (1.0 - f)
		# narrow well drops fast (f^0.5 steep walls); wide well is a soft parabola (f^2)
		var depth_f: float = (sqrt(f) if narrow else (f * f))
		var y: float = -depth * depth_f
		for s in range(segs + 1):
			var th: float = (float(s) / float(segs)) * TAU
			verts.append(center + Vector3(rr * cos(th), y, rr * sin(th)))
			normals.append(Vector3.UP)
	var stride: int = segs + 1
	for b in range(bands):
		for s in range(segs):
			var i0: int = b * stride + s
			var i1: int = b * stride + s + 1
			var i2: int = (b + 1) * stride + s + 1
			var i3: int = (b + 1) * stride + s
			indices.append_array([i0, i1, i2, i0, i2, i3])
	var am := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	var mat := _matte_mat(col, 0.5, 0.2)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.25 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# Room floor
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), _matte_mat(floor_col, 0.95, 0.1)))

	# DEAD well — deep and narrow.
	var dead_c := Vector3(dead_x, 0.0, 0.0)
	add_child(_well_mesh(dead_c, 0.9, 2.2, true, dead_col))
	# A single rigid frozen shape locked at the bottom — one cube, never moving.
	add_child(_box(dead_c + Vector3(0.0, -2.0, 0.0), Vector3(0.5, 0.5, 0.5), _matte_mat(dead_col, 0.6, 0.4)))
	add_child(_billboard_label("DEAD WELL\ndeep · narrow · one frozen shape", dead_c + Vector3(0.0, 1.4, 0.0), 18, Color(0.78, 0.80, 0.86)))

	# ALIVE well — shallow and wide.
	_alive_center = Vector3(alive_x, 0.0, 0.0)
	add_child(_well_mesh(_alive_center, 2.2, 0.7, false, alive_col))
	add_child(_billboard_label("ALIVE WELL\nshallow · wide · keeps re-finding", _alive_center + Vector3(0.0, 1.4, 0.0), 18, Color(0.70, 0.96, 0.78)))

	# A soft body living in the alive well — live MultiMesh of particles.
	var sim = SBShapes.make_jelly_grid(3, 3, 3, 0.22, 0.55)
	sim.gravity = Vector3(0.0, -2.6, 0.0)
	sim.damping = 0.97
	sim.floor_y = -10.0
	for i in sim.positions.size():
		sim.positions[i] += _alive_center + Vector3(0.0, 1.0, 0.0)
		sim.prev_positions[i] = sim.positions[i]
	_sim = sim
	for _i in 60:
		_constrain_alive()
		_sim.step()

	_live_holder = Node3D.new()
	add_child(_live_holder)
	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	var smesh := SphereMesh.new()
	smesh.radius = 0.11
	smesh.height = 0.22
	mm.mesh = smesh
	mm.instance_count = _sim.positions.size()
	_live_mm = mm
	mmi.multimesh = mm
	var bmat := StandardMaterial3D.new()
	bmat.albedo_color = live_body_col
	bmat.roughness = 0.4
	bmat.emission_enabled = true
	bmat.emission = live_body_col
	bmat.emission_energy_multiplier = 0.4 if emissive else 0.0
	mmi.material_override = bmat
	_live_holder.add_child(mmi)
	_refresh_live()

	add_child(_billboard_label("MAX Q IS THE LIVELIEST MINIMUM, NOT THE DEEPEST", Vector3(0.0, 3.6, 0.0), 28, label_col))


func _alive_floor_h(x: float, z: float) -> float:
	# Wide shallow parabola centred on the alive well.
	var d := Vector2(x - _alive_center.x, z - _alive_center.z)
	var f: float = clampf(d.length() / 2.2, 0.0, 1.0)
	return -0.7 * (f * f) + 0.11


func _constrain_alive() -> void:
	for i in _sim.positions.size():
		var p: Vector3 = _sim.positions[i]
		var fh: float = _alive_floor_h(p.x, p.z)
		if p.y < fh:
			_sim.positions[i].y = fh
			# Slide toward the basin centre (downhill).
			var to_center := Vector2(_alive_center.x - p.x, _alive_center.z - p.z)
			_sim.positions[i].x += to_center.x * 0.0015
			_sim.positions[i].z += to_center.y * 0.0015


func _refresh_live() -> void:
	if _live_mm == null:
		return
	for i in _sim.positions.size():
		var t := Transform3D.IDENTITY
		t.origin = _sim.positions[i]
		_live_mm.set_instance_transform(i, t)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim != null:
		# Periodic jostle — the alive body never finishes settling; it keeps re-finding.
		if fmod(_t, 2.5) < delta:
			for i in _sim.positions.size():
				_sim.positions[i] += Vector3(_rng.randf_range(-0.08, 0.08), _rng.randf_range(0.02, 0.12), _rng.randf_range(-0.08, 0.08))
		_constrain_alive()
		_sim.step()
		_refresh_live()
