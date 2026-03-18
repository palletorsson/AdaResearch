extends Node3D

# Cube Cabin - Architectural form from cube subdivision
# Demonstrates how buildings emerge from subtractive/additive operations
# Subdivision creates rooms, windows, doors from a base cube

@export var cabin_size: float = 3.0
@export var show_construction: bool = true
@export var step_delay: float = 0.35

# Colors - rustic cabin
var wall_color := Color(0.6, 0.45, 0.3, 1.0)         # Log/wood walls
var roof_color := Color(0.35, 0.3, 0.25, 1.0)        # Dark roof
var floor_color := Color(0.5, 0.35, 0.2, 1.0)        # Wood floor
var window_color := Color(0.7, 0.85, 0.95, 0.8)      # Glass
var door_color := Color(0.4, 0.25, 0.15, 1.0)        # Dark wood door
var trim_color := Color(0.8, 0.75, 0.65, 1.0)        # Light trim
var chimney_color := Color(0.5, 0.45, 0.4, 1.0)      # Stone chimney

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
		0: _step_foundation()
		1: _step_walls()
		2: _step_door_opening()
		3: _step_windows()
		4: _step_roof()
		5: _step_chimney()
		6: _step_porch()
		7: _step_details()
		_:
			is_constructing = false
			print("Cabin complete! %d parts" % all_parts.size())

func _build_instant() -> void:
	_step_foundation()
	_step_walls()
	_step_door_opening()
	_step_windows()
	_step_roof()
	_step_chimney()
	_step_porch()
	_step_details()

func _step_foundation() -> void:
	# Raised foundation/floor
	var foundation_height = cabin_size * 0.08

	_create_part(
		Vector3(0, foundation_height * 0.5, 0),
		Vector3(cabin_size * 1.1, foundation_height, cabin_size * 1.1),
		floor_color, "Foundation"
	)
	print("Step 0: Foundation")

func _step_walls() -> void:
	var wall_thickness = cabin_size * 0.08
	var wall_height = cabin_size * 0.6
	var foundation_height = cabin_size * 0.08

	var base_y = foundation_height + wall_height * 0.5

	# Front wall (with door gap later)
	_create_part(
		Vector3(0, base_y, cabin_size * 0.5 - wall_thickness * 0.5),
		Vector3(cabin_size, wall_height, wall_thickness),
		wall_color, "FrontWall"
	)

	# Back wall
	_create_part(
		Vector3(0, base_y, -cabin_size * 0.5 + wall_thickness * 0.5),
		Vector3(cabin_size, wall_height, wall_thickness),
		wall_color, "BackWall"
	)

	# Left wall
	_create_part(
		Vector3(-cabin_size * 0.5 + wall_thickness * 0.5, base_y, 0),
		Vector3(wall_thickness, wall_height, cabin_size - wall_thickness * 2),
		wall_color, "LeftWall"
	)

	# Right wall
	_create_part(
		Vector3(cabin_size * 0.5 - wall_thickness * 0.5, base_y, 0),
		Vector3(wall_thickness, wall_height, cabin_size - wall_thickness * 2),
		wall_color, "RightWall"
	)

	print("Step 1: Walls")

func _step_door_opening() -> void:
	# Door frame and door
	var door_width = cabin_size * 0.22
	var door_height = cabin_size * 0.45
	var foundation_height = cabin_size * 0.08
	var wall_thickness = cabin_size * 0.08

	var door_y = foundation_height + door_height * 0.5
	var door_z = cabin_size * 0.5 - wall_thickness * 0.3

	# Door (slightly recessed)
	_create_part(
		Vector3(0, door_y, door_z),
		Vector3(door_width, door_height, wall_thickness * 0.5),
		door_color, "Door"
	)

	# Door frame - top
	_create_part(
		Vector3(0, foundation_height + door_height + cabin_size * 0.02, door_z + wall_thickness * 0.3),
		Vector3(door_width * 1.3, cabin_size * 0.04, wall_thickness * 0.3),
		trim_color, "DoorFrameTop"
	)

	# Door frame - sides
	_create_part(
		Vector3(-door_width * 0.6, door_y, door_z + wall_thickness * 0.3),
		Vector3(cabin_size * 0.04, door_height * 1.1, wall_thickness * 0.3),
		trim_color, "DoorFrameLeft"
	)
	_create_part(
		Vector3(door_width * 0.6, door_y, door_z + wall_thickness * 0.3),
		Vector3(cabin_size * 0.04, door_height * 1.1, wall_thickness * 0.3),
		trim_color, "DoorFrameRight"
	)

	print("Step 2: Door")

