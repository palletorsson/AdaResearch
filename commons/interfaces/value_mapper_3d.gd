extends Node3D

# 3D Value Mapper - Maps three dimensions to output values
# Useful for controlling triple parameters like RGB colors, XYZ positions, etc.
# Smaller, more compact version of VectorPoint for interface use

signal values_changed(x_value: float, y_value: float, z_value: float)

@export var space_size: Vector3 = Vector3(0.6, 0.6, 0.6)
@export var axis_color_x: Color = Color(1.0, 0.3, 0.3, 1)  # Red
@export var axis_color_y: Color = Color(0.3, 1.0, 0.3, 1)  # Green
@export var axis_color_z: Color = Color(0.3, 0.3, 1.0, 1)  # Blue
@export var axis_thickness: float = 0.006
@export var output_x_min: float = 0.0
@export var output_x_max: float = 1.0
@export var output_y_min: float = 0.0
@export var output_y_max: float = 1.0
@export var output_z_min: float = 0.0
@export var output_z_max: float = 1.0
@export var show_labels: bool = true
@export var label_x: String = "X"
@export var label_y: String = "Y"
@export var label_z: String = "Z"
@export var show_projection_lines: bool = true

var point: Node3D
var axis_x: Node3D
var axis_y: Node3D
var axis_z: Node3D
var x_projection_line: MeshInstance3D
var y_projection_line: MeshInstance3D
var z_projection_line: MeshInstance3D
var value_label: Label3D
var x_label: Label3D
var y_label: Label3D
var z_label: Label3D

const POINT_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")
const COORDINATE_LINE := preload("res://commons/primitives/line/coordinate_line.tscn")

func _ready() -> void:
	_create_axes()
	_create_point()
	if show_projection_lines:
		_create_projection_lines()
	if show_labels:
		_create_labels()
	_update_output()

func _create_axes() -> void:
	# Create corner box layout - all axes start from origin (corner) and extend in positive directions

	# X axis (extends in +X direction)
	axis_x = COORDINATE_LINE.instantiate()
	axis_x.name = "AxisX"
	axis_x.set("length", space_size.x)
	axis_x.set("thickness", axis_thickness)
	axis_x.set("color", axis_color_x)
	# Position so it starts at origin and extends to +X
	axis_x.position = Vector3(space_size.x * 0.5, 0, 0)
	add_child(axis_x)

	# Y axis (extends in +Y direction)
	axis_y = COORDINATE_LINE.instantiate()
	axis_y.name = "AxisY"
	axis_y.set("length", space_size.y)
	axis_y.set("thickness", axis_thickness)
	axis_y.set("color", axis_color_y)
	# Rotate 90 degrees around Z and position to extend in +Y
	axis_y.transform = Transform3D(Basis.from_euler(Vector3(0, 0, PI/2)), Vector3(0, space_size.y * 0.5, 0))
	add_child(axis_y)

	# Z axis (extends in +Z direction)
	axis_z = COORDINATE_LINE.instantiate()
	axis_z.name = "AxisZ"
	axis_z.set("length", space_size.z)
	axis_z.set("thickness", axis_thickness)
	axis_z.set("color", axis_color_z)
	# Rotate 90 degrees around Y and position to extend in +Z
	axis_z.transform = Transform3D(Basis.from_euler(Vector3(0, -PI/2, 0)), Vector3(0, 0, space_size.z * 0.5))
	add_child(axis_z)

func _create_point() -> void:
	point = POINT_SCENE.instantiate()
	point.name = "SpacePoint"
	add_child(point)
	# Start at center of the corner box (half of each dimension)
	point.position = Vector3(space_size.x * 0.5, space_size.y * 0.5, space_size.z * 0.5)

	# Disable highlight ring for cleaner look
	var highlight = point.get_node_or_null("HighlightRing")
	if highlight:
		highlight.visible = false

func _create_projection_lines() -> void:
	# X projection (red)
	x_projection_line = _create_projection_line(axis_color_x)
	x_projection_line.name = "XProjection"

	# Y projection (green)
	y_projection_line = _create_projection_line(axis_color_y)
	y_projection_line.name = "YProjection"

	# Z projection (blue)
	z_projection_line = _create_projection_line(axis_color_z)
	z_projection_line.name = "ZProjection"

func _create_projection_line(color: Color) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = 0.1
	cylinder.top_radius = axis_thickness * 0.7
	cylinder.bottom_radius = axis_thickness * 0.7
	cylinder.radial_segments = 6

	line.mesh = cylinder

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.albedo_color.a = 0.4
	line.material_override = material

	add_child(line)
	return line

