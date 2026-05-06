# InfoBoardComponent.gd
# Component for placing handheld info boards in 3D scenes
# Follows the same pattern as GridUtilitiesComponent for consistent usage
extends Node
class_name InfoBoardComponent

# References
var parent_node: Node3D
var structure_component = null  # Optional: can work without grid structure

# Settings
var cube_size: float = 1.0
var gutter: float = 0.0
var default_height: float = 1.5  # Default height for info boards

# Info board tracking
var info_boards: Dictionary = {}  # Vector3i -> Node3D
var scene_cache: Dictionary = {}

# Signals
signal board_generation_complete(board_count: int)
signal board_interacted(board_type: String, position: Vector3, data: Dictionary)

func _ready():
	print("InfoBoardComponent: Initialized")

# Initialize with references and settings
func initialize(parent: Node3D, settings: Dictionary = {}):
	parent_node = parent

	# Apply settings
	cube_size = settings.get("cube_size", 1.0)
	gutter = settings.get("gutter", 0.0)
	default_height = settings.get("default_height", 1.5)

	print("InfoBoardComponent: Initialized with cube_size=%f, gutter=%f, default_height=%f" % [cube_size, gutter, default_height])

# Initialize with grid structure component (optional)
func initialize_with_structure(parent: Node3D, struct_component, settings: Dictionary = {}):
	initialize(parent, settings)
	structure_component = struct_component
	print("InfoBoardComponent: Initialized with structure component")

# Generate info boards from layout data
func generate_boards(board_data, board_definitions: Dictionary = {}):
	if not board_data:
		print("InfoBoardComponent: No board data provided")
		return

	var layout_data

	# Handle both raw arrays and objects with layout_data property
	if typeof(board_data) == TYPE_ARRAY:
		layout_data = board_data
	elif "layout_data" in board_data:
		# Works for both dictionaries and objects (like JsonUtilityDataAdapter)
		layout_data = board_data.layout_data
	else:
		print("InfoBoardComponent: Invalid board data format (expected Array or object with layout_data)")
		print("InfoBoardComponent: Received type: %s" % typeof(board_data))
		return

	print("InfoBoardComponent: Generating info boards")

	var total_size = cube_size + gutter
	var board_count = 0

	# Validate boards using InfoBoardRegistry
	var validation = InfoBoardRegistry.validate_board_config(layout_data)
	if not validation.valid:
		print("InfoBoardComponent: WARNING - Board validation issues:")
		for error in validation.errors:
			print("  ERROR: %s" % error)
		for warning in validation.warnings:
			print("  WARNING: %s" % warning)

	# Place info boards
	for z in range(layout_data.size()):
		var row = layout_data[z]
		for x in range(row.size()):
			var board_cell = str(row[x]).strip_edges()

			if board_cell.is_empty() or board_cell == " ":
				continue

			# Parse board cell with parameters
			var parsed = InfoBoardRegistry.parse_board_cell(board_cell)
			var board_type = parsed.type
			var parameters = parsed.parameters

			if InfoBoardRegistry.is_valid_board_type(board_type):
				# Determine Y position
				var y_pos = default_height

				# If we have structure component, find highest Y
				if structure_component and structure_component.has_method("find_highest_y_at"):
					y_pos = structure_component.find_highest_y_at(x, z)

				# Get board definition if available
				var board_definition = board_definitions.get(board_type, {})

				_place_board(x, y_pos, z, board_type, parameters, board_definition, total_size)
				board_count += 1

	print("InfoBoardComponent: Added %d info boards" % board_count)
	board_generation_complete.emit(board_count)

# Create a board using the universal template
# This allows boards to work with just JSON content, no scene file needed
func _create_board_with_universal_template(board_id: String) -> Node3D:
	# Check if content exists for this board
	var page_count = InfoBoardContentLoader.get_page_count(board_id)
	if page_count == 0:
		return null  # No content, can't create board

	# Load the base handheld InfoBoard scene
	var base_scene_path = "res://commons/infoboards_3d/base/HandheldInfoBoard.tscn"
	if not ResourceLoader.exists(base_scene_path):
		print("InfoBoardComponent: WARNING - HandheldInfoBoard base scene not found at: %s" % base_scene_path)
		return null

	var board_3d = load(base_scene_path).instantiate()

	# Get the InfoBoardUI control from the Viewport2Din3D structure
	var ui = board_3d.get_node_or_null("BoardFrame/TabletFrame/Viewport2Din3D/Viewport/InfoBoardUI")
	if not ui:
		print("InfoBoardComponent: WARNING - Could not find InfoBoardUI in HandheldInfoBoard for board_id '%s'" % board_id)
		board_3d.queue_free()
		return null

	# Apply the UniversalInfoBoard script
	var universal_script = load("res://commons/infoboards_3d/base/UniversalInfoBoard.gd")
	ui.set_script(universal_script)
	ui.board_id = board_id

	print("InfoBoardComponent: Created board '%s' using UniversalInfoBoard template (Content: %d pages)" % [board_id, page_count])

	return board_3d

