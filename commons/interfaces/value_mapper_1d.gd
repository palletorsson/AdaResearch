extends Node3D

# 1D Value Mapper - Maps a single dimension to output values
# Useful for controlling single parameters like amplitude, frequency, volume, etc.

signal value_changed(value: float)

@export var line_length: float = 1.0
@export var line_color: Color = Color(0.788235, 0.462745, 0.996078, 1)
@export var line_thickness: float = 0.01
@export var output_min: float = 0.0
@export var output_max: float = 1.0
@export var show_labels: bool = true
@export var label_text: String = "Value"

var point: Node3D
var line_mesh: MeshInstance3D
var value_label: Label3D
var min_label: Label3D
var max_label: Label3D

const POINT_SCENE := preload("res://commons/primitives/point/grab_sphere_point_with_text.tscn")

func _ready() -> void:
	_create_line()
	_create_point()
	if show_labels:
		_create_labels()
	_update_output()

func _create_line() -> void:
	# Create horizontal line along X axis
	line_mesh = MeshInstance3D.new()
	var cylinder = CylinderMesh.new()
	cylinder.height = line_length
	cylinder.top_radius = line_thickness
	cylinder.bottom_radius = line_thickness
	cylinder.radial_segments = 8

	line_mesh.mesh = cylinder
	# Rotate to horizontal (along X axis)
	line_mesh.transform = Transform3D(
		Basis(Vector3(0, 1, 0), Vector3(-1, 0, 0), Vector3(0, 0, 1)),
		Vector3.ZERO
	)

	var material = StandardMaterial3D.new()
	material.albedo_color = line_color
	material.metallic = 0.6
	material.roughness = 0.2
	material.emission_enabled = true
	material.emission = line_color * 0.5
	line_mesh.material_override = material

	add_child(line_mesh)

func _create_point() -> void:
	point = POINT_SCENE.instantiate()
	point.name = "SliderPoint"
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

	# Min label
	min_label = Label3D.new()
	min_label.name = "MinLabel"
	min_label.text = "%.2f" % output_min
	min_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	min_label.font_size = 20
	min_label.modulate = Color(0.7, 0.7, 0.7, 0.8)
	min_label.outline_size = 3
	min_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	min_label.scale = Vector3.ONE * 0.08
	min_label.position = Vector3(-line_length * 0.5, -0.08, 0)
	add_child(min_label)

	# Max label
	max_label = Label3D.new()
	max_label.name = "MaxLabel"
	max_label.text = "%.2f" % output_max
	max_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	max_label.font_size = 20
	max_label.modulate = Color(0.7, 0.7, 0.7, 0.8)
	max_label.outline_size = 3
	max_label.outline_modulate = Color(0.0, 0.0, 0.0, 1.0)
	max_label.scale = Vector3.ONE * 0.08
	max_label.position = Vector3(line_length * 0.5, -0.08, 0)
	add_child(max_label)

func _process(_delta: float) -> void:
	if point:
		_constrain_point()
		_update_output()

func _constrain_point() -> void:
	# Constrain point to line (X axis only)
	var pos = point.position
	var half_length = line_length * 0.5
	pos.x = clamp(pos.x, -half_length, half_length)
	pos.y = 0.0
	pos.z = 0.0
	point.position = pos

func _update_output() -> void:
	if not point:
		return

	var normalized = (point.position.x + line_length * 0.5) / line_length
	var output_value = lerp(output_min, output_max, normalized)

	if show_labels and value_label:
		value_label.text = "%s: %.2f" % [label_text, output_value]
		value_label.position = point.position + Vector3(0, 0.08, 0)

	value_changed.emit(output_value)

func get_value() -> float:
	if not point:
		return (output_min + output_max) * 0.5
	var normalized = (point.position.x + line_length * 0.5) / line_length
	return lerp(output_min, output_max, normalized)

func set_value(value: float) -> void:
	if not point:
		return
	var normalized = inverse_lerp(output_min, output_max, value)
	var x_pos = (normalized * line_length) - (line_length * 0.5)
	point.position.x = x_pos