func _step_windows() -> void:
	var window_size = cabin_size * 0.18
	var window_height = cabin_size * 0.15
	var wall_height = cabin_size * 0.6
	var foundation_height = cabin_size * 0.08
	var wall_thickness = cabin_size * 0.08

	var window_y = foundation_height + wall_height * 0.6

	# Front windows (flanking door)
	for side in [-1, 1]:
		var window_x = side * cabin_size * 0.3
		var window_z = cabin_size * 0.5 - wall_thickness * 0.3

		# Window glass
		_create_part(
			Vector3(window_x, window_y, window_z),
			Vector3(window_size, window_height, wall_thickness * 0.2),
			window_color, "FrontWindow_%d" % side
		)

		# Window frame
		_create_part(
			Vector3(window_x, window_y, window_z + wall_thickness * 0.2),
			Vector3(window_size * 1.2, window_height * 1.2, wall_thickness * 0.15),
			trim_color, "WindowFrame_%d" % side
		)

	# Side windows
	for side in [-1, 1]:
		var wall_x = side * (cabin_size * 0.5 - wall_thickness * 0.3)

		_create_part(
			Vector3(wall_x, window_y, 0),
			Vector3(wall_thickness * 0.2, window_height, window_size),
			window_color, "SideWindow_%d" % side
		)

		_create_part(
			Vector3(wall_x + side * wall_thickness * 0.2, window_y, 0),
			Vector3(wall_thickness * 0.15, window_height * 1.2, window_size * 1.2),
			trim_color, "SideWindowFrame_%d" % side
		)

	print("Step 3: Windows")

func _step_roof() -> void:
	var wall_height = cabin_size * 0.6
	var foundation_height = cabin_size * 0.08
	var roof_height = cabin_size * 0.35
	var roof_overhang = cabin_size * 0.15

	var roof_base_y = foundation_height + wall_height

	# Simple gabled roof using two angled panels
	# Left roof slope
	var roof_panel_width = cabin_size * 0.6
	var roof_panel_length = cabin_size + roof_overhang * 2
	var roof_thickness = cabin_size * 0.04

	# Roof ridge
	_create_part(
		Vector3(0, roof_base_y + roof_height, 0),
		Vector3(cabin_size * 0.06, cabin_size * 0.04, roof_panel_length),
		trim_color, "RoofRidge"
	)

	# Left roof panel (angled - approximated with box)
	var left_roof = _create_part(
		Vector3(-cabin_size * 0.28, roof_base_y + roof_height * 0.55, 0),
		Vector3(roof_panel_width, roof_thickness, roof_panel_length),
		roof_color, "LeftRoof"
	)
	left_roof.rotation_degrees.z = 30

	# Right roof panel
	var right_roof = _create_part(
		Vector3(cabin_size * 0.28, roof_base_y + roof_height * 0.55, 0),
		Vector3(roof_panel_width, roof_thickness, roof_panel_length),
		roof_color, "RightRoof"
	)
	right_roof.rotation_degrees.z = -30

	# Gable ends (triangular areas - approximated)
	_create_part(
		Vector3(0, roof_base_y + roof_height * 0.4, cabin_size * 0.5),
		Vector3(cabin_size * 0.5, roof_height * 0.6, cabin_size * 0.04),
		wall_color, "FrontGable"
	)
	_create_part(
		Vector3(0, roof_base_y + roof_height * 0.4, -cabin_size * 0.5),
		Vector3(cabin_size * 0.5, roof_height * 0.6, cabin_size * 0.04),
		wall_color, "BackGable"
	)

	print("Step 4: Roof")

