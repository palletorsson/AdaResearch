extends Node2D

@export var grid_size = 40
@export var population_size = 100
@export var mutation_rate = 0.01
@export var generations = 100

var ca_rules = []
var population = []
var fitness = []
var target_shape = []

var multimesh_instance: MultiMeshInstance2D

var current_generation = 0
var ca_grids = []
var ca_grid_index = 0

func _ready():
	multimesh_instance = $MultiMeshInstance2D
	$Timer.wait_time = 0.1
	$Timer.timeout.connect(stamp_ca_generation)
	create_target_shape()
	initialize_population()
	run_ga_generation()

func _process(delta):
	pass

func run_ga_generation():
	if current_generation < generations:
		evaluate_population()
		var best_fitness = fitness.max()
		print("Generation: ", current_generation, " Best Fitness: ", best_fitness)
		if best_fitness == 1.0:
			set_process(false)
			return
		
		select_new_population()
		
		var best_individual_index = fitness.find(fitness.max())
		var best_rules = population[best_individual_index]
		ca_grids = run_ca(best_rules)
		ca_grid_index = 0
		$Timer.start()
	else:
		set_process(false)

func stamp_ca_generation():
	if ca_grid_index < ca_grids.size():
		update_multimesh(ca_grids[ca_grid_index])
		ca_grid_index += 1
		$Timer.start()
	else:
		current_generation += 1
		run_ga_generation()

func create_target_shape():
	target_shape.resize(grid_size)
	for x in range(grid_size):
		target_shape[x] = []
		target_shape[x].resize(grid_size)
		for y in range(grid_size):
			if x >= 10 and x < 30 and y >= 10 and y < 30:
				target_shape[x][y] = 1
			else:
				target_shape[x][y] = 0

func initialize_population():
	population.resize(population_size)
	for i in range(population_size):
		population[i] = []
		population[i].resize(10) # 10 rules for the CA
		for j in range(10):
			population[i][j] = randi() % 2

func evaluate_population():
	fitness.resize(population_size)
	for i in range(population_size):
		var rules = population[i]
		var grids = run_ca(rules)
		fitness[i] = calculate_fitness(grids.back())

func run_ca(rules):
	var grids = []
	var grid = []
	grid.resize(grid_size)
	for x in range(grid_size):
		grid[x] = []
		grid[x].resize(grid_size)
		for y in range(grid_size):
			grid[x][y] = 0
	
	grid[grid_size / 2][grid_size / 2] = 1
	grids.append(grid.duplicate())

	for i in range(10): # Run the CA for 10 generations
		var next_grid = []
		next_grid.resize(grid_size)
		for x in range(grid_size):
			next_grid[x] = []
			next_grid[x].resize(grid_size)
			for y in range(grid_size):
				var neighbors = count_neighbors(grid, x, y)
				var current_state = grid[x][y]
				var rule_index = current_state * 9 + neighbors
				if rule_index < 10:
					next_grid[x][y] = rules[rule_index]
				else:
					next_grid[x][y] = 0
		grid = next_grid
		grids.append(grid.duplicate())
	return grids

func count_neighbors(grid, x, y):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			if i == 0 and j == 0:
				continue
			var nx = x + i
			var ny = y + j
			if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size:
				if grid[nx][ny] == 1:
					count += 1
	return count

func calculate_fitness(grid):
	var score = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == target_shape[x][y]:
				score += 1
	return float(score) / (grid_size * grid_size)

func select_new_population():
	var new_population = []
	new_population.resize(population_size)
	for i in range(population_size):
		var parent1 = tournament_selection()
		var parent2 = tournament_selection()
		var child = crossover(parent1, parent2)
		mutate(child)
		new_population[i] = child
	population = new_population

func tournament_selection():
	var best_individual_index = -1
	var best_fitness = -1
	for i in range(5): # Tournament size of 5
		var index = randi() % population_size
		if fitness[index] > best_fitness:
			best_fitness = fitness[index]
			best_individual_index = index
	return population[best_individual_index]

func crossover(parent1, parent2):
	var child = []
	child.resize(10)
	var crossover_point = randi() % 10
	for i in range(10):
		if i < crossover_point:
			child[i] = parent1[i]
		else:
			child[i] = parent2[i]
	return child

func mutate(child):
	for i in range(10):
		if randf() < mutation_rate:
			child[i] = 1 - child[i]

func update_multimesh(grid):
	var square_mesh = QuadMesh.new()
	square_mesh.size = Vector2(10, 10)
	var multimesh = MultiMesh.new()
	multimesh.mesh = square_mesh

	var instance_count = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == 1:
				instance_count += 1

	multimesh.instance_count = instance_count
	var instance_index = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == 1:
				var transform = Transform2D().translated(Vector2(x * 10, y * 10))
				multimesh.set_instance_transform_2d(instance_index, transform)
				instance_index += 1

	multimesh_instance.multimesh = multimesh
