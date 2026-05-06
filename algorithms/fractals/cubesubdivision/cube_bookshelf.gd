extends Node3D

# Cube Bookshelf - Grid subdivision creating shelves
# Demonstrates how a regular grid subdivision creates functional storage
# The "removed" cells become the storage spaces

# @identity
# essence: bookshelf = frame + horizontal_shelves(rows) + vertical_dividers(cols) + trim, uniform grid subdivision
# desire: To organize — the grid creates equal cells, and the emptiness between dividers is where meaning (books) will live
# critical_parameter: rows * columns — the grid resolution determines how many compartments emerge from the single rectangular volume
# triggers: Construction sequence: back panel → frame → shelves → dividers → crown molding; each step subdivides further
# emerges: The crown and base molding appear as aesthetic finishing — the bookshelf develops architectural personality from utility
# needs: VR place-books interaction [missing], grid size control [missing]
# relationships: Simplest grid-subdivision furniture; contrasts with cube_desk (nested hierarchy) and recursive_chair (role-based)
# truth: A bookshelf is the negative space of a grid — the shelves exist so that the gaps between them can hold something.

@export var shelf_size: float = 2.0
@export var rows: int = 4
@export var columns: int = 3
@export var show_construction: bool = true
@export var step_delay: float = 0.25

# Colors - warm wood tones
var frame_color := Color(0.45, 0.25, 0.12, 1.0)      # Dark wood frame
var shelf_color := Color(0.55, 0.35, 0.18, 1.0)      # Medium wood shelves
var back_color := Color(0.35, 0.2, 0.1, 1.0)         # Dark back panel
var accent_color := Color(0.65, 0.4, 0.2, 1.0)       # Light accent

var all_parts: Array[MeshInstance3D] = []
var step: int = 0
var timer: float = 0.0
var is_constructing: bool = false

func _ready() -> void:
	if show_construction:
		is_constructing = true
		step = 0
	else:
		_build_instant()

func _process(delta: float) -> void:
	if not is_constructing:
		return

	timer += delta
	if timer >= step_delay:
		timer = 0.0
		_execute_step(step)
		step += 1

func _execute_step(s: int) -> void:
	match s:
		0: _step_0_back_panel()
		1: _step_1_outer_frame()
		2: _step_2_horizontal_shelves()
		3: _step_3_vertical_dividers()
		4: _step_4_top_trim()
		_:
			is_constructing = false
			print("Bookshelf complete! %d parts" % all_parts.size())

func _build_instant() -> void:
	_step_0_back_panel()
	_step_1_outer_frame()
	_step_2_horizontal_shelves()
	_step_3_vertical_dividers()
	_step_4_top_trim()

func _step_0_back_panel() -> void:
	# Thin back panel
	var thickness = shelf_size * 0.02
	var height = shelf_size * 1.5
	var width = shelf_size

	_create_part(
		Vector3(0, height * 0.5, -shelf_size * 0.24),
		Vector3(width * 0.96, height * 0.96, thickness),
		back_color, "BackPanel"
	)
	print("Step 0: Back panel")

func _step_1_outer_frame() -> void:
	var thickness = shelf_size * 0.06
	var height = shelf_size * 1.5
	var depth = shelf_size * 0.25

	# Left side
	_create_part(
		Vector3(-shelf_size * 0.5 + thickness * 0.5, height * 0.5, 0),
		Vector3(thickness, height, depth),
		frame_color, "LeftSide"
	)

	# Right side
	_create_part(
		Vector3(shelf_size * 0.5 - thickness * 0.5, height * 0.5, 0),
		Vector3(thickness, height, depth),
		frame_color, "RightSide"
	)

	# Top
	_create_part(
		Vector3(0, height - thickness * 0.5, 0),
		Vector3(shelf_size, thickness, depth),
		frame_color, "Top"
	)

	# Bottom
	_create_part(
		Vector3(0, thickness * 0.5, 0),
		Vector3(shelf_size, thickness, depth),
		frame_color, "Bottom"
	)

	print("Step 1: Outer frame")

func _step_2_horizontal_shelves() -> void:
	var thickness = shelf_size * 0.04
	var height = shelf_size * 1.5
	var depth = shelf_size * 0.24
	var inner_width = shelf_size * 0.88
	var frame_thick = shelf_size * 0.06

	# Create horizontal shelves between rows
	var cell_height = (height - frame_thick * 2) / rows

	for i in range(1, rows):
		var y_pos = frame_thick + cell_height * i
		_create_part(
			Vector3(0, y_pos, 0),
			Vector3(inner_width, thickness, depth),
			shelf_color, "Shelf_%d" % i
		)

	print("Step 2: Horizontal shelves (%d)" % (rows - 1))

func _step_3_vertical_dividers() -> void:
	var thickness = shelf_size * 0.03
	var height = shelf_size * 1.5
	var depth = shelf_size * 0.23
	var frame_thick = shelf_size * 0.06
	var inner_width = shelf_size - frame_thick * 2

	var cell_width = inner_width / columns
	var cell_height = (height - frame_thick * 2) / rows

	# Create vertical dividers between columns
	for col in range(1, columns):
		var x_pos = -shelf_size * 0.5 + frame_thick + cell_width * col

		# Full height divider
		_create_part(
			Vector3(x_pos, height * 0.5, 0),
			Vector3(thickness, height - frame_thick * 2, depth),
			shelf_color, "Divider_%d" % col
		)

	print("Step 3: Vertical dividers (%d)" % (columns - 1))

func _step_4_top_trim() -> void:
	# Decorative crown molding at top
	var trim_height = shelf_size * 0.08
	var trim_depth = shelf_size * 0.28
	var height = shelf_size * 1.5

	_create_part(
		Vector3(0, height + trim_height * 0.4, shelf_size * 0.02),
		Vector3(shelf_size * 1.05, trim_height, trim_depth),
		accent_color, "CrownMolding"
	)

	# Base molding
	_create_part(
		Vector3(0, -shelf_size * 0.02, shelf_size * 0.02),
		Vector3(shelf_size * 1.02, shelf_size * 0.04, trim_depth),
		accent_color, "BaseMolding"
	)

	print("Step 4: Trim details")

func _create_part(pos: Vector3, size: Vector3, color: Color, part_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.name = part_name

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.0
	material.roughness = 0.7
	mesh_instance.material_override = material

	add_child(mesh_instance)
	all_parts.append(mesh_instance)

func reset() -> void:
	for part in all_parts:
		if is_instance_valid(part):
			part.queue_free()
	all_parts.clear()
	step = 0
	timer = 0.0

	if show_construction:
		is_constructing = true
	else:
		_build_instant()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
