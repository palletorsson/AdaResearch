# ===========================================================================
# NOC Example 3.9: The Wave
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var wavelength: float = 0.15
@export var amplitude: float = 0.12
@export var wave_speed: float = 0.05

var _sim_root: Node3D
var _wave_mesh: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D
var _theta: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_wave()
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

	var wavelength_controller := CONTROLLER_SCENE.instantiate()
	wavelength_controller.parameter_name = "Wavelength"
	wavelength_controller.min_value = 0.05
	wavelength_controller.max_value = 0.3
	wavelength_controller.default_value = wavelength
	wavelength_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(wavelength_controller)
	wavelength_controller.value_changed.connect(func(v: float) -> void:
		wavelength = v
	)
	wavelength_controller.set_value(wavelength)

	var amplitude_controller := CONTROLLER_SCENE.instantiate()
	amplitude_controller.parameter_name = "Amplitude"
	amplitude_controller.min_value = 0.03
	amplitude_controller.max_value = 0.25
	amplitude_controller.default_value = amplitude
	amplitude_controller.position = Vector3(0, -0.18, 0)
	amplitude_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(amplitude_controller)
	amplitude_controller.value_changed.connect(func(v: float) -> void:
		amplitude = v
	)
	amplitude_controller.set_value(amplitude)

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Speed"
	speed_controller.min_value = 0.01
	speed_controller.max_value = 0.15
	speed_controller.default_value = wave_speed
	speed_controller.position = Vector3(0, -0.36, 0)
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		wave_speed = v
	)
	speed_controller.set_value(wave_speed)

func _spawn_wave() -> void:
	_wave_mesh = MeshInstance3D.new()
	_sim_root.add_child(_wave_mesh)

func _process(_delta: float) -> void:
	_theta += wave_speed
	_update_wave()
	_status_label.text = "Animated Wave"

func _update_wave() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_points := 80
	var angle := _theta
	for i in num_points:
		var x := remap(i, 0, num_points - 1, -0.4, 0.4)
		var y := sin(angle) * amplitude
		var pos := Vector3(x, 0.5 + y, 0)
		mesh.surface_set_color(Color(1.0, 0.75, 0.95))
		mesh.surface_add_vertex(pos)
		angle += (TAU / wavelength) * (0.8 / num_points)

	mesh.surface_end()
	_wave_mesh.mesh = mesh
	_wave_mesh.material_override = MAT_WAVE
