# GridTaskHandler.gd
extends RefCounted

# Reference to the grid system
var grid_system = null

# Task data
var task_json_data = []
var task_layout_data = []
var task_markers = {}
var task_lookup = {}

# Initialize with reference to grid system
func _init(parent_grid_system):
	grid_system = parent_grid_system

# Load task data for a specific map
func load_data(map_name: String = "") -> void:
	#print("GridTaskHandler: Loading task data")
	
	task_json_data = []
	task_layout_data = []
	task_lookup = {}
	
	# Load global task definitions from task_data.gd
	_load_global_task_definitions()
	
	# Load map-specific task layout
	if not map_name.is_empty():
		_load_map_specific_task_layout(map_name)
	
	#print("GridTaskHandler: Task data loaded")

# Load global task definitions from the main task_data.gd file
func _load_global_task_definitions() -> void:
	# Load artifact definitions from file
	if ResourceLoader.exists(GridCommon.ARTIFACT_DATA_PATH):
		var artifact_data_script = load(GridCommon.ARTIFACT_DATA_PATH)
		if artifact_data_script:
			var artifact_data_instance = artifact_data_script.new()
			
			# Check if ARTIFACTS_JSON exists using get()
			if artifact_data_instance.get("ARTIFACTS_JSON") != null:
				task_json_data = artifact_data_instance.ARTIFACTS_JSON
				#print("GridTaskHandler: Loaded %d artifact definitions from %s" % [task_json_data.size(), GridCommon.ARTIFACT_DATA_PATH])
				
				# Build task lookup dictionary
				for task in task_json_data:
					if task.has("lookup_name"):
						task_lookup[task["lookup_name"]] = task
				
				print("GridTaskHandler: Task lookup dictionary built with %d entries" % task_lookup.size())
			else:
				push_error("GridTaskHandler: ARTIFACTS_JSON constant not found in artifact data script")
			
			# Clean up the instance
			if artifact_data_instance.has_method("queue_free"):
				artifact_data_instance.queue_free()
		else:
			push_error("GridTaskHandler: Failed to instantiate artifact data script")
	else:
		push_error("GridTaskHandler: Artifact data script not found at %s" % GridCommon.ARTIFACT_DATA_PATH)

# Load map-specific task layout from the map's task_data.gd file
func _load_map_specific_task_layout(map_name: String) -> void:
	var map_artifact_data_path = GridCommon.MAPS_PATH + map_name + "/artifact_data.gd"
	
	if ResourceLoader.exists(map_artifact_data_path):
		var map_artifact_data_script = load(map_artifact_data_path)
		if map_artifact_data_script:
			var map_artifact_data_instance = map_artifact_data_script.new()
			
			# Check if artifact_data array exists using get()
			if map_artifact_data_instance.get("artifact_data") != null:
				task_layout_data = map_artifact_data_instance.artifact_data
				#print("GridTaskHandler: Loaded map-specific artifact layout from %s" % map_artifact_data_path)
				#print("GridTaskHandler: Artifact layout has %d rows" % task_layout_data.size())
			else:
				push_error("GridTaskHandler: 'artifact_data' array not found in map artifact data script")
			
			# Clean up the instance
			if map_artifact_data_instance.has_method("queue_free"):
				map_artifact_data_instance.queue_free()
		else:
			push_error("GridTaskHandler: Failed to instantiate map artifact data script")
	else:
		print("GridTaskHandler: No map-specific artifact layout found at %s, using global positions instead" % map_artifact_data_path)

# Clear all task markers
func clear() -> void:
	for key in task_markers.keys():
		var marker = task_markers[key]
		if is_instance_valid(marker):
			marker.queue_free()
	
	task_markers.clear()

# Apply task data to the grid
func apply_data() -> void:
	#print("GridTaskHandler: Applying task data to grid")
	
	var total_size = grid_system.cube_size + grid_system.gutter
	var task_count = 0
	
	# If we have a map-specific task layout, use it to place tasks
	if task_layout_data.size() > 0:
		task_count = _apply_map_specific_layout(total_size)
	else:
		# Otherwise fall back to using global task positions
		task_count = _apply_global_positions(total_size)
	
	#print("GridTaskHandler: Added %d task markers to the grid" % task_count)
	
	# Connect to task system signals if available
	connect_to_task_system()

# Apply tasks based on the map-specific layout
func _apply_map_specific_layout(total_size: float) -> int:
	var task_count = 0
	
	# Iterate through the task layout grid
	for z in range(task_layout_data.size()):
		var row = task_layout_data[z]
		for x in range(row.size()):
			var task_lookup_name = row[x].strip_edges()
			
			# Skip empty spaces
			if task_lookup_name == " " or task_lookup_name.is_empty():
				continue
			
			# Check if this task exists in our lookup
			if task_lookup.has(task_lookup_name):
				# Find the appropriate y position (top of structure or utility)
				var y_pos = _find_highest_position_at(x, z)
				
				#print("GridTaskHandler: Placing task '%s' at grid position (%d, %d, %d)" % [task_lookup_name, x, y_pos, z])
				
				# Check if there's already an interactable at this position
				if not grid_system.interactable_handler.get_interactable_at(x, y_pos, z):
					# Place a task marker using the task definition
					_place_task_marker(x, y_pos, z, task_lookup_name, task_lookup[task_lookup_name])
					task_count += 1
				else:
					print("GridTaskHandler: Position (%d, %d, %d) already has an interactable, skipping task marker" % [x, y_pos, z])
			else:
				push_error("GridTaskHandler: Task with lookup name '%s' not found in task definitions" % task_lookup_name)
	
	return task_count

