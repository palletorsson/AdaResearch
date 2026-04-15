extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

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
var _control_panel: Node3D

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
	_setup_controls()
	call_deferred("_apply_standard_presentation")
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
	sphere1.height = sphere1.radius * 2.0
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
	sphere2.height = sphere2.radius * 2.0
	_bob2.mesh = sphere2
	_bob2.material_override = MAT_BOB
	_pivot2.add_child(_bob2)

	_trail = MeshInstance3D.new()
	_sim_root.add_child(_trail)

func _setup_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("DOUBLE PENDULUM", [
		[
			{"type": "slider_h", "label": "ARM 1", "default": (arm1_length - 0.05) / 0.35},
			{"type": "slider_h", "label": "ARM 2", "default": (arm2_length - 0.05) / 0.35},
		],
		[
			{"type": "slider_h", "label": "GRAVITY", "default": (gravity - 0.1) / 0.9},
		],
		[{"type": "button", "label": "RESET"}],
	])
	_control_panel.position = Vector3(0.3, 0.2, 0.1)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	var arm1_slider: Node = _control_panel.find_child("Param_0", true, false)
	var arm2_slider: Node = _control_panel.find_child("Param_1", true, false)
	var grav_slider: Node = _control_panel.find_child("Param_2", true, false)

	if arm1_slider and arm1_slider.has_signal("slider_moved"):
		arm1_slider.slider_moved.connect(func(_n: String) -> void:
			arm1_length = 0.05 + arm1_slider.get_normalized_value() * 0.35
			var cyl: CylinderMesh = _rod1.mesh
			cyl.height = arm1_length
		)
	if arm2_slider and arm2_slider.has_signal("slider_moved"):
		arm2_slider.slider_moved.connect(func(_n: String) -> void:
			arm2_length = 0.05 + arm2_slider.get_normalized_value() * 0.35
			var cyl: CylinderMesh = _rod2.mesh
			cyl.height = arm2_length
		)
	if grav_slider and grav_slider.has_signal("slider_moved"):
		grav_slider.slider_moved.connect(func(_n: String) -> void:
			gravity = 0.1 + grav_slider.get_normalized_value() * 0.9
		)

	var reset_btn: Node = _control_panel.find_child("Btn_0", true, false)
	if reset_btn:
		var area: Node = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b: bool) -> void:
				_angle1 = PI / 2.0
				_angle2 = PI / 2.0
				_angular_vel1 = 0.0
				_angular_vel2 = 0.0
				_trail_points.clear()
			)


func _process(_delta: float) -> void:
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

func _apply_standard_presentation() -> void:
	await get_tree().process_frame
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass


