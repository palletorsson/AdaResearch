# ===========================================================================
# NOC Example 1.5: Exercise 1.5: Accelerate and Decelerate
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

var _sim_root: Node3D
var _ball: MeshInstance3D
var _target: MeshInstance3D
var _position: Vector3 = Vector3(-0.3, 0.5, 0)
var _velocity: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3(0.3, 0.5, 0)
var _max_speed: float = 0.08
var _max_force: float = 0.005
var _ball_radius: float = 0.03
var _time: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_objects()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


func _spawn_objects() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _ball_radius
	sphere.height = _ball_radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

	_target = MeshInstance3D.new()
	var target_sphere := SphereMesh.new()
	target_sphere.radius = 0.02
	target_sphere.height = 0.04
	_target.mesh = target_sphere
	_target.material_override = MAT_TARGET
	_target.position = _target_position
	_sim_root.add_child(_target)

func _process(delta: float) -> void:
	_time += delta

	_target_position.x = sin(_time * 0.8) * 0.3
	_target_position.z = cos(_time * 0.5) * 0.25
	_target.position = _target_position

	var to_target := _target_position - _position
	var distance := to_target.length()

	if distance > 0.01:
		var desired := to_target.normalized() * _max_speed

		if distance < 0.15:
			var m := remap(distance, 0.0, 0.15, 0.0, 1.0)
			desired *= m

		var steer := desired - _velocity
		steer = steer.limit_length(_max_force)

		_velocity += steer
		_velocity = _velocity.limit_length(_max_speed)
	else:
		_velocity *= 0.95

	_position += _velocity
	_ball.position = _position
