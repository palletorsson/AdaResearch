# ===========================================================================
# NOC Example 5.9: Flocking
# Original: Daniel Shiffman (Processing) - https://natureofcode.com
# Translation: AI-assisted Processing → GDScript, 2025
#
# This is a translation adapted for VR where the original algorithm and logic are maintained.
# License: CC BY-NC-SA 3.0 (derivative of CC BY-NC 3.0 original)
# ===========================================================================

extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_AGENT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")

@export var num_boids: int = 30
@export var alignment_weight: float = 1.0
@export var cohesion_weight: float = 1.0
@export var separation_weight: float = 1.5

var _sim_root: Node3D
var _flock: Flock
var _status_label: Label3D
var _controller_root: Node3D

func _ready() -> void:
	_setup_environment()
	_spawn_flock()
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

	var align_controller := CONTROLLER_SCENE.instantiate()
	align_controller.parameter_name = "Alignment"
	align_controller.min_value = 0.0
	align_controller.max_value = 3.0
	align_controller.default_value = alignment_weight
	align_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(align_controller)
	align_controller.value_changed.connect(func(v: float) -> void:
		alignment_weight = v
	)
	align_controller.set_value(alignment_weight)

	var cohesion_controller := CONTROLLER_SCENE.instantiate()
	cohesion_controller.parameter_name = "Cohesion"
	cohesion_controller.min_value = 0.0
	cohesion_controller.max_value = 3.0
	cohesion_controller.default_value = cohesion_weight
	cohesion_controller.position = Vector3(0, -0.18, 0)
	cohesion_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(cohesion_controller)
	cohesion_controller.value_changed.connect(func(v: float) -> void:
		cohesion_weight = v
	)
	cohesion_controller.set_value(cohesion_weight)

	var separation_controller := CONTROLLER_SCENE.instantiate()
	separation_controller.parameter_name = "Separation"
	separation_controller.min_value = 0.0
	separation_controller.max_value = 3.0
	separation_controller.default_value = separation_weight
	separation_controller.position = Vector3(0, -0.36, 0)
	separation_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(separation_controller)
	separation_controller.value_changed.connect(func(v: float) -> void:
		separation_weight = v
	)
	separation_controller.set_value(separation_weight)

func _spawn_flock() -> void:
	_flock = Flock.new(_sim_root, MAT_AGENT, num_boids)

func _process(delta: float) -> void:
	_flock.run(delta, alignment_weight, cohesion_weight, separation_weight)
	_status_label.text = "Flocking | %d boids" % _flock.boids.size()

func _exit_tree() -> void:
	if _flock:
		_flock.queue_free()

class Flock:
	var boids: Array[FlockingBoid] = []

	func _init(parent: Node3D, mat: Material, count: int) -> void:
		for i in count:
			var b := FlockingBoid.new()
			b.init(parent, mat)
			b.position = Vector3(
				randf_range(-0.4, 0.4),
				randf_range(0.1, 0.9),
				0
			)
			b.velocity = Vector3(randf_range(-0.1, 0.1), randf_range(-0.1, 0.1), 0)
			boids.append(b)

	func run(delta: float, align_w: float, cohesion_w: float, sep_w: float) -> void:
		for boid in boids:
			boid.flock(boids, align_w, cohesion_w, sep_w)
			boid.update(delta)
			boid.wrap_bounds()

	func queue_free() -> void:
		for b in boids:
			b.queue_free()

class FlockingBoid:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var max_speed: float = 0.25
	var max_force: float = 0.04
	var neighbor_dist: float = 0.15
	var desired_separation: float = 0.08

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, mat: Material) -> void:
		root = Node3D.new()
		root.name = "Boid"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var cone := CylinderMesh.new()
		cone.top_radius = 0.025
		cone.bottom_radius = 0.025
		cone.height = 0.08
		body.mesh = cone
		body.material_override = mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

	func flock(boids: Array[FlockingBoid], align_w: float, cohesion_w: float, sep_w: float) -> void:
		var sep := separate(boids) * sep_w
		var ali := align(boids) * align_w
		var coh := cohesion(boids) * cohesion_w
		apply_force(sep)
		apply_force(ali)
		apply_force(coh)

	func separate(boids: Array[FlockingBoid]) -> Vector3:
		var steer := Vector3.ZERO
		var count := 0
		for other in boids:
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

	func align(boids: Array[FlockingBoid]) -> Vector3:
		var sum := Vector3.ZERO
		var count := 0
		for other in boids:
			if other == self:
				continue
			var d := position.distance_to(other.position)
			if d > 0 and d < neighbor_dist:
				sum += other.velocity
				count += 1

		if count > 0:
			sum /= float(count)
			sum = sum.normalized() * max_speed
			var steer := sum - velocity
			steer = steer.limit_length(max_force)
			return steer

		return Vector3.ZERO

	func cohesion(boids: Array[FlockingBoid]) -> Vector3:
		var sum := Vector3.ZERO
		var count := 0
		for other in boids:
			if other == self:
				continue
			var d := position.distance_to(other.position)
			if d > 0 and d < neighbor_dist:
				sum += other.position
				count += 1

		if count > 0:
			sum /= float(count)
			return seek(sum)

		return Vector3.ZERO

	func seek(target: Vector3) -> Vector3:
		var desired := target - position
		desired.z = 0
		if desired.length() > 0:
			desired = desired.normalized() * max_speed
		var steer := desired - velocity
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
