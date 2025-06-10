# InfoBoard.gd
# Animated version that cycles through summary sections
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

# The specific level info to display on this board
# Set these in the Inspector to override auto-detection
@export var specific_category: String = ""
@export var specific_id: int = -1

# Reference to the grid system
@onready var grid_system = $"../../multiLayerGrid"

func _ready():
	# Connect to XP signal for updates
	if get_node_or_null("/root/GameManager") != null:
		GameManager.connect("xp_updated", Callable(self, "_update_xp_display"))
		_update_xp_display(GameManager.get_xp())
		_update_health_display(100)  # Assuming full health at start
	
	# Load the level data and start animation
	if specific_category != "" and specific_id >= 0:
		_load_specific_level_info()
	else:
		_load_from_map_name()

# Helper function to get all children recursively
func _get_all_children(node):
	var nodes = []
	for child in node.get_children():
		nodes.append(child)
		nodes.append_array(_get_all_children(child))
	return nodes

# Load information for a specifically assigned level
func _load_specific_level_info():
	pass

# Load level info from grid system's map_name by parsing it
func _load_from_map_name():
	if not grid_system:
		push_error("InfoBoard: No grid system found!")
		return
	
	# Get the map_name from the grid system
	var map_name = grid_system.map_name
	print("InfoBoard: Using map name: " + map_name)
	
	# Parse the map name to extract category and ID
	var category = ""
	var id = -1
	
	# Try different parsing approaches
	
	# Approach 1: Split by underscore (e.g., "Intro_0")
	var parts = map_name.split("_")
	if parts.size() >= 2:
		category = parts[0].to_lower()  # Convert to lowercase to match LevelsManager
		id = int(parts[1])
		print("InfoBoard: Parsed from map name: category=" + category + ", id=" + str(id))
	
	
# Update the info board with level data
func _update_info_board(category, id, data):
	# Format number with leading zero if needed
	var number_text = str(id)
	if id < 10:
		number_text = "0" + number_text
	
	# Update labels
	level_number_label.text = number_text
	level_id_label.text = category + "/" + str(id)
	title_label.text = data.title
	
	# Update barcode
	barcode.text = "||||||||||||||||||||||||||"
	
	# Clear and repopulate icons
	for child in icons_container.get_children():
		child.queue_free()

	# Add icons based on the level's icon list
	if data.has("icons"):
		for icon_name in data.icons:
			if icon_textures.has(icon_name):
				var icon = TextureRect.new()
				icon.texture = icon_textures[icon_name]
				icon.expand = true
				icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
				icon.custom_minimum_size = Vector2(50, 50)
				icons_container.add_child(icon)
	
	# Extract summary sections and start animation
	_extract_summary_sections(data)
	start_animation()

# Extract summary sections from data
func _extract_summary_sections(data):
	summary_sections.clear()
	
	# If summary is a dictionary with numbered sections
	if data.has("summary") and data.summary is Dictionary:
		var sorted_keys = data.summary.keys()
		sorted_keys.sort()
		
		for key in sorted_keys:
			summary_sections.append(data.summary[key])
		
		print("InfoBoard: Extracted " + str(summary_sections.size()) + " summary sections")
	
	# If summary is a simple string, use it as a single section
	elif data.has("summary") and data.summary is String:
		summary_sections.append(data.summary)
		print("InfoBoard: Using summary as a single section")
	
	# If we somehow got no sections, add a placeholder
	if summary_sections.size() == 0:
		summary_sections.append("No summary available for this level.")
		print("InfoBoard: No summary sections found, using placeholder")

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
