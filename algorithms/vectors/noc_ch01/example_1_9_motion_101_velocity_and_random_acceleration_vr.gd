# ===========================================================================
# NOC Example 1.9: Motion 101: Velocity and Random Acceleration
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TRAIL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3.ZERO
var _bounds_min: Vector3 = Vector3(-0.45, 0.05, -0.45)
var _bounds_max: Vector3 = Vector3(0.45, 0.95, 0.45)
var _ball_radius: float = 0.03
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 200

func _ready() -> void:
	_setup_environment()
	_spawn_ball()
	_setup_trail()
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

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	_trail_instance.material_override = MAT_TRAIL
	_sim_root.add_child(_trail_instance)

func _process(delta: float) -> void:
	var random_accel := Vector3(
		randf_range(-0.02, 0.02),
		randf_range(-0.02, 0.02),
		randf_range(-0.02, 0.02)
	)

	_velocity += random_accel
	_velocity = _velocity.limit_length(0.15)
	_position += _velocity

	if _position.x - _ball_radius < _bounds_min.x or _position.x + _ball_radius > _bounds_max.x:
		_velocity.x *= -0.8
		_position.x = clamp(_position.x, _bounds_min.x + _ball_radius, _bounds_max.x - _ball_radius)

	if _position.y - _ball_radius < _bounds_min.y or _position.y + _ball_radius > _bounds_max.y:
		_velocity.y *= -0.8
		_position.y = clamp(_position.y, _bounds_min.y + _ball_radius, _bounds_max.y - _ball_radius)

	if _position.z - _ball_radius < _bounds_min.z or _position.z + _ball_radius > _bounds_max.z:
		_velocity.z *= -0.8
		_position.z = clamp(_position.z, _bounds_min.z + _ball_radius, _bounds_max.z - _ball_radius)

	_ball.position = _position

	_trail_points.append(_position)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)

	_update_trail()

func _update_trail() -> void:
	_trail_mesh.clear_surfaces()
	if _trail_points.size() < 2:
		return

	_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
	for point in _trail_points:
		_trail_mesh.surface_add_vertex(point)
	_trail_mesh.surface_end()
