extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_SPIRAL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var spiral_growth: float = 0.002
@export var angular_speed: float = 0.05

var _sim_root: Node3D
var _spiral_mesh: MeshInstance3D
var _spiral_points: Array[Vector3] = []
var _status_label: Label3D
var _controller_root: Node3D
var _angle: float = 0.0
var _radius: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_spiral()
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

	var growth_controller := CONTROLLER_SCENE.instantiate()
	growth_controller.parameter_name = "Growth"
	growth_controller.min_value = 0.001
	growth_controller.max_value = 0.005
	growth_controller.default_value = spiral_growth
	growth_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(growth_controller)
	growth_controller.value_changed.connect(func(v: float) -> void:
		spiral_growth = v
		_spiral_points.clear()
		_angle = 0.0
		_radius = 0.0
	)
	growth_controller.set_value(spiral_growth)

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Speed"
	speed_controller.min_value = 0.01
	speed_controller.max_value = 0.15
	speed_controller.default_value = angular_speed
	speed_controller.position = Vector3(0, -0.18, 0)
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		angular_speed = v
	)
	speed_controller.set_value(angular_speed)

func _spawn_spiral() -> void:
	_spiral_mesh = MeshInstance3D.new()
	_sim_root.add_child(_spiral_mesh)

func _process(_delta: float) -> void:
	_angle += angular_speed
	_radius += spiral_growth

	var x := cos(_angle) * _radius
	var y := sin(_angle) * _radius
	var pos := Vector3(x, 0.5 + y, 0)

	_spiral_points.append(pos)

	if _spiral_points.size() > 500:
		_spiral_points.pop_front()

	if _radius > 0.4:
		_angle = 0.0
		_radius = 0.0
		_spiral_points.clear()

	_update_spiral()

	_status_label.text = "Spiral | Radius %.2f" % _radius

func _update_spiral() -> void:
	if _spiral_points.size() < 2:
		return

	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(_spiral_points.size()):
		var alpha := float(i) / _spiral_points.size()
		mesh.surface_set_color(Color(1.0, 0.75, 0.95, alpha * 0.8))
		mesh.surface_add_vertex(_spiral_points[i])

	mesh.surface_end()
	_spiral_mesh.mesh = mesh
	_spiral_mesh.material_override = MAT_SPIRAL
