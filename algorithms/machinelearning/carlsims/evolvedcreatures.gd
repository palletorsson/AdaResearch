extends Node3D

## Carl Sims-inspired Evolved Creatures.
## A population of bipedal creatures evolve their gait parameters (hip amplitude,
## frequency, phase) through genetic algorithms. Fitness is measured by forward
## locomotion distance. The best creatures pass their genes to the next generation.

class_name CarlsimsEvolution

const POPULATION_SIZE: int = 20
const GENERATION_DURATION: float = 20.0
const HIP_LIMIT: float = 0.9
const HIP_MAX_TORQUE: float = 50.0
const CREATURE_SPACING: float = 7.0
const ROOT_HEIGHT: float = 2.2
const FLOOR_EXTENT: float = 40.0

@export var random_seed: int = 20241103
@export var enable_random_restart: bool = false
@export var enable_debug_prints: bool = true

@onready var camera: Camera3D = $Camera3D
@onready var light: DirectionalLight3D = $DirectionalLight3D

var _rng: RandomNumberGenerator = RandomNumberGenerator.new()
var _population: Array[CreatureInstance] = []
var _timer: float = 0.0
var _generation: int = 0
var _status_label: Label3D = null
var _best_fitness_ever: float = 0.0

class CreatureGenome:
	var hip_amplitude: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
	var hip_frequency: PackedFloat32Array = PackedFloat32Array([1.0, 1.0])
	var hip_phase: PackedFloat32Array = PackedFloat32Array([0.0, PI])
	var torso_mass: float = 4.0
	var leg_mass: float = 2.0
	var fitness: float = 0.0

	func randomize(rng: RandomNumberGenerator) -> void:
		for i in range(2):
			hip_amplitude[i] = rng.randf_range(0.6, 1.8)
			hip_frequency[i] = rng.randf_range(0.6, 1.4)
			hip_phase[i] = rng.randf_range(0.0, TAU)
		torso_mass = rng.randf_range(3.0, 6.0)
		leg_mass = rng.randf_range(1.2, 3.0)
		fitness = 0.0

	func duplicate() -> CreatureGenome:
		var copy := CreatureGenome.new()
		copy.hip_amplitude = hip_amplitude.duplicate()
		copy.hip_frequency = hip_frequency.duplicate()
		copy.hip_phase = hip_phase.duplicate()
		copy.torso_mass = torso_mass
		copy.leg_mass = leg_mass
		copy.fitness = fitness
		return copy

class CreatureInstance:
	var genome: CreatureGenome
	var bodies: Array[RigidBody3D] = []
	var joints: Array[HingeJoint3D] = []
	var start_position: Vector3 = Vector3.ZERO
	var elapsed: float = 0.0

func _ready() -> void:
	_rng.seed = random_seed
	_build_ground()
	_create_status_label()
	spawn_initial_population()

func _create_status_label() -> void:
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 48
	_status_label.modulate = Color(1.0, 0.85, 0.2)
	_status_label.outline_modulate = Color(0, 0, 0, 0.6)
	_status_label.outline_size = 4
	_status_label.position = Vector3(0, 6, 0)
	_status_label.text = "Generation 0 | Evolving…"
	add_child(_status_label)

func _build_ground() -> void:
	var floor := StaticBody3D.new()
	var shape := BoxShape3D.new()
	shape.size = Vector3(FLOOR_EXTENT, 0.4, FLOOR_EXTENT)
	var collider := CollisionShape3D.new()
	collider.shape = shape
	floor.add_child(collider)
	var mesh_instance := MeshInstance3D.new()
	var plane_mesh := BoxMesh.new()
	plane_mesh.size = shape.size
	mesh_instance.mesh = plane_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.24, 0.26, 1.0)
	mat.roughness = 0.85
	mat.metallic = 0.05
	mesh_instance.material_override = mat
	floor.add_child(mesh_instance)
	floor.position = Vector3(0, -0.2, 0)
	add_child(floor)

func spawn_initial_population() -> void:
	_clear_population()
	for idx in range(POPULATION_SIZE):
		var genome := CreatureGenome.new()
		genome.randomize(_rng)
		var pos := _grid_position(idx)
		var creature := _spawn_creature(genome, pos)
		_population.append(creature)
	_generation = 0
	_timer = 0.0

