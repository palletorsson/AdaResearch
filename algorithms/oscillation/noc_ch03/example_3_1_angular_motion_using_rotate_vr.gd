# ===========================================================================
# NOC Example 3.1: Angular Motion Using Rotate
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_BEAM := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var angular_velocity: float = 0.02

var _sim_root: Node3D
var _beam: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D
var _angle: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_beam()
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

	var velocity_controller := CONTROLLER_SCENE.instantiate()
	velocity_controller.parameter_name = "Angular Vel"
	velocity_controller.min_value = -0.1
	velocity_controller.max_value = 0.1
	velocity_controller.default_value = angular_velocity
	velocity_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(velocity_controller)
	velocity_controller.value_changed.connect(func(v: float) -> void:
		angular_velocity = v
	)
	velocity_controller.set_value(angular_velocity)

func _spawn_beam() -> void:
	_beam = MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(0.4, 0.02, 0.02)
	_beam.mesh = box
	_beam.material_override = MAT_BEAM
	_beam.position = Vector3(0, 0.5, 0)
	_sim_root.add_child(_beam)

func _process(_delta: float) -> void:
	_angle += angular_velocity
	_beam.rotation = Vector3(0, 0, _angle)

	var deg := rad_to_deg(fmod(_angle, TAU))
	_status_label.text = "Angular Motion | %.1f°" % deg
