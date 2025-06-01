# GridExplainHandler.gd
extends RefCounted

# Reference to the grid system
var grid_system = null

# Explanation data
var explain_data_instance = null
var explain_markers = {}
var explain_lookup = {}

# Initialize with reference to grid system
func _init(parent_grid_system):
	grid_system = parent_grid_system

# Load explanation data for a specific map
func load_data(map_name: String) -> void:
	print("GridExplainHandler: Loading explanation data for map: %s" % map_name)
	
	explain_data_instance = null
	
	# Load explanation data script
	var explain_path =  GridCommon.MAPS_PATH + map_name + "/explain_data.gd"
	var fallback_used = false
	
	if ResourceLoader.exists(explain_path):
		var explain_data_script = load(explain_path)
		if explain_data_script:
			explain_data_instance = explain_data_script.new()
			print("GridExplainHandler: Loaded explanation data script: %s" % explain_path)
			# Build lookup dictionary for quick access
			if explain_data_instance.has_method("get_explanation") and explain_data_instance.EXPLANATIONS_JSON:
				print("GridExplainHandler: Metod get_explanation ok")
				for key in explain_data_instance.EXPLANATIONS_JSON.keys():
					print("GridExplainHandler key:" + str(key))
					explain_lookup[key] = explain_data_instance.EXPLANATIONS_JSON[key]
				print("GridExplainHandler: Built explanation lookup with %d entries" % explain_lookup.size())
		else:
			push_error("GridExplainHandler: Failed to load explanation data script: %s" % explain_path)
			fallback_used = true
	else:
		print("GridExplainHandler: Explanation data script not found: %s - trying default" % explain_path)
		fallback_used = true
	
	# Try default map if original failed
	if fallback_used and map_name != "default":
		var default_path = GridCommon.MAPS_PATH + "default/explain_data.gd"
		if ResourceLoader.exists(default_path):
			var default_script = load(default_path)
			if default_script:
				explain_data_instance = default_script.new()
				print("GridExplainHandler: Using default explanation data as fallback")
				# Build lookup dictionary for default data
				if explain_data_instance.has_method("get_explanation") and explain_data_instance.has("EXPLANATIONS_JSON"):
					for key in explain_data_instance.EXPLANATIONS_JSON.keys():
						explain_lookup[key] = explain_data_instance.EXPLANATIONS_JSON[key]
					print("GridExplainHandler: Built default explanation lookup with %d entries" % explain_lookup.size())
			else:
				push_error("GridExplainHandler: Failed to load default explanation data script")
		else:
			push_error("GridExplainHandler: Default explanation data script not found: %s" % default_path)

# Clear all explanation markers
func clear() -> void:
	for key in explain_markers.keys():
		var marker = explain_markers[key]
		if is_instance_valid(marker):
			marker.queue_free()
	
	explain_markers.clear()

# Apply explanation data to the grid
func apply_data() -> void:
	# Skip if explanation data instance isn't created
	if not explain_data_instance:
		push_error("GridExplainHandler: Cannot apply explanation data, instance not created!")
		return
		
	print("GridExplainHandler: Applying explanation data")
	
	# Check map for specific explanation layout
	var explain_layout = _get_explain_layout()
	var total_size = grid_system.cube_size + grid_system.gutter
	var marker_count = 0
	
	if explain_layout:
		# Place markers based on layout
		marker_count = _place_markers_from_layout(explain_layout, total_size)
	else:
		# Place markers based on task positions as fallback
		marker_count = _place_markers_from_tasks(total_size)
	
	print("GridExplainHandler: Added %d explanation markers to the grid" % marker_count)

# Get explanation layout for current map
func _get_explain_layout():
	# Try to find explanation layout in map-specific data
	# This would need to be implemented based on your map structure
	# For now, returns null to use the fallback
	return null

# Place explanation markers based on layout
func _place_markers_from_layout(explain_layout, total_size: float) -> int:
	var marker_count = 0
	
	# Place markers from layout data
	# Implementation would depend on your layout format
	
	return marker_count

# Place markers based on task positions as fallback
func _place_markers_from_tasks(total_size: float) -> int:
	var marker_count = 0
	
	# No task system available, skip marker placement
	print("GridExplainHandler: Task system not available, skipping task-based marker placement")
	
	return marker_count

# Place an explanation marker at a specific position
func _place_explain_marker(x: int, y: int, z: int, lookup_name: String, total_size: float) -> void:
	var position = Vector3(x, y, z) * total_size
	
	# Create marker
	var marker = _create_marker(lookup_name)
	marker.position = position
	grid_system.add_child(marker)
	
	# Store in marker map
	explain_markers[Vector3i(x, y, z)] = marker
	
	print("GridExplainHandler: Added explanation marker '%s' at (%d, %d, %d)" % [lookup_name, x, y, z])

# Create an explanation marker
func _create_marker(lookup_name: String) -> Node3D:
	var marker = MeshInstance3D.new()
	marker.name = "ExplainMarker_" + lookup_name
	
	# Create a distinctive mesh for explanation markers
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.2
	cylinder.bottom_radius = 0.2
	cylinder.height = 0.1
	marker.mesh = cylinder
	
	# Create a material
	var material = StandardMaterial3D.new()
	material.emission_enabled = true
	material.emission = Color(0.0, 0.8, 1.0)  # Cyan/blue glow
	material.emission_energy = 2.0
	marker.material_override = material
	
	# Add interactivity
	var area = Area3D.new()
	marker.add_child(area)
	
	var collision_shape = CollisionShape3D.new()
	var sphere_shape = SphereShape3D.new()
	sphere_shape.radius = 0.5
	collision_shape.shape = sphere_shape
	area.add_child(collision_shape)
	
	# Connect signal for interactivity
	area.input_event.connect(_on_explain_area_input_event.bind(lookup_name))
	
	return marker

# Handle interaction with explanation markers
func _on_explain_area_input_event(camera, event, click_position, normal, shape_idx, lookup_name: String) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		show_explanation(lookup_name)

# Show explanation for a specific lookup name
func show_explanation(lookup_name: String) -> void:
	if not explain_lookup.has(lookup_name):
		print("GridExplainHandler: No explanation found for '%s'" % lookup_name)
		return
		
	var explanation_data = explain_lookup[lookup_name]
	print("GridExplainHandler: Showing explanation for '%s'" % lookup_name)
	

# Format explanation content
func _format_content(content: Dictionary) -> String:
	var formatted_text = ""
	
	# Sort keys numerically
	var keys = content.keys()
	keys.sort_custom(func(a, b): return int(a) < int(b))
	
	# Append content in order
	for key in keys:
		formatted_text += content[key] + "\n\n"
	
	return formatted_text.strip_edges()

# Get explanation data for a specific lookup name
func get_explanation(lookup_name: String) -> Dictionary:
	if explain_lookup.has(lookup_name):
		return explain_lookup[lookup_name]
	return {}

# Public method to show an explanation directly
func show_explanation_for_lookup(lookup_name: String) -> bool:
	if explain_lookup.has(lookup_name):
		show_explanation(lookup_name)
		return true
	return false
