extends Node3D
class_name TranslationCubeDemo

# @identity
# essence: constrained_translation — move only on allowed axis; sequential constraints: first UP, then SIDEWAYS
# desire: learner physically discovers that translation is axis-specific — the door will not open any other way
# critical_parameter: the axis sequence constraint — UP must complete before SIDEWAYS unlocks
# triggers: grabbing the knob and moving; axis deviation is corrected by projecting motion onto the allowed axis
# emerges: the idea that translation has direction — not all displacement is allowed, only along defined axes
# needs: [has two grabbable door knobs [has], missing visual axis indicator showing current allowed direction]
# relationships: precursor to axis_translation_cube; demonstrates constrained translation before the animated version
# truth: a translation requires both a direction and a magnitude — constraint is what makes it meaningful

## Translation Demo - Two sliding doors with doorknob handles
## Each door: grab knob, slide UP, then slide SIDEWAYS to open

@export var cube_size: float = 1.5  # Container size
@export var door_width: float = 0.5   # Door panel width
@export var door_height: float = 1.0  # Door panel height
@export var door_depth: float = 0.04  # Door thickness
@export var target_y: float = 0.25    # Slide up this far
@export var knob_height: float = 0.5  # Doorknob height on door

var _left_door: Node3D
var _right_door: Node3D
var _container: Node3D
var _both_reached: bool = false

const ConstrainedDoor = preload("res://commons/primitives/translation/constrained_door.gd")

func _ready() -> void:
	_setup_container()
	_create_doors()
	_create_path_indicators()

func _setup_container() -> void:
	_container = Node3D.new()
	_container.name = "Container"
	add_child(_container)

	# Draw wireframe edges
	var edges = [
		[Vector3(-0.5, 0, -0.5), Vector3(0.5, 0, -0.5)],
		[Vector3(0.5, 0, -0.5), Vector3(0.5, 0, 0.5)],
		[Vector3(0.5, 0, 0.5), Vector3(-0.5, 0, 0.5)],
		[Vector3(-0.5, 0, 0.5), Vector3(-0.5, 0, -0.5)],
		[Vector3(-0.5, 1, -0.5), Vector3(0.5, 1, -0.5)],
		[Vector3(0.5, 1, -0.5), Vector3(0.5, 1, 0.5)],
		[Vector3(0.5, 1, 0.5), Vector3(-0.5, 1, 0.5)],
		[Vector3(-0.5, 1, 0.5), Vector3(-0.5, 1, -0.5)],
		[Vector3(-0.5, 0, -0.5), Vector3(-0.5, 1, -0.5)],
		[Vector3(0.5, 0, -0.5), Vector3(0.5, 1, -0.5)],
		[Vector3(0.5, 0, 0.5), Vector3(0.5, 1, 0.5)],
		[Vector3(-0.5, 0, 0.5), Vector3(-0.5, 1, 0.5)],
	]

	for edge in edges:
		_create_edge_line(edge[0] * cube_size, edge[1] * cube_size)

func _create_edge_line(from: Vector3, to: Vector3) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = Color(0.5, 0.5, 0.5, 0.3)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mesh_instance.material_override = material
	_container.add_child(mesh_instance)

func _create_doors() -> void:
	var door_gap = 0.02  # Small gap between doors
	var door_offset = door_width / 2 + door_gap

	# Left door: slides UP then LEFT (outward)
	_left_door = _create_constrained_door(
		"LeftDoor",
		Vector3(-door_offset, 0.0, 0.0),
		Color(0.8, 0.3, 0.3),  # Red
		target_y,
		-(door_width + door_gap),  # Slide left to open (outward)
		false  # knob on right side
	)
	add_child(_left_door)

	# Right door: slides UP then RIGHT (outward)
	_right_door = _create_constrained_door(
		"RightDoor",
		Vector3(door_offset, 0.0, 0.0),
		Color(0.3, 0.3, 0.8),  # Blue
		target_y,
		door_width + door_gap,  # Slide right to open (outward)
		true  # knob on left side (mirrored)
	)
	add_child(_right_door)

func _create_constrained_door(
	door_name: String,
	start_pos: Vector3,
	color: Color,
	up_target: float,
	x_slide: float,
	knob_mirrored: bool = false
) -> Node3D:
	var door = Node3D.new()
	door.set_script(ConstrainedDoor)
	door.name = door_name
	door.position = start_pos

	# Set door properties
	door.door_width = door_width
	door.door_height = door_height
	door.door_depth = door_depth
	door.door_color = color
	door.knob_height = knob_height
	door.target_y = up_target
	door.target_x = x_slide
	door.mirror_knob = knob_mirrored

	# Connect signal
	door.goal_reached.connect(_on_door_goal_reached.bind(door_name))

	return door

