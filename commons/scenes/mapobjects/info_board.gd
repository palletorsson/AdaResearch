# InfoBoard.gd
# Map-specific info board that loads data from map_data.json
extends Node3D

# References to UI elements
@onready var level_number_label = $Viewport/InfoBoardUI/MainPanel/LevelNumber
@onready var level_id_label = $Viewport/InfoBoardUI/MainPanel/LevelID
@onready var title_label = $Viewport/InfoBoardUI/MainPanel/Title
@onready var summary_label = $Viewport/InfoBoardUI/MainPanel/Summary
@onready var barcode = $Viewport/InfoBoardUI/MainPanel/Barcode
@onready var xp_label = $Viewport/InfoBoardUI/MainPanel/XPLabel
@onready var health_label = $Viewport/InfoBoardUI/MainPanel/HealthLabel
@onready var icons_container = $Viewport/InfoBoardUI/MainPanel/IconsContainer

# Animation settings
@export var base_display_time: float = 5.0  # Base time in seconds for displaying each text section
@export var chars_per_second: float = 15.0  # Reading speed estimation
@export var min_display_time: float = 4.0  # Minimum display time for very short sections
@export var max_display_time: float = 12.0  # Maximum display time for long sections
@export var fade_duration: float = 0.75  # Fade transition duration

# Animation state
var current_section: int = 0
var is_animating: bool = false
var summary_sections = []
var player_in_range: bool = true  # Default to true for testing
var animation_paused: bool = false

# Map data
var map_data: Dictionary = {}
var map_name: String = ""

# Icon textures dictionary using your actual icons
var icon_textures = {
	"ai": preload("res://commons/icons/ai-icon.png"),
	"array": preload("res://commons/icons/array-icon.png"),
	"camera": preload("res://commons/icons/camera-icon.png"),
	"collision": preload("res://commons/icons/collision-icon.png"),
	"cube": preload("res://commons/icons/cube-icon.png"),
	"danger": preload("res://commons/icons/danger-icon.png"),
	"entropy": preload("res://commons/icons/entropy-icon.png"),
	"flow-field": preload("res://commons/icons/flow-field-icon.png"),
	"genetic": preload("res://commons/icons/genetic-icon.png"),
	"gravity": preload("res://commons/icons/gravity-icon.png"),
	"line": preload("res://commons/icons/line-icon.png"),
	"material": preload("res://commons/icons/material-icon.png"),
	"neural-net": preload("res://commons/icons/neural-net-icon.png"),
	"noise": preload("res://commons/icons/noise-icon.png"),
	"particles": preload("res://commons/icons/particles-icon.png"),
	"pathfinding": preload("res://commons/icons/pathfinding-icon.png"),
	"physics": preload("res://commons/icons/physics-icon.png"),
	"plane": preload("res://commons/icons/plane-icon.png"),
	"point": preload("res://commons/icons/point-icon.png"),
	"procedural": preload("res://commons/icons/procedural-icon.png"),
	"queer": preload("res://commons/icons/queer-icon.png"),
	"random": preload("res://commons/icons/random-icon.png"),
	"recursion": preload("res://commons/icons/recursion-icon.png"),
	"shader": preload("res://commons/icons/shader-icon.png"),
	"simulation": preload("res://commons/icons/simulation-icon.png"),
	"texture": preload("res://commons/icons/texture-icon.png"),
	"time": preload("res://commons/icons/time-icon.png"),
	"vector": preload("res://commons/icons/vector-icon.png"),
	"xp": preload("res://commons/icons/xp-icon.png")
}

# Reference to the grid system - will be found dynamically
var grid_system: Node = null

func _ready():
	# Connect to XP signal for updates
	if get_node_or_null("/root/GameManager") != null:
		GameManager.connect("xp_updated", Callable(self, "_update_xp_display"))
		_update_xp_display(GameManager.get_xp())
		_update_health_display(100)  # Assuming full health at start
	
	# Defer loading until grid system is ready
	call_deferred("_initialize_info_board")

func _initialize_info_board():
	"""Initialize info board after grid system is ready"""
	# Wait a few frames to ensure grid system is fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Load map data from the current map
	_load_map_data()

