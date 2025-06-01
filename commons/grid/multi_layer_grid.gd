extends Node3D

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

# Path constants
const MAPS_PATH = "res://commons/maps/"
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"

# Grid properties
var grid_x: int  # Set dynamically from layout data
var grid_z: int  # Set dynamically from layout data
var grid: Array = []
var cube_map: Dictionary = {}
var utility_objects: Dictionary = {}
var interactable_objects: Dictionary = {}

# Data script references
var structure_data_script: GDScript
var utility_data_script: GDScript
var interactable_data_script: GDScript

# Components
@onready var base_cube = $CubeBaseStaticBody3D
@onready var algorithm_registry = AlgorithmRegistry.new()

# Scene cache to avoid loading the same scene multiple times
var scene_cache = {}

# For random number generation
var rng = RandomNumberGenerator.new()

# Empty space, no interactable
const EMPTY_SPACE = UtilityRegistry.EMPTY_SPACE

# Instances of the data scripts
var structure_data_instance
var utility_data_instance
var interactable_data_instance

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
	
	# Load map data scripts
	_load_map_data_scripts()
	
	# Load the grid dimensions
	_load_grid_dimensions()
	
	# Try direct initialization if registry already has data
	print("Checking if registry already has data...")
	if algorithm_registry.get_all_algorithm_ids().size() > 0:
		print("Registry already has data, initializing grid directly")
		_on_algorithm_registry_loaded()

func _load_map_data_scripts() -> void:
	print("Loading map data for: %s" % map_name)
	
	# Clear previous instances
	structure_data_instance = null
	utility_data_instance = null
	interactable_data_instance = null
	
	# Try to load JSON data first
	var json_path = MAPS_PATH + map_name + "/map_data.json"
	if ResourceLoader.exists(json_path):
		print("Found JSON map data: %s" % json_path)
		_load_json_map_data(json_path)
		return
	
	# Fallback to old GDScript method
	print("JSON not found, trying GDScript files...")
	_load_gdscript_map_data()

func _load_json_map_data(json_path: String) -> void:
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		print("ERROR: Could not open JSON file: %s" % json_path)
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		print("ERROR: Failed to parse JSON: %s" % json.get_error_message())
		return
	
	var map_data = json.data
	print("Successfully loaded JSON map data")
	
	# Create fake data instances that mimic the old GDScript structure
	structure_data_instance = _create_structure_instance(map_data)
	utility_data_instance = _create_utility_instance(map_data)
	interactable_data_instance = _create_interactable_instance(map_data)

func _create_structure_instance(map_data: Dictionary):
	# Create a simple dictionary instead of RefCounted
	var instance = {"layout_data": []}
	
	if map_data.has("layers") and map_data.layers.has("structure"):
		var structure_data = map_data.layers.structure
		print("Raw structure data from JSON: %s" % str(structure_data))
		print("Structure data type: %s" % typeof(structure_data))
		print("Structure data size: %d" % structure_data.size())
		
		if structure_data.size() > 0:
			print("First row: %s" % str(structure_data[0]))
			print("First row type: %s" % typeof(structure_data[0]))
			if structure_data[0].size() > 0:
				print("First row size: %d" % structure_data[0].size())
		
		instance["layout_data"] = structure_data
		print("Created structure data instance with %d rows" % structure_data.size())
		
		# Verify we can get it back
		var test_get = instance["layout_data"]
		print("Test get layout_data: %s (null: %s)" % [str(test_get), str(test_get == null)])
	else:
		print("ERROR: No structure layer found in JSON data")
		instance["layout_data"] = []
	return instance

func _create_utility_instance(map_data: Dictionary):
	# Create a simple dictionary instead of RefCounted
	var instance = {"layout_data": []}
	
	if map_data.has("layers") and map_data.layers.has("utilities"):
		instance["layout_data"] = map_data.layers.utilities
		print("Created utility data instance with %d rows" % map_data.layers.utilities.size())
	else:
		print("WARNING: No utilities layer found in JSON data")
		instance["layout_data"] = []
	return instance

