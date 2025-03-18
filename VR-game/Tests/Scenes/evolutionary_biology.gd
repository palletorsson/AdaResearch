extends Node3D

# Evolutionary Sculpture Generator for Godot 4
# This script creates a procedural sculpture that evolves over time based on evolutionary principles

# Constants
const POPULATION_SIZE = 20  # Number of "organisms" in each generation
const MUTATION_RATE = 0.1   # Probability of mutation
const SELECTION_PRESSURE = 0.5  # How strongly fitness affects selection
const GENERATIONS = 10      # How many evolutionary iterations to perform

# Classes for our organism parts
class Gene:
	var position = Vector3()
	var size = 1.0
	var color = Color(1, 1, 1)
	var shape_type = 0  # 0 = sphere, 1 = cube, 2 = cylinder
	
	func _init(p_position = null, p_size = null, p_color = null, p_shape = null):
		position = p_position if p_position != null else Vector3(randf_range(-5, 5), randf_range(-5, 5), randf_range(-5, 5))
		size = p_size if p_size != null else randf_range(0.5, 2.0)
		color = p_color if p_color != null else Color(randf(), randf(), randf())
		shape_type = p_shape if p_shape != null else randi() % 3
	
	func mutate():
		if randf() < MUTATION_RATE:
			position += Vector3(randf_range(-1, 1), randf_range(-1, 1), randf_range(-1, 1))
		if randf() < MUTATION_RATE:
			size = clamp(size + randf_range(-0.5, 0.5), 0.1, 3.0)
		if randf() < MUTATION_RATE:
			color = Color(
				clamp(color.r + randf_range(-0.2, 0.2), 0, 1),
				clamp(color.g + randf_range(-0.2, 0.2), 0, 1),
				clamp(color.b + randf_range(-0.2, 0.2), 0, 1)
			)
		if randf() < MUTATION_RATE:
			shape_type = randi() % 3

class Organism:
	var genes = []
	var fitness = 0.0
	
	func _init(gene_count = 10):
		for i in range(gene_count):
			genes.append(Gene.new())
	
	func calculate_fitness():
		# Calculate fitness based on aesthetic principles:
		# 1. Connectedness (spheres close enough to overlap)
		# 2. Color gradient harmony 
		# 3. Cohesive overall shape
		var connectedness_score = 0.0
		var color_harmony = 0.0
		var cohesion_score = 0.0
		
		# Check connectedness - spheres should be close to at least one other sphere
		for i in range(genes.size()):
			var gene = genes[i]
			var connected = false
			
			for j in range(genes.size()):
				if i == j:
					continue
					
				var other_gene = genes[j]
				var distance = gene.position.distance_to(other_gene.position)
				var connection_threshold = gene.size + other_gene.size
				
				if distance < connection_threshold * 0.8:
					connected = true
					connectedness_score += 1.0
					break
			
			if !connected:
				connectedness_score -= 0.5  # Penalty for isolated spheres
		
		# Calculate color harmony using gradient-like progression
		var positions = []
		var colors = []
		
		for gene in genes:
			positions.append(gene.position.length())
			colors.append(gene.color)
		
		# Sort by distance from center
		var sorted_indices = range(positions.size())
		sorted_indices.sort_custom(func(a, b): return positions[a] < positions[b])
		
		# Check if colors follow a gradient pattern
		for i in range(1, sorted_indices.size()):
			var curr_idx = sorted_indices[i]
			var prev_idx = sorted_indices[i-1]
			
			var curr_color = colors[curr_idx]
			var prev_color = colors[prev_idx]
			
			var color_diff = abs(curr_color.r - prev_color.r) + \
							abs(curr_color.g - prev_color.g) + \
							abs(curr_color.b - prev_color.b)
			
			# Lower difference means smoother gradient
			color_harmony += 1.0 - clamp(color_diff / 3.0, 0.0, 1.0)
		
		# Calculate cohesion - spheres should form a single connected structure
		# Use center of mass as reference
		var center_of_mass = Vector3.ZERO
		for gene in genes:
			center_of_mass += gene.position
		center_of_mass /= genes.size()
		
		# Calculate standard deviation of distances from center of mass
		var avg_distance = 0.0
		for gene in genes:
			avg_distance += gene.position.distance_to(center_of_mass)
		avg_distance /= genes.size()
		
		var distance_variance = 0.0
		for gene in genes:
			var distance = gene.position.distance_to(center_of_mass)
			distance_variance += pow(distance - avg_distance, 2)
		distance_variance /= genes.size()
		
		# Lower variance means more cohesive shape
		cohesion_score = 1.0 / (1.0 + distance_variance * 0.1)
		
		# Combine scores
		fitness = (connectedness_score / (genes.size() * 0.5)) + \
				  (color_harmony / genes.size()) + \
				  (cohesion_score * 2.0)
		
		return fitness
	
	func crossover(other):
		var child = Organism.new(0)  # Empty organism
		var split_point = randi() % genes.size()
		
		for i in range(genes.size()):
			if i < split_point:
				child.genes.append(Gene.new(genes[i].position, genes[i].size, genes[i].color, genes[i].shape_type))
			else:
				child.genes.append(Gene.new(other.genes[i].position, other.genes[i].size, other.genes[i].color, other.genes[i].shape_type))
		
		return child
	
	func mutate():
		for gene in genes:
			gene.mutate()

