extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BlueNoiseToy
## @identity
## lineage: Mitchell's best-candidate sampling → handheld pad of even dots
## essence: every new dot is the one that landed farthest from all the rest
## truth: evenness is not order imposed — it is each point keeping its distance.

@export var pad_size: float = 0.4
@export var max_points: int = 36
@export var candidates: int = 12

var _points: Array = []
var _dots: Node3D
var _accum: float = 0.0


func _ready() -> void:
	_rng.randomize()
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()


func _build() -> void:
	# Small held pad near origin, y 0..0.5.
	add_child(_box(Vector3(0, 0.02, 0), Vector3(pad_size, 0.04, pad_size), _matte_mat(Color(0.1, 0.12, 0.18), 0.6)))
	add_child(_box(Vector3(0, 0.045, 0), Vector3(pad_size * 0.92, 0.005, pad_size * 0.92), _glass_mat(Color(0.2, 0.4, 0.7), 0.25)))
	_dots = Node3D.new()
	add_child(_dots)
	_points.clear()
	# Fill to a representative, even spread immediately.
	for i in range(max_points):
		_add_best_candidate()
	_render()


func _best_candidate() -> Vector2:
	var half: float = pad_size * 0.42
	var best := Vector2.ZERO
	var best_d: float = -1.0
	for i in range(candidates):
		var p := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
		var nearest: float = 1e9
		for q in _points:
			nearest = minf(nearest, p.distance_to(q))
		if _points.is_empty():
			nearest = 1e9
		if nearest > best_d:
			best_d = nearest
			best = p
	return best


func _add_best_candidate() -> void:
	_points.append(_best_candidate())


func _render() -> void:
	for c in _dots.get_children(): _dots.remove_child(c); c.queue_free()
	var dot_mat := _glow_mat(Color(0.4, 0.7, 1.0), 3.0)
	var ring_mat := _glass_mat(Color(0.5, 0.8, 1.0), 0.18)
	for p in _points:
		var pos := Vector3(p.x, 0.06, p.y)
		_dots.add_child(_sphere(pos, 0.012, dot_mat))
		_dots.add_child(_torus(pos, 0.026, 0.003, ring_mat))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < 0.5:
		return
	_accum = 0.0
	if _points.size() >= max_points:
		_points.clear()
	else:
		_add_best_candidate()
	_render()
