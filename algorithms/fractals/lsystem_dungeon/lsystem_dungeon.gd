extends Node3D

# L-System Procedural Dungeon Generator
# Uses Lindenmayer systems to create branching dungeon structures
# Can optionally use CSG booleans for room carving

@export_group("L-System Rules")
@export var axiom: String = "F"
@export var iterations: int = 3
@export var rules: Dictionary = {
	"F": "F[+F]F[-F]F"  # Default branching pattern
}

@export_group("Dungeon Settings")
@export var room_size: float = 4.0
@export var corridor_length: float = 6.0
@export var turn_angle: float = 90.0
@export var branch_probability: float = 0.7
@export var use_csg_carving: bool = false

@export_group("Generation")
@export var show_construction: bool = true
@export var step_delay: float = 0.15
@export var random_seed: int = 0

# Room types
enum RoomType { CORRIDOR, SMALL_ROOM, LARGE_ROOM, JUNCTION, DEAD_END }

# Colors
var floor_color := Color(0.25, 0.22, 0.2)
var wall_color := Color(0.35, 0.32, 0.3)
var ceiling_color := Color(0.2, 0.18, 0.17)
var accent_color := Color(0.5, 0.35, 0.2)

# State
var lsystem_string: String = ""
var all_parts: Array[Node3D] = []
var room_positions: Array[Vector3] = []  # Track placed rooms to avoid overlap

# Turtle state for interpreting L-system
var turtle_pos: Vector3 = Vector3.ZERO
var turtle_dir: Vector3 = Vector3.FORWARD
var turtle_stack: Array[Dictionary] = []

var step_index: int = 0
var is_constructing: bool = false
var timer: float = 0.0

# Preset dungeon patterns
var presets := {
	"linear": {"axiom": "F", "rules": {"F": "FF"}, "iterations": 4},
	"branching": {"axiom": "F", "rules": {"F": "F[+F]F[-F]F"}, "iterations": 3},
	"maze": {"axiom": "F", "rules": {"F": "F+F-F-F+F"}, "iterations": 3},
	"organic": {"axiom": "X", "rules": {"X": "F[+X][-X]FX", "F": "FF"}, "iterations": 4},
	"symmetric": {"axiom": "F", "rules": {"F": "F[+F][-F]"}, "iterations": 4},
	"dense": {"axiom": "F", "rules": {"F": "F[+F][F][-F]F"}, "iterations": 3},
	"spiral": {"axiom": "F", "rules": {"F": "F+F"}, "iterations": 6},
}

func _ready() -> void:
	if random_seed != 0:
		seed(random_seed)
	else:
		randomize()

	generate_lsystem()

	if show_construction:
		is_constructing = true
		step_index = 0
	else:
		_build_instant()

func _process(delta: float) -> void:
	if not is_constructing:
		return

	timer += delta
	if timer >= step_delay:
		timer = 0.0
		_build_step()

func generate_lsystem() -> void:
	"""Generate the L-system string from axiom and rules"""
	lsystem_string = axiom

	for i in range(iterations):
		var new_string = ""
		for c in lsystem_string:
			if rules.has(c):
				new_string += rules[c]
			else:
				new_string += c
		lsystem_string = new_string

	print("L-System Dungeon: Generated string length: %d" % lsystem_string.length())
	print("L-System: %s..." % lsystem_string.substr(0, min(50, lsystem_string.length())))

func _build_instant() -> void:
	"""Build entire dungeon at once"""
	turtle_pos = Vector3.ZERO
	turtle_dir = Vector3.FORWARD
	turtle_stack.clear()

	for c in lsystem_string:
		_interpret_symbol(c)

	print("L-System Dungeon: Built %d parts" % all_parts.size())

func _build_step() -> void:
	"""Build one symbol at a time"""
	if step_index >= lsystem_string.length():
		is_constructing = false
		print("L-System Dungeon: Construction complete! %d parts" % all_parts.size())
		return

	var c = lsystem_string[step_index]
	_interpret_symbol(c)
	step_index += 1

