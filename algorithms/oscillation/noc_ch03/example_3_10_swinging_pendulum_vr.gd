# ===========================================================================
# NOC Example 3.10: Swinging Pendulum
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ROD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_BOB := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var arm_length: float = 0.3
@export var gravity: float = 0.4

var _sim_root: Node3D
var _anchor: Node3D
var _rod: MeshInstance3D
var _bob: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D
var _angle: float = PI / 4.0
var _angular_velocity: float = 0.0
var _angular_acceleration: float = 0.0

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

	_rod = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.005
	cylinder.bottom_radius = 0.005
	cylinder.height = arm_length
	_rod.mesh = cylinder
	_rod.material_override = MAT_ROD
	_anchor.add_child(_rod)

	_bob = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	_bob.mesh = sphere
	_bob.material_override = MAT_BOB
	_anchor.add_child(_bob)

func _process(delta: float) -> void:
	_angular_acceleration = (-gravity / arm_length) * sin(_angle)
	_angular_velocity += _angular_acceleration
	_angular_velocity *= 0.995
	_angle += _angular_velocity

	_anchor.rotation = Vector3(0, 0, _angle)
	_rod.position = Vector3(0, -arm_length / 2, 0)
	_bob.position = Vector3(0, -arm_length, 0)

	_status_label.text = "Pendulum | %.1f°" % rad_to_deg(_angle)
