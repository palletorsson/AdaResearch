# GridSystem.gd
# Enhanced grid system that supports JSON map format (now the main grid system)
# Unified interface for loading and managing map data from JSON files

extends Node3D
class_name GridSystem

# Configuration
@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var grid_y: int = 6  # Maximum height
@export var showgrid: bool = false

# Map selection
@export var map_name: String = "Tutorial_Start"
@export var reload_map: bool = false : set = reload_map_setter

# Path constants
const MAPS_PATH = "res://commons/maps/"
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"

# Grid properties
var grid_x: int
var grid_z: int
var grid: Array = []
var cube_map: Dictionary = {}
var utility_objects: Dictionary = {}
var interactable_objects: Dictionary = {}

# Enhanced utility handling
var use_enhanced_utility_handler: bool = true
var enhanced_utility_handler: EnhancedUtilityHandler

# Task registry for artifact lookup
var task_info_registry: Dictionary = {}

# Map loading system
var current_map_format: String = "json"
var json_loader: JsonMapLoader
var prefer_json_format: bool = true

# Data instances (unified interface)
var structure_data_instance
var utility_data_instance
var interactable_data_instance

# Components
@onready var base_cube = $CubeScene
@onready var algorithm_registry = AlgorithmRegistry.new()

# Scene cache
var scene_cache = {}
var rng = RandomNumberGenerator.new()

# Signals
signal map_loaded(map_name: String, format: String)
signal map_generation_complete()
signal interactable_activated(object_id, position, data)

func _ready():
	if not base_cube:
		print("ERROR: Base cube reference not found!")
		return
	
	rng.randomize()
	print("GridSystem: Initializing...")
	
	# Initialize enhanced utility handler if enabled
	if use_enhanced_utility_handler:
		enhanced_utility_handler = EnhancedUtilityHandler.new(self)
		add_child(enhanced_utility_handler)
		print("GridSystem: Enhanced utility handler initialized")
	
	# Add algorithm registry
	add_child(algorithm_registry)
	algorithm_registry.connect("registry_loaded", _on_algorithm_registry_loaded)
	
	# Load the JSON map
	_load_json_map()

func _load_json_map() -> void:
	var json_path = MAPS_PATH + map_name + "/map_data.json"
	
	if not JsonMapLoader.is_json_map_file(json_path):
		print("ERROR: No JSON map data found for '%s'" % map_name)
		return
	
	print("GridSystem: Loading JSON map from '%s'" % json_path)
	
	json_loader = JsonMapLoader.new()
	if json_loader.load_map(json_path):
		current_map_format = "json"
		
		# Extract instances from JSON loader
		structure_data_instance = json_loader.structure_data_instance
		utility_data_instance = json_loader.utility_data_instance
		interactable_data_instance = json_loader.interactable_data_instance
		
		# Apply JSON settings
		var settings = json_loader.get_settings()
		cube_size = settings.get("cube_size", cube_size)
		gutter = settings.get("gutter", gutter)
		showgrid = settings.get("show_grid", showgrid)
		
		# Set grid dimensions from JSON
		var dimensions = json_loader.get_dimensions()
		grid_x = dimensions.get("width", 0)
		grid_z = dimensions.get("depth", 0)
		grid_y = dimensions.get("max_height", grid_y)
		
		print("GridSystem: JSON map loaded successfully")
		print("  Dimensions: %dx%dx%d" % [grid_x, grid_z, grid_y])
		print("  Cube size: %f, Gutter: %f" % [cube_size, gutter])
		
		emit_signal("map_loaded", map_name, "json")
		
		# Generate report
		print("\n" + json_loader.generate_report())
		
		_finalize_map_loading()
	else:
		print("ERROR: Failed to load JSON map")

func _finalize_map_loading() -> void:
	# Wait for algorithm registry if needed
	if algorithm_registry.get_all_algorithm_ids().size() > 0:
		_on_algorithm_registry_loaded()
	else:
		# Registry is empty or not loaded yet, proceed anyway
		print("GridSystem: Algorithm registry empty, proceeding with grid generation...")
		_on_algorithm_registry_loaded()

func _on_algorithm_registry_loaded():
	print("GridSystem: Algorithm registry loaded, generating grid...")
	base_cube.visible = false
	_generate_grid()

func _generate_grid() -> void:
	print("GridSystem: Starting grid generation")
	_initialize_grid()
	_apply_structure_data()
	_apply_utility_data()
	_apply_interactable_data()
	
	print("GridSystem: Grid generation completed")
	emit_signal("map_generation_complete")

