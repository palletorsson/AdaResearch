# GridSystem.gd
extends Node3D
class_name GridSystem1 
# Configuration
@export var cube_size: float = 1.0
@export var gutter: float = 0.0
@export var grid_y: int = 6  # Maximum height
@export var showgrid: bool = false

# Map selection
@export var map_name: String = "Intro_0"
@export var reload_map: bool = false : set = reload_map_setter

# Teleport destinations dictionary - maps teleport IDs to scene paths
@export_file("*.tscn") var scene: String = ""

# Grid properties
var grid_x: int  # Set dynamically from layout data
var grid_z: int  # Set dynamically from layout data
var grid: Array = []

# Component references
@onready var base_cube = $CubeBaseStaticBody3D
@onready var algorithm_registry = AlgorithmRegistry.new()

# Handler instances
var structure_handler = null
var utility_handler = null
var interactable_handler = null
var task_handler = null

# Scene cache to avoid loading the same scene multiple times
var scene_cache = {}

# For random number generation
var rng = RandomNumberGenerator.new()

# Signal for when an interactable is activated
signal interactable_activated(object_id, position, data)

func _ready():
	if not base_cube:
		print("ERROR: Base cube reference not found!")
		return
	
	# Initialize the random number generator
	rng.randomize()
	print("Load initialization")
	
	# Add the algorithm registry to the scene tree
	add_child(algorithm_registry)
	print("Added algorithm registry to scene tree")
	
	# Connect to the registry loaded signal
	algorithm_registry.connect("registry_loaded", _on_algorithm_registry_loaded)
	print("Connected to registry_loaded signal")
	
	# Initialize handlers
	_init_handlers()
	
	# Load map data scripts
	_load_map_data()
	
	# Try direct initialization if registry already has data
	print("Checking if registry already has data...")
	if algorithm_registry.get_all_algorithm_ids().size() > 0:
		print("Registry already has data, initializing grid directly")
		_on_algorithm_registry_loaded()

func _init_handlers():
	# Create handler instances
	var StructureHandler = load("res://adaresearch/Common/Scripts/Grid/GridStructureHandler.gd")
	var UtilityHandler = load("res://adaresearch/Common/Scripts/Grid/GridUtilityHandler.gd")
	var InteractableHandler = load("res://adaresearch/Common/Scripts/Grid/GridInteractableHandler.gd")
	var TaskHandler = load("res://adaresearch/Common/Scripts/Grid/GridTaskHandler.gd")
	
	structure_handler = StructureHandler.new(self)
	utility_handler = UtilityHandler.new(self)
	interactable_handler = InteractableHandler.new(self)
	task_handler = TaskHandler.new(self)
	
	print("GridSystem: All handlers initialized")

func _load_map_data():
	# Load map data using handlers
	structure_handler.load_data(map_name)
	utility_handler.load_data(map_name)
	interactable_handler.load_data(map_name)
	task_handler.load_data(map_name)  # Pass map_name to task_handler
	# Load grid dimensions from structure data
	_load_grid_dimensions()

func _load_grid_dimensions():
	var dimensions = structure_handler.get_grid_dimensions()
	if dimensions:
		grid_x = dimensions.x
		# grid_y is already set in the GridSystem
		grid_z = dimensions.z
		#print("Grid dimensions set to: x=%d y=%d z=%d" % [grid_x, grid_y, grid_z])
	else:
		print("ERROR: Could not get grid dimensions from structure handler")

func _on_algorithm_registry_loaded():
	#print("Algorithm registry loaded with %d algorithms" % algorithm_registry.get_all_algorithm_ids().size())
	
	# Now that algorithms are loaded, generate the grid
	#print("Game initialization")
	base_cube.visible = false
	_generate_grid()

func _generate_grid():
	#print("Starting grid generation")
	initialize_grid()
	#print("Grid initialized")
	
	# Apply data using handlers
	structure_handler.apply_data()
	#print("Structure data applied")
	
	utility_handler.apply_data()
	#print("Utility data applied")
	
	interactable_handler.apply_data()
	#print("Interactable data applied")
	
	task_handler.apply_data()
	#print("Task data applied")
	
	#print("Grid generation completed")

func initialize_grid():
	#print("Initializing grid: x=%d, y=%d, z=%d" % [grid_x, grid_y, grid_z])
	grid = []
	
	# Clear dictionaries in all handlers
	structure_handler.clear()
	utility_handler.clear()
	interactable_handler.clear()
	task_handler.clear()
	
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
	
	#print("Grid array initialized with dimensions: %d x %d x %d" % [grid.size(), grid[0].size(), grid[0][0].size()])

func reload_map_setter(value: bool):
	if value:
		reload_map = false  # Reset the toggle
		generate_layout()

func generate_layout():
	if not base_cube:
		#print("ERROR: Base cube not found in editor!")
		return
	
	#print("Generating layout for map: %s" % map_name)
	
	# Clear existing objects using handlers
	structure_handler.clear()
	utility_handler.clear()
	interactable_handler.clear()
	task_handler.clear()
	
	# Clear scene cache to reload any changed scenes
	scene_cache.clear()
	
	# Reload map data
	_load_map_data()
	
	# Generate the grid
	_generate_grid()
	
	#print("Layout generation complete")

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
	
	# If TaskSystem singleton exists, update task progress
	if Engine.has_singleton("TaskSystem"):
		TaskSystem.update_task_progress(algorithm_id)

# Get methods that delegate to handlers

func get_algorithm_at(x: int, y: int, z: int) -> Node:
	return interactable_handler.get_interactable_at(x, y, z)

func get_algorithms_by_category(category: String) -> Array:
	return interactable_handler.get_interactables_by_category(category)

func get_task_at(x: int, y: int, z: int) -> Dictionary:
	return task_handler.get_task_at(x, y, z)

func get_all_tasks() -> Array:
	return task_handler.get_all_tasks()

func get_task_by_lookup_name(lookup_name: String) -> Dictionary:
	return task_handler.get_task_by_lookup_name(lookup_name)

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
	if property in ["cube_size", "gutter", "grid_y", "map_name", "teleport_destinations"]:
		set(property, value)
		if Engine.is_editor_hint():
			generate_layout()
		return true
	return false
