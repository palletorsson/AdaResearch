extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_WAVE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_waves: int = 3
@export var wave_speed: float = 0.03

var _sim_root: Node3D
var _wave_mesh: MeshInstance3D
var _waves: Array[Dictionary] = []
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_init_waves()
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

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Speed"
	speed_controller.min_value = 0.01
	speed_controller.max_value = 0.1
	speed_controller.default_value = wave_speed
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		wave_speed = v
	)
	speed_controller.set_value(wave_speed)

func _init_waves() -> void:
	_waves.clear()
	for i in num_waves:
		_waves.append({
			"amplitude": randf_range(0.03, 0.08),
			"wavelength": randf_range(0.08, 0.2),
			"theta": randf() * TAU,
			"speed": randf_range(0.8, 1.2)
		})

func _spawn_wave() -> void:
	_wave_mesh = MeshInstance3D.new()
	_sim_root.add_child(_wave_mesh)

func _process(_delta: float) -> void:
	for wave in _waves:
		wave.theta += wave_speed * wave.speed

	_update_wave()
	_status_label.text = "Additive Wave | %d waves" % num_waves

func _update_wave() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	var num_points := 80
	for i in num_points:
		var x := remap(i, 0, num_points - 1, -0.4, 0.4)
		var y := 0.0

		for wave in _waves:
			var angle: float = wave.theta + (x / wave.wavelength) * TAU
			y += sin(angle) * wave.amplitude

		var pos := Vector3(x, 0.5 + y, 0)
		mesh.surface_set_color(Color(1.0, 0.75, 0.95))
		mesh.surface_add_vertex(pos)

	mesh.surface_end()
	_wave_mesh.mesh = mesh
	_wave_mesh.material_override = MAT_WAVE
