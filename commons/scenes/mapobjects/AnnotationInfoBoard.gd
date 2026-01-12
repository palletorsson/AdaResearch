# AnnotationInfoBoard.gd
# Uses the existing info board structure to display map name and description
# Automatically loads info from the GridDataComponent JSON

extends Node3D
class_name AnnotationInfoBoard

# References to UI elements
@onready var level_number_label = $Viewport/InfoBoardUI/MainPanel/LevelNumber
@onready var level_id_label = $Viewport/InfoBoardUI/MainPanel/LevelID
@onready var title_label = $Viewport/InfoBoardUI/MainPanel/Title
@onready var summary_label = $Viewport/InfoBoardUI/MainPanel/Summary
@onready var barcode = $Viewport/InfoBoardUI/MainPanel/Barcode
@onready var xp_label = $Viewport/InfoBoardUI/MainPanel/XPLabel
@onready var health_label = $Viewport/InfoBoardUI/MainPanel/HealthLabel

# Configuration
@export var auto_update_on_map_load: bool = true
@export var show_level_number: bool = true
@export var show_metadata: bool = true
@export var animate_text: bool = false

# Current map info
var current_map_name: String = ""
var current_description: String = ""
var current_metadata: Dictionary = {}

# Sequence parameter support
var sequence_name: String = ""
var sequence_data: Dictionary = {}

func _ready():
	print("----------------------------------------------------------------------")
	print("AnnotationInfoBoard: Initializing map info display board")
	
	# Connect to GameManager for XP updates if available
	if GameManager and GameManager.has_signal("score_updated"):
		GameManager.score_updated.connect(_update_xp_display)
		_update_xp_display(GameManager.get_score())
	
	# Connect to GameManager for Health updates if available
	if GameManager and GameManager.has_signal("health_updated"):
		GameManager.health_updated.connect(_on_health_updated_signal)
		# Initial update handled by _update_completion_status later, but can force here too
		# but _delayed_initialization calls update_info_board which calls _update_completion_status

	
	# Delay initialization to allow utilities to be placed first
	call_deferred("_delayed_initialization")

func _delayed_initialization():
	"""Delayed initialization to ensure utilities are placed first"""
	print("AnnotationInfoBoard: Starting delayed initialization...")
	
	# Wait additional frames to ensure grid utilities are fully loaded
	await get_tree().process_frame
	await get_tree().process_frame
	await get_tree().process_frame
	
	# Check for sequence parameter from utility placement
	_check_for_sequence_parameter()
	
	# Connect to grid system for map data
	_connect_to_grid_system()

func _check_for_sequence_parameter():
	"""Check if a sequence parameter was provided via utility placement"""
	if "sequence_name" in self:
		sequence_name = self.sequence_name
		print("AnnotationInfoBoard: Using sequence from property: " + sequence_name)
	elif has_meta("sequence_name"):
		sequence_name = get_meta("sequence_name")
		print("AnnotationInfoBoard: Using sequence from metadata: " + sequence_name)
	
	if not sequence_name.is_empty():
		print("AnnotationInfoBoard: Will load sequence data for: " + sequence_name)
		_load_sequence_data()

func _load_sequence_data():
	"""Load sequence data from MapProgressionManager"""
	# Use the global manager if available
	if not MapProgressionManager:
		print("AnnotationInfoBoard: MapProgressionManager not found")
		return

	# Access sequences directly from manager
	var sequences = MapProgressionManager.sequences
	
	# Find the specific sequence
	if sequences.has(sequence_name):
		var sequence = sequences[sequence_name]
		sequence_data = sequence.duplicate()
		sequence_data["sequence_name"] = sequence_name
		
		# Map index will be calculated in _update_info_board based on current map
		sequence_data["map_index"] = 0 
		sequence_data["total_maps"] = sequence.get("maps", []).size()
		print("AnnotationInfoBoard: ✅ Loaded sequence data for: " + sequence_name)
		
		# Also load current map info so we can display both sequence and map details
		_load_current_map_info_for_display()
		
		# Update the info board immediately with sequence data
		_update_info_board()
	else:
		print("AnnotationInfoBoard: ❌ Sequence '" + sequence_name + "' not found")
		print("AnnotationInfoBoard: Available sequences: " + str(sequences.keys()))

func _load_current_map_info_for_display():
	"""Load current map info for display purposes (without updating the board)"""
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if not grid_system:
		grid_system = _find_node_by_class(get_tree().current_scene, "GridSystem")
	
	if grid_system:
		var data_component = grid_system.get_data_component()
		if data_component:
			# Get map_info section directly from JSON
			if data_component.json_loader and data_component.json_loader.map_data:
				var map_info = data_component.json_loader.map_data.get("map_info", {})
				current_map_name = map_info.get("name", "Unknown Map")
				current_description = map_info.get("description", "No description available")
				current_metadata = map_info.get("metadata", {})
				
				print("AnnotationInfoBoard: Loaded current map info for display - Name: '%s'" % current_map_name)
			else:
				# Fallback to metadata method
				var metadata = data_component.get_map_metadata()
				current_map_name = metadata.get("name", "Unknown Map")
				current_description = metadata.get("description", "No description available")
				current_metadata = metadata
				print("AnnotationInfoBoard: Loaded current map info from metadata fallback")
		else:
			print("AnnotationInfoBoard: No data component found for map info display")

