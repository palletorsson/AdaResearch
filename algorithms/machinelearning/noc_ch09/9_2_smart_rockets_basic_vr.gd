extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_ROCKET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_TARGET := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45

@export var population_size: int = 25
@export var mutation_rate: float = 0.01
@export var lifespan: int = 320
@export var max_force: float = 0.06

var _sim_root: Node3D
var _rockets: Array[Rocket] = []
var _target: MeshInstance3D
var _generation: int = 1
var _step: int = 0
var _status_label: Label3D

func _ready() -> void:
	_setup_environment()
	_spawn_target()
	_spawn_population()
	_update_status()
	set_physics_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.modulate = Color(1.0, 0.85, 1.0)
	_status_label.position = Vector3(0, 0.82, 0)
	_sim_root.add_child(_status_label)

	_create_controller()

func _create_controller() -> void:
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

func _spawn_target() -> void:
	_target = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.05
	_target.mesh = sphere
	_target.material_override = MAT_TARGET
	_target.position = Vector3(0.35, 0.75, 0)
	_sim_root.add_child(_target)

func _spawn_population() -> void:
	for rocket in _rockets:
		rocket.queue_free()
	_rockets.clear()

	for i in range(population_size):
		var rocket := Rocket.new()
		rocket.init(_sim_root, MAT_ROCKET, lifespan, max_force)
		rocket.position = Vector3(-0.4, 0.2 + (i % 5) * 0.06, 0)
		_rockets.append(rocket)

	_step = 0

func _physics_process(delta: float) -> void:
	if _rockets.is_empty():
		return

	if _step >= lifespan:
		_next_generation()
		return

	for rocket in _rockets:
		rocket.apply_gene(_step)
		rocket.update(delta, _target.position)

	_step += 1
	_update_status()

	var all_done := true
	for rocket in _rockets:
		if not rocket.done:
			all_done = false
			break
	if all_done:
		_next_generation()

func _update_status() -> void:
	var best := 0.0
	for rocket in _rockets:
		best = max(best, rocket.fitness)
	_status_label.text = "Gen %d | Step %d/%d | Best %.2f" % [_generation, _step, lifespan, best]

func _next_generation() -> void:
	var mating_pool: Array[Rocket] = []
	var max_fit := 0.0
	for rocket in _rockets:
		max_fit = max(max_fit, rocket.fitness)

	if max_fit <= 0.0:
		max_fit = 0.001

	for rocket in _rockets:
		var n := int((rocket.fitness / max_fit) * 40.0)
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
		child.init(_sim_root, MAT_ROCKET, lifespan, max_force)
		child.position = Vector3(-0.4, 0.2 + (i % 5) * 0.06, 0)
		child.dna.copy_from(parent.dna)
		child.dna.mutate(mutation_rate, max_force)
		new_generation.append(child)

	_rockets = new_generation
	_generation += 1
	_step = 0
	_update_status()

class Rocket:
	var root: Node3D
	var body: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var acceleration: Vector3 = Vector3.ZERO
	var dna := DNA.new()
	var fitness: float = 0.0
	var done: bool = false

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
		capsule.radius = 0.02
		capsule.height = 0.1
		body.mesh = capsule
		body.material_override = material
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

		dna.generate_random(genome_length, max_force_value)

	func apply_gene(step: int) -> void:
		if done:
			return
		acceleration += dna.get_force(step)

	func update(delta: float, target: Vector3) -> void:
		if done:
			return

		velocity += acceleration
		velocity = velocity.limit_length(0.6)
		root.position += velocity * delta * 60.0
		acceleration = Vector3.ZERO

		var dist := root.position.distance_to(target)
		fitness = max(0.0, 1.5 - dist * 3.0)
		if dist < 0.07:
			done = true
			fitness += 5.0

		if root.position.x < MIN_X or root.position.x > MAX_X or root.position.y < MIN_Y or root.position.y > MAX_Y:
			done = true

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
