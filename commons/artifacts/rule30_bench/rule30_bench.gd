extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name Rule30Bench

## @identity
## lineage: Stephen Wolfram's Rule 30 — the elementary CA Mathematica used as its randomness source.
## essence: One seed, a deterministic local rule, and a triangle that scrambles into noise; the centre column is the dice.
## truth: Perfect order run forward becomes chance. The rule is knowable, the column is not — the deep lives in the running.

@export var rule: int = 30
@export var cols: int = 48
@export var gens: int = 32
@export var cell: float = 0.0125
@export var step_period: float = 0.12

var _field: MultiMeshInstance3D
var _rows: Array = []
var _alive_col: Color = Color(0.55, 0.95, 0.6, 1)
var _hot_col: Color = Color(1.0, 0.35, 0.25, 1)
var _dead_col: Color = Color(0.05, 0.05, 0.07, 1)
var _accum: float = 0.0
var _draw_to: int = 0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("rule"):
		rule = int(config["rule"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _make_field(cols_n: int, rows_n: int, cell_sz: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(cell_sz * 0.88, cell_sz * 0.88, cell_sz * 0.88)
	mm.mesh = bm
	mm.instance_count = cols_n * rows_n
	for r in range(rows_n):
		for c in range(cols_n):
			var i := r * cols_n + c
			var pos := Vector3(c * cell_sz, r * cell_sz, 0.0) if plane_xy else Vector3(c * cell_sz, 0.0, r * cell_sz)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, _dead_col)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	var steel := _steel_mat(Color(0.30, 0.32, 0.36))
	add_child(_box(Vector3(0, 0.10, 0), Vector3(1.1, 0.2, 0.7), steel))
	add_child(_box(Vector3(0, 0.50, -0.05), Vector3(0.22, 0.7, 0.22), steel))
	var top := _matte_mat(Color(0.12, 0.13, 0.16), 0.6)
	add_child(_box(Vector3(0, 0.86, 0), Vector3(0.95, 0.04, 0.6), top))

	_field = _make_field(cols, gens, cell, true)
	var w := cols * cell
	var h := gens * cell
	_field.position = Vector3(-w * 0.5, 0.90, 0.0)
	add_child(_field)

	add_child(_billboard_label("RULE 30\norder, run forward, becomes chance", Vector3(0, 1.6, 0), 28, _hot_col))
	# a thin hot marker behind the centre column, naming the bit-stream
	var marker := _glow_mat(_hot_col, 1.4)
	add_child(_box(Vector3(0, 0.90 + h * 0.5, -0.01), Vector3(cell * 1.1, h, 0.004), marker))

	_seed()
	_compute_all()
	_draw_to = gens
	_redraw()


func _seed() -> void:
	rule = ((rule % 256) + 256) % 256
	_rows.clear()
	var first := PackedInt32Array()
	first.resize(cols)
	for c in range(cols):
		first[c] = 0
	first[cols / 2] = 1
	_rows.append(first)


func _next_row(prev: PackedInt32Array) -> PackedInt32Array:
	var out := PackedInt32Array()
	out.resize(cols)
	for c in range(cols):
		var l: int = prev[(c - 1 + cols) % cols]
		var m: int = prev[c]
		var rr: int = prev[(c + 1) % cols]
		var pat: int = (l << 2) | (m << 1) | rr
		out[c] = (rule >> pat) & 1
	return out


func _compute_all() -> void:
	while _rows.size() < gens:
		_rows.append(_next_row(_rows[_rows.size() - 1]))


func _redraw() -> void:
	var mm := _field.multimesh
	var mid := cols / 2
	for r in range(gens):
		var visible := r < _draw_to
		var row: PackedInt32Array = _rows[r] if r < _rows.size() else PackedInt32Array()
		for c in range(cols):
			var i := r * cols + c
			if visible and c < row.size() and row[c] == 1:
				mm.set_instance_color(i, _hot_col if c == mid else _alive_col)
			else:
				mm.set_instance_color(i, _dead_col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_period:
		return
	_accum = 0.0
	if _draw_to < gens:
		_draw_to += 1
		_redraw()
	else:
		_seed()
		_compute_all()
		_draw_to = 0
		_redraw()
