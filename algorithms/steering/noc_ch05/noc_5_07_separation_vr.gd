# ===========================================================================
# NOC Example 5.07: Separation
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_vehicles: int = 20
@export var separation_weight: float = 2.0
@export var desired_separation: float = 0.12

var _sim_root: Node3D
var _vehicles: Array[Vehicle] = []
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_vehicles()
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

	var weight_controller := CONTROLLER_SCENE.instantiate()
	weight_controller.parameter_name = "Sep Weight"
	weight_controller.min_value = 0.5
	weight_controller.max_value = 5.0
	weight_controller.default_value = separation_weight
	weight_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(weight_controller)
	weight_controller.value_changed.connect(func(v: float) -> void:
		separation_weight = v
	)
	weight_controller.set_value(separation_weight)

	var distance_controller := CONTROLLER_SCENE.instantiate()
	distance_controller.parameter_name = "Sep Distance"
	distance_controller.min_value = 0.05
	distance_controller.max_value = 0.25
	distance_controller.default_value = desired_separation
	distance_controller.position = Vector3(0, -0.18, 0)
	distance_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(distance_controller)
	distance_controller.value_changed.connect(func(v: float) -> void:
		desired_separation = v
	)
	distance_controller.set_value(desired_separation)

func _spawn_vehicles() -> void:
	for i in num_vehicles:
		var v := Vehicle.new()
		v.init(_sim_root, MAT_AGENT)
		v.position = Vector3(
			randf_range(-0.4, 0.4),
			randf_range(0.1, 0.9),
			0
		)
		v.velocity = Vector3(randf_range(-0.2, 0.2), randf_range(-0.2, 0.2), 0)
		_vehicles.append(v)

func _process(delta: float) -> void:
	for vehicle in _vehicles:
		var sep := vehicle.separate(_vehicles, desired_separation)
		sep *= separation_weight
		vehicle.apply_force(sep)
		vehicle.update(delta)
		vehicle.wrap_bounds()

	_status_label.text = "Separation | %d vehicles" % _vehicles.size()

func _exit_tree() -> void:
	for v in _vehicles:
		v.queue_free()

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.3
	var max_force: float = 0.05

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
		cone.top_radius = 0.03
		cone.bottom_radius = 0.03
		cone.height = 0.1
		body.mesh = cone
		body.material_override = body_mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func separate(vehicles: Array[Vehicle], desired_sep: float) -> Vector3:
		var steer := Vector3.ZERO
		var count := 0

		for other in vehicles:
			if other == self:
				continue
			var d := position.distance_to(other.position)
			if d > 0 and d < desired_sep:
				var diff := position - other.position
				diff.z = 0
				diff = diff.normalized() / d
				steer += diff
				count += 1

		if count > 0:
			steer /= float(count)

		if steer.length() > 0:
			steer = steer.normalized() * max_speed
			steer -= velocity
			steer = steer.limit_length(max_force)

		return steer

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO
		if velocity.length() > 0.01:
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