func _grid_position(index: int) -> Vector3:
	var columns := 5
	var row := index / columns
	var col := index % columns
	var x := (col - (columns - 1) * 0.5) * CREATURE_SPACING
	var z := (row - 1.0) * CREATURE_SPACING
	return Vector3(x, ROOT_HEIGHT, z)

func _spawn_creature(genome: CreatureGenome, start_pos: Vector3) -> CreatureInstance:
	var instance := CreatureInstance.new()
	instance.genome = genome
	instance.start_position = start_pos
	var torso := _create_body(Vector3(0.7, 0.4, 0.5), genome.torso_mass, Color(0.7, 0.5, 0.9, 1.0))
	torso.position = start_pos
	torso.name = "Torso"
	instance.bodies.append(torso)
	for leg_idx in [0, 1]:
		var offset := Vector3(0.4 if leg_idx == 0 else -0.4, -0.6, 0.0)
		var leg := _create_body(Vector3(0.25, 0.8, 0.3), genome.leg_mass, Color(0.4 + 0.3 * leg_idx, 0.85, 0.6, 1.0))
		leg.position = start_pos + offset
		leg.name = "Leg_%d" % leg_idx
		instance.bodies.append(leg)
		var joint := _create_hip_joint(torso, leg, offset, leg_idx)
		joint.set_meta("index", leg_idx)
		instance.joints.append(joint)
	return instance

func _create_body(size: Vector3, mass: float, colour: Color) -> RigidBody3D:
	## Creates a physics body with emissive, slightly metallic material
	var body := RigidBody3D.new()
	body.mass = mass
	body.linear_damp = 0.2
	body.angular_damp = 0.2
	body.can_sleep = false
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	body.add_child(collider)
	var mesh := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.5
	mat.metallic = 0.15
	mat.emission_enabled = true
	mat.emission = colour * 0.12
	mesh.material_override = mat
	body.add_child(mesh)
	add_child(body)
	return body

func _create_hip_joint(parent: RigidBody3D, child: RigidBody3D, offset: Vector3, leg_idx: int) -> HingeJoint3D:
	var joint := HingeJoint3D.new()
	joint.node_a = parent.get_path()
	joint.node_b = child.get_path()
	joint.position = parent.position + offset * 0.5
	joint.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0 if leg_idx == 0 else -90.0))
	joint.set_param(HingeJoint3D.PARAM_LIMIT_LOWER, -HIP_LIMIT)
	joint.set_param(HingeJoint3D.PARAM_LIMIT_UPPER, HIP_LIMIT)
	joint.set_flag(HingeJoint3D.FLAG_USE_LIMIT, true)
	joint.set_flag(HingeJoint3D.FLAG_ENABLE_MOTOR, true)
	joint.set_param(HingeJoint3D.PARAM_MOTOR_MAX_IMPULSE, HIP_MAX_TORQUE)
	add_child(joint)
	return joint

func _physics_process(delta: float) -> void:
	_timer += delta
	for creature in _population:
		creature.elapsed += delta
		for joint in creature.joints:
			var idx: int = int(joint.get_meta("index"))
			var amp := creature.genome.hip_amplitude[idx]
			var freq := creature.genome.hip_frequency[idx]
			var phase := creature.genome.hip_phase[idx]
			var target := amp * sin(creature.elapsed * freq + phase)
			joint.set_param(HingeJoint3D.PARAM_MOTOR_TARGET_VELOCITY, target)
	if _timer >= GENERATION_DURATION:
		_evaluate_population()
		_evolve_generation()
		_timer = 0.0

func _evaluate_population() -> void:
	var gen_best: float = 0.0
	var gen_avg: float = 0.0
	for creature in _population:
		if creature.bodies.is_empty():
			creature.genome.fitness = 0.0
			continue
		var torso := creature.bodies[0]
		if not is_instance_valid(torso):
			creature.genome.fitness = 0.0
			continue
		var displacement := torso.global_position - creature.start_position
		var forward := displacement.x
		var distance := displacement.length()
		var height_bonus: float = max(0.0, torso.global_position.y - 1.0)
		creature.genome.fitness = forward * 2.0 + distance * 0.5 + height_bonus * 0.3
		gen_best = max(gen_best, creature.genome.fitness)
		gen_avg += creature.genome.fitness
		if enable_debug_prints:
			print("Generation %d fitness: %.2f" % [_generation, creature.genome.fitness])
	
	gen_avg /= max(1, _population.size())
	_best_fitness_ever = max(_best_fitness_ever, gen_best)
	
	# Highlight the best creature with a gold flash
	for creature in _population:
		if creature.genome.fitness >= gen_best and creature.bodies.size() > 0:
			var torso = creature.bodies[0]
			if is_instance_valid(torso):
				var mesh_child = torso.get_child(1) if torso.get_child_count() > 1 else null
				if mesh_child is MeshInstance3D and mesh_child.material_override is StandardMaterial3D:
					var mat = mesh_child.material_override as StandardMaterial3D
					var orig_emission = mat.emission
					mat.emission = Color(1.0, 0.85, 0.2) * 0.6
					var tw = create_tween()
					tw.tween_property(mat, "emission", orig_emission, 1.5)
			break
	
	# Update HUD
	if _status_label:
		_status_label.text = "Gen %d | Best %.1f | Avg %.1f | Record %.1f" % [_generation, gen_best, gen_avg, _best_fitness_ever]