# Place a single info board
func _place_board(x: int, y: int, z: int, board_type: String, parameters: Array, definition: Dictionary, total_size: float):
	var position = Vector3(x, y, z) * total_size

	# NEW: Try to create board using universal template first
	var board_object = _create_board_with_universal_template(board_type)

	# Fallback: Try loading from registry scene path
	if not board_object:
		var scene_path = InfoBoardRegistry.get_board_scene_path(board_type)
		if scene_path.is_empty():
			print("InfoBoardComponent: WARNING - No scene file for board type '%s'" % board_type)
			return

		var scene_resource = _load_scene_cached(scene_path)
		if not scene_resource:
			print("InfoBoardComponent: WARNING - Could not load scene for board type '%s'" % board_type)
			return

		board_object = scene_resource.instantiate()
	if board_object:
		board_object.position = position

		# Apply parameters if supported
		if parameters.size() > 0 and InfoBoardRegistry.supports_parameters(board_type):
			print("InfoBoardComponent: Applying parameters for board type '%s'" % board_type)
			_apply_board_parameters(board_object, board_type, parameters)

		# Apply definition properties
		_apply_board_definition(board_object, board_type, definition)

		# Connect signals if board has them
		_connect_board_signals(board_object, board_type)

		parent_node.add_child(board_object)

		# Set owner for editor
		if parent_node.get_tree() and parent_node.get_tree().edited_scene_root:
			board_object.owner = parent_node.get_tree().edited_scene_root

		info_boards[Vector3i(x, y, z)] = board_object

		var param_info = ""
		if parameters.size() > 0:
			param_info = " (params: %s)" % str(parameters)
		print("  Added %s at (%d,%d,%d)%s" % [InfoBoardRegistry.get_board_name(board_type), x, y, z, param_info])

# Apply board parameters
func _apply_board_parameters(board_object: Node3D, board_type: String, parameters: Array):
	# Common parameter: height offset
	if parameters.size() > 0:
		var param = parameters[0]
		if param.is_valid_float():
			var height_offset = float(param)
			board_object.position.y += height_offset
			print("InfoBoardComponent: Applied height offset: %.2f" % height_offset)

	# Board-specific parameters can be added here
	# For example: rotation, scale, specific page to open, etc.

# Apply board definition properties from configuration
func _apply_board_definition(board_object: Node3D, board_type: String, definition: Dictionary):
	if definition.is_empty():
		return

	var properties = definition.get("properties", {})

	# Apply generic properties
	for property_name in properties.keys():
		var property_value = properties[property_name]
		if property_name in board_object:
			board_object.set(property_name, property_value)
		else:
			# Store as metadata if property doesn't exist
			board_object.set_meta(property_name, property_value)

	# Apply category color if specified
	if properties.has("category"):
		var category = properties["category"]
		var color = InfoBoardRegistry.get_category_color(category)
		_set_board_color(board_object, color)

# Set board color (theme color)
func _set_board_color(board_object: Node3D, color: Color):
	# Find the InfoBoardUI control and set its category color
	var ui_node = _find_info_board_ui(board_object)
	if ui_node and "category_color" in ui_node:
		ui_node.category_color = color
		print("InfoBoardComponent: Set board category color to %s" % color)

# Find InfoBoardUI node in board hierarchy
func _find_info_board_ui(board_object: Node3D) -> Control:
	# Check common locations
	var potential_paths = [
		"SubViewport/InfoBoardUI",
		"Viewport/InfoBoardUI",
		"InfoBoardUI"
	]

	for path in potential_paths:
		var ui_node = board_object.get_node_or_null(path)
		if ui_node:
			return ui_node

	# Search recursively
	return _find_control_recursive(board_object)

func _find_control_recursive(node: Node) -> Control:
	if node is Control and node.get_script() and node.get_script().get_global_name() == "AlgorithmInfoBoardBase":
		return node

	for child in node.get_children():
		var found = _find_control_recursive(child)
		if found:
			return found

	return null

