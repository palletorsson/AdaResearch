# GridUtilitiesComponent.gd  
# Handles utility object placement (teleports, lifts, doors, etc.)
# Uses UtilityRegistry for type definitions and validation

extends Node
class_name GridUtilitiesComponent

# Path constants - CORRECTED TO MATCH ACTUAL PROJECT STRUCTURE
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"

# References
var parent_node: Node3D
var structure_component: GridStructureComponent

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0

# Utility objects tracking
var utility_objects: Dictionary = {}
var scene_cache: Dictionary = {}

# Signals
signal utility_generation_complete(utility_count: int)
signal utility_activated(utility_type: String, position: Vector3, data: Dictionary)

func _ready():
	print("GridUtilitiesComponent: Initialized")

# Initialize with references and settings
func initialize(grid_parent: Node3D, struct_component: GridStructureComponent, settings: Dictionary = {}):
	parent_node = grid_parent
	structure_component = struct_component
	
	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	
	print("GridUtilitiesComponent: Initialized with cube_size=%f, gutter=%f" % [cube_size, gutter])

# Generate utilities from data
func generate_utilities(utility_data, utility_definitions: Dictionary = {}):
	if not utility_data:
		print("GridUtilitiesComponent: No utility data provided")
		return
		
	if not utility_data.layout_data:
		print("GridUtilitiesComponent: No layout_data in utility data")
		return
		
	print("GridUtilitiesComponent: Generating utilities")
	
	var utility_layout = utility_data.layout_data
	var total_size = cube_size + gutter
	var utility_count = 0
	
	# Get grid dimensions from structure component
	var dimensions = structure_component.get_grid_dimensions()
	
	# Validate utilities using UtilityRegistry
	var validation = UtilityRegistry.validate_utility_grid(utility_layout)
	if not validation.valid:
		print("GridUtilitiesComponent: WARNING - Utility validation issues:")
		for error in validation.errors:
			print("  ERROR: %s" % error)
		for warning in validation.warnings:
			print("  WARNING: %s" % warning)
	
	# Place utilities
	for z in range(min(dimensions.z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(dimensions.x, row.size())):
			var utility_cell = str(row[x]).strip_edges()
			
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			
			# Parse utility cell with parameters
			var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
			var utility_type = parsed.type
			var parameters = parsed.parameters
			
			if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
				var y_pos = structure_component.find_highest_y_at(x, z)
				
				# Get utility definition if available
				var utility_definition = utility_definitions.get(utility_type, {})
				
				# Ensure utility_definition is always a Dictionary (handle string references)
				if typeof(utility_definition) != TYPE_DICTIONARY:
					print("GridUtilitiesComponent: Note - Using external utility reference for '%s': %s" % [utility_type, str(utility_definition)])
					utility_definition = {}
				
				_place_utility(x, y_pos, z, utility_type, parameters, utility_definition, total_size)
				utility_count += 1
	
	print("GridUtilitiesComponent: Added %d utilities" % utility_count)
	utility_generation_complete.emit(utility_count)

# Place a single utility object
func _place_utility(x: int, y: int, z: int, utility_type: String, parameters: Array, definition: Dictionary, total_size: float):
	var position = Vector3(x, y, z) * total_size
	
	var scene_path = UtilityRegistry.get_utility_scene_path(utility_type)
	if scene_path.is_empty():
		print("GridUtilitiesComponent: WARNING - No scene file for utility type '%s'" % utility_type)
		return
	
	var scene_resource = _load_scene_cached(UtilityRegistry.get_utility_info(utility_type).file)
	if not scene_resource:
		print("GridUtilitiesComponent: WARNING - Could not load scene for utility type '%s'" % utility_type)
		return
	
	var utility_object = scene_resource.instantiate()
	if utility_object:
		utility_object.position = position
		
		# Apply parameters if supported
		print("GridUtilitiesComponent: Utility type '%s' has %d parameters: %s" % [utility_type, parameters.size(), str(parameters)])
		if parameters.size() > 0 and UtilityRegistry.supports_parameters(utility_type):
			print("GridUtilitiesComponent: Applying parameters for utility type '%s'" % utility_type)
			_apply_utility_parameters(utility_object, utility_type, parameters)
		else:
			print("GridUtilitiesComponent: No parameters to apply for utility type '%s' (supports: %s)" % [utility_type, UtilityRegistry.supports_parameters(utility_type)])
		
		# Apply definition properties
		_apply_utility_definition(utility_object, utility_type, definition)
		
		# Connect signals if utility has them
		_connect_utility_signals(utility_object, utility_type)
		
		parent_node.add_child(utility_object)
		
		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			utility_object.owner = parent_node.get_tree().edited_scene_root
		
		utility_objects[Vector3i(x, y, z)] = utility_object
		
		var param_info = ""
		if parameters.size() > 0:
			param_info = " (params: %s)" % str(parameters)
		print("  Added %s at (%d,%d,%d)%s" % [UtilityRegistry.get_utility_name(utility_type), x, y, z, param_info])

# Apply utility parameters

# Add this to GridUtilitiesComponent.gd in the _apply_utility_parameters method

func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array):
	match utility_type:
		"t":  # Teleport
			if parameters.size() > 0:
				var destination = parameters[0]
				if "destination" in utility_object:
					utility_object.destination = destination
				else:
					utility_object.set_meta("destination", destination)
				print("GridUtilitiesComponent: Set teleporter destination to: %s" % destination)
		"l":  # Lift
			if parameters.size() > 0 and "height" in utility_object:
				utility_object.height = float(parameters[0])
		"s":  # Spawn point
			if parameters.size() > 0:
				utility_object.set_meta("spawn_name", parameters[0])
		"wp":  # Walkable prism
			if parameters.size() > 0:
				var rotation_y = float(parameters[0])
				utility_object.rotation_degrees.y = rotation_y
				print("GridUtilitiesComponent: Set walkable prism rotation to: %f degrees" % rotation_y)
			if parameters.size() > 1:
				var color_param = parameters[1]
				_apply_color_to_utility(utility_object, color_param)
				print("GridUtilitiesComponent: Applied color '%s' to walkable prism" % color_param)
		"an":  # Annotation/Info Board
			print("GridUtilitiesComponent: Info board will load map data automatically")
		"tc":  # Transport Cube
			if parameters.size() >= 2:
				var distance = float(parameters[0])
				var direction_param = parameters[1]
				var direction = Vector3(1, 0, 0)
				match direction_param.to_lower():
					"x":
						direction = Vector3(1, 0, 0)
					"y":
						direction = Vector3(0, 1, 0)
					"z":
						direction = Vector3(0, 0, 1)
					"-x":
						direction = Vector3(-1, 0, 0)
					"-y":
						direction = Vector3(0, -1, 0)
					"-z":
						direction = Vector3(0, 0, -1)
					_:
						var coords = direction_param.split(",")
						if coords.size() >= 3:
							direction = Vector3(
								coords[0].to_float(),
								coords[1].to_float(),
								coords[2].to_float()
							)
				if "set_transport_parameters" in utility_object:
					utility_object.set_transport_parameters(distance, direction)
				print("GridUtilitiesComponent: Set transport cube to move %.1f units in direction %s" % [distance, direction])
		"rg":  # Regenerate cube
			var target_params: Array = []
			var status_message := ""
			for param in parameters:
				var value := str(param).strip_edges()
				if value.is_empty():
					continue
				if value.begins_with("msg="):
					status_message = value.substr(4, value.length() - 4)
				else:
					target_params.append(value)
			if utility_object.has_method("set_targets_from_parameters"):
				utility_object.set_targets_from_parameters(target_params)
			elif utility_object.has_method("set_target_data"):
				utility_object.set_target_data([], target_params)
			if status_message.length() > 0 and utility_object.has_method("set_status_message"):
				utility_object.set_status_message(status_message)