func _initialize_grid() -> void:
	print("GridSystem: Initializing grid: %dx%dx%d" % [grid_x, grid_y, grid_z])
	grid = []
	cube_map.clear()
	utility_objects.clear()
	interactable_objects.clear()
	
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

func _apply_structure_data() -> void:
	if not structure_data_instance:
		print("WARNING: No structure data to apply")
		return
	
	print("GridSystem: Applying structure data")
	var structure_layout = structure_data_instance.layout_data
	var total_size = cube_size + gutter
	var cube_count = 0
	
	for z in grid_z:
		var row = structure_layout[z]
		for x in grid_x:
			var cell_value = str(row[x]).strip_edges()
			var stack_height = 0
			
			if cell_value.is_valid_int():
				stack_height = int(cell_value)
			
			# Create stacked cubes
			for y in range(0, min(stack_height, grid_y)):
				_add_cube(x, y, z, total_size)
				grid[x][y][z] = true
				cube_count += 1
	
	print("GridSystem: Added %d cubes" % cube_count)

func _apply_utility_data() -> void:
	if not utility_data_instance:
		print("WARNING: No utility data to apply")
		return
	
	print("GridSystem: Applying utility data")
	var total_size = cube_size + gutter
	var utility_count = 0
	
	# Check if we're using JSON format with utility definitions and enhanced handler
	if current_map_format == "json" and use_enhanced_utility_handler and enhanced_utility_handler:
		print("GridSystem: Using enhanced utility handler for JSON format")
		
		# Get utility definitions from JSON data
		var utility_definitions = {}
		if json_loader and json_loader.map_data.has("utility_definitions"):
			utility_definitions = json_loader.map_data["utility_definitions"]
		
		var utility_layout = utility_data_instance.layout_data
		
		for z in range(min(grid_z, utility_layout.size())):
			var row = utility_layout[z]
			for x in range(min(grid_x, row.size())):
				var utility_cell = str(row[x]).strip_edges()
				
				if utility_cell.is_empty() or utility_cell == " ":
					continue
				
				# Parse utility cell with parameters
				var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
				var utility_type = parsed.type
				
				if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
					var y_pos = _find_highest_y_at(x, z)
					
					# Get utility definition if available
					var utility_definition = utility_definitions.get(utility_type, {})
					
					# Use enhanced handler to place utility
					enhanced_utility_handler.place_utility(x, y_pos, z, utility_type, utility_definition, total_size)
					utility_count += 1
		
		print("GridSystem: Added %d utilities via enhanced handler" % utility_count)
		return
	
	# Fallback to original utility placement for legacy format or when enhanced handler is disabled
	print("GridSystem: Using legacy utility placement")
	var utility_layout = utility_data_instance.layout_data
	
	# Validate utilities using UtilityRegistry
	var validation = UtilityRegistry.validate_utility_grid(utility_layout)
	if not validation.valid:
		print("WARNING: Utility validation issues found:")
		for error in validation.errors:
			print("  ERROR: %s" % error)
		for warning in validation.warnings:
			print("  WARNING: %s" % warning)
	
	for z in range(min(grid_z, utility_layout.size())):
		var row = utility_layout[z]
		for x in range(min(grid_x, row.size())):
			var utility_cell = str(row[x]).strip_edges()
			
			if utility_cell.is_empty() or utility_cell == " ":
				continue
			
			# Parse utility cell with parameters
			var parsed = UtilityRegistry.parse_utility_cell(utility_cell)
			var utility_type = parsed.type
			var parameters = parsed.parameters
			
			if UtilityRegistry.is_valid_utility_type(utility_type) and utility_type != " ":
				var y_pos = _find_highest_y_at(x, z)
				_place_utility(x, y_pos, z, utility_type, parameters, total_size)
				utility_count += 1
	
	print("GridSystem: Added %d utilities" % utility_count)

