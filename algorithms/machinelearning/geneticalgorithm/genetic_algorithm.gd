extends Node3D

# Advanced Evolutionary Neural Network Ecosystem
# Combines genetic algorithms, neural networks, emergent behavior, and multi-species evolution
# Features adaptive fitness landscapes, speciation, neuroevolution, and ecosystem dynamics

@export_category("Evolution Parameters")
@export var population_size: int = 100
@export var mutation_rate: float = 0.15
@export var crossover_rate: float = 0.8
@export var elite_count: int = 8
@export var generation_time: float = 15.0
@export var environment_size: float = 30.0
@export var species_threshold: float = 3.0
@export var speciation_enabled: bool = true

@export_category("Neural Network")
@export var neural_complexity: int = 3  # Number of hidden layers
@export var neurons_per_layer: int = 8
@export var activation_function: String = "tanh"  # "sigmoid", "tanh", "relu", "leaky_relu"
@export var neuroevolution_enabled: bool = true
@export var synaptic_pruning: bool = true

@export_category("Ecosystem Dynamics")
@export var food_sources: int = 20
@export var predator_prey_enabled: bool = true
@export var environmental_pressure: float = 0.1
@export var resource_competition: bool = true
@export var age_limit: float = 60.0
@export var reproduction_threshold: float = 50.0

@export_category("Adaptive Features")
@export var adaptive_mutation: bool = true
@export var fitness_landscape_evolution: bool = true
@export var epigenetic_inheritance: bool = true
@export var cultural_transmission: bool = true

@export_category("Visualization")
@export var show_neural_connections: bool = true
@export var show_species_colors: bool = true
@export var show_fitness_landscape: bool = true
@export var show_family_trees: bool = false
@export var trail_visualization: bool = true
@export var real_time_graphs: bool = true

@export_category("Queer Forms & TDA")
@export var queer_forms_detection: bool = true
@export var topological_analysis_enabled: bool = true
@export var persistent_homology_enabled: bool = true
@export var mapper_algorithm_enabled: bool = true
@export var entropy_threshold: float = 0.7
@export var non_normativity_bias: float = 0.3

# Evolution state
var population: Array = []
var species_groups: Array = []
var generation: int = 0
var generation_timer: float = 0.0
var best_fitness: float = 0.0
var average_fitness: float = 0.0
var diversity_score: float = 0.0
var environmental_factors: Dictionary = {}

# Ecosystem elements
var food_sources_array: Array = []
var predators: Array = []
var environmental_hazards: Array = []
var pheromone_trails: Dictionary = {}

# Visual elements
var creatures: Array = []
var ui_elements: Dictionary = {}
var environment: Node3D
var fitness_landscape_mesh: MeshInstance3D
var neural_visualizer: Node3D

# Queer Forms Analysis
var queer_forms_detector: QueerFormsDetector
var current_queer_analysis: Dictionary = {}
var queer_forms_history: Array = []

# Performance tracking
var performance_metrics: Dictionary = {
	"generation_times": [],
	"fitness_progression": [],
	"species_count": [],
	"behavioral_diversity": []
}

# Enhanced creature class with neural networks and complex behaviors
class EvolutionaryCreature:
	var genes: Dictionary = {}
	var neural_network: NeuralNetwork
	var fitness: float = 0.0
	var age: float = 0.0
	var energy: float = 100.0
	var reproduction_count: int = 0
	var species_id: int = 0
	var generation_born: int = 0
	
	# Physical properties
	var position: Vector3
	var velocity: Vector3
	var angular_velocity: float = 0.0
	var size: float = 1.0
	var mass: float = 1.0
	
	# Behavioral states
	var behavior_state: String = "exploring"  # exploring, hunting, fleeing, reproducing, resting
	var memory: Array = []
	var learned_behaviors: Dictionary = {}
	var social_connections: Array = []
	
	# Visual representation
	var mesh_instance: MeshInstance3D
	var trail_points: Array = []
	var neural_display: Node3D
	
	# Sensory system
	var vision_range: float = 10.0
	var hearing_range: float = 8.0
	var smell_range: float = 5.0
	var perceived_objects: Array = []
	
	func _init():
		initialize_genes()
		initialize_neural_network()
		position = Vector3(
			randf_range(-10, 10),
			randf_range(0, 3),
			randf_range(-10, 10)
		)
		velocity = Vector3.ZERO
		memory = []
		learned_behaviors = {}
		social_connections = []
	
	func initialize_genes():
		"""Initialize comprehensive genetic code"""
		genes = {
			# Physical traits
			"size": randf_range(0.5, 2.5),
			"speed": randf_range(0.8, 4.0),
			"strength": randf_range(0.5, 2.0),
			"endurance": randf_range(0.5, 2.0),
			"agility": randf_range(0.5, 2.0),
			
			# Coloration (RGB + pattern)
			"red": randf(),
			"green": randf(),
			"blue": randf(),
			"pattern_complexity": randf(),
			"luminescence": randf(),
			
			# Behavioral traits
			"aggression": randf(),
			"social_tendency": randf(),
			"exploration": randf(),
			"risk_taking": randf(),
			"memory_capacity": randf_range(0.3, 1.0),
			"learning_rate": randf_range(0.1, 0.5),
			
			# Sensory capabilities
			"vision_acuity": randf(),
			"hearing_sensitivity": randf(),
			"smell_sensitivity": randf(),
			"touch_sensitivity": randf(),
			
			# Metabolic traits
			"energy_efficiency": randf(),
			"reproduction_drive": randf(),
			"longevity": randf(),
			"disease_resistance": randf(),
			
			# Neural architecture genes
			"neural_complexity": randi_range(2, 6),
			"connection_density": randf_range(0.3, 0.9),
			"plasticity": randf(),
			"processing_speed": randf()
		}
		
		# Calculate derived properties
		size = genes.size
		mass = genes.size * genes.size * 0.5
		vision_range = 5.0 + genes.vision_acuity * 15.0
		hearing_range = 4.0 + genes.hearing_sensitivity * 10.0
		smell_range = 3.0 + genes.smell_sensitivity * 8.0
	
	func initialize_neural_network():
		"""Create adaptive neural network based on genetic parameters"""
		var input_size = 12  # Sensory inputs
		var hidden_layers = genes.neural_complexity
		var neurons_per_layer = int(4 + genes.connection_density * 8)
		var output_size = 6  # Movement outputs
		
		neural_network = NeuralNetwork.new(
			input_size, 
			hidden_layers, 
			neurons_per_layer, 
			output_size,
			genes.plasticity
		)
		
		# Initialize with genetic biases
		neural_network.set_genetic_biases(genes)
	
	func update(delta: float, environment_data: Dictionary):
		"""Complex update with neural decision making"""
		age += delta
		
		# Sensory processing
		var sensory_input = process_sensory_input(environment_data)
		
		# Neural network decision making
		var neural_output = neural_network.forward_pass(sensory_input)
		
		# Safety check: ensure we have enough outputs
		while neural_output.size() < 6:
			neural_output.append(0.5)  # Default neutral values
		
		# Interpret neural output as behaviors
		var movement_vector = Vector3(
			neural_output[0] * 2.0 - 1.0,  # X movement
			neural_output[1] * 0.5 - 0.25,  # Y movement (reduced)
			neural_output[2] * 2.0 - 1.0   # Z movement
		)
		
		var desired_speed = neural_output[3] * genes.speed
		var turn_rate = (neural_output[4] * 2.0 - 1.0) * genes.agility
		var action_intensity = neural_output[5]
		
		# Apply environmental physics
		apply_movement(movement_vector, desired_speed, turn_rate, delta, environment_data)
		
		# Behavioral state machine
		update_behavior_state(neural_output, environment_data)
		
		# Learning and adaptation
		if neural_network.learning_enabled:
			neural_network.update_weights(get_learning_signals())
		
		# Energy management
		update_energy(delta, action_intensity)
		
		# Social interactions
		process_social_interactions(environment_data)
		
		# Memory formation
		update_memory(sensory_input, neural_output)
		
		# Fitness calculation
		calculate_fitness(delta, environment_data)
	
	func process_sensory_input(environment_data: Dictionary) -> Array:
		"""Process environmental information through sensory systems"""
		var inputs = []
		
		# Spatial awareness
		inputs.append(position.x / 15.0)  # Normalized position
		inputs.append(position.z / 15.0)
		inputs.append(velocity.length() / genes.speed)  # Normalized velocity
		
		# Environmental sensors
		inputs.append(detect_food_sources(environment_data))
		inputs.append(detect_threats(environment_data))
		inputs.append(detect_mates(environment_data))
		
		# Internal state
		inputs.append(energy / 100.0)  # Normalized energy
		inputs.append(age / 60.0)      # Normalized age
		inputs.append(float(reproduction_count) / 10.0)  # Reproduction history
		
		# Social context
		inputs.append(detect_population_density(environment_data))
		inputs.append(detect_pheromones(environment_data))
		
		# Environmental conditions
		inputs.append(environment_data.get("temperature", 0.5))
		
		return inputs
	
	func detect_food_sources(environment_data: Dictionary) -> float:
		"""Detect nearby food sources"""
		var food_signal = 0.0
		var food_sources = environment_data.get("food_sources", [])
		
		for food in food_sources:
			var distance = position.distance_to(food.position)
			if distance < vision_range:
				food_signal += (1.0 - distance / vision_range) * food.nutritional_value
		
		return clamp(food_signal, 0.0, 1.0)
	
	func detect_threats(environment_data: Dictionary) -> float:
		"""Detect predators and hazards"""
		var threat_level = 0.0
		var threats = environment_data.get("threats", [])
		
		for threat in threats:
			var distance = position.distance_to(threat.position)
			if distance < hearing_range:
				threat_level += (1.0 - distance / hearing_range) * threat.danger_level
		
		return clamp(threat_level, 0.0, 1.0)
	
	func detect_mates(environment_data: Dictionary) -> float:
		"""Detect potential mates"""
		var mate_signal = 0.0
		var creatures = environment_data.get("population", [])
		
		if energy > 50.0:  # reproduction_threshold
			for creature in creatures:
				if creature != self and creature.species_id == species_id:
					var distance = position.distance_to(creature.position)
					if distance < smell_range:
						mate_signal += (1.0 - distance / smell_range) * creature.fitness
		
		return clamp(mate_signal, 0.0, 1.0)
	
	func detect_population_density(environment_data: Dictionary) -> float:
		"""Assess local population density"""
		var nearby_count = 0
		var creatures = environment_data.get("population", [])
		
		for creature in creatures:
			if creature != self and position.distance_to(creature.position) < vision_range:
				nearby_count += 1
		
		return clamp(float(nearby_count) / 10.0, 0.0, 1.0)
	
	func detect_pheromones(environment_data: Dictionary) -> float:
		"""Detect chemical signals"""
		var pheromone_strength = 0.0
		var pheromones = environment_data.get("pheromones", {})
		
		for pheromone_type in pheromones:
			var trails = pheromones[pheromone_type]
			for trail in trails:
				var distance = position.distance_to(trail.position)
				if distance < smell_range:
					pheromone_strength += trail.intensity * (1.0 - distance / smell_range)
		
		return clamp(pheromone_strength, 0.0, 1.0)
	
	func apply_movement(movement_vector: Vector3, desired_speed: float, turn_rate: float, delta: float, environment_data: Dictionary):
		"""Apply physics-based movement with environmental constraints"""
		
		# Environmental forces
		var environment_force = Vector3.ZERO
		var boundaries = environment_data.get("boundaries", {"size": 30.0})
		var boundary_size = boundaries.size / 2.0
		
		# Boundary repulsion
		if abs(position.x) > boundary_size - 3.0:
			environment_force.x = -sign(position.x) * 5.0
		if abs(position.z) > boundary_size - 3.0:
			environment_force.z = -sign(position.z) * 5.0
		
		# Obstacle avoidance
		var obstacles = environment_data.get("obstacles", [])
		for obstacle in obstacles:
			var distance = position.distance_to(obstacle.position)
			if distance < obstacle.radius + 2.0:
				var avoid_dir = (position - obstacle.position).normalized()
				environment_force += avoid_dir * (3.0 - distance) * 2.0
		
		# Apply movement
		var target_velocity = movement_vector.normalized() * desired_speed
		target_velocity += environment_force
		
		# Smooth velocity changes
		velocity = velocity.lerp(target_velocity, delta * genes.agility)
		
		# Update position
		position += velocity * delta
		
		# Ground constraint
		position.y = max(0.1, position.y)
		
		# Angular movement
		angular_velocity += turn_rate * delta
		angular_velocity = lerp(angular_velocity, 0.0, delta * 2.0)
	
	func update_behavior_state(neural_output: Array, environment_data: Dictionary):
		"""Update behavioral state based on neural decisions and environment"""
		var behavior_weights = {
			"exploring": neural_output[0] * genes.exploration,
			"hunting": neural_output[1] * (1.0 - genes.social_tendency),
			"fleeing": neural_output[2] * (1.0 - genes.risk_taking),
			"reproducing": neural_output[3] * genes.reproduction_drive,
			"socializing": neural_output[4] * genes.social_tendency,
			"resting": neural_output[5] * (1.0 - energy / 100.0)
		}
		
		# Find dominant behavior
		var max_weight = 0.0
		var new_behavior = "exploring"
		
		for behavior in behavior_weights:
			if behavior_weights[behavior] > max_weight:
				max_weight = behavior_weights[behavior]
				new_behavior = behavior
		
		# State transition logic
		if new_behavior != behavior_state:
			behavior_state = new_behavior
			# Trigger behavior-specific actions
			match behavior_state:
				"hunting":
					release_pheromone("hunting", 0.8)
				"fleeing":
					release_pheromone("alarm", 1.0)
				"reproducing":
					release_pheromone("mating", 0.6)
				"socializing":
					release_pheromone("social", 0.4)
	
	func release_pheromone(pheromone_type: String, intensity: float):
		"""Release chemical signals"""
		# This would be handled by the main ecosystem
		pass
	
	func update_energy(delta: float, action_intensity: float):
		"""Complex energy management"""
		var base_metabolism = genes.size * 0.5 + (1.0 - genes.energy_efficiency) * 0.3
		var movement_cost = velocity.length() * genes.size * 0.1
		var neural_cost = neural_network.get_processing_cost() * 0.05
		var action_cost = action_intensity * genes.strength * 0.1
		
		var total_cost = (base_metabolism + movement_cost + neural_cost + action_cost) * delta
		
		energy -= total_cost
		energy = max(0.0, energy)
		
		# Death condition
		if energy <= 0.0 or age > 60.0 * genes.longevity:  # age_limit
			fitness *= 0.5  # Death penalty
	
	func calculate_fitness(delta: float, environment_data: Dictionary):
		"""Advanced fitness calculation with multiple objectives"""
		var survival_fitness = age * 2.0
		var energy_fitness = energy * 0.1
		var reproduction_fitness = reproduction_count * 20.0
		var exploration_fitness = trail_points.size() * 0.1
		var social_fitness = social_connections.size() * 5.0
		var behavioral_fitness = get_behavioral_diversity_score() * 10.0
		
		# Environmental adaptation bonus
		var adaptation_bonus = 0.0
		if behavior_state == "hunting" and detect_food_sources(environment_data) > 0.5:
			adaptation_bonus += 5.0
		if behavior_state == "fleeing" and detect_threats(environment_data) > 0.5:
			adaptation_bonus += 5.0
		
		fitness = survival_fitness + energy_fitness + reproduction_fitness + exploration_fitness + social_fitness + behavioral_fitness + adaptation_bonus
		
		# Normalize
		fitness = max(0.0, fitness)
	
	func get_behavioral_diversity_score() -> float:
		"""Calculate behavioral diversity metric"""
		return float(learned_behaviors.size()) * genes.learning_rate
	
	func crossover(partner) -> EvolutionaryCreature:
		"""Advanced crossover with multiple inheritance patterns"""
		var child = EvolutionaryCreature.new()
		
		# Genetic crossover with multiple patterns
		for gene in genes.keys():
			var inheritance_pattern = randf()
			
			if inheritance_pattern < 0.4:  # Simple blend
				child.genes[gene] = (genes[gene] + partner.genes[gene]) / 2.0
			elif inheritance_pattern < 0.7:  # Dominant/recessive
				child.genes[gene] = genes[gene] if randf() < 0.6 else partner.genes[gene]
			else:  # Novel combination
				var variance = abs(genes[gene] - partner.genes[gene]) * 0.3
				child.genes[gene] = (genes[gene] + partner.genes[gene]) / 2.0 + randf_range(-variance, variance)
		
		# Neural network crossover
		child.neural_network = neural_network.crossover_with(partner.neural_network)
		
		# Epigenetic inheritance
		if true:  # epigenetic_inheritance enabled
			child.inherit_learned_behaviors(self, partner)
		
		child.generation_born = generation_born + 1
		return child
	
	func inherit_learned_behaviors(parent1, parent2):
		"""Inherit learned behaviors from parents"""
		# Combine learned behaviors from both parents
		for behavior in parent1.learned_behaviors:
			if randf() < 0.3:  # 30% chance to inherit
				learned_behaviors[behavior] = parent1.learned_behaviors[behavior]
		
		for behavior in parent2.learned_behaviors:
			if randf() < 0.3:
				learned_behaviors[behavior] = parent2.learned_behaviors[behavior]
	
	func mutate(mutation_rate: float, environmental_pressure: float):
		"""Adaptive mutation based on environmental conditions"""
		var adaptive_rate = mutation_rate * (1.0 + environmental_pressure)
		
		for gene in genes.keys():
			if randf() < adaptive_rate:
				var mutation_strength = get_mutation_strength(gene)
				var mutation_amount = randf_range(-mutation_strength, mutation_strength)
				
				genes[gene] += mutation_amount
				
				# Apply gene-specific constraints
				apply_gene_constraints(gene)
		
		# Neural network mutation
		if neural_network:
			neural_network.mutate(adaptive_rate)
	
	func get_mutation_strength(gene: String) -> float:
		"""Calculate mutation strength based on gene type and environmental pressure"""
		match gene:
			"size", "speed", "strength":
				return 0.2
			"red", "green", "blue":
				return 0.1
			"aggression", "social_tendency", "exploration":
				return 0.15
			_:
				return 0.1
	
	func apply_gene_constraints(gene: String):
		"""Apply realistic constraints to gene values"""
		match gene:
			"size":
				genes[gene] = clamp(genes[gene], 0.3, 3.0)
			"speed":
				genes[gene] = clamp(genes[gene], 0.2, 5.0)
			"red", "green", "blue":
				genes[gene] = clamp(genes[gene], 0.0, 1.0)
			_:
				genes[gene] = clamp(genes[gene], 0.0, 1.0)
	
	func process_social_interactions(environment_data: Dictionary):
		"""Handle complex social behaviors"""
		var creatures = environment_data.get("population", [])
		
		for creature in creatures:
			if creature != self and position.distance_to(creature.position) < 5.0:
				var interaction_strength = calculate_social_compatibility(creature)
				
				if interaction_strength > 0.7:
					# Positive interaction
					form_social_bond(creature)
					share_information(creature)
				elif interaction_strength < 0.3:
					# Negative interaction
					compete_for_resources(creature)
	
	func calculate_social_compatibility(other) -> float:
		"""Calculate social compatibility between creatures"""
		var genetic_similarity = calculate_genetic_similarity(other)
		var behavioral_similarity = calculate_behavioral_similarity(other)
		var size_compatibility = 1.0 - abs(genes.size - other.genes.size) / 2.0
		
		return (genetic_similarity + behavioral_similarity + size_compatibility) / 3.0
	
	func calculate_genetic_similarity(other) -> float:
		"""Calculate genetic similarity"""
		var similarity = 0.0
		var gene_count = 0
		
		for gene in genes.keys():
			if other.genes.has(gene):
				similarity += 1.0 - abs(genes[gene] - other.genes[gene])
				gene_count += 1
		
		return similarity / float(gene_count) if gene_count > 0 else 0.0
	
	func calculate_behavioral_similarity(other) -> float:
		"""Calculate behavioral similarity"""
		var behavior_match = 0.0
		var total_behaviors = 0
		
		for behavior in learned_behaviors:
			if other.learned_behaviors.has(behavior):
				behavior_match += 1.0
			total_behaviors += 1
		
		return behavior_match / float(total_behaviors) if total_behaviors > 0 else 0.0
	
	func form_social_bond(other):
		"""Form social connection"""
		if not other in social_connections:
			social_connections.append(other)
	
	func share_information(other):
		"""Share learned behaviors"""
		if true:  # cultural_transmission enabled
			for behavior in learned_behaviors:
				if randf() < 0.1 and not other.learned_behaviors.has(behavior):
					other.learned_behaviors[behavior] = learned_behaviors[behavior]
	
	func compete_for_resources(other):
		"""Competition mechanics"""
		if genes.strength > other.genes.strength:
			energy += 5.0
			other.energy -= 2.0
	
	func update_memory(sensory_input: Array, neural_output: Array):
		"""Update memory with current experience"""
		var memory_entry = {
			"timestamp": age,
			"sensory_state": sensory_input.duplicate(),
			"action_taken": neural_output.duplicate(),
			"behavior_state": behavior_state,
			"fitness_at_time": fitness
		}
		
		memory.append(memory_entry)
		
		# Memory capacity management
		var max_memory = int(genes.memory_capacity * 100)
		if memory.size() > max_memory:
			memory.pop_front()
	
	func get_learning_signals() -> Array:
		"""Generate learning signals for neural network"""
		var signals = []
		
		# Fitness-based learning
		if memory.size() > 1:
			var current_fitness = fitness
			var previous_fitness = memory[-2].fitness_at_time
			var fitness_change = current_fitness - previous_fitness
			
			signals.append(fitness_change)
		
		# Behavioral success signals
		match behavior_state:
			"hunting":
				signals.append(1.0 if energy > 70.0 else -0.5)
			"fleeing":
				signals.append(1.0 if energy > 50.0 else -0.8)
			"reproducing":
				signals.append(1.0 if reproduction_count > 0 else -0.3)
		
		return signals