# Apply color to utility object (works with materials and shaders)
func _apply_color_to_utility(utility_object: Node3D, color_param: String):
	var color = _parse_color_parameter(color_param)
	if color == Color.WHITE:
		print("GridUtilitiesComponent: Warning - Could not parse color '%s', using white" % color_param)
	
	# Find the mesh instance in the utility object
	var mesh_instance = _find_mesh_instance_in_utility(utility_object)
	if not mesh_instance:
		print("GridUtilitiesComponent: Warning - No MeshInstance3D found in utility object")
		return
	
	# Apply color based on material type
	var material = mesh_instance.material_override
	if material is ShaderMaterial:
		_apply_color_to_shader_material(material as ShaderMaterial, color)
	elif material is StandardMaterial3D:
		_apply_color_to_standard_material(material as StandardMaterial3D, color)
	else:
		# Create new standard material if none exists
		var new_material = StandardMaterial3D.new()
		_apply_color_to_standard_material(new_material, color)
		mesh_instance.material_override = new_material

# Parse color parameter string to Color object
func _parse_color_parameter(color_param: String) -> Color:
	match color_param.to_lower():
		"red": return Color.RED
		"green": return Color.GREEN
		"blue": return Color.BLUE
		"yellow": return Color.YELLOW
		"cyan": return Color.CYAN
		"magenta": return Color.MAGENTA
		"orange": return Color.ORANGE
		"purple": return Color.PURPLE
		"pink": return Color.PINK
		"white": return Color.WHITE
		"black": return Color.BLACK
		"gray", "grey": return Color.GRAY
		"lime": return Color(0.5, 1.0, 0.0, 1.0)
		"navy": return Color(0.0, 0.0, 0.5, 1.0)
		"maroon": return Color(0.5, 0.0, 0.0, 1.0)
		"olive": return Color(0.5, 0.5, 0.0, 1.0)
		"aqua": return Color(0.0, 1.0, 1.0, 1.0)
		"silver": return Color(0.75, 0.75, 0.75, 1.0)
		_:
			# Try to parse as hex color (e.g., "ff0000" for red)
			if color_param.length() == 6:
				var hex_color = Color.html("#" + color_param)
				if hex_color != Color.BLACK or color_param == "000000":
					return hex_color
			# Try direct HTML color parsing
			var html_color = Color.html(color_param)
			if html_color != Color.BLACK or color_param.to_lower() == "black":
				return html_color
			return Color.WHITE  # Default fallback

