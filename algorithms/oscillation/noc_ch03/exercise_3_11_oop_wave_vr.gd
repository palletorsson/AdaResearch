extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var wave_amplitude: float = 0.1
@export var wave_speed: float = 0.04

var _sim_root: Node3D
var _wave: Wave
var _status_label: Label3D
var _controller_root: Node3D

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
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var amp_controller := CONTROLLER_SCENE.instantiate()
	amp_controller.parameter_name = "Amplitude"
	amp_controller.min_value = 0.03
	amp_controller.max_value = 0.2
	amp_controller.default_value = wave_amplitude
	amp_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(amp_controller)
	amp_controller.value_changed.connect(func(v: float) -> void:
		wave_amplitude = v
		if _wave:
			_wave.amplitude = v
	)
	amp_controller.set_value(wave_amplitude)

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Speed"
	speed_controller.min_value = 0.01
	speed_controller.max_value = 0.12
	speed_controller.default_value = wave_speed
	speed_controller.position = Vector3(0, -0.18, 0)
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		wave_speed = v
		if _wave:
			_wave.speed = v
	)
	speed_controller.set_value(wave_speed)

func _spawn_wave() -> void:
	_wave = Wave.new()
	_wave.init(_sim_root, MAT_WAVE)
	_wave.amplitude = wave_amplitude
	_wave.speed = wave_speed
	_wave.wavelength = 0.12

func _process(delta: float) -> void:
	_wave.update(delta)
	_status_label.text = "OOP Wave"

class Wave:
	var root: Node3D
	var mesh_instance: MeshInstance3D
	var amplitude: float = 0.1
	var wavelength: float = 0.12
	var speed: float = 0.04
	var theta: float = 0.0
	var num_points: int = 80

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Wave"
		parent.add_child(root)

		mesh_instance = MeshInstance3D.new()
		mesh_instance.material_override = mat
		root.add_child(mesh_instance)

	func update(_delta: float) -> void:
		theta += speed

		var mesh := ImmediateMesh.new()
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

		var angle := theta
		for i in num_points:
			var x := remap(i, 0, num_points - 1, -0.4, 0.4)
			var y := sin(angle) * amplitude
			var pos := Vector3(x, 0.5 + y, 0)
			mesh.surface_set_color(Color(1.0, 0.75, 0.95))
			mesh.surface_add_vertex(pos)
			angle += (TAU / wavelength) * (0.8 / num_points)

		mesh.surface_end()
		mesh_instance.mesh = mesh

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