# Neural Network Implementation
class NeuralNetwork:
	var layers: Array = []
	var weights: Array = []
	var biases: Array = []
	var activation_func: String = "tanh"
	var learning_rate: float = 0.1
	var learning_enabled: bool = true
	var plasticity: float = 0.5
	
	func _init(input_size: int, hidden_layers: int, neurons_per_layer: int, output_size: int, plasticity_factor: float = 0.5):
		plasticity = plasticity_factor
		learning_rate = 0.05 + plasticity * 0.1
		
		# Initialize layer sizes
		layers = [input_size]
		for i in range(hidden_layers):
			layers.append(neurons_per_layer)
		layers.append(output_size)
		
		# Initialize weights and biases
		initialize_weights()
	
	func initialize_weights():
		"""Initialize neural network weights"""
		weights = []
		biases = []
		
		for i in range(layers.size() - 1):
			var layer_weights = []
			var layer_biases = []
			
			for j in range(layers[i + 1]):
				var neuron_weights = []
				for k in range(layers[i]):
					neuron_weights.append(randf_range(-1.0, 1.0))
				layer_weights.append(neuron_weights)
				layer_biases.append(randf_range(-0.5, 0.5))
			
			weights.append(layer_weights)
			biases.append(layer_biases)
	
	func forward_pass(inputs: Array) -> Array:
		"""Forward propagation through network"""
		var current_layer = inputs.duplicate()
		
		for layer_idx in range(weights.size()):
			var next_layer = []
			
			for neuron_idx in range(weights[layer_idx].size()):
				var sum_value = biases[layer_idx][neuron_idx]
				
				for input_idx in range(current_layer.size()):
					sum_value += current_layer[input_idx] * weights[layer_idx][neuron_idx][input_idx]
				
				next_layer.append(activate(sum_value))
			
			current_layer = next_layer
		
		return current_layer
	
	func activate(x: float) -> float:
		"""Activation function"""
		match activation_func:
			"sigmoid":
				return 1.0 / (1.0 + exp(-x))
			"tanh":
				return tanh(x)
			"relu":
				return max(0.0, x)
			"leaky_relu":
				return max(0.1 * x, x)
			_:
				return tanh(x)
	
	func set_genetic_biases(genes: Dictionary):
		"""Set initial biases based on genetic traits"""
		for layer_idx in range(biases.size()):
			for neuron_idx in range(biases[layer_idx].size()):
				var genetic_influence = 0.0
				
				# Incorporate relevant genes
				if layer_idx == 0:  # Input layer biases
					genetic_influence = genes.get("exploration", 0.5) * 0.2
				elif layer_idx == biases.size() - 1:  # Output layer biases
					genetic_influence = genes.get("aggression", 0.5) * 0.2
				
				biases[layer_idx][neuron_idx] += genetic_influence
	
	func crossover_with(partner: NeuralNetwork) -> NeuralNetwork:
		"""Create offspring neural network"""
		# Calculate proper parameters from parent network structure
		var input_size = layers[0]
		var output_size = layers[-1]
		var hidden_layers = max(0, layers.size() - 2)  # Ensure non-negative
		var neurons_per_layer = layers[1] if layers.size() > 2 else output_size
		
		var child = NeuralNetwork.new(input_size, hidden_layers, neurons_per_layer, output_size, plasticity)
		
		# Crossover weights
		for layer_idx in range(weights.size()):
			for neuron_idx in range(weights[layer_idx].size()):
				for weight_idx in range(weights[layer_idx][neuron_idx].size()):
					if randf() < 0.5:
						child.weights[layer_idx][neuron_idx][weight_idx] = weights[layer_idx][neuron_idx][weight_idx]
					else:
						child.weights[layer_idx][neuron_idx][weight_idx] = partner.weights[layer_idx][neuron_idx][weight_idx]
		
		# Crossover biases
		for layer_idx in range(biases.size()):
			for neuron_idx in range(biases[layer_idx].size()):
				if randf() < 0.5:
					child.biases[layer_idx][neuron_idx] = biases[layer_idx][neuron_idx]
				else:
					child.biases[layer_idx][neuron_idx] = partner.biases[layer_idx][neuron_idx]
		
		return child
	
	func mutate(mutation_rate: float):
		"""Mutate neural network"""
		# Mutate weights
		for layer_idx in range(weights.size()):
			for neuron_idx in range(weights[layer_idx].size()):
				for weight_idx in range(weights[layer_idx][neuron_idx].size()):
					if randf() < mutation_rate:
						weights[layer_idx][neuron_idx][weight_idx] += randf_range(-0.1, 0.1)
						weights[layer_idx][neuron_idx][weight_idx] = clamp(weights[layer_idx][neuron_idx][weight_idx], -2.0, 2.0)
		
		# Mutate biases
		for layer_idx in range(biases.size()):
			for neuron_idx in range(biases[layer_idx].size()):
				if randf() < mutation_rate:
					biases[layer_idx][neuron_idx] += randf_range(-0.05, 0.05)
					biases[layer_idx][neuron_idx] = clamp(biases[layer_idx][neuron_idx], -1.0, 1.0)
	
	func update_weights(learning_signals: Array):
		"""Update weights based on learning signals"""
		if not learning_enabled or learning_signals.is_empty():
			return
		
		var avg_signal = 0.0
		for _signal in learning_signals:
			avg_signal += _signal
		avg_signal /= learning_signals.size()
		
		# Simple weight adjustment based on performance
		for layer_idx in range(weights.size()):
			for neuron_idx in range(weights[layer_idx].size()):
				for weight_idx in range(weights[layer_idx][neuron_idx].size()):
					weights[layer_idx][neuron_idx][weight_idx] += avg_signal * learning_rate * randf_range(-0.1, 0.1)
					weights[layer_idx][neuron_idx][weight_idx] = clamp(weights[layer_idx][neuron_idx][weight_idx], -2.0, 2.0)
	
	func get_processing_cost() -> float:
		"""Calculate computational cost of neural processing"""
		var cost = 0.0
		for layer_size in layers:
			cost += layer_size * 0.01
		return cost

# Food source class for ecosystem
class FoodSource:
	var position: Vector3
	var nutritional_value: float
	var regeneration_rate: float
	var current_amount: float
	var max_amount: float
	var mesh_instance: MeshInstance3D
	
	func _init(pos: Vector3, nutrition: float = 1.0):
		position = pos
		nutritional_value = nutrition
		regeneration_rate = 0.1
		max_amount = 10.0
		current_amount = max_amount
	
	func update(delta: float):
		current_amount = min(max_amount, current_amount + regeneration_rate * delta)
	
	func consume(amount: float) -> float:
		var consumed = min(amount, current_amount)
		current_amount -= consumed
		return consumed * nutritional_value