func _apply_interactable_data() -> void:
	if not interactable_data_instance:
		print("WARNING: No interactable data to apply")
		return
	
	print("GridSystem: Applying interactable data")
	
	# Check for different property names (layout_data vs interactable_data)
	var interactable_layout = null
	if interactable_data_instance.has_method("get") and interactable_data_instance.get("layout_data"):
		interactable_layout = interactable_data_instance.layout_data
	elif interactable_data_instance.has_method("get") and interactable_data_instance.get("interactable_data"):
		interactable_layout = interactable_data_instance.interactable_data
	
	if not interactable_layout:
		print("WARNING: No interactable layout found")
		return
	
	var total_size = cube_size + gutter
	var interactable_count = 0
	
	for z in range(min(grid_z, interactable_layout.size())):
		var row = interactable_layout[z]
		for x in range(min(grid_x, row.size())):
			var algorithm_id = str(row[x]).strip_edges()
			
			if algorithm_id != " " and not algorithm_id.is_empty():
				var algorithm_data = algorithm_registry.get_algorithm(algorithm_id)
				if algorithm_data and algorithm_data.size() > 0:
					var y_pos = _find_highest_y_at(x, z)
					
					# Adjust for utilities at same position
					var utility_key = Vector3i(x, y_pos, z)
					if utility_objects.has(utility_key):
						y_pos += 1
					
					_place_algorithm(x, y_pos, z, algorithm_id, total_size)
					interactable_count += 1
				else:
					print("WARNING: Algorithm '%s' not found in registry" % algorithm_id)
	
	print("GridSystem: Added %d interactables" % interactable_count)

func _find_highest_y_at(x: int, z: int) -> int:
	for y in range(grid_y-1, -1, -1):
		if grid[x][y][z]:
			return y + 1
	return 0

