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
	
	# Defer loading until grid system is ready
	call_deferred("_initialize_info_board")

func _initialize_info_board():
	"""Initialize info board after grid system is ready"""
	# Wait a few frames to ensure grid system is fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check if a specific sequence was provided via parameter
	var sequence_name = ""
	if "sequence_name" in self:
		sequence_name = self.sequence_name
		print("InfoBoard: Using sequence from property: " + sequence_name)
	elif has_meta("sequence_name"):
		sequence_name = get_meta("sequence_name")
		print("InfoBoard: Using sequence from metadata: " + sequence_name)
	
	# Load the level data and start animation
	if not sequence_name.is_empty():
		_load_sequence_directly(sequence_name)
	elif specific_category != "" and specific_id >= 0:
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

# Load sequence directly by name
func _load_sequence_directly(sequence_name: String):
	print("InfoBoard: Loading sequence directly: " + sequence_name)
	
	# Load sequence data from map_sequences.json
	var sequence_data = _load_specific_sequence_data(sequence_name)
	if sequence_data.is_empty():
		push_error("InfoBoard: No sequence data found for: " + sequence_name)
		return
	
	print("InfoBoard: Found sequence data for: " + sequence_name)
	_update_info_board_with_sequence_data("", sequence_data)

# Load information for a specifically assigned level
func _load_specific_level_info():
	print("InfoBoard: Loading specific level info for category: " + specific_category + ", id: " + str(specific_id))

# Load level info from grid system's map_name by parsing it
func _load_from_map_name():
	if not grid_system:
		push_error("InfoBoard: No grid system found!")
		return
	
	# Get the map_name from the grid system
	var map_name = grid_system.map_name
	print("InfoBoard: Using map name: '" + map_name + "'")
	print("InfoBoard: Map name length: " + str(map_name.length()))
	
	# Load sequence data from map_sequences.json
	var sequence_data = _load_sequence_data_for_map(map_name)
	if sequence_data.is_empty():
		push_error("InfoBoard: No sequence data found for map: " + map_name)
		return
	
	print("InfoBoard: Found sequence data for: " + map_name)
	_update_info_board_with_sequence_data(map_name, sequence_data)

# Load sequence data from map_sequences.json for the current map
func _load_sequence_data_for_map(map_name: String) -> Dictionary:
	var sequence_file_path = "res://commons/maps/map_sequences.json"
	
	if not FileAccess.file_exists(sequence_file_path):
		push_error("InfoBoard: map_sequences.json not found!")
		return {}
	
	var file = FileAccess.open(sequence_file_path, FileAccess.READ)
	if not file:
		push_error("InfoBoard: Could not open map_sequences.json")
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("InfoBoard: Failed to parse map_sequences.json")
		return {}
	
	var json_data = json.data
	var sequences = json_data.get("sequences", {})
	
	# Find which sequence contains this map
	print("InfoBoard: Searching for map '" + map_name + "' in sequences...")
	
	for sequence_name in sequences.keys():
		var sequence = sequences[sequence_name]
		var maps = sequence.get("maps", [])
		
		print("InfoBoard: Checking sequence '" + sequence_name + "' with maps: " + str(maps))
		
		if map_name in maps:
			print("InfoBoard: ✅ Found map '" + map_name + "' in sequence '" + sequence_name + "'")
			var result = sequence.duplicate()
			result["sequence_name"] = sequence_name
			result["map_index"] = maps.find(map_name)
			result["total_maps"] = maps.size()
			return result
	
	print("InfoBoard: ❌ Map '" + map_name + "' not found in any sequence")
	print("InfoBoard: Available sequences: " + str(sequences.keys()))
	return {}

# Load specific sequence data directly by sequence name
func _load_specific_sequence_data(sequence_name: String) -> Dictionary:
	var sequence_file_path = "res://commons/maps/map_sequences.json"
	
	if not FileAccess.file_exists(sequence_file_path):
		push_error("InfoBoard: map_sequences.json not found!")
		return {}
	
	var file = FileAccess.open(sequence_file_path, FileAccess.READ)
	if not file:
		push_error("InfoBoard: Could not open map_sequences.json")
		return {}
	
	var json_text = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(json_text)
	
	if parse_result != OK:
		push_error("InfoBoard: Failed to parse map_sequences.json")
		return {}
	
	var json_data = json.data
	var sequences = json_data.get("sequences", {})
	
	# Find the specific sequence
	if sequences.has(sequence_name):
		var sequence = sequences[sequence_name]
		var result = sequence.duplicate()
		result["sequence_name"] = sequence_name
		result["map_index"] = 0  # Default to first map
		result["total_maps"] = sequence.get("maps", []).size()
		print("InfoBoard: ✅ Found sequence '" + sequence_name + "'")
		return result
	else:
		print("InfoBoard: ❌ Sequence '" + sequence_name + "' not found")
		print("InfoBoard: Available sequences: " + str(sequences.keys()))
		return {}

