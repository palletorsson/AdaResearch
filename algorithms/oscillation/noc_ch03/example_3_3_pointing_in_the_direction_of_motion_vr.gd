# ===========================================================================
# NOC Example 3.3: Pointing in the Direction of Motion
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_MOVER := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var thrust_magnitude: float = 0.05

var _sim_root: Node3D
var _mover: DirectionalMover
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_mover()
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

	var thrust_controller := CONTROLLER_SCENE.instantiate()
	thrust_controller.parameter_name = "Thrust"
	thrust_controller.min_value = 0.01
	thrust_controller.max_value = 0.15
	thrust_controller.default_value = thrust_magnitude
	thrust_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(thrust_controller)
	thrust_controller.value_changed.connect(func(v: float) -> void:
		thrust_magnitude = v
	)
	thrust_controller.set_value(thrust_magnitude)

func _spawn_mover() -> void:
	_mover = DirectionalMover.new()
	_mover.init(_sim_root, MAT_MOVER)
	_mover.position = Vector3(0, 0.5, 0)
	_mover.velocity = Vector3(0.2, 0.1, 0)

func _process(delta: float) -> void:
	var t := Time.get_ticks_msec() / 1000.0
	var thrust_dir := Vector3(sin(t * 0.6), cos(t * 0.8), sin(t * 0.4))
	thrust_dir = thrust_dir.normalized()
	var thrust := thrust_dir * thrust_magnitude

	_mover.apply_force(thrust)
	_mover.update(delta)
	_mover.wrap_bounds()

	_status_label.text = "Pointing | Speed %.2f" % _mover.velocity.length()

class DirectionalMover:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.5

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
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0  # Makes it a cone
		cone.bottom_radius = 0.04
		cone.height = 0.14
		body.mesh = cone
		body.material_override = mat
		root.add_child(body)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		if velocity.length() > 0.01:
			root.look_at(position + velocity, Vector3.UP)
			root.rotate_object_local(Vector3.RIGHT, -PI / 2)

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
