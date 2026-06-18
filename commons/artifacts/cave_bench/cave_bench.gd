extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name CaveBench

## @identity
## lineage: cellular-automata cave generation (the 4-5 majority rule) -> percolation,
##   roguelike level design, the geology of cracks and pores.
## essence: a bench that builds a cave out of noise. It starts as a sandstorm of random
##   rock and air, then a neighbour-majority vote runs a handful of times — and the static
##   resolves into smooth caverns and walls you could walk. The smoothing is shown happening,
##   step by step, then the cave holds, then it reseeds and does it again.
## truth: randomness is not the opposite of structure — it is structure's raw material.
##   One local rule, "become whatever most of your neighbours are", smooths white noise into
##   a place. Nothing is added; the information was already in the seed. The run is the deep:
##   the same few votes always carve the same cave from the same noise, irreversibly, only forward.

@export var cols: int = 36
@export var rows: int = 28
@export var cell: float = 0.018
@export var step_time: float = 0.55          # slow so each smoothing pass is legible
@export var fill_prob: float = 0.46          # initial rock probability
@export var smooth_passes: int = 5           # majority votes before the cave "holds"
@export var hold_steps: int = 6              # ticks to dwell on the finished cave
@export var rock_color: Color = Color(0.30, 0.24, 0.20, 1.0)     # solid (settled)
@export var rock_raw_color: Color = Color(0.55, 0.30, 0.42, 1.0) # solid during the storm
@export var air_color: Color = Color(0.05, 0.07, 0.10, 1.0)      # open / walkable
@export var edge_color: Color = Color(0.40, 0.85, 1.0, 1.0)      # cave/rock boundary glow

var _grid: Array = []         # 1 rock, 0 air
var _next: Array = []
var _field: MultiMeshInstance3D
var _readout: Label3D
var _accum: float = 0.0
var _pass: int = 0            # 0..smooth_passes done; then hold; then reseed
var _hold: int = 0
var _settled: bool = false


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("cols"):
		cols = int(config["cols"])
	if config.has("rows"):
		rows = int(config["rows"])
	if config.has("step_time"):
		step_time = float(config["step_time"])
	if config.has("smooth_passes"):
		smooth_passes = int(config["smooth_passes"])
	for child in get_children():
		child.queue_free()
	_build()


func _make_field(field_cols: int, field_rows: int, field_cell: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(field_cell * 0.88, field_cell * 0.88, field_cell * 0.88)
	mm.mesh = bm
	mm.instance_count = field_cols * field_rows
	for r: int in range(field_rows):
		for c: int in range(field_cols):
			var i: int = r * field_cols + c
			var pos := Vector3(c * field_cell, r * field_cell, 0.0) if plane_xy else Vector3(c * field_cell, 0.0, r * field_cell)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, air_color)
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi


func _seed_noise() -> void:
	# random fill, with the border forced to rock so the cave stays enclosed
	_grid = []
	for r: int in range(rows):
		var row: Array = []
		for c: int in range(cols):
			if c == 0 or c == cols - 1 or r == 0 or r == rows - 1:
				row.append(1)
			else:
				row.append(1 if _rng.randf() < fill_prob else 0)
		_grid.append(row)
	_next = []
	for r: int in range(rows):
		var nrow: Array = []
		for c: int in range(cols):
			nrow.append(0)
		_next.append(nrow)
	_pass = 0
	_hold = 0
	_settled = false


func _rock_neighbors(c: int, r: int) -> int:
	# Moore neighbourhood; off-grid counts as rock (keeps edges solid)
	var n: int = 0
	for dy: int in range(-1, 2):
		for dx: int in range(-1, 2):
			if dx == 0 and dy == 0:
				continue
			var x: int = c + dx
			var y: int = r + dy
			if x < 0 or x >= cols or y < 0 or y >= rows:
				n += 1
			elif int(_grid[y][x]) == 1:
				n += 1
	return n


func _smooth_once() -> void:
	# the 4-5 rule: a cell becomes rock if 5+ neighbours are rock, air if fewer.
	for r: int in range(rows):
		for c: int in range(cols):
			if c == 0 or c == cols - 1 or r == 0 or r == rows - 1:
				_next[r][c] = 1
				continue
			var n: int = _rock_neighbors(c, r)
			if n >= 5:
				_next[r][c] = 1
			elif n <= 3:
				_next[r][c] = 0
			else:
				_next[r][c] = int(_grid[r][c])
	var tmp: Array = _grid
	_grid = _next
	_next = tmp


func _is_edge(c: int, r: int) -> bool:
	# a rock cell touching air is a cave wall — glow it once settled
	if int(_grid[r][c]) != 1:
		return false
	for d: Vector2i in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
		var x: int = c + d.x
		var y: int = r + d.y
		if x < 0 or x >= cols or y < 0 or y >= rows:
			continue
		if int(_grid[y][x]) == 0:
			return true
	return false


func _paint() -> void:
	var solid: Color = rock_color if _settled else rock_raw_color
	var mm: MultiMesh = _field.multimesh
	for r: int in range(rows):
		for c: int in range(cols):
			var i: int = r * cols + c
			if int(_grid[r][c]) == 1:
				if _settled and _is_edge(c, r):
					mm.set_instance_color(i, edge_color)
				else:
					mm.set_instance_color(i, solid)
			else:
				mm.set_instance_color(i, air_color)


func _update_readout() -> void:
	if not is_instance_valid(_readout):
		return
	if not _settled:
		_readout.text = "smoothing  %d / %d" % [_pass, smooth_passes]
		_readout.modulate = rock_raw_color
	else:
		_readout.text = "a place"
		_readout.modulate = edge_color


func _build() -> void:
	# --- bench housing ---
	var base_mat := _matte_mat(Color(0.16, 0.17, 0.2), 0.85)
	var steel := _steel_mat(Color(0.45, 0.47, 0.52))
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 0.7), base_mat))
	add_child(_box(Vector3(0, 0.5, -0.12), Vector3(0.12, 0.62, 0.12), steel))
	add_child(_box(Vector3(0, 0.86, 0), Vector3(1.0, 0.04, 0.6), _steel_mat(Color(0.3, 0.32, 0.36))))

	# --- field standing vertical on the bench top, facing +Z ---
	_field = _make_field(cols, rows, cell, true)
	var w: float = cols * cell
	_field.position = Vector3(-w * 0.5, 0.9, 0.04)
	add_child(_field)

	_readout = _billboard_label("", Vector3(0.0, 0.9 + rows * cell + 0.06, 0.05), 16, edge_color)
	add_child(_readout)
	add_child(_billboard_label("CAVE CA\nrandomness, smoothed into a place", Vector3(0, 1.6, 0.05), 28, edge_color))

	# pre-run: show the cave already half-smoothed so the first frame is legible,
	# then let _process carry the remaining passes visibly.
	_seed_noise()
	var pre: int = max(smooth_passes - 2, 1)
	for _i: int in range(pre):
		_smooth_once()
		_pass += 1
	_paint()
	_update_readout()


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_time:
		return
	_accum = 0.0
	if _pass < smooth_passes:
		_smooth_once()
		_pass += 1
		if _pass >= smooth_passes:
			_settled = true
	elif _hold < hold_steps:
		_hold += 1
	else:
		_seed_noise()        # back to the storm
	_paint()
	_update_readout()
