extends Node3D

# Evolving Flowers using Genetic Algorithms
# Based on Nature of Code principles

const POPULATION_SIZE = 16
const GENERATION_TIME = 8.0
const MUTATION_RATE = 0.15
const ELITE_COUNT = 2

var generation := 0
var timer := 0.0
var current_population := []
var fitness_scores := []

class FlowerGenome:
	var petal_count: int = 5
	var petal_length: float = 1.0
	var petal_width: float = 0.5
	var petal_curve: float = 0.0
	var center_size: float = 0.3
	var color_hue: float = 0.0
	var color_saturation: float = 0.8
	var color_value: float = 1.0
	var stem_height: float = 1.5
	var leaf_size: float = 0.5
	var symmetry: float = 1.0
	var fitness: float = 0.0

	# L-System parameters for branching
	var lsystem_axiom: String = "F"
	var lsystem_rules: Dictionary = {"F": "F[+F]F[-F]F"}
	var lsystem_iterations: int = 2
	var branch_angle: float = 25.0
	var branch_length_decay: float = 0.7
	
	func _init():
		randomize_genome()
	
	func randomize_genome():
		petal_count = randi() % 8 + 3  # 3-10 petals
		petal_length = randf_range(0.5, 1.5)
		petal_width = randf_range(0.2, 0.8)
		petal_curve = randf_range(-0.3, 0.3)
		center_size = randf_range(0.2, 0.5)
		color_hue = randf()
		color_saturation = randf_range(0.6, 1.0)
		color_value = randf_range(0.7, 1.0)
		stem_height = randf_range(1.0, 2.5)
		leaf_size = randf_range(0.3, 0.8)
		symmetry = randf_range(0.8, 1.0)

		# Randomize L-System parameters
		lsystem_iterations = randi() % 3 + 1  # 1-3 iterations
		branch_angle = randf_range(15.0, 45.0)
		branch_length_decay = randf_range(0.5, 0.8)

		# Random L-System rule selection
		var rule_options = [
			"F[+F]F[-F]F",
			"F[+F][-F]F",
			"FF[+F][-F]",
			"F[++F][--F]F",
			"F[+F][F][-F]"
		]
		lsystem_rules = {"F": rule_options[randi() % rule_options.size()]}
	
	func crossover(other: FlowerGenome) -> FlowerGenome:
		var child = FlowerGenome.new()
		# Uniform crossover
		child.petal_count = self.petal_count if randf() < 0.5 else other.petal_count
		child.petal_length = lerp(self.petal_length, other.petal_length, randf())
		child.petal_width = lerp(self.petal_width, other.petal_width, randf())
		child.petal_curve = lerp(self.petal_curve, other.petal_curve, randf())
		child.center_size = lerp(self.center_size, other.center_size, randf())
		child.color_hue = lerp(self.color_hue, other.color_hue, randf())
		child.color_saturation = lerp(self.color_saturation, other.color_saturation, randf())
		child.color_value = lerp(self.color_value, other.color_value, randf())
		child.stem_height = lerp(self.stem_height, other.stem_height, randf())
		child.leaf_size = lerp(self.leaf_size, other.leaf_size, randf())
		child.symmetry = lerp(self.symmetry, other.symmetry, randf())

		# L-System crossover
		child.lsystem_iterations = self.lsystem_iterations if randf() < 0.5 else other.lsystem_iterations
		child.branch_angle = lerp(self.branch_angle, other.branch_angle, randf())
		child.branch_length_decay = lerp(self.branch_length_decay, other.branch_length_decay, randf())
		child.lsystem_rules = self.lsystem_rules if randf() < 0.5 else other.lsystem_rules

		return child
	
	func mutate():
		if randf() < MUTATION_RATE:
			petal_count = clampi(petal_count + (randi() % 3 - 1), 3, 12)
		if randf() < MUTATION_RATE:
			petal_length = clamp(petal_length + randf_range(-0.2, 0.2), 0.3, 2.0)
		if randf() < MUTATION_RATE:
			petal_width = clamp(petal_width + randf_range(-0.1, 0.1), 0.1, 1.0)
		if randf() < MUTATION_RATE:
			petal_curve = clamp(petal_curve + randf_range(-0.1, 0.1), -0.5, 0.5)
		if randf() < MUTATION_RATE:
			center_size = clamp(center_size + randf_range(-0.05, 0.05), 0.1, 0.7)
		if randf() < MUTATION_RATE:
			color_hue = fmod(color_hue + randf_range(-0.1, 0.1), 1.0)
		if randf() < MUTATION_RATE:
			color_saturation = clamp(color_saturation + randf_range(-0.1, 0.1), 0.3, 1.0)
		if randf() < MUTATION_RATE:
			color_value = clamp(color_value + randf_range(-0.1, 0.1), 0.5, 1.0)
		if randf() < MUTATION_RATE:
			stem_height = clamp(stem_height + randf_range(-0.2, 0.2), 0.5, 3.0)
		if randf() < MUTATION_RATE:
			leaf_size = clamp(leaf_size + randf_range(-0.1, 0.1), 0.2, 1.0)
		if randf() < MUTATION_RATE:
			symmetry = clamp(symmetry + randf_range(-0.05, 0.05), 0.7, 1.0)

		# L-System mutations
		if randf() < MUTATION_RATE:
			lsystem_iterations = clampi(lsystem_iterations + (randi() % 3 - 1), 1, 4)
		if randf() < MUTATION_RATE:
			branch_angle = clamp(branch_angle + randf_range(-5.0, 5.0), 10.0, 60.0)
		if randf() < MUTATION_RATE:
			branch_length_decay = clamp(branch_length_decay + randf_range(-0.1, 0.1), 0.4, 0.9)
		if randf() < MUTATION_RATE * 0.5:  # Rarer mutation
			var rule_options = [
				"F[+F]F[-F]F",
				"F[+F][-F]F",
				"FF[+F][-F]",
				"F[++F][--F]F",
				"F[+F][F][-F]"
			]
			lsystem_rules = {"F": rule_options[randi() % rule_options.size()]}

