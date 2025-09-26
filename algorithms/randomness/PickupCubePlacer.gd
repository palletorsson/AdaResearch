# PickupCubePlacer.gd
# Script to place multiple pickup cubes in the grid system

extends Node3D
class_name PickupCubePlacer

@export var number_of_cubes: int = 10
@export var placement_pattern: String = "random"  # "random", "grid", "circle", "line"
@export var grid_bounds: Vector3i = Vector3i(3, 1, 21)  # Max placement area
@export var avoid_occupied_spaces: bool = true

const PICKUP_CUBE_SCENE = "res://commons/scenes/mapobjects/pick_up_cube.tscn"

var grid_system: GridSystem
var pickup_cubes: Array[Node3D] = []

func _ready():
	# Find the grid system
	call_deferred("_find_grid_system")

func _find_grid_system():
	# Look for GridSystem in the scene
	grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		print("PickupCubePlacer: Found grid system")
		# Wait for grid to be ready
		if grid_system.is_map_ready():
			place_pickup_cubes()
		else:
			grid_system.map_generation_complete.connect(place_pickup_cubes)
	else:
		print("PickupCubePlacer: WARNING - No GridSystem found!")

func _find_node_by_class(node: Node, _class_name: String) -> Node:
	if node.get_script() and node.get_script().get_global_name() == _class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, _class_name)
		if result:
			return result
	return null

func place_pickup_cubes():
	print("PickupCubePlacer: Placing %d pickup cubes using '%s' pattern" % [number_of_cubes, placement_pattern])
	
	var positions = _generate_positions()
	
	for i in range(min(number_of_cubes, positions.size())):
		var pos = positions[i]
		_create_pickup_cube_at(pos.x+1, pos.y, pos.z)
	
	print("PickupCubePlacer: ✅ Placed %d pickup cubes" % pickup_cubes.size())

func _generate_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	
	match placement_pattern:
		"random":
			positions = _generate_random_positions()
		"grid":
			positions = _generate_grid_positions()
		"circle":
			positions = _generate_circle_positions()
		"line":
			positions = _generate_line_positions()
		_:
			print("PickupCubePlacer: Unknown pattern '%s', using random" % placement_pattern)
			positions = _generate_random_positions()
	
	return positions

func _generate_random_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var attempts = 0
	var max_attempts = number_of_cubes * 10
	
	while positions.size() < number_of_cubes and attempts < max_attempts:
		attempts += 1
		
		var x = randi_range(0, grid_bounds.x - 1)
		var z = randi_range(0, grid_bounds.z - 1)
		var y = _find_highest_y_at(x, z)
		
		var pos = Vector3i(x, y, z)
		
		# Check if position is valid and not already used
		if _is_valid_position(pos) and not positions.has(pos):
			positions.append(pos)
	
	return positions

func _generate_grid_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var grid_size = int(ceil(sqrt(number_of_cubes)))
	var spacing = max(1, grid_bounds.x / (grid_size + 1))
	
	var placed = 0
	for i in range(grid_size):
		for j in range(grid_size):
			if placed >= number_of_cubes:
				break
			
			var x = int((i + 1) * spacing)
			var z = int((j + 1) * spacing)
			
			if x < grid_bounds.x and z < grid_bounds.z:
				var y = _find_highest_y_at(x, z)
				var pos = Vector3i(x, y, z)
				
				if _is_valid_position(pos):
					positions.append(pos)
					placed += 1
	
	return positions

func _generate_circle_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var center_x = grid_bounds.x / 2
	var center_z = grid_bounds.z / 2
	var radius = min(grid_bounds.x, grid_bounds.z) / 3
	
	for i in range(number_of_cubes):
		var angle = (float(i) / number_of_cubes) * TAU
		var x = int(center_x + cos(angle) * radius)
		var z = int(center_z + sin(angle) * radius)
		
		# Clamp to bounds
		x = clamp(x, 0, grid_bounds.x - 1)
		z = clamp(z, 0, grid_bounds.z - 1)
		
		var y = _find_highest_y_at(x, z)
		var pos = Vector3i(x, y, z)
		
		if _is_valid_position(pos):
			positions.append(pos)
	
	return positions

