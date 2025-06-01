# GridSystem.gd
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
@export var prefer_json_format: bool = true  # Use JSON format by default

# Teleport destinations dictionary - maps teleport IDs to scene paths
@export_file("*.tscn") var scene: String = ""

# Path constants
const MAPS_PATH = "res://adaresearch/Common/Data/Maps/"

# Grid properties
var grid_x: int  # Set dynamically from layout data
var grid_z: int  # Set dynamically from layout data
var grid: Array = []

# Component references
@onready var base_cube = $CubeBaseStaticBody3D
@onready var algorithm_registry = AlgorithmRegistry.new()

# Map loading system
var current_map_format: String = "json"
var json_loader: JsonMapLoader

# Data instances (unified interface for both JSON and GDScript)
var structure_data_instance
var utility_data_instance
var interactable_data_instance
var explain_data_instance

# Handler instances
var structure_handler = null
var utility_handler = null
var interactable_handler = null
var explain_handler = null

# Scene cache to avoid loading the same scene multiple times
var scene_cache = {}

# For random number generation
var rng = RandomNumberGenerator.new()

# Signal for when an interactable is activated
signal interactable_activated(object_id, position, data)

func _ready():
	print("=== GridSystem._ready() START ===")
	
	if not base_cube:
		print("ERROR: Base cube reference not found!")
		return
	print("✓ Base cube reference found")
	
	# Initialize the random number generator
	rng.randomize()
	print("✓ RNG initialized")
	
	# Add emergency bypass for VR testing
	var bypass_grid = OS.get_environment("BYPASS_GRID")
	if bypass_grid == "1" or bypass_grid == "true":
		print("🚨 EMERGENCY BYPASS: Skipping grid initialization for VR testing")
		return
	
	print("GridSystem: Load initialization starting...")
	
	# Add the algorithm registry to the scene tree
	if algorithm_registry:
		add_child(algorithm_registry)
		print("✓ Added algorithm registry to scene tree")
	else:
		print("❌ FAILED to create algorithm registry")
		return
	
	# Connect to the registry loaded signal
	if algorithm_registry.has_signal("registry_loaded"):
		algorithm_registry.connect("registry_loaded", _on_algorithm_registry_loaded)
		print("✓ Connected to registry_loaded signal")
	else:
		print("❌ FAILED to find registry_loaded signal")
		return
	
	# Initialize handlers
	_init_handlers()
	if structure_handler and utility_handler and interactable_handler and explain_handler:
		print("✓ Handlers initialized")
	else:
		print("❌ FAILED to initialize handlers")
		return
	
	# Load map data scripts
	_load_map_data()
	print("✓ Map data loading completed")
	
	# Try direct initialization if registry already has data
	print("Checking if registry already has data...")
	var algorithm_count = 0
	if algorithm_registry and algorithm_registry.has_method("get_all_algorithm_ids"):
		algorithm_count = algorithm_registry.get_all_algorithm_ids().size()
		print("✓ Algorithm registry has %d algorithms" % algorithm_count)
	else:
		print("❌ Algorithm registry missing get_all_algorithm_ids method")
		return
		
	if algorithm_count > 0:
		print("Registry already has data, initializing grid directly")
		_on_algorithm_registry_loaded()
		print("✓ Grid initialization completed")
	else:
		print("⏳ Waiting for algorithm registry to load...")
	
	print("=== GridSystem._ready() END ===")

func _init_handlers():
	# Create handler instances
	var StructureHandler = load("res://adaresearch/Common/Scripts/Grid/GridStructureHandler.gd")
	var UtilityHandler = load("res://adaresearch/Common/Scripts/Grid/GridUtilityHandler.gd")
	var InteractableHandler = load("res://adaresearch/Common/Scripts/Grid/GridInteractableHandler.gd")
	var ExplainHandler = load("res://adaresearch/Common/Scripts/Grid/GridExplainHandler.gd")	
	
	structure_handler = StructureHandler.new(self)
	utility_handler = UtilityHandler.new(self)
	interactable_handler = InteractableHandler.new(self)
	explain_handler = ExplainHandler.new(self)	
	
	print("GridSystem: All handlers initialized")

func _load_map_data():
	print("GridSystem: Loading map data for: %s" % map_name)
	
	# Try to load JSON format first if preferred
	if prefer_json_format and _try_load_json_map():
		print("GridSystem: Successfully loaded JSON map data")
		# Provide JSON data to handlers
		_setup_handlers_with_json_data()
		return
	
	# Fall back to legacy GDScript loading if JSON not available
	print("GridSystem: Falling back to legacy GDScript loading")
	_load_legacy_map_data()
	
	# Load grid dimensions
	_load_grid_dimensions()

