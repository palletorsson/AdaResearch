extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name MeshGrammarRoom

## @identity
## name: Mesh Grammar Room
## tier: large
## concept: Mesh & shape grammars
## truth: one rule, run deep, raises a tower no architect drew.

@export var max_depth: int = 6
@export var floor_size: float = 7.0
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
	# Room floor
	var floor_mat := _matte_mat(Color(0.1, 0.11, 0.13), 0.9)
	add_child(_box(Vector3(0.0, -0.05, 0.0), Vector3(floor_size, 0.1, floor_size), floor_mat))

	# Overhead truth label
	add_child(_billboard_label("MESH GRAMMAR — GROWN STRUCTURE", Vector3(0.0, 3.6, 0.0), 30, Color(0.8, 0.95, 1.0)))

	# Grammar-grown building
	_grammar_root = Node3D.new()
	_grammar_root.name = "GrownStructure"
	add_child(_grammar_root)

	# Seed: a substantial base block on the floor
	var seed_size := Vector3(1.0, 1.0, 1.0)
	var seed_center := Vector3(0.0, seed_size.y * 0.5, 0.0)
	_grammar_root.add_child(_box(seed_center, seed_size, _tower_mat(0)))
	_grow(seed_center, seed_size, 0)


func _tower_mat(depth: int) -> StandardMaterial3D:
	var t: float = float(depth) / float(max(max_depth, 1))
	# base concrete-steel blue, tips glow cyan/white
	var c: Color = Color(0.35, 0.4, 0.5).lerp(Color(0.55, 0.85, 0.95), t)
	var m: StandardMaterial3D = _glow_mat(c, 0.4 + t * 1.2)
	m.metallic = 0.3
	m.roughness = 0.5
	return m


func _grow(center: Vector3, size: Vector3, depth: int) -> void:
	if depth >= max_depth:
		return
	# Building grammar: mostly stack upward, occasionally inset + branch
	var chosen: Array[Vector3] = [Vector3.UP]
	# branch sideways less often than vertical to keep a tower shape
	if depth >= 1:
		for dir: Vector3 in [Vector3.RIGHT, Vector3.LEFT, Vector3.FORWARD, Vector3.BACK]:
			if _rng.randf() < 0.3:
				chosen.append(dir)

	for dir: Vector3 in chosen:
		var is_up: bool = dir.y > 0.5
		# upward stacks shrink slowly; side branches shrink more
		var shrink: float = _rng.randf_range(0.78, 0.92) if is_up else _rng.randf_range(0.55, 0.72)
		var child_size: Vector3 = size * shrink

		# RULE: inset — a stacked block that is narrower than its parent (ziggurat step)
		if is_up and _rng.randf() < 0.6:
			child_size.x = size.x * _rng.randf_range(0.6, 0.85)
			child_size.z = size.z * _rng.randf_range(0.6, 0.85)
			child_size.y = size.y * _rng.randf_range(0.7, 1.0)

		var half_parent: float = _half_along(size, dir)
		var half_child: float = _half_along(child_size, dir)
		var dist: float = half_parent + half_child
		var child_center: Vector3 = center + dir * dist
		if not is_up:
			# lateral branches lift slightly so they read as outcroppings
			child_center.y += _rng.randf_range(0.0, size.y * 0.15)

		# RULE: split a vertical run into twin towers occasionally
		if is_up and _rng.randf() < 0.22 and depth >= 2:
			var axis: Vector3 = Vector3.RIGHT if _rng.randf() < 0.5 else Vector3.FORWARD
			var s_size: Vector3 = child_size
			s_size = _scale_along(s_size, axis, 0.42)
			var off: float = _half_along(child_size, axis) * 0.55
			var c_a: Vector3 = child_center + axis * off
			var c_b: Vector3 = child_center - axis * off
			_grammar_root.add_child(_box(c_a, s_size, _tower_mat(depth + 1)))
			_grammar_root.add_child(_box(c_b, s_size, _tower_mat(depth + 1)))
			_grow(c_a, s_size, depth + 1)
			_grow(c_b, s_size, depth + 1)
		else:
			_grammar_root.add_child(_box(child_center, child_size, _tower_mat(depth + 1)))
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


func _process(delta: float) -> void:
	if Engine.is_editor_hint():
		return
	_sway_t += delta
	if _grammar_root != null:
		_grammar_root.rotation.y = 0.03 * sin(_sway_t * 0.35)