# Find the grid system in the scene tree
func _find_grid_system() -> Node:
	# Try different common paths and names for the grid system
	var potential_paths = [
		"../../multiLayerGrid",
		"../../GridSystem", 
		"../GridSystem",
		"../../LabGridSystem",
		"../LabGridSystem"
	]
	
	# Try direct path references first
	for path in potential_paths:
		var node = get_node_or_null(path)
		if node and (node.get_class() == "GridSystem" or node.get_class() == "LabGridSystem"):
			print("InfoBoard: Found grid system at path: " + path)
			return node
	
	# Try finding by class name in the scene tree
	var scene_root = get_tree().current_scene
	if scene_root:
		var grid_systems = _find_nodes_by_class_name(scene_root, "GridSystem")
		if grid_systems.size() > 0:
			print("InfoBoard: Found grid system by class search")
			return grid_systems[0]
		
		var lab_grid_systems = _find_nodes_by_class_name(scene_root, "LabGridSystem")
		if lab_grid_systems.size() > 0:
			print("InfoBoard: Found lab grid system by class search")
			return lab_grid_systems[0]
	
	# Try finding in parent hierarchy
	var current = get_parent()
	while current:
		if current.get_class() == "GridSystem" or current.get_class() == "LabGridSystem":
			print("InfoBoard: Found grid system in parent hierarchy")
			return current
		current = current.get_parent()
	
	print("InfoBoard: No grid system found in scene tree")
	return null

# Helper function to find nodes by class name
func _find_nodes_by_class_name(node: Node, target_class: String) -> Array:
	var results = []
	if node.get_class() == target_class:
		results.append(node)
	
	for child in node.get_children():
		results.append_array(_find_nodes_by_class_name(child, target_class))
	
	return results

# Load map data from the current map's map_data.json
func _load_map_data():
	# Find the grid system dynamically
	grid_system = _find_grid_system()
	
	if not grid_system:
		push_error("InfoBoard: No grid system found!")
		_show_fallback_info()
		return
	
	# Get the map_name from the grid system
	map_name = grid_system.map_name
	print("InfoBoard: Found grid system: " + str(grid_system.name))
	print("InfoBoard: Loading map data for: " + map_name)
	
	# Load map data from map_data.json
	var map_data_path = "res://commons/maps/" + map_name + "/map_data.json"
	print("InfoBoard: Looking for map data at: " + map_data_path)
	
	if not FileAccess.file_exists(map_data_path):
		push_error("InfoBoard: map_data.json not found at: " + map_data_path)
		_show_fallback_info()
		return
	
	var file = FileAccess.open(map_data_path, FileAccess.READ)
	if not file:
		push_error("InfoBoard: Could not open map_data.json")
		_show_fallback_info()
		return
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("InfoBoard: Failed to parse map_data.json")
		_show_fallback_info()
		return
	
	map_data = json.data
	print("InfoBoard: Successfully loaded map data for: " + map_name)
	print("InfoBoard: Map data keys: " + str(map_data.keys()))
	_update_info_board_with_map_data()

# Show fallback info when map data cannot be loaded
func _show_fallback_info():
	level_number_label.text = "??"
	level_id_label.text = "Unknown Map"
	title_label.text = "Map Information Unavailable"
	summary_label.text = "Unable to load map data. Please check the map configuration."
	barcode.text = "||||||||||||||||||||||||||"
	start_animation()

# Update the info board with map-specific data
func _update_info_board_with_map_data():
	if map_data.is_empty():
		push_error("InfoBoard: No map data available")
		return
	
	print("InfoBoard: Updating info board with map data...")
	
	var map_info = map_data.get("map_info", {})
	var metadata = map_info.get("metadata", {})
	
	print("InfoBoard: Map info keys: " + str(map_info.keys()))
	print("InfoBoard: Metadata keys: " + str(metadata.keys()))
	
	# Extract map information
	var map_name_display = map_info.get("name", "Unknown Map")
	var description = map_info.get("description", "No description available")
	var difficulty = metadata.get("difficulty", "unknown")
	var category = metadata.get("category", "unknown")
	var estimated_time = metadata.get("estimated_time", "Unknown")
	var learning_objectives = metadata.get("learning_objectives", [])
	
	print("InfoBoard: Map name: " + map_name_display)
	print("InfoBoard: Description: " + description)
	print("InfoBoard: Category: " + category)
	print("InfoBoard: Difficulty: " + difficulty)
	
	# Update labels with map information
	level_number_label.text = "01"  # Could be enhanced to show map number if needed
	level_id_label.text = category + "/" + map_name_display
	title_label.text = map_name_display
	
	# Update barcode
	barcode.text = "||||||||||||||||||||||||||"
	
	# Clear and repopulate icons based on map metadata
	for child in icons_container.get_children():
		child.queue_free()
	
	# Add icons based on map category and difficulty
	var map_icons = _get_icons_for_map(category, difficulty)
	
	for icon_name in map_icons:
		if icon_textures.has(icon_name):
			var icon = TextureRect.new()
			icon.texture = icon_textures[icon_name]
			icon.expand = true
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(50, 50)
			icons_container.add_child(icon)
	
	# Create summary sections from map data
	_create_summary_from_map_data(map_info, metadata)
	start_animation()