# EcosystemPredator class for ecosystem dynamics
class EcosystemPredator:
	var position: Vector3
	var velocity: Vector3
	var hunting_range: float
	var danger_level: float
	var mesh_instance: MeshInstance3D
	
	func _init(pos: Vector3):
		position = pos
		velocity = Vector3.ZERO
		hunting_range = 15.0
		danger_level = 1.0
	
	func update(delta: float, prey_positions: Array):
		# Simple predator AI - move towards nearest prey
		var nearest_prey = null
		var nearest_distance = INF
		
		for prey_pos in prey_positions:
			var distance = position.distance_to(prey_pos)
			if distance < nearest_distance and distance < hunting_range:
				nearest_distance = distance
				nearest_prey = prey_pos
		
		if nearest_prey:
			var direction = (nearest_prey - position).normalized()
			velocity = velocity.lerp(direction * 3.0, delta * 2.0)
			position += velocity * delta

# Species management
class Species:
	var id: int
	var members: Array = []
	var representative: EvolutionaryCreature
	var color: Color
	var generation_created: int
	var traits: Dictionary = {}
	var behavioral_patterns: Array = []
	
	func _init(species_id: int, founder: EvolutionaryCreature):
		id = species_id
		representative = founder
		members = [founder]
		color = Color(randf(), randf(), randf())
		generation_created = founder.generation_born
		analyze_species_traits()
	
	func analyze_species_traits():
		"""Analyze common traits of species members"""
		if members.is_empty():
			return
		
		# Calculate average traits
		traits = {}
		for member in members:
			for gene in member.genes:
				if not traits.has(gene):
					traits[gene] = 0.0
				traits[gene] += member.genes[gene]
		
		# Average the traits
		for _trait in traits:
			traits[_trait] /= members.size()
	
	func add_member(creature: EvolutionaryCreature):
		members.append(creature)
		creature.species_id = id
		analyze_species_traits()
	
	func remove_member(creature: EvolutionaryCreature):
		members.erase(creature)
		if members.is_empty():
			return false  # Species extinct
		
		# Update representative if needed
		if creature == representative and not members.is_empty():
			representative = members[0]
		
		analyze_species_traits()
		return true
	
	func calculate_genetic_distance(creature: EvolutionaryCreature) -> float:
		"""Calculate genetic distance from species representative"""
		var distance = 0.0
		var gene_count = 0
		
		for gene in representative.genes:
			if creature.genes.has(gene):
				distance += abs(representative.genes[gene] - creature.genes[gene])
				gene_count += 1
		
		return distance / gene_count if gene_count > 0 else 0.0

# Main ecosystem functions
func _ready():
	setup_environment()
	initialize_ecosystem()
	initialize_population()
	setup_ui()
	setup_performance_tracking()
	
	# Initialize queer forms detector
	if queer_forms_detection:
		queer_forms_detector = QueerFormsDetector.new()
		print("Queer forms detector initialized")

func _process(delta):
	update_environment(delta)
	update_ecosystem(delta)
	update_creatures(delta)
	update_species_dynamics(delta)
	update_generation_timer(delta)
	update_visualizations(delta)
	update_ui()

func setup_environment():
	"""Setup the 3D environment"""
	environment = Node3D.new()
	environment.name = "EcosystemEnvironment"
	add_child(environment)
	
	# Advanced lighting system
	var main_light = DirectionalLight3D.new()
	main_light.light_energy = 1.0
	main_light.rotation_degrees = Vector3(-45, 30, 0)
	main_light.shadow_enabled = true
	add_child(main_light)
	
	# Ambient lighting
	var ambient_light = DirectionalLight3D.new()
	ambient_light.light_energy = 0.3
	ambient_light.rotation_degrees = Vector3(45, -30, 0)
	add_child(ambient_light)
	
	# Environment settings
	var env = WorldEnvironment.new()
	var environment_resource = Environment.new()
	environment_resource.background_mode = Environment.BG_COLOR
	environment_resource.background_color = Color(0.05, 0.1, 0.15)
	environment_resource.ambient_light_color = Color(0.4, 0.4, 0.5)
	environment_resource.ambient_light_energy = 0.4
	environment_resource.fog_enabled = true
	environment_resource.fog_light_color = Color(0.3, 0.4, 0.5)
	environment_resource.fog_light_energy = 0.2
	environment_resource.fog_density = 0.01
	env.environment = environment_resource
	add_child(env)
	
	# Terrain
	create_terrain()
	
	# Fitness landscape visualization
	if show_fitness_landscape:
		create_fitness_landscape()

func create_terrain():
	"""Create complex terrain with various features"""
	# Main ground
	var ground = MeshInstance3D.new()
	ground.mesh = PlaneMesh.new()
	ground.mesh.size = Vector2(environment_size, environment_size)
	
	var ground_material = StandardMaterial3D.new()
	ground_material.albedo_color = Color(0.2, 0.4, 0.2)
	ground_material.roughness = 0.8
	ground_material.metallic = 0.1
	ground.material_override = ground_material
	environment.add_child(ground)
	
	# Add terrain features
	create_terrain_features()

func create_terrain_features():
	"""Add rocks, hills, and other terrain features"""
	# Rocks and obstacles
	for i in range(15):
		var rock = MeshInstance3D.new()
		rock.mesh = SphereMesh.new()
		rock.mesh.radius = randf_range(0.5, 2.0)
		rock.mesh.height = rock.mesh.radius * 2
		
		var rock_material = StandardMaterial3D.new()
		rock_material.albedo_color = Color(0.3, 0.3, 0.3)
		rock_material.roughness = 0.9
		rock.material_override = rock_material
		
		rock.position = Vector3(
			randf_range(-environment_size/2 + 3, environment_size/2 - 3),
			rock.mesh.radius,
			randf_range(-environment_size/2 + 3, environment_size/2 - 3)
		)
		
		environment.add_child(rock)
	
	# Hills
	for i in range(8):
		var hill = MeshInstance3D.new()
		hill.mesh = SphereMesh.new()
		hill.mesh.radius = randf_range(3.0, 6.0)
		hill.mesh.height = hill.mesh.radius * 0.5
		
		var hill_material = StandardMaterial3D.new()
		hill_material.albedo_color = Color(0.15, 0.35, 0.15)
		hill_material.roughness = 0.7
		hill.material_override = hill_material
		
		hill.position = Vector3(
			randf_range(-environment_size/2 + 5, environment_size/2 - 5),
			hill.mesh.height * 0.3,
			randf_range(-environment_size/2 + 5, environment_size/2 - 5)
		)
		
		environment.add_child(hill)

func create_fitness_landscape():
	"""Create visual representation of fitness landscape"""
	fitness_landscape_mesh = MeshInstance3D.new()
	fitness_landscape_mesh.name = "FitnessLandscape"
	
	# Create height map based on current fitness distribution
	var plane_mesh = PlaneMesh.new()
	plane_mesh.size = Vector2(environment_size, environment_size)
	plane_mesh.subdivide_width = 50
	plane_mesh.subdivide_depth = 50
	
	fitness_landscape_mesh.mesh = plane_mesh
	
	var landscape_material = StandardMaterial3D.new()
	landscape_material.albedo_color = Color(0.1, 0.3, 0.8, 0.3)
	landscape_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	landscape_material.wireframe = true
	fitness_landscape_mesh.material_override = landscape_material
	
	fitness_landscape_mesh.position.y = 5.0
	environment.add_child(fitness_landscape_mesh)

func initialize_ecosystem():
	"""Initialize food sources, predators, and environmental factors"""
	# Food sources
	food_sources_array = []
	for i in range(food_sources):
		var food_pos = Vector3(
			randf_range(-environment_size/2 + 2, environment_size/2 - 2),
			0.5,
			randf_range(-environment_size/2 + 2, environment_size/2 - 2)
		)
		
		var food = FoodSource.new(food_pos, randf_range(0.5, 2.0))
		food_sources_array.append(food)
		
		# Visual representation
		var food_mesh = MeshInstance3D.new()
		food_mesh.mesh = SphereMesh.new()
		food_mesh.mesh.radius = 0.3
		
		var food_material = StandardMaterial3D.new()
		food_material.albedo_color = Color(0.8, 0.6, 0.2)
		food_material.emission_enabled = true
		food_material.emission = Color(0.4, 0.3, 0.1)
		food_mesh.material_override = food_material
		
		food_mesh.position = food_pos
		food.mesh_instance = food_mesh
		environment.add_child(food_mesh)
	
	# Predators
	if predator_prey_enabled:
		predators = []
		for i in range(3):
			var predator_pos = Vector3(
				randf_range(-environment_size/2, environment_size/2),
				1.0,
				randf_range(-environment_size/2, environment_size/2)
			)
			
			var predator = EcosystemPredator.new(predator_pos)
			predators.append(predator)
			
			# Visual representation
			var predator_mesh = MeshInstance3D.new()
			predator_mesh.mesh = BoxMesh.new()
			predator_mesh.mesh.size = Vector3(1.5, 1.0, 3.0)
			
			var predator_material = StandardMaterial3D.new()
			predator_material.albedo_color = Color(0.8, 0.2, 0.2)
			predator_material.emission_enabled = true
			predator_material.emission = Color(0.4, 0.1, 0.1)
			predator_mesh.material_override = predator_material
			
			predator_mesh.position = predator_pos
			predator.mesh_instance = predator_mesh
			environment.add_child(predator_mesh)
	
	# Environmental factors
	environmental_factors = {
		"temperature": 0.5,
		"humidity": 0.5,
		"resource_availability": 1.0,
		"predator_activity": 0.3,
		"seasonal_cycle": 0.0
	}
	
	# Initialize pheromone trails
	pheromone_trails = {
		"hunting": [],
		"alarm": [],
		"mating": [],
		"social": []
	}

func initialize_population():
	"""Initialize the creature population with species diversity"""
	population = []
	creatures = []
	species_groups = []
	
	for i in range(population_size):
		var creature = EvolutionaryCreature.new()
		creature.generation_born = 0
		population.append(creature)
		
		# Assign to species
		assign_to_species(creature)
		
		# Create visual representation
		create_creature_visual(creature)

func assign_to_species(creature: EvolutionaryCreature):
	"""Assign creature to appropriate species or create new one"""
	if not speciation_enabled:
		creature.species_id = 0
		return
	
	# Find compatible species
	for species in species_groups:
		if species.calculate_genetic_distance(creature) < species_threshold:
			species.add_member(creature)
			return
	
	# Create new species
	var new_species = Species.new(species_groups.size(), creature)
	species_groups.append(new_species)
	print("EcosystemEvolution: New species created - ID: %d, Members: %d" % [new_species.id, new_species.members.size()])

func create_creature_visual(creature: EvolutionaryCreature):
	"""Create sophisticated visual representation of creature"""
	var mesh_instance = MeshInstance3D.new()
	
	# Create complex mesh based on genes
	var mesh = create_creature_mesh(creature)
	mesh_instance.mesh = mesh
	
	# Create material based on genetic traits
	var material = StandardMaterial3D.new()
	
	# Base color from genes
	var base_color = Color(
		creature.genes.red,
		creature.genes.green,
		creature.genes.blue
	)
	
	# Species coloring
	if show_species_colors and creature.species_id < species_groups.size():
		var species_color = species_groups[creature.species_id].color
		base_color = base_color.lerp(species_color, 0.4)
	
	material.albedo_color = base_color
	
	# Genetic traits affecting material properties
	material.roughness = 0.3 + creature.genes.get("roughness", 0.5) * 0.4
	material.metallic = creature.genes.get("metallic", 0.1) * 0.3
	
	# Bioluminescence
	if creature.genes.luminescence > 0.7:
		material.emission_enabled = true
		material.emission = base_color * creature.genes.luminescence * 0.5
	
	# Pattern complexity (using textures or normal maps could be added here)
	if creature.genes.pattern_complexity > 0.5:
		material.albedo_color = material.albedo_color.lerp(Color.WHITE, 0.2)
	
	mesh_instance.material_override = material
	mesh_instance.position = creature.position
	
	# Add to scene
	creature.mesh_instance = mesh_instance
	environment.add_child(mesh_instance)
	creatures.append(creature)
	
	# Create neural network visualization
	if show_neural_connections:
		create_neural_visualization(creature)

func create_creature_mesh(creature: EvolutionaryCreature) -> Mesh:
	"""Create mesh based on creature's genetic traits"""
	var mesh
	
	# Body shape based on genes
	if creature.genes.size < 1.0:
		# Small creatures are more spherical
		mesh = SphereMesh.new()
		mesh.radius = creature.genes.size * 0.5
		mesh.height = creature.genes.size
	elif creature.genes.size > 1.8:
		# Large creatures are more box-like
		mesh = BoxMesh.new()
		mesh.size = Vector3(creature.genes.size, creature.genes.size * 0.8, creature.genes.size * 1.2)
	else:
		# Medium creatures are capsule-shaped
		mesh = CapsuleMesh.new()
		mesh.radius = creature.genes.size * 0.4
		mesh.height = creature.genes.size * 1.2
	
	return mesh

func create_neural_visualization(creature: EvolutionaryCreature):
	"""Create visualization of creature's neural network"""
	var neural_display = Node3D.new()
	neural_display.name = "NeuralDisplay"
	
	# Create simple neural network visualization
	var input_layer_pos = Vector3(0, 2, 0)
	var output_layer_pos = Vector3(0, 2, 2)
	
	# Input nodes
	for i in range(3):  # Simplified - show only 3 input nodes
		var input_node = MeshInstance3D.new()
		input_node.mesh = SphereMesh.new()
		input_node.mesh.radius = 0.1
		
		var node_material = StandardMaterial3D.new()
		node_material.albedo_color = Color(0.2, 0.8, 0.2)
		node_material.emission_enabled = true
		node_material.emission = Color(0.1, 0.4, 0.1)
		input_node.material_override = node_material
		
		input_node.position = input_layer_pos + Vector3(i * 0.3 - 0.3, 0, 0)
		neural_display.add_child(input_node)
	
	# Output nodes
	for i in range(3):  # Simplified - show only 3 output nodes
		var output_node = MeshInstance3D.new()
		output_node.mesh = SphereMesh.new()
		output_node.mesh.radius = 0.1
		
		var node_material = StandardMaterial3D.new()
		node_material.albedo_color = Color(0.8, 0.2, 0.2)
		node_material.emission_enabled = true
		node_material.emission = Color(0.4, 0.1, 0.1)
		output_node.material_override = node_material
		
		output_node.position = output_layer_pos + Vector3(i * 0.3 - 0.3, 0, 0)
		neural_display.add_child(output_node)
	
	# Neural connections (simplified representation)
	for i in range(3):
		for j in range(3):
			var connection = MeshInstance3D.new()
			connection.mesh = CylinderMesh.new()
			connection.mesh.height = 2.0
			connection.mesh.top_radius = 0.02
			connection.mesh.bottom_radius = 0.02
			
			var connection_material = StandardMaterial3D.new()
			connection_material.albedo_color = Color(0.5, 0.5, 1.0, 0.6)
			connection_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			connection.material_override = connection_material
			
			connection.position = (input_layer_pos + output_layer_pos) / 2 + Vector3(i * 0.1, 0, 0)
			connection.rotation_degrees = Vector3(0, 0, 45)
			neural_display.add_child(connection)
	
	creature.neural_display = neural_display
	creature.mesh_instance.add_child(neural_display)

