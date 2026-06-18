extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name ElementaryCaBench

## @identity
## lineage: Wolfram's elementary cellular automata — A New Kind of Science, the 256 one-dimensional rules.
## essence: A single lit seed falls through time on a bench; the rule below it rewrites every generation.
## truth: Eight bits name a universe. The same triangle holds order, fractal, and chaos — the run is the deep, not the rule.

@export var rule: int = 30
@export var cols: int = 48
@export var gens: int = 32
@export var cell: float = 0.0125
@export var step_period: float = 0.12

var _field: MultiMeshInstance3D
var _rows: Array = []          # Array of PackedInt32Array, one per generation
var _alive_col: Color = Color(0.35, 0.95, 1.0, 1)
var _dead_col: Color = Color(0.05, 0.05, 0.07, 1)
var _rule_cycle: PackedInt32Array = PackedInt32Array([30, 90, 110, 184])
var _rule_idx: int = 0
var _readout: Label3D
var _accum: float = 0.0
var _draw_to: int = 0           # how many generations are currently revealed


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
	# --- housing: bench base + pillar ---
	var steel := _steel_mat(Color(0.30, 0.32, 0.36))
	add_child(_box(Vector3(0, 0.10, 0), Vector3(1.1, 0.2, 0.7), steel))
	add_child(_box(Vector3(0, 0.50, -0.05), Vector3(0.22, 0.7, 0.22), steel))
	var top := _matte_mat(Color(0.12, 0.13, 0.16), 0.6)
	add_child(_box(Vector3(0, 0.86, 0), Vector3(0.95, 0.04, 0.6), top))

	# --- field, standing vertical on the bench top, facing +Z ---
	_field = _make_field(cols, gens, cell, true)
	var w := cols * cell
	var h := gens * cell
	_field.position = Vector3(-w * 0.5, 0.90, 0.0)
	add_child(_field)

	# --- label + readout ---
	add_child(_billboard_label("ELEMENTARY CA\n256 rules, 256 universes", Vector3(0, 1.6, 0), 28, _alive_col))
	_readout = _billboard_label("RULE 30", Vector3(0, 0.90 + h + 0.06, 0.0), 22, Color(1.0, 0.85, 0.4))
	add_child(_readout)

	# --- pre-run the CA so the first captured frame already shows the full triangle ---
	_seed_rule(rule)
	_compute_all()
	_draw_to = gens
	_redraw()
	_update_readout()


func _seed_rule(rl: int) -> void:
	rule = ((rl % 256) + 256) % 256
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


func _cell_color(state: int) -> Color:
	return _alive_col if state == 1 else _dead_col


func _redraw() -> void:
	var mm := _field.multimesh
	for r in range(gens):
		var visible := r < _draw_to
		var row: PackedInt32Array = _rows[r] if r < _rows.size() else PackedInt32Array()
		for c in range(cols):
			var i := r * cols + c
			if visible and c < row.size():
				mm.set_instance_color(i, _cell_color(row[c]))
			else:
				mm.set_instance_color(i, _dead_col)


func _update_readout() -> void:
	if _readout:
		_readout.text = "RULE %d" % rule


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
		# advance to the next rule in the cycle, reseed, replay reveal
		_rule_idx = (_rule_idx + 1) % _rule_cycle.size()
		_seed_rule(_rule_cycle[_rule_idx])
		_compute_all()
		_draw_to = 0
		_redraw()
		_update_readout()
