class_name HeightRandomnessAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = ""
var algorithm_description: String = ""
var grid_reference = null
var max_steps: int = 100

# Height properties
@export var raise_amount: float = 0.2
var total_raises: int = 0
@export var max_raises: int = 100

# 8x8 area bounds in the middle of 11x16 map
@export var region_min_x: int = 2
@export var region_max_x: int = 9
@export var region_min_z: int = 4
@export var region_max_z: int = 11
@export var target_y_level: int = 1

# Node3D properties
@export var auto_start: bool = true
@export var step_delay: float = 0.15
@export var auto_loop: bool = true  # Automatically restart when finished
@export var loop_delay: float = 2.0  # Delay before restarting (seconds)
var timer: Timer
var loop_timer: Timer
var is_running: bool = false

# Signals
signal algorithm_step_complete()
signal algorithm_finished()

func _init():
	algorithm_name = "Height Distribution (8x8 Region)"
	algorithm_description = "Random height distribution in middle 8x8 area with auto-loop capability"
	max_steps = max_raises

func _ready():
	# Create timer for stepping
	timer = Timer.new()
	timer.wait_time = step_delay
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Create timer for looping
	loop_timer = Timer.new()
	loop_timer.wait_time = loop_delay
	loop_timer.one_shot = true
	loop_timer.timeout.connect(_on_loop_timer_timeout)
	add_child(loop_timer)
	
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
		print("HeightRandomnessAlgorithm: Connected to grid system")
	else:
		print("HeightRandomnessAlgorithm: WARNING - Could not find GridSystem!")

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
		print("HeightRandomnessAlgorithm: Cannot start - grid not ready")
		return
	
	setup_initial_state()
	is_running = true
	timer.start()
	print("HeightRandomnessAlgorithm: Algorithm started")

func stop_algorithm():
	is_running = false
	timer.stop()
	loop_timer.stop()  # Also stop the loop timer
	print("HeightRandomnessAlgorithm: Algorithm stopped")

func set_auto_loop(enabled: bool):
	"""Enable or disable automatic looping"""
	auto_loop = enabled
	print("HeightRandomnessAlgorithm: Auto-loop %s" % ("enabled" if enabled else "disabled"))

func step_once():
	if not grid_reference:
		return false
	
	var result = execute_step()
	algorithm_step_complete.emit()
	
	if not result:
		stop_algorithm()
		algorithm_finished.emit()
		
		# Start loop timer if auto_loop is enabled
		if auto_loop:
			print("HeightRandomnessAlgorithm: Algorithm finished, restarting in %.1f seconds..." % loop_delay)
			loop_timer.start()
	
	return result

func _on_timer_timeout():
	if is_running:
		step_once()

func _on_loop_timer_timeout():
	"""Called when it's time to restart the algorithm"""
	if auto_loop:
		reset_algorithm()
		start_algorithm()

func reset_algorithm():
	"""Reset the algorithm to its initial state"""
	if not grid_reference:
		return
	
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	print("HeightRandomnessAlgorithm: Resetting cubes to base level...")
	
	# Reset all cubes in the region back to their base positions
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			var cube = structure_component.get_cube_at(x, target_y_level, z)
			if cube:
				# Reset to original position using GridCommon utility
				var grid_pos = Vector3i(x, target_y_level, z)
				var world_pos = GridCommon.grid_to_world_position(grid_pos, structure_component.cube_size, structure_component.gutter)
				cube.position = world_pos
	
	# Reset counters
	total_raises = 0
	
	print("HeightRandomnessAlgorithm: Reset complete - ready to restart")

func setup_initial_state():
	# Ensure there are base cubes in the 8x8 region
	if not grid_reference:
		return
		
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Add base cubes in the region at target Y level if they don't exist
	for x in range(region_min_x, region_max_x + 1):
		for z in range(region_min_z, region_max_z + 1):
			if not structure_component.has_cube_at(x, target_y_level, z):
				_place_cube_at(x, target_y_level, z)
	
	total_raises = 0
	print("HeightRandomness: Initialized 8x8 region with base cubes")

func execute_step() -> bool:
	if total_raises >= max_raises:
		return false
	
	# Choose random position within the 8x8 region
	var rand_x = randi_range(region_min_x, region_max_x)
	var rand_z = randi_range(region_min_z, region_max_z)
	
	# Raise the cube at this position
	_raise_cube(rand_x, rand_z)
	total_raises += 1
	
	return total_raises < max_raises

# Set grid reference for the algorithm to work with
func set_grid_reference(grid_ref):
	grid_reference = grid_ref

func _raise_cube(x: int, z: int):
	if not grid_reference:
		return
	
	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return
	
	# Raise the cube at target Y level position
	var cube = structure_component.get_cube_at(x, target_y_level, z)
	if cube:
		cube.position.y += raise_amount

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
		"max_raises": max_raises,
		"current_raises": total_raises,
		"raise_amount": raise_amount,
		"auto_loop": auto_loop,
		"loop_delay": loop_delay,
		"is_running": is_running,
		"region_bounds": get_region_bounds()
	} 