func update_environment(delta: float):
	"""Update environmental conditions"""
	# Seasonal cycle
	environmental_factors.seasonal_cycle += delta * 0.1
	if environmental_factors.seasonal_cycle > 2.0 * PI:
		environmental_factors.seasonal_cycle = 0.0
	
	# Dynamic temperature
	environmental_factors.temperature = 0.5 + sin(environmental_factors.seasonal_cycle) * 0.3
	
	# Resource availability fluctuations
	environmental_factors.resource_availability = 0.7 + sin(environmental_factors.seasonal_cycle * 0.5) * 0.3
	
	# Predator activity cycles
	environmental_factors.predator_activity = 0.3 + sin(environmental_factors.seasonal_cycle * 2.0) * 0.2

func update_ecosystem(delta: float):
	"""Update ecosystem components"""
	# Update food sources
	for food in food_sources_array:
		food.update(delta)
		
		# Update visual representation
		if food.mesh_instance:
			var scale_factor = food.current_amount / food.max_amount
			food.mesh_instance.scale = Vector3.ONE * (0.3 + scale_factor * 0.7)
	
	# Update predators
	for predator in predators:
		var prey_positions = []
		for creature in creatures:
			if creature.energy > 0:
				prey_positions.append(creature.position)
		
		predator.update(delta, prey_positions)
		
		if predator.mesh_instance:
			predator.mesh_instance.position = predator.position
	
	# Update pheromone trails
	update_pheromone_trails(delta)

func update_pheromone_trails(delta: float):
	"""Update pheromone trail decay and visualization"""
	for trail_type in pheromone_trails:
		var trails = pheromone_trails[trail_type]
		for i in range(trails.size() - 1, -1, -1):
			var trail = trails[i]
			trail.intensity -= delta * 0.5  # Decay rate
			
			if trail.intensity <= 0:
				trails.remove_at(i)
				# Remove visual representation if exists
				if trail.has("mesh_instance") and trail.mesh_instance:
					trail.mesh_instance.queue_free()

func update_creatures(delta: float):
	"""Update all creatures with ecosystem context"""
	var environment_data = {
		"food_sources": food_sources_array,
		"threats": predators,
		"population": creatures,
		"boundaries": {"size": environment_size},
		"pheromones": pheromone_trails,
		"environmental_factors": environmental_factors,
		"obstacles": []  # Could add terrain obstacles here
	}
	
	# Update each creature
	for i in range(creatures.size() - 1, -1, -1):
		var creature = creatures[i]
		
		if creature.energy > 0 and creature.age < age_limit * creature.genes.longevity:
			creature.update(delta, environment_data)
			
			# Update visual position
			if creature.mesh_instance:
				creature.mesh_instance.position = creature.position
				
				# Update neural network visualization
				if show_neural_connections and creature.neural_display:
					update_neural_visualization(creature)
			
			# Trail visualization
			if trail_visualization:
				# Trail update handled by the function at line 2387
				update_creature_trail(creature)
			
			# Handle reproduction
			if creature.energy > reproduction_threshold and creature.age > 20.0:
				attempt_reproduction(creature, environment_data)
		
		else:
			# Creature died
			handle_creature_death(creature, i)

# Note: update_neural_visualization function is implemented at line 2498

# Note: update_creature_trail function is implemented at line 2388

func attempt_reproduction(creature: EvolutionaryCreature, environment_data: Dictionary):
	"""Handle creature reproduction"""
	var potential_mates = []
	
	# Find potential mates
	for other_creature in creatures:
		if other_creature != creature and other_creature.species_id == creature.species_id:
			var distance = creature.position.distance_to(other_creature.position)
			if distance < 3.0 and other_creature.energy > reproduction_threshold:
				potential_mates.append(other_creature)
	
	if potential_mates.size() > 0:
		var mate = potential_mates[randi() % potential_mates.size()]
		var offspring = create_offspring(creature, mate)
		
		if offspring:
			# Reduce parent energy
			creature.energy -= 30.0
			mate.energy -= 30.0
			
			# Increase reproduction count
			creature.reproduction_count += 1
			mate.reproduction_count += 1
			
			print("EcosystemEvolution: Reproduction successful - Generation %d" % offspring.generation_born)

func create_offspring(parent1: EvolutionaryCreature, parent2: EvolutionaryCreature) -> EvolutionaryCreature:
	"""Create offspring from two parents"""
	if population.size() >= population_size * 2:  # Population limit
		return null
	
	var offspring = parent1.crossover(parent2)
	offspring.mutate(mutation_rate, environmental_pressure)
	
	# Place offspring near parents
	var parent_center = (parent1.position + parent2.position) / 2.0
	offspring.position = parent_center + Vector3(
		randf_range(-2.0, 2.0),
		0,
		randf_range(-2.0, 2.0)
	)
	
	population.append(offspring)
	assign_to_species(offspring)
	create_creature_visual(offspring)
	
	return offspring

func handle_creature_death(creature: EvolutionaryCreature, index: int):
	"""Handle creature death and cleanup"""
	# Remove from species
	if creature.species_id < species_groups.size():
		var species = species_groups[creature.species_id]
		if not species.remove_member(creature):
			# Species went extinct
			print("EcosystemEvolution: Species %d went extinct" % creature.species_id)
	
	# Remove visual representation
	if creature.mesh_instance:
		creature.mesh_instance.queue_free()
	
	# Remove from arrays
	creatures.remove_at(index)
	population.erase(creature)
	
	print("EcosystemEvolution: Creature died - Age: %.1f, Fitness: %.1f" % [creature.age, creature.fitness])

func update_species_dynamics(delta: float):
	"""Update species-level dynamics"""
	if not speciation_enabled:
		return
	
	# Remove extinct species
	for i in range(species_groups.size() - 1, -1, -1):
		if species_groups[i].members.is_empty():
			species_groups.remove_at(i)
	
	# Update species traits
	for species in species_groups:
		species.analyze_species_traits()

func update_generation_timer(delta: float):
	"""Update generation timer and trigger evolution"""
	generation_timer += delta
	
	if generation_timer >= generation_time:
		evolve_population()
		generation_timer = 0.0

func evolve_population():
	"""Advanced evolution with speciation and environmental pressure"""
	print("EcosystemEvolution: Starting evolution - Generation %d" % generation)
	
	# Calculate fitness statistics
	calculate_fitness_stats()
	
	# Record performance metrics
	record_performance_metrics()
	
	# Environmental pressure changes
	if fitness_landscape_evolution:
		update_fitness_landscape()
	
	# Species-based evolution
	if speciation_enabled:
		evolve_species()
	else:
		evolve_traditional()
	
	generation += 1
	print("EcosystemEvolution: Evolution complete - Generation %d, Species: %d, Best Fitness: %.2f" % [generation, species_groups.size(), best_fitness])

func evolve_species():
	"""Evolve each species separately"""
	var new_population = []
	
	for species in species_groups:
		if species.members.is_empty():
			continue
		
		# Sort species members by fitness
		species.members.sort_custom(func(a, b): return a.fitness > b.fitness)
		
		# Calculate species fitness sharing
		var species_fitness = 0.0
		for member in species.members:
			species_fitness += member.fitness
		var avg_species_fitness = species_fitness / species.members.size()
		
		# Determine offspring allocation based on species performance
		var species_size = species.members.size()
		var offspring_quota = max(2, int(species_size * (avg_species_fitness / (best_fitness + 1.0))))
		
		# Elite selection within species
		var elite_count_species = max(1, int(species_size * 0.2))
		for i in range(min(elite_count_species, species.members.size())):
			new_population.append(species.members[i])
		
		# Generate offspring for this species
		var offspring_created = 0
		while offspring_created < offspring_quota and new_population.size() < population_size:
			var parent1 = select_parent_from_species(species)
			var parent2 = select_parent_from_species(species)
			
			if parent1 and parent2:
				var child = parent1.crossover(parent2)
				child.mutate(get_adaptive_mutation_rate(species), environmental_pressure)
				child.generation_born = generation + 1
				new_population.append(child)
				offspring_created += 1
	
	# Fill remaining population with inter-species crossover
	while new_population.size() < population_size:
		var species1 = species_groups[randi() % species_groups.size()]
		var species2 = species_groups[randi() % species_groups.size()]
		
		var parent1 = select_parent_from_species(species1)
		var parent2 = select_parent_from_species(species2)
		
		if parent1 and parent2:
			var child = parent1.crossover(parent2)
			child.mutate(mutation_rate * 1.5, environmental_pressure)  # Higher mutation for inter-species
			child.generation_born = generation + 1
			new_population.append(child)
	
	# Replace old population
	replace_population(new_population)

func evolve_traditional():
	"""Traditional genetic algorithm evolution"""
	# Sort by fitness
	population.sort_custom(func(a, b): return a.fitness > b.fitness)
	
	var new_population = []
	
	# Elite selection
	for i in range(min(elite_count, population.size())):
		new_population.append(population[i])
	
	# Generate offspring
	while new_population.size() < population_size:
		var parent1 = select_parent_tournament()
		var parent2 = select_parent_tournament()
		
		if randf() < crossover_rate:
			var child = parent1.crossover(parent2)
			child.mutate(get_adaptive_mutation_rate_individual(parent1, parent2), environmental_pressure)
			child.generation_born = generation + 1
			new_population.append(child)
		else:
			# Mutation only
			var child = parent1.crossover(parent1)  # Self-reproduction
			child.mutate(mutation_rate * 2.0, environmental_pressure)
			child.generation_born = generation + 1
			new_population.append(child)
	
	# Replace old population
	replace_population(new_population)

func select_parent_from_species(species: Species):
	"""Select parent from specific species using tournament selection"""
	if species.members.is_empty():
		return null
	
	var tournament_size = min(3, species.members.size())
	var best_candidate = null
	var best_fitness = -1.0
	
	for i in range(tournament_size):
		var candidate = species.members[randi() % species.members.size()]
		if candidate.fitness > best_fitness:
			best_fitness = candidate.fitness
			best_candidate = candidate
	
	return best_candidate

func select_parent_tournament():
	"""Tournament selection from entire population"""
	var tournament_size = min(5, population.size())
	var best_candidate = null
	var best_fitness = -1.0
	
	for i in range(tournament_size):
		var candidate = population[randi() % population.size()]
		if candidate.fitness > best_fitness:
			best_fitness = candidate.fitness
			best_candidate = candidate
	
	return best_candidate

func get_adaptive_mutation_rate(species: Species) -> float:
	"""Calculate adaptive mutation rate based on species diversity"""
	if not adaptive_mutation:
		return mutation_rate
	
	var diversity = calculate_species_diversity(species)
	var base_rate = mutation_rate
	
	# Increase mutation rate for low diversity species
	if diversity < 0.3:
		base_rate *= 1.5
	elif diversity > 0.7:
		base_rate *= 0.7
	
	return base_rate

func get_adaptive_mutation_rate_individual(parent1: EvolutionaryCreature, parent2: EvolutionaryCreature) -> float:
	"""Calculate adaptive mutation rate for individual crossover"""
	if not adaptive_mutation:
		return mutation_rate
	
	var genetic_distance = calculate_genetic_distance(parent1, parent2)
	var base_rate = mutation_rate
	
	# Increase mutation for genetically similar parents
	if genetic_distance < 0.2:
		base_rate *= 1.3
	elif genetic_distance > 0.8:
		base_rate *= 0.8
	
	return base_rate

func calculate_species_diversity(species: Species) -> float:
	"""Calculate genetic diversity within species"""
	if species.members.size() < 2:
		return 0.0
	
	var total_diversity = 0.0
	var comparisons = 0
	
	for i in range(species.members.size()):
		for j in range(i + 1, species.members.size()):
			total_diversity += calculate_genetic_distance(species.members[i], species.members[j])
			comparisons += 1
	
	return total_diversity / comparisons if comparisons > 0 else 0.0

func calculate_genetic_distance(creature1: EvolutionaryCreature, creature2: EvolutionaryCreature) -> float:
	"""Calculate genetic distance between two creatures"""
	var distance = 0.0
	var gene_count = 0
	
	for gene in creature1.genes:
		if creature2.genes.has(gene):
			distance += abs(creature1.genes[gene] - creature2.genes[gene])
			gene_count += 1
	
	return distance / gene_count if gene_count > 0 else 0.0

func replace_population(new_population: Array):
	"""Replace old population with new one"""
	# Clear old visuals
	for creature in creatures:
		if creature.mesh_instance:
			creature.mesh_instance.queue_free()
	
	# Update population
	population = new_population
	creatures.clear()
	
	# Reset species assignments
	if speciation_enabled:
		for species in species_groups:
			species.members.clear()
		
		for creature in population:
			assign_to_species(creature)
	
	# Create new visuals
	for creature in population:
		create_creature_visual(creature)

func calculate_fitness_stats():
	"""Calculate comprehensive fitness statistics"""
	if population.is_empty():
		return
	
	var total_fitness = 0.0
	var fitness_values = []
	best_fitness = population[0].fitness
	var worst_fitness = population[0].fitness
	
	for creature in population:
		total_fitness += creature.fitness
		fitness_values.append(creature.fitness)
		
		if creature.fitness > best_fitness:
			best_fitness = creature.fitness
		if creature.fitness < worst_fitness:
			worst_fitness = creature.fitness
	
	average_fitness = total_fitness / population.size()
	
	# Calculate diversity metrics
	diversity_score = calculate_population_diversity()
	
	# Calculate species-specific stats
	if speciation_enabled:
		calculate_species_stats()