func _create_labels() -> void:
	# Value label (follows point)
	value_label = Label3D.new()
	value_label.name = "ValueLabel"
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	value_label.font_size = 26
	value_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	value_label.outline_size = 4
	value_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	value_label.scale = Vector3.ONE * 0.09
	add_child(value_label)

	# X axis label (at end of X axis)
	x_label = Label3D.new()
	x_label.name = "XLabel"
	x_label.text = label_x
	x_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	x_label.font_size = 22
	x_label.modulate = axis_color_x
	x_label.outline_size = 3
	x_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	x_label.scale = Vector3.ONE * 0.08
	x_label.position = Vector3(space_size.x + 0.12, 0, 0)
	add_child(x_label)

	# Y axis label (at end of Y axis)
	y_label = Label3D.new()
	y_label.name = "YLabel"
	y_label.text = label_y
	y_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	y_label.font_size = 22
	y_label.modulate = axis_color_y
	y_label.outline_size = 3
	y_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	y_label.scale = Vector3.ONE * 0.08
	y_label.position = Vector3(0, space_size.y + 0.12, 0)
	add_child(y_label)

	# Z axis label (at end of Z axis)
	z_label = Label3D.new()
	z_label.name = "ZLabel"
	z_label.text = label_z
	z_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	z_label.font_size = 22
	z_label.modulate = axis_color_z
	z_label.outline_size = 3
	z_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	z_label.scale = Vector3.ONE * 0.08
	z_label.position = Vector3(0, 0, space_size.z + 0.12)
	add_child(z_label)

func _process(_delta: float) -> void:
	if point:
		_constrain_point()
		_update_projection_lines()
		_update_output()

func _constrain_point() -> void:
	# Constrain point to corner box space (0 to size in each dimension)
	var pos = point.position
	pos.x = clamp(pos.x, 0, space_size.x)
	pos.y = clamp(pos.y, 0, space_size.y)
	pos.z = clamp(pos.z, 0, space_size.z)
	point.position = pos

func _update_projection_lines() -> void:
	if not show_projection_lines or not point:
		return

	var pos = point.position

	# X projection (from point to YZ plane)
	_update_line_transform(x_projection_line, Vector3.ZERO, pos * Vector3.RIGHT)

	# Y projection (from point to XZ plane)
	_update_line_transform(y_projection_line, Vector3.ZERO, pos * Vector3.UP)

	# Z projection (from point to XY plane)
	_update_line_transform(z_projection_line, Vector3.ZERO, pos * Vector3.BACK)

func _update_line_transform(line: MeshInstance3D, start: Vector3, end: Vector3) -> void:
	if not line or not is_instance_valid(line):
		return

	var cylinder = line.mesh as CylinderMesh
	if not cylinder:
		return

	var distance = start.distance_to(end)
	cylinder.height = distance

	var center = (start + end) * 0.5
	line.position = center

	var direction = (end - start).normalized()
	if direction.length() > 0.001:
		var up = Vector3.UP
		var right = direction.cross(up).normalized()
		if right.length() < 0.001:
			right = Vector3.RIGHT
			up = right.cross(direction).normalized()
		else:
			up = right.cross(direction).normalized()
		line.transform.basis = Basis(right, direction, up)

func _update_output() -> void:
	if not point:
		return

	# Normalize from corner box space (0 to size) to 0-1 range
	var normalized_x = point.position.x / space_size.x
	var normalized_y = point.position.y / space_size.y
	var normalized_z = point.position.z / space_size.z

	var output_x = lerp(output_x_min, output_x_max, normalized_x)
	var output_y = lerp(output_y_min, output_y_max, normalized_y)
	var output_z = lerp(output_z_min, output_z_max, normalized_z)

	if show_labels and value_label:
		value_label.text = "%s: %.2f\n%s: %.2f\n%s: %.2f" % [
			label_x, output_x,
			label_y, output_y,
			label_z, output_z
		]
		value_label.position = point.position + Vector3(0.15, 0, 0)

	values_changed.emit(output_x, output_y, output_z)

func get_values() -> Vector3:
	if not point:
		return Vector3(
			(output_x_min + output_x_max) * 0.5,
			(output_y_min + output_y_max) * 0.5,
			(output_z_min + output_z_max) * 0.5
		)

	# Normalize from corner box space (0 to size) to 0-1 range
	var normalized_x = point.position.x / space_size.x
	var normalized_y = point.position.y / space_size.y
	var normalized_z = point.position.z / space_size.z

	return Vector3(
		lerp(output_x_min, output_x_max, normalized_x),
		lerp(output_y_min, output_y_max, normalized_y),
		lerp(output_z_min, output_z_max, normalized_z)
	)

func set_values(x_value: float, y_value: float, z_value: float) -> void:
	if not point:
		return

	var normalized_x = inverse_lerp(output_x_min, output_x_max, x_value)
	var normalized_y = inverse_lerp(output_y_min, output_y_max, y_value)
	var normalized_z = inverse_lerp(output_z_min, output_z_max, z_value)

	# Map from 0-1 range to corner box space (0 to size)
	point.position.x = normalized_x * space_size.x
	point.position.y = normalized_y * space_size.y
	point.position.z = normalized_z * space_size.z
