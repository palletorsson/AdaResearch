class_name GaussianDistributionAlgorithm
extends Node3D

# Algorithm properties
var algorithm_name: String = ""
var algorithm_description: String = ""
var grid_reference = null
var max_steps: int = 200

# Gaussian properties
@export var raise_amount: float = 0.05
var total_raises: int = 0
@export var max_raises: int = 200
var center_x: float
var center_z: float
@export var sigma: float = 2.0  # Standard deviation

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

# Box-Muller spare value (persists across calls)
var _has_spare: bool = false
var _spare: float = 0.0

# Position lookup cache (avoids O(n) search per step)
var _position_cache: Dictionary = {}

# Signals
signal algorithm_step_complete()
signal algorithm_finished()

func _init() -> void:
	algorithm_name = "Gaussian Distribution (8x8 Region)"
	algorithm_description = "Bell curve distribution in middle 8x8 area"
	max_steps = max_raises

func _ready() -> void:
	# Create timer for stepping
	timer = Timer.new()
	timer.wait_time = step_delay
	timer.timeout.connect(_on_timer_timeout)
	add_child(timer)
	
	# Auto-connect to grid system
	call_deferred("_find_and_connect_grid")
	
	if auto_start:
		call_deferred("start_algorithm")

func _find_and_connect_grid() -> void:
	# Look for GridSystem in the scene
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		# Try finding by class name
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		set_grid_reference(grid_system)
		print("GaussianDistributionAlgorithm: Connected to grid system")
	else:
		print("GaussianDistributionAlgorithm: WARNING - Could not find GridSystem!")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	if node and node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func start_algorithm() -> void:
	if not grid_reference:
		print("GaussianDistributionAlgorithm: Cannot start - grid not ready")
		return
	
	setup_initial_state()
	is_running = true
	timer.start()
	print("GaussianDistributionAlgorithm: Algorithm started")

func stop_algorithm() -> void:
	is_running = false
	timer.stop()
	print("GaussianDistributionAlgorithm: Algorithm stopped")

func step_once():
	if not grid_reference:
		return false
	
	var result = execute_step()
	algorithm_step_complete.emit()
	
	if not result:
		stop_algorithm()
		algorithm_finished.emit()
	
	return result

func _on_timer_timeout() -> void:
	if is_running:
		step_once()

func setup_initial_state() -> void:
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
	
	# Set center of distribution to middle of 8x8 region
	center_x = (region_min_x + region_max_x) / 2.0
	center_z = (region_min_z + region_max_z) / 2.0
	total_raises = 0
	
	print("GaussianDistribution: Initialized with center at (%f, %f)" % [center_x, center_z])

func execute_step() -> bool:
	if total_raises >= max_raises:
		return false
	
	# Generate Gaussian distributed coordinates
	var rand_x = _gaussian_random(center_x, sigma)
	var rand_z = _gaussian_random(center_z, sigma)
	
	# Clamp to 8x8 region bounds
	var x = int(clamp(rand_x, region_min_x, region_max_x))
	var z = int(clamp(rand_z, region_min_z, region_max_z))
	
	# Raise the cube at this position
	_raise_cube(x, z)
	total_raises += 1
	
	return total_raises < max_raises

# Set grid reference for the algorithm to work with
func set_grid_reference(grid_ref) -> void:
	grid_reference = grid_ref

func _gaussian_random(mean: float, std_dev: float) -> float:
	# Box-Muller transform to generate Gaussian random numbers
	if _has_spare:
		_has_spare = false
		return _spare * std_dev + mean

	_has_spare = true
	var u := maxf(randf(), 1e-10)  # Avoid log(0)
	var v := randf()
	var mag := std_dev * sqrt(-2.0 * log(u))
	_spare = mag * cos(2.0 * PI * v)
	return mag * sin(2.0 * PI * v) + mean

func _raise_cube(x: int, z: int) -> void:
	if not grid_reference:
		return

	var structure_component = grid_reference.get_structure_component()
	if not structure_component:
		return

	# Find the MultiMesh instance for this cube position
	var multimesh = structure_component.multimesh
	if not multimesh:
		return

	# Find the instance index for this position
	var instance_idx = _find_instance_index(structure_component, x, target_y_level, z)
	if instance_idx >= 0:
		# Get current transform and raise it
		var transform = multimesh.get_instance_transform(instance_idx)
		transform.origin.y += raise_amount
		multimesh.set_instance_transform(instance_idx, transform)

# Place a cube at specific 3D coordinates
func _place_cube_at(_x: int, y: int, z: int) -> void:
	# With MultiMesh, cubes should be pre-generated by the structure
	# This function is kept for compatibility but does nothing
	# Cubes need to exist in the initial structure layout
	pass

# Find the instance index for a given grid position (cached)
func _find_instance_index(structure_component, x: int, y: int, z: int) -> int:
	var target_pos := Vector3i(x, y, z)

	if _position_cache.has(target_pos):
		return _position_cache[target_pos]

	# Build cache on first miss
	if _position_cache.is_empty():
		var cube_positions = structure_component.cube_positions
		for i in range(cube_positions.size()):
			_position_cache[cube_positions[i]] = i

	return _position_cache.get(target_pos, -1)

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
		"sigma": sigma,
		"center": {"x": center_x, "z": center_z},
		"region_bounds": get_region_bounds()
	}

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
