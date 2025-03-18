# GridUtilityHandler.gd
extends RefCounted

# Reference to the grid system
var grid_system = null

# Utility data
var utility_data_instance = null
var utility_objects = {}

# Initialize with reference to grid system
func _init(parent_grid_system):
	grid_system = parent_grid_system

# Load utility data for a specific map
func load_data(map_name: String) -> void:
	#print("GridUtilityHandler: Loading utility data for map: %s" % map_name)
	
	utility_data_instance = null
	
	# Load utility data script
	var utility_path = GridCommon.MAPS_PATH + map_name + "/utility_data.gd"
	if ResourceLoader.exists(utility_path):
		var utility_data_script = load(utility_path)
		if utility_data_script:
			utility_data_instance = utility_data_script.new()
			#print("GridUtilityHandler: Loaded utility data script: %s" % utility_path)
		else:
			push_error("GridUtilityHandler: Failed to load utility data script: %s" % utility_path)
	else:
		push_error("GridUtilityHandler: Utility data script not found: %s" % utility_path)

# Clear all utility objects
func clear() -> void:
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()
	
	utility_objects.clear()

# Apply utility data to the grid
func apply_data() -> void:
	# Skip if utility data instance isn't created
	if not utility_data_instance:
		print("WARNING: GridUtilityHandler: Cannot apply utility data, instance not created!")
		return
		
	#print("GridUtilityHandler: Applying utility data")
	var utility_layout = utility_data_instance.layout_data
	var total_size = grid_system.cube_size + grid_system.gutter
	var utility_count = 0
	
	for z in range(min(grid_system.grid_z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(grid_system.grid_x, row.size())):
			var utility_info = row[x].strip_edges()
			
			# Skip empty cells
			if utility_info == "" or utility_info == " ":
				continue
				
			# Parse utility info: can be just a type or type:id
			var utility_type = utility_info[0]  # First character is the type
			var teleport_id = ""
			
			# Check if the utility info includes a teleport ID
			if utility_type == "t" and ":" in utility_info:
				var parts = utility_info.split(":")
				if parts.size() > 1:
					teleport_id = parts[1]
			
			# If it's a recognized utility type, place it
			if utility_type in GridCommon.UTILITY_TYPES.keys() and utility_type != " ":
				# Find the highest occupied y position at this x,z coordinate
				var y_pos = 0
				for y in range(grid_system.grid_y-1, -1, -1):
					if grid_system.grid[x][y][z]:
						y_pos = y + 1  # Place utility on top of the highest cube
						break
				
				_place_utility(x, y_pos, z, utility_type, teleport_id, total_size)
				utility_count += 1
	
	#print("GridUtilityHandler: Added %d utility objects to the grid" % utility_count)

# Place a utility in the grid
func _place_utility(x: int, y: int, z: int, utility_type: String, teleport_id: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var utility_object = null
	
	# Skip if utility type is not recognized
	if not GridCommon.UTILITY_TYPES.has(utility_type) or utility_type == " ":
		return
		
	# Get scene file name for this utility type
	var scene_file = GridCommon.UTILITY_TYPES[utility_type].file
	
	# Load the scene
	var scene_resource = grid_system.load_scene(scene_file)
	if scene_resource:
		utility_object = scene_resource.instantiate()
	else:
		print("WARNING: GridUtilityHandler: Could not load scene for utility type '%s'" % utility_type)
		return
	
	if utility_object:
		utility_object.position = position
		
		# For teleport objects, set the destination scene
		if utility_type == "t" and not grid_system.scene.is_empty():
			utility_object.scene = grid_system.scene
			#print("GridUtilityHandler: Set teleport scene: %s" % grid_system.scene)
			
		grid_system.add_child(utility_object)
		
		# Set owner for editor
		if grid_system.get_tree() and grid_system.get_tree().edited_scene_root:
			utility_object.owner = grid_system.get_tree().edited_scene_root
			
		utility_objects[Vector3i(x, y, z)] = utility_object
		#print("GridUtilityHandler: Added utility object of type '%s' at position (%d, %d, %d)" % [utility_type, x, y, z])
	else:
		print("WARNING: GridUtilityHandler: Failed to instantiate utility type '%s'" % utility_type)

# Get a utility object at a specific position
func get_utility_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	if utility_objects.has(key):
		return utility_objects[key]
	return null

# Remove a utility object at a specific position
func remove_utility_at(x: int, y: int, z: int) -> void:
	var key = Vector3i(x, y, z)
	if utility_objects.has(key):
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()
		utility_objects.erase(key)

# Check if a position has a utility object
func has_utility_at(x: int, y: int, z: int) -> bool:
	return utility_objects.has(Vector3i(x, y, z))

# Get all utility objects of a specific type
func get_utilities_by_type(type: String) -> Array:
	var result = []
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		# Note: This assumes utility objects have a get_type() method or similar
		# If they don't, you may need to store the type along with the object
		if utility and utility.has_method("get_type") and utility.get_type() == type:
			result.append(utility)
	return result
