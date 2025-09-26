extends Node3D

# Randomly add boxes to the grid system within a bounding box
# Based on the cube structure from grid_3d_4x4x4.gd

@export var bounding_box_min: Vector3 = Vector3(0, 0, 0)
@export var bounding_box_max: Vector3 = Vector3(10, 10, 10)
@export var cube_spacing: float = 1.0
@export var add_interval: float = 1.0  # Add a box every 1 second
@export var max_cubes: int = 100  # Maximum number of cubes to add

var timer: Timer
var cube_scene: PackedScene
var added_cubes: Array = []
var current_cube_count: int = 0

func _ready():
	# Load the pickup cube scene (same as grid_3d_4x4x4.gd)
	cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	
	# Create timer for adding cubes
	timer = Timer.new()
	timer.wait_time = add_interval
	timer.one_shot = false
	timer.timeout.connect(_on_add_timer_timeout)
	add_child(timer)
	
	# Start adding cubes
	timer.start()
	print("Started randomly adding cubes to grid. Bounding box: ", bounding_box_min, " to ", bounding_box_max)

func _on_add_timer_timeout():
	"""Called every add_interval seconds to add a random cube"""
	if current_cube_count >= max_cubes:
		print("Maximum cube limit reached: ", max_cubes)
		timer.stop()
		return
	
	# Generate random position within bounding box
	var random_pos = generate_random_position()
	
	# Check if position is already occupied
	if is_position_occupied(random_pos):
		print("Position occupied, trying again: ", random_pos)
		return
	
	# Create and add the cube
	add_cube_at_position(random_pos)
	current_cube_count += 1
	print("Added cube #", current_cube_count, " at position: ", random_pos)

func generate_random_position() -> Vector3:
	"""Generate a random position within the bounding box"""
	var x = randf_range(bounding_box_min.x, bounding_box_max.x)
	var y = randf_range(bounding_box_min.y, bounding_box_max.y)
	var z = randf_range(bounding_box_min.z, bounding_box_max.z)
	
	# Snap to grid spacing
	x = round(x / cube_spacing) * cube_spacing
	y = round(y / cube_spacing) * cube_spacing
	z = round(z / cube_spacing) * cube_spacing
	
	return Vector3(x, y, z)

func is_position_occupied(pos: Vector3) -> bool:
	"""Check if a position is already occupied by a cube"""
	for cube in added_cubes:
		if cube.position.distance_to(pos) < 0.1:  # Small tolerance for floating point
			return true
	return false

func add_cube_at_position(pos: Vector3):
	"""Add a cube at the specified position"""
	if not cube_scene:
		print("Error: Cube scene not loaded")
		return
	
	# Instantiate the cube (same as grid_3d_4x4x4.gd)
	var cube_instance = cube_scene.instantiate()
	cube_instance.name = "RandomCube_" + str(current_cube_count) + "_" + str(pos.x) + "_" + str(pos.y) + "_" + str(pos.z)
	cube_instance.position = pos
	
	# Add to scene and track it
	add_child(cube_instance)
	added_cubes.append(cube_instance)
	
	print("Created cube: ", cube_instance.name, " at ", pos)

func set_bounding_box(min_pos: Vector3, max_pos: Vector3):
	"""Set the bounding box for random cube placement"""
	bounding_box_min = min_pos
	bounding_box_max = max_pos
	print("Updated bounding box: ", bounding_box_min, " to ", bounding_box_max)

func set_add_interval(interval: float):
	"""Set how often to add cubes (in seconds)"""
	add_interval = interval
	if timer:
		timer.wait_time = interval
	print("Updated add interval to: ", interval, " seconds")

func set_max_cubes(max: int):
	"""Set maximum number of cubes to add"""
	max_cubes = max
	print("Updated max cubes to: ", max)

func stop_adding():
	"""Stop adding cubes"""
	if timer:
		timer.stop()
	print("Stopped adding cubes. Total cubes: ", current_cube_count)

func start_adding():
	"""Start adding cubes"""
	if timer:
		timer.start()
	print("Started adding cubes")

func clear_all_cubes():
	"""Remove all added cubes"""
	for cube in added_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	added_cubes.clear()
	current_cube_count = 0
	print("Cleared all cubes")

func get_cube_count() -> int:
	"""Get current number of cubes"""
	return current_cube_count

func get_cube_positions() -> Array:
	"""Get array of all cube positions"""
	var positions = []
	for cube in added_cubes:
		if is_instance_valid(cube):
			positions.append(cube.position)
	return positions