# Apply tasks based on their global positions
func _apply_global_positions(total_size: float) -> int:
	var task_count = 0
	
	# Place task markers for each task using their world position
	for task in task_json_data:
		if task.has("x_position") and task.has("y_position") and task.has("z_position") and task.has("lookup_name"):
			var world_pos = Vector3(task["x_position"], task["y_position"], task["z_position"])
			var grid_pos = GridCommon.world_to_grid_position(world_pos, grid_system.cube_size, grid_system.gutter)
			
			#print("GridTaskHandler: Processing task '%s' at grid position (%d, %d, %d)" % [task["lookup_name"], grid_pos.x, grid_pos.y, grid_pos.z])
			
			# Check if there's already an interactable at this position
			if not grid_system.interactable_handler.get_interactable_at(grid_pos.x, grid_pos.y, grid_pos.z):
				# Place a task marker
				_place_task_marker(grid_pos.x, grid_pos.y, grid_pos.z, task["lookup_name"], task)
				task_count += 1
			else:
				print("GridTaskHandler: Position (%d, %d, %d) already has an interactable, skipping task marker" % [grid_pos.x, grid_pos.y, grid_pos.z])
	
	return task_count

# Find the highest y position at a given x,z coordinate
func _find_highest_position_at(x: int, z: int) -> int:
	var y_pos = 0
	
	# Check for structure
	for y in range(grid_system.grid_y-1, -1, -1):
		if GridCommon.is_position_in_bounds(x, y, z, grid_system.grid_x, grid_system.grid_y, grid_system.grid_z):
			if grid_system.grid[x][y][z]:
				y_pos = y + 1  # Place on top of highest structure
				break
	
	# Check for utility and place on top if found
	if grid_system.utility_handler.has_utility_at(x, y_pos, z):
		y_pos += 1
	
	return y_pos
# Modified _place_task_marker function for GridTaskHandler.gd

# Place a task marker in the grid
func _place_task_marker(x: int, y: int, z: int, task_lookup_name: String, task_data: Dictionary) -> void:
	var position = GridCommon.grid_to_world_position(Vector3i(x, y, z), grid_system.cube_size, grid_system.gutter)
	var marker = null
	
	# Check if task has a custom scene
	if task_data.has("scene") and not task_data["scene"].is_empty():
		# Try to load the custom scene
		var scene_path = task_data["scene"]
		if ResourceLoader.exists(scene_path):
			var scene_resource = load(scene_path)
			if scene_resource:
				marker = scene_resource.instantiate()
				#print("GridTaskHandler: Loaded custom scene for task '%s': %s" % [task_lookup_name, scene_path])
				
				# Initialize the scene with task data if it supports it
				if marker.has_method("initialize_with_task_data"):
					marker.initialize_with_task_data(task_data)
			else:
				push_error("GridTaskHandler: Failed to load scene for task '%s': %s" % [task_lookup_name, scene_path])
		else:
			push_error("GridTaskHandler: Scene file not found for task '%s': %s" % [task_lookup_name, scene_path])
	
	# If no scene was loaded (or loading failed), create a default marker
	if not marker:
		marker = _create_default_task_marker(task_data)
		#print("GridTaskHandler: Created default marker for task '%s'" % task_lookup_name)
	
	# Set position
	marker.position = position
	
	# Add interaction capability if the marker doesn't already have it
	if not _has_interaction_capability(marker):
		_add_interaction_capability(marker, task_lookup_name, Vector3i(x, y, z), task_data)
	
	# Add to scene
	grid_system.add_child(marker)
	
	# Store in task markers dictionary
	task_markers[Vector3i(x, y, z)] = marker
	
	# Also register in the interactable_objects dictionary
	grid_system.interactable_handler.register_interactable(Vector3i(x, y, z), marker)
	
	#print("GridTaskHandler: Added task marker for '%s' at position (%d, %d, %d)" % [task_lookup_name, x, y, z])

# Create a default task marker when no custom scene is provided
func _create_default_task_marker(task_data: Dictionary) -> MeshInstance3D:
	var marker = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = 0.2
	sphere.height = 0.4
	marker.mesh = sphere
	
	# Create a material with emission for the marker
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = GridCommon.TASK_STATE["default"]["color"]
	material.emission_energy = GridCommon.TASK_STATE["default"]["energy"]
	marker.material_override = material
	
	# Add a label with task name
	var label = Label3D.new()
	label.text = task_data.get("artifact_name", "Unknown Artifact")
	label.position = Vector3(0, 0.3, 0)  # Position above the marker
	label.font_size = 14
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.add_child(label)
	
	return marker