class Flower:
	var genome: FlowerGenome
	var root_node: Node3D
	var flower_head: Node3D
	var petals: Array = []
	var position: Vector3
	var age: float = 0.0
	
	func _init(g: FlowerGenome, pos: Vector3):
		genome = g
		position = pos

func _ready():
	setup_environment()
	initialize_population()

func setup_environment():
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-45, -30, 0)
	light.light_energy = 1.0
	light.shadow_enabled = true
	add_child(light)
	
	var ambient := WorldEnvironment.new()
	ambient.environment = Environment.new()
	ambient.environment.background_mode = Environment.BG_SKY
	ambient.environment.sky = Sky.new()
	ambient.environment.sky.sky_material = ProceduralSkyMaterial.new()
	(ambient.environment.sky.sky_material as ProceduralSkyMaterial).sky_top_color = Color(0.4, 0.6, 1.0)
	(ambient.environment.sky.sky_material as ProceduralSkyMaterial).sky_horizon_color = Color(0.7, 0.8, 1.0)
	(ambient.environment.sky.sky_material as ProceduralSkyMaterial).ground_bottom_color = Color(0.2, 0.3, 0.2)
	ambient.environment.sky.sky_material.ground_horizon_color = Color(0.4, 0.5, 0.3)
	ambient.environment.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	ambient.environment.ambient_light_energy = 0.5
	add_child(ambient)
	
	# Ground plane
	var ground := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 20)
	ground.mesh = plane
	var ground_mat := StandardMaterial3D.new()
	ground_mat.albedo_color = Color(0.3, 0.5, 0.2)
	ground.material_override = ground_mat
	ground.position.y = -0.01
	add_child(ground)
	
	var camera := Camera3D.new()
	camera.position = Vector3(0, 8, 12)
	camera.look_at_from_position(camera.position, Vector3(0, 1, 0), Vector3.UP)
	add_child(camera)
	
	# Info label
	var label := Label3D.new()
	label.text = "Evolving Flowers - Generation 0"
	label.font_size = 32
	label.position = Vector3(0, 5, -5)
	label.modulate = Color(1, 1, 1, 0.9)
	add_child(label)

