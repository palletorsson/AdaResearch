# AnnotationCubeController.gd
# A utility cube that displays the current map's name and description
# Automatically loads info from the GridDataComponent JSON

extends Node3D
class_name AnnotationCubeController

@export var display_mode: String = "both"  # "name_only", "description_only", "both"
@export var text_scale: float = 1.0
@export var billboard_enabled: bool = true
@export var auto_update_on_map_load: bool = true
@export var pulse_on_update: bool = true

# Visual components
var mesh_instance: MeshInstance3D
var name_label: Label3D
var description_label: Label3D
var shader_material: ShaderMaterial

# Current map info
var current_map_name: String = ""
var current_description: String = ""

# Animation
var base_scale: Vector3
var is_animating: bool = false

func _ready():
	print("AnnotationCube: Initializing map info display cube")
	
	# Find visual components
	_setup_visual_components()
	
	# Connect to grid system for map data
	_connect_to_grid_system()
	
	# Initial display
	_update_display()

func _setup_visual_components():
	"""Setup mesh instance and labels"""
	
	# Find mesh instance
	mesh_instance = find_child("MeshInstance3D", true, false)
	if not mesh_instance:
		mesh_instance = find_child("CubeBaseMesh", true, false)
	
	if mesh_instance:
		base_scale = mesh_instance.scale
		shader_material = mesh_instance.material_override as ShaderMaterial
		print("AnnotationCube: Found mesh instance")
	
	# Find or create name label
	name_label = find_child("NameLabel", true, false)
	if not name_label:
		name_label = _create_label("NameLabel", Vector3(0, 0.8, 0))
		name_label.font_size = 48
		name_label.modulate = Color.CYAN
	
	# Find or create description label  
	description_label = find_child("DescriptionLabel", true, false)
	if not description_label:
		description_label = _create_label("DescriptionLabel", Vector3(0, 0.4, 0))
		description_label.font_size = 32
		description_label.modulate = Color.WHITE

func _create_label(label_name: String, position: Vector3) -> Label3D:
	"""Create a new 3D label"""
	var label = Label3D.new()
	label.name = label_name
	label.position = position
	
	if billboard_enabled:
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	
	label.outline_size = 4
	label.outline_color = Color.BLACK
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	
	add_child(label)
	return label

func _connect_to_grid_system():
	"""Connect to grid system to get map data"""
	# Wait for scene to be ready
	call_deferred("_find_grid_system")

func _find_grid_system():
	"""Find and connect to the grid system"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		# Connect to map loaded signal
		if grid_system.has_signal("map_loaded") and not grid_system.map_loaded.is_connected(_on_map_loaded):
			grid_system.map_loaded.connect(_on_map_loaded)
			print("AnnotationCube: Connected to GridSystem.map_loaded")
		
		# Get current map info
		_load_current_map_info(grid_system)
	else:
		print("AnnotationCube: WARNING - Could not find GridSystem")

func _find_node_by_class(node: Node, target_class_name: String) -> Node:
	"""Find node by class name"""
	if node.get_script() and node.get_script().get_global_name() == target_class_name:
		return node
	
	for child in node.get_children():
		var result = _find_node_by_class(child, target_class_name)
		if result:
			return result
	
	return null

func _on_map_loaded(map_name: String, format: String):
	"""Handle when a new map is loaded"""
	print("AnnotationCube: Map loaded - %s (%s)" % [map_name, format])
	
	# Find grid system to get data
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if grid_system:
		_load_current_map_info(grid_system)

func _load_current_map_info(grid_system):
	"""Load map info from grid system data component"""
	var data_component = grid_system.get_data_component()
	if not data_component:
		print("AnnotationCube: No data component found")
		return
	
	# Get map_info section directly from JSON
	if data_component.json_loader and data_component.json_loader.map_data:
		var map_info = data_component.json_loader.map_data.get("map_info", {})
		current_map_name = map_info.get("name", "Unknown Map")
		current_description = map_info.get("description", "No description available")
		
		print("AnnotationCube: Loaded from map_info - Name: '%s'" % current_map_name)
		print("AnnotationCube: Description: '%s'" % current_description)
	else:
		# Fallback to metadata method
		var metadata = data_component.get_map_metadata()
		current_map_name = metadata.get("name", "Unknown Map")
		current_description = metadata.get("description", "No description available")
		print("AnnotationCube: Loaded from metadata fallback")
	
	# Clean up description (remove redundant info)
	current_description = _clean_description(current_description)
	
	print("AnnotationCube: Loaded map info - '%s'" % current_map_name)
	
	# Update display
	_update_display()
	
	if pulse_on_update:
		_pulse_animation()

func _clean_description(description: String) -> String:
	"""Clean up description text for better display"""
	# Remove redundant map name from description
	if description.begins_with(current_map_name):
		description = description.substr(current_map_name.length()).strip_edges()
		if description.begins_with(" - "):
			description = description.substr(3)
	
	# Limit length for readability
	if description.length() > 80:
		description = description.substr(0, 77) + "..."
	
	return description

func _update_display():
	"""Update the label displays based on current mode"""
	match display_mode:
		"name_only":
			name_label.text = current_map_name
			name_label.visible = true
			description_label.visible = false
			
		"description_only":
			description_label.text = current_description
			description_label.visible = true
			name_label.visible = false
			
		"both":
			name_label.text = current_map_name
			description_label.text = current_description
			name_label.visible = true
			description_label.visible = true
	
	# Apply text scaling
	name_label.scale = Vector3.ONE * text_scale
	description_label.scale = Vector3.ONE * text_scale
	
	# Update cube color based on content
	_update_cube_color()

func _update_cube_color():
	"""Update cube color to indicate annotation status"""
	if not shader_material:
		return
	
	var color = Color.CYAN
	if current_map_name.is_empty():
		color = Color.GRAY  # No data
	elif current_map_name.contains("Tutorial"):
		color = Color.YELLOW  # Tutorial levels
	else:
		color = Color.CYAN  # Regular levels
	
	shader_material.set_shader_parameter("emissionColor", color)

func _pulse_animation():
	"""Pulse animation when info updates"""
	if not mesh_instance or is_animating:
		return
	
	is_animating = true
	var tween = create_tween()
	
	# Scale up then back down
	tween.tween_property(mesh_instance, "scale", base_scale * 1.2, 0.2)
	tween.tween_property(mesh_instance, "scale", base_scale, 0.2)
	
	await tween.finished
	is_animating = false

# Public API
func set_display_mode(mode: String):
	"""Change what information is displayed"""
	if mode in ["name_only", "description_only", "both"]:
		display_mode = mode
		_update_display()
		print("AnnotationCube: Display mode set to '%s'" % mode)

func set_text_scale(scale: float):
	"""Change the scale of the text labels"""
	text_scale = clamp(scale, 0.1, 3.0)
	_update_display()

func toggle_billboard():
	"""Toggle billboard mode for labels"""
	billboard_enabled = !billboard_enabled
	
	if name_label:
		name_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard_enabled else BaseMaterial3D.BILLBOARD_DISABLED
	
	if description_label:
		description_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED if billboard_enabled else BaseMaterial3D.BILLBOARD_DISABLED

func force_update():
	"""Force update the display"""
	_find_grid_system()

func get_current_info() -> Dictionary:
	"""Get current map information"""
	return {
		"name": current_map_name,
		"description": current_description,
		"display_mode": display_mode
	}
