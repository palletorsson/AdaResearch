extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_SHIP := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var thrust_power: float = 0.02
@export var turn_speed: float = 0.05

var _sim_root: Node3D
var _ship: Spaceship
var _status_label: Label3D
var _controller_root: Node3D
var _thrust_input: float = 0.0
var _turn_input: float = 0.0

func _ready() -> void:
	_setup_environment()
	_spawn_ship()
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
	thrust_controller.max_value = 0.08
	thrust_controller.default_value = thrust_power
	thrust_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(thrust_controller)
	thrust_controller.value_changed.connect(func(v: float) -> void:
		thrust_power = v
	)
	thrust_controller.set_value(thrust_power)

	var turn_controller := CONTROLLER_SCENE.instantiate()
	turn_controller.parameter_name = "Turn Speed"
	turn_controller.min_value = 0.01
	turn_controller.max_value = 0.15
	turn_controller.default_value = turn_speed
	turn_controller.position = Vector3(0, -0.18, 0)
	turn_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(turn_controller)
	turn_controller.value_changed.connect(func(v: float) -> void:
		turn_speed = v
	)
	turn_controller.set_value(turn_speed)

func _spawn_ship() -> void:
	_ship = Spaceship.new()
	_ship.init(_sim_root, MAT_SHIP)
	_ship.position = Vector3(0, 0.5, 0)

func _process(delta: float) -> void:
	var t: float = Time.get_ticks_msec() / 1000.0
	_thrust_input = sin(t * 0.8)
	_turn_input = cos(t * 0.5)

	if _thrust_input > 0:
		_ship.thrust(thrust_power * _thrust_input)
	_ship.turn(turn_speed * _turn_input)

	_ship.update(delta)
	_ship.wrap_bounds()

	_status_label.text = "Asteroids Ship | Speed %.2f" % _ship.velocity.length()

class Spaceship:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var heading: float = 0.0
	var max_speed: float = 0.4

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Spaceship"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.04
		cone.bottom_radius = 0.04
		cone.height = 0.12
		body.mesh = cone
		body.material_override = mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func thrust(amount: float) -> void:
		var force := Vector3(cos(heading), sin(heading), 0) * amount
		apply_force(force)

	func turn(amount: float) -> void:
		heading += amount

	func apply_force(force: Vector3) -> void:
		acceleration += force

	func update(delta: float) -> void:
		velocity += acceleration
		velocity = velocity.limit_length(max_speed)
		velocity *= 0.99
		position += velocity * delta * 60.0
		acceleration = Vector3.ZERO
		root.rotation = Vector3(0, 0, heading)

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
