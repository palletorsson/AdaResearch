extends Node3D

# Cube Desk - Table with subdivided drawer storage
# Demonstrates hierarchical subdivision: table form + drawer grid
# Shows how functional complexity emerges from recursive structure

# @identity
# essence: desk = table_form + grid_subdivide(drawer_unit, rows * cols), nested subdivision hierarchy
# desire: To be used — drawers that emerged from subdividing a box within a box, functional complexity from recursive cuts
# critical_parameter: drawer_rows * drawer_cols — the grid resolution of the drawer unit determines storage granularity
# triggers: Construction sequence: desktop -> legs -> drawer frame -> individual drawers with handles -> details
# emerges: Cable management holes and accent strips appear as final-step details — the desk develops personality
# needs: VR drawer-open interaction [missing], construction speed control [missing]
# relationships: Most complex cube-subdivision furniture; builds on recursive_table by adding nested second-level subdivision
# truth: A desk is a table that subdivided one of its own volumes into a grid — recursion within recursion.

@export var desk_size: float = 2.0
@export var drawer_rows: int = 2
@export var drawer_cols: int = 3
@export var show_construction: bool = true
@export var step_delay: float = 0.25

# Colors - modern office look
var top_color := Color(0.85, 0.82, 0.78, 1.0)        # Light wood top
var frame_color := Color(0.25, 0.25, 0.28, 1.0)      # Dark metal frame
var drawer_color := Color(0.9, 0.88, 0.85, 1.0)      # White drawers
var handle_color := Color(0.6, 0.58, 0.55, 1.0)      # Metal handles
var accent_color := Color(0.2, 0.5, 0.7, 1.0)        # Blue accent

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
	var total_steps = 5 + drawer_rows * drawer_cols
	if s == 0:
		_step_desktop()
	elif s == 1:
		_step_legs()
	elif s == 2:
		_step_drawer_frame()
	elif s == 3:
		_step_back_panel()
	elif s >= 4 and s < 4 + drawer_rows * drawer_cols:
		var drawer_idx = s - 4
		var row = drawer_idx / drawer_cols
		var col = drawer_idx % drawer_cols
		_step_single_drawer(row, col)
	elif s == 4 + drawer_rows * drawer_cols:
		_step_details()
	else:
		is_constructing = false
		print("Desk complete! %d parts" % all_parts.size())

func _build_instant() -> void:
	_step_desktop()
	_step_legs()
	_step_drawer_frame()
	_step_back_panel()
	for row in range(drawer_rows):
		for col in range(drawer_cols):
			_step_single_drawer(row, col)
	_step_details()

func _step_desktop() -> void:
	# Main work surface
	var top_thickness = desk_size * 0.04
	var desk_height = desk_size * 0.4
	var desk_width = desk_size * 1.2
	var desk_depth = desk_size * 0.6

	_create_part(
		Vector3(0, desk_height, 0),
		Vector3(desk_width, top_thickness, desk_depth),
		top_color, "Desktop"
	)
	print("Step: Desktop surface")

func _step_legs() -> void:
	var leg_thickness = desk_size * 0.04
	var desk_height = desk_size * 0.4 - desk_size * 0.02
	var desk_width = desk_size * 1.2
	var desk_depth = desk_size * 0.6

	# Four legs at corners (only back two visible, front has drawers)
	var leg_positions = [
		Vector3(-desk_width * 0.45, desk_height * 0.5, -desk_depth * 0.4),  # Back left
		Vector3(desk_width * 0.45, desk_height * 0.5, -desk_depth * 0.4),   # Back right
	]

	for i in range(leg_positions.size()):
		_create_part(
			leg_positions[i],
			Vector3(leg_thickness, desk_height, leg_thickness),
			frame_color, "Leg_%d" % i
		)

	print("Step: Legs")

