# GridInteractableHandler.gd
extends RefCounted

# Reference to the grid system
var grid_system = null

# Interactable data
var interactable_data_instance = null
var interactable_objects = {}

# Tile effect trigger definitions from JSON
var tile_effect_definitions = {}

# Initialize with reference to grid system
func _init(parent_grid_system):
	grid_system = parent_grid_system

# Load interactable data for a specific map
func load_data(map_name: String) -> void:
	#print("GridInteractableHandler: Loading interactable data for map: %s" % map_name)
	
	interactable_data_instance = null
	tile_effect_definitions.clear()
	
	# Try loading JSON format first
	var json_path = GridCommon.MAPS_PATH + map_name + "/map_data.json"
	if ResourceLoader.exists(json_path):
		_load_json_data(json_path)
		return
	
	# Fallback to GDScript format
	var interactable_path = GridCommon.MAPS_PATH + map_name + "/interactable_data.gd"
	var fallback_used = false
	
	if ResourceLoader.exists(interactable_path):
		var interactable_data_script = load(interactable_path)
		if interactable_data_script:
			interactable_data_instance = interactable_data_script.new()
			#print("GridInteractableHandler: Loaded interactable data script: %s" % interactable_path)
		else:
			push_error("GridInteractableHandler: Failed to load interactable data script: %s" % interactable_path)
			fallback_used = true
	else:
		print("GridInteractableHandler: Interactable data script not found: %s - trying default" % interactable_path)
		fallback_used = true
	
	# Try default map if original failed
	if fallback_used and map_name != "default":
		var default_path = GridCommon.MAPS_PATH + "default/interactable_data.gd"
		if ResourceLoader.exists(default_path):
			var default_script = load(default_path)
			if default_script:
				interactable_data_instance = default_script.new()
				print("GridInteractableHandler: Using default interactable data as fallback")
			else:
				push_error("GridInteractableHandler: Failed to load default interactable data script")
		else:
			push_error("GridInteractableHandler: Default interactable data script not found: %s" % default_path)

func _load_json_data(json_path: String) -> void:
	"""Load interactable data from JSON format"""
	var file = FileAccess.open(json_path, FileAccess.READ)
	if not file:
		push_error("GridInteractableHandler: Could not open JSON file: %s" % json_path)
		return
	
	var json_string = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_string)
	
	if parse_result != OK:
		push_error("GridInteractableHandler: Failed to parse JSON: %s" % json.error_string)
		return
	
	var map_data = json.data
	
	# Extract interactable layer
	var interactable_layer = map_data.get("layers", {}).get("interactables", [])
	
	# Extract tile effect definitions
	tile_effect_definitions = map_data.get("tile_effect_definitions", {})
	
	# Create compatibility instance
	interactable_data_instance = JsonInteractableDataAdapter.new()
	interactable_data_instance.interactable_data = interactable_layer
	
	print("GridInteractableHandler: Loaded JSON data with %d tile effect definitions" % tile_effect_definitions.size())

# JSON adapter class for compatibility
class JsonInteractableDataAdapter:
	var interactable_data: Array = []

# Clear all interactable objects
func clear() -> void:
	for key in interactable_objects.keys():
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			interactable.queue_free()
	
	interactable_objects.clear()