# Variables
var population = []
var current_generation = 0
var best_organism = null
var evolution_timer = null
var sculpture_node = null

# Main functions
func _ready():
	randomize()
	
	# Create a node to hold our sculpture first
	sculpture_node = Node3D.new()
	sculpture_node.name = "EvolutionarySculpture"
	add_child(sculpture_node)
	
	# Setup camera and lights
	setup_viewer()
	
	# Then initialize population and timer
	initialize_population()
	evolution_timer = Timer.new()
	evolution_timer.wait_time = 2.0
	evolution_timer.timeout.connect(_on_evolution_step)
	add_child(evolution_timer)
	evolution_timer.start()

func initialize_population():
	population.clear()
	for i in range(POPULATION_SIZE):
		var organism = Organism.new()
		organism.calculate_fitness()
		population.append(organism)
	
	# Find best organism
	update_best_organism()

func update_best_organism():
	var best_fitness = -1
	for organism in population:
		if organism.fitness > best_fitness:
			best_fitness = organism.fitness
			best_organism = organism
	
	# Display the best organism
	display_organism(best_organism)

func display_organism(organism):
	# Check if sculpture_node exists before trying to clear it
	if sculpture_node:
		# Clear previous sculpture
		for child in sculpture_node.get_children():
			child.queue_free()
	else:
		# Create the node if it doesn't exist
		sculpture_node = Node3D.new()
		sculpture_node.name = "EvolutionarySculpture"
		add_child(sculpture_node)
	
	# Create new shapes based on genes
	for gene in organism.genes:
		var shape_node
		var material = StandardMaterial3D.new()
		material.albedo_color = gene.color
		
		# Set transparency properties
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		material.albedo_color.a = 0.6  # Make semi-transparent
		
		# Only use spheres
		shape_node = MeshInstance3D.new()
		shape_node.mesh = SphereMesh.new()
		shape_node.mesh.radius = gene.size
		shape_node.mesh.height = gene.size * 2
		
		shape_node.material_override = material
		shape_node.position = gene.position
		sculpture_node.add_child(shape_node)

func _on_evolution_step():
	if current_generation >= GENERATIONS:
		evolution_timer.stop()
		print("Evolution complete!")
		return
	
	evolve_population()
	current_generation += 1
	print("Generation: ", current_generation)
	
	# Update the display with the best organism
	update_best_organism()

func evolve_population():
	# Calculate fitness for all organisms
	for organism in population:
		organism.calculate_fitness()
	
	# Sort by fitness
	population.sort_custom(sort_by_fitness)
	
	# Create new generation through selection, crossover and mutation
	var new_population = []
	
	# Keep the best organism (elitism)
	new_population.append(population[0])
	
	# Create the rest through selection and crossover
	while new_population.size() < POPULATION_SIZE:
		var parent1 = select_organism()
		var parent2 = select_organism()
		var child = parent1.crossover(parent2)
		child.mutate()
		new_population.append(child)
	
	population = new_population

func sort_by_fitness(a, b):
	return a.fitness > b.fitness

func select_organism():
	# Tournament selection
	var tournament_size = int(POPULATION_SIZE * SELECTION_PRESSURE)
	var best = null
	var best_fitness = -1
	
	for i in range(tournament_size):
		var contestant = population[randi() % population.size()]
		if best == null or contestant.fitness > best_fitness:
			best = contestant
			best_fitness = contestant.fitness
	
	return best

func _process(delta):
	# Rotate the sculpture slowly for better viewing
	if sculpture_node:
		sculpture_node.rotate_y(delta * 0.2)

# Sample scene setup (add a camera and lights)
func setup_viewer():
	var camera = Camera3D.new()
	camera.position = Vector3(0, 0, 15)
	add_child(camera)
	
	var light = DirectionalLight3D.new()
	light.position = Vector3(10, 10, 10)
	light.look_at_from_position(Vector3(10, 10, 10), Vector3.ZERO, Vector3.UP)
	add_child(light)
	
	var light2 = DirectionalLight3D.new()
	light2.position = Vector3(-10, 5, -10)
	light2.look_at_from_position(Vector3(-10, 5, -10), Vector3.ZERO, Vector3.UP)
	add_child(light2)
