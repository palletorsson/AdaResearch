extends Node2D

# @identity
# essence: population(t+1) = reproduce(survive(eat(move(population(t))))) with DNA crossover and mutation at each birth — evolution in a closed box
# desire: to watch a predator-prey cycle spike and crash and recover — to feel the ecosystem breathe and realize no agent understands the cycle, only you can see it
# critical_parameter: mutation_rate — at 0 the ecosystem either freezes in its starting configuration or collapses; at 0.1 adaptation keeps prey one step ahead of predators indefinitely
# triggers: balance_ecosystem() acts as a hidden stabilizer that respawns prey below 10 and weakens predators when they outnumber prey by 2:1 — remove it and the system collapses in minutes
# emerges: prey develop faster flee_weight and higher perception_radius over generations without explicit selection pressure — predation IS the selection pressure
# needs: [missing] no VR controls at all; prey_population, predator_population, and mutation_rate are hardcoded; learner cannot experiment with initial conditions
# relationships: synthesis artifact for the swarmintelligence sequence; combines local movement rules from boids with genetic memory from neuroevolution; previews machinelearning sequence's evolutionary algorithms
# truth: evolution has no goal — only the dead are wrong, and only the living get to try again

## Ecosystem simulation — 3D VR version.
## Prey, predators, and food rendered via MultiMeshInstance3D.

# Ecosystem parameters
var prey_population: int = 50
var predator_population: int = 5
var food_amount: int = 100
var mutation_rate: float = 0.1
var proximity_for_mating: float = 0.03

# Bounds (half-extents on X/Z, full height on Y)
const HALF_X: float = 0.4
const HALF_Z: float = 0.4
const HEIGHT: float = 0.4

# Entity lists
var prey_list: Array = []
var predator_list: Array = []
var food_list: Array = []

# MultiMesh rendering
var prey_mm_instance: MultiMeshInstance3D
var predator_mm_instance: MultiMeshInstance3D
var food_mm_instance: MultiMeshInstance3D
var info_label: Label3D

# Inner classes ────────────────────────────────────────

class EcoPrey extends Creature:
	func _init(pos: Vector3, dna_values: Dictionary = {}) -> void:
		super(pos, dna_values)

	func eat_food(nutrition: float) -> void:
		health += nutrition

class EcoPredator extends Creature:
	func _init(pos: Vector3, dna_values: Dictionary = {}) -> void:
		super(pos, dna_values)
		if dna.size() > 0:
			dna["max_speed"] = max(dna["max_speed"], 0.08)

	func eat_prey(_prey) -> void:
		health += 0.5

# Lifecycle ────────────────────────────────────────────

func _ready() -> void:
	_setup_multimeshes()
	_setup_label()

	for i in range(prey_population):
		spawn_prey(_random_pos())

	for i in range(predator_population):
		spawn_predator(_random_pos())

	spawn_food(food_amount)

func _process(delta: float) -> void:
	update_prey(delta)
	update_predators(delta)

	# Periodically spawn food
	if randf() < 0.01:
		spawn_food(1)

	balance_ecosystem()
	_sync_multimeshes()
	_update_label()

func _exit_tree() -> void:
	for p in prey_list:
		if is_instance_valid(p):
			p.queue_free()
	for p in predator_list:
		if is_instance_valid(p):
			p.queue_free()
	for f in food_list:
		if is_instance_valid(f):
			f.queue_free()

# Setup ────────────────────────────────────────────────

func _setup_multimeshes() -> void:
	# Prey — blue spheres
	prey_mm_instance = MultiMeshInstance3D.new()
	var prey_mm = MultiMesh.new()
	prey_mm.transform_format = MultiMesh.TRANSFORM_3D
	prey_mm.use_colors = true
	var prey_mesh = SphereMesh.new()
	prey_mesh.radius = 0.008
	prey_mesh.height = 0.016
	prey_mm.mesh = prey_mesh
	prey_mm.instance_count = 0
	prey_mm_instance.multimesh = prey_mm
	add_child(prey_mm_instance)

	# Predators — red boxes
	predator_mm_instance = MultiMeshInstance3D.new()
	var pred_mm = MultiMesh.new()
	pred_mm.transform_format = MultiMesh.TRANSFORM_3D
	pred_mm.use_colors = true
	var pred_mesh = BoxMesh.new()
	pred_mesh.size = Vector3(0.012, 0.012, 0.012)
	pred_mm.mesh = pred_mesh
	pred_mm.instance_count = 0
	predator_mm_instance.multimesh = pred_mm
	add_child(predator_mm_instance)

	# Food — green spheres
	food_mm_instance = MultiMeshInstance3D.new()
	var food_mm = MultiMesh.new()
	food_mm.transform_format = MultiMesh.TRANSFORM_3D
	food_mm.use_colors = true
	var food_mesh = SphereMesh.new()
	food_mesh.radius = 0.004
	food_mesh.height = 0.008
	food_mm.mesh = food_mesh
	food_mm.instance_count = 0
	food_mm_instance.multimesh = food_mm
	add_child(food_mm_instance)

func _setup_label() -> void:
	info_label = Label3D.new()
	info_label.position = Vector3(0.0, HEIGHT + 0.05, 0.0)
	info_label.font_size = 32
	info_label.pixel_size = 0.001
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(info_label)

# MultiMesh sync ───────────────────────────────────────