# Apply interactable data to the grid
func apply_data() -> void:
	# Skip if interactable data instance isn't created
	if not interactable_data_instance:
		print("WARNING: GridInteractableHandler: Cannot apply interactable data, instance not created!")
		return
		
	#print("GridInteractableHandler: Applying interactable data")
	
	# Skip if algorithm registry is not yet loaded
	if grid_system.algorithm_registry.get_all_algorithm_ids().size() == 0:
		print("WARNING: GridInteractableHandler: Algorithm registry not loaded, skipping interactable placement")
		return
	
	# Check which property is available
	var has_layout_data = interactable_data_instance.get("layout_data") != null
	var has_interactable_data = interactable_data_instance.get("interactable_data") != null
	
	var interactable_layout
	if has_layout_data:
		interactable_layout = interactable_data_instance.layout_data
	elif has_interactable_data:
		interactable_layout = interactable_data_instance.interactable_data
	else:
		push_error("GridInteractableHandler: Interactable data script has no layout_data or interactable_data property!")
		return
	
	var total_size = grid_system.cube_size + grid_system.gutter
	var interactable_count = 0
	var tile_effect_trigger_count = 0
	
	#print("GridInteractableHandler: Interactable layout size: %d rows" % interactable_layout.size())
	
	for z in range(min(grid_system.grid_z, interactable_layout.size())):
		var row = interactable_layout[z]
		#print("GridInteractableHandler: Processing interactable row %d, length: %d" % [z, row.size()])
		
		for x in range(min(grid_system.grid_x, row.size())):
			var item_id = row[x].strip_edges()
			
			# If it's a valid item ID, place it
			if item_id != GridCommon.EMPTY_SPACE and item_id != '':
				#print("GridInteractableHandler: Found item ID: '%s' at position (%d, ?, %d)" % [item_id, x, z])
				
				# Check if it's a tile effect trigger
				if item_id.begins_with("trigger:"):
					var effect_type = item_id.substr(8)  # Remove "trigger:" prefix
					_place_tile_effect_trigger(x, z, effect_type, total_size)
					tile_effect_trigger_count += 1
				else:
					# Regular algorithm placement
					var algorithm_data = grid_system.algorithm_registry.get_algorithm(item_id)
					if algorithm_data and algorithm_data.size() > 0:
						# Find the highest occupied y position at this x,z coordinate
						var y_pos = 0
						for y in range(grid_system.grid_y-1, -1, -1):
							if grid_system.grid[x][y][z]:
								y_pos = y + 1  # Place interactable on top of the highest cube
								break
						
						# Check if there's a utility at this position and adjust height accordingly
						var utility_key = Vector3i(x, y_pos, z)
						if grid_system.utility_handler.has_utility_at(x, y_pos, z):
							y_pos += 1  # Place interactable on top of utility
						
						#print("GridInteractableHandler: Placing algorithm '%s' at position (%d, %d, %d)" % [item_id, x, y_pos, z])
						_place_algorithm(x, y_pos, z, item_id, total_size)
						interactable_count += 1
					else:
						print("WARNING: GridInteractableHandler: Algorithm ID '%s' not found in registry" % item_id)
	
	print("GridInteractableHandler: Added %d interactables and %d tile effect triggers to the grid" % [interactable_count, tile_effect_trigger_count])

# Place a tile effect trigger in the grid
func _place_tile_effect_trigger(x: int, z: int, effect_type: String, total_size: float) -> void:
	# Find surface level for placement
	var y_pos = 0
	for y in range(grid_system.grid_y-1, -1, -1):
		if grid_system.grid[x][y][z]:
			y_pos = y + 1  # Place trigger on top of the highest cube
			break
	
	# Check if there's a utility at this position and adjust height accordingly
	if grid_system.utility_handler.has_utility_at(x, y_pos, z):
		y_pos += 1  # Place trigger on top of utility
	
	var position = Vector3(x, y_pos, z) * total_size
	
	# Load the tile effect trigger scene
	var trigger_scene_path = "res://adaresearch/Common/Scripts/Grid/tile_effect_trigger.tscn"
	if not ResourceLoader.exists(trigger_scene_path):
		print("ERROR: TileEffectTrigger scene not found: %s" % trigger_scene_path)
		return
	
	var trigger_scene = load(trigger_scene_path)
	var trigger_object = trigger_scene.instantiate()
	
	if not trigger_object:
		print("ERROR: Failed to instantiate TileEffectTrigger scene")
		return
	
	# Configure the trigger
	trigger_object.position = position
	trigger_object.effect_type = effect_type
	
	# Apply effect configuration from JSON definitions
	if tile_effect_definitions.has(effect_type):
		var effect_config = tile_effect_definitions[effect_type]
		trigger_object.set_effect_config(effect_config)
		print("GridInteractableHandler: Applied effect config for '%s'" % effect_type)
	
	# Connect trigger signals
	if trigger_object.has_signal("effect_triggered"):
		trigger_object.connect("effect_triggered", _on_tile_effect_triggered)
	
	if trigger_object.has_signal("trigger_activated"):
		trigger_object.connect("trigger_activated", _on_trigger_activated)
	
	# Add to scene
	grid_system.add_child(trigger_object)
	
	# Set owner for editor
	if grid_system.get_tree() and grid_system.get_tree().edited_scene_root:
		trigger_object.owner = grid_system.get_tree().edited_scene_root
	
	# Store reference
	interactable_objects[Vector3i(x, y_pos, z)] = trigger_object
	
	print("GridInteractableHandler: Placed tile effect trigger '%s' at (%d, %d, %d)" % [effect_type, x, y_pos, z])