func _step_chimney() -> void:
	var wall_height = cabin_size * 0.6
	var foundation_height = cabin_size * 0.08
	var roof_height = cabin_size * 0.35

	var chimney_width = cabin_size * 0.12
	var chimney_height = cabin_size * 0.5

	_create_part(
		Vector3(-cabin_size * 0.3, foundation_height + wall_height + chimney_height * 0.3, -cabin_size * 0.35),
		Vector3(chimney_width, chimney_height, chimney_width),
		chimney_color, "Chimney"
	)

	# Chimney cap
	_create_part(
		Vector3(-cabin_size * 0.3, foundation_height + wall_height + chimney_height * 0.85, -cabin_size * 0.35),
		Vector3(chimney_width * 1.3, cabin_size * 0.03, chimney_width * 1.3),
		chimney_color, "ChimneyCap"
	)

	print("Step 5: Chimney")

func _step_porch() -> void:
	var foundation_height = cabin_size * 0.08
	var porch_depth = cabin_size * 0.25
	var porch_width = cabin_size * 0.6

	# Porch floor
	_create_part(
		Vector3(0, foundation_height * 0.5, cabin_size * 0.5 + porch_depth * 0.5),
		Vector3(porch_width, foundation_height, porch_depth),
		floor_color, "PorchFloor"
	)

	# Porch posts
	var post_size = cabin_size * 0.05
	var post_height = cabin_size * 0.4

	for side in [-1, 1]:
		_create_part(
			Vector3(side * porch_width * 0.45, foundation_height + post_height * 0.5, cabin_size * 0.5 + porch_depth * 0.8),
			Vector3(post_size, post_height, post_size),
			trim_color, "PorchPost_%d" % side
		)

	# Porch roof
	_create_part(
		Vector3(0, foundation_height + post_height + cabin_size * 0.02, cabin_size * 0.5 + porch_depth * 0.5),
		Vector3(porch_width * 1.1, cabin_size * 0.03, porch_depth * 1.2),
		roof_color, "PorchRoof"
	)

	# Steps
	var step_height = foundation_height * 0.5
	_create_part(
		Vector3(0, step_height * 0.5, cabin_size * 0.5 + porch_depth + cabin_size * 0.08),
		Vector3(cabin_size * 0.3, step_height, cabin_size * 0.15),
		floor_color, "PorchStep"
	)

	print("Step 6: Porch")

func _step_details() -> void:
	var foundation_height = cabin_size * 0.08

	# Welcome mat (small dark rectangle)
	_create_part(
		Vector3(0, foundation_height + cabin_size * 0.005, cabin_size * 0.5 + cabin_size * 0.15),
		Vector3(cabin_size * 0.15, cabin_size * 0.01, cabin_size * 0.1),
		Color(0.3, 0.25, 0.2), "WelcomeMat"
	)

	# Lantern by door
	_create_part(
		Vector3(cabin_size * 0.2, foundation_height + cabin_size * 0.35, cabin_size * 0.52),
		Vector3(cabin_size * 0.03, cabin_size * 0.06, cabin_size * 0.03),
		Color(0.8, 0.7, 0.3), "Lantern"
	)

	print("Step 7: Details")

func _create_part(pos: Vector3, size: Vector3, color: Color, part_name: String) -> MeshInstance3D:
	var mesh_instance := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_instance.mesh = box
	mesh_instance.position = pos
	mesh_instance.name = part_name

	var material := StandardMaterial3D.new()
	material.albedo_color = color
	if color == window_color:
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.metallic = 0.3
		material.roughness = 0.1
	else:
		material.metallic = 0.0
		material.roughness = 0.7
	mesh_instance.material_override = material

	add_child(mesh_instance)
	all_parts.append(mesh_instance)
	return mesh_instance

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
