# ===========================================================================
# NOC Example 5.02: Arrive
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_RADIUS := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var max_force: float = 0.08
@export var max_speed: float = 0.45
@export var slow_radius: float = 0.25

var _sim_root: Node3D
var _vehicle: Vehicle
var _target: MeshInstance3D
var _radius_ring: MeshInstance3D
var _status_label: Label3D

func _ready() -> void:
	_setup_environment()
	_spawn_vehicle_and_target()
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

	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var force_controller := CONTROLLER_SCENE.instantiate()
	force_controller.parameter_name = "Max Force"
	force_controller.min_value = 0.02
	force_controller.max_value = 0.2
	force_controller.default_value = max_force
	force_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(force_controller)
	force_controller.value_changed.connect(func(v: float) -> void:
		max_force = v
		if _vehicle:
			_vehicle.max_force = v
	)
	force_controller.set_value(max_force)

	var radius_controller := CONTROLLER_SCENE.instantiate()
	radius_controller.parameter_name = "Slow Radius"
	radius_controller.min_value = 0.1
	radius_controller.max_value = 0.4
	radius_controller.default_value = slow_radius
	radius_controller.position = Vector3(0, -0.18, 0)
	radius_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(radius_controller)
	radius_controller.value_changed.connect(func(v: float) -> void:
		slow_radius = v
		_update_radius_ring()
	)
	radius_controller.set_value(slow_radius)

func _spawn_vehicle_and_target() -> void:
	_vehicle = Vehicle.new()
	_vehicle.init(_sim_root, MAT_AGENT)
	_vehicle.position = Vector3(-0.3, 0.5, 0)
	_vehicle.max_force = max_force
	_vehicle.max_speed = max_speed
	_vehicle.slow_radius = slow_radius

	_target = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.06
	_target.mesh = sphere
	_target.material_override = MAT_TARGET
	_target.position = Vector3(0.35, 0.65, 0)
	_sim_root.add_child(_target)

	_radius_ring = MeshInstance3D.new()
	_sim_root.add_child(_radius_ring)
	_update_radius_ring()

func _update_radius_ring() -> void:
	if _vehicle:
		_vehicle.slow_radius = slow_radius
	if not _radius_ring:
		return
	var torus := TorusMesh.new()
	torus.inner_radius = slow_radius * 0.95
	torus.outer_radius = slow_radius
	_radius_ring.mesh = torus
	_radius_ring.material_override = MAT_RADIUS
	_radius_ring.position = _target.position

func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	_target.position = Vector3(0.35, 0.6 + 0.1 * sin(t * 0.6), 0.1 * sin(t * 0.4))
	_radius_ring.position = _target.position

	_vehicle.arrive(_target.position)
	_vehicle.update(delta)
	_vehicle.wrap_bounds()

	_status_label.text = "Arrive | Speed %.2f" % _vehicle.velocity.length()

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.45
	var max_force: float = 0.08
	var slow_radius: float = 0.25

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_mat: Material) -> void:
		root = Node3D.new()
		root.name = "Vehicle"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.05
		cone.bottom_radius = 0.05
		cone.height = 0.16
		body.mesh = cone
		body.material_override = body_mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func arrive(target: Vector3) -> void:
		var desired := target - position
		desired.z = 0
		var distance := desired.length()
		if distance > 0:
			desired = desired.normalized()
			var speed := max_speed
			if distance < slow_radius:
				speed = lerp(0.1, max_speed, distance / slow_radius)
			desired *= speed
		var steer := desired - velocity
		steer = steer.limit_length(max_force)
		apply_force(steer)

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO
		var angle := atan2(velocity.y, velocity.x)
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
		position = pos

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