func _create_interactable_instance(map_data: Dictionary):
	# Create a simple dictionary instead of RefCounted
	var instance = {"layout_data": []}
	
	if map_data.has("layers") and map_data.layers.has("interactables"):
		var interactable_data = map_data.layers.interactables
		print("Raw interactable data from JSON: %s" % str(interactable_data))
		print("Interactable data type: %s" % typeof(interactable_data))
		print("Interactable data size: %d" % interactable_data.size())
		
		instance["layout_data"] = interactable_data
		print("Created interactable data instance with %d rows" % interactable_data.size())
		
		# Verify we can get it back
		var test_get = instance["layout_data"]
		print("Test get layout_data: %s (null: %s)" % [str(test_get), str(test_get == null)])
	else:
		print("WARNING: No interactables layer found in JSON data")
		instance["layout_data"] = []
	return instance

func _load_gdscript_map_data() -> void:
	# Original GDScript loading code (kept for backwards compatibility)
	
	# Load structure data script
	var struct_path = MAPS_PATH + map_name + "/struct_data.gd"
	if ResourceLoader.exists(struct_path):
		structure_data_script = load(struct_path)
		if structure_data_script:
			structure_data_instance = structure_data_script.new()
			print("Loaded structure data script: %s" % struct_path)
		else:
			print("ERROR: Failed to load structure data script: %s" % struct_path)
	else:
		print("ERROR: Structure data script not found: %s" % struct_path)
	
	# Load utility data script
	var utility_path = MAPS_PATH + map_name + "/utility_data.gd"
	if ResourceLoader.exists(utility_path):
		utility_data_script = load(utility_path)
		if utility_data_script:
			utility_data_instance = utility_data_script.new()
			print("Loaded utility data script: %s" % utility_path)
		else:
			print("ERROR: Failed to load utility data script: %s" % utility_path)
	else:
		print("ERROR: Utility data script not found: %s" % utility_path)
	
	# Load interactable data script
	var interactable_path = MAPS_PATH + map_name + "/interactable_data.gd"
	if ResourceLoader.exists(interactable_path):
		interactable_data_script = load(interactable_path)
		if interactable_data_script:
			interactable_data_instance = interactable_data_script.new()
			print("Loaded interactable data script: %s" % interactable_path)
		else:
			print("ERROR: Failed to load interactable data script: %s" % interactable_path)
	else:
		print("ERROR: Interactable data script not found: %s" % interactable_path)

func _on_algorithm_registry_loaded():
	print("Algorithm registry loaded with %d algorithms" % algorithm_registry.get_all_algorithm_ids().size())
	
	# Now that algorithms are loaded, generate the grid
	print("Game initialization")
	base_cube.visible = false
	_generate_grid()