# Apply color to shader material (like the walkable prism)
func _apply_color_to_shader_material(shader_material: ShaderMaterial, color: Color):
	# Check for common shader parameter names
	var shader_params = ["fill_color", "base_color", "albedo_color", "modelColor", "color"]
	
	for param_name in shader_params:
		if shader_material.shader and shader_material.shader.get_shader_params().has(param_name):
			shader_material.set_shader_parameter(param_name, color)
			print("GridUtilitiesComponent: Set shader parameter '%s' to %s" % [param_name, color])
			break
	
	# Also try to set wireframe color to a complementary color
	var wireframe_params = ["wireframe_color", "edge_color", "wireframeColor"]
	var wireframe_color = Color(1.0 - color.r, 1.0 - color.g, 1.0 - color.b, 1.0)  # Complementary color
	
	for param_name in wireframe_params:
		if shader_material.shader and shader_material.shader.get_shader_params().has(param_name):
			shader_material.set_shader_parameter(param_name, wireframe_color)
			print("GridUtilitiesComponent: Set wireframe parameter '%s' to %s" % [param_name, wireframe_color])
			break

# Apply color to standard material
func _apply_color_to_standard_material(standard_material: StandardMaterial3D, color: Color):
	standard_material.albedo_color = color
	# Add subtle emission for better visibility
	standard_material.emission_enabled = true
	standard_material.emission = color * 0.2
	print("GridUtilitiesComponent: Set standard material albedo to %s" % color)

# Find MeshInstance3D in utility object
func _find_mesh_instance_in_utility(utility_object: Node3D) -> MeshInstance3D:
	# Check if the object itself is a MeshInstance3D
	if utility_object is MeshInstance3D:
		return utility_object as MeshInstance3D
	
	# Search children recursively
	return _find_mesh_instance_recursive(utility_object)

func _find_mesh_instance_recursive(node: Node) -> MeshInstance3D:
	for child in node.get_children():
		if child is MeshInstance3D:
			return child as MeshInstance3D
		var found = _find_mesh_instance_recursive(child)
		if found:
			return found
	return null

