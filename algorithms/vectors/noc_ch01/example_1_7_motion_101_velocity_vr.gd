# ===========================================================================
# NOC Example 1.7: Motion 101: Velocity
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3(0.08, 0.05, 0.06)
var _bounds_min: Vector3 = Vector3(-0.45, 0.05, -0.45)
var _bounds_max: Vector3 = Vector3(0.45, 0.95, 0.45)
var _ball_radius: float = 0.03

func _ready() -> void:
	_setup_environment()
	_spawn_ball()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _ball_radius
	sphere.height = _ball_radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

func _process(delta: float) -> void:
	_position += _velocity * delta * 10.0

	if _position.x - _ball_radius < _bounds_min.x or _position.x + _ball_radius > _bounds_max.x:
		_velocity.x *= -1.0
		_position.x = clamp(_position.x, _bounds_min.x + _ball_radius, _bounds_max.x - _ball_radius)

	if _position.y - _ball_radius < _bounds_min.y or _position.y + _ball_radius > _bounds_max.y:
		_velocity.y *= -1.0
		_position.y = clamp(_position.y, _bounds_min.y + _ball_radius, _bounds_max.y - _ball_radius)

	if _position.z - _ball_radius < _bounds_min.z or _position.z + _ball_radius > _bounds_max.z:
		_velocity.z *= -1.0
		_position.z = clamp(_position.z, _bounds_min.z + _ball_radius, _bounds_max.z - _ball_radius)

	_ball.position = _position
