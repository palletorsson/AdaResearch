extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_PATH := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

@export var num_vehicles: int = 20
@export var path_radius: float = 0.1
@export var separation_weight: float = 2.0

var _sim_root: Node3D
var _vehicles: Array[Vehicle] = []
var _path := CrowdPath3D.new()
var _path_mesh: MeshInstance3D
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_path.generate()
	_spawn_vehicles()
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
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var radius_controller := CONTROLLER_SCENE.instantiate()
	radius_controller.parameter_name = "Path Radius"
	radius_controller.min_value = 0.05
	radius_controller.max_value = 0.2
	radius_controller.default_value = path_radius
	radius_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(radius_controller)
	radius_controller.value_changed.connect(func(v: float) -> void:
		path_radius = v
		for vehicle in _vehicles:
			vehicle.path_radius = v
		_update_path_mesh()
	)
	radius_controller.set_value(path_radius)

	var sep_controller := CONTROLLER_SCENE.instantiate()
	sep_controller.parameter_name = "Separation"
	sep_controller.min_value = 0.5
	sep_controller.max_value = 4.0
	sep_controller.default_value = separation_weight
	sep_controller.position = Vector3(0, -0.18, 0)
	sep_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(sep_controller)
	sep_controller.value_changed.connect(func(v: float) -> void:
		separation_weight = v
	)
	sep_controller.set_value(separation_weight)

	_update_path_mesh()

func _spawn_vehicles() -> void:
	for i in num_vehicles:
		var v := Vehicle.new()
		v.init(_sim_root, MAT_AGENT)
		v.position = Vector3(
			randf_range(-0.4, 0.4),
			randf_range(0.1, 0.9),
			0
		)
		v.velocity = Vector3(randf_range(-0.1, 0.2), randf_range(-0.1, 0.1), 0)
		v.max_speed = randf_range(0.2, 0.45)
		v.max_force = randf_range(0.03, 0.08)
		v.path_radius = path_radius
		_vehicles.append(v)

func _process(delta: float) -> void:
	for vehicle in _vehicles:
		vehicle.follow(_path)
		var sep := vehicle.separate(_vehicles) * separation_weight
		vehicle.apply_force(sep)
		vehicle.update(delta)
		vehicle.wrap_bounds()

	_status_label.text = "Crowd Path Following | %d vehicles" % _vehicles.size()

func _update_path_mesh() -> void:
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	var points := _path.points
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
	mesh.surface_end()
	_path_mesh.mesh = mesh

func _exit_tree() -> void:
	for v in _vehicles:
		v.queue_free()

class Vehicle:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.35
	var max_force: float = 0.06
	var path_radius: float = 0.1
	var desired_separation: float = 0.08

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
		cone.top_radius = 0.025
		cone.bottom_radius = 0.025
		cone.height = 0.09
		body.mesh = cone
		body.material_override = mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func follow(path: CrowdPath3D) -> void:
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

	func separate(vehicles: Array[Vehicle]) -> Vector3:
		var steer := Vector3.ZERO
		var count := 0
		for other in vehicles:
			if other == self:
				continue
			var d := position.distance_to(other.position)
			if d > 0 and d < desired_separation:
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

class CrowdPath3D:
	var points: Array[Vector3] = []

	func generate() -> void:
		points.clear()
		points.append(Vector3(-0.4, 0.3, 0))
		points.append(Vector3(-0.2, 0.2, 0))
		points.append(Vector3(0.1, 0.6, 0))
		points.append(Vector3(0.3, 0.7, 0))
		points.append(Vector3(0.4, 0.45, 0))

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
