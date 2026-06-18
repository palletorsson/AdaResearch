extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name Rule110Computer

## @identity
## lineage: Rule 110 as a literal computer — Cook's proof that gliders on a periodic background emulate a cyclic tag system.
## essence: A framed console runs the CA; moving structures are flagged as signals, their crossings as collisions, under a UNIVERSAL lamp.
## truth: A machine made only of an edge condition. The same four bits that look like noise are, read as particles, a universal computer — the run is the program.

@export var rule: int = 110
@export var cols: int = 48
@export var gens: int = 32
@export var cell: float = 0.0125
@export var step_period: float = 0.12

var _field: MultiMeshInstance3D
var _rows: Array = []
var _bg_col: Color = Color(0.16, 0.14, 0.22, 1)     # structured background ether
var _signal_col: Color = Color(0.4, 1.0, 0.9, 1)    # gliders = signals
var _collide_col: Color = Color(1.0, 0.55, 0.25, 1) # collisions
var _dead_col: Color = Color(0.05, 0.05, 0.07, 1)
var _accum: float = 0.0
var _draw_to: int = 0
var _lamp_mat: StandardMaterial3D
var _lamp_phase: float = 0.0


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
	var w := cols * cell
	var h := gens * cell

	# --- computer housing: a console box with a framed bezel around the screen ---
	var case_mat := _matte_mat(Color(0.13, 0.14, 0.17), 0.6)
	add_child(_box(Vector3(0, 0.10, 0), Vector3(1.0, 0.2, 0.45), case_mat))            # base deck
	add_child(_box(Vector3(0, 0.62, -0.16), Vector3(0.96, 0.78, 0.05), case_mat))      # back panel
	# screen bezel (frame around the field)
	var bezel := _steel_mat(Color(0.35, 0.37, 0.42))
	var bx := w * 0.5 + 0.03
	var cy := 0.30 + h * 0.5
	add_child(_box(Vector3(-bx, cy, -0.13), Vector3(0.03, h + 0.07, 0.03), bezel))
	add_child(_box(Vector3(bx, cy, -0.13), Vector3(0.03, h + 0.07, 0.03), bezel))
	add_child(_box(Vector3(0, cy + h * 0.5 + 0.02, -0.13), Vector3(w + 0.09, 0.03, 0.03), bezel))
	add_child(_box(Vector3(0, cy - h * 0.5 - 0.02, -0.13), Vector3(w + 0.09, 0.03, 0.03), bezel))
	# dark screen backing
	add_child(_box(Vector3(0, cy, -0.145), Vector3(w + 0.02, h + 0.02, 0.01), _matte_mat(Color(0.03, 0.03, 0.04), 0.4)))

	# --- the field, inset in the bezel, facing +Z ---
	_field = _make_field(cols, gens, cell, true)
	_field.position = Vector3(-w * 0.5, 0.30, -0.135)
	add_child(_field)

	# --- UNIVERSAL lamp + label on the deck ---
	_lamp_mat = _glow_mat(_signal_col, 1.6)
	add_child(_sphere(Vector3(-0.4, 0.225, 0.16), 0.03, _lamp_mat))
	add_child(_billboard_label("UNIVERSAL", Vector3(-0.18, 0.235, 0.16), 18, _signal_col))
	add_child(_billboard_label("RULE 110 COMPUTER\ngliders are signals — collisions compute", Vector3(0, 0.30 + h + 0.12, 0.0), 24, _signal_col))

	# --- pre-run so the first frame shows a populated screen with classified cells ---
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
		first[c] = 1 if _rng.randf() < 0.5 else 0
	first[cols - 1] = 1
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


func _classify(r: int, c: int) -> int:
	# 0 = off, 1 = background, 2 = signal (glider edge), 3 = collision
	var row: PackedInt32Array = _rows[r]
	if row[c] == 0:
		return 0
	var left_on: bool = row[(c - 1 + cols) % cols] == 1
	var right_on: bool = row[(c + 1) % cols] == 1
	# a live cell with at least one dead horizontal neighbour reads as a moving boundary (glider front)
	var is_edge := (not left_on) or (not right_on)
	if not is_edge:
		return 1
	# collision: this edge cell sits where a left-moving and right-moving front meet between two rows
	if r > 0:
		var prev: PackedInt32Array = _rows[r - 1]
		var came_from_left: bool = prev[(c - 1 + cols) % cols] == 1
		var came_from_right: bool = prev[(c + 1) % cols] == 1
		if came_from_left and came_from_right and prev[c] == 0:
			return 3
	return 2


func _color_for(kind: int) -> Color:
	match kind:
		3:
			return _collide_col
		2:
			return _signal_col
		1:
			return _bg_col
		_:
			return _dead_col


func _redraw() -> void:
	var mm := _field.multimesh
	for r in range(gens):
		var visible := r < _draw_to and r < _rows.size()
		for c in range(cols):
			var i := r * cols + c
			if visible:
				mm.set_instance_color(i, _color_for(_classify(r, c)))
			else:
				mm.set_instance_color(i, _dead_col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# pulse the UNIVERSAL lamp
	_lamp_phase += delta
	if _lamp_mat:
		var e: float = 1.1 + 0.6 * (0.5 + 0.5 * sin(_lamp_phase * 3.0))
		_lamp_mat.emission_energy_multiplier = e if emissive else 0.0

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
