extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MeshGrammarBench

## @identity
## name: Mesh Grammar Bench
## tier: medium
## concept: Mesh & shape grammars
## truth: apply a rule, apply it again — a mesh grows barnacles.

@export var max_depth: int = 4
@export var bench_top_y: float = 0.85
@export var seed_value: int = 0

var _grammar_root: Node3D = null
var _sway_t: float = 0.0


func _ready() -> void:
	_rng.randomize()
	if seed_value != 0:
		_rng.seed = seed_value
	_build()
	set_process(not Engine.is_editor_hint())


func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"):
		emissive = bool(config["emissive"])
	for c in get_children():
		remove_child(c)
		c.queue_free()
	_build()


func _build() -> void:
	# Bench base, top at bench_top_y
	var base_mat := _steel_mat(Color(0.16, 0.18, 0.22))
	add_child(_box(Vector3(0.0, bench_top_y * 0.5, 0.0), Vector3(1.2, bench_top_y, 1.2), base_mat))

	# Label
	add_child(_billboard_label("MESH GRAMMAR", Vector3(0.0, bench_top_y + 0.75, 0.0), 22, Color(0.8, 1.0, 0.85)))

	# Grammar-grown form
	_grammar_root = Node3D.new()
	_grammar_root.name = "GrammarForm"
	_grammar_root.position = Vector3(0.0, bench_top_y, 0.0)
	add_child(_grammar_root)

	# Seed box at base of growth
	var seed_size := Vector3(0.28, 0.28, 0.28)
	var seed_center := Vector3(0.0, seed_size.y * 0.5, 0.0)
	_grammar_root.add_child(_box(seed_center, seed_size, _coral_mat(0)))
	# Recursively grow from each face of the seed
	_grow(seed_center, seed_size, 0)


func _coral_mat(depth: int) -> StandardMaterial3D:
	# warm coral gradient: base reddish, tips pinker/brighter
	var t: float = float(depth) / float(max(max_depth, 1))
	var c: Color = Color(0.85, 0.35, 0.35).lerp(Color(0.95, 0.7, 0.85), t)
	return _glow_mat(c, 1.0 + t * 0.6)


func _grow(center: Vector3, size: Vector3, depth: int) -> void:
	if depth >= max_depth:
		return
	# choose how many faces to extrude from (top biased, plus sides)
	var faces: Array[Vector3] = [
		Vector3.UP,
		Vector3.RIGHT, Vector3.LEFT,
		Vector3.FORWARD, Vector3.BACK,
	]
	# Always extrude up; sometimes branch sideways
	var chosen: Array[Vector3] = [Vector3.UP]
	for k in range(1, faces.size()):
		if _rng.randf() < 0.45:
			chosen.append(faces[k])

	for dir: Vector3 in chosen:
		# child is a smaller box extruded from that face
		var shrink: float = _rng.randf_range(0.6, 0.8)
		var child_size: Vector3 = size * shrink
		# extrude distance along the face normal
		var half_parent: float = _half_along(size, dir)
		var half_child: float = _half_along(child_size, dir)
		var dist: float = half_parent + half_child + _rng.randf_range(0.0, 0.04)
		var child_center: Vector3 = center + dir * dist
		# small lateral jitter on perpendicular axes for an organic look
		child_center += _perp_jitter(dir, size.x * 0.18)

		# RULE: sometimes INSET/SPLIT into two thinner boxes instead of one
		if _rng.randf() < 0.3 and depth >= 1:
			var split_axis: Vector3 = _pick_perp(dir)
			var s_size: Vector3 = child_size
			s_size = _scale_along(s_size, split_axis, 0.42)
			var off: float = _half_along(child_size, split_axis) * 0.55
			var c_a: Vector3 = child_center + split_axis * off
			var c_b: Vector3 = child_center - split_axis * off
			_grammar_root.add_child(_box(c_a, s_size, _coral_mat(depth + 1)))
			_grammar_root.add_child(_box(c_b, s_size, _coral_mat(depth + 1)))
			_grow(c_a, s_size, depth + 1)
			_grow(c_b, s_size, depth + 1)
		else:
			_grammar_root.add_child(_box(child_center, child_size, _coral_mat(depth + 1)))
			_grow(child_center, child_size, depth + 1)


func _half_along(size: Vector3, dir: Vector3) -> float:
	return absf(dir.x) * size.x * 0.5 + absf(dir.y) * size.y * 0.5 + absf(dir.z) * size.z * 0.5


func _scale_along(size: Vector3, axis: Vector3, f: float) -> Vector3:
	var out: Vector3 = size
	if absf(axis.x) > 0.5:
		out.x *= f
	elif absf(axis.y) > 0.5:
		out.y *= f
	else:
		out.z *= f
	return out


func _pick_perp(dir: Vector3) -> Vector3:
	if absf(dir.y) > 0.5:
		return Vector3.RIGHT if _rng.randf() < 0.5 else Vector3.FORWARD
	if absf(dir.x) > 0.5:
		return Vector3.UP if _rng.randf() < 0.5 else Vector3.FORWARD
	return Vector3.UP if _rng.randf() < 0.5 else Vector3.RIGHT


func _perp_jitter(dir: Vector3, amount: float) -> Vector3:
	var j := Vector3.ZERO
	if absf(dir.y) < 0.5:
		j.y += _rng.randf_range(-amount, amount)
	if absf(dir.x) < 0.5:
		j.x += _rng.randf_range(-amount, amount)
	if absf(dir.z) < 0.5:
		j.z += _rng.randf_range(-amount, amount)
	return j


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	# gentle sway of the whole grown form
	_sway_t += delta
	if _grammar_root != null:
		_grammar_root.rotation.y = 0.06 * sin(_sway_t * 0.5)