# Apply utility definition properties from JSON
func _apply_utility_definition(utility_object: Node3D, utility_type: String, definition: Dictionary):
	if definition.is_empty():
		return
		
	var properties = definition.get("properties", {})
	
	# Apply visual effects for teleporters
	if utility_type == "t" and properties.has("visual_effect"):
		_apply_teleporter_visual_effect(utility_object, properties["visual_effect"])
	
	# Apply spawn point properties
	if utility_type == "s":
		_apply_spawn_point_properties(utility_object, properties)
	
	# Apply generic properties
	for property_name in properties.keys():
		var property_value = properties[property_name]
		if property_name in utility_object:
			utility_object.set(property_name, property_value)
		else:
			# Store as metadata if property doesn't exist
			utility_object.set_meta(property_name, property_value)

# Apply spawn point specific properties
func _apply_spawn_point_properties(spawn_point: Node3D, properties: Dictionary):
	# Set spawn point metadata
	if properties.has("spawn_name"):
		spawn_point.set_meta("spawn_name", properties["spawn_name"])
	
	if properties.has("priority"):
		spawn_point.set_meta("priority", int(properties["priority"]))
	
	if properties.has("height"):
		spawn_point.set_meta("height", float(properties["height"]))
	
	if properties.has("player_rotation"):
		spawn_point.set_meta("player_rotation", float(properties["player_rotation"]))
	
	# Apply visual settings
	if properties.has("visible_in_game"):
		var visible = bool(properties["visible_in_game"])
		_set_spawn_point_visibility(spawn_point, visible)

# Set spawn point visual components visibility
func _set_spawn_point_visibility(spawn_point: Node3D, visible: bool):
	var components = ["Platform", "Indicator", "Label3D"]
	for component_name in components:
		var component = spawn_point.get_node_or_null(component_name)
		if component:
			component.visible = visible

# Apply teleporter visual effects
func _apply_teleporter_visual_effect(teleporter: Node3D, effect: String):
	# This would depend on the teleporter scene structure
	match effect:
		"portal_glow":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(0.2, 0.6, 1.0)
		"warning":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(1.0, 0.5, 0.0)
		"exit":
			if "active_beam_color" in teleporter:
				teleporter.active_beam_color = Color(0.0, 1.0, 0.3)

# Connect utility signals
func _connect_utility_signals(utility_object: Node3D, utility_type: String):
	# Connect common utility signals
	if utility_object.has_signal("activated"):
		utility_object.activated.connect(_on_utility_activated.bind(utility_type, utility_object))
	
	if utility_object.has_signal("teleporter_activated"):
		utility_object.teleporter_activated.connect(_on_teleporter_activated.bind(utility_object))
		print("GridUtilitiesComponent: ✅ Connected teleporter_activated signal for %s" % utility_type)

# Handle general utility activation
func _on_utility_activated(utility_type: String, utility_object: Node3D):
	var utility_data = {
		"position": utility_object.global_position,
		"name": utility_object.name,
		"type": utility_type
	}
	
	# Add utility-specific data
	if "destination" in utility_object:
		utility_data["destination"] = utility_object.destination
	else:
		utility_data["destination"] = utility_object.get_meta("destination", "")
	
	# Add action property from metadata (crucial for teleporters!)
	if utility_object.has_meta("action"):
		utility_data["action"] = utility_object.get_meta("action")
		print("GridUtilitiesComponent: 🎯 Found action in metadata: %s" % utility_data["action"])
	
	utility_activated.emit(utility_type, utility_object.global_position, utility_data)

# Handle teleporter activation specifically - connect to SceneManager
func _on_teleporter_activated(utility_object: Node3D):
	print("GridUtilitiesComponent: 🚀 Teleporter activated - checking for custom handling")
	
	# Get destination and action from teleporter
	var destination = ""
	if "destination" in utility_object:
		destination = utility_object.destination
	else:
		destination = utility_object.get_meta("destination", "")
	
	var action = utility_object.get_meta("action", "")
	
	# First, try to let the parent GridSystem handle it (for lab-specific logic)
	if parent_node and parent_node.has_method("_on_utility_activated"):
		var utility_data = {
			"position": utility_object.global_position,
			"name": utility_object.name,
			"type": "t",
			"destination": destination,
			"action": action
		}
		
		print("GridUtilitiesComponent: Delegating to parent GridSystem for custom handling")
		print("GridUtilitiesComponent: Action: %s" % action)
		print("GridUtilitiesComponent: Destination: %s" % destination)
		parent_node._on_utility_activated("t", utility_object.global_position, utility_data)
		return
	
	# Fallback to default behavior
	print("GridUtilitiesComponent: Using default teleporter behavior")
	var scene_manager = _find_scene_manager()
	if scene_manager:
		scene_manager.request_transition({
			"type": 1,
			"action": "start_sequence" if _is_sequence_name(destination) else "load_map",
			"sequence": destination if _is_sequence_name(destination) else "",
			"destination": destination if not _is_sequence_name(destination) else "",
			"source": "teleporter",
			"position": utility_object.global_position
		})
