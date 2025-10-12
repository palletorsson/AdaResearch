extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BAR := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_END := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var rotation_speed: float = 0.03
@export var baton_length: float = 0.3

var _sim_root: Node3D
var _baton: Node3D
var _bar: MeshInstance3D
var _end_a: MeshInstance3D
var _end_b: MeshInstance3D
var _trail_a: Array[Vector3] = []
var _trail_b: Array[Vector3] = []
var _trail_mesh: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D
var _angle: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_baton()
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
	speed_controller.parameter_name = "Rotation Speed"
	speed_controller.min_value = -0.1
	speed_controller.max_value = 0.1
	speed_controller.default_value = rotation_speed
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		rotation_speed = v
	)
	speed_controller.set_value(rotation_speed)

func _spawn_baton() -> void:
	_baton = Node3D.new()
	_baton.position = Vector3(0, 0.5, 0)
	_sim_root.add_child(_baton)

	_bar = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(baton_length, 0.015, 0.015)
	_bar.mesh = box
	_bar.material_override = MAT_BAR
	_baton.add_child(_bar)

	_end_a = MeshInstance3D.new()
	var sphere_a := SphereMesh.new()
	sphere_a.radius = 0.025
	_end_a.mesh = sphere_a
	_end_a.material_override = MAT_END
	_end_a.position = Vector3(-baton_length / 2, 0, 0)
	_baton.add_child(_end_a)

	_end_b = MeshInstance3D.new()
	var sphere_b := SphereMesh.new()
	sphere_b.radius = 0.025
	_end_b.mesh = sphere_b
	_end_b.material_override = MAT_END
	_end_b.position = Vector3(baton_length / 2, 0, 0)
	_baton.add_child(_end_b)

	_trail_mesh = MeshInstance3D.new()
	_sim_root.add_child(_trail_mesh)

func _process(_delta: float) -> void:
	_angle += rotation_speed
	_baton.rotation = Vector3(0, 0, _angle)

	_trail_a.append(_end_a.global_position)
	_trail_b.append(_end_b.global_position)

	if _trail_a.size() > 150:
		_trail_a.pop_front()
	if _trail_b.size() > 150:
		_trail_b.pop_front()

	_update_trails()

	_status_label.text = "Rotating Baton | %.1f°" % rad_to_deg(fmod(_angle, TAU))

func _update_trails() -> void:
	var mesh := ImmediateMesh.new()

	if _trail_a.size() > 1:
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(_trail_a.size()):
			var alpha := float(i) / _trail_a.size()
			mesh.surface_set_color(Color(1.0, 0.75, 0.95, alpha * 0.5))
			mesh.surface_add_vertex(_trail_a[i])
		mesh.surface_end()

	if _trail_b.size() > 1:
		mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for i in range(_trail_b.size()):
			var alpha := float(i) / _trail_b.size()
			mesh.surface_set_color(Color(1.0, 0.75, 0.95, alpha * 0.5))
			mesh.surface_add_vertex(_trail_b[i])
		mesh.surface_end()

	_trail_mesh.mesh = mesh
