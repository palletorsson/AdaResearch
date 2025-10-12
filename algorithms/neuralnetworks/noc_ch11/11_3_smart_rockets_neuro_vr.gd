extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ROCKET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_ROCKET_HIGHLIGHT := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_OBSTACLE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45

@export var population_size: int = 24
@export var mutation_rate: float = 0.02
@export var lifespan: int = 420
@export var max_force: float = 0.08
@export var obstacle_height: float = 0.18
@export var target_radius: float = 0.05

var _sim_root: Node3D
var _target: MeshInstance3D
var _obstacles: Array[Obstacle] = []
var _rockets: Array[Rocket] = []
var _step: int = 0
var _generation: int = 1
var _status_label: Label3D

func _ready() -> void:
	randomize()
	_setup_environment()
	_spawn_target()
	_spawn_obstacles()
	_spawn_population()
	_update_status()
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.modulate = Color(1.0, 0.8, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_status_label.text = ""
	_sim_root.add_child(_status_label)

	_create_controllers()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.name = "Controllers"
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.2
	mutation_controller.default_value = mutation_rate
	mutation_controller.position = Vector3(0, 0.1, 0)
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = v
	)
	mutation_controller.set_value(mutation_rate)

	var obstacle_controller := CONTROLLER_SCENE.instantiate()
	obstacle_controller.parameter_name = "Obstacle Height"
	obstacle_controller.min_value = 0.05
	obstacle_controller.max_value = 0.35
	obstacle_controller.default_value = obstacle_height
	obstacle_controller.position = Vector3(0, -0.15, 0)
	obstacle_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(obstacle_controller)
	obstacle_controller.value_changed.connect(func(v: float) -> void:
		obstacle_height = v
		_refresh_obstacles()
	)
	obstacle_controller.set_value(obstacle_height)

func _spawn_target() -> void:
	_target = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = target_radius
	_target.mesh = sphere
	_target.material_override = MAT_TARGET
	_target.position = Vector3(0.35, 0.75, 0)
	_sim_root.add_child(_target)

func _spawn_obstacles() -> void:
	for obstacle in _obstacles:
		obstacle.queue_free()
	_obstacles.clear()

	var centers := [Vector3(0.0, 0.45, 0.0), Vector3(0.25, 0.25, 0.0)]
	for center in centers:
		var obstacle := Obstacle.new()
		obstacle.init(_sim_root, center, Vector3(0.4, obstacle_height, 0.3), MAT_OBSTACLE)
		_obstacles.append(obstacle)

func _refresh_obstacles() -> void:
	for obstacle in _obstacles:
		obstacle.resize(Vector3(obstacle.size.x, obstacle_height, obstacle.size.z))

func _spawn_population() -> void:
	for rocket in _rockets:
		rocket.queue_free()
	_rockets.clear()

	for i in range(population_size):
		var rocket := Rocket.new()
		rocket.init(_sim_root, MAT_ROCKET, MAT_ROCKET_HIGHLIGHT, lifespan, max_force)
		rocket.position = Vector3(-0.4, 0.15 + float(i % 4) * 0.05, 0)
		_rockets.append(rocket)

func _physics_process(delta: float) -> void:
	if _rockets.is_empty():
		return

	if _step >= lifespan:
		_next_generation()
		return

	for rocket in _rockets:
		rocket.apply_gene(_step)
		rocket.update(delta, _target.position, _obstacles)

	_step += 1

	var all_done := true
	var best_fit := 0.0
	for rocket in _rockets:
		best_fit = max(best_fit, rocket.fitness)
		if not (rocket.done or rocket.crashed):
			all_done = false

	_highlight_best(best_fit)
	_update_status(best_fit)

	if all_done:
		_next_generation()

func _highlight_best(best_fit: float) -> void:
	var threshold := best_fit * 0.98
	for rocket in _rockets:
		rocket.set_highlight(best_fit > 0.0 and rocket.fitness >= threshold and rocket.done)

