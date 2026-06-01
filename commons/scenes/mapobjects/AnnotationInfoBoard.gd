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
var current_lookup_name: String = ""
var current_map_id: String = ""
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

	
	# Delay initialization to allow utilities to be placed first
	call_deferred("_delayed_initialization")

func _delayed_initialization():
	"""Delayed initialization to ensure utilities are placed first"""
	# This runs via call_deferred from _ready, by which point the node may
	# already have been removed from the tree (e.g. a parent that rebuilds
	# its children, like lab_room's apply_grid_config). get_tree() is null on
	# a detached node, so bail out instead of crashing on .process_frame.
	if not is_inside_tree():
		return
	print("AnnotationInfoBoard: Starting delayed initialization...")

	# Wait additional frames to ensure grid utilities are fully loaded.
	# Re-check after each await — the node can be freed/detached mid-wait.
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return
	await get_tree().process_frame
	if not is_inside_tree():
		return

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
		sequence_data = sequence.duplicate(true)  # Deep copy to preserve array types
		sequence_data["sequence_name"] = sequence_name
		
		# Ensure maps array is properly typed and accessible
		if sequence.has("maps"):
			var maps_array = sequence["maps"]
			# Convert to Array[String] if needed to ensure type consistency
			var typed_maps: Array[String] = []
			for map_id in maps_array:
				typed_maps.append(str(map_id).strip_edges())  # Strip whitespace
			sequence_data["maps"] = typed_maps
			print("AnnotationInfoBoard: Loaded %d maps from sequence: %s" % [typed_maps.size(), typed_maps])
		else:
			sequence_data["maps"] = []
		
		# Map index will be calculated in _update_info_board based on current map
		sequence_data["map_index"] = 0 
		sequence_data["total_maps"] = sequence_data["maps"].size()
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
				current_lookup_name = map_info.get("lookup_name", "")
				current_metadata = map_info.get("metadata", {})

				# Try to load blurb.md first, fall back to description
				current_description = _load_blurb_or_description(current_map_name, map_info.get("description", "No description available"))

				print("AnnotationInfoBoard: Loaded current map info for display - Name: '%s'" % current_map_name)
			else:
				# Fallback to metadata method
				var metadata = data_component.get_map_metadata()
				current_map_name = metadata.get("name", "Unknown Map")
				current_lookup_name = metadata.get("lookup_name", "")
				current_metadata = metadata

				# Try to load blurb.md first, fall back to description
				current_description = _load_blurb_or_description(current_map_name, metadata.get("description", "No description available"))
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
		current_lookup_name = map_info.get("lookup_name", "")
		current_metadata = map_info.get("metadata", {})

		# Try to load blurb.md first, fall back to description
		current_description = _load_blurb_or_description(current_map_name, map_info.get("description", "No description available"))

		print("AnnotationInfoBoard: Loaded from map_info - Name: '%s'" % current_map_name)
		print("AnnotationInfoBoard: Description: '%s'" % current_description)
	else:
		# Fallback to metadata method
		var metadata = data_component.get_map_metadata()
		current_map_name = metadata.get("name", "Unknown Map")
		current_lookup_name = metadata.get("lookup_name", "")
		current_metadata = metadata

		# Try to load blurb.md first, fall back to description
		current_description = _load_blurb_or_description(current_map_name, metadata.get("description", "No description available"))
		print("AnnotationInfoBoard: Loaded from metadata fallback")

	# Update the info board display
	_update_info_board()

func _update_info_board():
	"""Update the info board with current map information"""
	print("DEBUG INFOBOARD: Current Map: '%s'" % current_map_name)
	
	# ALWAYS try to determine the true Map ID (filename)
	var check_id = MapProgressionManager.current_map if MapProgressionManager else ""
	
	if check_id.is_empty() and grid_system_ref: 
		# Try to get from grid system if manager is empty (e.g. direct scene load)
		var gs_map_name = grid_system_ref.get("map_name")
		if gs_map_name:
			check_id = gs_map_name
			print("AnnotationInfoBoard: Got ID '%s' from GridSystem.map_name" % check_id)
		elif "current_map_name" in grid_system_ref:
			check_id = grid_system_ref.current_map_name
			print("AnnotationInfoBoard: Got ID '%s' from GridSystem.current_map_name" % check_id)
		
		# If GridSystem property failed, try DataComponent (MOST RELIABLE)
		if check_id.is_empty():
			var data_comp = grid_system_ref.get_data_component()
			if data_comp and data_comp.has_method("get_current_map_name"):
				var dc_name = data_comp.get_current_map_name()
				if not dc_name.is_empty():
					check_id = dc_name
					print("AnnotationInfoBoard: Got ID '%s' from GridDataComponent.get_current_map_name()" % check_id)
	
	# Fallback: Get from scene filename
	if check_id.is_empty():
		var scene_path = get_tree().current_scene.scene_file_path
		if not scene_path.is_empty():
			check_id = scene_path.get_file().get_basename()
			print("AnnotationInfoBoard: Extracted ID '%s' from scene path" % check_id)
			
	if not check_id.is_empty():
		current_map_id = str(check_id).strip_edges() # Store valid ID for index lookup (normalized)
		print("AnnotationInfoBoard: Stored normalized map ID: '%s'" % current_map_id)
	
	# 1. Primary Check: current_map_id
	var candidates = []
	if not current_map_id.is_empty():
		candidates.append(current_map_id)
		# candidates.append(str(current_map_id).strip_edges()) # Duplicate if normalized above

	# 2. Secondary Check: Lookup Name (Explicit Override)
	if not current_lookup_name.is_empty():
		candidates.append(current_lookup_name)
		print("AnnotationInfoBoard: Added lookup_name candidate: '%s'" % current_lookup_name)

	
	# 2. Secondary Check: Display Name -> ID conversion (Point Zero -> Point_Zero)
	if not current_map_name.is_empty():
		var underscores = current_map_name.replace(" ", "_")
		candidates.append(underscores)
		# Also try stripping edges from name
		candidates.append(current_map_name.strip_edges())

	if sequence_data.is_empty() and MapProgressionManager:
		for cand in candidates:
			if cand.is_empty(): continue
			
			for seq_id in MapProgressionManager.sequences:
				var seq = MapProgressionManager.sequences[seq_id]
				if seq.has("maps"):
					if cand in seq.maps:
						sequence_name = seq_id
						current_map_id = cand # Update to the working ID
						_load_sequence_data()
						break
			if not sequence_data.is_empty():
				break

	# Use sequence data if available, otherwise fall back to map data
	if not sequence_data.is_empty():
		_update_info_board_with_sequence_data()
	else:
		_update_info_board_with_map_data()