func calculate_population_diversity() -> float:
	"""Calculate overall population genetic diversity"""
	if population.size() < 2:
		return 0.0
	
	var total_diversity = 0.0
	var comparisons = 0
	
	# Sample-based diversity calculation for performance
	var sample_size = min(20, population.size())
	var sample_creatures = []
	
	for i in range(sample_size):
		sample_creatures.append(population[randi() % population.size()])
	
	for i in range(sample_creatures.size()):
		for j in range(i + 1, sample_creatures.size()):
			total_diversity += calculate_genetic_distance(sample_creatures[i], sample_creatures[j])
			comparisons += 1
	
	return total_diversity / comparisons if comparisons > 0 else 0.0

func calculate_species_stats():
	"""Calculate species-specific statistics"""
	for species in species_groups:
		if species.members.is_empty():
			continue
		
		var species_fitness = 0.0
		for member in species.members:
			species_fitness += member.fitness
		
		species.traits["average_fitness"] = species_fitness / species.members.size()
		species.traits["size"] = species.members.size()
		species.traits["diversity"] = calculate_species_diversity(species)

func record_performance_metrics():
	"""Record performance metrics for analysis"""
	performance_metrics.generation_times.append(generation_timer)
	performance_metrics.fitness_progression.append(best_fitness)
	performance_metrics.species_count.append(species_groups.size())
	performance_metrics.behavioral_diversity.append(calculate_behavioral_diversity())
	
	# Limit history size
	var max_history = 100
	for metric in performance_metrics.values():
		if metric.size() > max_history:
			metric.pop_front()
	
	# Update real-time graphs
	if real_time_graphs:
		update_performance_graphs()
	
	# Analyze queer forms
	if queer_forms_detection and queer_forms_detector:
		perform_queer_forms_analysis()

func update_performance_graphs():
	"""Update the real-time performance graphs with new data"""
	# Update fitness progression graph
	if ui_elements.has("fitness_graph"):
		var fitness_graph = ui_elements["fitness_graph"]
		var renderer = fitness_graph.get_child(2) as GraphRenderer  # Graph renderer is 3rd child
		if renderer:
			renderer.add_data_point(best_fitness)
	
	# Update species count graph
	if ui_elements.has("species_graph"):
		var species_graph = ui_elements["species_graph"]
		var renderer = species_graph.get_child(2) as GraphRenderer
		if renderer:
			renderer.add_data_point(species_groups.size())
	
	# Update population size graph
	if ui_elements.has("population_graph"):
		var population_graph = ui_elements["population_graph"]
		var renderer = population_graph.get_child(2) as GraphRenderer
		if renderer:
			renderer.add_data_point(population.size())
	
	# Update behavioral diversity graph
	if ui_elements.has("behavior_graph"):
		var behavior_graph = ui_elements["behavior_graph"]
		var renderer = behavior_graph.get_child(2) as GraphRenderer
		if renderer:
			renderer.add_data_point(calculate_behavioral_diversity())

func calculate_behavioral_diversity() -> float:
	"""Calculate behavioral diversity across population"""
	var behavior_counts = {}
	
	for creature in creatures:
		if not behavior_counts.has(creature.behavior_state):
			behavior_counts[creature.behavior_state] = 0
		behavior_counts[creature.behavior_state] += 1
	
	# Calculate Shannon diversity index
	var total_creatures = creatures.size()
	var diversity = 0.0
	
	for behavior in behavior_counts:
		var frequency = float(behavior_counts[behavior]) / total_creatures
		if frequency > 0:
			diversity -= frequency * log(frequency)
	
	return diversity

func update_fitness_landscape():
	"""Update fitness landscape based on environmental changes"""
	if not fitness_landscape_evolution:
		return
	
	# Dynamic fitness landscape that changes over time
	var landscape_shift = sin(generation * 0.1) * 0.2
	environmental_pressure = 0.1 + landscape_shift
	
	# Update environmental factors
	environmental_factors.resource_availability *= (1.0 + landscape_shift)
	environmental_factors.resource_availability = clamp(environmental_factors.resource_availability, 0.3, 1.5)

func setup_ui():
	"""Setup comprehensive UI system"""
	var canvas = CanvasLayer.new()
	add_child(canvas)
	
	ui_elements = {}
	
	# Main info panel
	var info_panel = Panel.new()
	info_panel.position = Vector2(20, 20)
	info_panel.size = Vector2(300, 200)
	canvas.add_child(info_panel)
	
	# Generation counter
	var gen_label = Label.new()
	gen_label.position = Vector2(30, 30)
	gen_label.text = "Generation: 0"
	canvas.add_child(gen_label)
	ui_elements["generation"] = gen_label
	
	# Population stats
	var pop_label = Label.new()
	pop_label.position = Vector2(30, 50)
	pop_label.text = "Population: 0"
	canvas.add_child(pop_label)
	ui_elements["population"] = pop_label
	
	# Fitness stats
	var fitness_label = Label.new()
	fitness_label.position = Vector2(30, 70)
	fitness_label.text = "Best Fitness: 0.0"
	canvas.add_child(fitness_label)
	ui_elements["best_fitness"] = fitness_label
	
	var avg_fitness_label = Label.new()
	avg_fitness_label.position = Vector2(30, 90)
	avg_fitness_label.text = "Avg Fitness: 0.0"
	canvas.add_child(avg_fitness_label)
	ui_elements["avg_fitness"] = avg_fitness_label
	
	# Species info
	if speciation_enabled:
		var species_label = Label.new()
		species_label.position = Vector2(30, 110)
		species_label.text = "Species: 0"
		canvas.add_child(species_label)
		ui_elements["species"] = species_label
	
	# Diversity metrics
	var diversity_label = Label.new()
	diversity_label.position = Vector2(30, 130)
	diversity_label.text = "Diversity: 0.0"
	canvas.add_child(diversity_label)
	ui_elements["diversity"] = diversity_label
	
	# Environmental info
	var env_label = Label.new()
	env_label.position = Vector2(30, 150)
	env_label.text = "Environment: Normal"
	canvas.add_child(env_label)
	ui_elements["environment"] = env_label
	
	# Queer forms metrics
	if queer_forms_detection:
		var queer_title = Label.new()
		queer_title.position = Vector2(30, 175)
		queer_title.text = "=== QUEER FORMS ==="
		queer_title.add_theme_font_size_override("font_size", 12)
		canvas.add_child(queer_title)
		
		var queer_score_label = Label.new()
		queer_score_label.position = Vector2(30, 195)
		queer_score_label.text = "Queerness: 0.0"
		canvas.add_child(queer_score_label)
		ui_elements["queer_score"] = queer_score_label
		
		var topo_label = Label.new()
		topo_label.position = Vector2(30, 215)
		topo_label.text = "Topo Q: 0.0"
		canvas.add_child(topo_label)
		ui_elements["topo_queerness"] = topo_label
		
		var gen_entropy_label = Label.new()
		gen_entropy_label.position = Vector2(150, 195)
		gen_entropy_label.text = "Gen Entropy: 0.0"
		canvas.add_child(gen_entropy_label)
		ui_elements["genetic_entropy"] = gen_entropy_label
		
		var beh_entropy_label = Label.new()
		beh_entropy_label.position = Vector2(150, 215)
		beh_entropy_label.text = "Beh Entropy: 0.0"
		canvas.add_child(beh_entropy_label)
		ui_elements["behavioral_entropy"] = beh_entropy_label
	
	# Real-time graphs
	if real_time_graphs:
		setup_performance_graphs(canvas)
	
	# Interactive controls
	setup_interactive_controls(canvas)

func setup_performance_graphs(canvas: CanvasLayer):
	"""Setup real-time performance graphs"""
	# Create graph panel
	var graph_panel = Panel.new()
	graph_panel.position = Vector2(350, 20)
	graph_panel.size = Vector2(400, 300)
	canvas.add_child(graph_panel)
	
	# Graph title
	var graph_title = Label.new()
	graph_title.position = Vector2(360, 30)
	graph_title.text = "Performance Metrics"
	graph_title.add_theme_font_size_override("font_size", 16)
	canvas.add_child(graph_title)
	
	# Create fitness progression graph
	var fitness_graph = create_line_graph(
		Vector2(360, 60),
		Vector2(180, 80),
		"Fitness Over Time",
		Color.GREEN
	)
	canvas.add_child(fitness_graph)
	ui_elements["fitness_graph"] = fitness_graph
	
	# Create species diversity graph
	var species_graph = create_line_graph(
		Vector2(560, 60),
		Vector2(180, 80),
		"Species Count",
		Color.BLUE
	)
	canvas.add_child(species_graph)
	ui_elements["species_graph"] = species_graph
	
	# Create population size graph
	var population_graph = create_line_graph(
		Vector2(360, 160),
		Vector2(180, 80),
		"Population Size",
		Color.RED
	)
	canvas.add_child(population_graph)
	ui_elements["population_graph"] = population_graph
	
	# Create behavioral diversity graph
	var behavior_graph = create_line_graph(
		Vector2(560, 160),
		Vector2(180, 80),
		"Behavioral Diversity",
		Color.YELLOW
	)
	canvas.add_child(behavior_graph)
	ui_elements["behavior_graph"] = behavior_graph
	
	# Fitness trend indicator
	var fitness_trend_label = Label.new()
	fitness_trend_label.position = Vector2(360, 250)
	fitness_trend_label.text = "Fitness Trend: ↗"
	canvas.add_child(fitness_trend_label)
	ui_elements["fitness_trend"] = fitness_trend_label

func create_line_graph(position: Vector2, size: Vector2, title: String, color: Color) -> Control:
	"""Create a line graph control"""
	var graph_container = Control.new()
	graph_container.position = position
	graph_container.size = size
	
	# Graph title
	var title_label = Label.new()
	title_label.position = Vector2(0, -20)
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", 12)
	graph_container.add_child(title_label)
	
	# Graph background
	var graph_bg = ColorRect.new()
	graph_bg.size = size
	graph_bg.color = Color(0.1, 0.1, 0.1, 0.8)
	graph_container.add_child(graph_bg)
	
	# Create custom graph renderer
	var graph_renderer = GraphRenderer.new()
	graph_renderer.size = size
	graph_renderer.line_color = color
	graph_renderer.max_data_points = 50
	graph_container.add_child(graph_renderer)
	
	return graph_container

