# ===========================================================================
# NOC Example 1.3: Exercise 1.3: 3D Bouncing Ball
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: p += v; v += g; if(wall) v *= -e. Position accumulates velocity, velocity accumulates gravity, walls reverse and damp.
# desire: To trap motion in a box and watch it slowly die — each bounce lower than the last, energy leaking into the walls.
# critical_parameter: _elasticity (0.9) — the fraction of speed kept per bounce. At 1.0 the ball bounces forever; below 1.0 it decays exponentially.
# triggers: Automatic — ball launches with initial velocity, gravity pulls down every frame, boundary collision reverses and damps per-axis
# emerges: The parabolic arc between bounces. The trail drawing the ball’s history as a fading line. The slow settling as elasticity drains energy.
# needs: Auto-running simulation [has], trail visualization [has]. Missing: VR grab to relaunch, elasticity slider, gravity toggle.
# relationships: Simplest dynamics artifact in forces. Foundation for exercise_1_8 (adds attraction). Contrasts with momentum_collision (two bodies vs one).
# truth: A bouncing ball is a clock that runs down. Each bounce measures how much the universe forgot.

class_name BouncingBall3DVR
extends Node3D

const MAT_TRAIL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

@export var ball_radius: float = 0.06
@export var elasticity: float = 0.9
@export var gravity_strength: float = 0.015
@export var box_size: float = 0.9
@export_color_no_alpha var ball_color: Color = Color(1.0, 0.4, 0.7)
@export_color_no_alpha var box_color: Color = Color(0.4, 0.7, 1.0, 0.5)

var _sim_root: Node3D
var _ball: MeshInstance3D
var _position: Vector3 = Vector3(0, 0.5, 0)
var _velocity: Vector3 = Vector3(0.12, 0.08, 0.1)
var _gravity: Vector3
var _bounds_min: Vector3
var _bounds_max: Vector3
var _trail_points: Array[Vector3] = []
var _trail_mesh: ImmediateMesh
var _trail_instance: MeshInstance3D
var _max_trail_length: int = 150

func _ready() -> void:
	var half := box_size / 2.0
	_bounds_min = Vector3(-half, 0.05, -half)
	_bounds_max = Vector3(half, box_size + 0.05, half)
	_gravity = Vector3(0, -gravity_strength, 0)
	_setup_environment()
	_spawn_ball()
	_create_wireframe_box()
	_setup_trail()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)

func _spawn_ball() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = ball_radius
	sphere.height = ball_radius * 2.0
	_ball.mesh = sphere
	var mat := StandardMaterial3D.new()
	mat.albedo_color = ball_color
	mat.emission_enabled = true
	mat.emission = ball_color * 0.5
	mat.emission_energy_multiplier = 1.5
	mat.metallic = 0.3
	mat.roughness = 0.4
	_ball.material_override = mat
	_sim_root.add_child(_ball)

func _create_wireframe_box() -> void:
	var edge_mat := StandardMaterial3D.new()
	edge_mat.albedo_color = Color(box_color, 0.5)
	edge_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	edge_mat.emission_enabled = true
	edge_mat.emission = box_color
	edge_mat.emission_energy_multiplier = 0.6
	edge_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

	var corners: Array[Vector3] = [
		_bounds_min,
		Vector3(_bounds_max.x, _bounds_min.y, _bounds_min.z),
		Vector3(_bounds_max.x, _bounds_min.y, _bounds_max.z),
		Vector3(_bounds_min.x, _bounds_min.y, _bounds_max.z),
		Vector3(_bounds_min.x, _bounds_max.y, _bounds_min.z),
		Vector3(_bounds_max.x, _bounds_max.y, _bounds_min.z),
		_bounds_max,
		Vector3(_bounds_min.x, _bounds_max.y, _bounds_max.z),
	]
	var edges := [
		[0,1],[1,2],[2,3],[3,0],
		[4,5],[5,6],[6,7],[7,4],
		[0,4],[1,5],[2,6],[3,7],
	]
	for i in range(edges.size()):
		var a: Vector3 = corners[edges[i][0]]
		var b: Vector3 = corners[edges[i][1]]
		var edge := MeshInstance3D.new()
		var cyl := CylinderMesh.new()
		cyl.top_radius = 0.005
		cyl.bottom_radius = 0.005
		cyl.height = a.distance_to(b)
		cyl.radial_segments = 4
		edge.mesh = cyl
		edge.material_override = edge_mat
		edge.position = (a + b) / 2.0
		var dir := (b - a).normalized()
		if dir.length() > 0.001:
			var up := Vector3.UP
			var right := dir.cross(up).normalized()
			if right.length() < 0.001:
				right = Vector3.RIGHT
				up = right.cross(dir).normalized()
			else:
				up = right.cross(dir).normalized()
			edge.transform.basis = Basis(right, dir, up)
		_sim_root.add_child(edge)

func _setup_trail() -> void:
	_trail_mesh = ImmediateMesh.new()
	_trail_instance = MeshInstance3D.new()
	_trail_instance.mesh = _trail_mesh
	_trail_instance.material_override = MAT_TRAIL
	_sim_root.add_child(_trail_instance)

func _process(_delta: float) -> void:
	_velocity += _gravity
	_position += _velocity

	if _position.x - ball_radius < _bounds_min.x or _position.x + ball_radius > _bounds_max.x:
		_velocity.x *= -elasticity
		_position.x = clamp(_position.x, _bounds_min.x + ball_radius, _bounds_max.x - ball_radius)

	if _position.y - ball_radius < _bounds_min.y or _position.y + ball_radius > _bounds_max.y:
		_velocity.y *= -elasticity
		_position.y = clamp(_position.y, _bounds_min.y + ball_radius, _bounds_max.y - ball_radius)

	if _position.z - ball_radius < _bounds_min.z or _position.z + ball_radius > _bounds_max.z:
		_velocity.z *= -elasticity
		_position.z = clamp(_position.z, _bounds_min.z + ball_radius, _bounds_max.z - ball_radius)

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