# Update the info board with sequence data from map_sequences.json
func _update_info_board_with_sequence_data(map_name: String, sequence_data: Dictionary):
	var sequence_name = sequence_data.get("sequence_name", "Unknown")
	var map_index = sequence_data.get("map_index", 0)
	var total_maps = sequence_data.get("total_maps", 1)
	
	# Format number with leading zero if needed
	var number_text = str(map_index + 1)  # Show 1-based index
	if (map_index + 1) < 10:
		number_text = "0" + number_text
	
	# Update labels with sequence information
	level_number_label.text = number_text
	level_id_label.text = sequence_name + "/" + str(map_index + 1) + " of " + str(total_maps)
	title_label.text = sequence_data.get("name", "Unknown Sequence")
	
	# Update barcode
	barcode.text = "||||||||||||||||||||||||||"
	
	# Clear and repopulate icons based on sequence difficulty and category
	for child in icons_container.get_children():
		child.queue_free()
	
	# Add icons based on sequence metadata
	var difficulty = sequence_data.get("difficulty", "beginner")
	var sequence_icons = _get_icons_for_sequence(sequence_name, difficulty)
	
	for icon_name in sequence_icons:
		if icon_textures.has(icon_name):
			var icon = TextureRect.new()
			icon.texture = icon_textures[icon_name]
			icon.expand = true
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.custom_minimum_size = Vector2(50, 50)
			icons_container.add_child(icon)
	
	# Create summary sections from sequence data
	_create_summary_from_sequence_data(sequence_data)
	start_animation()

# Get appropriate icons for a sequence
func _get_icons_for_sequence(sequence_name: String, difficulty: String) -> Array:
	var icons = []
	
	# Add difficulty-based icons
	match difficulty:
		"beginner":
			icons.append("array")
		"intermediate":
			icons.append("procedural")
		"advanced":
			icons.append("ai")
	
	# Add sequence-specific icons
	match sequence_name:
		"randomness_exploration":
			icons.append_array(["random", "noise"])
		"physicssimulation":
			icons.append_array(["physics", "gravity", "collision"])
		"softbodies":
			icons.append_array(["material", "physics"])
		"wavefunctions":
			icons.append_array(["procedural", "noise"])
		"machinelearning":
			icons.append_array(["ai", "neural-net"])
		"patterngeneration":
			icons.append_array(["procedural", "texture"])
		"graphtheory":
			icons.append_array(["pathfinding", "flow-field"])
		"recursiveemergence":
			icons.append_array(["recursion", "procedural"])
		"criticalalgorithms":
			icons.append_array(["ai", "danger"])
		_:
			icons.append("cube")
	
	return icons

# Create summary sections from sequence data
func _create_summary_from_sequence_data(sequence_data: Dictionary):
	summary_sections.clear()
	
	# Section 1: Sequence description
	var description = sequence_data.get("description", "No description available")
	summary_sections.append("SEQUENCE: " + description)
	
	# Section 2: Learning objectives
	var objectives = sequence_data.get("learning_objectives", [])
	if objectives.size() > 0:
		var objectives_text = "LEARNING OBJECTIVES:\n"
		for objective in objectives:
			objectives_text += "• " + objective + "\n"
		summary_sections.append(objectives_text.strip_edges())
	
	# Section 3: Progress and timing
	var estimated_time = sequence_data.get("estimated_time", "Unknown")
	var difficulty = sequence_data.get("difficulty", "Unknown")
	var map_index = sequence_data.get("map_index", 0)
	var total_maps = sequence_data.get("total_maps", 1)
	
	var progress_text = "PROGRESS: Map %d of %d\n" % [map_index + 1, total_maps]
	progress_text += "DIFFICULTY: %s\n" % difficulty.capitalize()
	progress_text += "ESTIMATED TIME: %s" % estimated_time
	summary_sections.append(progress_text)
	
	# Section 4: Prerequisites (if any)
	var unlock_requirements = sequence_data.get("unlock_requirements", [])
	if unlock_requirements.size() > 0:
		var prereq_text = "PREREQUISITES:\n"
		for req in unlock_requirements:
			prereq_text += "• " + req.replace("_", " ").capitalize() + "\n"
		summary_sections.append(prereq_text.strip_edges())
	
	print("InfoBoard: Created " + str(summary_sections.size()) + " summary sections from sequence data")
	
	
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