func _evolve_generation() -> void:
	_generation += 1
	var genomes: Array[CreatureGenome] = []
	for creature in _population:
		genomes.append(creature.genome)
	genomes.sort_custom(func(a: CreatureGenome, b: CreatureGenome): return a.fitness > b.fitness)
	var parents: Array[CreatureGenome] = []
	var keep: int = min(2, genomes.size())
	for i in range(keep):
		parents.append(genomes[i].duplicate())
	var offspring: Array[CreatureGenome] = parents.duplicate()
	while offspring.size() < POPULATION_SIZE:
		var mother := genomes[_rng.randi_range(0, min(4, genomes.size() - 1))]
		var father := genomes[_rng.randi_range(0, min(4, genomes.size() - 1))]
		var child := _crossover(mother, father)
		_mutate(child)
		offspring.append(child)
	_reset_population_with_genomes(offspring)

func _crossover(a: CreatureGenome, b: CreatureGenome) -> CreatureGenome:
	var child := CreatureGenome.new()
	for i in range(2):
		var t := _rng.randf_range(0.0, 1.0)
		child.hip_amplitude[i] = lerp(a.hip_amplitude[i], b.hip_amplitude[i], t)
		child.hip_frequency[i] = lerp(a.hip_frequency[i], b.hip_frequency[i], t)
		child.hip_phase[i] = lerp_angle(a.hip_phase[i], b.hip_phase[i], t)
	child.torso_mass = lerp(a.torso_mass, b.torso_mass, 0.5)
	child.leg_mass = lerp(a.leg_mass, b.leg_mass, 0.5)
	return child

func _mutate(genome: CreatureGenome) -> void:
	for i in range(2):
		if _rng.randf() < 0.5:
			genome.hip_amplitude[i] = clamp(genome.hip_amplitude[i] + _rng.randfn(0.0, MUTATION_STD), 0.3, 2.5)
		if _rng.randf() < 0.5:
			genome.hip_frequency[i] = clamp(genome.hip_frequency[i] + _rng.randfn(0.0, MUTATION_STD), 0.3, 2.0)
		if _rng.randf() < 0.5:
			genome.hip_phase[i] = wrapf(genome.hip_phase[i] + _rng.randfn(0.0, MUTATION_STD), 0.0, TAU)
	if _rng.randf() < 0.3:
		genome.torso_mass = clamp(genome.torso_mass + _rng.randfn(0.0, MUTATION_STD), 2.0, 8.0)
	if _rng.randf() < 0.3:
		genome.leg_mass = clamp(genome.leg_mass + _rng.randfn(0.0, MUTATION_STD), 0.8, 4.0)

func _reset_population_with_genomes(genomes: Array[CreatureGenome]) -> void:
	_clear_population()
	for idx in range(POPULATION_SIZE):
		var genome := genomes[idx % genomes.size()].duplicate()
		if enable_random_restart and idx >= genomes.size():
			genome.randomize(_rng)
		var pos := _grid_position(idx)
		var creature := _spawn_creature(genome, pos)
		_population.append(creature)
	_timer = 0.0

func _clear_population() -> void:
	for creature in _population:
		for joint in creature.joints:
			if is_instance_valid(joint):
				joint.queue_free()
		for body in creature.bodies:
			if is_instance_valid(body):
				body.queue_free()
	_population.clear()

func _randfn(mean := 0.0, std_dev := 0.1) -> float:
	return _rng.randfn(mean, std_dev)

const MUTATION_STD: float = 0.25

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

