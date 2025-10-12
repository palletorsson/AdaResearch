# ===========================================================================
# NOC Example 3.2: Forces with Arbitrary Angular Motion
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ATTRACTOR := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_MOVER := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_movers: int = 8
@export var attractor_strength: float = 0.15
@export var angular_damping: float = 0.98

var _sim_root: Node3D
var _attractor: MeshInstance3D
var _movers: Array[AngularMover] = []
var _status_label: Label3D
var _controller_root: Node3D

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

	var strength_controller := CONTROLLER_SCENE.instantiate()
	strength_controller.parameter_name = "Attractor"
	strength_controller.min_value = 0.05
	strength_controller.max_value = 0.3
	strength_controller.default_value = attractor_strength
	strength_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(strength_controller)
	strength_controller.value_changed.connect(func(v: float) -> void:
		attractor_strength = v
	)
	strength_controller.set_value(attractor_strength)

	var damping_controller := CONTROLLER_SCENE.instantiate()
	damping_controller.parameter_name = "Damping"
	damping_controller.min_value = 0.9
	damping_controller.max_value = 0.999
	damping_controller.default_value = angular_damping
	damping_controller.position = Vector3(0, -0.18, 0)
	damping_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(damping_controller)
	damping_controller.value_changed.connect(func(v: float) -> void:
		angular_damping = v
	)
	damping_controller.set_value(angular_damping)

func _spawn_scene() -> void:
	_attractor = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	_attractor.mesh = sphere
	_attractor.material_override = MAT_ATTRACTOR
	_attractor.position = Vector3(0, 0.5, 0)
	_sim_root.add_child(_attractor)

	for i in num_movers:
		var m := AngularMover.new()
		m.init(_sim_root, MAT_MOVER)
		var angle := (float(i) / num_movers) * TAU
		var radius := randf_range(0.2, 0.35)
		m.position = Vector3(
			cos(angle) * radius,
			0.5 + randf_range(-0.1, 0.1),
			sin(angle) * radius
		)
		m.velocity = Vector3(
			-sin(angle) * 0.3,
			randf_range(-0.05, 0.05),
			cos(angle) * 0.3
		)
		_movers.append(m)

func _process(delta: float) -> void:
	for mover in _movers:
		var dir := (_attractor.position - mover.position).normalized()
		var force := dir * attractor_strength
		mover.apply_force(force)
		mover.angular_velocity *= angular_damping
		mover.update(delta)
		mover.wrap_bounds()

	_status_label.text = "Angular + Forces | %d movers" % _movers.size()

func _exit_tree() -> void:
	for m in _movers:
		m.queue_free()

class AngularMover:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var angular_velocity: float = 0.0
	var angle: float = 0.0
	var max_speed: float = 0.4

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Mover"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.06, 0.02, 0.02)
		body.mesh = box
		body.material_override = mat
		root.add_child(body)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		angular_velocity += randf_range(-0.01, 0.01)
		angle += angular_velocity
		root.rotation = Vector3(0, 0, angle)

	func wrap_bounds() -> void:
		var pos := position
		if pos.x < -0.45:
			pos.x = 0.45
		elif pos.x > 0.45:
			pos.x = -0.45
		if pos.y < 0.05:
			pos.y = 0.95
		elif pos.y > 0.95:
			pos.y = 0.05
		if pos.z < -0.45:
			pos.z = 0.45
		elif pos.z > 0.45:
			pos.z = -0.45
		position = pos

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
