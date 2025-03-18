extends Node2D

# Ecosystem parameters
var prey_population: int = 50
var predator_population: int = 5
var food_amount: int = 100
var mutation_rate: float = 0.1
var proximity_for_mating: float = 30.0

# Arrays to hold our entities
var prey_list = []
var predator_list = []
var food_list = []

# Debug label
var debug_label: Label

func _ready():
	# Add debug label
	debug_label = Label.new()
	debug_label.position = Vector2(10, 10)
	add_child(debug_label)
	
	# Initialize the ecosystem
	for i in range(prey_population):
		spawn_prey(Vector2(randf_range(0, get_viewport_rect().size.x), 
					 randf_range(0, get_viewport_rect().size.y)))
	
	for i in range(predator_population):
		spawn_predator(Vector2(randf_range(0, get_viewport_rect().size.x), 
						 randf_range(0, get_viewport_rect().size.y)))
	
	spawn_food(food_amount)
	
	print("Ecosystem initialized with: ", prey_list.size(), " prey, ", predator_list.size(), " predators, and ", food_list.size(), " food")

func _process(delta):
	# Update debug info
	debug_label.text = "Prey: " + str(prey_list.size()) + "\n"
	debug_label.text += "Predators: " + str(predator_list.size()) + "\n"
	debug_label.text += "Food: " + str(food_list.size())
	
	# Update all entities
	update_prey(delta)
	update_predators(delta)

	# Periodically spawn new food
	if randf() < 0.01: # Reduced from 0.05 to 0.01 to prevent food overflow
		spawn_food(1)
	
	# Check for balance and adjust if necessary
	balance_ecosystem()
	
func update_prey(delta):
	var prey_to_remove = []
	
	for prey in prey_list:
		prey.update(delta)
		
		# Check for nearby food
		var food_eaten = null
		for food in food_list:
			var distance = prey.position.distance_to(food.position)
			if distance < prey.size + food.size:
				prey.eat_food(food.nutrition)
				food_eaten = food
				break
		
		# Remove eaten food
		if food_eaten:
			food_list.erase(food_eaten)
			food_eaten.queue_free()
		
		# Check for nearby predators to flee from
		var flee_force = Vector2.ZERO
		for predator in predator_list:
			var distance = prey.position.distance_to(predator.position)
			if distance < prey.dna["perception_radius"]:
				var flee = prey.flee(predator.position)
				flee_force += flee * prey.dna["flee_weight"]
		
		prey.apply_force(flee_force)
		
		# Check for reproduction
		if prey.can_reproduce() and randf() < prey.dna["reproduction_rate"] * delta:
			check_for_mate(prey)
		
		# Mark dead prey for removal
		if prey.is_dead():
			prey_to_remove.append(prey)
	
	# Remove dead prey
	for prey in prey_to_remove:
		prey_list.erase(prey)
		prey.queue_free()

func update_predators(delta):
	var predators_to_remove = []
	
	for predator in predator_list:
		predator.update(delta)
		
		# Look for nearby prey to hunt
		var nearest_prey = null
		var min_distance = predator.dna["perception_radius"]
		
		for prey in prey_list:
			var distance = predator.position.distance_to(prey.position)
			if distance < min_distance:
				min_distance = distance
				nearest_prey = prey
		
		# Hunt the nearest prey
		if nearest_prey:
			var seek_force = predator.seek(nearest_prey.position) * predator.dna["seek_weight"]
			predator.apply_force(seek_force)
			
			# Check if close enough to eat
			if min_distance < predator.size + nearest_prey.size:
				predator.eat_prey(nearest_prey)
				prey_list.erase(nearest_prey)
				nearest_prey.queue_free()
		
		# Check for reproduction
		if predator.can_reproduce() and randf() < predator.dna["reproduction_rate"] * delta:
			check_for_mate(predator, true)
		
		# Mark dead predators for removal
		if predator.is_dead():
			predators_to_remove.append(predator)
	
	# Remove dead predators
	for predator in predators_to_remove:
		predator_list.erase(predator)
		predator.queue_free()

