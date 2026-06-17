extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RandomWalkBench
## @identity
## lineage: the drunkard's walk — Brownian motion stripped to a grid and a coin
## essence: a token that has no plan, only a fresh coin at every step, tracing where chance led
## truth: no memory, no destination, yet the path is unmistakably its own

@export var step_time: float = 0.35
@export var grid_cells: int = 9
@export var trail_len: int = 60

var _token: MeshInstance3D
var _trail: Node3D
var _path: Array[Vector2i] = []
var _cell: float = 0.1
var _top_y: float = 0.22
var _t: float = 0.0

func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	_path.clear()
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.1, 0.2, 1.1), _steel_mat(Color(0.28, 0.3, 0.36))))
	add_child(_cylinder(Vector3(0, -0.25, 0), 0.08, 0.5, _steel_mat(Color(0.22, 0.24, 0.28))))
	add_child(_box(Vector3(0, _top_y, 0), Vector3(0.95, 0.02, 0.95), _matte_mat(Color(0.1, 0.11, 0.14))))
	# grid lines
	var line_mat := _glow_mat(Color(0.3, 0.5, 0.7), 0.5)
	var half: float = grid_cells * _cell * 0.5
	for i in range(grid_cells + 1):
		var o: float = -half + i * _cell
		add_child(_box(Vector3(o, _top_y + 0.012, 0), Vector3(0.004, 0.004, half * 2.0), line_mat))
		add_child(_box(Vector3(0, _top_y + 0.012, o), Vector3(half * 2.0, 0.004, 0.004), line_mat))
	_trail = Node3D.new()
	add_child(_trail)
	# pre-trace ~trail_len steps so the wander already reads
	var p := Vector2i(grid_cells / 2, grid_cells / 2)
	_path.append(p)
	for _i in range(trail_len):
		p = _stepped(p)
		_path.append(p)
	_redraw_trail()
	_token = _sphere(_cell_pos(_path[-1], 0.06), 0.05, _glow_mat(Color(1.0, 0.9, 0.3), 2.2))
	add_child(_token)
	add_child(_billboard_label("RANDOM WALK\neach step a fresh coin", Vector3(0, 1.6, -0.4), 34, Color(0.95, 0.95, 1.0)))

func _stepped(p: Vector2i) -> Vector2i:
	var d: int = _rng.randi_range(0, 3)
	var n := p
	if d == 0: n.x += 1
	elif d == 1: n.x -= 1
	elif d == 2: n.y += 1
	else: n.y -= 1
	return n

func _in_grid(p: Vector2i) -> bool:
	return p.x >= 0 and p.x < grid_cells and p.y >= 0 and p.y < grid_cells

func _cell_pos(p: Vector2i, y: float) -> Vector3:
	var half: float = grid_cells * _cell * 0.5
	return Vector3(-half + (p.x + 0.5) * _cell, _top_y + y, -half + (p.y + 0.5) * _cell)

func _redraw_trail() -> void:
	for c in _trail.get_children():
		_trail.remove_child(c); c.queue_free()
	var n: int = _path.size()
	for i in range(n):
		var age: float = float(i) / float(maxi(n - 1, 1))   # 0 = oldest, 1 = newest
		var mat := _glow_mat(Color(1.0, 0.55 + age * 0.35, 0.2), 0.3 + age * 1.6)
		_trail.add_child(_sphere(_cell_pos(_path[i], 0.03), 0.018 + age * 0.012, mat))

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_t += delta
	if _t < step_time: return
	_t = 0.0
	var nxt: Vector2i = _stepped(_path[-1])
	if not _in_grid(nxt):
		_path.clear()
		_path.append(Vector2i(grid_cells / 2, grid_cells / 2))
	else:
		_path.append(nxt)
		while _path.size() > trail_len + 1:
			_path.remove_at(0)
	_redraw_trail()
	_token.position = _cell_pos(_path[-1], 0.06)
