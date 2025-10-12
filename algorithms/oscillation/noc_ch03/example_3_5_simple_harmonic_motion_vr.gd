# ===========================================================================
# NOC Example 3.5: Simple Harmonic Motion
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

@export var amplitude: float = 0.2
@export var frequency: float = 1.5

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
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var amp_controller := CONTROLLER_SCENE.instantiate()
	amp_controller.parameter_name = "Amplitude"
	amp_controller.min_value = 0.05
	amp_controller.max_value = 0.35
	amp_controller.default_value = amplitude
	amp_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(amp_controller)
	amp_controller.value_changed.connect(func(v: float) -> void:
		amplitude = v
		_trail_points.clear()
	)
	amp_controller.set_value(amplitude)

	var freq_controller := CONTROLLER_SCENE.instantiate()
	freq_controller.parameter_name = "Frequency"
	freq_controller.min_value = 0.5
	freq_controller.max_value = 4.0
	freq_controller.default_value = frequency
	freq_controller.position = Vector3(0, -0.18, 0)
	freq_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(freq_controller)
	freq_controller.value_changed.connect(func(v: float) -> void:
		frequency = v
		_trail_points.clear()
	)
	freq_controller.set_value(frequency)

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

	var x := sin(_time * frequency * TAU) * amplitude
	var pos := Vector3(x, 0.5, 0)

	_bob.position = pos
	_trail_points.append(pos)

	if _trail_points.size() > 150:
		_trail_points.pop_front()

	_update_trail()

	_status_label.text = "Simple Harmonic | X %.2f" % x

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