# Find SceneManager in the scene tree
func _find_scene_manager():
	# Try common locations for SceneManager
	var potential_managers = [
		get_node_or_null("/root/SceneManager"),
		get_node_or_null("/root/AdaSceneManager"),
		get_tree().current_scene.find_child("SceneManager", true, false),
		get_tree().current_scene.find_child("AdaSceneManager", true, false)
	]
	
	for manager in potential_managers:
		if manager:
			print("GridUtilitiesComponent: Found SceneManager at: %s" % manager.get_path())
			return manager
	
	return null

func _is_sequence_name(name: String) -> bool:
	"""Check if the name is a sequence name rather than a map name"""
	var known_sequences = [
		"primitives",
		"transformation",
		"tests", 
		"color", 
		"array_tutorial",
		"meshestextures",
		"randomness_exploration",
		"wavefunctions",
		"noise",
		"forces",
		"proceduralaudio",
		"physicssimulation",
		"softbodies",
		"recursiveemergence",
		"lsystems",
		"swarmintelligence",
		"patterngeneration",
		"proceduralgeneration",
		"searchpathfinding",
		"graphtheory",
		"computationalgeometry",
		"machinelearning",
		"criticalalgorithms",
		"speculativecomputation",
		"resourcemanagement",
		"advancedlaboratory"
	]
	return name in known_sequences
	
# Debug: Print scene tree to help find SceneManager
func _debug_print_scene_tree():
	print("GridUtilitiesComponent: Scene tree structure:")
	_print_node_tree(get_tree().current_scene, 0)

func _print_node_tree(node: Node, depth: int):
	var indent = "  ".repeat(depth)
	print("%s%s (%s)" % [indent, node.name, node.get_class()])
	
	if depth < 3:  # Limit depth to avoid spam
		for child in node.get_children():
			_print_node_tree(child, depth + 1)

# Load scene with caching
func _load_scene_cached(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null
	
	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]
	
	var scene_path = MAP_OBJECTS_PATH + scene_filename
	print("GridUtilitiesComponent: Attempting to load scene: %s" % scene_path)
	
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		print("GridUtilitiesComponent: ✅ Successfully loaded scene: %s" % scene_filename)
		return scene
	else:
		print("GridUtilitiesComponent: ❌ ERROR - Scene file not found: %s" % scene_path)
		
		# Try to find what files actually exist
		_list_available_scenes()
		
		return null

# Debug: List available utility scenes
func _list_available_scenes():
	print("GridUtilitiesComponent: Listing available scenes in %s:" % MAP_OBJECTS_PATH)
	
	var dir = DirAccess.open(MAP_OBJECTS_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()
		
		while file_name != "":
			if file_name.ends_with(".tscn"):
				print("  → %s" % file_name)
			file_name = dir.get_next()
	else:
		print("GridUtilitiesComponent: Could not open scenes directory: %s" % MAP_OBJECTS_PATH)

# Get utility at position
func get_utility_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return utility_objects.get(key, null)

# Check if position has utility
func has_utility_at(x: int, y: int, z: int) -> bool:
	return utility_objects.has(Vector3i(x, y, z))

# Clear all utilities
func clear_utilities():
	print("GridUtilitiesComponent: Clearing all utilities")
	
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()
	
	utility_objects.clear()

# Get utility count
func get_utility_count() -> int:
	return utility_objects.size()

# Get all utility positions
func get_all_utility_positions() -> Array:
	return utility_objects.keys()
