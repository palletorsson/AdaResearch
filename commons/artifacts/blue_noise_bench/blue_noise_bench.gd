extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name BlueNoiseBench
## @identity
## lineage: white-vs-blue sampling on two pads → side-by-side comparison
## essence: same count of points, one clumps and one spaces — the eye sees why
## truth: random is not even; evenness costs a choice random never makes.

@export var point_count: int = 40
@export var candidates: int = 12
@export var pad_w: float = 0.4

var _left: Node3D
var _right: Node3D
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
	# Bench: base box ~1.1 wide, top at y≈0.85.
	add_child(_box(Vector3(0, 0.1, 0), Vector3(1.15, 0.2, 0.7), _matte_mat(Color(0.16, 0.15, 0.18))))
	add_child(_cylinder(Vector3(0, 0.5, 0), 0.07, 0.6, _steel_mat(Color(0.4, 0.42, 0.46))))
	add_child(_box(Vector3(0, 0.83, 0), Vector3(1.05, 0.04, 0.6), _matte_mat(Color(0.22, 0.2, 0.24))))
	# Two pads side by side, faces +Z.
	add_child(_box(Vector3(-0.28, 0.86, 0.05), Vector3(pad_w, 0.02, pad_w), _matte_mat(Color(0.12, 0.1, 0.1), 0.6)))
	add_child(_box(Vector3(0.28, 0.86, 0.05), Vector3(pad_w, 0.02, pad_w), _matte_mat(Color(0.1, 0.12, 0.18), 0.6)))
	_left = Node3D.new()
	_right = Node3D.new()
	add_child(_left)
	add_child(_right)
	_refill()
	add_child(_billboard_label("white", Vector3(-0.28, 1.12, 0.05), 24, Color(1.0, 0.6, 0.6)))
	add_child(_billboard_label("blue", Vector3(0.28, 1.12, 0.05), 24, Color(0.5, 0.8, 1.0)))


func _white_points() -> Array:
	var pts: Array = []
	var half: float = pad_w * 0.44
	for i in range(point_count):
		pts.append(Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half)))
	return pts


func _blue_points() -> Array:
	var pts: Array = []
	var half: float = pad_w * 0.44
	for i in range(point_count):
		var best := Vector2.ZERO
		var best_d: float = -1.0
		for c in range(candidates):
			var p := Vector2(_rng.randf_range(-half, half), _rng.randf_range(-half, half))
			var nearest: float = 1e9
			for q in pts:
				nearest = minf(nearest, p.distance_to(q))
			if pts.is_empty():
				nearest = 1e9
			if nearest > best_d:
				best_d = nearest
				best = p
		pts.append(best)
	return pts


func _scatter(host: Node3D, pts: Array, cx: float, col: Color) -> void:
	for c in host.get_children(): host.remove_child(c); c.queue_free()
	var mat := _glow_mat(col, 3.0)
	for p in pts:
		host.add_child(_sphere(Vector3(cx + p.x, 0.89, 0.05 + p.y), 0.011, mat))


func _refill() -> void:
	_scatter(_left, _white_points(), -0.28, Color(1.0, 0.55, 0.5))
	_scatter(_right, _blue_points(), 0.28, Color(0.45, 0.75, 1.0))


func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_accum += delta
	if _accum < 2.5:
		return
	_accum = 0.0
	_refill()