# Place an algorithm in the grid
func _place_algorithm(x: int, y: int, z: int, algorithm_id: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	
	# Get the algorithm scene from the registry
	#print("GridInteractableHandler: Loading algorithm scene for ID '%s'" % algorithm_id)
	var algorithm_object = grid_system.algorithm_registry.get_algorithm_scene(algorithm_id)
	
	if algorithm_object:
		algorithm_object.position = position
		
		# Get the algorithm metadata to access the name
		var algorithm_metadata = grid_system.algorithm_registry.get_algorithm(algorithm_id)
		var algorithm_name = "Unknown Algorithm"
		if algorithm_metadata != null and algorithm_metadata.has("name"):
			algorithm_name = algorithm_metadata.get("name")
		
		# Find and update the Label3D if it exists
		var label = algorithm_object.find_child("id_info_Label3D")
		if label and label is Label3D:
			label.text = str(algorithm_id) + ": " + str(algorithm_name)
			#print("GridInteractableHandler: Updated Label3D text to: %s" % label.text)
		
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
		
		grid_system.add_child(algorithm_object)
		
		# Set owner for editor
		if grid_system.get_tree() and grid_system.get_tree().edited_scene_root:
			algorithm_object.owner = grid_system.get_tree().edited_scene_root
			
		interactable_objects[Vector3i(x, y, z)] = algorithm_object
		#print("GridInteractableHandler: Successfully placed algorithm '%s' at (%d, %d, %d)" % [algorithm_id, x, y, z])
	else:
		print("WARNING: GridInteractableHandler: Attempted to place algorithm with ID '%s' but the scene could not be loaded" % algorithm_id)

# Handle tile effect trigger events
func _on_tile_effect_triggered(effect_type: String, position: Vector3i, config: Dictionary):
	print("GridInteractableHandler: Tile effect '%s' triggered at %s" % [effect_type, position])
	
	# Forward to grid system for potential logging or additional handling
	grid_system._on_interactable_activated("trigger:" + effect_type, position, {"effect_config": config})

func _on_trigger_activated(trigger: TileEffectTrigger):
	var info = trigger.get_trigger_info()
	print("GridInteractableHandler: Trigger activated - %s" % info)

# Handle algorithm interaction
func _on_algorithm_interact(algorithm_id: String, position: Vector3i, data = null) -> void:
	# Forward the signal to the grid system
	grid_system._on_interactable_activated(algorithm_id, position, data)

# Handle algorithm event
func _on_algorithm_event(event_name: String, event_data, algorithm_id: String, position: Vector3i) -> void:
	# Handle algorithm-specific events
	pass
	#print("GridInteractableHandler: Algorithm event: %s from ID %s at position %s" % [event_name, algorithm_id, position])
	
	# Forward the event to the grid system if needed
	# You can add custom logic here to handle different event types

# Get an interactable object at a specific position
func get_interactable_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	if interactable_objects.has(key):
		return interactable_objects[key]
	return null

# Remove an interactable object at a specific position
func remove_interactable_at(x: int, y: int, z: int) -> void:
	var key = Vector3i(x, y, z)
	if interactable_objects.has(key):
		var interactable = interactable_objects[key]
		if is_instance_valid(interactable):
			interactable.queue_free()
		interactable_objects.erase(key)

# Register an interactable object at a specific position
func register_interactable(position: Vector3i, interactable: Node3D) -> void:
	interactable_objects[position] = interactable

# Get all interactable objects of a specific category
func get_interactables_by_category(category: String) -> Array:
	var results = []
	for key in interactable_objects.keys():
		var obj = interactable_objects[key]
		if obj and obj.has_method("get_algorithm_metadata"):
			var metadata = obj.get_algorithm_metadata()
			if metadata.get("category") == category:
				results.append(obj)
	return results

# Get all tile effect triggers
func get_tile_effect_triggers() -> Array:
	var results = []
	for key in interactable_objects.keys():
		var obj = interactable_objects[key]
		if obj is TileEffectTrigger:
			results.append(obj)
	return results

# Get tile effect trigger at position
func get_tile_effect_trigger_at(x: int, y: int, z: int) -> TileEffectTrigger:
	var obj = get_interactable_at(x, y, z)
	if obj is TileEffectTrigger:
		return obj
	return null