func _step_drawer_frame() -> void:
	# Frame that holds the drawers (left side of desk)
	var frame_thickness = desk_size * 0.02
	var drawer_unit_width = desk_size * 0.5
	var drawer_unit_height = desk_size * 0.35
	var drawer_unit_depth = desk_size * 0.55
	var desk_height = desk_size * 0.4

	# Position drawer unit on left side
	var unit_x = -desk_size * 0.35
	var unit_y = drawer_unit_height * 0.5
	var unit_z = desk_size * 0.02

	# Left side panel
	_create_part(
		Vector3(unit_x - drawer_unit_width * 0.5 + frame_thickness * 0.5, unit_y, unit_z),
		Vector3(frame_thickness, drawer_unit_height, drawer_unit_depth),
		frame_color, "DrawerFrameLeft"
	)

	# Right side panel
	_create_part(
		Vector3(unit_x + drawer_unit_width * 0.5 - frame_thickness * 0.5, unit_y, unit_z),
		Vector3(frame_thickness, drawer_unit_height, drawer_unit_depth),
		frame_color, "DrawerFrameRight"
	)

	# Bottom panel
	_create_part(
		Vector3(unit_x, frame_thickness * 0.5, unit_z),
		Vector3(drawer_unit_width, frame_thickness, drawer_unit_depth),
		frame_color, "DrawerFrameBottom"
	)

	# Horizontal dividers between drawer rows
	var cell_height = drawer_unit_height / drawer_rows
	for i in range(1, drawer_rows):
		_create_part(
			Vector3(unit_x, cell_height * i, unit_z),
			Vector3(drawer_unit_width * 0.96, frame_thickness * 0.5, drawer_unit_depth * 0.95),
			frame_color, "DrawerDivider_%d" % i
		)

	print("Step: Drawer frame")

func _step_back_panel() -> void:
	var desk_height = desk_size * 0.4
	var desk_width = desk_size * 1.2
	var desk_depth = desk_size * 0.6

	# Back modesty panel
	_create_part(
		Vector3(0, desk_height * 0.4, -desk_depth * 0.48),
		Vector3(desk_width * 0.9, desk_height * 0.6, desk_size * 0.02),
		frame_color, "BackPanel"
	)
	print("Step: Back panel")

func _step_single_drawer(row: int, col: int) -> void:
	var drawer_unit_width = desk_size * 0.5
	var drawer_unit_height = desk_size * 0.35
	var drawer_unit_depth = desk_size * 0.55
	var unit_x = -desk_size * 0.35
	var unit_z = desk_size * 0.02

	var frame_thickness = desk_size * 0.02
	var inner_width = drawer_unit_width - frame_thickness * 2
	var cell_width = inner_width / drawer_cols
	var cell_height = drawer_unit_height / drawer_rows

	var drawer_width = cell_width * 0.92
	var drawer_height = cell_height * 0.85
	var drawer_depth = drawer_unit_depth * 0.9
	var front_thickness = desk_size * 0.02

	var x_pos = unit_x - inner_width * 0.5 + cell_width * (col + 0.5)
	var y_pos = cell_height * (row + 0.5)
	var z_pos = unit_z + drawer_unit_depth * 0.5 - drawer_depth * 0.5 + front_thickness

	# Drawer front face
	_create_part(
		Vector3(x_pos, y_pos, unit_z + drawer_unit_depth * 0.52),
		Vector3(drawer_width, drawer_height, front_thickness),
		drawer_color, "DrawerFront_%d_%d" % [row, col]
	)

	# Drawer handle
	var handle_width = drawer_width * 0.4
	var handle_height = desk_size * 0.015

	_create_part(
		Vector3(x_pos, y_pos, unit_z + drawer_unit_depth * 0.55),
		Vector3(handle_width, handle_height, handle_height),
		handle_color, "Handle_%d_%d" % [row, col]
	)

	print("Step: Drawer [%d,%d]" % [row, col])

func _step_details() -> void:
	var desk_height = desk_size * 0.4
	var desk_width = desk_size * 1.2

	# Cable management hole (decorative circle representation)
	_create_part(
		Vector3(desk_width * 0.3, desk_height + desk_size * 0.01, 0),
		Vector3(desk_size * 0.08, desk_size * 0.02, desk_size * 0.08),
		frame_color, "CableHole"
	)

	# Accent strip on front edge
	_create_part(
		Vector3(0, desk_height - desk_size * 0.015, desk_size * 0.29),
		Vector3(desk_width * 0.98, desk_size * 0.01, desk_size * 0.02),
		accent_color, "AccentStrip"
	)

	print("Step: Details")

func _create_part(pos: Vector3, size: Vector3, color: Color, part_name: String) -> void:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.name = part_name

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.metallic = 0.2 if color == frame_color or color == handle_color else 0.0
	material.roughness = 0.4 if color == frame_color else 0.6
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
