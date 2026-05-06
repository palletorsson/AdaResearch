extends Node3D

## Scene references
@export var cube_scene: PackedScene = preload("res://commons/primitives/cubes/cube_scene.tscn")
@export var slope_cube_scene: PackedScene = preload("res://algorithms/randomness/randomup/slopecube.tscn")

## Generation parameters
@export var max_steps: int = 50
@export var upward_bias: float = 0.6  # 60% chance to move up
@export var horizontal_range: int = 8  # Max X/Z deviation
@export var seed: int = 0

## Grid settings (matching your 1m cube)
const CUBE_SIZE: Vector3 = Vector3.ONE
const BRIDGE_SPAN: int = 3  # Slope cube covers 3m horizontally

## Private state
var _rng: RandomNumberGenerator
var _current_position: Vector3i
var _occupied_positions: Dictionary = {}  # Vector3i -> Node3D
var _nav_graph: Dictionary = {}  # Vector3i -> Array[Vector3i]
var _blocked_positions: Dictionary = {}  # Vector3i -> bool, reserved by slope footprints


func _ready() -> void:
	_rng = RandomNumberGenerator.new()
	_rng.seed = seed
	_current_position = Vector3i.ZERO
	generate_palace()


func generate_palace() -> void:
	# Start with foundation cube
	_place_cube(_current_position)
	
	for step in range(max_steps):
		var next_pos = _choose_next_position()
		var is_upward_move = next_pos.y > _current_position.y
		
		if next_pos == _current_position:
			continue
		
		if _is_viable_target(next_pos):
			if is_upward_move:
				_place_slope_cube(_current_position, next_pos)
			else:
				_place_cube(next_pos)
			
			# Update navigation graph
			if not _nav_graph.has(_current_position):
				_nav_graph[_current_position] = []
			_nav_graph[_current_position].append(next_pos)
			_nav_graph[next_pos] = [_current_position]  # Initialize with backward link
			
			_current_position = next_pos
		
		# Early exit if we've reached altitude cap
		if next_pos.y > max_steps * 0.8:
			break


func _choose_next_position() -> Vector3i:
	"""Biased random walk where upward moves use 3m bridge geometry."""
	if _rng.randf() < upward_bias:
		var upward_target = _pick_vertical_target()
		if upward_target != Vector3i.ZERO:
			return upward_target
	
	return _pick_horizontal_target()


func _pick_vertical_target() -> Vector3i:
	var axes = [0, 1]
	axes.shuffle()
	for axis in axes:
		var signs = [-1, 1]
		signs.shuffle()
		for sign in signs:
			var candidate = _current_position
			candidate.y += 1
			if axis == 0:
				candidate.x += sign * BRIDGE_SPAN
			else:
				candidate.z += sign * BRIDGE_SPAN
			if _is_viable_target(candidate):
				return candidate
	return Vector3i.ZERO


func _pick_horizontal_target() -> Vector3i:
	var attempts = 0
	while attempts < 16:
		var offset = Vector3i(
			_rng.randi_range(-1, 1),
			0,
			_rng.randi_range(-1, 1)
		)
		if offset == Vector3i.ZERO:
			attempts += 1
			continue
		var candidate = _current_position + offset
		if _is_viable_target(candidate):
			return candidate
		attempts += 1
	
	return _fallback_horizontal_target()


func _fallback_horizontal_target() -> Vector3i:
	var offsets = [
		Vector3i(1, 0, 0),
		Vector3i(-1, 0, 0),
		Vector3i(0, 0, 1),
		Vector3i(0, 0, -1),
		Vector3i(1, 0, 1),
		Vector3i(-1, 0, 1),
		Vector3i(1, 0, -1),
		Vector3i(-1, 0, -1)
	]
	for offset in offsets:
		var candidate = _current_position + offset
		if _is_viable_target(candidate):
			return candidate
	return _current_position


func _place_cube(pos: Vector3i) -> void:
	"""Instantiate cube and register in spatial database"""
	var cube = cube_scene.instantiate()
	cube.position = pos
	add_child(cube)
	_register_cube(pos, cube)


func _place_slope_cube(from: Vector3i, to: Vector3i) -> void:
	"""Places the combined slope+cube bridge for upward moves and reserves the slope footprint."""
	var slope_cube = slope_cube_scene.instantiate()
	slope_cube.position = Vector3(to)
	slope_cube.rotation = _bridge_rotation(from, to)
	add_child(slope_cube)
	_register_cube(to, slope_cube)
	_block_bridge_between(from, to)
	print("Slope cube %s -> %s (rot: %.2f deg)" % [from, to, rad_to_deg(slope_cube.rotation.y)])


func _register_cube(pos: Vector3i, node: Node3D) -> void:
	_occupied_positions[pos] = node
	if not _nav_graph.has(pos):
		_nav_graph[pos] = []


func _bridge_rotation(from: Vector3i, to: Vector3i) -> Vector3:
	var horizontal = Vector3(from.x - to.x, 0, from.z - to.z)
	if horizontal.length() == 0:
		return Vector3.ZERO
	horizontal = horizontal.normalized()
	var yaw = atan2(-horizontal.x, -horizontal.z)
	return Vector3(0, yaw, 0)


func _block_bridge_between(from: Vector3i, to: Vector3i) -> void:
	var horizontal = Vector3i(to.x - from.x, 0, to.z - from.z)
	if horizontal == Vector3i.ZERO:
		return
	var step = Vector3i(_sign_int(horizontal.x), 0, _sign_int(horizontal.z))
	_block_column_above(from, 2)
	_block_cell(to)
	_block_column_above(to, 2)
	for i in range(1, BRIDGE_SPAN):
		var walkway_cell = to - step * i
		_block_cell(walkway_cell)
		_block_column_above(walkway_cell, 2)
		var lower_cell = Vector3i(walkway_cell.x, walkway_cell.y - 1, walkway_cell.z)
		_block_cell(lower_cell)


func _is_viable_target(pos: Vector3i) -> bool:
	return _is_within_bounds(pos) and not _occupied_positions.has(pos) and not _is_blocked(pos)


func _is_within_bounds(pos: Vector3i) -> bool:
	return abs(pos.x) <= horizontal_range and abs(pos.z) <= horizontal_range


func _is_blocked(pos: Vector3i) -> bool:
	return _blocked_positions.has(pos)


func _sign_int(value: int) -> int:
	if value > 0:
		return 1
	elif value < 0:
		return -1
	return 0




func _block_cell(pos: Vector3i) -> void:
	_blocked_positions[pos] = true


func _block_column_above(base: Vector3i, extra_levels: int) -> void:
	for height in range(1, extra_levels + 1):
		var elevated = Vector3i(base.x, base.y + height, base.z)
		_block_cell(elevated)

func _validate_palace() -> bool:
	"""Flood-fill from origin to ensure 100% traversability"""
	var visited = []
	var stack = [Vector3i.ZERO]
	
	while stack.size() > 0:
		var pos = stack.pop_back()
		if visited.has(pos): 
			continue
		
		visited.append(pos)
		for neighbor in _nav_graph.get(pos, []):
			if not visited.has(neighbor):
				stack.append(neighbor)
	
	var all_reachable = visited.size() == _occupied_positions.size()
	print("Palace self-validation: %d/%d cubes reachable = %s" % 
		  [visited.size(), _occupied_positions.size(), "PASS" if all_reachable else "FAIL"])
	return all_reachable

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
