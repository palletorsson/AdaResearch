class_name RandomWalkAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = ""
var algorithm_description: String = ""
var grid_reference = null
var max_steps: int = -1  # -1 means unlimited

# Walker properties
var walker_x: int = 0
var walker_z: int = 0  # Changed from walker_y to walker_z for proper 3D
@export var trail_length: int = 20
var trail_positions: Array[Vector2i] = []

# 8x8 area bounds in the middle of 11x16 map
@export var region_min_x: int = 2
@export var region_max_x: int = 9
@export var region_min_z: int = 4
@export var region_max_z: int = 11
@export var target_y_level: int = 1

# Node3D properties
@export var auto_start: bool = true
@export var step_delay: float = 0.1
var timer: Timer
var is_running: bool = false

# Signals
signal algorithm_step_complete()
signal algorithm_finished()

func _init():
	algorithm_name = "Random Walk (8x8 Region)"
	algorithm_description = "Walker leaves trail in middle 8x8 area"

func _ready():
	# Create timer for stepping
	timer = Timer.new()
	timer.wait_time = step_delay
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Auto-connect to grid system
	call_deferred("_find_and_connect_grid")
	
	if auto_start:
		call_deferred("start_algorithm")

func _find_and_connect_grid():
	# Look for GridSystem in the scene
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		# Try finding by class name
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		set_grid_reference(grid_system)
		print("RandomWalkAlgorithm: Connected to grid system")
	else:
		print("RandomWalkAlgorithm: WARNING - Could not find GridSystem!")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func start_algorithm():
	if not grid_reference:
		print("RandomWalkAlgorithm: Cannot start - grid not ready")
		return
	
	setup_initial_state()
	is_running = true
	timer.start()
	print("RandomWalkAlgorithm: Algorithm started")

func stop_algorithm():
	is_running = false
	timer.stop()
	print("RandomWalkAlgorithm: Algorithm stopped")

func step_once():
	if not grid_reference:
		return false
	
	var result = execute_step()
	algorithm_step_complete.emit()
	
	if not result:
		stop_algorithm()
		algorithm_finished.emit()
	
	return result

func _on_timer_timeout():
	if is_running:
		step_once()

func setup_initial_state():
	# Start walker in center of 8x8 region
	walker_x = (region_min_x + region_max_x) / 2
	walker_z = (region_min_z + region_max_z) / 2
	trail_positions.clear()
	set_cell_3d(walker_x, walker_z, true)
	trail_positions.append(Vector2i(walker_x, walker_z))

func execute_step() -> bool:
	var directions = [Vector2i(-1, 0), Vector2i(1, 0), Vector2i(0, -1), Vector2i(0, 1)]
	var direction = directions[randi() % directions.size()]
	
	var new_x = walker_x + direction.x
	var new_z = walker_z + direction.y
	
	# Keep walker within 8x8 region bounds
	new_x = clamp(new_x, region_min_x, region_max_x)
	new_z = clamp(new_z, region_min_z, region_max_z)
	
	walker_x = new_x
	walker_z = new_z
	
	set_cell_3d(walker_x, walker_z, true)
	trail_positions.append(Vector2i(walker_x, walker_z))
	
	if trail_positions.size() > trail_length:
		var old_pos = trail_positions.pop_front()
		set_cell_3d(old_pos.x, old_pos.y, false)
	
	return true

# Set grid reference for the algorithm to work with
func set_grid_reference(grid_ref):
	grid_reference = grid_ref

# New function to work with 3D grid system at specified Y level
func set_cell_3d(x: int, z: int, active: bool):
	if not grid_reference:
		return
	
	# Get the structure component from the new grid system
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	if active:
		# Place cube at target Y level
		_place_cube_at(x, target_y_level, z)
	else:
		# Remove cube at target Y level
		_remove_cube_at(x, target_y_level, z)

# Place a cube at specific 3D coordinates
func _place_cube_at(x: int, y: int, z: int):
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Check if cube already exists
	if structure_component.has_cube_at(x, y, z):
		return
	
	# Create new cube using the grid system's method
	var total_size = structure_component.cube_size + structure_component.gutter
	structure_component._add_cube(x, y, z, total_size)
	# Don't manipulate grid array directly - let the component handle it

# Remove a cube at specific 3D coordinates
func _remove_cube_at(x: int, y: int, z: int):
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Get and remove the cube
	var cube = structure_component.get_cube_at(x, y, z)
	if cube and is_instance_valid(cube):
		cube.queue_free()
		structure_component.cube_map.erase(Vector3i(x, y, z))
		# Don't manipulate grid array directly - let the component handle it

# Get current region bounds for external access
func get_region_bounds() -> Dictionary:
	return {
		"min_x": region_min_x,
		"max_x": region_max_x,
		"min_z": region_min_z,
		"max_z": region_max_z,
		"center_x": (region_min_x + region_max_x) / 2,
		"center_z": (region_min_z + region_max_z) / 2
	}

# Get algorithm info
func get_algorithm_info() -> Dictionary:
	return {
		"name": algorithm_name,
		"description": algorithm_description,
		"max_steps": max_steps,
		"region_bounds": get_region_bounds()
	}