func _load_grid_dimensions() -> void:
	# Skip if structure data script isn't instantiated
	if not structure_data_instance:
		print("ERROR: Structure data instance not created!")
		return
		
	# Load dimensions from structure data using dictionary access
	var structure_layout = structure_data_instance["layout_data"]
	if structure_layout == null:
		print("ERROR: Could not get layout_data from structure instance!")
		return
		
	print("Structure data loaded, rows: %d" % structure_layout.size())
	
	if structure_layout.is_empty():
		print("ERROR: Structure layout is empty - cannot determine grid dimensions!")
		return
	
	# Safely get grid dimensions
	grid_z = structure_layout.size()
	if grid_z > 0 and structure_layout[0].size() > 0:
		grid_x = structure_layout[0].size()
	else:
		print("ERROR: First row of structure layout is empty!")
		grid_x = 0
		return
		
	print("Grid dimensions set to: x=%d y=%d z=%d" % [grid_x, grid_y, grid_z])
	
	if grid_x == 0 or grid_z == 0:
		print("ERROR: Invalid grid dimensions! Cannot continue.")
		return
	
	# Skip utility checks if utility data script isn't instantiated
	if not utility_data_instance:
		print("WARNING: Utility data instance not created, skipping utility dimension check")
		return
		
	# Verify utility data has same dimensions using dictionary access
	var utility_layout = utility_data_instance["layout_data"]
	if utility_layout == null:
		print("WARNING: Could not get utility layout_data")
		return
		
	print("Utility data loaded, rows: %d" % utility_layout.size())
	
	if utility_layout.size() != grid_z:
		print("ERROR: Utility layout Z dimension (%d) doesn't match structure layout (%d)!" % [utility_layout.size(), grid_z])
	
	for z in grid_z:
		if z < utility_layout.size() and utility_layout[z].size() != grid_x:
			print("ERROR: Utility layout X dimension (%d) at row %d doesn't match structure layout (%d)!" % [utility_layout[z].size(), z, grid_x])
	
	# Skip interactable checks if interactable data script isn't instantiated
	if not interactable_data_instance:
		print("WARNING: Interactable data instance not created, skipping interactable dimension check")
		return
		
	# Check which property is available using dictionary access
	var has_layout_data = interactable_data_instance.has("layout_data") and interactable_data_instance["layout_data"] != null
	var has_interactable_data = interactable_data_instance.has("interactable_data") and interactable_data_instance["interactable_data"] != null
	
	print("Interactable script has layout_data: %s" % has_layout_data)
	print("Interactable script has interactable_data: %s" % has_interactable_data)
	
	var interactable_layout
	if has_layout_data:
		interactable_layout = interactable_data_instance["layout_data"]
	elif has_interactable_data:
		interactable_layout = interactable_data_instance["interactable_data"]
	else:
		print("ERROR: Interactable data script has no layout_data or interactable_data property!")
		return
	
	print("Interactable data loaded, rows: %d" % interactable_layout.size())
	
	if interactable_layout.size() != grid_z:
		print("ERROR: Interactable layout Z dimension (%d) doesn't match structure layout (%d)!" % [interactable_layout.size(), grid_z])
	
	for z in grid_z:
		if z < interactable_layout.size() and interactable_layout[z].size() != grid_x:
			print("ERROR: Interactable layout X dimension (%d) at row %d doesn't match structure layout (%d)!" % [interactable_layout[z].size(), z, grid_x])

func _generate_grid() -> void:
	print("Starting grid generation")
	initialize_grid()
	print("Grid initialized")
	apply_structure_data()
	print("Structure data applied")
	apply_utility_data()
	print("Utility data applied")
	apply_interactable_data()
	print("Interactable data applied")
	print("Grid generation completed")

func initialize_grid() -> void:
	print("Initializing grid: x=%d, y=%d, z=%d" % [grid_x, grid_y, grid_z])
	
	# Validate grid dimensions before proceeding
	if grid_x <= 0 or grid_y <= 0 or grid_z <= 0:
		print("ERROR: Invalid grid dimensions - cannot initialize grid!")
		return
	
	grid = []
	cube_map.clear()
	utility_objects.clear()
	interactable_objects.clear()
	
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
	
	# Safe debug print - only access arrays if they exist
	if grid.size() > 0 and grid[0].size() > 0 and grid[0][0].size() > 0:
		print("Grid array initialized with dimensions: %d x %d x %d" % [grid.size(), grid[0].size(), grid[0][0].size()])
	else:
		print("ERROR: Grid array failed to initialize properly")

