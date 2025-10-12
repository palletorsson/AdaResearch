# ===========================================================================
# NOC Example 5.12: Sine/Cosine Lookup Table
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_SINE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_COSINE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var table_size: int = 360
@export var wave_frequency: float = 1.0
@export var wave_amplitude: float = 0.15

var _sim_root: Node3D
var _sine_wave: MeshInstance3D
var _cosine_wave: MeshInstance3D
var _sine_lookup: PackedFloat32Array
var _cosine_lookup: PackedFloat32Array
var _status_label: Label3D
var _controller_root: Node3D
var _time: float = 0.0

func _ready() -> void:
	_setup_environment()
	_generate_lookup_tables()
	_spawn_waves()
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

	var freq_controller := CONTROLLER_SCENE.instantiate()
	freq_controller.parameter_name = "Frequency"
	freq_controller.min_value = 0.5
	freq_controller.max_value = 5.0
	freq_controller.default_value = wave_frequency
	freq_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(freq_controller)
	freq_controller.value_changed.connect(func(v: float) -> void:
		wave_frequency = v
	)
	freq_controller.set_value(wave_frequency)

	var amp_controller := CONTROLLER_SCENE.instantiate()
	amp_controller.parameter_name = "Amplitude"
	amp_controller.min_value = 0.05
	amp_controller.max_value = 0.25
	amp_controller.default_value = wave_amplitude
	amp_controller.position = Vector3(0, -0.18, 0)
	amp_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(amp_controller)
	amp_controller.value_changed.connect(func(v: float) -> void:
		wave_amplitude = v
	)
	amp_controller.set_value(wave_amplitude)

func _generate_lookup_tables() -> void:
	_sine_lookup.resize(table_size)
	_cosine_lookup.resize(table_size)

	for i in table_size:
		var angle := (float(i) / table_size) * TAU
		_sine_lookup[i] = sin(angle)
		_cosine_lookup[i] = cos(angle)

func _spawn_waves() -> void:
	_sine_wave = MeshInstance3D.new()
	_sim_root.add_child(_sine_wave)

	_cosine_wave = MeshInstance3D.new()
	_sim_root.add_child(_cosine_wave)

func _process(delta: float) -> void:
	_time += delta * wave_frequency

	_update_wave(_sine_wave, _sine_lookup, Vector3(0, 0.6, 0), MAT_SINE)
	_update_wave(_cosine_wave, _cosine_lookup, Vector3(0, 0.4, 0), MAT_COSINE)

	_status_label.text = "Sine/Cosine Lookup | Table Size: %d" % table_size

func _update_wave(wave: MeshInstance3D, lookup: PackedFloat32Array, offset: Vector3, mat: Material) -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_points := 60
	for i in num_points:
		var x := remap(i, 0, num_points - 1, -0.4, 0.4)
		var lookup_index := int((i + _time * 10.0)) % table_size
		var y := lookup[lookup_index] * wave_amplitude
		var pos := Vector3(x, y, 0) + offset
		mesh.surface_set_color(Color(1.0, 0.8, 0.95))
		mesh.surface_add_vertex(pos)

	mesh.surface_end()
	wave.mesh = mesh
	wave.material_override = mat