func _setup_handlers_with_json_data():
	"""Setup handlers with the loaded JSON data"""
	print("GridSystem: Setting up handlers with JSON data")
	
	# Set the data instances directly in the handlers using the JSON adapter instances
	if structure_handler and structure_data_instance:
		structure_handler.structure_data_instance = structure_data_instance
		print("GridSystem: Assigned structure data instance to handler")
	
	if utility_handler and utility_data_instance:
		utility_handler.utility_data_instance = utility_data_instance
		print("GridSystem: Assigned utility data instance to handler")
	
	if interactable_handler and interactable_data_instance:
		interactable_handler.interactable_data_instance = interactable_data_instance
		print("GridSystem: Assigned interactable data instance to handler")
	
	if explain_handler and explain_data_instance:
		explain_handler.explain_data_instance = explain_data_instance
		print("GridSystem: Assigned explain data instance to handler")

func _try_load_json_map() -> bool:
	print("🔄 Attempting to load JSON map...")
	var json_path = MAPS_PATH + map_name + "/map_data.json"
	
	print("📁 Checking JSON path: %s" % json_path)
	if not JsonMapLoader.is_json_map_file(json_path):
		print("❌ GridSystem: No JSON map data found for '%s'" % map_name)
		return false
	
	print("✓ JSON file found, creating loader...")
	
	json_loader = JsonMapLoader.new()
	if not json_loader:
		print("❌ GridSystem: Failed to create JsonMapLoader")
		return false
	
	print("🔄 Loading JSON map from '%s'" % json_path)
	
	# Add timeout protection
	var start_time = Time.get_time_dict_from_system()
	
	if json_loader.load_map(json_path):
		var end_time = Time.get_time_dict_from_system()
		var duration = (end_time.hour * 3600 + end_time.minute * 60 + end_time.second) - (start_time.hour * 3600 + start_time.minute * 60 + start_time.second)
		print("✓ JSON loaded in %d seconds" % duration)
		
		current_map_format = "json"
		
		print("🔄 Extracting data instances...")
		# Extract instances from JSON loader
		structure_data_instance = json_loader.structure_data_instance
		utility_data_instance = json_loader.utility_data_instance
		interactable_data_instance = json_loader.interactable_data_instance
		explain_data_instance = json_loader  # JSON loader can handle explain data too
		print("✓ Data instances extracted")
		
		print("🔄 Applying JSON settings...")
		# Apply JSON settings
		var settings = json_loader.get_settings()
		cube_size = settings.get("cube_size", cube_size)
		gutter = settings.get("gutter", gutter)
		showgrid = settings.get("show_grid", showgrid)
		print("✓ Settings applied: cube_size=%f, gutter=%f" % [cube_size, gutter])
		
		print("🔄 Setting grid dimensions...")
		# Set grid dimensions from JSON
		var dimensions = json_loader.get_dimensions()
		grid_x = dimensions.get("width", 0)
		grid_z = dimensions.get("depth", 0)
		grid_y = dimensions.get("max_height", grid_y)
		
		print("GridSystem: JSON map loaded successfully")
		print("  Dimensions: %dx%dx%d" % [grid_x, grid_z, grid_y])
		print("  Cube size: %f, Gutter: %f" % [cube_size, gutter])
		
		return true
	else:
		print("❌ GridSystem: Failed to load JSON map")
		return false

func _load_legacy_map_data():
	# Load map data using handlers (legacy GDScript approach)
	if structure_handler and utility_handler and interactable_handler and explain_handler:
		structure_handler.load_data(map_name)
		utility_handler.load_data(map_name)
		interactable_handler.load_data(map_name)
		explain_handler.load_data(map_name)
		
		# Get data instances from handlers
		structure_data_instance = structure_handler.structure_data_instance
		utility_data_instance = utility_handler.utility_data_instance
		interactable_data_instance = interactable_handler.interactable_data_instance
		explain_data_instance = explain_handler.explain_data_instance
	else:
		print("GridSystem: ERROR - Handlers not initialized for legacy loading")

