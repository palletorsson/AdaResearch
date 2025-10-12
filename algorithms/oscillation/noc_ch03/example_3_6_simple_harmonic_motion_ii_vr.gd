# ===========================================================================
# NOC Example 3.6: Simple Harmonic Motion II
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BOB := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TRAIL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var amplitude_x: float = 0.2
@export var amplitude_y: float = 0.15
@export var frequency_x: float = 1.2
@export var frequency_y: float = 1.8

var _sim_root: Node3D
var _bob: MeshInstance3D
var _trail: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _status_label: Label3D
var _controller_root: Node3D
var _time: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_scene()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var amp_x_controller := CONTROLLER_SCENE.instantiate()
	amp_x_controller.parameter_name = "Amp X"
	amp_x_controller.min_value = 0.05
	amp_x_controller.max_value = 0.35
	amp_x_controller.default_value = amplitude_x
	amp_x_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(amp_x_controller)
	amp_x_controller.value_changed.connect(func(v: float) -> void:
		amplitude_x = v
		_trail_points.clear()
	)
	amp_x_controller.set_value(amplitude_x)

	var amp_y_controller := CONTROLLER_SCENE.instantiate()
	amp_y_controller.parameter_name = "Amp Y"
	amp_y_controller.min_value = 0.05
	amp_y_controller.max_value = 0.35
	amp_y_controller.default_value = amplitude_y
	amp_y_controller.position = Vector3(0, -0.18, 0)
	amp_y_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(amp_y_controller)
	amp_y_controller.value_changed.connect(func(v: float) -> void:
		amplitude_y = v
		_trail_points.clear()
	)
	amp_y_controller.set_value(amplitude_y)

	var freq_x_controller := CONTROLLER_SCENE.instantiate()
	freq_x_controller.parameter_name = "Freq X"
	freq_x_controller.min_value = 0.5
	freq_x_controller.max_value = 4.0
	freq_x_controller.default_value = frequency_x
	freq_x_controller.position = Vector3(0, -0.36, 0)
	freq_x_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(freq_x_controller)
	freq_x_controller.value_changed.connect(func(v: float) -> void:
		frequency_x = v
		_trail_points.clear()
	)
	freq_x_controller.set_value(frequency_x)

func _spawn_scene() -> void:
	_bob = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	_bob.mesh = sphere
	_bob.material_override = MAT_BOB
	_sim_root.add_child(_bob)

	_trail = MeshInstance3D.new()
	_sim_root.add_child(_trail)

func _process(delta: float) -> void:
	_time += delta

	var x := sin(_time * frequency_x * TAU) * amplitude_x
	var y := sin(_time * frequency_y * TAU) * amplitude_y
	var pos := Vector3(x, 0.5 + y, 0)

	_bob.position = pos
	_trail_points.append(pos)

	if _trail_points.size() > 250:
		_trail_points.pop_front()

	_update_trail()

	_status_label.text = "SHM 2-Axis | Lissajous"

func _update_trail() -> void:
	if _trail_points.size() < 2:
		return

	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(_trail_points.size()):
		var alpha := float(i) / _trail_points.size()
		mesh.surface_set_color(Color(1.0, 0.75, 0.95, alpha * 0.6))
		mesh.surface_add_vertex(_trail_points[i])

	mesh.surface_end()
	_trail.mesh = mesh
