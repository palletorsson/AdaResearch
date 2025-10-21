# InfoBoardRegistry.gd
# Central registry for all info board types and their configurations
# Similar to UtilityRegistry for consistent type definitions
extends RefCounted
class_name InfoBoardRegistry

# Info board type definitions
# Use syntax: ib:randomwalk, ib:bfs, etc.
const INFO_BOARD_TYPES = {
	"randomwalk": {
		"name": "Random Walk Info Board",
		"category": "Randomness",
		"scene": "RandomWalk/RandomWalkInfoBoard.tscn",
		"description": "Explains random walk algorithms",
		"color": Color(0.8, 0.5, 0.9),
		"supports_parameters": true  # Can have height offset
	},
	"point": {
		"name": "Point Info Board",
		"category": "Fundamentals",
		"scene": "Point/PointInfoBoard.tscn",
		"description": "The fundamental building block - understanding points in 3D space",
		"color": Color(1.0, 0.9, 0.2),
		"supports_parameters": true
	},
	"line": {
		"name": "Line Info Board",
		"category": "Fundamentals",
		"scene": "Line/LineInfoBoard.tscn",
		"description": "Connecting points - lines, direction, and paths in 3D space",
		"color": Color(0.2, 0.8, 1.0),
		"supports_parameters": true
	},
	"vectors": {
		"name": "Vectors Info Board",
		"category": "Mathematics",
		"scene": "Vectors/VectorsInfoBoard.tscn",
		"description": "Vector mathematics and physics",
		"color": Color(0.6, 0.8, 0.9),
		"supports_parameters": true
	},
	"forces": {
		"name": "Forces Info Board",
		"category": "Physics",
		"scene": "Forces/ForcesInfoBoard.tscn",
		"description": "Forces, gravity, friction, and motion",
		"color": Color(0.9, 0.5, 0.6),
		"supports_parameters": true
	},
	"unitcircle": {
		"name": "Unit Circle & Waves Info Board",
		"category": "Mathematics",
		"scene": "UnitCircle/WaveInfoBoard.tscn",
		"description": "Trigonometric functions and wave patterns",
		"color": Color(0.5, 0.8, 0.9),
		"supports_parameters": true
	},
	"bfs": {
		"name": "BFS Info Board",
		"category": "Graph Theory",
		"scene": "BFSInfoBoard.tscn",
		"description": "Breadth-First Search algorithm",
		"color": Color(0.3, 0.8, 0.5),
		"supports_parameters": true
	},
	"neural": {
		"name": "Neural Network Info Board",
		"category": "Machine Learning",
		"scene": "NeuralNetworkInfoBoard.tscn",
		"description": "Neural network fundamentals",
		"color": Color(0.9, 0.6, 0.3),
		"supports_parameters": true
	},
	"sorting": {
		"name": "Sorting Algorithms Info Board",
		"category": "Algorithms",
		"scene": "SortingInfoBoard.tscn",
		"description": "Comparison of sorting algorithms",
		"color": Color(0.5, 0.7, 0.9),
		"supports_parameters": true
	}
}

# Category colors for consistent theming
const CATEGORY_COLORS = {
	"Fundamentals": Color(1.0, 0.9, 0.2),
	"Randomness": Color(0.8, 0.5, 0.9),
	"Mathematics": Color(0.6, 0.8, 0.9),
	"Graph Theory": Color(0.3, 0.8, 0.5),
	"Machine Learning": Color(0.9, 0.6, 0.3),
	"Algorithms": Color(0.5, 0.7, 0.9),
	"Data Structures": Color(0.7, 0.4, 0.8),
	"Physics": Color(0.4, 0.6, 0.9),
	"Procedural Generation": Color(0.6, 0.9, 0.5),
	"Cellular Automata": Color(0.9, 0.7, 0.4),
	"Fractals": Color(0.8, 0.3, 0.6),
	"Wave Functions": Color(0.5, 0.8, 0.9),
	"Critical Theory": Color(0.7, 0.5, 0.7)
}

# Base path for info board scenes
const INFO_BOARD_SCENES_PATH = "res://commons/infoboards_3d/boards/"

# Check if board type is valid
static func is_valid_board_type(board_type: String) -> bool:
	return INFO_BOARD_TYPES.has(board_type)

# Get board type info
static func get_board_info(board_type: String) -> Dictionary:
	return INFO_BOARD_TYPES.get(board_type, {})

# Get board scene path
static func get_board_scene_path(board_type: String) -> String:
	var info = get_board_info(board_type)
	if info.is_empty():
		return ""
	return INFO_BOARD_SCENES_PATH + info.get("scene", "")

# Get board name
static func get_board_name(board_type: String) -> String:
	var info = get_board_info(board_type)
	return info.get("name", "Unknown Board")