# Custom graph renderer class
class GraphRenderer extends Control:
	var data_points: Array = []
	var line_color: Color = Color.WHITE
	var max_data_points: int = 50
	var min_value: float = 0.0
	var max_value: float = 100.0
	var auto_scale: bool = true
	
	func _ready():
		custom_minimum_size = Vector2(100, 50)
	
	func add_data_point(value: float):
		"""Add a new data point to the graph"""
		data_points.append(value)
		
		# Limit data points for performance
		if data_points.size() > max_data_points:
			data_points.pop_front()
		
		# Auto-scale if enabled
		if auto_scale and data_points.size() > 1:
			min_value = data_points.min()
			max_value = data_points.max()
			
			# Add some padding
			var range_val = max_value - min_value
			if range_val > 0:
				min_value -= range_val * 0.1
				max_value += range_val * 0.1
		
		queue_redraw()
	
	func _draw():
		"""Draw the graph lines"""
		if data_points.size() < 2:
			return
		
		var graph_size = get_size()
		var point_spacing = graph_size.x / (max_data_points - 1)
		var value_range = max_value - min_value
		
		if value_range <= 0:
			return
		
		# Draw grid lines
		draw_grid_lines(graph_size)
		
		# Draw data line
		var points = PackedVector2Array()
		for i in range(data_points.size()):
			var x = i * point_spacing
			var normalized_value = (data_points[i] - min_value) / value_range
			var y = graph_size.y - (normalized_value * graph_size.y)
			points.append(Vector2(x, y))
		
		# Draw the line
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], line_color, 2.0)
		
		# Draw data points
		for point in points:
			draw_circle(point, 2.0, line_color)
		
		# Draw value labels
		draw_value_labels(graph_size)
	
	func draw_grid_lines(graph_size: Vector2):
		"""Draw background grid lines"""
		var grid_color = Color(0.3, 0.3, 0.3, 0.5)
		
		# Horizontal grid lines
		for i in range(5):
			var y = i * graph_size.y / 4
			draw_line(Vector2(0, y), Vector2(graph_size.x, y), grid_color, 1.0)
		
		# Vertical grid lines
		for i in range(6):
			var x = i * graph_size.x / 5
			draw_line(Vector2(x, 0), Vector2(x, graph_size.y), grid_color, 1.0)
	
	func draw_value_labels(graph_size: Vector2):
		"""Draw value labels on the graph"""
		var font = ThemeDB.fallback_font
		var font_size = 10
		
		# Y-axis labels (values)
		for i in range(5):
			var y = i * graph_size.y / 4
			var value = max_value - (i * (max_value - min_value) / 4)
			var label = str(snapped(value, 0.1))
			draw_string(font, Vector2(-30, y + 5), label, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		
		# X-axis labels (generation numbers)
		if data_points.size() > 0:
			var current_gen = data_points.size()
			draw_string(font, Vector2(graph_size.x - 20, graph_size.y + 15), str(current_gen), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)
			draw_string(font, Vector2(0, graph_size.y + 15), str(max(0, current_gen - max_data_points)), HORIZONTAL_ALIGNMENT_CENTER, -1, font_size)

func setup_interactive_controls(canvas: CanvasLayer):
	"""Setup interactive controls for real-time parameter adjustment"""
	# Controls panel
	var control_panel = Panel.new()
	control_panel.position = Vector2(20, 250)
	control_panel.size = Vector2(280, 400)
	canvas.add_child(control_panel)
	
	# Controls title
	var controls_title = Label.new()
	controls_title.position = Vector2(30, 260)
	controls_title.text = "Evolution Controls"
	controls_title.add_theme_font_size_override("font_size", 14)
	canvas.add_child(controls_title)
	
	var y_offset = 280
	
	# Mutation rate control
	var mutation_label = Label.new()
	mutation_label.position = Vector2(30, y_offset)
	mutation_label.text = "Mutation Rate: " + str(mutation_rate)
	canvas.add_child(mutation_label)
	ui_elements["mutation_label"] = mutation_label
	
	var mutation_slider = HSlider.new()
	mutation_slider.position = Vector2(30, y_offset + 20)
	mutation_slider.size = Vector2(200, 20)
	mutation_slider.min_value = 0.01
	mutation_slider.max_value = 0.5
	mutation_slider.value = mutation_rate
	mutation_slider.value_changed.connect(_on_mutation_rate_changed)
	canvas.add_child(mutation_slider)
	
	y_offset += 50
	
	# Population size control
	var pop_size_label = Label.new()
	pop_size_label.position = Vector2(30, y_offset)
	pop_size_label.text = "Population Size: " + str(population_size)
	canvas.add_child(pop_size_label)
	ui_elements["pop_size_label"] = pop_size_label
	
	var pop_slider = HSlider.new()
	pop_slider.position = Vector2(30, y_offset + 20)
	pop_slider.size = Vector2(200, 20)
	pop_slider.min_value = 20
	pop_slider.max_value = 200
	pop_slider.value = population_size
	pop_slider.value_changed.connect(_on_population_size_changed)
	canvas.add_child(pop_slider)
	
	y_offset += 50
	
	# Environmental pressure control
	var env_pressure_label = Label.new()
	env_pressure_label.position = Vector2(30, y_offset)
	env_pressure_label.text = "Environmental Pressure: " + str(environmental_pressure)
	canvas.add_child(env_pressure_label)
	ui_elements["env_pressure_label"] = env_pressure_label
	
	var env_slider = HSlider.new()
	env_slider.position = Vector2(30, y_offset + 20)
	env_slider.size = Vector2(200, 20)
	env_slider.min_value = 0.0
	env_slider.max_value = 1.0
	env_slider.value = environmental_pressure
	env_slider.value_changed.connect(_on_environmental_pressure_changed)
	canvas.add_child(env_slider)
	
	y_offset += 50
	
	# Queer forms detection toggle
	var queer_forms_check = CheckBox.new()
	queer_forms_check.position = Vector2(30, y_offset)
	queer_forms_check.text = "Detect Queer Forms"
	queer_forms_check.button_pressed = true
	queer_forms_check.toggled.connect(_on_queer_forms_toggled)
	canvas.add_child(queer_forms_check)
	
	y_offset += 30
	
	# Topological analysis toggle
	var tda_check = CheckBox.new()
	tda_check.position = Vector2(30, y_offset)
	tda_check.text = "Topological Analysis"
	tda_check.button_pressed = true
	tda_check.toggled.connect(_on_tda_toggled)
	canvas.add_child(tda_check)
	
	y_offset += 40
	
	# Action buttons
	var reset_button = Button.new()
	reset_button.position = Vector2(30, y_offset)
	reset_button.size = Vector2(80, 30)
	reset_button.text = "Reset"
	reset_button.pressed.connect(_on_reset_pressed)
	canvas.add_child(reset_button)
	
	var evolve_button = Button.new()
	evolve_button.position = Vector2(120, y_offset)
	evolve_button.size = Vector2(80, 30)
	evolve_button.text = "Force Evolve"
	evolve_button.pressed.connect(_on_force_evolve_pressed)
	canvas.add_child(evolve_button)
	
	y_offset += 40
	
	# Environmental events
	var drought_button = Button.new()
	drought_button.position = Vector2(30, y_offset)
	drought_button.size = Vector2(60, 25)
	drought_button.text = "Drought"
	drought_button.pressed.connect(func(): trigger_environmental_event("drought", 0.8))
	canvas.add_child(drought_button)
	
	var boom_button = Button.new()
	boom_button.position = Vector2(100, y_offset)
	boom_button.size = Vector2(60, 25)
	boom_button.text = "Boom"
	boom_button.pressed.connect(func(): trigger_environmental_event("resource_boom", 0.8))
	canvas.add_child(boom_button)
	
	var predator_button = Button.new()
	predator_button.position = Vector2(170, y_offset)
	predator_button.size = Vector2(60, 25)
	predator_button.text = "Predators"
	predator_button.pressed.connect(func(): trigger_environmental_event("predator_invasion", 0.8))
	canvas.add_child(predator_button)

func _on_mutation_rate_changed(value: float):
	mutation_rate = value
	if ui_elements.has("mutation_label"):
		ui_elements["mutation_label"].text = "Mutation Rate: " + str(snapped(value, 0.01))

func _on_population_size_changed(value: float):
	population_size = int(value)
	if ui_elements.has("pop_size_label"):
		ui_elements["pop_size_label"].text = "Population Size: " + str(population_size)

func _on_environmental_pressure_changed(value: float):
	environmental_pressure = value
	if ui_elements.has("env_pressure_label"):
		ui_elements["env_pressure_label"].text = "Environmental Pressure: " + str(snapped(value, 0.01))

func _on_queer_forms_toggled(pressed: bool):
	# Toggle queer forms detection
	queer_forms_detection = pressed
	print("Queer forms detection: ", pressed)

func _on_tda_toggled(pressed: bool):
	# Toggle topological data analysis
	topological_analysis_enabled = pressed
	print("Topological analysis: ", pressed)

func _on_reset_pressed():
	# Reset the entire simulation
	reset_simulation()

func reset_simulation():
	"""Reset the simulation to initial state"""
	# Clear existing creatures
	for creature in creatures:
		if creature.mesh_instance:
			creature.mesh_instance.queue_free()
	creatures.clear()
	
	# Reset generation counter
	generation = 0
	
	# Initialize new population
	initialize_population()
	
	print("Simulation reset - new population generated")

func _on_force_evolve_pressed():
	# Force evolution to next generation
	evolve_population()

func setup_performance_tracking():
	"""Initialize performance tracking systems"""
	performance_metrics = {
		"generation_times": [],
		"fitness_progression": [],
		"species_count": [],
		"behavioral_diversity": [],
		"environmental_pressure": [],
		"population_size": [],
		"topological_features": [],
		"queer_forms_detected": []
	}

func update_visualizations(delta: float):
	"""Update all visual elements"""
	# Update fitness landscape
	if show_fitness_landscape and fitness_landscape_mesh:
		update_fitness_landscape_visual()
	
	# Update creature trails
	if trail_visualization:
		update_trail_visualizations()
	
	# Update neural network visualizations
	if show_neural_connections:
		update_neural_network_visualizations()
	
	# Update queer forms visualizations
	if queer_forms_detection and not current_queer_analysis.is_empty():
		visualize_queer_forms()

func update_fitness_landscape_visual():
	"""Update fitness landscape visual representation"""
	if not fitness_landscape_mesh:
		return
	
	# Create height map based on current population fitness distribution
	var material = fitness_landscape_mesh.material_override as StandardMaterial3D
	if material:
		# Update color based on average fitness
		var fitness_ratio = average_fitness / max(best_fitness, 1.0)
		material.albedo_color = Color(0.1, 0.3 + fitness_ratio * 0.5, 0.8, 0.3)

func update_trail_visualizations():
	"""Update creature trail visualizations"""
	for creature in creatures:
		if creature.mesh_instance:
			update_creature_trail(creature)

func update_creature_trail(creature: EvolutionaryCreature):
	"""Update trail visualization for a single creature"""
	# Add current position to trail
	creature.trail_points.append(creature.position)
	
	# Limit trail length for performance
	var max_trail_length = 50
	if creature.trail_points.size() > max_trail_length:
		creature.trail_points.pop_front()
	
	# Find or create trail renderer
	var trail_renderer = null
	for child in creature.mesh_instance.get_children():
		if child.name == "TrailRenderer":
			trail_renderer = child
			break
	
	if not trail_renderer:
		trail_renderer = create_trail_renderer(creature)
		creature.mesh_instance.add_child(trail_renderer)
	
	# Update trail mesh
	if trail_renderer:
		update_trail_mesh(trail_renderer, creature)

func create_trail_renderer(creature: EvolutionaryCreature) -> MeshInstance3D:
	"""Create a trail renderer for a creature"""
	var trail_renderer = MeshInstance3D.new()
	trail_renderer.name = "TrailRenderer"
	
	# Create trail material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(
		creature.genes.red,
		creature.genes.green,
		creature.genes.blue,
		0.6
	)
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	material.emission_enabled = true
	material.emission_energy = creature.genes.luminescence * 0.3
	material.no_depth_test = true
	material.vertex_color_use_as_albedo = true
	
	trail_renderer.material_override = material
	
	return trail_renderer

func update_trail_mesh(trail_renderer: MeshInstance3D, creature: EvolutionaryCreature):
	"""Update the trail mesh based on creature's trail points"""
	if creature.trail_points.size() < 2:
		return
	
	var mesh = ArrayMesh.new()
	var vertices = PackedVector3Array()
	var colors = PackedColorArray()
	var indices = PackedInt32Array()
	
	# Create trail geometry
	var trail_width = creature.size * 0.1
	var base_color = Color(
		creature.genes.red,
		creature.genes.green,
		creature.genes.blue,
		1.0
	)
	
	for i in range(creature.trail_points.size()):
		var point = creature.trail_points[i]
		var alpha = float(i) / creature.trail_points.size()  # Fade from old to new
		
		# Calculate perpendicular vector for trail width
		var direction = Vector3.ZERO
		if i < creature.trail_points.size() - 1:
			direction = (creature.trail_points[i + 1] - point).normalized()
		elif i > 0:
			direction = (point - creature.trail_points[i - 1]).normalized()
		
		var perpendicular = Vector3.UP.cross(direction).normalized() * trail_width
		
		# Add vertices for trail segment
		vertices.append(point + perpendicular)
		vertices.append(point - perpendicular)
		
		# Add colors with alpha fade
		var color = base_color
		color.a = alpha * (creature.energy / 100.0) * 0.8
		colors.append(color)
		colors.append(color)
		
		# Add indices for triangles
		if i < creature.trail_points.size() - 1:
			var base_idx = i * 2
			# First triangle
			indices.append(base_idx)
			indices.append(base_idx + 1)
			indices.append(base_idx + 2)
			# Second triangle
			indices.append(base_idx + 1)
			indices.append(base_idx + 3)
			indices.append(base_idx + 2)
	
	# Create mesh arrays
	var arrays = []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = vertices
	arrays[Mesh.ARRAY_COLOR] = colors
	arrays[Mesh.ARRAY_INDEX] = indices
	
	# Apply to mesh
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	trail_renderer.mesh = mesh

func update_neural_network_visualizations():
	"""Update neural network visualizations"""
	for creature in creatures:
		if creature.neural_display:
			update_neural_visualization(creature)

func update_neural_visualization(creature: EvolutionaryCreature):
	"""Update neural network visualization for a creature"""
	if not creature.neural_display:
		return
	
	# Get the neural network activity
	var network = creature.neural_network
	if not network:
		return
	
	# Create visualization of neural network layers
	var layer_count = network.layers.size()
	var layer_spacing = 2.0
	var neuron_spacing = 0.5
	
	# Clear existing visualization
	for child in creature.neural_display.get_children():
		child.queue_free()
	
	# Create nodes for each layer
	for layer_idx in range(layer_count):
		var layer_size = network.layers[layer_idx]
		var layer_node = Node3D.new()
		layer_node.position = Vector3(layer_idx * layer_spacing, 0, 0)
		creature.neural_display.add_child(layer_node)
		
		# Create neurons in this layer
		for neuron_idx in range(layer_size):
			var neuron_mesh = MeshInstance3D.new()
			var sphere = SphereMesh.new()
			sphere.radius = 0.1
			sphere.radial_segments = 8
			sphere.rings = 4
			neuron_mesh.mesh = sphere
			
			# Position neuron
			var y_offset = (neuron_idx - layer_size / 2.0) * neuron_spacing
			neuron_mesh.position = Vector3(0, y_offset, 0)
			
			# Color based on activation (if we have activation data)
			var material = StandardMaterial3D.new()
			var activation_strength = 0.5  # Default neutral
			
			# Try to get actual activation if available
			if layer_idx < network.weights.size() and creature.perceived_objects.size() > 0:
				# Use a simple approximation based on recent inputs
				activation_strength = abs(sin(Time.get_time_dict_from_system()["second"] * 0.1 + neuron_idx))
			
			material.albedo_color = Color(
				activation_strength,
				1.0 - activation_strength,
				0.5,
				0.8
			)
			material.emission_enabled = true
			material.emission_energy = activation_strength * 0.5
			neuron_mesh.material_override = material
			
			layer_node.add_child(neuron_mesh)
		
		# Create connections to next layer
		if layer_idx < layer_count - 1:
			create_neural_connections(layer_node, network, layer_idx, creature)

func create_neural_connections(layer_node: Node3D, network: NeuralNetwork, layer_idx: int, creature: EvolutionaryCreature):
	"""Create visual connections between neural layers"""
	var current_layer_size = network.layers[layer_idx]
	var next_layer_size = network.layers[layer_idx + 1]
	
	# Create connections (sample a subset for performance)
	var max_connections = min(50, current_layer_size * next_layer_size)
	var connections_created = 0
	
	for from_neuron in range(current_layer_size):
		for to_neuron in range(next_layer_size):
			if connections_created >= max_connections:
				break
			
			# Only show some connections to avoid visual clutter
			if randf() < 0.3:  # Show 30% of connections
				var connection_line = create_connection_line(
					Vector3(0, (from_neuron - current_layer_size / 2.0) * 0.5, 0),
					Vector3(2.0, (to_neuron - next_layer_size / 2.0) * 0.5, 0),
					network.weights[layer_idx][to_neuron][from_neuron]
				)
				layer_node.add_child(connection_line)
				connections_created += 1
		
		if connections_created >= max_connections:
			break

func create_connection_line(from_pos: Vector3, to_pos: Vector3, weight: float) -> MeshInstance3D:
	"""Create a line representing a neural connection"""
	var line_mesh = MeshInstance3D.new()
	
	# Create a simple cylinder for the connection
	var cylinder = CylinderMesh.new()
	cylinder.top_radius = 0.01
	cylinder.bottom_radius = 0.01
	cylinder.height = from_pos.distance_to(to_pos)
	line_mesh.mesh = cylinder
	
	# Position and orient the line
	line_mesh.position = (from_pos + to_pos) / 2.0
	line_mesh.look_at(from_pos, Vector3.UP)
	
	# Color based on weight strength
	var material = StandardMaterial3D.new()
	var weight_strength = abs(weight) / 2.0  # Normalize assuming weights are in [-2, 2]
	weight_strength = clamp(weight_strength, 0.0, 1.0)
	
	if weight > 0:
		material.albedo_color = Color(0.2, 1.0, 0.2, weight_strength)  # Green for positive
	else:
		material.albedo_color = Color(1.0, 0.2, 0.2, weight_strength)  # Red for negative
	
	material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	line_mesh.material_override = material
	
	return line_mesh