func _interpret_symbol(symbol: String) -> void:
	"""Interpret L-system symbol and build geometry"""
	match symbol:
		"F":
			# Move forward and draw corridor
			_create_corridor()
			turtle_pos += turtle_dir * corridor_length
		"f":
			# Move forward without drawing
			turtle_pos += turtle_dir * corridor_length
		"+":
			# Turn right
			turtle_dir = turtle_dir.rotated(Vector3.UP, deg_to_rad(-turn_angle))
		"-":
			# Turn left
			turtle_dir = turtle_dir.rotated(Vector3.UP, deg_to_rad(turn_angle))
		"[":
			# Push state (start branch)
			turtle_stack.push_back({
				"pos": turtle_pos,
				"dir": turtle_dir
			})
			# Possibly create room at branch point
			if randf() < 0.5:
				_create_room(RoomType.JUNCTION)
		"]":
			# Pop state (end branch)
			if turtle_stack.size() > 0:
				var state = turtle_stack.pop_back()
				turtle_pos = state.pos
				turtle_dir = state.dir
		"X":
			# Variable - no geometry, just placeholder for rules
			pass
		"R":
			# Create a room
			_create_room(RoomType.SMALL_ROOM)
		"L":
			# Create a large room
			_create_room(RoomType.LARGE_ROOM)

func _create_corridor() -> void:
	"""Create a corridor segment"""
	var corridor_width = room_size * 0.6
	var corridor_height = room_size * 0.8

	var midpoint = turtle_pos + turtle_dir * corridor_length * 0.5

	# Check for overlap
	if _check_overlap(midpoint):
		return

	room_positions.append(midpoint)

	if use_csg_carving:
		_create_csg_corridor(midpoint, corridor_width, corridor_height)
	else:
		_create_mesh_corridor(midpoint, corridor_width, corridor_height)

func _create_mesh_corridor(pos: Vector3, width: float, height: float) -> void:
	"""Create corridor using simple meshes"""
	var corridor = Node3D.new()
	corridor.name = "Corridor_%d" % all_parts.size()
	corridor.position = pos

	# Align to turtle direction
	corridor.look_at(pos + turtle_dir, Vector3.UP)

	# Floor
	var floor_mesh = _create_box(
		Vector3(0, 0, 0),
		Vector3(width, 0.1, corridor_length),
		floor_color
	)
	corridor.add_child(floor_mesh)

	# Walls
	var wall_left = _create_box(
		Vector3(-width * 0.5, height * 0.5, 0),
		Vector3(0.2, height, corridor_length),
		wall_color
	)
	corridor.add_child(wall_left)

	var wall_right = _create_box(
		Vector3(width * 0.5, height * 0.5, 0),
		Vector3(0.2, height, corridor_length),
		wall_color
	)
	corridor.add_child(wall_right)

	# Ceiling
	var ceiling = _create_box(
		Vector3(0, height, 0),
		Vector3(width, 0.15, corridor_length),
		ceiling_color
	)
	corridor.add_child(ceiling)

	add_child(corridor)
	all_parts.append(corridor)

func _create_csg_corridor(pos: Vector3, width: float, height: float) -> void:
	"""Create corridor using CSG for carving effect"""
	var combiner = CSGCombiner3D.new()
	combiner.name = "CSGCorridor_%d" % all_parts.size()
	combiner.position = pos
	combiner.look_at(pos + turtle_dir, Vector3.UP)

	# Outer shell
	var outer = CSGBox3D.new()
	outer.size = Vector3(width + 0.4, height + 0.3, corridor_length)
	outer.position.y = height * 0.5
	combiner.add_child(outer)

	# Inner carve (subtraction)
	var inner = CSGBox3D.new()
	inner.size = Vector3(width, height, corridor_length + 0.1)
	inner.position.y = height * 0.5
	inner.operation = CSGShape3D.OPERATION_SUBTRACTION
	combiner.add_child(inner)

	var material = StandardMaterial3D.new()
	material.albedo_color = wall_color
	combiner.material_override = material

	add_child(combiner)
	all_parts.append(combiner)

