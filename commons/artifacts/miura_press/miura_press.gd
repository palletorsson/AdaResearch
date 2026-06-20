extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MiuraPress

## @identity
## name: "Origami & the Miura fold"
## tier: applied
## lineage: A press that collapses a flat sheet into a Miura-ori packed solid and back. The
##   zigzag crease pattern means one pull along a single axis folds the whole map — or solar
##   array — into a line, and one push opens it flat again.
## truth: "ONE CREASE PATTERN, ONE PULL — THE WHOLE FLAT SHEET COLLAPSES TO A LINE AND BACK"
## applications: deployable solar arrays, folding maps, packed antennas, stents, self-folding
##   metamaterials — area stored in a fold, opened on command.

@export var cols: int = 8       # crease columns
@export var rows: int = 5       # crease rows
@export var cell: float = 0.12
@export var fold_rate: float = 0.35
@export var sheet_col: Color = Color(0.85, 0.72, 0.30)
@export var crease_col: Color = Color(0.55, 0.45, 0.18)
@export var frame_col: Color = Color(0.2, 0.21, 0.25)
@export var readout_col: Color = Color(0.98, 0.82, 0.50)
@export var label_col: Color = Color(0.92, 0.95, 0.99)

var _t: float = 0.0
var _fold: float = 0.0          # 0 = flat, 1 = fully packed
var _mesh: ArrayMesh = null
var _mi: MeshInstance3D = null
var _indices: PackedInt32Array = PackedInt32Array()
var _plate: MeshInstance3D = null
var _readout: Label3D = null
var _origin := Vector3(0.0, 0.5, 0.0)


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cols"):
		cols = int(clampf(float(config["cols"]), 4, 12))
	if config.has("rows"):
		rows = int(clampf(float(config["rows"]), 3, 8))
	if config.has("sheet_col"):
		sheet_col = _parse_color(config["sheet_col"], sheet_col)
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_mesh = null
	_mi = null
	_plate = null
	_readout = null
	_fold = 0.0
	_build()


func _build() -> void:
	# Press frame: base, two posts, a moving top plate.
	add_child(_box(Vector3(0.0, 0.05, 0.0), Vector3(1.2, 0.1, 0.7), _matte_mat(frame_col, 0.85)))
	add_child(_cylinder_between(Vector3(-0.55, 0.1, -0.28), Vector3(-0.55, 1.0, -0.28), 0.03, _steel_mat(Color(0.5, 0.5, 0.55))))
	add_child(_cylinder_between(Vector3(0.55, 0.1, -0.28), Vector3(0.55, 1.0, -0.28), 0.03, _steel_mat(Color(0.5, 0.5, 0.55))))
	_plate = _box(Vector3(0.0, 1.0, 0.0), Vector3(1.1, 0.05, 0.6), _steel_mat(Color(0.45, 0.45, 0.5)))
	add_child(_plate)

	# The Miura sheet (built as one ArrayMesh, vertices repositioned per frame).
	_build_sheet_mesh()

	# Readout.
	add_child(_box(Vector3(0.0, 0.85, 0.32), Vector3(0.4, 0.14, 0.02), _matte_mat(Color(0.08, 0.09, 0.12), 0.4)))
	_readout = _billboard_label(_readout_text(), Vector3(0.0, 0.85, 0.34), 14, readout_col)
	add_child(_readout)

	add_child(_billboard_label("MIURA PRESS — ONE PULL FOLDS THE WHOLE SHEET", Vector3(0.0, 1.2, 0.0), 18, label_col))


func _build_sheet_mesh() -> void:
	_indices = PackedInt32Array()
	for r in range(rows - 1):
		for c in range(cols - 1):
			var i0: int = r * cols + c
			var i1: int = r * cols + c + 1
			var i2: int = (r + 1) * cols + c + 1
			var i3: int = (r + 1) * cols + c
			_indices.append_array([i0, i1, i2, i0, i2, i3])
	_mesh = ArrayMesh.new()
	_mi = MeshInstance3D.new()
	_mi.mesh = _mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = sheet_col
	mat.roughness = 0.5
	mat.metallic = 0.2
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.emission_enabled = true
	mat.emission = sheet_col
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	_mi.material_override = mat
	add_child(_mi)
	_refresh_sheet()


func _miura_vertex(c: int, r: int, fold: float) -> Vector3:
	# Standard Miura-ori parametrization.
	# Flat layout in X (cols) and Z (rows); folding raises a zigzag in Y and
	# compresses X, while the row offset shears in Z (the parallelogram crease).
	var fold_ang: float = fold * 1.2   # max dihedral fold
	var col_phase: float = float(c)
	var row_phase: float = float(r)
	# X compresses as it folds.
	var x: float = (col_phase - float(cols - 1) * 0.5) * cell * (1.0 - fold * 0.55)
	# Zigzag in Y: alternating columns rise/sink with fold.
	var y: float = sin(col_phase * PI) * sin(fold_ang) * cell * 0.9
	# Z shear: odd rows offset by the fold — the Miura parallelogram.
	var z_base: float = (row_phase - float(rows - 1) * 0.5) * cell
	var shear: float = (float(c % 2) - 0.5) * fold * cell * 0.5
	var z: float = z_base * (1.0 - fold * 0.15) + shear
	return _origin + Vector3(x, y, z)


func _refresh_sheet() -> void:
	if _mesh == null:
		return
	var verts := PackedVector3Array()
	var normals := PackedVector3Array()
	for r in range(rows):
		for c in range(cols):
			verts.append(_miura_vertex(c, r, _fold))
			normals.append(Vector3.UP)
	# Recompute normals from triangles.
	for i in normals.size():
		normals[i] = Vector3.ZERO
	var tri: int = _indices.size() / 3
	for k in range(tri):
		var ia: int = _indices[k * 3]
		var ib: int = _indices[k * 3 + 1]
		var ic: int = _indices[k * 3 + 2]
		var n: Vector3 = (verts[ib] - verts[ia]).cross(verts[ic] - verts[ia])
		if n.length_squared() > 1e-12:
			n = n.normalized()
		normals[ia] += n
		normals[ib] += n
		normals[ic] += n
	for i in normals.size():
		var nn: Vector3 = normals[i]
		normals[i] = nn.normalized() if nn.length_squared() > 1e-12 else Vector3.UP
	var arrays: Array = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = _indices
	_mesh.clear_surfaces()
	_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)


func _readout_text() -> String:
	var pct: int = int(round(_fold * 100.0))
	return "MIURA PRESS\nfold: %d%%\ncreases: %dx%d" % [pct, cols, rows]


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_t += delta
	# Oscillate fold<->unfold.
	_fold = sin(_t * TAU * fold_rate) * 0.5 + 0.5
	_refresh_sheet()
	# Press plate descends as the sheet packs.
	if _plate != null:
		_plate.position.y = lerpf(1.0, _origin.y + 0.12, _fold)
	if _readout != null:
		_readout.text = _readout_text()
