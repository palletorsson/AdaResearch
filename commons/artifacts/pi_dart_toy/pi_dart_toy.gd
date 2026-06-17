extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name PiDartToy

## @identity
## lineage: Monte Carlo — the held seed (toy → bench)
## essence: count darts inside the quarter-circle; 4×inside/total estimates pi
## truth: randomness, counted, remembers a number it was never told.

@export var dart_count: int = 150
@export var reroll_period: float = 0.4

var _dots: Node3D
var _readout: Label3D
var _inside: int = 0
var _total: int = 0
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("dart_count"): dart_count = int(config["dart_count"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	_inside = 0
	_total = 0
	var frame_mat := _steel_mat(Color(0.6, 0.62, 0.7))
	# unit square frame in XY, origin at lower-left
	add_child(_cylinder_between(Vector3(0, 0, 0), Vector3(1, 0, 0), 0.012, frame_mat))
	add_child(_cylinder_between(Vector3(0, 1, 0), Vector3(1, 1, 0), 0.012, frame_mat))
	add_child(_cylinder_between(Vector3(0, 0, 0), Vector3(0, 1, 0), 0.012, frame_mat))
	add_child(_cylinder_between(Vector3(1, 0, 0), Vector3(1, 1, 0), 0.012, frame_mat))
	# inscribed quarter-circle arc (radius 1, centre at origin), as small segments
	var amat := _glow_mat(Color(0.95, 0.85, 0.3), 2.2)
	var prev := Vector3(1, 0, 0)
	for i in range(1, 33):
		var a: float = (PI * 0.5) * float(i) / 32.0
		var p := Vector3(cos(a), sin(a), 0)
		add_child(_cylinder_between(prev, p, 0.01, amat))
		prev = p
	# darts
	_dots = Node3D.new()
	add_child(_dots)
	for i in range(dart_count):
		_dots.add_child(_make_dart())
	# centre offset so the toy sits around origin (square is 0..1)
	_dots.position = Vector3.ZERO
	# pi readout
	_readout = _billboard_label(_pi_text(), Vector3(0.5, 1.18, 0.0), 22, Color(0.85, 0.95, 1.0))
	add_child(_readout)


func _make_dart() -> MeshInstance3D:
	var x: float = _rng.randf()
	var y: float = _rng.randf()
	var inside: bool = (x * x + y * y) <= 1.0
	_total += 1
	if inside:
		_inside += 1
	var col: Color = Color(0.2, 1.0, 0.35) if inside else Color(0.55, 0.57, 0.62)
	var energy: float = 2.4 if inside else 0.4
	return _sphere(Vector3(x, y, 0.001), 0.016, _glow_mat(col, energy))


func _pi_text() -> String:
	var est: float = 4.0 * float(_inside) / float(maxi(_total, 1))
	return "pi ≈ %.4f\n%d / %d inside" % [est, _inside, _total]


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < reroll_period:
		return
	_accum = 0.0
	var n: int = _dots.get_child_count()
	if n == 0:
		return
	# re-roll a handful, keeping inside/total accurate
	for k in range(6):
		var idx: int = _rng.randi_range(0, n - 1)
		var old := _dots.get_child(idx) as MeshInstance3D
		# recover whether it was inside from its position
		var was_inside: bool = (old.position.x * old.position.x + old.position.y * old.position.y) <= 1.0
		_total -= 1
		if was_inside:
			_inside -= 1
		_dots.remove_child(old); old.queue_free()
		_dots.add_child(_make_dart())
	_readout.text = _pi_text()
