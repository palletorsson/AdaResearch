# UtilityRegistry.gd
extends RefCounted
class_name UtilityRegistry

# Centralized utility type definitions - SINGLE SOURCE OF TRUTH
# This is the authoritative definition for all utility types used in the grid system
const UTILITY_TYPES = {
	# Transportation utilities
	"l": {
		"name": "platform_lift", 
		"file": "platform_lift_scene.tscn", 
		"category": "transport",
		"description": "Vertical platform that lifts players",
		"supports_parameters": true
	},
	"d": {
		"name": "door", 
		"file": "door_scene.tscn", 
		"category": "transport",
		"description": "Transitions between areas",
		"supports_parameters": false
	},
 
	"wp": {
		"name": "walkway", 
		"file": "walkableprism.tscn", 
		"category": "transport",
		"description": "walkway walk your way",
		"supports_parameters": true  # destination, spawn point
	},
	"t": {
		"name": "teleport", 
		"file": "teleport_scene.tscn", 
		"category": "transport",
		"description": "Instant location changes",
		"supports_parameters": true  # destination, spawn point
	},
	"s": {
		"name": "spawn_point", 
		"file": "spawn_point_scene.tscn", 
		"category": "transport",
		"description": "Player starting position and respawn location",
		"supports_parameters": true  # spawn_name, rotation, priority
	},
	"sp": {
	"name": "score points", 
	"file": "score_cube.tscn", 
	"category": "score",
	"description": "show score",
	"supports_parameters": true  # position, height_offset, warning_distance
	},
	"an": {
	"name": "annotation_cube", 
	"file": "info_board.tscn", 
	"category": "ui",
	"description": "Displays current map name and description",
	"supports_parameters": true  # display_mode, text_scale
	},
	"r": {
	"name": "reset_cube", 
	"file": "reset_cube.tscn", 
	"category": "safety",
	"description": "Resets player to safe position when approached",
	"supports_parameters": true  # position, height_offset, warning_distance
	},
	"q": {
		"name": "quit_cube", 
		"file": "quit_cube.tscn", 
		"category": "game_control",
		"description": "Quit game when player approaches - with confirmation",
		"supports_parameters": true  # confirmation_timeout, require_confirmation
	},
	# Visual/Structural utilities
	"el": {
		"name": "extra_light",
		"file": "overhead_light.tscn",
		"category": "visual",
		"description": "An extra overhead light.",
		"supports_parameters": true
	},
	"w": {
		"name": "window", 
		"file": "window_scene.tscn", 
		"category": "visual",
		"description": "Visual portals and openings",
		"supports_parameters": false
	},
	"a": {
		"name": "wall", 
		"file": "wall_scene.tscn", 
		"category": "structure",
		"description": "Barriers and boundaries",
		"supports_parameters": true  # material, transparency
	},
	"hb": {
		"name": "horizontal_border", 
		"file": "horizontalboarder.tscn", 
		"category": "structure",
		"description": "Horizontal border element",
		"supports_parameters": false
	},
	
	# Furniture utilities
	"b": {
		"name": "table", 
		"file": "table_scene.tscn", 
		"category": "furniture",
		"description": "Surface for objects and interaction",
		"supports_parameters": false
	},
	
	# Interactive utilities
	"p": {
		"name": "pick_up", 
		"file": "pick_up_cube.tscn", 
		"category": "interactive",
		"description": "Grabbable objects for interaction",
		"supports_parameters": false
	},
	"n": {
		"name": "next_cube", 
		"file": "next_cube.tscn", 
		"category": "interactive",
		"description": "Advances to next example/pattern with 3s respawn",
		"supports_parameters": true  # respawn_time, rotation_speed
	},

	"rg": {
		"name": "regenerate_cube", 
		"file": "regenerate_cube.tscn", 
		"category": "interactive",
		"description": "Triggers regenerate signal for linked listings",
		"supports_parameters": true
	},
	"tc": {
		"name": "transport_cube", 
		"file": "transport_cube.tscn", 
		"category": "transport",
		"description": "Cube that carries players across voids with directional movement",
		"supports_parameters": true  # distance:direction (e.g. "4:z" or "3.5:1,0,0")
	},
	
	# UI/Information utilities
	"x": {
		"name": "xp_label", 
		"file": "xp_label.tscn", 
		"category": "ui",
		"description": "Experience point displays",
		"supports_parameters": false
	},
	"i": {
		"name": "info_board",
		"file": "info_board.tscn",
		"category": "educational",
		"description": "Information and instruction displays",
		"supports_parameters": false
	},
	"la": {
		"name": "label",
		"file": "info_label.tscn",
		"category": "ui",
		"description": "Displays artifact name from grid_artifacts.json by keyid",
		"supports_parameters": true  # keyid parameter
	},

	# Navigation utilities
	"arrow": {
		"name": "exit_arrow", 
		"file": "exit_arrow_scene.tscn", 
		"category": "navigation",
		"description": "Directional indicators and exits",
		"supports_parameters": true  # direction, destination
	},
	
	# Empty space
	" ": {
		"name": "none", 
		"file": "", 
		"category": "empty",
		"description": "Empty grid space",
		"supports_parameters": false
	}
}

# Categories for organizing utilities
const CATEGORIES = {
	"transport": "Transportation and movement utilities",
	"visual": "Visual elements and portals", 
	"structure": "Structural elements and barriers",
	"furniture": "Furniture and static objects",
	"interactive": "Interactive and grabbable objects",
	"ui": "User interface elements",
	"educational": "Educational and informational content",
	"navigation": "Navigation aids and indicators",
	"empty": "Empty space marker"
}

