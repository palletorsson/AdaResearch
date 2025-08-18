extends Node3D

var time = 0.0
var ant_count = 20
var ants = []
var food_sources = []
var pheromone_grid = []
var pheromone_trails = []
var grid_size = 20
var cell_size = 0.4

# ACO parameters
var pheromone_evaporation = 0.95
var pheromone_deposit = 10.0
var alpha = 1.0  # Pheromone importance
var beta = 2.0   # Distance importance

class Ant:
	var position: Vector2
	var target: Vector2
	var has_food: bool = false
	var path: Array = []
	var visual_object: CSGSphere3D
	var speed: float = 2.0
	
	func _init(start_pos: Vector2):
		position = start_pos
		target = start_pos
		path = []

func _ready():
	create_pheromone_grid()
	create_food_sources()
	create_ants()
	setup_materials()

func create_pheromone_grid():
	for x in range(grid_size):
		pheromone_grid.append([])
		for y in range(grid_size):
			pheromone_grid[x].append(0.0)

func create_food_sources():
	var food_parent = $FoodSources
	var food_positions = [
		Vector2(3, 3),
		Vector2(-4, 2),
		Vector2(2, -3),
		Vector2(-2, -4)
	]
	
	for pos in food_positions:
		var food = CSGSphere3D.new()
		food.radius = 0.3
		food.position = Vector3(pos.x, pos.y, 0.2)
		food_parent.add_child(food)
		food_sources.append(pos)

func create_ants():
	var ant_parent = $Ants
	
	for i in range(ant_count):
		var ant = Ant.new(Vector2.ZERO)
		
		# Create visual representation
		var ant_sphere = CSGSphere3D.new()
		ant_sphere.radius = 0.08
		ant_sphere.position = Vector3(0, 0, 0.1)
		ant_parent.add_child(ant_sphere)
		ant.visual_object = ant_sphere
		
		ants.append(ant)

func setup_materials():
	# Nest material
	var nest_material = StandardMaterial3D.new()
	nest_material.albedo_color = Color(0.6, 0.4, 0.2, 1.0)
	nest_material.emission_enabled = true
	nest_material.emission = Color(0.2, 0.1, 0.05, 1.0)
	$Nest.material_override = nest_material
	
	# Food materials
	var food_material = StandardMaterial3D.new()
	food_material.albedo_color = Color(0.2, 1.0, 0.2, 1.0)
	food_material.emission_enabled = true
	food_material.emission = Color(0.05, 0.3, 0.05, 1.0)
	
	for child in $FoodSources.get_children():
		child.material_override = food_material
	
	# Ant materials
	var ant_material = StandardMaterial3D.new()
	ant_material.albedo_color = Color(0.8, 0.2, 0.2, 1.0)
	ant_material.emission_enabled = true
	ant_material.emission = Color(0.3, 0.05, 0.05, 1.0)
	
	for ant in ants:
		ant.visual_object.material_override = ant_material
	
	# Control materials
	var pheromone_material = StandardMaterial3D.new()
	pheromone_material.albedo_color = Color(1.0, 0.8, 0.2, 1.0)
	pheromone_material.emission_enabled = true
	pheromone_material.emission = Color(0.3, 0.2, 0.05, 1.0)
	$PheromoneStrength.material_override = pheromone_material
	
	var count_material = StandardMaterial3D.new()
	count_material.albedo_color = Color(0.2, 0.8, 1.0, 1.0)
	count_material.emission_enabled = true
	count_material.emission = Color(0.05, 0.2, 0.3, 1.0)
	$AntCount.material_override = count_material

func _process(delta):
	time += delta
	
	update_ants(delta)
	evaporate_pheromones()
	update_pheromone_visualization()
	animate_swarm()
	animate_indicators()

func update_ants(delta):
	for ant in ants:
		if ant.has_food:
			# Return to nest
			ant.target = Vector2.ZERO
			move_ant_towards_target(ant, delta)
			
			# Check if reached nest
			if ant.position.distance_to(Vector2.ZERO) < 0.3:
				ant.has_food = false
				deposit_pheromone_on_path(ant)
				ant.path.clear()
		else:
			# Search for food
			if ant.target == ant.position or ant.position.distance_to(ant.target) < 0.2:
				choose_next_target(ant)
			
			move_ant_towards_target(ant, delta)
			
			# Check if reached food
			for food_pos in food_sources:
				if ant.position.distance_to(food_pos) < 0.5:
					ant.has_food = true
					ant.target = Vector2.ZERO
					break

func move_ant_towards_target(ant: Ant, delta):
	var direction = (ant.target - ant.position).normalized()
	var movement = direction * ant.speed * delta
	ant.position += movement
	ant.path.append(ant.position)
	
	# Update visual position
	ant.visual_object.position = Vector3(ant.position.x, ant.position.y, 0.1)

func choose_next_target(ant: Ant):
	# Use ACO algorithm to choose next target
	var possible_targets = []
	var probabilities = []
	
	# Generate possible targets in vicinity
	for dx in range(-2, 3):
		for dy in range(-2, 3):
			if dx == 0 and dy == 0:
				continue
			
			var new_target = ant.position + Vector2(dx, dy) * 0.5
			
			# Keep within bounds
			if abs(new_target.x) < 8 and abs(new_target.y) < 8:
				possible_targets.append(new_target)
	
	# Calculate probabilities based on pheromone and distance
	for target in possible_targets:
		var pheromone_level = get_pheromone_at_position(target)
		var distance = ant.position.distance_to(target)
		var heuristic = 1.0 / max(distance, 0.1)
		
		var probability = pow(pheromone_level + 0.1, alpha) * pow(heuristic, beta)
		probabilities.append(probability)
	
	# Select target based on probabilities
	if probabilities.size() > 0:
		var selected_index = weighted_random_choice(probabilities)
		ant.target = possible_targets[selected_index]
	else:
		# Fallback: random direction
		var angle = randf() * 2.0 * PI
		ant.target = ant.position + Vector2(cos(angle), sin(angle)) * 2.0

