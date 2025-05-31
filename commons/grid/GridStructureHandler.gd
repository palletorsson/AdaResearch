# GridStructureHandler.gd
extends RefCounted

# Reference to the grid system
var grid_system = null

# Structure data
var structure_data_instance = null
var cube_map = {}

# Initialize with reference to grid system
func _init(parent_grid_system):
	grid_system = parent_grid_system

# Load structure data for a specific map
func load_data(map_name: String) -> void:
	print("GridStructureHandler: Loading structure data for map: %s" % map_name)
	
	structure_data_instance = null
	
	# Load structure data script
	var struct_path = GridCommon.MAPS_PATH + map_name + "/struct_data.gd"
	var fallback_used = false
	
	if ResourceLoader.exists(struct_path):
		var structure_data_script = load(struct_path)
		if structure_data_script:
			structure_data_instance = structure_data_script.new()
			print("GridStructureHandler: Loaded structure data script: %s" % struct_path)
		else:
			push_error("GridStructureHandler: Failed to load structure data script: %s" % struct_path)
			fallback_used = true
	else:
		print("GridStructureHandler: Structure data script not found: %s - trying default" % struct_path)
		fallback_used = true
	
	# Try default map if original failed
	if fallback_used and map_name != "default":
		var default_path = GridCommon.MAPS_PATH + "default/struct_data.gd"
		if ResourceLoader.exists(default_path):
			var default_script = load(default_path)
			if default_script:
				structure_data_instance = default_script.new()
				print("GridStructureHandler: Using default structure data as fallback")
			else:
				push_error("GridStructureHandler: Failed to load default structure data script")
		else:
			push_error("GridStructureHandler: Default structure data script not found: %s" % default_path)

# Clear all cubes
func clear() -> void:
	for key in cube_map.keys():
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
	
	cube_map.clear()

# Apply structure data to the grid
func apply_data() -> void:
	# Skip if structure data instance isn't created
	if not structure_data_instance:
		push_error("GridStructureHandler: Cannot apply structure data, instance not created!")
		return
		
	print("GridStructureHandler: Applying structure data")
	var structure_layout = structure_data_instance.layout_data
	var total_size = grid_system.cube_size + grid_system.gutter
	var cube_count = 0
	
	for z in grid_system.grid_z:
		var row = structure_layout[z]
		for x in grid_system.grid_x:
			var cell_value = row[x].strip_edges()
			var stack_height = 0
			
			# Try to parse the cell value as a number
			if cell_value.is_valid_int():
				stack_height = int(cell_value)
			
			# Create stacked cubes based on the height value
			for y in range(0, min(stack_height, grid_system.grid_y)):
				add_cube(x, y, z, total_size)
				#await grid_system.get_tree().create_timer(0.005).timeout
				grid_system.grid[x][y][z] = true
				cube_count += 1
	
	print("GridStructureHandler: Added %d cubes to the grid" % cube_count)

# Add a cube to the grid
func add_cube(x: int, y: int, z: int, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var new_cube = grid_system.base_cube.duplicate()
	new_cube.position = position
	new_cube.visible = true
	grid_system.add_child(new_cube)
	
	# Set owner for editor
	if grid_system.get_tree() and grid_system.get_tree().edited_scene_root:
		new_cube.owner = grid_system.get_tree().edited_scene_root
		
	cube_map[Vector3i(x, y, z)] = new_cube

# Fixed get_grid_dimensions function in GridStructureHandler.gd

# Get grid dimensions from structure data
func get_grid_dimensions() -> Vector3i:
	if not structure_data_instance:
		push_error("GridStructureHandler: Cannot get dimensions, structure data instance not created!")
		return Vector3i.ZERO

	var structure_layout = structure_data_instance.layout_data
	var z_size = structure_layout.size()
	var x_size = structure_layout[0].size() if structure_layout.size() > 0 else 0

	# Return all three grid dimensions
	return Vector3i(x_size, grid_system.grid_y, z_size)

# Get a cube at a specific position
func get_cube_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	if cube_map.has(key):
		return cube_map[key]
	return null

# Remove a cube at a specific position
func remove_cube_at(x: int, y: int, z: int) -> void:
	var key = Vector3i(x, y, z)
	if cube_map.has(key):
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
		cube_map.erase(key)
		
		# Also update the grid
		if GridCommon.is_position_in_bounds(x, y, z, grid_system.grid_x, grid_system.grid_y, grid_system.grid_z):
			grid_system.grid[x][y][z] = false

# Check if a position has a cube
func has_cube_at(x: int, y: int, z: int) -> bool:
	return cube_map.has(Vector3i(x, y, z))

# Get the highest y position at a specific x,z coordinate
func get_highest_y_at(x: int, z: int) -> int:
	for y in range(grid_system.grid_y-1, -1, -1):
		if has_cube_at(x, y, z):
			return y
	return -1