func update_ui():
	"""Update all UI elements"""
	if ui_elements.has("generation"):
		ui_elements["generation"].text = "Generation: " + str(generation)
	
	if ui_elements.has("population"):
		ui_elements["population"].text = "Population: " + str(population.size())
	
	if ui_elements.has("best_fitness"):
		ui_elements["best_fitness"].text = "Best Fitness: " + str(snapped(best_fitness, 0.1))
	
	if ui_elements.has("avg_fitness"):
		ui_elements["avg_fitness"].text = "Avg Fitness: " + str(snapped(average_fitness, 0.1))
	
	if ui_elements.has("species"):
		ui_elements["species"].text = "Species: " + str(species_groups.size())
	
	if ui_elements.has("diversity"):
		ui_elements["diversity"].text = "Diversity: " + str(snapped(diversity_score, 0.01))
	
	if ui_elements.has("environment"):
		var env_state = get_environmental_state()
		ui_elements["environment"].text = "Environment: " + env_state
	
	if ui_elements.has("fitness_trend"):
		var trend = calculate_fitness_trend()
		ui_elements["fitness_trend"].text = "Fitness Trend: " + trend
	
	# Update queer forms metrics
	if queer_forms_detection and not current_queer_analysis.is_empty():
		if ui_elements.has("queer_score"):
			ui_elements["queer_score"].text = "Queerness: " + str(snapped(current_queer_analysis.overall_queerness, 0.01))
		
		if ui_elements.has("topo_queerness"):
			ui_elements["topo_queerness"].text = "Topo Q: " + str(snapped(current_queer_analysis.topological_queerness, 0.01))
		
		if ui_elements.has("genetic_entropy"):
			ui_elements["genetic_entropy"].text = "Gen Entropy: " + str(snapped(current_queer_analysis.genetic_entropy, 0.01))
		
		if ui_elements.has("behavioral_entropy"):
			ui_elements["behavioral_entropy"].text = "Beh Entropy: " + str(snapped(current_queer_analysis.behavioral_entropy, 0.01))

func get_environmental_state() -> String:
	"""Get current environmental state description"""
	var temp = environmental_factors.temperature
	var resources = environmental_factors.resource_availability
	var predator_activity = environmental_factors.predator_activity
	
	if temp > 0.7:
		return "Hot"
	elif temp < 0.3:
		return "Cold"
	elif resources < 0.5:
		return "Scarce"
	elif predator_activity > 0.6:
		return "Dangerous"
	else:
		return "Normal"

func calculate_fitness_trend() -> String:
	"""Calculate fitness trend over recent generations"""
	var history = performance_metrics.fitness_progression
	if history.size() < 5:
		return "→"
	
	var recent_avg = 0.0
	var older_avg = 0.0
	var recent_count = min(5, history.size())
	
	for i in range(recent_count):
		recent_avg += history[history.size() - 1 - i]
	recent_avg /= recent_count
	
	for i in range(recent_count, min(recent_count * 2, history.size())):
		older_avg += history[history.size() - 1 - i]
	older_avg /= recent_count
	
	if recent_avg > older_avg * 1.05:
		return "↗"
	elif recent_avg < older_avg * 0.95:
		return "↘"
	else:
		return "→"

# Debug and analysis functions
func print_ecosystem_report():
	"""Print comprehensive ecosystem analysis"""
	print("=== ECOSYSTEM EVOLUTION REPORT ===")
	print("Generation: ", generation)
	print("Population Size: ", population.size())
	print("Species Count: ", species_groups.size())
	print("Best Fitness: ", best_fitness)
	print("Average Fitness: ", average_fitness)
	print("Diversity Score: ", diversity_score)
	print("Environmental Pressure: ", environmental_pressure)
	
	if speciation_enabled:
		print("\n=== SPECIES BREAKDOWN ===")
		for species in species_groups:
			print("Species %d: %d members, avg fitness: %.2f" % [species.id, species.members.size(), species.traits.get("average_fitness", 0.0)])
	
	print("\n=== BEHAVIORAL DISTRIBUTION ===")
	var behavior_counts = {}
	for creature in creatures:
		if not behavior_counts.has(creature.behavior_state):
			behavior_counts[creature.behavior_state] = 0
		behavior_counts[creature.behavior_state] += 1
	
	for behavior in behavior_counts:
		var percentage = float(behavior_counts[behavior]) / creatures.size() * 100.0
		print("%s: %d creatures (%.1f%%)" % [behavior, behavior_counts[behavior], percentage])

func export_evolution_data() -> Dictionary:
	"""Export evolution data for analysis"""
	var data = {
		"generation": generation,
		"population_size": population.size(),
		"species_count": species_groups.size(),
		"best_fitness": best_fitness,
		"average_fitness": average_fitness,
		"diversity_score": diversity_score,
		"environmental_factors": environmental_factors.duplicate(),
		"performance_metrics": performance_metrics.duplicate()
	}
	
	if speciation_enabled:
		data["species_data"] = []
		for species in species_groups:
			data["species_data"].append({
				"id": species.id,
				"size": species.members.size(),
				"traits": species.traits.duplicate(),
				"generation_created": species.generation_created
			})
	
	return data

# Public API functions for external control
func set_evolution_parameters(params: Dictionary):
	"""Set evolution parameters from external source"""
	if params.has("mutation_rate"):
		mutation_rate = params.mutation_rate
	if params.has("population_size"):
		population_size = params.population_size
	if params.has("environmental_pressure"):
		environmental_pressure = params.environmental_pressure
	# Add more parameter setters as needed

func trigger_environmental_event(event_type: String, intensity: float = 1.0):
	"""Trigger environmental events that affect evolution"""
	match event_type:
		"drought":
			environmental_factors.resource_availability *= (1.0 - intensity * 0.5)
		"predator_invasion":
			environmental_factors.predator_activity += intensity * 0.3
		"temperature_change":
			environmental_factors.temperature += (randf() - 0.5) * intensity * 0.4
		"resource_boom":
			environmental_factors.resource_availability += intensity * 0.3
	
	print("EcosystemEvolution: Environmental event triggered - %s (intensity: %.2f)" % [event_type, intensity])

func get_best_creature() -> EvolutionaryCreature:
	"""Get the current best performing creature"""
	if population.is_empty():
		return null
	
	var best_creature = population[0]
	for creature in population:
		if creature.fitness > best_creature.fitness:
			best_creature = creature
	
	return best_creature

func get_ecosystem_state() -> Dictionary:
	"""Get current ecosystem state"""
	return {
		"generation": generation,
		"population": population.size(),
		"species": species_groups.size(),
		"best_fitness": best_fitness,
		"average_fitness": average_fitness,
		"diversity": diversity_score,
		"environment": environmental_factors.duplicate(),
		"alive_creatures": creatures.size()
	}

# ==============================================================================
# TOPOLOGICAL DATA ANALYSIS & QUEER FORMS DETECTION
# ==============================================================================

# Persistent Homology class for detecting topological features
class PersistentHomology:
	var dimension: int = 2
	var max_filtration_value: float = 10.0
	var resolution: float = 0.1
	
	func _init(dim: int = 2, max_filt: float = 10.0):
		dimension = dim
		max_filtration_value = max_filt
	
	func compute_persistent_homology(point_cloud: Array) -> Dictionary:
		"""Compute persistent homology of a point cloud"""
		var persistence_pairs = []
		var betti_numbers = []
		
		# Create filtration (simplified Vietoris-Rips complex)
		var filtration_values = []
		for i in range(int(max_filtration_value / resolution)):
			filtration_values.append(i * resolution)
		
		# Track connected components (H0) and loops (H1)
		var previous_components = 0
		var previous_loops = 0
		
		for filt_value in filtration_values:
			var components = count_connected_components(point_cloud, filt_value)
			var loops = count_loops(point_cloud, filt_value)
			
			# Detect birth and death of topological features
			if components != previous_components:
				persistence_pairs.append({
					"dimension": 0,
					"birth": filt_value,
					"death": -1,  # Still alive
					"feature_type": "component"
				})
			
			if loops != previous_loops:
				persistence_pairs.append({
					"dimension": 1,
					"birth": filt_value,
					"death": -1,  # Still alive
					"feature_type": "loop"
				})
			
			betti_numbers.append({"H0": components, "H1": loops})
			previous_components = components
			previous_loops = loops
		
		return {
			"persistence_pairs": persistence_pairs,
			"betti_numbers": betti_numbers,
			"filtration_values": filtration_values
		}
	
	func count_connected_components(points: Array, threshold: float) -> int:
		"""Count connected components at given threshold"""
		var components = 0
		var visited = []
		
		for i in range(points.size()):
			visited.append(false)
		
		for i in range(points.size()):
			if not visited[i]:
				components += 1
				dfs_component(points, i, threshold, visited)
		
		return components
	
	func dfs_component(points: Array, start: int, threshold: float, visited: Array):
		"""Depth-first search for connected components"""
		visited[start] = true
		
		for i in range(points.size()):
			if not visited[i]:
				var distance = points[start].distance_to(points[i])
				if distance <= threshold:
					dfs_component(points, i, threshold, visited)
	
	func count_loops(points: Array, threshold: float) -> int:
		"""Estimate number of loops (simplified)"""
		var edges = 0
		var vertices = points.size()
		
		# Count edges in the graph
		for i in range(points.size()):
			for j in range(i + 1, points.size()):
				var distance = points[i].distance_to(points[j])
				if distance <= threshold:
					edges += 1
		
		# Euler characteristic approximation: loops ≈ edges - vertices + components
		var components = count_connected_components(points, threshold)
		return max(0, edges - vertices + components)
	
	func detect_queer_topology(persistence_data: Dictionary) -> float:
		"""Detect non-normative topological features"""
		var queer_score = 0.0
		var persistence_pairs = persistence_data.persistence_pairs
		
		# Look for unusual topological features
		for pair in persistence_pairs:
			var persistence = pair.get("death", max_filtration_value) - pair.birth
			
			# Reward long-lived features (non-standard)
			if persistence > max_filtration_value * 0.3:
				queer_score += 0.5
			
			# Reward higher-dimensional features
			if pair.dimension > 0:
				queer_score += 0.3
		
		# Normalize score
		return clamp(queer_score / max(1, persistence_pairs.size()), 0.0, 1.0)

# Mapper Algorithm class for data visualization
class MapperAlgorithm:
	var filter_function: String = "distance_to_center"
	var num_intervals: int = 10
	var overlap_percent: float = 0.3
	var clustering_method: String = "single_linkage"
	
	func _init(filter_func: String = "distance_to_center", intervals: int = 10):
		filter_function = filter_func
		num_intervals = intervals
	
	func compute_mapper_graph(data_points: Array, metadata: Array = []) -> Dictionary:
		"""Compute Mapper graph from data points"""
		# Step 1: Apply filter function
		var filter_values = []
		for point in data_points:
			filter_values.append(apply_filter_function(point, data_points))
		
		# Step 2: Create overlapping intervals
		var min_filter = filter_values.min()
		var max_filter = filter_values.max()
		var interval_size = (max_filter - min_filter) / num_intervals
		var overlap_size = interval_size * overlap_percent
		
		var intervals = []
		for i in range(num_intervals):
			var start = min_filter + i * interval_size - overlap_size
			var end = min_filter + (i + 1) * interval_size + overlap_size
			intervals.append({"start": start, "end": end, "index": i})
		
		# Step 3: Cluster points in each interval
		var nodes = []
		var node_id = 0
		
		for interval in intervals:
			var points_in_interval = []
			var indices_in_interval = []
			
			for i in range(data_points.size()):
				if filter_values[i] >= interval.start and filter_values[i] <= interval.end:
					points_in_interval.append(data_points[i])
					indices_in_interval.append(i)
			
			if points_in_interval.size() > 0:
				var clusters = cluster_points(points_in_interval)
				
				for cluster in clusters:
					var node = {
						"id": node_id,
						"interval": interval.index,
						"points": cluster,
						"indices": indices_in_interval,
						"center": calculate_cluster_center(cluster),
						"size": cluster.size()
					}
					nodes.append(node)
					node_id += 1
		
		# Step 4: Create edges between overlapping nodes
		var edges = []
		for i in range(nodes.size()):
			for j in range(i + 1, nodes.size()):
				if nodes_overlap(nodes[i], nodes[j]):
					edges.append({
						"source": nodes[i].id,
						"target": nodes[j].id,
						"weight": calculate_edge_weight(nodes[i], nodes[j])
					})
		
		return {
			"nodes": nodes,
			"edges": edges,
			"filter_values": filter_values,
			"intervals": intervals
		}
	
	func apply_filter_function(point: Vector3, all_points: Array) -> float:
		"""Apply filter function to a point"""
		match filter_function:
			"distance_to_center":
				return point.distance_to(Vector3.ZERO)
			"density":
				return calculate_local_density(point, all_points)
			"eccentricity":
				return calculate_eccentricity(point, all_points)
			"queer_divergence":
				return calculate_queer_divergence(point, all_points)
			_:
				return point.distance_to(Vector3.ZERO)
	
	func calculate_local_density(point: Vector3, all_points: Array, radius: float = 2.0) -> float:
		"""Calculate local density around a point"""
		var count = 0
		for p in all_points:
			if point.distance_to(p) <= radius:
				count += 1
		return float(count) / all_points.size()
	
	func calculate_eccentricity(point: Vector3, all_points: Array) -> float:
		"""Calculate eccentricity (average distance to all other points)"""
		var total_distance = 0.0
		for p in all_points:
			total_distance += point.distance_to(p)
		return total_distance / all_points.size()
	
	func calculate_queer_divergence(point: Vector3, all_points: Array) -> float:
		"""Calculate divergence from normative patterns"""
		var center = Vector3.ZERO
		for p in all_points:
			center += p
		center /= all_points.size()
		
		# Distance from population center
		var distance_from_center = point.distance_to(center)
		
		# Variance in local neighborhood
		var local_variance = 0.0
		var neighbors = []
		for p in all_points:
			if point.distance_to(p) <= 3.0:
				neighbors.append(p)
		
		if neighbors.size() > 1:
			var local_center = Vector3.ZERO
			for n in neighbors:
				local_center += n
			local_center /= neighbors.size()
			
			for n in neighbors:
				local_variance += local_center.distance_squared_to(n)
			local_variance /= neighbors.size()
		
		# Combine measures: high divergence = far from center + high local variance
		return distance_from_center * 0.7 + local_variance * 0.3
	
	func cluster_points(points: Array) -> Array:
		"""Cluster points using simple single linkage"""
		if points.size() <= 1:
			return [points]
		
		var clusters = []
		var used = []
		
		for i in range(points.size()):
			used.append(false)
		
		for i in range(points.size()):
			if not used[i]:
				var cluster = [points[i]]
				used[i] = true
				
				# Find nearby points
				for j in range(points.size()):
					if not used[j] and points[i].distance_to(points[j]) <= 2.0:
						cluster.append(points[j])
						used[j] = true
				
				clusters.append(cluster)
		
		return clusters
	
	func calculate_cluster_center(cluster: Array) -> Vector3:
		"""Calculate center of a cluster"""
		var center = Vector3.ZERO
		for point in cluster:
			center += point
		return center / cluster.size()
	
	func nodes_overlap(node1: Dictionary, node2: Dictionary) -> bool:
		"""Check if two nodes have overlapping points"""
		for idx1 in node1.indices:
			for idx2 in node2.indices:
				if idx1 == idx2:
					return true
		return false
	
	func calculate_edge_weight(node1: Dictionary, node2: Dictionary) -> float:
		"""Calculate weight of edge between nodes"""
		var overlap_count = 0
		for idx1 in node1.indices:
			for idx2 in node2.indices:
				if idx1 == idx2:
					overlap_count += 1
		
		return float(overlap_count) / min(node1.size, node2.size)
	
	func detect_queer_patterns(mapper_graph: Dictionary) -> Dictionary:
		"""Detect non-normative patterns in the mapper graph"""
		var nodes = mapper_graph.nodes
		var edges = mapper_graph.edges
		
		var queer_patterns = {
			"isolated_nodes": [],
			"high_degree_nodes": [],
			"unusual_clusters": [],
			"bridge_nodes": []
		}
		
		# Calculate node degrees
		var node_degrees = {}
		for node in nodes:
			node_degrees[node.id] = 0
		
		for edge in edges:
			node_degrees[edge.source] += 1
			node_degrees[edge.target] += 1
		
		# Identify patterns
		for node in nodes:
			var degree = node_degrees[node.id]
			
			# Isolated nodes (potential outliers)
			if degree == 0:
				queer_patterns.isolated_nodes.append(node)
			
			# High-degree nodes (hubs)
			elif degree > 3:
				queer_patterns.high_degree_nodes.append(node)
			
			# Unusual cluster sizes
			if node.size > 10 or node.size == 1:
				queer_patterns.unusual_clusters.append(node)
		
		return queer_patterns