func _update_status(best_fit: float = 0.0) -> void:
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
		var n := int(normalized * 50.0)
		for j in range(n):
			mating_pool.append(rocket)

	if mating_pool.is_empty():
		mating_pool = _rockets.duplicate()

	var new_generation: Array[Rocket] = []
	for rocket in _rockets:
		rocket.queue_free()

	for i in range(population_size):
		var parent := mating_pool[randi() % mating_pool.size()]
		var child := Rocket.new()
		child.init(_sim_root, MAT_ROCKET, MAT_ROCKET_HIGHLIGHT, lifespan, max_force)
		child.position = Vector3(-0.4, 0.15 + float(i % 4) * 0.05, 0)
		child.dna.copy_from(parent.dna)
		child.dna.mutate(mutation_rate, max_force)
		new_generation.append(child)

	_rockets = new_generation
	_generation += 1
	_step = 0
	_update_status()

class Rocket:
	var root: Node3D
	var mesh: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var done: bool = false
	var crashed: bool = false
	var dna := DNA.new()
	var max_force_limit: float = 0.08
	var fitness: float = 0.0
	var highlight_mesh: MeshInstance3D

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_material: Material, highlight_material: Material, genome_length: int, max_force_value: float) -> void:
		root = Node3D.new()
		root.name = "Rocket"
		parent.add_child(root)
		root.global_position = Vector3(-0.4, 0.25, 0)

		mesh = MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.02
		capsule.height = 0.1
		mesh.mesh = capsule
		mesh.material_override = body_material
		mesh.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(mesh)

		highlight_mesh = MeshInstance3D.new()
		highlight_mesh.mesh = capsule
		highlight_mesh.material_override = highlight_material
		highlight_mesh.visible = false
		highlight_mesh.scale = Vector3(1.15, 1.15, 1.15)
		root.add_child(highlight_mesh)

		max_force_limit = max_force_value
		dna.generate_random(genome_length, max_force_limit)

	func apply_gene(step: int) -> void:
		if done or crashed:
			return
		acceleration += dna.get_force(step)

	func update(delta: float, target: Vector3, obstacles: Array[Obstacle]) -> void:
		if done or crashed:
			return

		velocity += acceleration
		velocity = velocity.limit_length(0.6)
		root.position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		var dist := root.position.distance_to(target)
		fitness += max(0.0, 1.5 - dist * 3.0) * delta

		if dist < target_radius * 1.5:
			done = true
			fitness += 10.0

		if root.position.x < MIN_X or root.position.x > MAX_X or root.position.y < MIN_Y or root.position.y > MAX_Y:
			crashed = true
			return

		for obstacle in obstacles:
			if obstacle.contains_point(root.position):
				crashed = true
				return

	func set_highlight(active: bool) -> void:
		highlight_mesh.visible = active

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

	func mutate(rate: float, max_force_value: float) -> void:
		for i in range(genes.size()):
			if randf() < rate:
				genes[i] += Vector3(randfn(0, max_force_value), randfn(0, max_force_value), 0)
				genes[i] = genes[i].limit_length(max_force_value)

	func copy_from(other: DNA) -> void:
		genes = other.genes.duplicate(true)

class Obstacle:
	var root: Node3D
	var mesh: MeshInstance3D
	var size: Vector3

	func init(parent: Node3D, center: Vector3, half_extents: Vector3, material: Material) -> void:
		size = half_extents
		root = Node3D.new()
		root.name = "Obstacle"
		root.position = center
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = half_extents * 2.0
		mesh.mesh = box
		mesh.material_override = material
		root.add_child(mesh)

	func resize(new_half_extents: Vector3) -> void:
		size = new_half_extents
		if mesh and mesh.mesh is BoxMesh:
			(mesh.mesh as BoxMesh).size = new_half_extents * 2.0

	func contains_point(point: Vector3) -> bool:
		var local := point - root.position
		return abs(local.x) <= size.x and abs(local.y) <= size.y and abs(local.z) <= size.z

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()
