extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ROCKET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_OBSTACLE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45
const MIN_Z := -0.2
const MAX_Z := 0.2

@export var population_size: int = 120
@export var mutation_rate: float = 0.01
@export var lifespan: int = 300
@export var max_force: float = 0.07
@export var obstacle_gap_height: float = 0.18

var _sim_root: Node3D
var _rockets: Array[Rocket] = []
var _obstacles: Array[Obstacle] = []
var _target: Target
var _status_label: Label3D
var _generation: int = 1
var _step: int = 0
var _record_time: int

func _ready() -> void:
	_setup_environment()
	_spawn_target()
	_spawn_obstacles()
	_spawn_population()
	_record_time = lifespan
	_update_status(0.0)
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 22
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_create_controllers()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.15
	mutation_controller.default_value = mutation_rate
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = clamp(v, 0.0, 0.15)
	)
	mutation_controller.set_value(mutation_rate)

	var gap_controller := CONTROLLER_SCENE.instantiate()
	gap_controller.parameter_name = "Obstacle Gap"
	gap_controller.min_value = 0.1
	gap_controller.max_value = 0.3
	gap_controller.default_value = obstacle_gap_height
	gap_controller.position = Vector3(0, -0.18, 0)
	gap_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(gap_controller)
	gap_controller.value_changed.connect(func(v: float) -> void:
		obstacle_gap_height = v
		_update_obstacles()
	)
	gap_controller.set_value(obstacle_gap_height)

func _spawn_target() -> void:
	_target = Target.new()
	_target.init(_sim_root, MAT_TARGET, Vector3(0.38, 0.78, 0), 0.05)

func _spawn_obstacles() -> void:
	for obstacle in _obstacles:
		obstacle.queue_free()
	_obstacles.clear()

	var center := Vector3(0.0, 0.5, 0)
	var thickness := 0.04
	var height := obstacle_gap_height

	var upper := Obstacle.new()
	upper.init(_sim_root, center + Vector3(0, height * 0.5 + 0.08, 0), Vector3(0.4, 0.08, thickness), MAT_OBSTACLE)
	var lower := Obstacle.new()
	lower.init(_sim_root, center - Vector3(0, height * 0.5 + 0.08, 0), Vector3(0.4, 0.08, thickness), MAT_OBSTACLE)
	_obstacles.append(upper)
	_obstacles.append(lower)

func _update_obstacles() -> void:
	_spawn_obstacles()

func _spawn_population() -> void:
	for rocket in _rockets:
		rocket.queue_free()
	_rockets.clear()

	for i in range(population_size):
		var rocket := Rocket.new()
		rocket.init(_sim_root, MAT_ROCKET, lifespan, max_force)
		rocket.position = Vector3(-0.4, 0.2 + (float(i % 6) * 0.08), 0)
		_rockets.append(rocket)

	_step = 0

func _physics_process(delta: float) -> void:
	if _rockets.is_empty():
		return

	if _step >= lifespan:
		_next_generation()
		return

	var best_fit := 0.0
	var all_done := true

	for rocket in _rockets:
		rocket.apply_gene(_step)
		rocket.update(delta, _target.position, _obstacles)
		best_fit = max(best_fit, rocket.fitness)
		if not rocket.done:
			all_done = false

	if _target.contains(rocket_position_nearest()):
		_record_time = min(_record_time, _step)

	_step += 1
	_update_status(best_fit)

	if all_done:
		_next_generation()

func rocket_position_nearest() -> Vector3:
	var best := Vector3.ZERO
	var dist := INF
	for rocket in _rockets:
		var d := rocket.position.distance_to(_target.position)
		if d < dist:
			dist = d
			best = rocket.position
	return best

func _update_status(best_fit: float) -> void:
	_status_label.text = "Gen %d | Step %d/%d | Best %.2f" % [_generation, _step, lifespan, best_fit]

