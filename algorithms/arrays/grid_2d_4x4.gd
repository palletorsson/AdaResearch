extends Node3D

# Local debug flag to gate prints (default off)
@export var debug: bool = false
@export var show_binary_table: bool = true

# 4x4 2D grid of cubes arranged in X and Z directions
# Each cube is spaced 1 units apart

# Grid data as 2D array (for binary table display)
var grid_data: Array = []

# Reference to binary table for updates
var _binary_table: Node3D = null

# Track cube references by coordinate
var _cube_refs: Dictionary = {}  # "x_z" -> cube_instance

func _ready() -> void:
	create_grid_2d()
	if show_binary_table:
		_create_binary_table()

func create_grid_2d() -> void:
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")

	# Initialize grid data as 4x4 array of 1s
	grid_data = []
	for x in range(4):
		var row: Array = []
		for z in range(4):
			row.append(1)
		grid_data.append(row)

	# Create 4x4 grid of cubes
	for x in range(4):
		for z in range(4):
			var cube_instance = pickup_cube_scene.instantiate()
			cube_instance.name = "Cube_" + str(x) + "_" + str(z)

			# Position cubes in a 4x4 grid, 1 unit apart
			cube_instance.position = Vector3(x * 1.0, 0, z * 1.0)

			# Store coordinate in metadata for tracking
			cube_instance.set_meta("grid_x", x)
			cube_instance.set_meta("grid_z", z)

			# Connect to tree_exiting signal to detect when cube is picked up/removed
			cube_instance.tree_exiting.connect(_on_cube_removed.bind(x, z))

			# Store reference
			_cube_refs["%d_%d" % [x, z]] = cube_instance

			# Add Index Label - high visibility from all angles
			var label = Label3D.new()
			label.text = "[%d, %d]" % [x, z]
			label.font_size = 32  # Larger for VR
			label.pixel_size = 0.003
			label.outline_size = 6  # Add outline for visibility
			label.outline_modulate = Color(0, 0, 0, 1)  # Black outline
			label.position = Vector3(0, 1.0, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true  # Always visible, even through objects
			label.modulate = Color(1.0, 1.0, 1.0)  # White for maximum contrast
			cube_instance.add_child(label)

			add_child(cube_instance)

func _create_binary_table() -> void:
	# Load the binary table display scene
	var table_scene = load("res://algorithms/arrays/binary_table/binary_table_display.tscn")
	if not table_scene:
		push_warning("Grid2D4x4: Could not load binary table display scene")
		return

	var table = table_scene.instantiate()
	table.name = "BinaryTableDisplay"

	# Position table to the side of the grid (left side, facing the grid)
	table.position = Vector3(-2.0, 1.8, 1.5)
	table.rotation_degrees = Vector3(0, 90, 0)  # Face toward the grid

	# Configure table - BIGGER for visibility
	table.rows = 4
	table.cols = 4
	table.title = ""  # No title
	table.cell_size = 0.22  # Increased from 0.12
	table.font_size = 56    # Increased from 32
	table.data = grid_data

	add_child(table)

	# Store reference for updates when cubes are removed
	_binary_table = table

func _on_cube_removed(x: int, z: int) -> void:
	# Called when a cube is picked up or removed from the grid
	if debug:
		print("Grid2D4x4: Cube removed at [%d, %d]" % [x, z])

	# Update grid data
	if x >= 0 and x < grid_data.size():
		if z >= 0 and z < grid_data[x].size():
			grid_data[x][z] = 0

	# Update binary table display
	if _binary_table and _binary_table.has_method("set_cell"):
		_binary_table.set_cell(x, z, 0)

	# Remove from tracking
	var key = "%d_%d" % [x, z]
	if _cube_refs.has(key):
		_cube_refs.erase(key)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	var cols = int(config["cols"]) if config.has("cols") else 4
	var rows = int(config["rows"]) if config.has("rows") else 4
	var spacing = float(config["spacing"]) if config.has("spacing") else 1.0
	var label_size = int(config["label_size"]) if config.has("label_size") else 32
	var label_color = Color.from_string(config["label_color"], Color.WHITE) if config.has("label_color") else Color.WHITE
	if config.has("show_binary_table"):
		show_binary_table = config["show_binary_table"] is bool and config["show_binary_table"]

	# Rebuild
	for child in get_children():
		if not child.owner:
			child.queue_free()
	_cube_refs.clear()
	_binary_table = null
	await get_tree().process_frame

	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")
	grid_data = []
	for x in range(cols):
		var row: Array = []
		for z in range(rows):
			row.append(1)
		grid_data.append(row)

	for x in range(cols):
		for z in range(rows):
			var cube_instance = pickup_cube_scene.instantiate()
			cube_instance.name = "Cube_%d_%d" % [x, z]
			cube_instance.position = Vector3(x * spacing, 0, z * spacing)
			cube_instance.set_meta("grid_x", x)
			cube_instance.set_meta("grid_z", z)
			cube_instance.tree_exiting.connect(_on_cube_removed.bind(x, z))
			_cube_refs["%d_%d" % [x, z]] = cube_instance

			var label = Label3D.new()
			label.text = "[%d, %d]" % [x, z]
			label.font_size = label_size
			label.pixel_size = 0.003
			label.outline_size = 6
			label.outline_modulate = Color(0, 0, 0, 1)
			label.position = Vector3(0, 1.0, 0)
			label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
			label.no_depth_test = true
			label.modulate = label_color
			cube_instance.add_child(label)

			add_child(cube_instance)

	if show_binary_table:
		_create_binary_table()