# Get board category
static func get_board_category(board_type: String) -> String:
	var info = get_board_info(board_type)
	return info.get("category", "General")

# Get board color
static func get_board_color(board_type: String) -> Color:
	var info = get_board_info(board_type)
	return info.get("color", Color.WHITE)

# Get category color
static func get_category_color(category: String) -> Color:
	return CATEGORY_COLORS.get(category, Color(0.6, 0.6, 0.7))

# Parse board cell notation (e.g., "ib:randomwalk:1.5" -> type + parameters)
# Supports both formats:
#   "ib:randomwalk" -> board type is "randomwalk"
#   "ib:randomwalk:0.5" -> board type is "randomwalk" with height offset 0.5
static func parse_board_cell(cell: String) -> Dictionary:
	var parts = cell.split(":")
	var parameters = []
	var board_type = ""

	# Check if using new "ib:" syntax
	if parts.size() >= 2 and parts[0].strip_edges() == "ib":
		# New syntax: ib:randomwalk or ib:randomwalk:0.5
		board_type = parts[1].strip_edges()

		# Parse additional parameters (height offset, etc.)
		for i in range(2, parts.size()):
			parameters.append(parts[i].strip_edges())
	else:
		# Old syntax for backwards compatibility: ib_randomwalk or ib_randomwalk:0.5
		board_type = parts[0].strip_edges()

		# Parse parameters
		for i in range(1, parts.size()):
			parameters.append(parts[i].strip_edges())

	return {
		"type": board_type,
		"parameters": parameters
	}

# Supports parameters (for future expansion)
static func supports_parameters(board_type: String) -> bool:
	var info = get_board_info(board_type)
	return info.get("supports_parameters", false)

# Validate board configuration
static func validate_board_config(board_data: Array) -> Dictionary:
	var result = {
		"valid": true,
		"errors": [],
		"warnings": [],
		"board_count": 0
	}

	for z in range(board_data.size()):
		var row = board_data[z]
		for x in range(row.size()):
			var cell = str(row[x]).strip_edges()

			if cell.is_empty() or cell == " ":
				continue

			var parsed = parse_board_cell(cell)
			var board_type = parsed.type

			# Check if valid board type
			if not is_valid_board_type(board_type):
				result.errors.append("Invalid board type '%s' at position (%d, %d)" % [board_type, x, z])
				result.valid = false
			else:
				result.board_count += 1

				# Check for scene file
				var scene_path = get_board_scene_path(board_type)
				if not ResourceLoader.exists(scene_path):
					result.warnings.append("Scene file missing for board type '%s' at (%d, %d): %s" % [board_type, x, z, scene_path])

	return result

# Get all board types for a category
static func get_boards_by_category(category: String) -> Array:
	var boards = []
	for board_type in INFO_BOARD_TYPES.keys():
		var info = INFO_BOARD_TYPES[board_type]
		if info.get("category", "") == category:
			boards.append(board_type)
	return boards

# Get all categories
static func get_all_categories() -> Array:
	var categories = []
	for board_type in INFO_BOARD_TYPES.keys():
		var category = INFO_BOARD_TYPES[board_type].get("category", "")
		if not category.is_empty() and not categories.has(category):
			categories.append(category)
	return categories

# Register new board type dynamically (for content generation)
static func register_board_type(board_type: String, info: Dictionary) -> void:
	# Validate required fields
	if not info.has("name"):
		push_error("InfoBoardRegistry: Cannot register board without 'name'")
		return
	if not info.has("scene"):
		push_error("InfoBoardRegistry: Cannot register board without 'scene'")
		return

	# Set defaults
	if not info.has("category"):
		info["category"] = "General"
	if not info.has("description"):
		info["description"] = ""
	if not info.has("color"):
		info["color"] = Color.WHITE
	if not info.has("supports_parameters"):
		info["supports_parameters"] = false

	# Register (note: modifying const at runtime doesn't work, so we'd need a runtime registry)
	# This is a placeholder for future expansion
	print("InfoBoardRegistry: Would register board type '%s' (runtime registration not yet supported)" % board_type)

# Debug: Print all registered board types
static func print_all_board_types() -> void:
	print("=== Info Board Registry ===")
	print("Total board types: %d" % INFO_BOARD_TYPES.size())
	print()

	for board_type in INFO_BOARD_TYPES.keys():
		var info = INFO_BOARD_TYPES[board_type]
		print("Type: %s" % board_type)
		print("  Name: %s" % info.get("name", "?"))
		print("  Category: %s" % info.get("category", "?"))
		print("  Scene: %s" % info.get("scene", "?"))
		print("  Color: %s" % info.get("color", Color.WHITE))
		print()
