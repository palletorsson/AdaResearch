extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name StigmergyToy

## @identity
## lineage: ant-colony optimization / stigmergy / ecological cellular automata
## essence: a few ants wandering a held grid, laying an evaporating pheromone trail
## truth: the trail IS the memory — the ants hold nothing, the ground holds everything;
##        what looks like a plan is just deposit minus evaporation, run long enough to glow.

@export var cols: int = 28
@export var rows: int = 28
@export var cell: float = 0.013
@export var ant_count: int = 4
@export var deposit: float = 1.0
@export var evaporation: float = 0.04
@export var step_seconds: float = 0.12
@export var warmup_steps: int = 90

var _field: Array = []            # Array[Array[float]] pheromone
var _ants: Array = []             # Array of {p:Vector2i, dir:Vector2i}
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
	for c in get_children():
		c.queue_free()
	_build()


func _build() -> void:
	_init_state()
	# housing — a small held tray
	var tray := _matte_mat(Color(0.10, 0.10, 0.13), 0.85, 0.0)
	add_child(_box(Vector3(cols * cell * 0.5, -cell * 1.2, rows * cell * 0.5), Vector3(cols * cell + 0.03, cell, rows * cell + 0.03), tray))
	# field
	_mi = _make_field(cols, rows, cell, false)
	_mi.position = Vector3(0.0, 0.0, 0.0)
	add_child(_mi)
	# label
	add_child(_billboard_label("STIGMERGY", Vector3(cols * cell * 0.5, 0.30, rows * cell * 0.5), 22, Color(0.85, 0.95, 1.0)))
	# PRE-RUN so trails already exist on first frame
	for i in range(warmup_steps):
		_step()
	_paint()


func _init_state() -> void:
	_field = []
	for r in range(rows):
		var row: Array = []
		for c in range(cols):
			row.append(0.0)
		_field.append(row)
	_ants = []
	var dirs := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
	for a in range(ant_count):
		var p := Vector2i(_rng.randi_range(0, cols - 1), _rng.randi_range(0, rows - 1))
		_ants.append({"p": p, "dir": dirs[_rng.randi_range(0, 3)]})


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
	# move ants, deposit, follow gradient with noise
	for a in range(_ants.size()):
		var ant: Dictionary = _ants[a]
		var p: Vector2i = ant["p"]
		# deposit on current cell
		var pr: Array = _field[p.y]
		pr[p.x] = minf(2.0, float(pr[p.x]) + deposit)
		# choose next: sniff neighbours, bias toward existing pheromone + momentum
		var best_dir: Vector2i = ant["dir"]
		var best_score: float = -1.0
		var cand := [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]
		for d: Vector2i in cand:
			var np := p + d
			if np.x < 0 or np.x >= cols or np.y < 0 or np.y >= rows:
				continue
			var nr: Array = _field[np.y]
			var score: float = float(nr[np.x]) + _rng.randf() * 0.6
			if d == ant["dir"]:
				score += 0.4
			if score > best_score:
				best_score = score
				best_dir = d
		var nxt := p + best_dir
		nxt.x = clampi(nxt.x, 0, cols - 1)
		nxt.y = clampi(nxt.y, 0, rows - 1)
		ant["p"] = nxt
		ant["dir"] = best_dir
		_ants[a] = ant


func _paint() -> void:
	var mm := _mi.multimesh
	for r in range(rows):
		var row: Array = _field[r]
		for c in range(cols):
			var i: int = r * cols + c
			var v: float = clampf(float(row[c]), 0.0, 1.5)
			var col := Color(0.04, 0.05, 0.07) + Color(0.12, 0.55, 0.30) * v
			mm.set_instance_color(i, col)
	# bright ant markers on top
	for a in range(_ants.size()):
		var ant: Dictionary = _ants[a]
		var p: Vector2i = ant["p"]
		mm.set_instance_color(p.y * cols + p.x, Color(1.0, 0.85, 0.25))


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
