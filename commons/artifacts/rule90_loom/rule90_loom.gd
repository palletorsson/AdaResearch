extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name Rule90Loom

## @identity
## lineage: Rule 90 put to work — the Sierpinski-printing CA reframed as a Jacquard-style loom.
## essence: A standing frame weaves a bolt of cloth that scrolls upward, each new pick computed by left-XOR-right.
## truth: A design job done by a rule, not a designer. The pattern is endless yet fully specified — the loom never repeats and never improvises.

@export var rule: int = 90
@export var cols: int = 40
@export var rows_vis: int = 30
@export var cell: float = 0.014
@export var step_period: float = 0.12

var _field: MultiMeshInstance3D
var _row: PackedInt32Array = PackedInt32Array()     # current live pick (top of cloth)
var _buffer: Array = []                             # Array of PackedInt32Array — the visible bolt, [0]=top newest
var _warp_col: Color = Color(0.95, 0.55, 0.2, 1)    # lit thread
var _cloth_col: Color = Color(0.10, 0.07, 0.05, 1)  # ground cloth
var _accum: float = 0.0
var _step_count: int = 0


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
	bm.size = Vector3(cell_sz * 0.92, cell_sz * 0.92, cell_sz * 0.35)
	mm.mesh = bm
	mm.instance_count = cols_n * rows_n
	for r in range(rows_n):
		for c in range(cols_n):
			var i := r * cols_n + c
			var pos := Vector3(c * cell_sz, r * cell_sz, 0.0) if plane_xy else Vector3(c * cell_sz, 0.0, r * cell_sz)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, _cloth_col)
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
	var w := cols * cell
	var h := rows_vis * cell

	# --- loom frame: two uprights + top beam (cloth beam) + bottom warp beam ---
	var wood := _matte_mat(Color(0.22, 0.16, 0.10), 0.7, 0.0)
	var post_w := 0.05
	var fx := w * 0.5 + 0.06
	add_child(_box(Vector3(-fx, h * 0.5 + 0.05, 0.0), Vector3(post_w, h + 0.3, post_w), wood))
	add_child(_box(Vector3(fx, h * 0.5 + 0.05, 0.0), Vector3(post_w, h + 0.3, post_w), wood))
	# top cloth beam (rolls finished bolt) + bottom warp beam
	var beam := _steel_mat(Color(0.45, 0.40, 0.32))
	add_child(_cylinder_between(Vector3(-fx, h + 0.10, 0.0), Vector3(fx, h + 0.10, 0.0), 0.035, beam))
	add_child(_cylinder_between(Vector3(-fx, -0.05, 0.0), Vector3(fx, -0.05, 0.0), 0.035, beam))
	# a foot so it stands
	add_child(_box(Vector3(0, -0.10, 0.0), Vector3(w + 0.3, 0.06, 0.3), wood))

	# --- the cloth field: rows scroll upward toward the cloth beam ---
	_field = _make_field(cols, rows_vis, cell, true)
	_field.position = Vector3(-w * 0.5, 0.0, 0.0)
	add_child(_field)

	add_child(_billboard_label("RULE 90 LOOM", Vector3(0, h + 0.30, 0.0), 26, _warp_col))

	# --- pre-run: weave a full bolt so the first frame already shows Sierpinski cloth ---
	_seed()
	for r in range(rows_vis):
		_buffer.insert(0, _row.duplicate())
		_advance_pick()
	# trim to visible height
	while _buffer.size() > rows_vis:
		_buffer.resize(rows_vis)
	_redraw()


func _seed() -> void:
	rule = ((rule % 256) + 256) % 256
	_row = PackedInt32Array()
	_row.resize(cols)
	for c in range(cols):
		_row[c] = 0
	_row[cols / 2] = 1
	_buffer.clear()
	_step_count = 0


func _advance_pick() -> void:
	var out := PackedInt32Array()
	out.resize(cols)
	for c in range(cols):
		var l: int = _row[(c - 1 + cols) % cols]
		var m: int = _row[c]
		var rr: int = _row[(c + 1) % cols]
		var pat: int = (l << 2) | (m << 1) | rr
		out[c] = (rule >> pat) & 1
	_row = out
	_step_count += 1


func _redraw() -> void:
	# buffer[0] is the newest pick, drawn at the TOP row (r = rows_vis-1)
	var mm := _field.multimesh
	for r in range(rows_vis):
		var src := rows_vis - 1 - r          # top row reads buffer[0]
		var pick: PackedInt32Array = _buffer[src] if src < _buffer.size() else PackedInt32Array()
		for c in range(cols):
			var i := r * cols + c
			if c < pick.size() and pick[c] == 1:
				mm.set_instance_color(i, _warp_col)
			else:
				mm.set_instance_color(i, _cloth_col)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_period:
		return
	_accum = 0.0
	# weave one new pick, push onto the bolt, scroll old picks up and off
	_buffer.insert(0, _row.duplicate())
	if _buffer.size() > rows_vis:
		_buffer.resize(rows_vis)
	_advance_pick()
	# occasionally reseed so the gasket restarts and the bolt stays lively (still fully deterministic per run)
	if _step_count > rows_vis * 3:
		var keep := _buffer.duplicate()
		_seed()
		_buffer = keep
	_redraw()