# Connect board signals
func _connect_board_signals(board_object: Node3D, board_type: String):
	# Find the UI controller and connect its signals
	var ui_node = _find_info_board_ui(board_object)
	if not ui_node:
		return

	# Connect page_changed signal
	if ui_node.has_signal("page_changed"):
		ui_node.page_changed.connect(_on_board_page_changed.bind(board_type, board_object))
		print("InfoBoardComponent: Connected page_changed signal for %s" % board_type)

	# Connect animation_toggled signal
	if ui_node.has_signal("animation_toggled"):
		ui_node.animation_toggled.connect(_on_board_animation_toggled.bind(board_type, board_object))

# Handle board page change
func _on_board_page_changed(page_index: int, board_type: String, board_object: Node3D):
	var board_data = {
		"position": board_object.global_position,
		"name": board_object.name,
		"type": board_type,
		"page_index": page_index
	}

	print("InfoBoardComponent: Board page changed to %d" % page_index)
	board_interacted.emit(board_type, board_object.global_position, board_data)

# Handle board animation toggle
func _on_board_animation_toggled(is_playing: bool, board_type: String, board_object: Node3D):
	print("InfoBoardComponent: Board animation toggled: %s" % ("playing" if is_playing else "paused"))

# Load scene with caching
func _load_scene_cached(scene_path: String) -> PackedScene:
	if scene_path.is_empty():
		return null

	if scene_cache.has(scene_path):
		return scene_cache[scene_path]

	print("InfoBoardComponent: Attempting to load scene: %s" % scene_path)

	if ResourceLoader.exists(scene_path):
		var scene = ResourceLoader.load(scene_path)
		scene_cache[scene_path] = scene
		print("InfoBoardComponent: ✅ Successfully loaded scene: %s" % scene_path)
		return scene
	else:
		print("InfoBoardComponent: ❌ ERROR - Scene file not found: %s" % scene_path)
		_list_available_board_scenes()
		return null

# Debug: List available board scenes
func _list_available_board_scenes():
	print("InfoBoardComponent: Listing available board scenes in %s:" % InfoBoardRegistry.INFO_BOARD_SCENES_PATH)

	var dir = DirAccess.open(InfoBoardRegistry.INFO_BOARD_SCENES_PATH)
	if dir:
		dir.list_dir_begin()
		var file_name = dir.get_next()

		while file_name != "":
			if file_name.ends_with(".tscn"):
				print("  → %s" % file_name)
			file_name = dir.get_next()
	else:
		print("InfoBoardComponent: Could not open scenes directory: %s" % InfoBoardRegistry.INFO_BOARD_SCENES_PATH)

# Place a single board at arbitrary position (no grid)
func place_board_at(board_type: String, position: Vector3, parameters: Array = [], definition: Dictionary = {}):
	if not InfoBoardRegistry.is_valid_board_type(board_type):
		push_error("InfoBoardComponent: Invalid board type '%s'" % board_type)
		return null

	var scene_path = InfoBoardRegistry.get_board_scene_path(board_type)
	if scene_path.is_empty():
		push_error("InfoBoardComponent: No scene file for board type '%s'" % board_type)
		return null

	var scene_resource = _load_scene_cached(scene_path)
	if not scene_resource:
		push_error("InfoBoardComponent: Could not load scene for board type '%s'" % board_type)
		return null

	var board_object = scene_resource.instantiate()
	if board_object:
		board_object.position = position

		if parameters.size() > 0:
			_apply_board_parameters(board_object, board_type, parameters)

		_apply_board_definition(board_object, board_type, definition)
		_connect_board_signals(board_object, board_type)

		parent_node.add_child(board_object)

		print("InfoBoardComponent: Placed %s at %s" % [InfoBoardRegistry.get_board_name(board_type), position])
		return board_object

	return null

# Get board at grid position
func get_board_at(x: int, y: int, z: int) -> Node3D:
	var key = Vector3i(x, y, z)
	return info_boards.get(key, null)

# Check if position has board
func has_board_at(x: int, y: int, z: int) -> bool:
	return info_boards.has(Vector3i(x, y, z))

# Clear all boards
func clear_boards():
	print("InfoBoardComponent: Clearing all info boards")

	for key in info_boards.keys():
		var board = info_boards[key]
		if is_instance_valid(board):
			board.queue_free()

	info_boards.clear()

# Get board count
func get_board_count() -> int:
	return info_boards.size()

# Get all board positions
func get_all_board_positions() -> Array:
	return info_boards.keys()

# Debug: Print all boards
func print_all_boards():
	print("InfoBoardComponent: Current boards:")
	for pos in info_boards.keys():
		var board = info_boards[pos]
		print("  Position: %s, Board: %s" % [pos, board.name])
