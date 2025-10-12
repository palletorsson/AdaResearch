extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ROD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_BOB := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var arm1_length: float = 0.2
@export var arm2_length: float = 0.2
@export var gravity: float = 0.4

var _sim_root: Node3D
var _anchor: Node3D
var _rod1: MeshInstance3D
var _bob1: MeshInstance3D
var _pivot2: Node3D
var _rod2: MeshInstance3D
var _bob2: MeshInstance3D
var _trail: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _status_label: Label3D
var _controller_root: Node3D

var _angle1: float = PI / 2.0
var _angle2: float = PI / 2.0
var _angular_vel1: float = 0.0
var _angular_vel2: float = 0.0
var _angular_acc1: float = 0.0
var _angular_acc2: float = 0.0
var _mass1: float = 1.0
var _mass2: float = 1.0

func _ready() -> void:
	_setup_environment()
	_spawn_pendulum()
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

	var gravity_controller := CONTROLLER_SCENE.instantiate()
	gravity_controller.parameter_name = "Gravity"
	gravity_controller.min_value = 0.1
	gravity_controller.max_value = 1.0
	gravity_controller.default_value = gravity
	gravity_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(gravity_controller)
	gravity_controller.value_changed.connect(func(v: float) -> void:
		gravity = v
	)
	gravity_controller.set_value(gravity)

func _spawn_pendulum() -> void:
	_anchor = Node3D.new()
	_anchor.position = Vector3(0, 0.9, 0)
	_sim_root.add_child(_anchor)

	_rod1 = MeshInstance3D.new()
	var cylinder1 := CylinderMesh.new()
	cylinder1.top_radius = 0.005
	cylinder1.bottom_radius = 0.005
	cylinder1.height = arm1_length
	_rod1.mesh = cylinder1
	_rod1.material_override = MAT_ROD
	_anchor.add_child(_rod1)

	_bob1 = MeshInstance3D.new()
	var sphere1 := SphereMesh.new()
	sphere1.radius = 0.03
	_bob1.mesh = sphere1
	_bob1.material_override = MAT_BOB
	_anchor.add_child(_bob1)

	_pivot2 = Node3D.new()
	_anchor.add_child(_pivot2)

	_rod2 = MeshInstance3D.new()
	var cylinder2 := CylinderMesh.new()
	cylinder2.top_radius = 0.005
	cylinder2.bottom_radius = 0.005
	cylinder2.height = arm2_length
	_rod2.mesh = cylinder2
	_rod2.material_override = MAT_ROD
	_pivot2.add_child(_rod2)

	_bob2 = MeshInstance3D.new()
	var sphere2 := SphereMesh.new()
	sphere2.radius = 0.03
	_bob2.mesh = sphere2
	_bob2.material_override = MAT_BOB
	_pivot2.add_child(_bob2)

	_trail = MeshInstance3D.new()
	_sim_root.add_child(_trail)

func _process(delta: float) -> void:
	var num1 := -gravity * (2 * _mass1 + _mass2) * sin(_angle1)
	num1 -= _mass2 * gravity * sin(_angle1 - 2 * _angle2)
	num1 -= 2 * sin(_angle1 - _angle2) * _mass2
	num1 *= (_angular_vel2 * _angular_vel2 * arm2_length + _angular_vel1 * _angular_vel1 * arm1_length * cos(_angle1 - _angle2))
	var den1 := arm1_length * (2 * _mass1 + _mass2 - _mass2 * cos(2 * _angle1 - 2 * _angle2))
	_angular_acc1 = num1 / den1

	var num2 := 2 * sin(_angle1 - _angle2)
	num2 *= (_angular_vel1 * _angular_vel1 * arm1_length * (_mass1 + _mass2))
	num2 += gravity * (_mass1 + _mass2) * cos(_angle1)
	num2 += _angular_vel2 * _angular_vel2 * arm2_length * _mass2 * cos(_angle1 - _angle2)
	var den2 := arm2_length * (2 * _mass1 + _mass2 - _mass2 * cos(2 * _angle1 - 2 * _angle2))
	_angular_acc2 = num2 / den2

	_angular_vel1 += _angular_acc1
	_angular_vel2 += _angular_acc2
	_angle1 += _angular_vel1
	_angle2 += _angular_vel2

	_angular_vel1 *= 0.995
	_angular_vel2 *= 0.995

	_anchor.rotation = Vector3(0, 0, _angle1)
	_rod1.position = Vector3(0, -arm1_length / 2, 0)
	_bob1.position = Vector3(0, -arm1_length, 0)
	_pivot2.position = Vector3(0, -arm1_length, 0)
	_pivot2.rotation = Vector3(0, 0, _angle2 - _angle1)
	_rod2.position = Vector3(0, -arm2_length / 2, 0)
	_bob2.position = Vector3(0, -arm2_length, 0)

	_trail_points.append(_bob2.global_position)
	if _trail_points.size() > 300:
		_trail_points.pop_front()

	_update_trail()

	_status_label.text = "Double Pendulum"

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
