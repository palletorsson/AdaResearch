extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name LangtonSwarm

## @identity
## lineage: Turmite swarm — many Langton-style ants sharing one surface, the
##   generative-art use of the rule: simple agents, emergent texture.
## essence: A device (~1m) that paints. 8-16 ants crawl a shared grid, each flipping
##   colours under a turmite rule; their interference weaves a pattern no single ant
##   intends. A readout counts the live agents.
## truth: The neighbourhood is a politics — and a crowd of them is a society. No
##   agent sees the whole; the image is what their collisions agree on. Each ant a
##   contingent universe, overlaid; the run is the deep, the edge alive with them.

@export var grid: int = 40
@export var cell_size: float = 0.022
@export var ant_count: int = 12
@export var prerun_steps: int = 900
@export var step_interval: float = 0.10

var _field: MultiMeshInstance3D
var _state: Array = []          # int 0..3 colour index per cell
var _ants: Array = []           # each: {x,y,dir,hue}
var _accum: float = 0.0
var _readout: Label3D
var _palette: Array = [
	Color(0.07, 0.07, 0.10),
	Color(0.95, 0.85, 0.35),
	Color(0.30, 0.85, 0.95),
	Color(0.95, 0.40, 0.70),
]


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
	if config.has("ant_count"):
		ant_count = int(config["ant_count"])
	if config.has("prerun_steps"):
		prerun_steps = int(config["prerun_steps"])
	if config.has("step_interval"):
		step_interval = float(config["step_interval"])
	for ch in get_children():
		ch.queue_free()
	_build()


func _reset_state() -> void:
	_state = []
	for y in range(grid):
		var row: Array = []
		for x in range(grid):
			row.append(0)
		_state.append(row)
	_ants = []
	var n: int = clampi(ant_count, 8, 16)
	for a in range(n):
		_ants.append({
			"x": _rng.randi_range(grid / 4, grid * 3 / 4),
			"y": _rng.randi_range(grid / 4, grid * 3 / 4),
			"dir": _rng.randi_range(0, 3),
			"hue": 1 + (a % 3),
		})


func _step_one(ant: Dictionary) -> void:
	var x: int = int(ant["x"])
	var y: int = int(ant["y"])
	var col: int = int(_state[y][x])
	# turmite: even colour -> turn right, odd colour -> turn left
	if col % 2 == 0:
		ant["dir"] = (int(ant["dir"]) + 1) % 4
	else:
		ant["dir"] = (int(ant["dir"]) + 3) % 4
	# cycle the cell toward this ant's hue band
	_state[y][x] = int(ant["hue"]) if col == 0 else 0
	match int(ant["dir"]):
		0: y += 1
		1: x += 1
		2: y -= 1
		3: x -= 1
	ant["x"] = wrapi(x, 0, grid)
	ant["y"] = wrapi(y, 0, grid)


func _step_swarm() -> void:
	for ant: Dictionary in _ants:
		_step_one(ant)


func _paint() -> void:
	var mm: MultiMesh = _field.multimesh
	for y in range(grid):
		for x in range(grid):
			var i: int = y * grid + x
			mm.set_instance_color(i, _palette[int(_state[y][x])])
	# overlay ant heads bright white
	for ant: Dictionary in _ants:
		var i2: int = int(ant["y"]) * grid + int(ant["x"])
		mm.set_instance_color(i2, Color(1.0, 1.0, 1.0))


func _build() -> void:
	_reset_state()
	for _s in range(prerun_steps):
		_step_swarm()

	# applied device: a ~1m painting easel doing the real job.
	var span: float = grid * cell_size
	add_child(_box(Vector3(0.0, 0.06, 0.0), Vector3(span + 0.2, 0.12, 0.35), _matte_mat(Color(0.12, 0.13, 0.15))))
	add_child(_box(Vector3(0.0, (0.55 + 0.12) * 0.5, -0.04), Vector3(0.10, 0.55, 0.10), _steel_mat(Color(0.42, 0.44, 0.48))))

	var top_y: float = 0.65
	_field = _make_field(grid, grid, cell_size, true)
	_field.position = Vector3(-span * 0.5, top_y, 0.06)
	add_child(_field)
	add_child(_box(Vector3(0.0, top_y + span * 0.5, 0.04), Vector3(span + 0.05, span + 0.05, 0.02), _matte_mat(Color(0.10, 0.10, 0.12))))
	_paint()

	add_child(_billboard_label("TURMITE SWARM", Vector3(0.0, top_y + span + 0.20, 0.06), 24, _palette[1]))
	_readout = _billboard_label("agents: %d" % _ants.size(), Vector3(0.0, top_y - 0.10, 0.10), 16, _palette[2])
	add_child(_readout)


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_interval:
		return
	_accum = 0.0
	for _s in range(5):
		_step_swarm()
	_paint()
	if _readout:
		_readout.text = "agents: %d" % _ants.size()
