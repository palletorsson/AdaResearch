extends Node3D

# Row of 4 cubes arranged in X direction
# Each cube is spaced 1 unit apart

@export var show_binary_table: bool = true
@export var debug: bool = false

# Array data (1D array for binary table)
var array_data: Array = []

# Reference to binary table for updates
var _binary_table: Node3D = null

# Track cube references by index
var _cube_refs: Dictionary = {}  # index -> cube_instance

func _ready() -> void:
	create_row()
	if show_binary_table:
		_create_binary_table()

func create_row() -> void:
	# Load the pickup cube scene
	var pickup_cube_scene = preload("res://commons/scenes/mapobjects/pick_up_cube.tscn")

	# Initialize array data as row of 1s
	array_data = [[1, 1, 1, 1]]  # 1 row, 4 columns

	# Create 4 cubes in X direction
	for i in range(4):
		var cube_instance = pickup_cube_scene.instantiate()
		cube_instance.name = "Cube_" + str(i)

		# Position cubes 1 unit apart in X direction
		cube_instance.position = Vector3(i * 1.0, 0, 0)

		# Store index in metadata for tracking
		cube_instance.set_meta("array_index", i)

		# Connect to tree_exiting signal to detect when cube is picked up/removed
		cube_instance.tree_exiting.connect(_on_cube_removed.bind(i))

		# Store reference
		_cube_refs[i] = cube_instance

		# Add Index Label
		var label = Label3D.new()
		label.text = "[%d]" % i
		label.font_size = 24
		label.pixel_size = 0.003
		label.outline_size = 0
		label.position = Vector3(0, 1.0, 0)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = Color(1.0, 0.7, 0.8)  # Light pink
		cube_instance.add_child(label)

		add_child(cube_instance)

func _create_binary_table() -> void:
	# Load the binary table display scene
	var table_scene = load("res://algorithms/arrays/binary_table/binary_table_display.tscn")
	if not table_scene:
		push_warning("Row3X: Could not load binary table display scene")
		return

	var table = table_scene.instantiate()
	table.name = "BinaryTableDisplay"

	# Position table above the row
	table.position = Vector3(1.5, 2.0, -1.0)
	table.rotation_degrees = Vector3(0, 0, 0)

	# Configure table (1 row, 4 columns) - BIGGER for visibility
	table.rows = 1
	table.cols = 4
	table.title = "array[i]"
	table.cell_size = 0.22  # Increased from 0.12
	table.font_size = 56    # Increased from 32
	table.data = array_data

	add_child(table)

	# Store reference for updates when cubes are removed
	_binary_table = table

func _on_cube_removed(index: int) -> void:
	# Called when a cube is picked up or removed from the row
	if debug:
		print("Row3X: Cube removed at index [%d]" % index)

	# Update array data
	if array_data.size() > 0 and index >= 0 and index < array_data[0].size():
		array_data[0][index] = 0

	# Update binary table display
	if _binary_table and _binary_table.has_method("set_cell"):
		_binary_table.set_cell(0, index, 0)

	# Remove from tracking
	if _cube_refs.has(index):
		_cube_refs.erase(index)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

