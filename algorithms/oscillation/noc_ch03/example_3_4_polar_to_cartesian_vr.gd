# ===========================================================================
# NOC Example 3.4: Polar to Cartesian
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_PARTICLE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TRAIL := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var orbit_radius: float = 0.2
@export var angular_speed: float = 0.03

var _sim_root: Node3D
var _particle: MeshInstance3D
var _trail: MeshInstance3D
var _trail_points: Array[Vector3] = []
var _status_label: Label3D
var _controller_root: Node3D
var _angle: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_scene()
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

	var radius_controller := CONTROLLER_SCENE.instantiate()
	radius_controller.parameter_name = "Radius"
	radius_controller.min_value = 0.1
	radius_controller.max_value = 0.35
	radius_controller.default_value = orbit_radius
	radius_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(radius_controller)
	radius_controller.value_changed.connect(func(v: float) -> void:
		orbit_radius = v
		_trail_points.clear()
	)
	radius_controller.set_value(orbit_radius)

	var speed_controller := CONTROLLER_SCENE.instantiate()
	speed_controller.parameter_name = "Speed"
	speed_controller.min_value = 0.01
	speed_controller.max_value = 0.1
	speed_controller.default_value = angular_speed
	speed_controller.position = Vector3(0, -0.18, 0)
	speed_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(speed_controller)
	speed_controller.value_changed.connect(func(v: float) -> void:
		angular_speed = v
	)
	speed_controller.set_value(angular_speed)

func _spawn_scene() -> void:
	_particle = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.03
	_particle.mesh = sphere
	_particle.material_override = MAT_PARTICLE
	_sim_root.add_child(_particle)

	_trail = MeshInstance3D.new()
	_sim_root.add_child(_trail)

func _process(_delta: float) -> void:
	_angle += angular_speed

	var x := cos(_angle) * orbit_radius
	var y := sin(_angle) * orbit_radius
	var pos := Vector3(x, 0.5 + y, 0)

	_particle.position = pos
	_trail_points.append(pos)

	if _trail_points.size() > 200:
		_trail_points.pop_front()

	_update_trail()

	_status_label.text = "Polar to Cartesian | %.1f°" % rad_to_deg(fmod(_angle, TAU))

func _update_trail() -> void:
	if _trail_points.size() < 2:
		return

	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_LINE_STRIP)

	for i in range(_trail_points.size()):
		var alpha := float(i) / _trail_points.size()
		mesh.surface_set_color(Color(1.0, 0.7, 0.95, alpha * 0.5))
		mesh.surface_add_vertex(_trail_points[i])

	mesh.surface_end()
	_trail.mesh = mesh