func initialize_population():
	for i in range(POPULATION_SIZE):
		var genome = FlowerGenome.new()
		var x = (i % 4 - 1.5) * 3.0
		var z = (i / 4 - 1.5) * 3.0
		var flower = spawn_flower(genome, Vector3(x, 0, z))
		current_population.append(flower)

func spawn_flower(genome: FlowerGenome, pos: Vector3) -> Flower:
	var flower = Flower.new(genome, pos)
	
	flower.root_node = Node3D.new()
	flower.root_node.position = pos
	add_child(flower.root_node)
	
	# Stem
	var stem := MeshInstance3D.new()
	var stem_mesh := CylinderMesh.new()
	stem_mesh.top_radius = 0.05
	stem_mesh.bottom_radius = 0.08
	stem_mesh.height = genome.stem_height
	stem.mesh = stem_mesh
	var stem_mat := StandardMaterial3D.new()
	stem_mat.albedo_color = Color(0.2, 0.5, 0.1)
	stem.material_override = stem_mat
	stem.position.y = genome.stem_height / 2
	flower.root_node.add_child(stem)
	
	# Leaves
	for i in range(2):
		var leaf := MeshInstance3D.new()
		var leaf_mesh := create_leaf_mesh(genome.leaf_size)
		leaf.mesh = leaf_mesh
		var leaf_mat := StandardMaterial3D.new()
		leaf_mat.albedo_color = Color(0.3, 0.6, 0.2)
		leaf_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		leaf.material_override = leaf_mat
		var leaf_height = genome.stem_height * (0.3 + i * 0.3)
		leaf.position = Vector3(0, leaf_height, 0)
		leaf.rotation_degrees.y = i * 180
		leaf.rotation_degrees.z = 45
		flower.root_node.add_child(leaf)
	
	# Flower head container
	flower.flower_head = Node3D.new()
	flower.flower_head.position.y = genome.stem_height
	flower.root_node.add_child(flower.flower_head)
	
	# Center
	var center := MeshInstance3D.new()
	var center_mesh := SphereMesh.new()
	center_mesh.radius = genome.center_size
	center_mesh.height = genome.center_size * 2
	center_mesh.radial_segments = 16
	center_mesh.rings = 8
	center.mesh = center_mesh
	var center_mat := StandardMaterial3D.new()
	center_mat.albedo_color = Color(0.9, 0.7, 0.2)
	center_mat.emission_enabled = true
	center_mat.emission = Color(0.9, 0.7, 0.2) * 0.3
	center.material_override = center_mat
	flower.flower_head.add_child(center)
	
	# Petals
	var petal_color = Color.from_hsv(genome.color_hue, genome.color_saturation, genome.color_value)
	for i in range(genome.petal_count):
		var angle = (float(i) / genome.petal_count) * TAU
		var petal := MeshInstance3D.new()
		petal.mesh = create_petal_mesh(genome)
		var petal_mat := StandardMaterial3D.new()
		petal_mat.albedo_color = petal_color
		petal_mat.emission_enabled = true
		petal_mat.emission = petal_color * 0.2
		petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		petal.material_override = petal_mat

		# Position with symmetry variation
		var symmetry_offset = randf_range(-1.0 + genome.symmetry, 1.0 - genome.symmetry) * 0.1
		petal.rotation.y = angle + symmetry_offset
		petal.position = Vector3(0, 0, 0)

		flower.flower_head.add_child(petal)
		flower.petals.append(petal)

	# L-System branching structure
	var lsystem_container = Node3D.new()
	lsystem_container.rotation_degrees.x = 90  # Point branches outward
	flower.flower_head.add_child(lsystem_container)
	create_lsystem_branches(genome, lsystem_container, petal_color)

	return flower