# Queer Forms Detector - integrates TDA with evolutionary patterns
class QueerFormsDetector:
	var persistent_homology: PersistentHomology
	var mapper_algorithm: MapperAlgorithm
	var entropy_calculator: EntropyCalculator
	
	func _init():
		persistent_homology = PersistentHomology.new(2, 15.0)
		mapper_algorithm = MapperAlgorithm.new("queer_divergence", 12)
		entropy_calculator = EntropyCalculator.new()
	
	func analyze_population(population: Array) -> Dictionary:
		"""Comprehensive analysis of population for queer forms"""
		var positions = []
		var genetic_vectors = []
		var behavioral_vectors = []
		
		# Extract data for analysis
		for creature in population:
			positions.append(creature.position)
			genetic_vectors.append(encode_genetic_vector(creature.genes))
			behavioral_vectors.append(encode_behavioral_vector(creature))
		
		# Topological analysis
		var tda_results = persistent_homology.compute_persistent_homology(positions)
		var topological_queerness = persistent_homology.detect_queer_topology(tda_results)
		
		# Mapper analysis
		var mapper_results = mapper_algorithm.compute_mapper_graph(positions, genetic_vectors)
		var pattern_queerness = mapper_algorithm.detect_queer_patterns(mapper_results)
		
		# Entropy analysis
		var genetic_entropy = entropy_calculator.calculate_genetic_entropy(genetic_vectors)
		var behavioral_entropy = entropy_calculator.calculate_behavioral_entropy(behavioral_vectors)
		
		return {
			"topological_analysis": tda_results,
			"topological_queerness": topological_queerness,
			"mapper_analysis": mapper_results,
			"pattern_queerness": pattern_queerness,
			"genetic_entropy": genetic_entropy,
			"behavioral_entropy": behavioral_entropy,
			"overall_queerness": calculate_overall_queerness(topological_queerness, pattern_queerness, genetic_entropy, behavioral_entropy)
		}
	
	func encode_genetic_vector(genes: Dictionary) -> Array:
		"""Encode genetic traits as vector"""
		return [
			genes.get("size", 0.5),
			genes.get("speed", 0.5),
			genes.get("aggression", 0.5),
			genes.get("exploration", 0.5),
			genes.get("social_tendency", 0.5),
			genes.get("red", 0.5),
			genes.get("green", 0.5),
			genes.get("blue", 0.5)
		]
	
	func encode_behavioral_vector(creature) -> Array:
		"""Encode behavioral traits as vector"""
		return [
			creature.energy / 100.0,
			creature.age / 60.0,
			creature.fitness / 100.0,
			creature.velocity.length() / 5.0,
			creature.social_connections.size() / 10.0
		]
	
	func calculate_overall_queerness(topo_q: float, pattern_q: float, genetic_e: float, behavioral_e: float) -> float:
		"""Calculate overall queerness score"""
		# Weight different measures
		var weights = [0.3, 0.25, 0.25, 0.2]  # topology, patterns, genetic entropy, behavioral entropy
		var values = [topo_q, pattern_q, genetic_e, behavioral_e]
		
		var weighted_sum = 0.0
		for i in range(weights.size()):
			weighted_sum += weights[i] * values[i]
		
		return clamp(weighted_sum, 0.0, 1.0)

# Entropy Calculator for measuring system complexity
class EntropyCalculator:
	func calculate_genetic_entropy(genetic_vectors: Array) -> float:
		"""Calculate entropy of genetic diversity"""
		if genetic_vectors.is_empty():
			return 0.0
		
		var dimensions = genetic_vectors[0].size()
		var total_entropy = 0.0
		
		for dim in range(dimensions):
			var values = []
			for vector in genetic_vectors:
				values.append(vector[dim])
			
			total_entropy += calculate_shannon_entropy(values)
		
		return total_entropy / dimensions
	
	func calculate_behavioral_entropy(behavioral_vectors: Array) -> float:
		"""Calculate entropy of behavioral diversity"""
		if behavioral_vectors.is_empty():
			return 0.0
		
		var dimensions = behavioral_vectors[0].size()
		var total_entropy = 0.0
		
		for dim in range(dimensions):
			var values = []
			for vector in behavioral_vectors:
				values.append(vector[dim])
			
			total_entropy += calculate_shannon_entropy(values)
		
		return total_entropy / dimensions
	
	func calculate_shannon_entropy(values: Array) -> float:
		"""Calculate Shannon entropy of a value array"""
		var bins = 10
		var min_val = values.min()
		var max_val = values.max()
		var bin_size = (max_val - min_val) / bins
		
		if bin_size == 0:
			return 0.0
		
		var bin_counts = []
		for i in range(bins):
			bin_counts.append(0)
		
		# Count values in each bin
		for value in values:
			var bin_index = int((value - min_val) / bin_size)
			bin_index = clamp(bin_index, 0, bins - 1)
			bin_counts[bin_index] += 1
		
		# Calculate entropy
		var entropy = 0.0
		var total = values.size()
		
		for count in bin_counts:
			if count > 0:
				var probability = float(count) / total
				entropy -= probability * log(probability)
		
		return entropy / log(bins)  # Normalize to [0,1]

# ==============================================================================
# QUEER FORMS ANALYSIS INTEGRATION
# ==============================================================================

func perform_queer_forms_analysis():
	"""Perform queer forms analysis on current population"""
	if not queer_forms_detector or population.is_empty():
		return
	
	# Perform analysis
	current_queer_analysis = queer_forms_detector.analyze_population(population)
	
	# Store in history
	queer_forms_history.append({
		"generation": generation,
		"overall_queerness": current_queer_analysis.overall_queerness,
		"topological_queerness": current_queer_analysis.topological_queerness,
		"genetic_entropy": current_queer_analysis.genetic_entropy,
		"behavioral_entropy": current_queer_analysis.behavioral_entropy
	})
	
	# Limit history size
	if queer_forms_history.size() > 100:
		queer_forms_history.pop_front()
	
	# Update performance metrics
	performance_metrics.topological_features.append(current_queer_analysis.topological_queerness)
	performance_metrics.queer_forms_detected.append(current_queer_analysis.overall_queerness)
	
	# Apply non-normativity bias to evolution
	if current_queer_analysis.overall_queerness > entropy_threshold:
		apply_queer_forms_bias()
	
	# Print analysis results
	if generation % 5 == 0:  # Every 5 generations
		print_queer_forms_report()

func apply_queer_forms_bias():
	"""Apply bias towards non-normative forms in evolution"""
	# Boost fitness of creatures with high queerness scores
	for creature in population:
		var creature_queerness = calculate_individual_queerness(creature)
		if creature_queerness > entropy_threshold:
			creature.fitness += creature.fitness * non_normativity_bias
			# Visual indication
			if creature.mesh_instance:
				highlight_queer_creature(creature)

func calculate_individual_queerness(creature) -> float:
	"""Calculate queerness score for individual creature"""
	# Simplified individual analysis
	var genetic_vector = queer_forms_detector.encode_genetic_vector(creature.genes)
	var behavioral_vector = queer_forms_detector.encode_behavioral_vector(creature)
	
	# Distance from population center
	var pop_center = Vector3.ZERO
	for c in population:
		pop_center += c.position
	pop_center /= population.size()
	
	var spatial_divergence = creature.position.distance_to(pop_center) / environment_size
	
	# Genetic divergence
	var genetic_divergence = 0.0
	for i in range(genetic_vector.size()):
		genetic_divergence += abs(genetic_vector[i] - 0.5)  # 0.5 is "normal"
	genetic_divergence /= genetic_vector.size()
	
	# Behavioral divergence
	var behavioral_divergence = 0.0
	for i in range(behavioral_vector.size()):
		behavioral_divergence += abs(behavioral_vector[i] - 0.5)
	behavioral_divergence /= behavioral_vector.size()
	
	return (spatial_divergence + genetic_divergence + behavioral_divergence) / 3.0

func highlight_queer_creature(creature):
	"""Visually highlight creatures with high queerness"""
	if creature.mesh_instance:
		var material = creature.mesh_instance.material_override as StandardMaterial3D
		if material:
			material.emission_enabled = true
			material.emission = Color(1.0, 0.5, 1.0)  # Queer pride colors
			material.emission_energy = 0.5

func print_queer_forms_report():
	"""Print detailed queer forms analysis report"""
	if current_queer_analysis.is_empty():
		return
	
	print("=== QUEER FORMS ANALYSIS REPORT ===")
	print("Generation: ", generation)
	print("Overall Queerness: ", snapped(current_queer_analysis.overall_queerness, 0.01))
	print("Topological Queerness: ", snapped(current_queer_analysis.topological_queerness, 0.01))
	print("Genetic Entropy: ", snapped(current_queer_analysis.genetic_entropy, 0.01))
	print("Behavioral Entropy: ", snapped(current_queer_analysis.behavioral_entropy, 0.01))
	
	var tda = current_queer_analysis.topological_analysis
	print("Topological Features: ", tda.persistence_pairs.size())
	
	var patterns = current_queer_analysis.pattern_queerness
	print("Isolated Nodes: ", patterns.isolated_nodes.size())
	print("Hub Nodes: ", patterns.high_degree_nodes.size())
	print("Unusual Clusters: ", patterns.unusual_clusters.size())
	
	print("====================================")

func visualize_queer_forms():
	"""Create visualizations of detected queer forms"""
	if not current_queer_analysis or not show_fitness_landscape:
		return
	
	# Create or update queer forms visualization
	var queer_viz = get_node_or_null("QueerFormsVisualization")
	if not queer_viz:
		queer_viz = Node3D.new()
		queer_viz.name = "QueerFormsVisualization"
		add_child(queer_viz)
	
	# Clear existing visualization
	for child in queer_viz.get_children():
		child.queue_free()
	
	# Visualize mapper graph
	visualize_mapper_graph(current_queer_analysis.mapper_analysis, queer_viz)
	
	# Visualize topological features
	visualize_topological_features(current_queer_analysis.topological_analysis, queer_viz)

func visualize_mapper_graph(mapper_data: Dictionary, parent: Node3D):
	"""Visualize the mapper graph structure"""
	var nodes = mapper_data.get("nodes", [])
	var edges = mapper_data.get("edges", [])
	
	# Create node visualizations
	for node in nodes:
		var node_viz = MeshInstance3D.new()
		node_viz.mesh = SphereMesh.new()
		node_viz.mesh.radius = 0.3 + node.size * 0.1
		
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1.0, 0.3, 0.8, 0.7)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		node_viz.material_override = material
		
		node_viz.position = node.center + Vector3(0, 10, 0)  # Elevated view
		parent.add_child(node_viz)
	
	# Create edge visualizations
	for edge in edges:
		var source_node = null
		var target_node = null
		
		for node in nodes:
			if node.id == edge.source:
				source_node = node
			elif node.id == edge.target:
				target_node = node
		
		if source_node and target_node:
			var edge_viz = create_connection_line(
				source_node.center + Vector3(0, 10, 0),
				target_node.center + Vector3(0, 10, 0),
				edge.weight
			)
			parent.add_child(edge_viz)

func visualize_topological_features(tda_data: Dictionary, parent: Node3D):
	"""Visualize persistent homology features"""
	var persistence_pairs = tda_data.get("persistence_pairs", [])
	
	for pair in persistence_pairs:
		if pair.feature_type == "loop":
			# Create visualization for loops
			var loop_viz = MeshInstance3D.new()
			loop_viz.mesh = TorusMesh.new()
			loop_viz.mesh.inner_radius = 0.5
			loop_viz.mesh.outer_radius = 1.0
			
			var material = StandardMaterial3D.new()
			material.albedo_color = Color(0.8, 0.2, 0.8, 0.5)
			material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
			material.emission_enabled = true
			material.emission = Color(0.4, 0.1, 0.4)
			loop_viz.material_override = material
			
			loop_viz.position = Vector3(randf_range(-5, 5), 8, randf_range(-5, 5))
			parent.add_child(loop_viz)