func _on_door_goal_reached(door_name: String) -> void:
	print("Translation Demo: %s opened!" % door_name)
	_check_both_complete()

func _check_both_complete() -> void:
	if _both_reached:
		return

	var left_done = _left_door.has_method("is_goal_reached") and _left_door.is_goal_reached()
	var right_done = _right_door.has_method("is_goal_reached") and _right_door.is_goal_reached()

	if left_done and right_done:
		_both_reached = true
		print("Translation Demo: Both doors open! Puzzle complete!")

func _create_path_indicators() -> void:
	var door_gap = 0.02
	var door_offset = door_width / 2 + door_gap
	var arrow_z = door_depth + 0.08

	# Left door arrows - slides UP then LEFT (outward)
	_create_path_arrow(
		Vector3(-door_offset, knob_height, arrow_z),
		Vector3(-door_offset, knob_height + target_y, arrow_z),
		Color(0.8, 0.3, 0.3, 0.7)
	)
	_create_path_arrow(
		Vector3(-door_offset, knob_height + target_y, arrow_z),
		Vector3(-door_offset - door_width, knob_height + target_y, arrow_z),  # Slide LEFT
		Color(0.8, 0.3, 0.3, 0.7)
	)
	_create_label("1.Up", Vector3(-door_offset + 0.15, knob_height + target_y/2, arrow_z), Color(0.8, 0.3, 0.3))
	_create_label("2.Slide", Vector3(-door_offset - door_width/2, knob_height + target_y + 0.1, arrow_z), Color(0.8, 0.3, 0.3))

	# Right door arrows - slides UP then RIGHT (outward)
	_create_path_arrow(
		Vector3(door_offset, knob_height, arrow_z),
		Vector3(door_offset, knob_height + target_y, arrow_z),
		Color(0.3, 0.3, 0.8, 0.7)
	)
	_create_path_arrow(
		Vector3(door_offset, knob_height + target_y, arrow_z),
		Vector3(door_offset + door_width, knob_height + target_y, arrow_z),  # Slide RIGHT
		Color(0.3, 0.3, 0.8, 0.7)
	)
	_create_label("1.Up", Vector3(door_offset - 0.15, knob_height + target_y/2, arrow_z), Color(0.3, 0.3, 0.8))
	_create_label("2.Slide", Vector3(door_offset + door_width/2, knob_height + target_y + 0.1, arrow_z), Color(0.3, 0.3, 0.8))

func _create_path_arrow(from: Vector3, to: Vector3, color: Color) -> void:
	var mesh_instance = MeshInstance3D.new()
	var immediate_mesh = ImmediateMesh.new()
	immediate_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	immediate_mesh.surface_add_vertex(from)
	immediate_mesh.surface_add_vertex(to)
	immediate_mesh.surface_end()
	mesh_instance.mesh = immediate_mesh

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission = color
	mesh_instance.material_override = material
	add_child(mesh_instance)

	var arrow_dir = (to - from).normalized()
	_create_arrowhead(to, arrow_dir, color)

func _create_arrowhead(pos: Vector3, direction: Vector3, color: Color) -> void:
	var cone = MeshInstance3D.new()
	var cone_mesh = CylinderMesh.new()
	cone_mesh.top_radius = 0.0
	cone_mesh.bottom_radius = 0.015
	cone_mesh.height = 0.04
	cone.mesh = cone_mesh

	var up = Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.RIGHT
	var right = direction.cross(up).normalized()
	up = right.cross(direction).normalized()
	cone.transform = Transform3D(Basis(right, up, -direction), pos)

	var material = StandardMaterial3D.new()
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color
	cone.material_override = material
	add_child(cone)

func _create_label(text: String, pos: Vector3, color: Color) -> void:
	var label = Label3D.new()
	label.text = text
	label.font_size = 20
	label.pixel_size = 0.002
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = pos
	label.modulate = color
	add_child(label)

func print_help() -> void:
	print("=== Translation Demo ===")
	print("Grab the doorknob (small cube)")
	print("Phase 1: Slide UP")
	print("Phase 2: Slide SIDEWAYS to open")