func create_petal_mesh(genome: FlowerGenome) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	
	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()
	
	# Create petal shape
	var segments = 8
	for i in range(segments + 1):
		var t = float(i) / segments
		var width = sin(t * PI) * genome.petal_width
		var length = t * genome.petal_length
		var curve = sin(t * PI) * genome.petal_curve
		
		vertices.append(Vector3(-width, curve, length + genome.center_size))
		vertices.append(Vector3(width, curve, length + genome.center_size))
		normals.append(Vector3.UP)
		normals.append(Vector3.UP)
	
	for i in range(segments):
		var base = i * 2
		indices.append(base)
		indices.append(base + 2)
		indices.append(base + 1)
		indices.append(base + 1)
		indices.append(base + 2)
		indices.append(base + 3)
	
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices
	
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

func create_leaf_mesh(size: float) -> ArrayMesh:
	var mesh := ArrayMesh.new()
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)

	var vertices := PackedVector3Array()
	var normals := PackedVector3Array()
	var indices := PackedInt32Array()

	# Simple leaf shape
	vertices.append(Vector3(0, 0, 0))
	vertices.append(Vector3(-size * 0.3, 0, size * 0.5))
	vertices.append(Vector3(0, 0, size))
	vertices.append(Vector3(size * 0.3, 0, size * 0.5))

	for i in range(4):
		normals.append(Vector3.UP)

	indices.append(0)
	indices.append(1)
	indices.append(2)
	indices.append(0)
	indices.append(2)
	indices.append(3)

	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_NORMAL] = normals
	arrays[Mesh.ARRAY_INDEX] = indices

	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return mesh

# L-System Generation
func generate_lsystem_string(genome: FlowerGenome) -> String:
	var result = genome.lsystem_axiom
	for i in range(genome.lsystem_iterations):
		var next_result = ""
		for c in result:
			if genome.lsystem_rules.has(c):
				next_result += genome.lsystem_rules[c]
			else:
				next_result += c
		result = next_result
	return result

func create_lsystem_branches(genome: FlowerGenome, parent: Node3D, petal_color: Color):
	var lstring = generate_lsystem_string(genome)
	var position = Vector3.ZERO
	var direction = Vector3.UP
	var length = genome.petal_length * 0.3

	var stack = []  # Stack for push/pop operations

	for c in lstring:
		match c:
			"F":  # Draw forward
				var end_pos = position + direction * length
				var branch = create_branch_segment(position, end_pos, length * 0.05, petal_color)
				parent.add_child(branch)

				# Add small petal at end
				var mini_petal = MeshInstance3D.new()
				mini_petal.mesh = create_petal_mesh(genome)
				mini_petal.scale = Vector3.ONE * 0.3
				mini_petal.position = end_pos
				var petal_mat = StandardMaterial3D.new()
				petal_mat.albedo_color = petal_color
				petal_mat.emission_enabled = true
				petal_mat.emission = petal_color * 0.3
				petal_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
				mini_petal.material_override = petal_mat
				parent.add_child(mini_petal)

				position = end_pos
				length *= genome.branch_length_decay

			"+":  # Rotate right
				direction = direction.rotated(Vector3.FORWARD, deg_to_rad(genome.branch_angle))

			"-":  # Rotate left
				direction = direction.rotated(Vector3.FORWARD, deg_to_rad(-genome.branch_angle))

			"[":  # Push state
				stack.append({"pos": position, "dir": direction, "len": length})

			"]":  # Pop state
				if stack.size() > 0:
					var state = stack.pop_back()
					position = state.pos
					direction = state.dir
					length = state.len

func create_branch_segment(start: Vector3, end: Vector3, thickness: float, color: Color) -> MeshInstance3D:
	var branch = MeshInstance3D.new()
	var mesh = CylinderMesh.new()
	mesh.top_radius = thickness
	mesh.bottom_radius = thickness * 1.2
	mesh.height = start.distance_to(end)
	branch.mesh = mesh

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color.darkened(0.3)
	branch.material_override = mat

	branch.position = (start + end) / 2.0
	# Only orient if positions are different (with tolerance)
	var distance = start.distance_to(end)
	if distance > 0.001:  # Use distance check instead of is_equal_approx
		branch.look_at_from_position(branch.position, end, Vector3.RIGHT)
		branch.rotate_object_local(Vector3.RIGHT, PI / 2)

	return branch