func _connect_to_grid_system():
	"""Connect to grid system to get map data"""
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
			print("AnnotationInfoBoard: Connected to GridSystem.map_loaded")
		
		# Get current map info
		_load_current_map_info(grid_system)
	else:
		print("AnnotationInfoBoard: WARNING - Could not find GridSystem")

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
	print("AnnotationInfoBoard: Map loaded - %s (%s)" % [map_name, format])
	
	# Find grid system to get data
	var grid_system = get_tree().get_first_node_in_group("grid_system")
	if grid_system:
		grid_system_ref = grid_system # Cache it
		_load_current_map_info(grid_system)

var grid_system_ref: Node # Cache for ID lookup

func _load_current_map_info(grid_system):
	"""Load map info from grid system data component"""
	var data_component = grid_system.get_data_component()
	if not data_component:
		print("AnnotationInfoBoard: No data component found")
		return
	
	# Get map_info section directly from JSON
	if data_component.json_loader and data_component.json_loader.map_data:
		var map_info = data_component.json_loader.map_data.get("map_info", {})
		current_map_name = map_info.get("name", "Unknown Map")
		current_description = map_info.get("description", "No description available")
		current_metadata = map_info.get("metadata", {})
		
		print("AnnotationInfoBoard: Loaded from map_info - Name: '%s'" % current_map_name)
		print("AnnotationInfoBoard: Description: '%s'" % current_description)
	else:
		# Fallback to metadata method
		var metadata = data_component.get_map_metadata()
		current_map_name = metadata.get("name", "Unknown Map")
		current_description = metadata.get("description", "No description available")
		current_metadata = metadata
		print("AnnotationInfoBoard: Loaded from metadata fallback")
	
	# Update the info board display
	_update_info_board()

func _update_info_board():
	"""Update the info board with current map information"""
	print("DEBUG INFOBOARD: Current Map: '%s'" % current_map_name)
	
	# If sequence not explicitly set, try to find one that contains this map
	if sequence_data.is_empty() and MapProgressionManager:
		var check_id = MapProgressionManager.current_map
		if check_id.is_empty() and grid_system_ref: 
			# Try to get from grid system if manager is empty (e.g. direct scene load)
			if "map_name" in grid_system_ref:
				check_id = grid_system_ref.map_name
			elif "current_map_name" in grid_system_ref: 
				check_id = grid_system_ref.current_map_name
		
		# Fallback: Get from scene filename
		if check_id.is_empty():
			var scene_path = get_tree().current_scene.scene_file_path
			if not scene_path.is_empty():
				check_id = scene_path.get_file().get_basename()
				print("AnnotationInfoBoard: Extracted ID '%s' from scene path" % check_id)
		
		# If we still don't have an ID, we can't strict match
		
		if not check_id.is_empty():
			print("AnnotationInfoBoard: Auto-detecting sequence for Map ID: '%s'" % check_id)
			for seq_id in MapProgressionManager.sequences:
				var seq = MapProgressionManager.sequences[seq_id]
				if seq.has("maps") and check_id in seq.maps:
					print("AnnotationInfoBoard: Auto-detected sequence '%s' for map ID '%s'" % [seq_id, check_id])
					sequence_name = seq_id
					_load_sequence_data() # Load it
					break
		else:
			print("AnnotationInfoBoard: Could not determine Map ID for sequence detection. Using Display Name '%s'" % current_map_name)
				
	if sequence_data.is_empty():
		print("DEBUG INFOBOARD: Still no sequence data found. sequence_name='%s'" % sequence_name)

	# Use sequence data if available, otherwise fall back to map data
	if not sequence_data.is_empty():
		_update_info_board_with_sequence_data()
	else:
		_update_info_board_with_map_data()

