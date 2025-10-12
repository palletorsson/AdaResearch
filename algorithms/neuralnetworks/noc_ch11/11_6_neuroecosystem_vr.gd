extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")
const MAT_CREATURE := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_primary.tres")
const MAT_CREATURE_ALPHA := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_accent.tres")
const MAT_FOOD := preload("res://commons/resourses/materials/noc_vr/noc_vr_pink_secondary.tres")

const MIN_Y := 0.05
const MAX_Y := 0.95
const MIN_X := -0.45
const MAX_X := 0.45
const MIN_Z := -0.45
const MAX_Z := 0.45

@export var population_size: int = 20
@export var mutation_rate: float = 0.05
@export var food_spawn_interval: float = 2.5
@export var food_radius: float = 0.06
@export var max_speed: float = 0.6

var _sim_root: Node3D
var _creatures: Array[EcoCreature] = []
var _foods: Array[FoodItem] = []
var _spawn_timer: float = 0.0
var _generation: int = 1
var _status_label: Label3D
var _alpha_energy: float = 0.0

func _ready() -> void:
	randomize()
	_setup_environment()
	_spawn_population()
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

	_create_controllers()
	_update_status()

func _create_controllers() -> void:
	var controller_root := Node3D.new()
	controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_rate = clamp(mutation_rate, 0.0, 0.3)
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.3
	mutation_controller.default_value = mutation_rate
	mutation_controller.position = Vector3(0, 0.1, 0)
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = v
	)
	mutation_controller.set_value(mutation_rate)

	var food_controller := CONTROLLER_SCENE.instantiate()
	food_controller.parameter_name = "Food Spawn"
	food_controller.min_value = 0.5
	food_controller.max_value = 4.0
	food_controller.default_value = food_spawn_interval
	food_controller.position = Vector3(0, -0.15, 0)
	food_controller.rotation_degrees = Vector3(0, 90, 0)
	controller_root.add_child(food_controller)
	food_controller.value_changed.connect(func(v: float) -> void:
		food_spawn_interval = v
	)
	food_controller.set_value(food_spawn_interval)

func _spawn_population() -> void:
	for creature in _creatures:
		creature.queue_free()
	_creatures.clear()

	for i in range(population_size):
		var creature := EcoCreature.new()
		creature.init(_sim_root, MAT_CREATURE, MAT_CREATURE_ALPHA)
		creature.position = Vector3(randf_range(MIN_X + 0.1, MAX_X - 0.1), randf_range(MIN_Y + 0.1, MAX_Y - 0.1), randf_range(MIN_Z + 0.1, MAX_Z - 0.1))
		_creatures.append(creature)

	_spawn_timer = food_spawn_interval

func _physics_process(delta: float) -> void:
	_spawn_timer -= delta
	if _spawn_timer <= 0.0:
		_spawn_food()
		_spawn_timer = food_spawn_interval

	var alive_count := 0
	for creature in _creatures:
		creature.update(delta, _foods, max_speed)
		if creature.energy > 0:
			alive_count += 1

	_update_foods(delta)
	_remove_consumed_food()

	if alive_count == 0:
		_next_generation()

	_update_status()

func _spawn_food() -> void:
	var food := FoodItem.new()
	food.init(_sim_root, MAT_FOOD, food_radius)
	food.position = Vector3(randf_range(MIN_X + 0.05, MAX_X - 0.05), randf_range(MIN_Y + 0.05, MAX_Y - 0.05), randf_range(MIN_Z + 0.05, MAX_Z - 0.05))
	_foods.append(food)

func _update_foods(delta: float) -> void:
	for food in _foods:
		food.pulse(delta)

func _remove_consumed_food() -> void:
	for food in _foods.duplicate():
		if food.consumed:
			food.queue_free()
			_foods.erase(food)

func _update_status() -> void:
	var alpha := _find_alpha()
	_alpha_energy = alpha.energy if alpha else 0.0
	var food_count := _foods.size()
	_status_label.text = "Gen %d | Creatures %d | Food %d | Alpha %.2f" % [_generation, _living_creatures(), food_count, _alpha_energy]

func _living_creatures() -> int:
	var count := 0
	for creature in _creatures:
		if creature.energy > 0:
			count += 1
	return count

func _find_alpha() -> EcoCreature:
	var best: EcoCreature = null
	var best_energy := -INF
	for creature in _creatures:
		if creature.energy > best_energy:
			best_energy = creature.energy
			best = creature
	return best

