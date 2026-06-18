extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LangtonBench

## @identity
## lineage: Langton's ant on a bench — the canonical demonstration: ~10k steps of
##   apparent chaos, then a periodic "highway" emerges and runs forever.
## essence: Same two-line rule as the toy, but pre-run far enough that you see both
##   the messy central scribble AND the diagonal highway escaping from it.
## truth: Order that arrives if you wait. No one wrote the highway; it is a theorem
##   the run discovers. The neighbourhood is a politics — a single cell, deterministic,
##   yet unpredictable except by living it out. The run is the deep; the edge is alive.

@export var grid: int = 32
@export var cell_size: float = 0.018
@export var prerun_steps: int = 11000
@export var step_interval: float = 0.11
@export var on_color: Color = Color(0.95, 0.85, 0.35)
@export var ant_color: Color = Color(1.0, 0.25, 0.45)
@export var base_color: Color = Color(0.18, 0.19, 0.22)

var _field: MultiMeshInstance3D
var _state: Array = []
var _ax: int = 0
var _ay: int = 0
var _dir: int = 0
var _accum: float = 0.0


func _make_field(cols: int, rows: int, cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(cell * 0.88, cell * 0.88, cell * 0.88)
	mm.mesh = bm
	mm.instance_count = cols * rows
	for r in range(rows):
		for c in range(cols):
			var i: int = r * cols + c
			var pos := Vector3(c * cell, r * cell, 0.0) if plane_xy else Vector3(c * cell, 0.0, r * cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, Color(0.05, 0.05, 0.07, 1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.6 if emissive else 0.0
	mi.material_override = mat
	return mi


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("grid"):
		grid = int(config["grid"])
	if config.has("prerun_steps"):
		prerun_steps = int(config["prerun_steps"])
	if config.has("step_interval"):
		step_interval = float(config["step_interval"])
	if config.has("on_color"):
		on_color = _parse_color(config["on_color"], on_color)
	for ch in get_children():
		ch.queue_free()
	_build()


func _reset_state() -> void:
	_state = []
	for y in range(grid):
		var row: Array = []
		for x in range(grid):
			row.append(false)
		_state.append(row)
	_ax = grid / 2
	_ay = grid / 2
	_dir = 0


func _step_ant() -> void:
	var on: bool = _state[_ay][_ax]
	if on:
		_dir = (_dir + 3) % 4
	else:
		_dir = (_dir + 1) % 4
	_state[_ay][_ax] = not on
	match _dir:
		0: _ay += 1
		1: _ax += 1
		2: _ay -= 1
		3: _ax -= 1
	_ax = wrapi(_ax, 0, grid)
	_ay = wrapi(_ay, 0, grid)


func _paint() -> void:
	var mm: MultiMesh = _field.multimesh
	for y in range(grid):
		for x in range(grid):
			var i: int = y * grid + x
			if x == _ax and y == _ay:
				mm.set_instance_color(i, ant_color)
			elif _state[y][x]:
				mm.set_instance_color(i, on_color)
			else:
				mm.set_instance_color(i, Color(0.07, 0.07, 0.10, 1))


func _build() -> void:
	_reset_state()
	for _s in range(prerun_steps):
		_step_ant()

	# bench: base box + short pillar + vertical field on top facing +Z.
	var top_y: float = 0.85
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), _matte_mat(Color(0.13, 0.14, 0.16))))
	add_child(_box(Vector3(0.0, (top_y + 0.20) * 0.5, -0.05), Vector3(0.12, top_y - 0.20, 0.12), _steel_mat(Color(0.4, 0.42, 0.46))))

	_field = _make_field(grid, grid, cell_size, true)
	var span: float = grid * cell_size
	_field.position = Vector3(-span * 0.5, top_y, 0.10)
	add_child(_field)
	# backing panel just behind the field
	add_child(_box(Vector3(0.0, top_y + span * 0.5, 0.08), Vector3(span + 0.06, span + 0.06, 0.02), _matte_mat(base_color)))
	_paint()

	add_child(_billboard_label("LANGTON'S ANT\norder that arrives if you wait", Vector3(0.0, 1.6, 0.10), 24, on_color))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_interval:
		return
	_accum = 0.0
	for _s in range(8):
		_step_ant()
	_paint()