func _update_info_board_with_sequence_data():
	"""Update info board using sequence data from MapProgressionManager"""
	var sequence_name = sequence_data.get("sequence_name", "Unknown")
	
	# Calculate correct map index based on current map ID
	var map_index = 0
	if sequence_data.has("maps"):
		var maps = sequence_data["maps"]
		var found = maps.find(current_map_id)
		
		# If exact ID not found, try the fallback candidates again within the known sequence
		if found == -1:
			var candidates = []
			if not current_lookup_name.is_empty():
				candidates.append(current_lookup_name)
			candidates.append(current_map_name.replace(" ", "_"))
			candidates.append(current_map_name)
			
			for cand in candidates:
				found = maps.find(cand)
				if found != -1:
					print("AnnotationInfoBoard: Found map ID '%s' at index %d via fallback search" % [cand, found])
					break
		
		if found != -1:
			map_index = found
			
	var total_maps = sequence_data.get("total_maps", 1)
	
	# Update level number (show progress in sequence)
	# Use 1-based indexing for human readability (01, 02, 03...)
	var display_index = map_index + 1
	if show_level_number:
		level_number_label.text = "%02d" % display_index
	else:
		level_number_label.text = str(display_index)

	# Update level ID (sequence/progress format + current map name)
	var level_id_text = "%s/%02d of %d" % [sequence_name, display_index, total_maps]
	if not current_map_name.is_empty():
		level_id_text += " - %s" % current_map_name
	level_id_label.text = level_id_text
	
	# Update title (use map name only)
	if not current_map_name.is_empty():
		title_label.text = current_map_name
	else:
		title_label.text = sequence_data.get("name", "Unknown Sequence")
	
	# Update summary (prioritize current map info, no prefixes)
	if not current_description.is_empty():
		summary_label.text = current_description
	else:
		# Fallback to sequence description only if map has no description
		summary_label.text = sequence_data.get("description", "No description available")
	
	# Update barcode (decorative) - use combination of sequence and map name
	var barcode_text = sequence_name
	if not current_map_name.is_empty():
		barcode_text += "_" + current_map_name
	barcode.text = _generate_barcode_pattern(barcode_text)
	
	# Update health to show completion status
	_update_completion_status()

func _update_info_board_with_map_data():
	"""Update info board using map data from map_data.json"""
	# Extract level number from map name if possible
	var level_number = _extract_level_number(current_map_name)
	
	# Update level number
	if show_level_number:
		level_number_label.text = "%02d" % level_number
	else:
		level_number_label.text = str(level_number)
	
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

func _extract_level_number(map_name: String) -> int:
	"""Extract level number from map name"""
	# Try to find numbers in the map name
	var regex = RegEx.new()
	regex.compile("\\d+")
	var result = regex.search(map_name)
	
	if result:
		return int(result.get_string())
	
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

func _load_blurb_or_description(map_name: String, fallback_description: String) -> String:
	"""Load blurb.md content if it exists, otherwise return the fallback description"""
	if map_name.is_empty():
		return fallback_description

	# Try multiple path candidates:
	# 1. lookup_name (folder name, e.g., "Point_One")
	# 2. map_name with spaces replaced by underscores
	# 3. map_name as-is (unlikely but try anyway)
	var path_candidates: Array[String] = []

	if not current_lookup_name.is_empty():
		path_candidates.append(current_lookup_name)

	var underscored_name = map_name.replace(" ", "_")
	if underscored_name != current_lookup_name:
		path_candidates.append(underscored_name)

	if map_name != underscored_name and map_name != current_lookup_name:
		path_candidates.append(map_name)

	for candidate in path_candidates:
		var blurb_path = "res://commons/maps/%s/blurb.md" % candidate
		print("AnnotationInfoBoard: Trying blurb path: %s" % blurb_path)
		if FileAccess.file_exists(blurb_path):
			var file = FileAccess.open(blurb_path, FileAccess.READ)
			if file:
				var content = file.get_as_text().strip_edges()
				file.close()
				if not content.is_empty():
					print("AnnotationInfoBoard: ✅ Loaded blurb.md from '%s'" % blurb_path)
					return content

	print("AnnotationInfoBoard: No blurb.md found, using JSON description")
	return fallback_description

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
