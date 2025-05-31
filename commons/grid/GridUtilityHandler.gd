# GridUtilityHandler.gd
extends RefCounted
class_name GridUtilityHandler

# Reference to the main grid system
var grid_system: Node3D
var utility_objects: Dictionary = {}

# Data instance
var utility_data_instance

func _init(grid_sys: Node3D):
	grid_system = grid_sys

# Load utility data for the current map
func load_data(map_name: String) -> bool:
	var utility_data_path = GridCommon.MAPS_PATH + map_name + "/utility_data.gd"
	
	# Check if utility data file exists
	if not FileAccess.file_exists(utility_data_path):
		print("WARNING: GridUtilityHandler: Utility data file not found: %s" % utility_data_path)
		return false
	
	# Load and instantiate the utility data script
	var utility_data_script = load(utility_data_path)
	if utility_data_script:
		utility_data_instance = utility_data_script.new()
		print("GridUtilityHandler: Loaded utility data for map '%s'" % map_name)
		
		# Validate the utility data
		var validation = UtilityRegistry.validate_utility_grid(utility_data_instance.layout_data)
		if not validation.valid:
			print("WARNING: GridUtilityHandler: Utility data validation failed for map '%s':" % map_name)
			for error in validation.errors:
				print("  ERROR: %s" % error)
			for warning in validation.warnings:
				print("  WARNING: %s" % warning)
			if validation.unknown_types.size() > 0:
				print("  Unknown utility types found: %s" % str(validation.unknown_types))
		
		return true
	else:
		print("ERROR: GridUtilityHandler: Failed to load utility data script: %s" % utility_data_path)
		return false

