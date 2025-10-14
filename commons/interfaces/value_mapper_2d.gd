extends Node3D

# 2D Value Mapper - Maps two dimensions to output values
# Useful for controlling paired parameters like frequency/amplitude, pan/volume, etc.

signal values_changed(x_value: float, y_value: float)

@export var plane_size: Vector2 = Vector2(1.0, 1.0)
@export var axis_color_x: Color = Color(1.0, 0.3, 0.3, 1)  # Red
@export var axis_color_y: Color = Color(0.3, 1.0, 0.3, 1)  # Green
@export var grid_color: Color = Color(0.5, 0.5, 0.5, 0.3)
@export var axis_thickness: float = 0.008
@export var output_x_min: float = 0.0
@export var output_x_max: float = 1.0
@export var output_y_min: float = 0.0
@export var output_y_max: float = 1.0
@export var show_labels: bool = true
@export var label_x: String = "X"
@export var label_y: String = "Y"
@export var show_grid: bool = true
@export var grid_divisions: int = 4

var point: Node3D
var axis_x: Node3D
var axis_y: Node3D
var grid_lines: Array[MeshInstance3D] = []
var value_label: Label3D
var x_label: Label3D
var y_label: Label3D

const POINT_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")
const COORDINATE_LINE := preload("res://commons/primitives/line/coordinate_line.tscn")

func _ready() -> void:
	_create_axes()
	if show_grid:
		_create_grid()
	_create_point()
	if show_labels:
		_create_labels()
	_update_output()

func _create_axes() -> void:
	# X axis
	axis_x = COORDINATE_LINE.instantiate()
	axis_x.name = "AxisX"
	axis_x.set("length", plane_size.x)
	axis_x.set("thickness", axis_thickness)
	axis_x.set("color", axis_color_x)
	add_child(axis_x)

	# Y axis (rotated 90 degrees)
	axis_y = COORDINATE_LINE.instantiate()
	axis_y.name = "AxisY"
	axis_y.set("length", plane_size.y)
	axis_y.set("thickness", axis_thickness)
	axis_y.set("color", axis_color_y)
	axis_y.transform = Transform3D(Basis.from_euler(Vector3(0, 0, PI/2)), Vector3.ZERO)
	add_child(axis_y)

func _create_grid() -> void:
	if grid_divisions <= 0:
		return

	var half_x = plane_size.x * 0.5
	var half_y = plane_size.y * 0.5
	var step_x = plane_size.x / grid_divisions
	var step_y = plane_size.y / grid_divisions

	# Vertical grid lines (parallel to Y)
	for i in range(grid_divisions + 1):
		var x_pos = -half_x + (i * step_x)
		if abs(x_pos) < 0.001:  # Skip center line (that's the axis)
			continue
		var line = _create_grid_line(Vector3(x_pos, -half_y, 0), Vector3(x_pos, half_y, 0))
		grid_lines.append(line)

	# Horizontal grid lines (parallel to X)
	for i in range(grid_divisions + 1):
		var y_pos = -half_y + (i * step_y)
		if abs(y_pos) < 0.001:  # Skip center line (that's the axis)
			continue
		var line = _create_grid_line(Vector3(-half_x, y_pos, 0), Vector3(half_x, y_pos, 0))
		grid_lines.append(line)

func _create_grid_line(start: Vector3, end: Vector3) -> MeshInstance3D:
	var line = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	var distance = start.distance_to(end)
	cylinder.height = distance
	cylinder.top_radius = axis_thickness * 0.5
	cylinder.bottom_radius = axis_thickness * 0.5
	cylinder.radial_segments = 6

	line.mesh = cylinder

	# Position and orient
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

	var material = StandardMaterial3D.new()
	material.albedo_color = grid_color
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line.material_override = material

	add_child(line)
	return line

func _create_point() -> void:
	point = POINT_SCENE.instantiate()
	point.name = "PlanePoint"
	add_child(point)
	# Start at center
	point.position = Vector3.ZERO

	# Disable highlight ring
	var highlight = point.get_node_or_null("HighlightRing")
	if highlight:
		highlight.visible = false

func _create_labels() -> void:
	# Value label (follows point)
	value_label = Label3D.new()
	value_label.name = "ValueLabel"
	value_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	value_label.font_size = 28
	value_label.modulate = Color(1.0, 1.0, 1.0, 0.9)
	value_label.outline_size = 4
	value_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	value_label.scale = Vector3.ONE * 0.1
	add_child(value_label)

	# X axis label
	x_label = Label3D.new()
	x_label.name = "XLabel"
	x_label.text = label_x
	x_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	x_label.font_size = 24
	x_label.modulate = axis_color_x
	x_label.outline_size = 3
	x_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	x_label.scale = Vector3.ONE * 0.09
	x_label.position = Vector3(plane_size.x * 0.5 + 0.15, 0, 0)
	add_child(x_label)

	# Y axis label
	y_label = Label3D.new()
	y_label.name = "YLabel"
	y_label.text = label_y
	y_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	y_label.font_size = 24
	y_label.modulate = axis_color_y
	y_label.outline_size = 3
	y_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	y_label.scale = Vector3.ONE * 0.09
	y_label.position = Vector3(0, plane_size.y * 0.5 + 0.15, 0)
	add_child(y_label)

func _process(_delta: float) -> void:
	if point:
		_constrain_point()
		_update_output()

func _constrain_point() -> void:
	# Constrain point to XY plane
	var pos = point.position
	var half_x = plane_size.x * 0.5
	var half_y = plane_size.y * 0.5
	pos.x = clamp(pos.x, -half_x, half_x)
	pos.y = clamp(pos.y, -half_y, half_y)
	pos.z = 0.0
	point.position = pos

func _update_output() -> void:
	if not point:
		return

	var half_x = plane_size.x * 0.5
	var half_y = plane_size.y * 0.5

	var normalized_x = (point.position.x + half_x) / plane_size.x
	var normalized_y = (point.position.y + half_y) / plane_size.y

	var output_x = lerp(output_x_min, output_x_max, normalized_x)
	var output_y = lerp(output_y_min, output_y_max, normalized_y)

	if show_labels and value_label:
		value_label.text = "%s: %.2f\n%s: %.2f" % [label_x, output_x, label_y, output_y]
		value_label.position = point.position + Vector3(0, 0, 0.12)

	values_changed.emit(output_x, output_y)

func get_values() -> Vector2:
	if not point:
		return Vector2(
			(output_x_min + output_x_max) * 0.5,
			(output_y_min + output_y_max) * 0.5
		)

	var half_x = plane_size.x * 0.5
	var half_y = plane_size.y * 0.5

	var normalized_x = (point.position.x + half_x) / plane_size.x
	var normalized_y = (point.position.y + half_y) / plane_size.y

	return Vector2(
		lerp(output_x_min, output_x_max, normalized_x),
		lerp(output_y_min, output_y_max, normalized_y)
	)

func set_values(x_value: float, y_value: float) -> void:
	if not point:
		return

	var normalized_x = inverse_lerp(output_x_min, output_x_max, x_value)
	var normalized_y = inverse_lerp(output_y_min, output_y_max, y_value)

	var half_x = plane_size.x * 0.5
	var half_y = plane_size.y * 0.5

	point.position.x = (normalized_x * plane_size.x) - half_x
	point.position.y = (normalized_y * plane_size.y) - half_y
	point.position.z = 0.0