func _sync_multimeshes() -> void:
	# Prey
	var pmm = prey_mm_instance.multimesh
	pmm.instance_count = prey_list.size()
	for i in range(prey_list.size()):
		var p = prey_list[i]
		pmm.set_instance_transform(i, Transform3D(Basis(), p.position))
		pmm.set_instance_color(i, Color(0.2, 0.5, 0.8))

	# Predators
	var rmm = predator_mm_instance.multimesh
	rmm.instance_count = predator_list.size()
	for i in range(predator_list.size()):
		var p = predator_list[i]
		rmm.set_instance_transform(i, Transform3D(Basis(), p.position))
		rmm.set_instance_color(i, Color(0.8, 0.2, 0.2))

	# Food
	var fmm = food_mm_instance.multimesh
	fmm.instance_count = food_list.size()
	for i in range(food_list.size()):
		var f = food_list[i]
		fmm.set_instance_transform(i, Transform3D(Basis(), f.position))
		fmm.set_instance_color(i, Color(0.2, 0.8, 0.2))

func _update_label() -> void:
	info_label.text = "Prey: %d  Predators: %d  Food: %d" % [
		prey_list.size(), predator_list.size(), food_list.size()]

# Simulation ───────────────────────────────────────────

func update_prey(delta: float) -> void:
	var prey_to_remove: Array = []

	for prey in prey_list:
		prey.update(delta)

		# Check for nearby food
		var food_eaten = null
		for food in food_list:
			var distance = prey.position.distance_to(food.position)
			if distance < prey.size + 0.005:
				prey.eat_food(food.nutrition)
				food_eaten = food
				break

		if food_eaten:
			food_list.erase(food_eaten)
			food_eaten.queue_free()

		# Flee from predators
		var flee_force := Vector3.ZERO
		for predator in predator_list:
			var distance = prey.position.distance_to(predator.position)
			if distance < prey.dna["perception_radius"]:
				var flee = prey.flee(predator.position)
				flee_force += flee * prey.dna["flee_weight"]

		prey.apply_force(flee_force)

		if prey.can_reproduce() and randf() < prey.dna["reproduction_rate"] * delta:
			check_for_mate(prey)

		if prey.is_dead():
			prey_to_remove.append(prey)

	for prey in prey_to_remove:
		prey_list.erase(prey)
		prey.queue_free()

func update_predators(delta: float) -> void:
	var predators_to_remove: Array = []

	for predator in predator_list:
		predator.update(delta)

		var nearest_prey = null
		var min_distance: float = predator.dna["perception_radius"]

		for prey in prey_list:
			var distance = predator.position.distance_to(prey.position)
			if distance < min_distance:
				min_distance = distance
				nearest_prey = prey

		if nearest_prey:
			var seek_force = predator.seek(nearest_prey.position) * predator.dna["seek_weight"]
			predator.apply_force(seek_force)

			if min_distance < predator.size + nearest_prey.size:
				predator.eat_prey(nearest_prey)
				prey_list.erase(nearest_prey)
				nearest_prey.queue_free()

		if predator.can_reproduce() and randf() < predator.dna["reproduction_rate"] * delta:
			check_for_mate(predator, true)

		if predator.is_dead():
			predators_to_remove.append(predator)

	for predator in predators_to_remove:
		predator_list.erase(predator)
		predator.queue_free()

func check_for_mate(creature, is_predator: bool = false) -> void:
	var creature_list = predator_list if is_predator else prey_list

	for potential_mate in creature_list:
		if potential_mate == creature:
			continue

		var distance = creature.position.distance_to(potential_mate.position)
		if distance < proximity_for_mating and potential_mate.can_reproduce():
			var child_dna = crossover_dna(creature.dna, potential_mate.dna)
			child_dna = mutate_dna(child_dna)

			var spawn_pos = (creature.position + potential_mate.position) / 2.0
			if is_predator:
				spawn_predator(spawn_pos, child_dna)
			else:
				spawn_prey(spawn_pos, child_dna)

			creature.health -= 0.2
			potential_mate.health -= 0.2
			break

func crossover_dna(dna1: Dictionary, dna2: Dictionary) -> Dictionary:
	var child_dna := {}
	for key in dna1.keys():
		if randf() < 0.5:
			child_dna[key] = dna1[key]
		else:
			child_dna[key] = dna2[key]
	return child_dna

func mutate_dna(dna: Dictionary) -> Dictionary:
	var mutated_dna = dna.duplicate()
	for key in mutated_dna.keys():
		if randf() < mutation_rate:
			var mutation_amount = randf_range(-0.2, 0.2)
			mutated_dna[key] = max(0.001, mutated_dna[key] * (1.0 + mutation_amount))
	return mutated_dna

# Spawning ─────────────────────────────────────────────

func spawn_prey(pos: Vector3, dna_values: Dictionary = {}) -> EcoPrey:
	var prey = EcoPrey.new(pos, dna_values)
	prey_list.append(prey)
	add_child(prey)
	return prey

func spawn_predator(pos: Vector3, dna_values: Dictionary = {}) -> EcoPredator:
	var predator = EcoPredator.new(pos, dna_values)
	predator_list.append(predator)
	add_child(predator)
	return predator

func spawn_food(amount: int) -> void:
	for i in range(amount):
		var pos = _random_pos()
		var food = Food.new(pos)
		food_list.append(food)
		add_child(food)

func balance_ecosystem() -> void:
	if prey_list.size() < 10:
		for i in range(5):
			spawn_prey(_random_pos())

	if predator_list.size() > prey_list.size() * 0.5:
		for predator in predator_list:
			predator.health -= 0.05

	if predator_list.size() < 2 and prey_list.size() > 20:
		for i in range(2):
			spawn_predator(_random_pos())

# Helpers ──────────────────────────────────────────────

func _random_pos() -> Vector3:
	return Vector3(
		randf_range(-HALF_X, HALF_X),
		randf_range(0.0, HEIGHT),
		randf_range(-HALF_Z, HALF_Z))

func apply_grid_config(config: Dictionary) -> void:
	pass
