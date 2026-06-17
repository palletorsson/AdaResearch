extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name RejectionToy

## @identity
## lineage: rejection sampling — the held seed of the ladder (toy → bench → room)
## essence: scatter uniformly, keep only what falls under the target curve
## truth: the shape is what survives the throwing-away.

@export var sample_count: int = 120
@export var bell_height: float = 0.78
@export var reroll_period: float = 0.3

var _dots: Node3D
var _accum: float = 0.0
var _curve_mat: StandardMaterial3D


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	if config.has("sample_count"): sample_count = int(config["sample_count"])
	if config.has("bell_height"): bell_height = float(config["bell_height"])
	for c in get_children():
		remove_child(c); c.queue_free()
	_build()


# bell-ish target: a Gaussian bump in 0..1, returns height in 0..1
func _curve(x: float) -> float:
	var d: float = (x - 0.5) / 0.18
	return bell_height * exp(-0.5 * d * d)


func _build() -> void:
	_curve_mat = _glow_mat(Color(0.95, 0.85, 0.3), 2.0)
	var frame_mat := _steel_mat(Color(0.6, 0.62, 0.7))
	# unit square frame in the XY plane
	var lo := Vector3(-0.5, 0.0, 0.0)
	add_child(_cylinder_between(lo, Vector3(0.5, 0.0, 0.0), 0.012, frame_mat))
	add_child(_cylinder_between(Vector3(-0.5, 1.0, 0.0), Vector3(0.5, 1.0, 0.0), 0.012, frame_mat))
	add_child(_cylinder_between(Vector3(-0.5, 0.0, 0.0), Vector3(-0.5, 1.0, 0.0), 0.012, frame_mat))
	add_child(_cylinder_between(Vector3(0.5, 0.0, 0.0), Vector3(0.5, 1.0, 0.0), 0.012, frame_mat))
	# target curve as a ribbon of small segments
	var prev := Vector3(-0.5, _curve(0.0), 0.0)
	for i in range(1, 41):
		var x: float = float(i) / 40.0
		var p := Vector3(-0.5 + x, _curve(x), 0.0)
		add_child(_cylinder_between(prev, p, 0.01, _curve_mat))
		prev = p
	# samples
	_dots = Node3D.new()
	add_child(_dots)
	for i in range(sample_count):
		_dots.add_child(_make_dot())


func _make_dot() -> MeshInstance3D:
	var x: float = _rng.randf()
	var y: float = _rng.randf()
	var accepted: bool = y <= _curve(x)
	var col: Color = Color(0.2, 1.0, 0.35) if accepted else Color(0.7, 0.18, 0.18)
	var energy: float = 2.4 if accepted else 0.5
	var r: float = 0.018 if accepted else 0.013
	return _sphere(Vector3(-0.5 + x, y, 0.001), r, _glow_mat(col, energy))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < reroll_period:
		return
	_accum = 0.0
	# re-roll a handful of dots so the cloud shimmers
	var n: int = _dots.get_child_count()
	if n == 0:
		return
	for k in range(8):
		var idx: int = _rng.randi_range(0, n - 1)
		var old := _dots.get_child(idx)
		_dots.remove_child(old); old.queue_free()
		_dots.add_child(_make_dot())
