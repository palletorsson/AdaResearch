# ===========================================================================
# NOC Example 5.05: Path Following (Simple)
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_VEHICLE_A := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_VEHICLE_B := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_PATH := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

var _sim_root: Node3D
var _vehicle_a: Vehicle
var _vehicle_b: Vehicle
var _path := SimplePath3D.new()
var _path_mesh: MeshInstance3D
var _controller_root: Node3D
var _status_label: Label3D

@export var path_radius: float = 0.08

func _ready() -> void:
	_setup_environment()
	_path.generate()
	_spawn_scene()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	add_child(_sim_root)


	_path_mesh = MeshInstance3D.new()
	_sim_root.add_child(_path_mesh)

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
	radius_controller.parameter_name = "Path Radius"
	radius_controller.min_value = 0.04
	radius_controller.max_value = 0.2
	radius_controller.default_value = path_radius
	radius_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(radius_controller)
	radius_controller.value_changed.connect(func(v: float) -> void:
		path_radius = v
		if _vehicle_a:
			_vehicle_a.path_radius = v
		if _vehicle_b:
			_vehicle_b.path_radius = v
		_update_path_mesh()
	)
	radius_controller.set_value(path_radius)

	_update_status()

func _spawn_scene() -> void:
	_update_path_mesh()

	_vehicle_a = Vehicle.new()
	_vehicle_a.init(_sim_root, MAT_VEHICLE_A)
	_vehicle_a.position = Vector3(-0.4, 0.45, 0)
	_vehicle_a.max_speed = 0.35
	_vehicle_a.max_force = 0.05
	_vehicle_a.path_radius = path_radius

	_vehicle_b = Vehicle.new()
	_vehicle_b.init(_sim_root, MAT_VEHICLE_B)
	_vehicle_b.position = Vector3(-0.4, 0.55, 0)
	_vehicle_b.max_speed = 0.5
	_vehicle_b.max_force = 0.08
	_vehicle_b.path_radius = path_radius

func _process(delta: float) -> void:
	_vehicle_a.follow(_path)
	_vehicle_b.follow(_path)
	_vehicle_a.update(delta)
	_vehicle_b.update(delta)
	_vehicle_a.wrap_bounds()
	_vehicle_b.wrap_bounds()

	_status_label.text = "Path Following"

func _update_status() -> void:
	_status_label.text = "Path Following"

func _update_path_mesh() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := _path.points
	var has_vertices = false
	for i in range(points.size() - 1):
		var a := points[i]
		var b := points[i + 1]
		var dir := (b - a).normalized()
		var normal := Vector3(-dir.y, dir.x, 0)
		normal *= path_radius
		mesh.surface_set_color(Color(1.0, 0.7, 0.95, 0.3))
		mesh.surface_add_vertex(a + normal)
		mesh.surface_add_vertex(b + normal)
		mesh.surface_add_vertex(b - normal)
		mesh.surface_add_vertex(a - normal)
		has_vertices = true
	
	if has_vertices:
		mesh.surface_end()
		_path_mesh.mesh = mesh
	else:
		_path_mesh.mesh = null

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3(0.2, 0, 0)
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.4
	var max_force: float = 0.05
	var path_radius: float = 0.08

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Vehicle"
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

	func follow(path: SimplePath3D) -> void:
		var predict := velocity.normalized() * 0.25
		var predict_pos := position + predict
		var target := path.closest_point(predict_pos)
		if predict_pos.distance_to(target) > path_radius:
			seek(target)

	func seek(target: Vector3) -> void:
		var desired := target - position
		if desired.length() > 0:
			desired = desired.normalized() * max_speed
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
			position = Vector3(0.45, pos.y, pos.z)
		elif pos.x > 0.45:
			position = Vector3(-0.45, pos.y, pos.z)
		if pos.y < 0.05:
			position = Vector3(pos.x, 0.95, pos.z)
		elif pos.y > 0.95:
			position = Vector3(pos.x, 0.05, pos.z)

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class SimplePath3D:
	var points: Array[Vector3] = []

	func generate() -> void:
		points.clear()
		points.append(Vector3(-0.45, 0.4, 0))
		points.append(Vector3(-0.15, 0.2, 0))
		points.append(Vector3(0.15, 0.7, 0))
		points.append(Vector3(0.45, 0.55, 0))

	func closest_point(pos: Vector3) -> Vector3:
		var closest := points[0]
		var record := INF
		for i in range(points.size() - 1):
			var a := points[i]
			var b := points[i + 1]
			var normal_point := _get_normal_point(pos, a, b)
			var dist := pos.distance_to(normal_point)
			if dist < record:
				record = dist
				closest = normal_point
		return closest

	func _get_normal_point(p: Vector3, a: Vector3, b: Vector3) -> Vector3:
		var ap := p - a
		var ab := b - a
		ab = ab.normalized()
		ab *= ap.dot(ab)
		var normal_point := a + ab
		normal_point.x = clamp(normal_point.x, min(a.x, b.x), max(a.x, b.x))
		normal_point.y = clamp(normal_point.y, min(a.y, b.y), max(a.y, b.y))
		return normal_point