# Apply utility data to the grid
func apply_data() -> void:
	# Skip if utility data instance isn't created
	if not utility_data_instance:
		print("WARNING: GridUtilityHandler: Cannot apply utility data, instance not created!")
		return
		
	print("GridUtilityHandler: Applying utility data...")
	var utility_layout = utility_data_instance.layout_data
	var total_size = grid_system.cube_size + grid_system.gutter
	var utility_count = 0
	
	for z in range(min(grid_system.grid_z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(grid_system.grid_x, row.size())):
			var utility_info = str(row[x]).strip_edges()
			
			# Skip empty cells
			if utility_info.is_empty() or utility_info == " ":
				continue
			
			# Parse utility cell (handles parameters)
			var parsed = UtilityRegistry.parse_utility_cell(utility_info)
			var utility_type = parsed.type
			var parameters = parsed.parameters
			
			# Skip if not a valid utility type
			if not UtilityRegistry.is_valid_utility_type(utility_type) or utility_type == " ":
				continue
			
			# Find the highest occupied y position at this x,z coordinate
			var y_pos = 0
			for y in range(grid_system.grid_y-1, -1, -1):
				if grid_system.grid[x][y][z]:
					y_pos = y + 1  # Place utility on top of the highest cube
					break
			
			_place_utility(x, y_pos, z, utility_type, parameters, total_size)
			utility_count += 1
	
	print("GridUtilityHandler: Added %d utility objects to the grid" % utility_count)

# Place a utility in the grid with enhanced parameter support
func _place_utility(x: int, y: int, z: int, utility_type: String, parameters: Array, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var utility_object = null
	
	# Skip if utility type is not recognized
	if not UtilityRegistry.is_valid_utility_type(utility_type) or utility_type == " ":
		print("WARNING: GridUtilityHandler: Invalid utility type '%s'" % utility_type)
		return
	
	# Get scene file path from registry
	var scene_path = UtilityRegistry.get_utility_scene_path(utility_type)
	if scene_path.is_empty():
		print("WARNING: GridUtilityHandler: No scene file for utility type '%s'" % utility_type)
		return
	
	# Load the scene
	var scene_resource = grid_system.load_scene(UtilityRegistry.get_utility_info(utility_type).file)
	if scene_resource:
		utility_object = scene_resource.instantiate()
	else:
		print("WARNING: GridUtilityHandler: Could not load scene for utility type '%s'" % utility_type)
		return
	
	if utility_object:
		utility_object.position = position
		
		# Apply parameters based on utility type
		_apply_utility_parameters(utility_object, utility_type, parameters)
		
		grid_system.add_child(utility_object)
		
		# Set owner for editor
		if grid_system.get_tree() and grid_system.get_tree().edited_scene_root:
			utility_object.owner = grid_system.get_tree().edited_scene_root
			
		utility_objects[Vector3i(x, y, z)] = utility_object
		
		var param_info = " with parameters %s" % str(parameters) if parameters.size() > 0 else ""
		print("GridUtilityHandler: Added %s (%s) at (%d, %d, %d)%s" % [
			UtilityRegistry.get_utility_name(utility_type), 
			utility_type, 
			x, y, z, 
			param_info
		])
	else:
		print("WARNING: GridUtilityHandler: Failed to instantiate utility type '%s'" % utility_type)

# Apply parameters to utility objects based on their type
func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array) -> void:
	if parameters.is_empty():
		return
	
	match utility_type:
		"t":  # Teleport
			_apply_teleport_parameters(utility_object, parameters)
		"l":  # Platform lift
			_apply_lift_parameters(utility_object, parameters)
		"a":  # Wall
			_apply_wall_parameters(utility_object, parameters)
		"arrow":  # Exit arrow
			_apply_arrow_parameters(utility_object, parameters)
		_:
			if UtilityRegistry.supports_parameters(utility_type):
				print("INFO: GridUtilityHandler: Utility type '%s' supports parameters but no handler implemented" % utility_type)

# Apply teleport-specific parameters
func _apply_teleport_parameters(teleport: Node3D, parameters: Array) -> void:
	if parameters.size() > 0 and not grid_system.scene.is_empty():
		teleport.scene = grid_system.scene
	
	# Additional teleport parameters could include:
	# - spawn point name/position
	# - transition effect
	# - activation conditions

# Apply lift-specific parameters  
func _apply_lift_parameters(lift: Node3D, parameters: Array) -> void:
	# Parameters could include: height, speed, delay
	if parameters.size() > 0:
		var height = parameters[0].to_float()
		if height > 0 and lift.has_property("lift_height"):
			lift.lift_height = height
	
	if parameters.size() > 1:
		var speed = parameters[1].to_float()
		if speed > 0 and lift.has_property("lift_speed"):
			lift.lift_speed = speed

# Apply wall-specific parameters
func _apply_wall_parameters(wall: Node3D, parameters: Array) -> void:
	# Parameters could include: material, transparency, breakable
	if parameters.size() > 0:
		var material_type = parameters[0]
		# Apply material based on type (glass, stone, metal, etc.)
	
	if parameters.size() > 1:
		var transparency = parameters[1].to_float()
		# Apply transparency if supported

# Apply arrow-specific parameters
func _apply_arrow_parameters(arrow: Node3D, parameters: Array) -> void:
	# Parameters could include: direction, destination
	if parameters.size() > 0:
		var direction = parameters[0]
		# Set arrow direction (up, down, left, right, etc.)
	
	if parameters.size() > 1:
		var destination = parameters[1]
		# Set destination for navigation

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

# Get all utility objects by category
func get_utilities_by_category(category: String) -> Array:
	var result = []
	var utilities_in_category = UtilityRegistry.get_utilities_by_category(category)
	
	for utility_info in utilities_in_category:
		var type_code = utility_info.code
		var type_utilities = get_utilities_by_type(type_code)
		result.append_array(type_utilities)
	
	return result

# Clear all utility objects
func clear_utilities() -> void:
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()
	utility_objects.clear()

# Clear method for compatibility with other handlers
func clear() -> void:
	clear_utilities()

# Generate utility summary report
func generate_utility_report() -> Dictionary:
	var report = {
		"total_utilities": utility_objects.size(),
		"by_category": {},
		"by_type": {},
		"positions": []
	}
	
	# Count utilities by type and category
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if utility and utility.has_method("get_type"):
			var type_code = utility.get_type()
			var category = UtilityRegistry.get_utility_category(type_code)
			
			# Count by type
			if not report.by_type.has(type_code):
				report.by_type[type_code] = 0
			report.by_type[type_code] += 1
			
			# Count by category
			if not report.by_category.has(category):
				report.by_category[category] = 0
			report.by_category[category] += 1
			
			# Add position info
			report.positions.append({
				"position": key,
				"type": type_code,
				"name": UtilityRegistry.get_utility_name(type_code),
				"category": category
			})
	
	return report