func _generate_line_positions() -> Array[Vector3i]:
	var positions: Array[Vector3i] = []
	var start_x = 1
	var end_x = grid_bounds.x - 1
	var z = grid_bounds.z / 2
	
	for i in range(number_of_cubes):
		var progress = float(i) / max(1, number_of_cubes - 1)
		var x = int(lerp(start_x, end_x, progress))
		var y = _find_highest_y_at(x, z)
		var pos = Vector3i(x, y, z)
		
		if _is_valid_position(pos):
			positions.append(pos)
	
	return positions

func _find_highest_y_at(x: int, z: int) -> int:
	if grid_system and grid_system.get_structure_component():
		return grid_system.get_structure_component().find_highest_y_at(x, z)
	return 1  # Default height

func _is_valid_position(pos: Vector3i) -> bool:
	# Check bounds
	if pos.x < 0 or pos.x >= grid_bounds.x or pos.z < 0 or pos.z >= grid_bounds.z:
		return false
	
	# Check if we should avoid occupied spaces
	if avoid_occupied_spaces and grid_system:
		# Check for existing cubes, utilities, or interactables
		var structure_comp = grid_system.get_structure_component()
		var utilities_comp = grid_system.get_utilities_component()
		var interactables_comp = grid_system.get_interactables_component()
		
		if structure_comp and structure_comp.has_cube_at(pos.x, pos.y, pos.z):
			return false
		
		if utilities_comp and utilities_comp.has_utility_at(pos.x, pos.y, pos.z):
			return false
		
		if interactables_comp and interactables_comp.has_interactable_at(pos.x, pos.y, pos.z):
			return false
	
	return true

func _create_pickup_cube_at(x: int, y: int, z: int):
	# Load pickup cube scene
	var scene_resource = load(PICKUP_CUBE_SCENE) as PackedScene
	if not scene_resource:
		print("PickupCubePlacer: Could not load pickup cube scene")
		return
	
	# Instantiate the cube
	var pickup_cube = scene_resource.instantiate()
	pickup_cube.name = "PickupCube_%d_%d_%d" % [x, y, z]
	
	# Position it using grid system's coordinate system
	if grid_system:
		var structure_comp = grid_system.get_structure_component()
		var total_size = structure_comp.cube_size + structure_comp.gutter
		pickup_cube.position = Vector3(x, y, z) * total_size
	else:
		pickup_cube.position = Vector3(x, y, z)
	
	# Add to scene
	grid_system.add_child(pickup_cube)
	pickup_cubes.append(pickup_cube)
	
	print("PickupCubePlacer: Created pickup cube at (%d,%d,%d)" % [x, y, z])

# Public API
func set_placement_pattern(pattern: String):
	placement_pattern = pattern
	print("PickupCubePlacer: Pattern set to '%s'" % pattern)

func set_number_of_cubes(count: int):
	number_of_cubes = max(1, count)
	print("PickupCubePlacer: Number of cubes set to %d" % number_of_cubes)

func clear_pickup_cubes():
	for cube in pickup_cubes:
		if is_instance_valid(cube):
			cube.queue_free()
	pickup_cubes.clear()
	print("PickupCubePlacer: Cleared all pickup cubes")

func respawn_pickup_cubes():
	clear_pickup_cubes()
	await get_tree().process_frame
	place_pickup_cubes()

# Get info about placed cubes
func get_pickup_info() -> Dictionary:
	return {
		"total_cubes": pickup_cubes.size(),
		"pattern": placement_pattern,
		"grid_bounds": grid_bounds,
		"positions": pickup_cubes.map(func(cube): return cube.position)
	}
