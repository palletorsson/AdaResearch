extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_CIRCLE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var wander_radius: float = 0.08
@export var wander_distance: float = 0.15
@export var wander_change: float = 0.3

var _sim_root: Node3D
var _vehicle: Vehicle
var _wander_circle: MeshInstance3D
var _target_dot: MeshInstance3D
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
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var radius_controller := CONTROLLER_SCENE.instantiate()
	radius_controller.parameter_name = "Wander Radius"
	radius_controller.min_value = 0.03
	radius_controller.max_value = 0.15
	radius_controller.default_value = wander_radius
	radius_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(radius_controller)
	radius_controller.value_changed.connect(func(v: float) -> void:
		wander_radius = v
		if _vehicle:
			_vehicle.wander_radius = v
	)
	radius_controller.set_value(wander_radius)

	var distance_controller := CONTROLLER_SCENE.instantiate()
	distance_controller.parameter_name = "Wander Dist"
	distance_controller.min_value = 0.05
	distance_controller.max_value = 0.3
	distance_controller.default_value = wander_distance
	distance_controller.position = Vector3(0, -0.18, 0)
	distance_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(distance_controller)
	distance_controller.value_changed.connect(func(v: float) -> void:
		wander_distance = v
		if _vehicle:
			_vehicle.wander_distance = v
	)
	distance_controller.set_value(wander_distance)

	var change_controller := CONTROLLER_SCENE.instantiate()
	change_controller.parameter_name = "Wander Change"
	change_controller.min_value = 0.05
	change_controller.max_value = 1.0
	change_controller.default_value = wander_change
	change_controller.position = Vector3(0, -0.36, 0)
	change_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(change_controller)
	change_controller.value_changed.connect(func(v: float) -> void:
		wander_change = v
		if _vehicle:
			_vehicle.wander_change = v
	)
	change_controller.set_value(wander_change)

func _spawn_scene() -> void:
	_vehicle = Vehicle.new()
	_vehicle.init(_sim_root, MAT_AGENT)
	_vehicle.position = Vector3(0, 0.5, 0)
	_vehicle.velocity = Vector3(0.2, 0, 0)
	_vehicle.wander_radius = wander_radius
	_vehicle.wander_distance = wander_distance
	_vehicle.wander_change = wander_change

	_wander_circle = MeshInstance3D.new()
	var torus: TorusMesh = TorusMesh.new()
	torus.inner_radius = 0.001
	torus.outer_radius = wander_radius
	torus.rings = 16
	torus.ring_segments = 16
	_wander_circle.mesh = torus
	_wander_circle.material_override = MAT_CIRCLE
	_sim_root.add_child(_wander_circle)

	_target_dot = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.015
	_target_dot.mesh = sphere
	_target_dot.material_override = MAT_AGENT
	_sim_root.add_child(_target_dot)

func _process(delta: float) -> void:
	var wander_info := _vehicle.wander()
	_vehicle.update(delta)
	_vehicle.wrap_bounds()

	_wander_circle.position = wander_info.circle_center
	_target_dot.position = wander_info.target

	_status_label.text = "Wander | Speed %.2f" % _vehicle.velocity.length()

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.3
	var max_force: float = 0.05
	var wander_theta: float = 0.0
	var wander_radius: float = 0.08
	var wander_distance: float = 0.15
	var wander_change: float = 0.3

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
		cone.top_radius = 0.04
		cone.bottom_radius = 0.04
		cone.height = 0.12
		body.mesh = cone
		body.material_override = body_mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func wander() -> Dictionary:
		wander_theta += randf_range(-wander_change, wander_change)

		var circle_center := velocity.normalized() * wander_distance
		var circle_offset := Vector3(
			cos(wander_theta) * wander_radius,
			sin(wander_theta) * wander_radius,
			0
		)
		var target := circle_center + circle_offset

		var steer := target.normalized() * max_force
		apply_force(steer)

		return {
			"circle_center": position + circle_center,
			"target": position + target
		}

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