func _load_grid_dimensions():
	if current_map_format == "json" and json_loader:
		# Dimensions already set in JSON loading
		print("GridSystem: Grid dimensions from JSON: %dx%dx%d" % [grid_x, grid_z, grid_y])
	elif structure_handler:
		# Legacy format - get dimensions from structure handler
		var dimensions = structure_handler.get_grid_dimensions()
		if dimensions:
			grid_x = dimensions.x
			grid_z = dimensions.z
			print("GridSystem: Grid dimensions from legacy: %dx%dx%d" % [grid_x, grid_z, grid_y])
		else:
			print("GridSystem: ERROR - Could not get grid dimensions from structure handler")
	else:
		print("GridSystem: ERROR - No valid data source for grid dimensions")

func _on_algorithm_registry_loaded():
	#print("Algorithm registry loaded with %d algorithms" % algorithm_registry.get_all_algorithm_ids().size())
	
	# Now that algorithms are loaded, generate the grid
	#print("Game initialization")
	base_cube.visible = false
	_generate_grid()

func _generate_grid():
	print("GridSystem: Starting grid generation using %s format" % current_map_format)
	
	initialize_grid()
	print("GridSystem: Grid initialized")
	
	# Apply all handler data (handlers use their own loaded data)
	structure_handler.apply_data()
	print("GridSystem: Structure data applied")
	
	utility_handler.apply_data()
	print("GridSystem: Utility data applied")
	
	interactable_handler.apply_data()
	print("GridSystem: Interactable data applied")

	explain_handler.apply_data()
	print("GridSystem: Explain data applied")
	
	print("GridSystem: Grid generation completed")

func initialize_grid():
	print("GridSystem: Initializing grid: %dx%dx%d" % [grid_x, grid_y, grid_z])
	grid = []
	
	# Clear dictionaries in all handlers
	if structure_handler: structure_handler.clear()
	if utility_handler: utility_handler.clear()  
	if interactable_handler: interactable_handler.clear()
	if explain_handler: explain_handler.clear()
	
	# Pre-allocate the grid with empty arrays
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
	
	print("GridSystem: Grid array initialized with dimensions: %d x %d x %d" % [grid.size(), grid[0].size(), grid[0][0].size()])

func reload_map_setter(value: bool):
	if value:
		reload_map = false  # Reset the toggle
		generate_layout()

func generate_layout():
	if not base_cube:
		print("GridSystem: ERROR - Base cube not found in editor!")
		return
	
	print("GridSystem: Generating layout for map: %s" % map_name)
	
	# Clear existing objects using handlers
	if structure_handler: structure_handler.clear()
	if utility_handler: utility_handler.clear()
	if interactable_handler: interactable_handler.clear()
	if explain_handler: explain_handler.clear()
	
	# Clear scene cache to reload any changed scenes
	scene_cache.clear()
	
	# Reload map data
	_load_map_data()
	
	# Generate the grid
	_generate_grid()
	
	print("GridSystem: Layout generation complete")

# Load a scene from the MAP_OBJECTS_PATH
func load_scene(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null
		
	# Check if scene is already cached
	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]
	
	# Build the full path
	var scene_path = GridCommon.MAP_OBJECTS_PATH + scene_filename
	
	# Try to load the scene
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		return scene
	else:
		print("ERROR: Scene file not found: %s" % scene_path)
		return null

# Forward signal from interactable handler
func _on_interactable_activated(algorithm_id: String, position: Vector3i, data = null):
	emit_signal("interactable_activated", algorithm_id, position, data)
	#print("GridSystem: Algorithm activated: ID %s at position %s" % [algorithm_id, position])

# Get methods that delegate to handlers

func get_algorithm_at(x: int, y: int, z: int) -> Node:
	return interactable_handler.get_interactable_at(x, y, z)

func get_algorithms_by_category(category: String) -> Array:
	return interactable_handler.get_interactables_by_category(category)

# Conversion utilities

func grid_to_world_position(grid_pos: Vector3i) -> Vector3:
	var total_size = cube_size + gutter
	return Vector3(grid_pos.x, grid_pos.y, grid_pos.z) * total_size

func world_to_grid_position(world_pos: Vector3) -> Vector3i:
	var total_size = cube_size + gutter
	return Vector3i(
		int(round(world_pos.x / total_size)),
		int(round(world_pos.y / total_size)),
		int(round(world_pos.z / total_size))
	)

# Handle property changes (especially in editor)
func _set(property, value):
	if property in ["cube_size", "gutter", "grid_y", "map_name"]:
		set(property, value)
		if Engine.is_editor_hint():
			generate_layout()
		return true
	return false