func _update_info_board_with_sequence_data():
	"""Update info board using sequence data from MapProgressionManager"""
	var sequence_name = sequence_data.get("sequence_name", "Unknown")
	
	# Calculate correct map index based on current map name
	var map_index = 0
	if sequence_data.has("maps"):
		var maps = sequence_data["maps"]
		var found = maps.find(current_map_name)
		if found != -1:
			map_index = found
			
	var total_maps = sequence_data.get("total_maps", 1)
	
	# Update level number (show progress in sequence)
	if show_level_number:
		# Use 0-based indexing as requested (00, 01, 02...)
		level_number_label.text = "%02d" % map_index
	else:
		level_number_label.text = "??"
	
	# Update level ID (sequence/progress format + current map name)
	# Also using 0-based index for consistency in the ID string
	var level_id_text = "%s/%02d of %d" % [sequence_name, map_index, total_maps]
	if not current_map_name.is_empty():
		level_id_text += " - %s" % current_map_name
	level_id_label.text = level_id_text
	
	# Update title (use sequence name + current map name)
	var title_text = sequence_data.get("name", "Unknown Sequence")
	if not current_map_name.is_empty():
		title_text += " - %s" % current_map_name
	title_label.text = title_text
	
	# Update summary (use sequence description + objectives + current map info)
	var summary_text = sequence_data.get("description", "No description available")
	
	# Add current map description if available
	if not current_description.is_empty():
		summary_text += "\n\nCurrent Map: %s" % current_description
	
	# User requested to hide objectives
	# if show_metadata and sequence_data.has("learning_objectives"):
	# 	var objectives = sequence_data.get("learning_objectives", [])
	# 	if objectives is Array and objectives.size() > 0:
	# 		summary_text += "\n\nLearning Objectives:"
	# 		for obj in objectives:
	# 			summary_text += "\n• %s" % obj
	
	summary_label.text = summary_text
	
	# Update barcode (decorative) - use combination of sequence and map name
	var barcode_text = sequence_name
	if not current_map_name.is_empty():
		barcode_text += "_" + current_map_name
	barcode.text = _generate_barcode_pattern(barcode_text)
	
	# Update health to show completion status
	_update_completion_status()
	
	print("AnnotationInfoBoard: ✅ Updated info board with sequence data")

func _update_info_board_with_map_data():
	"""Update info board using map data from map_data.json"""
	# Extract level number from map name if possible
	var level_number = _extract_level_number(current_map_name)
	
	# Update level number
	if show_level_number and level_number >= 0:
		level_number_label.text = "%02d" % level_number
	else:
		level_number_label.text = "??"
	
	# Update level ID (category/name format)
	var category = _get_map_category(current_map_name)
	level_id_label.text = "%s/%s" % [category, current_map_name]
	
	# Update title (use map name)
	title_label.text = current_map_name
	
	# Update summary (use description + metadata if available)
	var summary_text = current_description
	if show_metadata and not current_metadata.is_empty():
		summary_text += _format_metadata_summary()
	
	summary_label.text = summary_text
	
	# Update barcode (decorative)
	barcode.text = _generate_barcode_pattern(current_map_name)
	
	# Update health to show completion status
	_update_completion_status()
	
	print("AnnotationInfoBoard: ✅ Updated info board with map data")

func _extract_level_number(map_name: String) -> int:
	"""Extract level number from map name"""
	# Try to find numbers in the map name
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(map_name)
	
	if result:
		return int(result.get_string())
	
	# Fallback for tutorial sequence
	if map_name.begins_with("Tutorial"):
		if "Row" in map_name:
			return 1
		elif "2D" in map_name:
			return 2
		elif "Disco" in map_name:
			return 3
	
	return -1

func _get_map_category(map_name: String) -> String:
	"""Get category based on map name"""
	if map_name.begins_with("Tutorial"):
		return "tutorial"
	elif map_name.begins_with("Lab"):
		return "lab"
	elif map_name.begins_with("Algorithm"):
		return "algorithm"
	else:
		return "map"

func _format_metadata_summary() -> String:
	"""Format metadata into readable summary"""
	var metadata_text = ""

	
	# User requested to hide difficulty, time, and objectives
	# Keeping function structure in case other metadata needs to be added later
	
	return metadata_text

func _generate_barcode_pattern(map_name: String) -> String:
	"""Generate decorative barcode based on map name"""
	var pattern = ""
	var hash_val = map_name.hash()
	
	for i in range(32):
		if (hash_val >> i) & 1:
			pattern += "█"
		else:
			pattern += "▌"
	
	return pattern

func _update_completion_status():
	"""Update health label to show completion status"""
	# Show actual health if available, or default to 100%
	var health_val = 100
	if is_instance_valid(GameManager) and "player_health" in GameManager:
		health_val = GameManager.player_health
	
	health_label.text = "Health: %d%%" % health_val

func _on_health_updated_signal(_new_health: float):
	"""Signal handler for health updates"""
	_update_completion_status()


func _update_xp_display(new_score: int):
	"""Update XP display from GameManager"""
	if xp_label:
		xp_label.text = "XP: %d" % new_score

# Public API
func force_update():
	"""Force update the display"""
	_find_grid_system()

func set_animation_enabled(enabled: bool):
	"""Enable/disable text animation"""
	animate_text = enabled

func set_metadata_display(enabled: bool):
	"""Enable/disable metadata display"""
	show_metadata = enabled
	_update_info_board()

func get_current_info() -> Dictionary:
	"""Get current map information"""
	return {
		"name": current_map_name,
		"description": current_description,
		"metadata": current_metadata
	}
