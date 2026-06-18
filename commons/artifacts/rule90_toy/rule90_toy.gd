extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name Rule90Toy

## @identity
## lineage: Rule 90 — the elementary CA whose XOR rule prints the Sierpinski gasket.
## essence: A pocket-sized space-time slab you hold; a single seed unfolds into a self-similar triangle.
## truth: The fractal was never drawn — it was already folded inside three bits. The rule is one contingent universe; this one is shaped like itself at every scale.

@export var rule: int = 90
@export var cols: int = 33
@export var gens: int = 26
@export var cell: float = 0.012
@export var step_period: float = 0.12

var _field: MultiMeshInstance3D
var _rows: Array = []
var _alive_col: Color = Color(0.7, 0.85, 1.0, 1)
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
	# small held slab near origin — a thin dark backing plate + the field
	var w := cols * cell
	var h := gens * cell
	var back := _matte_mat(Color(0.07, 0.08, 0.10), 0.5)
	add_child(_box(Vector3(0, 0, -0.012), Vector3(w + 0.03, h + 0.03, 0.012), back))

	_field = _make_field(cols, gens, cell, true)
	_field.position = Vector3(-w * 0.5, -h * 0.5, 0.0)
	add_child(_field)

	add_child(_billboard_label("RULE 90", Vector3(0, h * 0.5 + 0.05, 0.0), 18, _alive_col))

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
	for r in range(gens):
		var visible := r < _draw_to
		var row: PackedInt32Array = _rows[r] if r < _rows.size() else PackedInt32Array()
		for c in range(cols):
			var i := r * cols + c
			if visible and c < row.size() and row[c] == 1:
				mm.set_instance_color(i, _alive_col)
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
