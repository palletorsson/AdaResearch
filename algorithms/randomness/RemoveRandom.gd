class_name RandomRemovalAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = ""
var algorithm_description: String = ""
var grid_reference = null
var max_steps: int = 15

# Removal properties
var removal_count: int = 0
@export var max_removals: int = 15
var active_positions: Array[Vector2i] = []

# 8x8 area bounds in the middle of 11x16 map
@export var region_min_x: int = 2
@export var region_max_x: int = 9
@export var region_min_z: int = 4
@export var region_max_z: int = 11
@export var target_y_level: int = 1

# Node3D properties
@export var auto_start: bool = true
@export var step_delay: float = 0.2
var timer: Timer
var is_running: bool = false

# Signals
signal algorithm_step_complete()
signal algorithm_finished()

func _init():
	algorithm_name = "Random Removal (8x8 Region)"
	algorithm_description = "Random cube removal in middle 8x8 area"
	max_steps = max_removals

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
		print("RandomRemovalAlgorithm: Connected to grid system")
	else:
		print("RandomRemovalAlgorithm: WARNING - Could not find GridSystem!")

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
		print("RandomRemovalAlgorithm: Cannot start - grid not ready")
		return
	
	setup_initial_state()
	is_running = true
	timer.start()
	print("RandomRemovalAlgorithm: Algorithm started")

func stop_algorithm():
	is_running = false
	timer.stop()
	print("RandomRemovalAlgorithm: Algorithm stopped")

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
	# Find existing cubes in the 8x8 region first
	active_positions.clear()
	
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Collect all existing cubes in the region at target Y level
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			# Check only target Y level for existing cubes
			if structure_component.has_cube_at(x, target_y_level, z):
				active_positions.append(Vector2i(x, z))
	
	removal_count = 0
	print("RandomRemoval: Found %d positions with cubes in 8x8 region" % active_positions.size())

func execute_step() -> bool:
	if removal_count >= max_removals or active_positions.is_empty():
		return false
	
	# Choose random position from remaining active cubes
	var random_index = randi() % active_positions.size()
	var pos = active_positions[random_index]
	
	# Remove the topmost cube at this position
	_remove_top_cube_at(pos.x, pos.y)
	
	# Check if there are still cubes at this position
	if not _has_cubes_at_position(pos.x, pos.y):
		active_positions.remove_at(random_index)
	
	removal_count += 1
	
	return removal_count < max_removals and not active_positions.is_empty()

# Set grid reference for the algorithm to work with
func set_grid_reference(grid_ref):
	grid_reference = grid_ref

# Remove the cube at target Y level position
func _remove_top_cube_at(x: int, z: int):
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Remove cube at target Y level
	var cube = structure_component.get_cube_at(x, target_y_level, z)
	if cube and is_instance_valid(cube):
		cube.queue_free()
		structure_component.cube_map.erase(Vector3i(x, target_y_level, z))
		# Don't manipulate grid array directly - let the component handle it

# Check if there are any cubes remaining at x,z position (target Y level)
func _has_cubes_at_position(x: int, z: int) -> bool:
	if not grid_reference:
		return false
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return false
	
	return structure_component.has_cube_at(x, target_y_level, z)

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
		"max_removals": max_removals,
		"current_removals": removal_count,
		"active_positions": active_positions.size(),
		"region_bounds": get_region_bounds()
	} 
