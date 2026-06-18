extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name NeighbourhoodBench

## @identity
## lineage: A comparative CA rig — the same growth rule run under three different
##   definitions of "neighbour": Moore (8), von Neumann (4), hex (6).
## essence: Three small fields side by side on a bench, identically seeded, stepping
##   in lockstep. Only the neighbourhood differs, and the patterns diverge visibly:
##   blocky, plus-shaped, rounded.
## truth: THE NEIGHBOURHOOD IS A POLITICS. The rule is not the whole law — who you
##   count as adjacent decides what can live. Same seed, same threshold, three worlds.
##   Each neighbourhood a contingent constitution; the run shows you what it permits.

@export var grid: int = 22
@export var cell_size: float = 0.014
@export var step_interval: float = 0.13
@export var birth_lo: int = 2
@export var birth_hi: int = 3
@export var survive_lo: int = 2
@export var survive_hi: int = 4

var _fields: Array = []         # MultiMeshInstance3D per panel
var _states: Array = []         # state grid per panel
var _nexts: Array = []
var _modes: Array = ["moore", "neumann", "hex"]
var _colors: Array = [Color(0.95, 0.80, 0.35), Color(0.40, 0.80, 0.95), Color(0.55, 0.95, 0.65)]
var _accum: float = 0.0


func _make_field(cols: int, rows: int, cell: float, plane_xy: bool = true, hex_offset: bool = false) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new(); bm.size = Vector3(cell * 0.82, cell * 0.82, cell * 0.82)
	mm.mesh = bm
	mm.instance_count = cols * rows
	for r in range(rows):
		for c in range(cols):
			var i: int = r * cols + c
			var off: float = (cell * 0.5) if (hex_offset and r % 2 == 1) else 0.0
			var ry: float = (cell * 0.87) if hex_offset else cell
			var pos := Vector3(c * cell + off, r * ry, 0.0) if plane_xy else Vector3(c * cell + off, 0.0, r * ry)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, Color(0.05, 0.05, 0.07, 1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true; mat.emission = Color.WHITE; mat.emission_energy_multiplier = 0.18 if emissive else 0.0
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
	if config.has("step_interval"):
		step_interval = float(config["step_interval"])
	for ch in get_children():
		ch.queue_free()
	_build()


func _count(state: Array, mode: String, x: int, y: int) -> int:
	var deltas: Array
	match mode:
		"neumann":
			deltas = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
		"hex":
			if y % 2 == 0:
				deltas = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, -1), Vector2i(0, -1), Vector2i(-1, 1), Vector2i(0, 1)]
			else:
				deltas = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(1, -1), Vector2i(0, 1), Vector2i(1, 1)]
		_:  # moore
			deltas = [Vector2i(-1, -1), Vector2i(0, -1), Vector2i(1, -1), Vector2i(-1, 0), Vector2i(1, 0), Vector2i(-1, 1), Vector2i(0, 1), Vector2i(1, 1)]
	var n: int = 0
	for d: Vector2i in deltas:
		var nx: int = wrapi(x + d.x, 0, grid)
		var ny: int = wrapi(y + d.y, 0, grid)
		if state[ny][nx]:
			n += 1
	return n


func _step_panel(p: int) -> void:
	var state: Array = _states[p]
	var nxt: Array = _nexts[p]
	var mode: String = _modes[p]
	for y in range(grid):
		for x in range(grid):
			var n: int = _count(state, mode, x, y)
			if state[y][x]:
				nxt[y][x] = (n >= survive_lo and n <= survive_hi)
			else:
				nxt[y][x] = (n >= birth_lo and n <= birth_hi)
	_states[p] = nxt
	_nexts[p] = state


func _paint_panel(p: int) -> void:
	var mm: MultiMesh = _fields[p].multimesh
	var state: Array = _states[p]
	var col: Color = _colors[p]
	for y in range(grid):
		for x in range(grid):
			var i: int = y * grid + x
			if state[y][x]:
				mm.set_instance_color(i, col)
			else:
				mm.set_instance_color(i, Color(0.06, 0.06, 0.09, 1))


func _build() -> void:
	_fields = []
	_states = []
	_nexts = []

	# identical seed for all three panels (the controlled variable)
	var seed_grid: Array = []
	for y in range(grid):
		var row: Array = []
		for x in range(grid):
			row.append(_rng.randf() < 0.40)
		seed_grid.append(row)

	# bench housing
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.6, 0.2, 0.6), _matte_mat(Color(0.13, 0.14, 0.16))))
	add_child(_box(Vector3(0.0, 0.52, -0.06), Vector3(0.10, 0.6, 0.10), _steel_mat(Color(0.4, 0.42, 0.46))))

	var top_y: float = 0.85
	var span: float = grid * cell_size
	var labels: Array = ["MOORE (8)", "VON NEUMANN (4)", "HEX (6)"]
	var xs: Array = [-span - 0.18, 0.0, span + 0.18]

	for p in range(3):
		# copy seed into this panel's state + a blank next
		var st: Array = []
		var nx: Array = []
		for y in range(grid):
			var rr: Array = []
			var nr: Array = []
			for x in range(grid):
				rr.append(seed_grid[y][x])
				nr.append(false)
			st.append(rr)
			nx.append(nr)
		_states.append(st)
		_nexts.append(nx)

		var is_hex: bool = (_modes[p] == "hex")
		var f: MultiMeshInstance3D = _make_field(grid, grid, cell_size, true, is_hex)
		f.position = Vector3(float(xs[p]) - span * 0.5, top_y, 0.05)
		add_child(f)
		_fields.append(f)
		# pre-run a few steps so divergence already shows
		for _s in range(5):
			_step_panel(p)
		_paint_panel(p)

		add_child(_billboard_label(labels[p], Vector3(float(xs[p]), top_y - 0.10, 0.10), 13, _colors[p]))

	add_child(_billboard_label("THE NEIGHBOURHOOD IS A POLITICS", Vector3(0.0, top_y + span + 0.22, 0.05), 22, Color(0.95, 0.95, 1.0)))


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_interval:
		return
	_accum = 0.0
	for p in range(3):
		_step_panel(p)
		_paint_panel(p)