func _create_room(type: RoomType) -> void:
	"""Create a room at current turtle position"""
	var size_multiplier = 1.0
	match type:
		RoomType.SMALL_ROOM:
			size_multiplier = 1.5
		RoomType.LARGE_ROOM:
			size_multiplier = 2.5
		RoomType.JUNCTION:
			size_multiplier = 1.2
		RoomType.DEAD_END:
			size_multiplier = 0.8

	var actual_size = room_size * size_multiplier

	# Check for overlap
	if _check_overlap(turtle_pos):
		return

	room_positions.append(turtle_pos)

	var room = Node3D.new()
	room.name = "Room_%d_%s" % [all_parts.size(), RoomType.keys()[type]]
	room.position = turtle_pos

	var height = room_size * 0.9

	# Floor
	var floor_mesh = _create_box(
		Vector3(0, 0, 0),
		Vector3(actual_size, 0.15, actual_size),
		floor_color
	)
	room.add_child(floor_mesh)

	# Walls with openings approximated
	var wall_thickness = 0.25

	# North wall
	var wall_n = _create_box(
		Vector3(0, height * 0.5, actual_size * 0.5),
		Vector3(actual_size, height, wall_thickness),
		wall_color
	)
	room.add_child(wall_n)

	# South wall
	var wall_s = _create_box(
		Vector3(0, height * 0.5, -actual_size * 0.5),
		Vector3(actual_size, height, wall_thickness),
		wall_color
	)
	room.add_child(wall_s)

	# East wall
	var wall_e = _create_box(
		Vector3(actual_size * 0.5, height * 0.5, 0),
		Vector3(wall_thickness, height, actual_size),
		wall_color
	)
	room.add_child(wall_e)

	# West wall
	var wall_w = _create_box(
		Vector3(-actual_size * 0.5, height * 0.5, 0),
		Vector3(wall_thickness, height, actual_size),
		wall_color
	)
	room.add_child(wall_w)

	# Ceiling
	var ceiling = _create_box(
		Vector3(0, height, 0),
		Vector3(actual_size, 0.2, actual_size),
		ceiling_color
	)
	room.add_child(ceiling)

	# Add detail based on room type
	if type == RoomType.LARGE_ROOM:
		_add_pillars(room, actual_size, height)

	add_child(room)
	all_parts.append(room)

func _add_pillars(room: Node3D, size: float, height: float) -> void:
	"""Add decorative pillars to large rooms"""
	var pillar_size = 0.4
	var inset = size * 0.35

	var positions = [
		Vector3(-inset, height * 0.5, -inset),
		Vector3(inset, height * 0.5, -inset),
		Vector3(-inset, height * 0.5, inset),
		Vector3(inset, height * 0.5, inset),
	]

	for pos in positions:
		var pillar = _create_box(pos, Vector3(pillar_size, height, pillar_size), accent_color)
		room.add_child(pillar)

func _create_box(pos: Vector3, size: Vector3, color: Color) -> MeshInstance3D:
	"""Create a simple box mesh"""
	var mesh_instance = MeshInstance3D.new()
	var box = BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	mesh_instance.material_override = material

	return mesh_instance

func _check_overlap(pos: Vector3) -> bool:
	"""Check if position overlaps with existing rooms"""
	var min_distance = room_size * 0.8
	for existing_pos in room_positions:
		if pos.distance_to(existing_pos) < min_distance:
			return true
	return false

# Public API
func use_preset(preset_name: String) -> void:
	"""Apply a preset L-system pattern"""
	if presets.has(preset_name):
		var preset = presets[preset_name]
		axiom = preset.axiom
		rules = preset.rules
		iterations = preset.iterations
		reset()

func reset() -> void:
	"""Clear and regenerate dungeon"""
	for part in all_parts:
		if is_instance_valid(part):
			part.queue_free()
	all_parts.clear()
	room_positions.clear()

	turtle_pos = Vector3.ZERO
	turtle_dir = Vector3.FORWARD
	turtle_stack.clear()

	generate_lsystem()

	if show_construction:
		is_constructing = true
		step_index = 0
		timer = 0.0
	else:
		_build_instant()

func set_rules_from_string(rule_string: String) -> void:
	"""Parse rules from string format like 'F:F[+F][-F]F,X:FX'"""
	rules.clear()
	var pairs = rule_string.split(",")
	for pair in pairs:
		var parts = pair.split(":")
		if parts.size() == 2:
			rules[parts[0].strip_edges()] = parts[1].strip_edges()
	reset()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

