# GridStructureComponent.gd
# Handles cube placement and grid structure building
# Creates the physical 3D layout from structure data

extends Node
class_name GridStructureComponent

# Grid properties
var grid_x: int
var grid_y: int  
var grid_z: int
var grid: Array = []
var cube_map: Dictionary = {}

# References
var base_cube: Node3D
var parent_node: Node3D

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Signals
signal structure_generation_complete(cube_count: int)

func _ready():
	print("GridStructureComponent: Initialized")

# Initialize with references and settings
func initialize(grid_parent: Node3D, cube_template: Node3D, settings: Dictionary = {}):
	parent_node = grid_parent
	base_cube = cube_template
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	print("GridStructureComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Generate structure from data
func generate_structure(structure_data, dimensions: Vector3i):
	if not structure_data:
		print("GridStructureComponent: No structure data provided")
		return
		
	# Set dimensions
	grid_x = dimensions.x
	grid_y = dimensions.y
	grid_z = dimensions.z
	
	print("GridStructureComponent: Generating structure %dx%dx%d" % [grid_x, grid_y, grid_z])
	
	# Initialize grid
	_initialize_grid()
	
	# Apply structure data
	_apply_structure_data(structure_data)

# Initialize the 3D grid array
func _initialize_grid():
	print("GridStructureComponent: Initializing grid array")
	grid = []
	cube_map.clear()
	
	# Pre-allocate grid
	grid.resize(grid_x)
	for x in grid_x:
		var y_array = []
		y_array.resize(grid_y)
		grid[x] = y_array
		
		for y in grid_y:
			var z_array = []
			z_array.resize(grid_z)
			grid[x][y] = z_array
			
			for z in grid_z:
				grid[x][y][z] = false

# Apply structure data to create cubes
func _apply_structure_data(structure_data):
	if not structure_data.layout_data:
		print("GridStructureComponent: No layout_data in structure")
		return
		
	var structure_layout = structure_data.layout_data
	var total_size = cube_size + gutter
	var cube_count = 0
	
	for z in grid_z:
		if z >= structure_layout.size():
			break
			
		var row = structure_layout[z]
		for x in grid_x:
			if x >= row.size():
				break
				
			var cell_value = str(row[x]).strip_edges()
			var stack_height = 0
			
			if cell_value.is_valid_int():
				stack_height = int(cell_value)
			
			# Create stacked cubes
			for y in range(0, min(stack_height, grid_y)):
				_add_cube(x, y, z, total_size)
				grid[x][y][z] = true
				cube_count += 1
	
	print("GridStructureComponent: Added %d cubes" % cube_count)
	structure_generation_complete.emit(cube_count)

# Add a single cube to the grid
func _add_cube(x: int, y: int, z: int, total_size: float):
	if not base_cube or not parent_node:
		print("GridStructureComponent: Missing base_cube or parent_node")
		return
		
	var position = Vector3(x, y, z) * total_size
	var new_cube = base_cube.duplicate()
	new_cube.position = position
	new_cube.visible = true
	parent_node.add_child(new_cube)
	
	# Set owner for editor
	if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
		new_cube.owner = parent_node.get_tree().edited_scene_root
	
	cube_map[Vector3i(x, y, z)] = new_cube

# Find highest Y position at X,Z coordinate
func find_highest_y_at(x: int, z: int) -> int:
	if not _is_valid_xz(x, z):
		return 0
		
	for y in range(grid_y-1, -1, -1):
		if grid[x][y][z]:
			return y + 1
	return 0

# Check if position has a cube
func has_cube_at(x: int, y: int, z: int) -> bool:
	if not _is_valid_xyz(x, y, z):
		return false
	return grid[x][y][z]

# Get cube at position
func get_cube_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return cube_map.get(key, null)

# Clear all cubes
func clear_structure():
	print("GridStructureComponent: Clearing all cubes")
	
	for key in cube_map.keys():
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
	
	cube_map.clear()
	grid.clear()

# Validation helpers
func _is_valid_xyz(x: int, y: int, z: int) -> bool:
	return x >= 0 and x < grid_x and y >= 0 and y < grid_y and z >= 0 and z < grid_z

func _is_valid_xz(x: int, z: int) -> bool:
	return x >= 0 and x < grid_x and z >= 0 and z < grid_z

# Get grid dimensions
func get_grid_dimensions() -> Vector3i:
	return Vector3i(grid_x, grid_y, grid_z)

# Get cube count
func get_cube_count() -> int:
	return cube_map.size()

# Get all cube positions
func get_all_cube_positions() -> Array:
	return cube_map.keys()