# Check if a node already has interaction capability
func _has_interaction_capability(node: Node) -> bool:
	# Check if the node or any of its children is an Area3D with input_event connected
	if node is Area3D and node.has_signal("input_event") and node.get_signal_connection_list("input_event").size() > 0:
		return true
	
	# Check children recursively
	for child in node.get_children():
		if _has_interaction_capability(child):
			return true
	
	return false

# Add interaction capability to a marker
func _add_interaction_capability(marker: Node, task_lookup_name: String, grid_pos: Vector3i, task_data: Dictionary) -> void:
	var area = Area3D.new()
	marker.add_child(area)
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	
	# Connect interaction signal
	area.input_event.connect(_on_task_marker_input_event.bind(task_lookup_name, grid_pos, task_data))
# The rest of the code (event handlers, etc.) remains the same
# Handle interaction with task markers
func _on_task_marker_input_event(camera, event, position, normal, shape_idx, task_lookup_name: String, grid_pos: Vector3i, task_data: Dictionary) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		#print("GridTaskHandler: Task marker clicked: %s at %s" % [task_lookup_name, grid_pos])
		
		# Emit the interactable_activated signal through the grid system
		grid_system.emit_signal("interactable_activated", task_lookup_name, grid_pos, task_data)

# Update task marker appearance based on state
func update_marker_appearance(lookup_name: String, state: String) -> void:
	# Find the task marker
	for key in task_markers.keys():
		var marker = task_markers[key]
		
		# Find Label3D child with task name
		for child in marker.get_children():
			if child is Label3D:
				var task = get_task_by_lookup_name(lookup_name)
				if task and task.has("task_name") and child.text == task["task_name"]:
					# Found the marker, update its appearance
					_update_marker_material(marker, state)
					#print("GridTaskHandler: Updated appearance of task marker '%s' to state '%s'" % [lookup_name, state])
					return

# Update the material of a task marker based on its state
func _update_marker_material(marker: Node, state: String) -> void:
	if marker is MeshInstance3D:
		# Create a new material based on the state
		var material = StandardMaterial3D.new()
		material.emission_enabled = true
		
		# Get state properties from GridCommon
		if GridCommon.TASK_STATE.has(state):
			material.emission = GridCommon.TASK_STATE[state]["color"]
			material.emission_energy = GridCommon.TASK_STATE[state]["energy"]
		else:
			material.emission = GridCommon.TASK_STATE["default"]["color"]
			material.emission_energy = GridCommon.TASK_STATE["default"]["energy"]
		
		marker.material_override = material

# Connect to TaskSystem signals
func connect_to_task_system() -> void:
	if Engine.has_singleton("TaskSystem"):
		var task_manager = TaskSystem.get_task_manager()
		if task_manager:
			# Connect to task activated signal
			if task_manager.has_signal("task_activated") and not task_manager.is_connected("task_activated", _on_task_activated):
				task_manager.connect("task_activated", _on_task_activated)
			
			# Connect to task completed signal
			if task_manager.has_signal("task_completed") and not task_manager.is_connected("task_completed", _on_task_completed):
				task_manager.connect("task_completed", _on_task_completed)
			
			#print("GridTaskHandler: Connected to TaskSystem signals")

# Handle task activation
func _on_task_activated(task) -> void:
	if task and task.has_method("get_lookup_name"):
		update_marker_appearance(task.get_lookup_name(), "active")

# Handle task completion
func _on_task_completed(task) -> void:
	if task and task.has_method("get_lookup_name"):
		update_marker_appearance(task.get_lookup_name(), "completed")

# Get task at a specific grid position
func get_task_at(x: int, y: int, z: int) -> Dictionary:
	var key = Vector3i(x, y, z)
	if task_markers.has(key):
		# Find which task this marker represents
		var marker = task_markers[key]
		for label in marker.get_children():
			if label is Label3D:
				for task in task_json_data:
					if task.has("task_name") and label.text == task["task_name"]:
						return task
	return {}

# Get all tasks
func get_all_tasks() -> Array:
	return task_json_data

# Get a task by its lookup name
func get_task_by_lookup_name(lookup_name: String) -> Dictionary:
	if task_lookup.has(lookup_name):
		return task_lookup[lookup_name]
	return {}

# Update all task markers based on their states in the TaskSystem
func update_all_markers() -> void:
	if not Engine.has_singleton("TaskSystem"):
		return
	
	#print("GridTaskHandler: Updating all task markers")
	
	# Update each task marker
	for task in task_json_data:
		if task.has("lookup_name"):
			var lookup_name = task["lookup_name"]
			
			# Determine the task state
			var state = "default"
			
			if TaskSystem.is_task_completed(lookup_name):
				state = "completed"
			elif TaskSystem.is_task_active(lookup_name):
				state = "active"
			
			# Update the marker
			update_marker_appearance(lookup_name, state)
