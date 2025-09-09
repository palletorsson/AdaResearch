# RandomWalk128.gd
# Random walk algorithm for 128x128 fine-grained grid using cube_scene.tscn
# Creates an 8x8 meter area with tiny cubes

class_name RandomWalk128Algorithm
extends Node3D

# Grid configuration
const GRID_SIZE = 128  # 128x128 grid
const GRID_AREA_SIZE = 8.0  # 8x8 meters
const CUBE_SIZE = GRID_AREA_SIZE / GRID_SIZE  # 0.0625m = 6.25cm per cube
const CUBE_SCALE = CUBE_SIZE  # Scale factor for cube_scene.tscn
const RAISE_AMOUNT = CUBE_SIZE * 0.5  # Half cube height

# Cube scene reference
const CUBE_SCENE_PATH = "res://commons/primitives/cubes/cube_scene.tscn"
var cube_scene_resource: PackedScene

# Grid storage
var grid: Array[Array] = []  # 2D array to track cube heights
var cube_instances: Array[Array] = []  # Store actual cube nodes
var walker_position: Vector2i = Vector2i(64, 64)  # Start at center

# Algorithm settings
@export var steps_per_frame: int = 10
@export var total_steps: int = 20000
@export var auto_start: bool = true
@export var show_walker: bool = true

# State tracking
var current_step: int = 0
var is_running: bool = false
var walker_cube: Node3D
var step_timer: Timer

# Signals
signal walk_step_complete(position: Vector2i, height: float)
signal walk_finished(total_steps: int)

func _ready():
	print("RandomWalk128: Initializing 128x128 random walk system")
	print("Grid size: %dx%d cubes" % [GRID_SIZE, GRID_SIZE])
	print("Area size: %.1fx%.1f meters" % [GRID_AREA_SIZE, GRID_AREA_SIZE])
	print("Cube size: %.4f meters (%.1f cm)" % [CUBE_SIZE, CUBE_SIZE * 100])
	
	# Load cube scene
	cube_scene_resource = load(CUBE_SCENE_PATH)
	if not cube_scene_resource:
		push_error("RandomWalk128: Could not load cube scene from: " + CUBE_SCENE_PATH)
		return
	else:
		print("RandomWalk128: Successfully loaded cube scene")
	
	# Initialize grid
	_initialize_grid()
	
	# Setup timer for smooth animation
	step_timer = Timer.new()
	step_timer.wait_time = 0.016  # ~60 FPS
	step_timer.timeout.connect(_step_walk)
	add_child(step_timer)
	
	# Create walker indicator
	if show_walker:
		_create_walker_indicator()
	
	if auto_start:
		print("RandomWalk128: Auto-start enabled, starting walk...")
		call_deferred("start_walk")
	else:
		print("RandomWalk128: Auto-start disabled. Use Space to start manually.")

func _initialize_grid():
	"""Initialize the 128x128 grid arrays"""
	print("RandomWalk128: Initializing grid arrays...")
	
	grid.resize(GRID_SIZE)
	cube_instances.resize(GRID_SIZE)
	
	for x in range(GRID_SIZE):
		grid[x] = []
		grid[x].resize(GRID_SIZE)
		cube_instances[x] = []
		cube_instances[x].resize(GRID_SIZE)
		
		for z in range(GRID_SIZE):
			grid[x][z] = 0.0  # Initial height
			cube_instances[x][z] = null  # No cube initially
	
	print("RandomWalk128: Grid initialized (%d x %d)" % [GRID_SIZE, GRID_SIZE])

func _create_walker_indicator():
	"""Create a visual indicator for the walker position"""
	walker_cube = cube_scene_resource.instantiate()
	walker_cube.name = "Walker"
	walker_cube.scale = Vector3.ONE * CUBE_SCALE * 2.0  # Bigger for visibility
	

	
	
	add_child(walker_cube)
	_update_walker_position()

func _find_mesh_instance(node: Node) -> MeshInstance3D:
	"""Find MeshInstance3D in node hierarchy"""
	if node is MeshInstance3D:
		return node as MeshInstance3D
	
	for child in node.get_children():
		var mesh = _find_mesh_instance(child)
		if mesh:
			return mesh
	
	return null

func start_walk():
	"""Start the random walk algorithm"""
	if is_running:
		return
	
	print("RandomWalk128: Starting random walk from center position")
	print("Target steps: %d" % total_steps)
	
	is_running = true
	current_step = 0
	walker_position = Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)  # Center
	_update_walker_position()
	
	step_timer.start()

func stop_walk():
	"""Stop the random walk"""
	is_running = false
	step_timer.stop()
	print("RandomWalk128: Walk stopped at step %d" % current_step)

func _step_walk():
	"""Execute multiple walk steps per frame for performance"""
	if not is_running:
		return
	
	for i in range(steps_per_frame):
		if current_step >= total_steps:
			_finish_walk()
			return
		
		_execute_single_step()
		current_step += 1
	
	# Update walker position after batch
	_update_walker_position()

