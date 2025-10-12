class_name ParameterController3D
extends Node3D

## 3D Parameter Controller - Grabbable slider/dial for VR interaction
## Based on line.tscn primitive. Uses the project-wide light pink palette.

signal value_changed(new_value: float)

const TRACK_MATERIAL: StandardMaterial3D = preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const HANDLE_MATERIAL: StandardMaterial3D = preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const LABEL_TINT: Color = Color(1.0, 0.9, 1.0)
const TRACK_LENGTH: float = 0.3

@export var parameter_name: String = "Parameter"
@export var min_value: float = 0.0
@export var max_value: float = 1.0
@export var default_value: float = 0.5
@export var step_size: float = 0.01

var current_value: float = 0.5

var slider_track: MeshInstance3D
var handle: MeshInstance3D
var label: Label3D

var is_grabbed: bool = false
var grab_offset: Vector3 = Vector3.ZERO

func _ready():
	current_value = clamp(default_value, min_value, max_value)
	create_slider_geometry()
	create_label()
	update_handle_position()
	update_label_text()

func create_slider_geometry() -> void:
	"""Create slider visuals using the pink palette."""
	slider_track = MeshInstance3D.new()
	var track_mesh := BoxMesh.new()
	track_mesh.size = Vector3(TRACK_LENGTH, 0.02, 0.02)
	slider_track.mesh = track_mesh
	slider_track.material_override = TRACK_MATERIAL.duplicate()
	add_child(slider_track)

	handle = MeshInstance3D.new()
	var handle_mesh := SphereMesh.new()
	handle_mesh.radius = 0.03
	handle_mesh.height = 0.06
	handle.mesh = handle_mesh
	handle.material_override = HANDLE_MATERIAL.duplicate()
	add_child(handle)

func create_label() -> void:
	label = Label3D.new()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.outline_size = 4
	label.outline_modulate = Color.BLACK
	label.modulate = LABEL_TINT
	label.position = Vector3(0, 0.08, 0)
	add_child(label)

func update_label_text() -> void:
	if label:
		label.text = "%s: %.2f" % [parameter_name, current_value]

func update_handle_position() -> void:
	if handle:
		var t: float = inverse_lerp(min_value, max_value, current_value)
		var x_pos: float = lerp(-TRACK_LENGTH / 2.0, TRACK_LENGTH / 2.0, t)
		handle.position = Vector3(x_pos, 0, 0)

func set_value(new_value: float) -> void:
	current_value = clamp(new_value, min_value, max_value)
	update_handle_position()
	update_label_text()
	value_changed.emit(current_value)

func get_value() -> float:
	return current_value

func on_grab_start(controller_position: Vector3) -> void:
	is_grabbed = true
	grab_offset = handle.global_position - controller_position

func on_grab_update(controller_position: Vector3) -> void:
	if not is_grabbed:
		return

	var local_pos: Vector3 = to_local(controller_position + grab_offset)
	var x_clamped: float = clamp(local_pos.x, -TRACK_LENGTH / 2.0, TRACK_LENGTH / 2.0)
	var t: float = inverse_lerp(-TRACK_LENGTH / 2.0, TRACK_LENGTH / 2.0, x_clamped)
	var new_value: float = lerp(min_value, max_value, t)

	if step_size > 0.0:
		new_value = round(new_value / step_size) * step_size

	set_value(new_value)

func on_grab_end() -> void:
	is_grabbed = false