func add_cube(x: int, y: int, z: int, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var new_cube = base_cube.duplicate()
	new_cube.position = position
	new_cube.visible = true
	add_child(new_cube)
	
	# Set owner for editor
	if get_tree() and get_tree().edited_scene_root:
		new_cube.owner = get_tree().edited_scene_root
		
	cube_map[Vector3i(x, y, z)] = new_cube

func apply_structure_data() -> void:
	# Skip if structure data instance isn't created
	if not structure_data_instance:
		print("ERROR: Cannot apply structure data, instance not created!")
		return
		
	print("Applying structure data")
	var structure_layout = structure_data_instance["layout_data"]
	
	# Check if layout data is valid
	if structure_layout == null:
		print("ERROR: Could not get structure layout data!")
		return
	
	if structure_layout.is_empty():
		print("ERROR: Structure layout is empty!")
		return
	
	var total_size = cube_size + gutter
	var cube_count = 0
	
	for z in grid_z:
		if z >= structure_layout.size():
			print("WARNING: z=%d exceeds structure layout size %d" % [z, structure_layout.size()])
			continue
			
		var row = structure_layout[z]
		if row.is_empty():
			print("WARNING: Row %d is empty in structure layout" % z)
			continue
			
		for x in grid_x:
			if x >= row.size():
				print("WARNING: x=%d exceeds row size %d at z=%d" % [x, row.size(), z])
				continue
				
			var cell_value = row[x].strip_edges()
			var stack_height = 0
			
			# Try to parse the cell value as a number
			if cell_value.is_valid_int():
				stack_height = int(cell_value)
			
			# Create stacked cubes based on the height value
			for y in range(0, min(stack_height, grid_y)):
				add_cube(x, y, z, total_size)
				grid[x][y][z] = true
				cube_count += 1
	
	print("Added %d cubes to the grid" % cube_count)

func apply_utility_data() -> void:
	# Skip if utility data instance isn't created
	if not utility_data_instance:
		print("WARNING: Cannot apply utility data, instance not created!")
		return
		
	print("Applying utility data")
	var utility_layout = utility_data_instance["layout_data"]
	
	# Check if layout data is valid
	if utility_layout == null:
		print("WARNING: Could not get utility layout data!")
		return
	
	if utility_layout.is_empty():
		print("WARNING: Utility layout is empty!")
		return
	
	var total_size = cube_size + gutter
	var utility_count = 0
	
	for z in range(min(grid_z, utility_layout.size())):
		var row = utility_layout[z]
		if row.is_empty():
			print("WARNING: Utility row %d is empty" % z)
			continue
			
		for x in range(min(grid_x, row.size())):
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
			if utility_type in UtilityRegistry.UTILITY_TYPES.keys() and utility_type != " ":
				# Find the highest occupied y position at this x,z coordinate
				var y_pos = 0
				for y in range(grid_y-1, -1, -1):
					if grid[x][y][z]:
						y_pos = y + 1  # Place utility on top of the highest cube
						break
				
				_place_utility(x, y_pos, z, utility_type, teleport_id, total_size)
				utility_count += 1
	
	print("Added %d utility objects to the grid" % utility_count)

func apply_interactable_data() -> void:
	# Skip if interactable data instance isn't created
	if not interactable_data_instance:
		print("WARNING: Cannot apply interactable data, instance not created!")
		return
		
	print("Applying interactable data")
	
	# Skip if algorithm registry is not yet loaded
	if algorithm_registry.get_all_algorithm_ids().size() == 0:
		print("WARNING: Algorithm registry not loaded, skipping interactable placement")
		return
	
	# Debug: Print what type the instance is
	print("Interactable instance type: Dictionary")
	
	# Check which property is available
	var has_layout_data = interactable_data_instance.has("layout_data") and interactable_data_instance["layout_data"] != null
	var has_interactable_data = interactable_data_instance.has("interactable_data") and interactable_data_instance["interactable_data"] != null
	
	print("Interactable script has layout_data: %s" % has_layout_data)
	print("Interactable script has interactable_data: %s" % has_interactable_data)
	
	if has_layout_data:
		print("DEBUG: layout_data value: %s" % str(interactable_data_instance["layout_data"]))
	if has_interactable_data:
		print("DEBUG: interactable_data value: %s" % str(interactable_data_instance["interactable_data"]))
	
	var interactable_layout
	if has_layout_data:
		interactable_layout = interactable_data_instance["layout_data"]
	elif has_interactable_data:
		interactable_layout = interactable_data_instance["interactable_data"]
	else:
		print("ERROR: Interactable data script has no layout_data or interactable_data property!")
		print("DEBUG: Available keys in dictionary: %s" % str(interactable_data_instance.keys()))
		return
	
	var total_size = cube_size + gutter
	var interactable_count = 0
	
	print("Interactable layout size: %d rows" % interactable_layout.size())
	
	for z in range(min(grid_z, interactable_layout.size())):
		var row = interactable_layout[z]
		print("Processing interactable row %d, length: %d" % [z, row.size()])
		
		for x in range(min(grid_x, row.size())):
			var algorithm_id = row[x].strip_edges()
			
			# If it's a valid algorithm ID, place it
			if algorithm_id != EMPTY_SPACE and algorithm_id != '':
				print("Found algorithm ID: '%s' at position (%d, ?, %d)" % [algorithm_id, x, z])
				
				var algorithm_data = algorithm_registry.get_algorithm(algorithm_id)
				if algorithm_data and algorithm_data.size() > 0:
					# Find the highest occupied y position at this x,z coordinate
					var y_pos = 0
					for y in range(grid_y-1, -1, -1):
						if grid[x][y][z]:
							y_pos = y + 1  # Place interactable on top of the highest cube
							break
					
					# Check if there's a utility at this position and adjust height accordingly
					var utility_key = Vector3i(x, y_pos, z)
					if utility_objects.has(utility_key):
						y_pos += 1  # Place interactable on top of utility
					
					print("Placing algorithm '%s' at position (%d, %d, %d)" % [algorithm_id, x, y_pos, z])
					_place_algorithm(x, y_pos, z, algorithm_id, total_size)
					interactable_count += 1
				else:
					print("WARNING: Algorithm ID '%s' not found in registry" % algorithm_id)
	
	print("Added %d interactable objects to the grid" % interactable_count)

# Load a scene from the MAP_OBJECTS_PATH
func _load_scene(scene_filename: String) -> PackedScene:
	if scene_filename.is_empty():
		return null
		
	# Check if scene is already cached
	if scene_cache.has(scene_filename):
		return scene_cache[scene_filename]
	
	# Build the full path
	var scene_path = MAP_OBJECTS_PATH + scene_filename
	
	# Try to load the scene
	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_filename] = scene
		return scene
	else:
		print("ERROR: Scene file not found: %s" % scene_path)
		return null

