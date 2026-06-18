extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name Rule30Rng

## @identity
## lineage: Rule 30 as Mathematica's RNG seed — a deterministic automaton tapped for its centre-column bits.
## essence: A small panel runs the rule; its middle column drips a bitstream into a row of flipping coin cells.
## truth: A machine with no dice inside becomes a dice. Determinism, run far enough, is indistinguishable from luck.

@export var rule: int = 30
@export var cols: int = 33
@export var gens: int = 24
@export var cell: float = 0.012
@export var bits_out: int = 8
@export var step_period: float = 0.12

var _field: MultiMeshInstance3D
var _rows: Array = []
var _alive_col: Color = Color(0.45, 0.9, 0.6, 1)
var _hot_col: Color = Color(1.0, 0.4, 0.3, 1)
var _dead_col: Color = Color(0.05, 0.05, 0.07, 1)
var _on_col: Color = Color(1.0, 0.85, 0.3, 1)
var _off_col: Color = Color(0.12, 0.12, 0.16, 1)
var _coins: Array = []          # Array of MeshInstance3D (the bit cells)
var _coin_mats: Array = []      # matching StandardMaterial3D
var _coin_labels: Array = []    # Array of Label3D ("0"/"1")
var _stream: PackedInt32Array = PackedInt32Array()
var _value_label: Label3D
var _accum: float = 0.0
var _cur_gen: int = 0           # which generation row we are emitting from


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
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _build() -> void:
	# --- device housing: a desktop unit ~1m ---
	var case_mat := _matte_mat(Color(0.16, 0.17, 0.20), 0.7)
	add_child(_box(Vector3(0, 0.10, 0), Vector3(1.0, 0.2, 0.5), case_mat))
	var panel := _matte_mat(Color(0.08, 0.09, 0.11), 0.5)
	# slanted-ish back panel that holds the CA
	add_child(_box(Vector3(0, 0.55, -0.18), Vector3(0.95, 0.7, 0.04), panel))

	# --- the Rule 30 panel on the back face, facing +Z ---
	_field = _make_field(cols, gens, cell, true)
	var w := cols * cell
	var h := gens * cell
	_field.position = Vector3(-w * 0.5, 0.30, -0.155)
	add_child(_field)

	# --- the output bitstream: a row of coin/bit cells on the deck ---
	var bw := 0.085
	var x0 := -((bits_out - 1) * bw) * 0.5
	_coins.clear()
	_coin_mats.clear()
	_coin_labels.clear()
	for b in range(bits_out):
		var m := _glow_mat(_off_col, 0.6)
		_coin_mats.append(m)
		var coin := _cylinder(Vector3(x0 + b * bw, 0.225, 0.16), 0.032, 0.02, m)
		coin.rotation = Vector3(0, 0, 0)
		add_child(coin)
		_coins.append(coin)
		var lbl := _billboard_label("0", Vector3(x0 + b * bw, 0.275, 0.16), 18, Color(0.9, 0.9, 0.95))
		add_child(lbl)
		_coin_labels.append(lbl)

	# --- labels / readout ---
	add_child(_billboard_label("RULE 30 RNG\ndeterminism as a dice", Vector3(0, 1.15, 0), 26, _hot_col))
	_value_label = _billboard_label("0x00", Vector3(0, 0.36, 0.18), 20, _on_col)
	add_child(_value_label)

	# --- pre-run: fill the CA and emit a first byte so the first frame reads as a working device ---
	_stream.resize(bits_out)
	for b in range(bits_out):
		_stream[b] = 0
	_seed()
	_compute_all()
	_cur_gen = 0
	for b in range(bits_out):
		_push_bit(_center_bit(_cur_gen))
		_cur_gen = (_cur_gen + 1) % gens
	_redraw_field()
	_redraw_coins()


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


func _center_bit(gen: int) -> int:
	if gen < 0 or gen >= _rows.size():
		return 0
	var row: PackedInt32Array = _rows[gen]
	return row[cols / 2]


func _push_bit(bit: int) -> void:
	# shift left, append newest bit at the end
	for b in range(bits_out - 1):
		_stream[b] = _stream[b + 1]
	_stream[bits_out - 1] = bit


func _redraw_field() -> void:
	var mm := _field.multimesh
	var mid := cols / 2
	for r in range(gens):
		var row: PackedInt32Array = _rows[r] if r < _rows.size() else PackedInt32Array()
		for c in range(cols):
			var i := r * cols + c
			if c < row.size() and row[c] == 1:
				mm.set_instance_color(i, _hot_col if c == mid else _alive_col)
			else:
				mm.set_instance_color(i, _dead_col)


func _redraw_coins() -> void:
	var value := 0
	for b in range(bits_out):
		var on := _stream[b] == 1
		_coin_mats[b].albedo_color = _on_col if on else _off_col
		_coin_mats[b].emission = _on_col if on else _off_col
		_coin_mats[b].emission_energy_multiplier = (1.4 if on else 0.4) if emissive else 0.0
		_coin_labels[b].text = "1" if on else "0"
		value = (value << 1) | _stream[b]
	if _value_label:
		_value_label.text = "0x%02X" % value


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_period:
		return
	_accum = 0.0
	# emit one fresh centre-column bit into the stream each step
	_push_bit(_center_bit(_cur_gen))
	_cur_gen += 1
	if _cur_gen >= gens:
		# exhausted this run's rows — reseed for a fresh deterministic stream
		_seed()
		_compute_all()
		_cur_gen = 0
	_redraw_field()
	_redraw_coins()
