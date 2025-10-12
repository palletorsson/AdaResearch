# ===========================================================================
# NOC Example 1.8: Exercise 1.8: Attraction Magnitude
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_ATTRACTOR := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_LINE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var attraction_strength: float = 0.5

var _sim_root: Node3D
var _ball: MeshInstance3D
var _attractor: MeshInstance3D
var _position: Vector3 = Vector3(-0.3, 0.7, 0.2)
var _velocity: Vector3 = Vector3(0.05, 0, 0.03)
var _attractor_position: Vector3 = Vector3(0, 0.5, 0)
var _ball_radius: float = 0.03
var _line_mesh: ImmediateMesh
var _line_instance: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_objects()
	_setup_line()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 20
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var strength_controller := CONTROLLER_SCENE.instantiate()
	strength_controller.parameter_name = "Strength"
	strength_controller.min_value = 0.0
	strength_controller.max_value = 1.5
	strength_controller.default_value = attraction_strength
	strength_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(strength_controller)
	strength_controller.value_changed.connect(func(v: float) -> void:
		attraction_strength = v
	)
	strength_controller.set_value(attraction_strength)

func _spawn_objects() -> void:
	_ball = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = _ball_radius
	sphere.height = _ball_radius * 2.0
	_ball.mesh = sphere
	_ball.material_override = MAT_BALL
	_sim_root.add_child(_ball)

	_attractor = MeshInstance3D.new()
	var attractor_sphere := SphereMesh.new()
	attractor_sphere.radius = 0.04
	attractor_sphere.height = 0.08
	_attractor.mesh = attractor_sphere
	_attractor.material_override = MAT_ATTRACTOR
	_attractor.position = _attractor_position
	_sim_root.add_child(_attractor)

func _setup_line() -> void:
	_line_mesh = ImmediateMesh.new()
	_line_instance = MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	_line_instance.material_override = MAT_LINE
	_sim_root.add_child(_line_instance)

func _process(delta: float) -> void:
	var to_attractor := _attractor_position - _position
	var distance := to_attractor.length()

	distance = clamp(distance, 0.05, 0.5)

	var force := to_attractor.normalized() * (attraction_strength / (distance * distance))
	_velocity += force
	_velocity = _velocity.limit_length(0.15)

	_position += _velocity
	_ball.position = _position

	_line_mesh.clear_surfaces()
	_line_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_line_mesh.surface_add_vertex(_position)
	_line_mesh.surface_add_vertex(_attractor_position)
	_line_mesh.surface_end()

	_status_label.text = "Attraction | dist: %.3f, force: %.4f" % [distance, force.length()]