func _execute_single_step():
	"""Execute a single random walk step"""
	# Choose random direction (4-directional: N, E, S, W)
	var directions = [
		Vector2i(0, 1),   # North
		Vector2i(1, 0),   # East
		Vector2i(0, -1),  # South
		Vector2i(-1, 0)   # West
	]
	
	var random_direction = directions[randi() % directions.size()]
	var new_position = walker_position + random_direction
	
	# Clamp to grid boundaries
	new_position.x = clamp(new_position.x, 0, GRID_SIZE - 1)
	new_position.y = clamp(new_position.y, 0, GRID_SIZE - 1)
	
	walker_position = new_position
	
	# Raise cube at walker position
	_raise_cube_at(walker_position.x, walker_position.y)
	
	# Emit step signal
	var height = grid[walker_position.x][walker_position.y]
	walk_step_complete.emit(walker_position, height)

func _raise_cube_at(x: int, z: int):
	"""Raise the cube at the specified grid position"""
	# Increase height in grid
	grid[x][z] += RAISE_AMOUNT
	
	# Create or update physical cube
	if cube_instances[x][z] == null:
		_create_cube_at(x, z)
	else:
		_update_cube_height(x, z)

func _create_cube_at(x: int, z: int):
	"""Create a new cube at the specified grid position"""
	var cube = cube_scene_resource.instantiate()
	cube.name = "Cube_%d_%d" % [x, z]
	
	# Scale down the cube
	cube.scale = Vector3.ONE * CUBE_SCALE
	
	# Position the cube
	var world_pos = _grid_to_world_position(x, z)
	cube.position = Vector3(world_pos.x, grid[x][z] / 2.0, world_pos.y)
	
	# Store reference
	cube_instances[x][z] = cube
	add_child(cube)

func _update_cube_height(x: int, z: int):
	"""Update the height of an existing cube"""
	var cube = cube_instances[x][z]
	if cube:
		var world_pos = _grid_to_world_position(x, z)
		cube.position = Vector3(world_pos.x, grid[x][z] / 2.0, world_pos.y)

func _grid_to_world_position(grid_x: int, grid_z: int) -> Vector2:
	"""Convert grid coordinates to world position"""
	var offset = -GRID_AREA_SIZE / 2.0 + CUBE_SIZE / 2.0
	var world_x = offset + grid_x * CUBE_SIZE
	var world_z = offset + grid_z * CUBE_SIZE
	return Vector2(world_x, world_z)

func _update_walker_position():
	"""Update the visual walker indicator position"""
	if walker_cube:
		var world_pos = _grid_to_world_position(walker_position.x, walker_position.y)
		var walker_height = grid[walker_position.x][walker_position.y] + CUBE_SIZE * 2.0
		walker_cube.position = Vector3(world_pos.x, walker_height, world_pos.y)

func _finish_walk():
	"""Complete the random walk"""
	is_running = false
	step_timer.stop()
	
	print("RandomWalk128: Walk completed!")
	print("Total steps: %d" % current_step)
	print("Final position: %s" % walker_position)
	print("Total cubes created: %d" % _count_created_cubes())
	
	walk_finished.emit(current_step)

func _count_created_cubes() -> int:
	"""Count how many cubes were actually created"""
	var count = 0
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if cube_instances[x][z] != null:
				count += 1
	return count

# === PUBLIC API ===

func restart_walk():
	"""Restart the walk from the beginning"""
	stop_walk()
	_clear_all_cubes()
	current_step = 0
	walker_position = Vector2i(GRID_SIZE / 2, GRID_SIZE / 2)
	start_walk()

func _clear_all_cubes():
	"""Clear all created cubes"""
	for x in range(GRID_SIZE):
		for z in range(GRID_SIZE):
			if cube_instances[x][z] != null:
				cube_instances[x][z].queue_free()
				cube_instances[x][z] = null
			grid[x][z] = 0.0

func set_walk_speed(new_steps_per_frame: int):
	"""Change the walking speed"""
	steps_per_frame = clamp(new_steps_per_frame, 1, 100)
	print("RandomWalk128: Speed set to %d steps per frame" % steps_per_frame)

func get_walk_info() -> Dictionary:
	"""Get current walk information"""
	return {
		"grid_size": GRID_SIZE,
		"cube_size": CUBE_SIZE,
		"current_step": current_step,
		"total_steps": total_steps,
		"walker_position": walker_position,
		"cubes_created": _count_created_cubes(),
		"is_running": is_running,
		"grid_area_meters": GRID_AREA_SIZE
	}

func print_walk_status():
	"""Print current walk status"""
	var info = get_walk_info()
	print("=== RANDOM WALK 128x128 STATUS ===")
	print("Grid: %dx%d (%.1fm x %.1fm)" % [info.grid_size, info.grid_size, info.grid_area_meters, info.grid_area_meters])
	print("Cube size: %.4fm (%.1fcm)" % [info.cube_size, info.cube_size * 100])
	print("Progress: %d / %d steps" % [info.current_step, info.total_steps])
	print("Walker at: %s" % info.walker_position)
	print("Cubes created: %d" % info.cubes_created)
	print("Running: %s" % info.is_running)
	print("=================================")