func _next_generation() -> void:
	var mating_pool: Array[EcoCreature] = []
	var best_energy := 0.0
	for creature in _creatures:
		best_energy = max(best_energy, creature.energy)

	if best_energy <= 0.0:
		best_energy = 0.001

	for creature in _creatures:
		var normalized: float = creature.energy / best_energy
		var copies := int(normalized * 20.0)
		for j in range(copies):
			mating_pool.append(creature)

	if mating_pool.is_empty():
		mating_pool = _creatures.duplicate()

	for creature in _creatures:
		creature.queue_free()
	_creatures.clear()

	for i in range(population_size):
		var parent := mating_pool[randi() % mating_pool.size()]
		var offspring := EcoCreature.new()
		offspring.init(_sim_root, MAT_CREATURE, MAT_CREATURE_ALPHA)
		offspring.position = Vector3(randf_range(MIN_X + 0.1, MAX_X - 0.1), randf_range(MIN_Y + 0.1, MAX_Y - 0.1), randf_range(MIN_Z + 0.1, MAX_Z - 0.1))
		offspring.brain.copy_from(parent.brain)
		offspring.brain.mutate(mutation_rate)
		_creatures.append(offspring)

	for food in _foods:
		food.queue_free()
	_foods.clear()
	_spawn_timer = food_spawn_interval
	_generation += 1

class EcoCreature:
	var root: Node3D
	var body: MeshInstance3D
	var halo: MeshInstance3D
	var velocity: Vector3 = Vector3.ZERO
	var energy: float = 5.0
	var brain := EcosystemBrain.new()

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, body_mat: Material, halo_mat: Material) -> void:
		root = Node3D.new()
		root.name = "Creature"
		parent.add_child(root)

		body = MeshInstance3D.new()
		var capsule := CapsuleMesh.new()
		capsule.radius = 0.045
		capsule.height = 0.12
		body.mesh = capsule
		body.material_override = body_mat
		body.rotation_degrees = Vector3(0, 0, -90)
		root.add_child(body)

		halo = MeshInstance3D.new()
		halo.mesh = capsule
		halo.material_override = halo_mat
		halo.visible = false
		halo.scale = Vector3(1.2, 1.2, 1.2)
		root.add_child(halo)

		brain.randomize()

	func update(delta: float, foods: Array[FoodItem], max_speed_value: float) -> void:
		if energy <= 0:
			if body.material_override is StandardMaterial3D:
				(body.material_override as StandardMaterial3D).albedo_color = Color(1, 1, 1, 0.1)
			return

		var desired := brain.seek_best_food(position, foods)
		velocity = velocity.lerp(desired, 0.1)
		velocity = velocity.limit_length(max_speed_value)
		position += velocity * delta * 60.0
		position = Vector3(
			clamp(position.x, MIN_X, MAX_X),
			clamp(position.y, MIN_Y, MAX_Y),
			clamp(position.z, MIN_Z, MAX_Z)
		)

		energy -= delta * 0.5
		if energy <= 0:
			energy = 0
			halo.visible = false
			return

		for food in foods:
			if food.consumed:
				continue
			if position.distance_to(food.position) < food.radius + 0.03:
				energy += food.energy
				food.mark_consumed()

		halo.visible = energy > 6.0

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

class EcosystemBrain:
	var weights: Array[float] = []

	func randomize() -> void:
		weights.resize(3)
		for i in range(weights.size()):
			weights[i] = randf_range(0.2, 1.0)

	func copy_from(other: EcosystemBrain) -> void:
		weights = other.weights.duplicate()

	func mutate(rate: float) -> void:
		for i in range(weights.size()):
			if randf() < rate:
				weights[i] = clamp(weights[i] + randfn(0, 0.2), 0.1, 1.5)

	func seek_best_food(position: Vector3, foods: Array[FoodItem]) -> Vector3:
		if foods.is_empty():
			return Vector3.ZERO

		var best_dir := Vector3.ZERO
		var best_score := -INF
		for food in foods:
			if food.consumed:
				continue
			var diff: Vector3 = food.position - position
			var dist: float = diff.length()
			var score: float = (weights[0] / max(dist, 0.001)) + weights[1] * food.energy - weights[2] * dist * 0.3
			if score > best_score:
				best_score = score
				best_dir = diff.normalized()
		return best_dir

class FoodItem:
	var root: Node3D
	var mesh: MeshInstance3D
	var radius: float = 0.06
	var energy: float = 2.0
	var consumed: bool = false
	var pulse_timer: float = 0.0

	var position: Vector3:
		get:
			return root.global_position
		set(value):
			root.global_position = value

	func init(parent: Node3D, material: Material, rad: float) -> void:
		radius = rad
		root = Node3D.new()
		root.name = "Food"
		parent.add_child(root)

		mesh = MeshInstance3D.new()
		var sphere := SphereMesh.new()
		sphere.radius = rad
		mesh.mesh = sphere
		var mat := StandardMaterial3D.new()
		mat.albedo_color = Color(1.0, 0.7, 0.95, 0.6)
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mesh.material_override = mat
		root.add_child(mesh)

	func pulse(delta: float) -> void:
		if consumed:
			return
		pulse_timer += delta
		var scale := 1.0 + 0.1 * sin(pulse_timer * 4.0)
		board_update(scale)

	func mark_consumed() -> void:
		consumed = true
		mesh.visible = false

	func queue_free() -> void:
		if is_instance_valid(root):
			root.queue_free()

	func board_update(scale: float) -> void:
		if mesh:
			mesh.scale = Vector3.ONE * scale
			if mesh.mesh is SphereMesh:
				(mesh.mesh as SphereMesh).radius = radius