func _add_cube(x: int, y: int, z: int, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var new_cube = base_cube.duplicate()
	new_cube.position = position
	new_cube.visible = true
	add_child(new_cube)
	
	if get_tree() and get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
	
	cube_map[Vector3i(x, y, z)] = new_cube

func _place_utility(x: int, y: int, z: int, utility_type: String, parameters: Array, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	
	var scene_path = UtilityRegistry.get_utility_scene_path(utility_type)
	if scene_path.is_empty():
		print("WARNING: No scene file for utility type '%s'" % utility_type)
		return
	
	var scene_resource = _load_scene_cached(UtilityRegistry.get_utility_info(utility_type).file)
	if not scene_resource:
		print("WARNING: Could not load scene for utility type '%s'" % utility_type)
		return
	
	var utility_object = scene_resource.instantiate()
	if utility_object:
		utility_object.position = position
		
		# Apply parameters if supported
		if parameters.size() > 0 and UtilityRegistry.supports_parameters(utility_type):
			_apply_utility_parameters(utility_object, utility_type, parameters)
		
		add_child(utility_object)
		
		if get_tree() and get_tree().edited_scene_root:
			utility_object.owner = get_tree().edited_scene_root
		
		utility_objects[Vector3i(x, y, z)] = utility_object
		
		var param_info = ""
		if parameters.size() > 0:
			param_info = " (params: %s)" % str(parameters)
		print("  Added %s at (%d,%d,%d)%s" % [UtilityRegistry.get_utility_name(utility_type), x, y, z, param_info])

func _apply_utility_parameters(utility_object: Node3D, utility_type: String, parameters: Array) -> void:
	# Basic parameter application - can be extended
	match utility_type:
		"t":  # Teleport
			if parameters.size() > 0 and utility_object.has_property("destination"):
				utility_object.destination = parameters[0]
		"l":  # Lift
			if parameters.size() > 0 and utility_object.has_property("height"):
				utility_object.height = float(parameters[0])

func _place_algorithm(x: int, y: int, z: int, algorithm_id: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var algorithm_object = algorithm_registry.get_algorithm_scene(algorithm_id)
	
	if algorithm_object:
		algorithm_object.position = position
		
		# Update label if exists
		var label = algorithm_object.find_child("id_info_Label3D")
		if label and label is Label3D:
			var algorithm_metadata = algorithm_registry.get_algorithm(algorithm_id)
			var algorithm_name = algorithm_metadata.get("name", "Unknown")
			label.text = str(algorithm_id) + ": " + str(algorithm_name)
		
		# Connect signals
		if algorithm_object.has_signal("interact"):
			algorithm_object.connect("interact", _on_algorithm_interact.bind(algorithm_id, Vector3i(x, y, z)))
		
		if algorithm_object.has_signal("algorithm_event"):
			algorithm_object.connect("algorithm_event", _on_algorithm_event.bind(algorithm_id, Vector3i(x, y, z)))
		
		add_child(algorithm_object)
		
		if get_tree() and get_tree().edited_scene_root:
			algorithm_object.owner = get_tree().edited_scene_root
		
		interactable_objects[Vector3i(x, y, z)] = algorithm_object
		print("  Added algorithm '%s' at (%d,%d,%d)" % [algorithm_id, x, y, z])

func _load_scene_cached(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null
	
	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]
	
	var scene_path = MAP_OBJECTS_PATH + scene_filename
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		return scene
	else:
		print("ERROR: Scene file not found: %s" % scene_path)
		return null

func _on_algorithm_interact(algorithm_id: String, position: Vector3i, data = null) -> void:
	emit_signal("interactable_activated", algorithm_id, position, data)
	print("Algorithm interaction: %s at %s" % [algorithm_id, position])

func _on_algorithm_event(event_name: String, event_data, algorithm_id: String, position: Vector3i) -> void:
	print("Algorithm event: %s from %s at %s" % [event_name, algorithm_id, position])

func reload_map_setter(value: bool) -> void:
	if value:
		reload_map = false
		# Use call_deferred for async function since setters can't be async
		call_deferred("_reload_current_map")

func _reload_current_map() -> void:
	print("GridSystem: Reloading map '%s'" % map_name)
	
	# Clear existing objects completely
	_clear_all_objects()
	scene_cache.clear()
	
	# Reset data instances
	structure_data_instance = null
	utility_data_instance = null
	interactable_data_instance = null
	json_loader = null
	
	# Wait one frame to ensure cleanup is complete
	await get_tree().process_frame
	
	# Reload map
	_load_json_map()

# Public reload method that can be awaited
func reload_map_async() -> void:
	await _reload_current_map()

func _clear_all_objects() -> void:
	print("GridSystem: Clearing all objects...")
	
	# Stop all audio first
	_stop_all_audio()
	
	# Clear cubes immediately
	for key in cube_map.keys():
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.remove_from_group("cubes") if cube.is_in_group("cubes") else null
			_stop_node_audio(cube)
			cube.queue_free()
	cube_map.clear()
	
	# Clear utilities immediately
	for key in utility_objects.keys():
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			_stop_node_audio(utility)
			utility.queue_free()
	utility_objects.clear()
	
	# Clear interactables immediately
	for key in interactable_objects.keys():
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			_stop_node_audio(interactable)
			interactable.queue_free()
	interactable_objects.clear()
	
	# Clear the grid array
	grid.clear()
	
	print("GridSystem: All objects cleared")

# Stop all audio from a node and its children
func _stop_node_audio(node: Node) -> void:
	if not is_instance_valid(node):
		return
	
	# Stop AudioStreamPlayer nodes
	if node is AudioStreamPlayer or node is AudioStreamPlayer2D or node is AudioStreamPlayer3D:
		node.stop()
	
	# Check all children recursively
	for child in node.get_children():
		_stop_node_audio(child)

# Stop all audio in the entire scene
func _stop_all_audio() -> void:
	print("GridSystem: Stopping all audio...")
	
	# Stop audio from the grid system and all its children
	_stop_node_audio(self)
	
	# Also stop any audio from the parent scene
	var root = get_tree().current_scene
	if root:
		_stop_node_audio(root)

# Get current map information
func get_current_map_info() -> Dictionary:
	var info = {
		"name": map_name,
		"format": current_map_format,
		"dimensions": {"x": grid_x, "y": grid_y, "z": grid_z},
		"objects": {
			"cubes": cube_map.size(),
			"utilities": utility_objects.size(),
			"interactables": interactable_objects.size()
		}
	}
	
	if current_map_format == "json" and json_loader:
		info.merge(json_loader.get_metadata())
	
	return info 

# Public API methods

# Enable enhanced utility handler for progression support
func enable_enhanced_utility_handler():
	use_enhanced_utility_handler = true
	if not enhanced_utility_handler:
		enhanced_utility_handler = EnhancedUtilityHandler.new(self)
		add_child(enhanced_utility_handler)
		print("GridSystem: Enhanced utility handler enabled")

# Disable enhanced utility handler 
func disable_enhanced_utility_handler():
	use_enhanced_utility_handler = false
	if enhanced_utility_handler:
		enhanced_utility_handler.queue_free()
		enhanced_utility_handler = null
		print("GridSystem: Enhanced utility handler disabled")

# Set utility handler type
func set_utility_handler_type(handler_type: String):
	match handler_type.to_lower():
		"enhanced":
			enable_enhanced_utility_handler()
		"legacy", "standard":
			disable_enhanced_utility_handler()
		_:
			print("GridSystem: Unknown utility handler type: %s" % handler_type) 
