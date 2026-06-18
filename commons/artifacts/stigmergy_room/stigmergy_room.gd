extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StigmergyRoom

## @identity
## lineage: slime mould (Physarum) / ant-colony optimization / ecological CA
## essence: a floor-scale pheromone network — agents wander between several food
##          nodes, reinforcing the trails that connect them into a living graph.
## truth: a CA wearing legs. The network is not designed; it is the residue of a
##        million crossings, decayed everywhere the crossings stopped. Memory you
##        can walk on — the floor remembers the route the colony forgot it chose.

@export var cols: int = 40
@export var rows: int = 40
@export var cell: float = 0.16
@export var agent_count: int = 60
@export var food_count: int = 5
@export var deposit: float = 1.0
@export var evaporation: float = 0.02
@export var diffusion: float = 0.14
@export var step_seconds: float = 0.12
@export var warmup_steps: int = 200

var _field: Array = []
var _agents: Array = []        # {p:Vector2i, dir:Vector2i, goal:int}
var _foods: Array = []         # Array[Vector2i]
var _mi: MultiMeshInstance3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	if config.has("agent_count"):
		agent_count = int(config["agent_count"])
	if config.has("food_count"):
		food_count = int(config["food_count"])
	if config.has("evaporation"):
		evaporation = float(config["evaporation"])
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_init_state()
	var fw: float = cols * cell
	var fd: float = rows * cell
	# room floor slab under the field
	var floor_mat := _matte_mat(Color(0.06, 0.06, 0.08), 0.95, 0.0)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(fw + 0.6, 0.1, fd + 0.6), floor_mat))
	# field as floor (horizontal), centred on origin
	_mi = _make_field(cols, rows, cell, false)
	_mi.position = Vector3(-fw * 0.5, 0.02, -fd * 0.5)
	add_child(_mi)
	# food node pillars
	for f: Vector2i in _foods:
		var w: Vector3 = _cell_world(f)
		add_child(_cylinder(w + Vector3(0, 0.25, 0), cell * 0.7, 0.5, _glow_mat(Color(1.0, 0.5, 0.2), 2.0)))
	# overhead label
	add_child(_billboard_label("STIGMERGY NETWORK\na CA wearing legs", Vector3(0.0, 3.6, 0.0), 46, Color(0.85, 0.95, 1.0)))
	# PRE-RUN so the network is already woven
	for i in range(warmup_steps):
		_step()
	_paint()


func _cell_world(p: Vector2i) -> Vector3:
	return _mi.position + Vector3(p.x * cell, 0.0, p.y * cell)


func _init_state() -> void:
	_field = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(0.0)
		_field.append(row)
	# scatter food nodes
	_foods = []
	for f in range(food_count):
		_foods.append(Vector2i(_rng.randi_range(3, cols - 4), _rng.randi_range(3, rows - 4)))
	# agents start on random food nodes, heading to another
	_agents = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for a in range(agent_count):
		var gi: int = _rng.randi_range(0, _foods.size() - 1)
		var p: Vector2i = _foods[gi]
		var goal: int = (gi + 1 + _rng.randi_range(0, max(0, _foods.size() - 2))) % _foods.size()
		_agents.append({"p": p, "dir": dirs[_rng.randi_range(0, 3)], "goal": goal})


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
	# diffuse
	if diffusion > 0.0:
		_diffuse()
	# agents
	for a in range(_agents.size()):
		var ag: Dictionary = _agents[a]
		var p: Vector2i = ag["p"]
		var target: Vector2i = _foods[ag["goal"]]
		var pr: Array = _field[p.y]
		pr[p.x] = minf(2.5, float(pr[p.x]) + deposit)
		var best_dir: Vector2i = ag["dir"]
		var best_score: float = -1.0
		var cand := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d: Vector2i in cand:
			var np := p + d
			if np.x < 0 or np.x >= cols or np.y < 0 or np.y >= rows:
				continue
			var nr: Array = _field[np.y]
			var to_t := target - np
			var goal_bias: float = 0.0
			if signi(to_t.x) == d.x and d.x != 0:
				goal_bias += 0.6
			if signi(to_t.y) == d.y and d.y != 0:
				goal_bias += 0.6
			var score: float = float(nr[np.x]) * 1.3 + goal_bias + _rng.randf() * 0.8
			if d == ag["dir"]:
				score += 0.3
			if score > best_score:
				best_score = score
				best_dir = d
		var nxt := p + best_dir
		nxt.x = clampi(nxt.x, 0, cols - 1)
		nxt.y = clampi(nxt.y, 0, rows - 1)
		ag["p"] = nxt
		ag["dir"] = best_dir
		# arrived → pick a new food goal
		if nxt.distance_to(Vector2(target)) < 2.0:
			ag["goal"] = (ag["goal"] + 1 + _rng.randi_range(0, max(0, _foods.size() - 2))) % _foods.size()
		_agents[a] = ag


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
			# slime-network look: yellow-green core, dark substrate
			var col := Color(0.03, 0.04, 0.05) + Color(0.55, 0.50, 0.10) * v
			mm.set_instance_color(i, col)
	# agent sparks
	for a in range(_agents.size()):
		var ag: Dictionary = _agents[a]
		var p: Vector2i = ag["p"]
		mm.set_instance_color(p.y * cols + p.x, Color(1.0, 0.95, 0.6))


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
