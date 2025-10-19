# ===========================================================================
# NOC Example 1.2: Bouncing Ball with Vectors
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_ARROW := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var gravity: float = 0.01
@export var bounce_elasticity: float = 0.9

var _sim_root: Node3D
var _ball: MeshInstance3D
var _arrow: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3(0.15, 0, 0.12)

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

	var elasticity_controller := CONTROLLER_SCENE.instantiate()
	elasticity_controller.parameter_name = "Elasticity"
	elasticity_controller.min_value = 0.5
	elasticity_controller.max_value = 1.0
	elasticity_controller.default_value = bounce_elasticity
	elasticity_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(elasticity_controller)
	elasticity_controller.value_changed.connect(func(v: float) -> void:
		bounce_elasticity = v
	)
	elasticity_controller.set_value(bounce_elasticity)

func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.04
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

	_arrow = MeshInstance3D.new()
	var cylinder := CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = 0.1
	_arrow.mesh = cylinder
	_arrow.material_override = MAT_ARROW
	_sim_root.add_child(_arrow)

func _process(_delta: float) -> void:
	_velocity.y += gravity

	_position += _velocity

	if _position.x > 0.45 or _position.x < -0.45:
		_velocity.x *= -1
	if _position.y > 0.95:
		_position.y = 0.95
		_velocity.y *= -bounce_elasticity
	if _position.y < 0.05:
		_position.y = 0.05
		_velocity.y *= -bounce_elasticity
	if _position.z > 0.45 or _position.z < -0.45:
		_velocity.z *= -1

	_ball.position = _position

	var vel_length := _velocity.length()
	if vel_length > 0.01:
		var arrow_length := vel_length * 2.0
		_arrow.visible = true
		_arrow.position = _position + (_velocity * 0.5)
		_arrow.look_at_from_position(_arrow.position, _position + _velocity, Vector3.UP)
		_arrow.rotate_object_local(Vector3.RIGHT, PI / 2)
		_arrow.scale = Vector3(1, arrow_length, 1)
	else:
		_arrow.visible = false

	_status_label.text = "Ball (Vectors) | Vel %.2f" % vel_length