# Get appropriate icons for a map based on category and difficulty
func _get_icons_for_map(category: String, difficulty: String) -> Array:
	var icons = []
	
	# Add difficulty-based icons
	match difficulty:
		"beginner":
			icons.append("array")
		"intermediate":
			icons.append("procedural")
		"advanced":
			icons.append("ai")
	
	# Add category-specific icons
	match category:
		"tutorial":
			icons.append_array(["cube", "array"])
		"primitives":
			icons.append_array(["cube", "plane", "point"])
		"color":
			icons.append_array(["material", "shader"])
		"physics":
			icons.append_array(["physics", "gravity", "collision"])
		"machinelearning":
			icons.append_array(["ai", "neural-net"])
		"procedural":
			icons.append_array(["procedural", "noise", "texture"])
		"randomness":
			icons.append_array(["random", "noise"])
		"wavefunctions":
			icons.append_array(["procedural", "noise"])
		"graphtheory":
			icons.append_array(["pathfinding", "flow-field"])
		"recursive":
			icons.append_array(["recursion", "procedural"])
		"critical":
			icons.append_array(["ai", "danger"])
		_:
			icons.append("cube")
	
	return icons

# Create summary sections from map data
func _create_summary_from_map_data(map_info: Dictionary, metadata: Dictionary):
	summary_sections.clear()
	
	# Section 1: Map description
	var description = map_info.get("description", "No description available")
	summary_sections.append("MAP: " + description)
	
	# Section 2: Learning objectives
	var learning_objectives = metadata.get("learning_objectives", [])
	if learning_objectives.size() > 0:
		var objectives_text = "LEARNING OBJECTIVES:\n"
		for objective in learning_objectives:
			objectives_text += "• " + objective + "\n"
		summary_sections.append(objectives_text.strip_edges())
	
	# Section 3: Map metadata
	var difficulty = metadata.get("difficulty", "Unknown")
	var estimated_time = metadata.get("estimated_time", "Unknown")
	var category = metadata.get("category", "Unknown")
	
	var metadata_text = "CATEGORY: %s\n" % category.capitalize()
	metadata_text += "DIFFICULTY: %s\n" % difficulty.capitalize()
	metadata_text += "ESTIMATED TIME: %s" % estimated_time
	summary_sections.append(metadata_text)
	
	# Section 4: Map dimensions (if available)
	var dimensions = map_info.get("dimensions", {})
	if not dimensions.is_empty():
		var width = dimensions.get("width", 0)
		var depth = dimensions.get("depth", 0)
		var max_height = dimensions.get("max_height", 0)
		
		var dimensions_text = "MAP DIMENSIONS:\n"
		dimensions_text += "Size: %dx%d\n" % [width, depth]
		dimensions_text += "Max Height: %d levels" % max_height
		summary_sections.append(dimensions_text)
	
	print("InfoBoard: Created " + str(summary_sections.size()) + " summary sections from map data")
	

# Animation control functions
func start_animation():
	if summary_sections.size() > 0:
		current_section = 0
		is_animating = true
		_show_current_section()
	else:
		push_error("InfoBoard: No summary sections to animate")

func stop_animation():
	is_animating = false

func pause_animation():
	animation_paused = true

func resume_animation():
	animation_paused = false
	# If we were in the middle of displaying a section, continue with the next one
	if is_animating:
		_show_current_section()

# Display the current summary section with fade effect
func _show_current_section():
	if animation_paused or not is_animating:
		return
		
	if current_section < summary_sections.size():
		var section_text = summary_sections[current_section]
		
		# Fade out current text
		var fade_out = create_tween()
		fade_out.tween_property(summary_label, "modulate", Color(1, 1, 1, 0), fade_duration)
		await fade_out.finished
		
		# Update text
		summary_label.text = section_text
		
		# Fade in new text
		var fade_in = create_tween()
		fade_in.tween_property(summary_label, "modulate", Color(1, 1, 1, 1), fade_duration)
		
		# Calculate display time based on text length
		var display_time = _calculate_display_time(section_text)
		
		# Wait for display time, then show next section
		await get_tree().create_timer(display_time).timeout
		
		# Move to next section or loop back to beginning
		current_section = (current_section + 1) % summary_sections.size()
		
		# Continue animation if still active
		if is_animating:
			_show_current_section()

# Calculate appropriate display time based on text length
func _calculate_display_time(text: String) -> float:
	# Calculate time based on text length (characters)
	var char_count = text.length()
	var estimated_time = char_count / chars_per_second
	
	# Add base time and clamp to min/max
	var display_time = base_display_time + estimated_time
	display_time = clamp(display_time, min_display_time, max_display_time)
	
	return display_time

# Update XP display
func _update_xp_display(new_xp):
	xp_label.text = "XP: " + str(new_xp)

# Update health display
func _update_health_display(health_value):
	health_label.text = "Health: " + str(health_value) + "%"

# Player interaction
func _on_area_entered(_body):
	player_in_range = true
	resume_animation()

func _on_area_exited(_body):
	player_in_range = false
	pause_animation()