func weighted_random_choice(weights: Array) -> int:
	var total_weight = 0.0
	for weight in weights:
		total_weight += weight
	
	var random_value = randf() * total_weight
	var current_weight = 0.0
	
	for i in range(weights.size()):
		current_weight += weights[i]
		if random_value <= current_weight:
			return i
	
	return weights.size() - 1

func get_pheromone_at_position(pos: Vector2) -> float:
	var grid_x = int((pos.x + 4.0) / 8.0 * grid_size)
	var grid_y = int((pos.y + 4.0) / 8.0 * grid_size)
	
	grid_x = clamp(grid_x, 0, grid_size - 1)
	grid_y = clamp(grid_y, 0, grid_size - 1)
	
	return pheromone_grid[grid_x][grid_y]

func deposit_pheromone_on_path(ant: Ant):
	for point in ant.path:
		var grid_x = int((point.x + 4.0) / 8.0 * grid_size)
		var grid_y = int((point.y + 4.0) / 8.0 * grid_size)
		
		grid_x = clamp(grid_x, 0, grid_size - 1)
		grid_y = clamp(grid_y, 0, grid_size - 1)
		
		pheromone_grid[grid_x][grid_y] += pheromone_deposit / ant.path.size()

func evaporate_pheromones():
	for x in range(grid_size):
		for y in range(grid_size):
			pheromone_grid[x][y] *= pheromone_evaporation

func update_pheromone_visualization():
	# Clear existing trails
	for trail in pheromone_trails:
		trail.queue_free()
	pheromone_trails.clear()
	
	# Create new pheromone visualization
	var trail_parent = $PheromoneTrails
	
	for x in range(grid_size):
		for y in range(grid_size):
			var pheromone_level = pheromone_grid[x][y]
			
			if pheromone_level > 0.1:  # Only show significant pheromone levels
				var world_x = -4.0 + (x / float(grid_size)) * 8.0
				var world_y = -4.0 + (y / float(grid_size)) * 8.0
				
				var trail_point = CSGSphere3D.new()
				trail_point.radius = 0.03 + pheromone_level * 0.02
				trail_point.position = Vector3(world_x, world_y, 0.05)
				
				# Material based on pheromone strength
				var trail_material = StandardMaterial3D.new()
				var intensity = min(pheromone_level / 20.0, 1.0)
				trail_material.albedo_color = Color(
					0.8 + intensity * 0.2,
					0.8 - intensity * 0.4,
					0.2,
					0.5 + intensity * 0.5
				)
				trail_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
				trail_material.emission_enabled = true
				trail_material.emission = trail_material.albedo_color * 0.6
				trail_point.material_override = trail_material
				
				trail_parent.add_child(trail_point)
				pheromone_trails.append(trail_point)

func animate_swarm():
	# Animate ants
	for i in range(ants.size()):
		var ant = ants[i]
		var pulse = 1.0 + sin(time * 6.0 + i * 0.5) * 0.3
		ant.visual_object.scale = Vector3.ONE * pulse
		
		# Color based on whether carrying food
		var material = ant.visual_object.material_override as StandardMaterial3D
		if material:
			if ant.has_food:
				material.albedo_color = Color(0.2, 0.8, 0.2, 1.0)
				material.emission = Color(0.05, 0.3, 0.05, 1.0)
			else:
				material.albedo_color = Color(0.8, 0.2, 0.2, 1.0)
				material.emission = Color(0.3, 0.05, 0.05, 1.0)
	
	# Animate food sources
	for child in $FoodSources.get_children():
		var food_pulse = 1.0 + sin(time * 4.0 + child.position.x) * 0.2
		child.scale = Vector3.ONE * food_pulse
	
	# Animate pheromone trails
	for trail in pheromone_trails:
		var trail_pulse = 1.0 + sin(time * 8.0 + trail.position.x + trail.position.y) * 0.4
		trail.scale = Vector3.ONE * trail_pulse

func animate_indicators():
	# Pheromone strength indicator
	var total_pheromone = 0.0
	for x in range(grid_size):
		for y in range(grid_size):
			total_pheromone += pheromone_grid[x][y]
	
	var pheromone_height = (total_pheromone / 100.0) * 2.0 + 0.5
	$PheromoneStrength.height = pheromone_height
	$PheromoneStrength.position.y = -3 + pheromone_height/2
	
	# Ant count indicator
	var ants_with_food = 0
	for ant in ants:
		if ant.has_food:
			ants_with_food += 1
	
	var efficiency = float(ants_with_food) / ant_count
	var count_height = efficiency * 2.0 + 0.5
	$AntCount.height = count_height
	$AntCount.position.y = -3 + count_height/2
	
	# Pulsing effects
	var pulse = 1.0 + sin(time * 4.0) * 0.1
	$PheromoneStrength.scale.x = pulse
	$AntCount.scale.x = pulse
