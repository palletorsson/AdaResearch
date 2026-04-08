# ===========================================================================
# NOC Example 1.5: Exercise 1.5: Accelerate and Decelerate
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

# @identity
# essence: steer = (desired - velocity).clamp(max_force). Seek + arrival. Distance to target scales desired speed.
# desire: to watch a ball chase a moving target, accelerating when far and decelerating when close — smooth arrival from pure math
# critical_parameter: max_force — the steering budget. High force = snappy turns. Low force = lazy curves. The tightness of the feedback loop.
# triggers: automatic — target traces sinusoidal curves, ball steers toward it every frame
# emerges: smooth deceleration zone near the target where speed ramps down proportionally to distance
# needs: auto-running simulation [has]. Missing: VR grabbable target, max_force slider, trail visualization
# relationships: extends bouncing_ball (adds steering instead of bouncing). Prepares for boid_flocking (many agents steering). Contrasts with exercise_1_8 (attraction vs steering).
# truth: smooth arrival is not a decision — it is a feedback loop. The closer you get, the gentler the approach.

class_name AccelerateDecelerateVR
extends Node3D

const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var max_speed: float = 0.08
@export var max_force: float = 0.005
@export var ball_radius: float = 0.05
@export_color_no_alpha var ball_color: Color = Color(0.3, 0.9, 1.0)
@export_color_no_alpha var target_color: Color = Color(1.0, 0.4, 0.7)

var _sim_root: Node3D
var _ball: MeshInstance3D
var _target: MeshInstance3D
var _position: Vector3 = Vector3(-0.3, 0.5, 0)
var _velocity: Vector3 = Vector3.ZERO
var _target_position: Vector3 = Vector3(0.3, 0.5, 0)
var _time: float = 0.0
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _line_mesh: ImmediateMesh
var _line_instance: MeshInstance3D
var _max_trail_length: int = 200

func _ready() -> void:
	_setup_environment()
	_spawn_objects()
	_setup_trail()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

func _spawn_objects() -> void:
	# Ball — the chaser
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	_ball.mesh = sphere
	var ball_mat := StandardMaterial3D.new()
	ball_mat.albedo_color = ball_color
	ball_mat.emission_enabled = true
	ball_mat.emission = ball_color * 0.4
	ball_mat.emission_energy_multiplier = 1.5
	ball_mat.metallic = 0.3
	ball_mat.roughness = 0.4
	_ball.material_override = ball_mat
	_sim_root.add_child(_ball)

	# Target — glowing pulsing sphere
	_target = MeshInstance3D.new()
	var target_sphere := SphereMesh.new()
	target_sphere.radius = 0.04
	target_sphere.height = 0.08
	_target.mesh = target_sphere
	var target_mat := StandardMaterial3D.new()
	target_mat.albedo_color = target_color
	target_mat.emission_enabled = true
	target_mat.emission = target_color
	target_mat.emission_energy_multiplier = 2.0
	target_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_target.material_override = target_mat
	_target.position = _target_position
	_sim_root.add_child(_target)

func _setup_trail() -> void:
	# Chase trail
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	var trail_mat := StandardMaterial3D.new()
	trail_mat.albedo_color = Color(ball_color, 0.4)
	trail_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	trail_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_trail_instance.material_override = trail_mat
	_sim_root.add_child(_trail_instance)
	# Connection line to target
	_line_mesh = ImmediateMesh.new()
	_line_instance = MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	var line_mat := StandardMaterial3D.new()
	line_mat.albedo_color = Color(1.0, 1.0, 1.0, 0.15)
	line_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_line_instance.material_override = line_mat
	_sim_root.add_child(_line_instance)

func _process(delta: float) -> void:
	_time += delta

	_target_position.x = sin(_time * 0.8) * 0.3
	_target_position.z = cos(_time * 0.5) * 0.25
	_target.position = _target_position

	var to_target := _target_position - _position
	var distance := to_target.length()

	if distance > 0.01:
		var desired := to_target.normalized() * max_speed

		if distance < 0.15:
			var m := remap(distance, 0.0, 0.15, 0.0, 1.0)
			desired *= m

		var steer := desired - _velocity
		steer = steer.limit_length(max_force)

		_velocity += steer
		_velocity = _velocity.limit_length(max_speed)
	else:
		_velocity *= 0.95

	_position += _velocity
	_ball.position = _position

	# Trail
	_trail_points.append(_position)
	if _trail_points.size() > _max_trail_length:
		_trail_points.remove_at(0)
	_trail_mesh.clear_surfaces()
	if _trail_points.size() >= 2:
		_trail_mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)
		for p in _trail_points:
			_trail_mesh.surface_add_vertex(p)
		_trail_mesh.surface_end()

	# Connection line
	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_line_mesh.surface_add_vertex(_position)
	_line_mesh.surface_add_vertex(_target_position)
	_line_mesh.surface_end()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
