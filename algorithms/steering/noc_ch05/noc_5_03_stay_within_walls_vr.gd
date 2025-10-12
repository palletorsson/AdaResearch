# ===========================================================================
# NOC Example 5.03: Stay Within Walls
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var max_force: float = 0.08
@export var max_speed: float = 0.45
@export var lookahead: float = 0.35

var _sim_root: Node3D
var _vehicle: Vehicle
var _status_label: Label3D
var _controller_root: Node3D
var _walls: Array[Wall] = []

func _ready() -> void:
	_setup_environment()
	_spawn_vehicle_and_walls()
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

	var look_controller := CONTROLLER_SCENE.instantiate()
	look_controller.parameter_name = "Lookahead"
	look_controller.min_value = 0.1
	look_controller.max_value = 0.6
	look_controller.default_value = lookahead
	look_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(look_controller)
	look_controller.value_changed.connect(func(v: float) -> void:
		lookahead = v
		if _vehicle:
			_vehicle.lookahead = v
	)
	look_controller.set_value(lookahead)

func _spawn_vehicle_and_walls() -> void:
	_vehicle = Vehicle.new()
	_vehicle.init(_sim_root, MAT_AGENT)
	_vehicle.position = Vector3(0, 0.5, 0)
	_vehicle.velocity = Vector3(0.4, 0.1, 0)
	_vehicle.max_speed = max_speed
	_vehicle.max_force = max_force
	_vehicle.lookahead = lookahead

	_walls = []
	_walls.append(Wall.new(Vector3(-0.45, 0.05, 0), Vector3(0.45, 0.05, 0)))
	_walls.append(Wall.new(Vector3(-0.45, 0.95, 0), Vector3(0.45, 0.95, 0)))
	_walls.append(Wall.new(Vector3(-0.45, 0.05, 0), Vector3(-0.45, 0.95, 0)))
	_walls.append(Wall.new(Vector3(0.45, 0.05, 0), Vector3(0.45, 0.95, 0)))
	for wall in _walls: wall.add_to(_sim_root)

func _process(delta: float) -> void:
	_vehicle.stay_in_walls(_walls)
	_vehicle.update(delta)
	_status_label.text = "Stay Within Walls"

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.45
	var max_force: float = 0.08
	var lookahead: float = 0.3

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

	func stay_in_walls(walls: Array[Wall]) -> void:
		var future := position + velocity.normalized() * lookahead
		for wall in walls:
			var normal := wall.normal()
			var distance := wall.distance_to_point(future)
			if distance < 0.0:
				var steer := normal * max_force * 2.0
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

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class Wall:
	var start: Vector3
	var end: Vector3
	var mesh: MeshInstance3D

	func _init(a: Vector3, b: Vector3) -> void:
		start = a
		end = b

	func add_to(parent: Node3D) -> void:
		mesh = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3((end - start).length(), 0.01, 0.01)
		mesh.mesh = box
		mesh.material_override = MAT_AGENT
		var mid := (start + end) / 2.0
		mesh.position = mid
		var angle := atan2(end.y - start.y, end.x - start.x)
		mesh.rotation = Vector3(0, 0, angle)
		parent.add_child(mesh)

	func normal() -> Vector3:
		var dir := (end - start).normalized()
		return Vector3(-dir.y, dir.x, 0)

	func distance_to_point(point: Vector3) -> float:
		var dir := (end - start).normalized()
		var normal := Vector3(-dir.y, dir.x, 0)
		return (point - start).dot(normal)
