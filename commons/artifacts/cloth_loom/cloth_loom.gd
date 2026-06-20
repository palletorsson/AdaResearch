extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ClothLoom

## @identity
## name: "Cloth physics"
## tier: applied
## lineage: A grid of particles with structural, shear and bend springs — the standard
##   mass-spring cloth. Pin two corners, let gravity hang the rest, push wind through it.
## essence: A loom rig that puts cloth simulation to work: a flag (or sail) pinned along its
##   mast, draping and rippling in a steady breeze. A small readout reports the breeze strength
##   and the cloth's spring count — the sim made useful, holding a shape it never stops adjusting.
## truth: "PIN TWO CORNERS, LET GRAVITY DRAPE THE REST, WIND DOES THE DANCING"
## applications: flags, sails, garments, capes, tents — surfaces that hang, fold and catch the wind.

const SBShapes = preload("res://commons/soft_body/soft_body_shapes.gd")

@export var cloth_cols: int = 12
@export var cloth_rows: int = 8
@export var cell_size: float = 0.075
@export var breeze: float = 1.0
@export var cloth_col: Color = Color(0.86, 0.30, 0.34)
@export var frame_col: Color = Color(0.22, 0.20, 0.18)
@export var readout_col: Color = Color(0.98, 0.80, 0.48)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _sim = null
var _cloth_mi: MeshInstance3D = null
var _cloth_mesh: ArrayMesh = null
var _indices: PackedInt32Array = PackedInt32Array()
var _readout: Label3D = null
var _cloth_origin := Vector3(0.0, 1.02, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cloth_cols"):
		cloth_cols = int(clampf(float(config["cloth_cols"]), 6, 18))
	if config.has("cloth_rows"):
		cloth_rows = int(clampf(float(config["cloth_rows"]), 5, 14))
	if config.has("breeze"):
		breeze = clampf(float(config["breeze"]), 0.0, 3.0)
	if config.has("cloth_col"):
		cloth_col = _parse_color(config["cloth_col"], cloth_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_sim = null
	_cloth_mi = null
	_cloth_mesh = null
	_readout = null
	_build()


func _build() -> void:
	# Loom / mast frame — base, vertical mast, top arm. The "useful" rig.
	add_child(_box(Vector3(0.0, 0.04, 0.0), Vector3(0.5, 0.08, 0.5), _matte_mat(frame_col, 0.85)))
	add_child(_cylinder_between(Vector3(-0.02, 0.08, 0.0), Vector3(-0.02, 1.12, 0.0), 0.03, _steel_mat(Color(0.42, 0.40, 0.36))))
	add_child(_cylinder_between(Vector3(-0.02, 1.08, 0.0), Vector3(0.04 + float(cloth_cols) * cell_size, 1.08, 0.0), 0.022, _steel_mat(Color(0.42, 0.40, 0.36))))

	# Cloth pinned along its left (mast) edge so it streams out like a flag.
	var sim = SBShapes.make_cloth(cloth_cols, cloth_rows, cell_size, "left_column", 0.8, _cloth_origin)
	sim.gravity = Vector3(0.0, -3.2, 0.0)
	sim.damping = 0.97
	sim.floor_y = 0.1
	_sim = sim
	# Pre-settle so the very first capture shows a relaxed drape, not a flat sheet.
	for _i in 50:
		_apply_breeze(0.45)
		_sim.step()

	_build_cloth_mesh()

	# Readout panel beside the loom.
	add_child(_box(Vector3(0.30, 0.45, 0.0), Vector3(0.30, 0.20, 0.02), _matte_mat(Color(0.10, 0.11, 0.14), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.30, 0.45, 0.02), 15, readout_col)
	add_child(_readout)

	add_child(_billboard_label("PIN TWO CORNERS, WIND DOES THE DANCING", Vector3(0.10, 1.5, 0.0), 20, label_col))


func _build_cloth_mesh() -> void:
	# Triangle indices for the grid (fixed; only vertices move each frame).
	_indices = PackedInt32Array()
	for r in range(cloth_rows - 1):
		for c in range(cloth_cols - 1):
			var i0: int = r * cloth_cols + c
			var i1: int = r * cloth_cols + c + 1
			var i2: int = (r + 1) * cloth_cols + c + 1
			var i3: int = (r + 1) * cloth_cols + c
			_indices.append_array([i0, i1, i2, i0, i2, i3])

	_cloth_mesh = ArrayMesh.new()
	_cloth_mi = MeshInstance3D.new()
	_cloth_mi.mesh = _cloth_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = cloth_col
	mat.roughness = 0.6
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = cloth_col
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	_cloth_mi.material_override = mat
	add_child(_cloth_mi)
	_refresh_cloth()


func _refresh_cloth() -> void:
	if _cloth_mesh == null:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for i in _sim.positions.size():
		verts.append(_sim.positions[i])
		normals.append(Vector3.BACK)
	_recompute_cloth_normals(verts, normals)
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = _indices
	_cloth_mesh.clear_surfaces()
	_cloth_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _recompute_cloth_normals(verts: PackedVector3Array, out_normals: PackedVector3Array) -> void:
	for i in out_normals.size():
		out_normals[i] = Vector3.ZERO
	var tri_count: int = _indices.size() / 3
	for k in range(tri_count):
		var ia: int = _indices[k * 3]
		var ib: int = _indices[k * 3 + 1]
		var ic: int = _indices[k * 3 + 2]
		var n: Vector3 = (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		if n.length_squared() > 1e-12:
			n = n.normalized()
		out_normals[ia] += n
		out_normals[ib] += n
		out_normals[ic] += n
	for i in out_normals.size():
		var nn: Vector3 = out_normals[i]
		out_normals[i] = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.BACK


func _apply_breeze(amount: float) -> void:
	# Wind pushes along +Z (out of the mast) with vertical flutter; varies per-column.
	var gust: float = amount * (0.7 + 0.3 * sin(_t * 2.1))
	for i in _sim.positions.size():
		if _sim.pinned[i]:
			continue
		var col: int = i % cloth_cols
		var lift: float = sin(_t * 3.0 + float(col) * 0.6) * 0.5
		_sim.positions[i].z += gust * 0.02 * float(col) / float(cloth_cols)
		_sim.positions[i].y += gust * 0.004 * lift


func _readout_text() -> String:
	var spring_n: int = 0 if _sim == null else _sim.springs.size()
	return "CLOTH LOOM\nbreeze: %.2f\nsprings: %d\ndrape: live" % [breeze, spring_n]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	if _sim == null:
		return
	_apply_breeze(breeze)
	_sim.step()
	_refresh_cloth()
	if _readout != null:
		_readout.text = _readout_text()
