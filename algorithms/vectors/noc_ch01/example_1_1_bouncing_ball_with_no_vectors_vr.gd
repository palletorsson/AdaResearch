# ===========================================================================
# NOC Example 1.1: Bouncing Ball with No Vectors
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var gravity_magnitude: float = 0.01

var _sim_root: Node3D
var _ball: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

var _x: float = 0.0
var _y: float = 0.5
var _z: float = 0.0
var _x_speed: float = 0.15
var _y_speed: float = 0.0
var _z_speed: float = 0.12

func _ready() -> void:
	_setup_environment()
	_spawn_ball()
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
	gravity_controller.min_value = 0.001
	gravity_controller.max_value = 0.03
	gravity_controller.default_value = gravity_magnitude
	gravity_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(gravity_controller)
	gravity_controller.value_changed.connect(func(v: float) -> void:
		gravity_magnitude = v
	)
	gravity_controller.set_value(gravity_magnitude)

func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

func _process(_delta: float) -> void:
	_y_speed += gravity_magnitude

	_x += _x_speed
	_y += _y_speed
	_z += _z_speed

	if _x > 0.45 or _x < -0.45:
		_x_speed *= -1
	if _y > 0.95:
		_y = 0.95
		_y_speed *= -0.9
	if _y < 0.05:
		_y = 0.05
		_y_speed *= -0.9
	if _z > 0.45 or _z < -0.45:
		_z_speed *= -1

	_ball.position = Vector3(_x, _y, _z)

	_status_label.text = "Ball (No Vectors) | Y %.2f" % _y
