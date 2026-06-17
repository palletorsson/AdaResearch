extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name DiceRainRoom
## @identity
## lineage: the law of large numbers made physical — a downpour of fair dice
## essence: each die is unbiased, yet the pile they make is the flattest of shapes
## truth: fairness has a silhouette, and it is level

@export var rain_rate: int = 3
@export var max_per_col: int = 24

var _cols: Array[Node3D] = []     # parent per column; child_count == settled height
var _settled: Array[int] = [0, 0, 0, 0, 0, 0]
var _falling: Array = []          # each: {node:Node3D, col:int, y:float}
var _col_x: Array[float] = [-2.5, -1.5, -0.5, 0.5, 1.5, 2.5]
var _col_mats: Array[StandardMaterial3D] = []
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
	_cols.clear()
	_falling.clear()
	_col_mats.clear()
	_settled.clear()
	for _c in range(6):
		_settled.append(0)
	add_child(_box(Vector3(0, -0.05, 0), Vector3(7.0, 0.1, 7.0), _matte_mat(Color(0.12, 0.13, 0.16))))
	var hue: float = 0.0
	for i in range(6):
		var col_root := Node3D.new()
		add_child(col_root)
		_cols.append(col_root)
		var mat := _glow_mat(Color.from_hsv(hue, 0.55, 1.0), 1.3)
		_col_mats.append(mat)
		hue += 0.13
		# bin label
		add_child(_billboard_label(str(i + 1), Vector3(_col_x[i], 0.2, 2.2), 44, Color(0.85, 0.85, 0.9)))
		# pre-build a roughly-flat histogram (uniform)
		var start_h: int = 14 + _rng.randi_range(-2, 2)
		for h in range(start_h):
			col_root.add_child(_make_die(Vector3(_col_x[i], 0.3 + h * 0.32, 2.0), mat))
		_settled[i] = start_h
	add_child(_billboard_label("fair dice -> uniform", Vector3(0, 3.6, 0), 72, Color(0.95, 0.95, 1.0)))

func _make_die(center: Vector3, mat: StandardMaterial3D) -> Node3D:
	var root := Node3D.new()
	root.position = center
	root.add_child(_box(Vector3.ZERO, Vector3(0.28, 0.28, 0.28), mat))
	var pip := _matte_mat(Color(0.05, 0.05, 0.07))
	root.add_child(_sphere(Vector3(0, 0, 0.145), 0.035, pip))
	root.add_child(_sphere(Vector3(0.08, 0.08, 0.145), 0.03, pip))
	return root

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	# advance falling dice; settle into their column when they reach the top of the pile
	var still: Array = []
	for f in _falling:
		f.y -= delta * 6.0
		var land_y: float = 0.3 + _settled[f.col] * 0.32
		if f.y <= land_y:
			var die: Node3D = f.node
			remove_child(die)
			die.position = Vector3(_col_x[f.col], land_y, 2.0)
			_cols[f.col].add_child(die)
			_settled[f.col] += 1
		else:
			f.node.position.y = f.y
			still.append(f)
	_falling = still
	_t += delta
	if _t >= 0.3:
		_t = 0.0
		for _i in range(rain_rate):
			var col: int = _rng.randi_range(0, 5)
			if _settled[col] >= max_per_col:
				continue
			var nd: Node3D = _make_die(Vector3(_col_x[col], 5.0, 2.0), _col_mats[col])
			add_child(nd)
			_falling.append({"node": nd, "col": col, "y": 5.0})