# Empty space constant
const EMPTY_SPACE = " "

# Path constants
const MAP_OBJECTS_PATH = "res://commons/scenes/mapobjects/"

# Get utility type info
static func get_utility_info(type_code: String) -> Dictionary:
	if UTILITY_TYPES.has(type_code):
		return UTILITY_TYPES[type_code]
	else:
		push_warning("UtilityRegistry: Unknown utility type '%s'" % type_code)
		return {}

# Check if utility type exists
static func is_valid_utility_type(type_code: String) -> bool:
	return UTILITY_TYPES.has(type_code)

# Get utility scene file path
static func get_utility_scene_path(type_code: String) -> String:
	var info = get_utility_info(type_code)
	if info.has("file") and not info["file"].is_empty():
		return MAP_OBJECTS_PATH + info["file"]
	return ""

# Get utility name
static func get_utility_name(type_code: String) -> String:
	var info = get_utility_info(type_code)
	return info.get("name", "unknown")

# Get utility category
static func get_utility_category(type_code: String) -> String:
	var info = get_utility_info(type_code)
	return info.get("category", "unknown")

# Get utility description
static func get_utility_description(type_code: String) -> String:
	var info = get_utility_info(type_code)
	return info.get("description", "No description available")

# Check if utility supports parameters
static func supports_parameters(type_code: String) -> bool:
	var info = get_utility_info(type_code)
	return info.get("supports_parameters", false)

# Get all utilities by category
static func get_utilities_by_category(category: String) -> Array:
	var result = []
	for type_code in UTILITY_TYPES.keys():
		var info = UTILITY_TYPES[type_code]
		if info.get("category") == category:
			result.append({
				"code": type_code,
				"name": info.get("name"),
				"file": info.get("file"),
				"description": info.get("description")
			})
	return result

# Get all available categories
static func get_all_categories() -> Array:
	return CATEGORIES.keys()

# Get category description
static func get_category_description(category: String) -> String:
	return CATEGORIES.get(category, "Unknown category")

# Validate utility data grid
static func validate_utility_grid(grid_data: Array) -> Dictionary:
	var validation_result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"unknown_types": []
	}
	
	for z in range(grid_data.size()):
		var row = grid_data[z]
		for x in range(row.size()):
			var cell_value = str(row[x]).strip_edges()
			
			# Skip empty cells
			if cell_value.is_empty() or cell_value == " ":
				continue
				
			# Extract base utility type (first character or before first colon)
			var utility_type = cell_value[0] if not cell_value.is_empty() else " "
			if ":" in cell_value:
				utility_type = cell_value.split(":")[0]
			
			# Check if utility type is valid
			if not is_valid_utility_type(utility_type):
				validation_result.valid = false
				validation_result.errors.append(
					"Unknown utility type '%s' at position [%d, %d]" % [utility_type, x, z]
				)
				if not validation_result.unknown_types.has(utility_type):
					validation_result.unknown_types.append(utility_type)
			
			# Check for parameter usage with non-parameter utilities
			if ":" in cell_value and not supports_parameters(utility_type):
				validation_result.warnings.append(
					"Utility type '%s' at [%d, %d] has parameters but doesn't support them" % [utility_type, x, z]
				)
	
	return validation_result

# Parse utility cell value with parameters
static func parse_utility_cell(cell_value: String) -> Dictionary:
	var result = {
		"type": " ",
		"parameters": []
	}
	
	if cell_value.is_empty():
		return result
		
	var clean_value = cell_value.strip_edges()
	if clean_value.is_empty() or clean_value == " ":
		return result
	
	# Split by colon to separate type from parameters
	var parts = clean_value.split(":")
	result.type = parts[0]
	
	# Extract parameters if they exist
	if parts.size() > 1:
		for i in range(1, parts.size()):
			if not parts[i].is_empty():
				result.parameters.append(parts[i])
	
	return result

# Generate utility type mapping comment for data files
static func generate_utility_mapping_comment() -> String:
	var comment_lines = [
		"# Utility type mapping (auto-generated - do not edit manually)",
		"# Generated by UtilityRegistry.gd - single source of truth for utility types"
	]
	
	# Group by category
	var categories_used = {}
	for type_code in UTILITY_TYPES.keys():
		if type_code == " ":
			continue
		var category = get_utility_category(type_code)
		if not categories_used.has(category):
			categories_used[category] = []
		categories_used[category].append(type_code)
	
	# Add category sections
	for category in categories_used.keys():
		comment_lines.append("# %s:" % category.capitalize())
		for type_code in categories_used[category]:
			var name = get_utility_name(type_code)
			var desc = get_utility_description(type_code)
			comment_lines.append("# \"%s\": %s - %s" % [type_code, name, desc])
		comment_lines.append("#")
	
	comment_lines.append("# \" \": empty space (no utility)")
	
	return "\n".join(comment_lines)

# Print utility registry summary
static func print_registry_summary():
	print("=== Utility Registry Summary ===")
	print("Total utility types: %d" % (UTILITY_TYPES.size() - 1))  # -1 for empty space
	print("Categories: %d" % CATEGORIES.size())
	
	for category in CATEGORIES.keys():
		if category == "empty":
			continue
		var utilities = get_utilities_by_category(category)
		print("  %s (%d): %s" % [category.capitalize(), utilities.size(), CATEGORIES[category]])
		for utility in utilities:
			var param_support = " (supports parameters)" if supports_parameters(utility.code) else ""
			print("    %s: %s%s" % [utility.code, utility.name, param_support]) 