func _next_generation() -> void:
	var mating_pool: Array[Rocket] = []
	var max_fit := 0.0
	for rocket in _rockets:
		max_fit = max(max_fit, rocket.fitness)

	if max_fit <= 0.0:
		max_fit = 0.001

	for rocket in _rockets:
		var normalized := rocket.fitness / max_fit
		var count := int(normalized * 40.0)
		for j in range(count):
			mating_pool.append(rocket)

	if mating_pool.is_empty():
		mating_pool = _rockets.duplicate()

	for rocket in _rockets:
		rocket.queue_free()

	var new_generation: Array[Rocket] = []
	for i in range(population_size):
		var parent := mating_pool[randi() % mating_pool.size()]
		var child := Rocket.new()
		child.init(_sim_root, MAT_ROCKET, lifespan, max_force)
		child.position = Vector3(-0.4, 0.2 + (float(i % 6) * 0.08), 0)
		child.dna.copy_from(parent.dna)
		child.dna.mutate(mutation_rate)
		new_generation.append(child)

	_rockets = new_generation
	_generation += 1
	_step = 0
	_record_time = lifespan
	_update_status(0.0)

class Rocket:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var dna := DNA.new()
	var fitness: float = 0.0
	var done: bool = false
	var record_distance: float = 9999.0
	var finish_time: int = 0
	var max_force_limit: float = 0.06

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, material: Material, genome_length: int, max_force_value: float) -> void:
		root = Node3D.new()
		root.name = "Rocket"
		parent.add_child(root)
		root.global_position = Vector3(-0.4, 0.2, 0)

		body = MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.018
		capsule.height = 0.09
		body.mesh = capsule
		body.material_override = material
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

		max_force_limit = max_force_value
		dna.generate_random(genome_length, max_force_limit)
		record_distance = 9999.0
		finish_time = 0
		velocity = Vector3.ZERO
		acceleration = Vector3.ZERO
		done = false
		fitness = 0.0

	func apply_gene(step: int) -> void:
		if done:
			return
		acceleration += dna.get_force(step)

	func update(delta: float, target: Vector3, obstacles: Array[Obstacle]) -> void:
		if done:
			return

		velocity += acceleration
		velocity = velocity.limit_length(0.6)
		position += velocity * delta * 60.0
		position = Vector3(clamp(position.x, MIN_X, MAX_X), clamp(position.y, MIN_Y, MAX_Y), 0)
		acceleration = Vector3.ZERO

		var dist := position.distance_to(target)
		record_distance = min(record_distance, dist)
		finish_time += 1

		var bonus := 0.3 if done else 0.0
		fitness = pow(1.0 / max(record_distance, 0.001), 2) * 0.7 + bonus

		if dist < 0.07:
			done = true
			fitness += 1.0
			return

		for obstacle in obstacles:
			if obstacle.contains(position):
				done = true
				fitness *= 0.2
				return

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class DNA:
	var genes: Array[Vector3] = []

	func generate_random(length: int, max_force_value: float) -> void:
		genes.resize(length)
		for i in range(length):
			genes[i] = Vector3(randfn(0, max_force_value), randfn(0, max_force_value), 0)

	func get_force(step: int) -> Vector3:
		if step >= genes.size():
			return Vector3.ZERO
		return genes[step]

	func mutate(rate: float) -> void:
		for i in range(genes.size()):
			if randf() < rate:
				genes[i] += Vector3(randfn(0, genes[i].length()), randfn(0, genes[i].length()), 0)

	func copy_from(other: DNA) -> void:
		genes = other.genes.duplicate(true)

class Target:
	var root: Node3D
	var mesh: MeshInstance3D
	var radius: float

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, material: Material, pos: Vector3, rad: float) -> void:
		radius = rad
		root = Node3D.new()
		root.name = "Target"
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rad
		mesh.mesh = sphere
		mesh.material_override = material
		root.add_child(mesh)
		root.global_position = pos

	func contains(point: Vector3) -> bool:
		return root.global_position.distance_to(point) <= radius

class Obstacle:
	var root: Node3D
	var mesh: MeshInstance3D
	var half_extents: Vector3

	func init(parent: Node3D, center: Vector3, half_size: Vector3, material: Material) -> void:
		half_extents = half_size
		root = Node3D.new()
		root.name = "Obstacle"
		root.position = center
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = half_size * 2.0
		mesh.mesh = box
		mesh.material_override = material
		# Apply tint via material since MeshInstance3D.modulate is not available for 3D meshes
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.6, 0.9, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		root.add_child(mesh)

	func contains(point: Vector3) -> bool:
		var local := point - root.position
		return abs(local.x) <= half_extents.x and abs(local.y) <= half_extents.y and abs(local.z) <= half_extents.z

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