func check_for_mate(creature, is_predator = false):
	var creature_list = predator_list if is_predator else prey_list
	
	# Look for a potential mate nearby
	for potential_mate in creature_list:
		if potential_mate == creature:
			continue
			
		var distance = creature.position.distance_to(potential_mate.position)
		if distance < proximity_for_mating and potential_mate.can_reproduce():
			# Reproduce!
			var child_dna = crossover_dna(creature.dna, potential_mate.dna)
			child_dna = mutate_dna(child_dna)
			
			var spawn_pos = (creature.position + potential_mate.position) / 2
			if is_predator:
				spawn_predator(spawn_pos, child_dna)
			else:
				spawn_prey(spawn_pos, child_dna)
			
			# Reproduction costs energy
			creature.health -= 0.2
			potential_mate.health -= 0.2
			break

func crossover_dna(dna1, dna2):
	var child_dna = {}
	
	# For each gene, randomly choose from either parent or blend
	for key in dna1.keys():
		if randf() < 0.5:
			# Take from first parent
			child_dna[key] = dna1[key]
		else:
			# Take from second parent
			child_dna[key] = dna2[key]
	
	return child_dna

func mutate_dna(dna):
	var mutated_dna = dna.duplicate()
	
	for key in mutated_dna.keys():
		if randf() < mutation_rate:
			# Apply a random mutation
			var mutation_amount = randf_range(-0.2, 0.2)
			mutated_dna[key] = max(0.1, mutated_dna[key] * (1 + mutation_amount))
	
	return mutated_dna

func spawn_prey(pos, dna_values = {}):
	var prey = Prey.new(pos, dna_values)
	prey_list.append(prey)
	
	# Add visual representation
	var visual = ColorRect.new()
	visual.color = Color(0.2, 0.5, 0.8)  # Blue for prey
	visual.size = Vector2(prey.size * 2, prey.size * 2)
	visual.position = Vector2(-prey.size, -prey.size)  # Center it
	prey.add_child(visual)
	
	add_child(prey)
	return prey

func spawn_predator(pos, dna_values = {}):
	var predator = Predator.new(pos, dna_values)
	predator_list.append(predator)
	
	# Add visual representation - triangle for predator
	var visual = Node2D.new()
	predator.add_child(visual)
	
	# Using a polygon for triangle shape
	var polygon = Polygon2D.new()
	var size = predator.size
	polygon.polygon = PackedVector2Array([
		Vector2(0, -size),
		Vector2(-size, size),
		Vector2(size, size)
	])
	polygon.color = Color(0.8, 0.2, 0.2)  # Red for predator
	visual.add_child(polygon)
	
	add_child(predator)
	return predator

func spawn_food(amount: int):
	for i in range(amount):
		var pos = Vector2(randf_range(0, get_viewport_rect().size.x), 
					randf_range(0, get_viewport_rect().size.y))
		var food = Food.new(pos)
		food_list.append(food)
		
		# Add visual representation - circle for food
		var visual = ColorRect.new()
		visual.color = Color(0.2, 0.8, 0.2)  # Green for food
		visual.size = Vector2(food.size * 2, food.size * 2)
		visual.position = Vector2(-food.size, -food.size)  # Center it
		food.add_child(visual)
		
		add_child(food)

func balance_ecosystem():
	# Implement techniques to achieve balance
	
	# If prey population is critically low, boost reproduction or add new prey
	if prey_list.size() < 10:
		for i in range(5):
			spawn_prey(Vector2(randf_range(0, get_viewport_rect().size.x), 
						 randf_range(0, get_viewport_rect().size.y)))
	
	# If predator population is too high compared to prey, reduce predator efficiency
	if predator_list.size() > prey_list.size() * 0.5:
		for predator in predator_list:
			predator.health -= 0.05
	
	# If predator population is critically low, boost reproduction
	if predator_list.size() < 2 and prey_list.size() > 20:
		for i in range(2):
			spawn_predator(Vector2(randf_range(0, get_viewport_rect().size.x), 
							 randf_range(0, get_viewport_rect().size.y)))