# Later in the _place_utility function:
func _place_utility(x: int, y: int, z: int, utility_type: String, teleport_id: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	var utility_object = null
	
	# Skip if utility type is not recognized
	if not UtilityRegistry.UTILITY_TYPES.has(utility_type) or utility_type == " ":
		return
		
	# Get scene file name for this utility type
	var scene_file = UtilityRegistry.UTILITY_TYPES[utility_type].file
	
	# Load the scene
	var scene_resource = _load_scene(scene_file)
	if scene_resource:
		utility_object = scene_resource.instantiate()
	else:
		print("WARNING: Could not load scene for utility type '%s'" % utility_type)
		return
	
	if utility_object:
		utility_object.position = position
		
		# For teleport objects, set the destination scene
		if utility_type == "t" and not scene.is_empty():
			# Check if the teleport object has a 'scene' property
			
			utility_object.scene = scene
			print("Set teleport scene: %s" % scene)
			
		add_child(utility_object)
		
		# Set owner for editor
		if get_tree() and get_tree().edited_scene_root:
			utility_object.owner = get_tree().edited_scene_root
			
		utility_objects[Vector3i(x, y, z)] = utility_object
		print("Added utility object of type '%s' at position (%d, %d, %d)" % [utility_type, x, y, z])
	else:
		print("WARNING: Failed to instantiate utility type '%s'" % utility_type)

func _place_algorithm(x: int, y: int, z: int, algorithm_id: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	
	# Get the algorithm scene from the registry
	print("Loading algorithm scene for ID '%s'" % algorithm_id)
	var algorithm_object = algorithm_registry.get_algorithm_scene(algorithm_id)
	
	if algorithm_object:
		algorithm_object.position = position
		
		# Get the algorithm metadata to access the name
		var algorithm_metadata = algorithm_registry.get_algorithm(algorithm_id)
		var algorithm_name = "Unknown Algorithm"
		if algorithm_metadata != null and algorithm_metadata.has("name"):
			algorithm_name = algorithm_metadata.get("name")
		
		# Find and update the Label3D if it exists
		var label = algorithm_object.find_child("id_info_Label3D")
		if label and label is Label3D:
			label.text = str(algorithm_id) + ": " + str(algorithm_name)
			print("Updated Label3D text to: %s" % label.text)
		
		# If the algorithm has an "interact" signal, connect it
		if algorithm_object.has_signal("interact"):
			algorithm_object.connect("interact", _on_algorithm_interact.bind(
				algorithm_id, Vector3i(x, y, z)
			))
		
		# If the algorithm has an "algorithm_event" signal, connect it
		if algorithm_object.has_signal("algorithm_event"):
			algorithm_object.connect("algorithm_event", _on_algorithm_event.bind(
				algorithm_id, Vector3i(x, y, z)
			))
		
		add_child(algorithm_object)
		
		# Set owner for editor
		if get_tree() and get_tree().edited_scene_root:
			algorithm_object.owner = get_tree().edited_scene_root
			
		interactable_objects[Vector3i(x, y, z)] = algorithm_object
		print("Successfully placed algorithm '%s' at (%d, %d, %d)" % [algorithm_id, x, y, z])
	else:
		print("WARNING: Attempted to place algorithm with ID '%s' but the scene could not be loaded" % algorithm_id)

func _on_algorithm_interact(algorithm_id: String, position: Vector3i, data = null) -> void:
	# Relay the interaction to any listeners
	emit_signal("interactable_activated", algorithm_id, position, data)
	print("Algorithm activated: ID %s at position %s" % [algorithm_id, position])

func _on_algorithm_event(event_name: String, event_data, algorithm_id: String, position: Vector3i) -> void:
	# Handle algorithm-specific events
	print("Algorithm event: %s from ID %s at position %s" % [event_name, algorithm_id, position])
	
	# You can add custom logic here to handle different event types

func remove_cube_at(x: int, y: int, z: int) -> void:
	var key = Vector3i(x, y, z)
	if cube_map.has(key):
		var cube = cube_map[key]
		if is_instance_valid(cube):
			cube.queue_free()
		cube_map.erase(key)

func remove_utility_at(x: int, y: int, z: int) -> void:
	var key = Vector3i(x, y, z)
	if utility_objects.has(key):
		var utility = utility_objects[key]
		if is_instance_valid(utility):
			utility.queue_free()
		utility_objects.erase(key)

func remove_interactable_at(x: int, y: int, z: int) -> void:
	var key = Vector3i(x, y, z)
	if interactable_objects.has(key):
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			interactable.queue_free()
		interactable_objects.erase(key)

func reload_map_setter(value: bool) -> void:
	if value:
		reload_map = false  # Reset the toggle
		generate_layout()

func generate_layout() -> void:
	if not base_cube:
		print("ERROR: Base cube not found in editor!")
		return
	
	print("Generating layout for map: %s" % map_name)
	
	# Clear existing objects
	for key in cube_map.keys():
		remove_cube_at(key.x, key.y, key.z)
	
	for key in utility_objects.keys():
		remove_utility_at(key.x, key.y, key.z)
	
	for key in interactable_objects.keys():
		remove_interactable_at(key.x, key.y, key.z)
	
	# Clear scene cache to reload any changed scenes
	scene_cache.clear()
	
	# Reload map data scripts
	_load_map_data_scripts()
	
	# Load grid dimensions
	_load_grid_dimensions()
	
	# Generate the grid
	_generate_grid()
	
	print("Layout generation complete")

# Get an algorithm at a specific position
func get_algorithm_at(x: int, y: int, z: int) -> Node:
	var key = Vector3i(x, y, z)
	if interactable_objects.has(key):
		return interactable_objects[key]
	return null

# Get all algorithms of a specific category
func get_algorithms_by_category(category: String) -> Array:
	var results = []
	for key in interactable_objects.keys():
		var obj = interactable_objects[key]
		if obj and obj.has_method("get_algorithm_metadata"):
			var metadata = obj.get_algorithm_metadata()
			if metadata.get("category") == category:
				results.append(obj)
	return results

# Handle property changes (especially in editor)
func _set(property, value):
	if property in ["cube_size", "gutter", "grid_y", "map_name", "teleport_destinations"]:
		set(property, value)
		if Engine.is_editor_hint():
			generate_layout()
		return true
	return false