func _process(delta):
	timer += delta
	
	# Animate flowers
	for flower in current_population:
		flower.age += delta
		if flower.flower_head:
			flower.flower_head.rotation.y += delta * 0.2
			var bob = sin(flower.age * 2.0) * 0.05
			flower.flower_head.position.y = flower.genome.stem_height + bob
	
	if timer >= GENERATION_TIME:
		evolve_population()
		timer = 0.0

func evolve_population():
	generation += 1
	print("\n=== Generation ", generation, " ===")
	
	# Calculate fitness
	calculate_fitness()
	
	# Sort by fitness
	var genomes_with_fitness = []
	for i in range(current_population.size()):
		genomes_with_fitness.append({
			"genome": current_population[i].genome,
			"fitness": fitness_scores[i]
		})
	genomes_with_fitness.sort_custom(func(a, b): return a.fitness > b.fitness)
	
	print("Best fitness: ", genomes_with_fitness[0].fitness)
	print("Average fitness: ", fitness_scores.reduce(func(a, b): return a + b, 0.0) / fitness_scores.size())
	
	# Clear old flowers
	for flower in current_population:
		if flower.root_node:
			flower.root_node.queue_free()
	current_population.clear()
	fitness_scores.clear()
	
	# Create new generation
	var new_genomes = []
	
	# Elitism - keep best
	for i in range(ELITE_COUNT):
		new_genomes.append(genomes_with_fitness[i].genome)
	
	# Breed the rest
	while new_genomes.size() < POPULATION_SIZE:
		var parent1 = select_parent(genomes_with_fitness)
		var parent2 = select_parent(genomes_with_fitness)
		var child = parent1.crossover(parent2)
		child.mutate()
		new_genomes.append(child)
	
	# Spawn new generation
	for i in range(POPULATION_SIZE):
		var x = (i % 4 - 1.5) * 3.0
		var z = (i / 4 - 1.5) * 3.0
		var flower = spawn_flower(new_genomes[i], Vector3(x, 0, z))
		current_population.append(flower)
	
	update_generation_label()

func calculate_fitness():
	fitness_scores.clear()
	for flower in current_population:
		var genome = flower.genome
		var fitness = 0.0

		# Reward specific traits
		fitness += genome.petal_count * 2.0  # More petals = better
		fitness += genome.petal_length * 10.0  # Longer petals = better
		fitness += genome.symmetry * 15.0  # Symmetry = better
		fitness += (1.0 - abs(genome.color_hue - 0.8)) * 20.0  # Prefer purple/pink hues
		fitness += genome.color_saturation * 10.0  # Vivid colors = better

		# L-System fitness rewards
		fitness += genome.lsystem_iterations * 8.0  # More complex = better
		fitness += (1.0 - abs(genome.branch_angle - 30.0) / 30.0) * 10.0  # Prefer ~30 degree angles
		fitness += genome.branch_length_decay * 5.0  # Reward gradual decay

		# Calculate L-System complexity
		var lstring = generate_lsystem_string(genome)
		var branch_count = lstring.count("F")
		fitness += min(branch_count, 20) * 0.5  # Reward branching up to a limit

		# Penalty for extreme values
		if genome.petal_count > 10:
			fitness -= 10.0
		if genome.petal_width < 0.3:
			fitness -= 5.0
		if branch_count > 50:  # Too many branches
			fitness -= 15.0

		flower.genome.fitness = fitness
		fitness_scores.append(fitness)

func select_parent(genomes_with_fitness: Array) -> FlowerGenome:
	# Tournament selection
	var tournament_size = 3
	var best = null
	var best_fitness = -INF
	
	for i in range(tournament_size):
		var candidate = genomes_with_fitness[randi() % genomes_with_fitness.size()]
		if candidate.fitness > best_fitness:
			best_fitness = candidate.fitness
			best = candidate.genome
	
	return best

func update_generation_label():
	for child in get_children():
		if child is Label3D:
			child.text = "Evolving Flowers - Generation " + str(generation)
			break
