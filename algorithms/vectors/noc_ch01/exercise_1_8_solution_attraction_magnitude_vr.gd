# ===========================================================================
# NOC Example 1.8: Exercise 1.8: Attraction Magnitude
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing -> GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================
#
# @identity
# essence: F = strength * dir / r^2. Inverse-square attraction. Closer = stronger. Orbit emerges from falling and missing.
# desire: To let the learner grab the attractor in VR and drag it — watching the orbiting ball reshape its path in real time.
# critical_parameter: attraction_strength — controls the force constant. Too weak → ball escapes. Too strong → ball spirals inward. The sweet spot produces stable orbits.
# triggers: VR grab attractor sphere → ball orbit changes shape, strength slider → orbits tighten or loosen, velocity clamped at 0.15 to prevent escape
# emerges: Elliptical orbits from the interplay of tangential velocity and radial attraction. Moving the attractor mid-orbit creates chaotic transitions between orbit shapes.
# needs: VR grabbable attractor [has], strength parameter controller [has], force line visualization [has]. Missing: trail showing orbit history.
# relationships: Extends bouncing_ball (adds attraction). Feeds into three_body_problem and nbody_simulation (many attractors). Gateway to gravitational dynamics.
# truth: An orbit is a perpetual fall that always misses the ground. Attraction creates structure from nothing but distance and direction.

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const GRAB_SPHERE_SCENE := preload("res://commons/primitives/math_gallery/GrabSphere.tscn")
const MAT_BALL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_ATTRACTOR := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_LINE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var attraction_strength: float = 0.5

var _sim_root: Node3D
var _ball: MeshInstance3D
var _attractor_grab: Node3D  # GrabSphere for VR interaction
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

	# Grabbable attractor sphere — move it in VR to redirect the orbiting ball
	_attractor_grab = GRAB_SPHERE_SCENE.instantiate()
	_attractor_grab.base_color = Color(1.0, 0.4, 0.7)
	_attractor_grab.object_scale = 0.08
	_attractor_grab.snap_to_shelf = false
	_attractor_grab.position = _attractor_position
	_sim_root.add_child(_attractor_grab)

func _setup_line() -> void:
	_line_mesh = ImmediateMesh.new()
	_line_instance = MeshInstance3D.new()
	_line_instance.mesh = _line_mesh
	_line_instance.material_override = MAT_LINE
	_sim_root.add_child(_line_instance)

func _process(_delta: float) -> void:
	# Track attractor position from the grabbable sphere (local to sim_root)
	if _attractor_grab:
		_attractor_position = _attractor_grab.position

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
