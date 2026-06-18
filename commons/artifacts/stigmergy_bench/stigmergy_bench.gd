extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StigmergyBench

## @identity
## lineage: ant-colony optimization / stigmergy / ecological cellular automata
## essence: ~20 ants depositing pheromone that evaporates AND diffuses; trails
##          self-reinforce into a shortest path between nest and food.
## truth: the trail is the memory. No ant decides the route — the route precipitates
##        out of deposit, decay, and blur. A colony is a CA that learned to walk.

@export var cols: int = 34
@export var rows: int = 34
@export var cell: float = 0.018
@export var ant_count: int = 20
@export var deposit: float = 1.0
@export var evaporation: float = 0.03
@export var diffusion: float = 0.12
@export var step_seconds: float = 0.12
@export var warmup_steps: int = 140

var _field: Array = []
var _ants: Array = []          # {p:Vector2i, dir:Vector2i, carrying:bool}
var _nest: Vector2i
var _food: Vector2i
var _mi: MultiMeshInstance3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("ant_count"):
		ant_count = int(config["ant_count"])
	if config.has("evaporation"):
		evaporation = float(config["evaporation"])
	if config.has("diffusion"):
		diffusion = float(config["diffusion"])
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_init_state()
	var fw: float = cols * cell
	var fd: float = rows * cell
	# bench base box
	var base_mat := _matte_mat(Color(0.12, 0.12, 0.15), 0.85, 0.0)
	add_child(_box(Vector3(0.0, 0.10, 0.0), Vector3(1.1, 0.2, 0.7), base_mat))
	# pillar
	var pillar_mat := _steel_mat(Color(0.35, 0.37, 0.42))
	add_child(_cylinder(Vector3(0.0, 0.52, 0.0), 0.05, 0.65, pillar_mat))
	# field VERTICAL on top, facing +Z, centred above pillar
	_mi = _make_field(cols, rows, cell, true)
	_mi.position = Vector3(-fw * 0.5, 0.85, 0.0)
	add_child(_mi)
	# label
	add_child(_billboard_label("STIGMERGY\nthe trail is the memory", Vector3(0.0, 1.6, 0.0), 28, Color(0.85, 0.95, 1.0)))
	# nest / food markers (small glow spheres in front of the plane)
	add_child(_sphere(_cell_world(_nest) + Vector3(0, 0, 0.02), cell * 0.9, _glow_mat(Color(0.3, 0.6, 1.0), 2.0)))
	add_child(_sphere(_cell_world(_food) + Vector3(0, 0, 0.02), cell * 0.9, _glow_mat(Color(1.0, 0.5, 0.2), 2.0)))
	# PRE-RUN
	for i in range(warmup_steps):
		_step()
	_paint()


func _cell_world(p: Vector2i) -> Vector3:
	return _mi.position + Vector3(p.x * cell, p.y * cell, 0.0)


func _init_state() -> void:
	_field = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(0.0)
		_field.append(row)
	_nest = Vector2i(int(cols * 0.18), int(rows * 0.5))
	_food = Vector2i(int(cols * 0.82), int(rows * 0.5))
	_ants = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for a in range(ant_count):
		_ants.append({"p": _nest, "dir": dirs[_rng.randi_range(0, 3)], "carrying": false})


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_accum += delta
	if _accum < step_seconds:
		return
	_accum = 0.0
	_step()
	_paint()


func _step() -> void:
	# evaporate
	for r in range(rows):
		var row: Array = _field[r]
		for c in range(cols):
			row[c] = maxf(0.0, float(row[c]) - evaporation)
	# diffuse (simple box blur into a fresh buffer)
	if diffusion > 0.0:
		_diffuse()
	# ants
	for a in range(_ants.size()):
		var ant: Dictionary = _ants[a]
		var p: Vector2i = ant["p"]
		var carrying: bool = ant["carrying"]
		var target: Vector2i = _nest if carrying else _food
		# deposit
		var pr: Array = _field[p.y]
		pr[p.x] = minf(2.5, float(pr[p.x]) + deposit)
		# steer: blend pheromone gradient, goal direction, momentum, noise
		var best_dir: Vector2i = ant["dir"]
		var best_score: float = -1.0
		var cand := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d: Vector2i in cand:
			var np := p + d
			if np.x < 0 or np.x >= cols or np.y < 0 or np.y >= rows:
				continue
			var nr: Array = _field[np.y]
			var goal_bias: float = 0.0
			var to_target := target - np
			if signi(to_target.x) == d.x and d.x != 0:
				goal_bias += 0.7
			if signi(to_target.y) == d.y and d.y != 0:
				goal_bias += 0.7
			var score: float = float(nr[np.x]) * 1.2 + goal_bias + _rng.randf() * 0.7
			if d == ant["dir"]:
				score += 0.3
			if score > best_score:
				best_score = score
				best_dir = d
		var nxt := p + best_dir
		nxt.x = clampi(nxt.x, 0, cols - 1)
		nxt.y = clampi(nxt.y, 0, rows - 1)
		ant["p"] = nxt
		ant["dir"] = best_dir
		# flip state on arrival
		if nxt.distance_to(Vector2(target)) < 2.0:
			ant["carrying"] = not carrying
		_ants[a] = ant


func _diffuse() -> void:
	var nf: Array = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			var sum: float = float(_field[r][c])
			var cnt: float = 1.0
			if c > 0:
				sum += float(_field[r][c - 1]); cnt += 1.0
			if c < cols - 1:
				sum += float(_field[r][c + 1]); cnt += 1.0
			if r > 0:
				sum += float(_field[r - 1][c]); cnt += 1.0
			if r < rows - 1:
				sum += float(_field[r + 1][c]); cnt += 1.0
			var blurred: float = sum / cnt
			row.append(lerpf(float(_field[r][c]), blurred, diffusion))
		nf.append(row)
	_field = nf


func _paint() -> void:
	var mm := _mi.multimesh
	for r in range(rows):
		var row: Array = _field[r]
		for c in range(cols):
			var i: int = r * cols + c
			var v: float = clampf(float(row[c]), 0.0, 2.0)
			var col := Color(0.04, 0.05, 0.07) + Color(0.10, 0.55, 0.35) * v
			mm.set_instance_color(i, col)
	# ant markers
	for a in range(_ants.size()):
		var ant: Dictionary = _ants[a]
		var p: Vector2i = ant["p"]
		var ac := Color(1.0, 0.85, 0.25) if not ant["carrying"] else Color(1.0, 0.55, 0.85)
		mm.set_instance_color(p.y * cols + p.x, ac)


func _make_field(cols_n: int, rows_n: int, cell_s: float, plane_xy: bool = true) -> MultiMeshInstance3D:
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var bm := BoxMesh.new()
	bm.size = Vector3(cell_s * 0.88, cell_s * 0.88, cell_s * 0.88)
	mm.mesh = bm
	mm.instance_count = cols_n * rows_n
	for r in range(rows_n):
		for c in range(cols_n):
			var i: int = r * cols_n + c
			var pos := Vector3(c * cell_s, r * cell_s, 0.0) if plane_xy else Vector3(c * cell_s, 0.0, r * cell_s)
			mm.set_instance_transform(i, Transform3D(Basis(), pos))
			mm.set_instance_color(i, Color(0.05, 0.05, 0.07, 1))
	var mi := MultiMeshInstance3D.new()
	mi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.emission = Color.WHITE
	mat.emission_energy_multiplier = 0.18 if emissive else 0.0
	mi.material_override = mat
	return mi
