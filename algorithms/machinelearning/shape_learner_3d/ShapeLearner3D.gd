extends Node3D

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

@export var grid_size = 20
@export var population_size = 100
@export var mutation_rate = 0.01
@export var generations = 100

enum TargetShape { CUBE, SPHERE, PYRAMID }
@export var target_shape_enum: TargetShape = TargetShape.CUBE

var population = []
var fitness = []
var target_shape = []

var multimesh_instance: MultiMeshInstance3D

var current_generation = 0
var ca_grids = []
var ca_grid_index = 0

func _ready():
	multimesh_instance = $MultiMeshInstance3D
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
			target_shape[x][y] = []
			target_shape[x][y].resize(grid_size)
			for z in range(grid_size):
				var is_in_shape = false
				match target_shape_enum:
					TargetShape.CUBE:
						if x >= 5 and x < 15 and y >= 5 and y < 15 and z >= 5 and z < 15:
							is_in_shape = true
					TargetShape.SPHERE:
						var center = Vector3(grid_size / 2.0, grid_size / 2.0, grid_size / 2.0)
						var pos = Vector3(x, y, z)
						if pos.distance_to(center) < grid_size / 4.0:
							is_in_shape = true
					TargetShape.PYRAMID:
						var height = 15
						if y < height:
							var size = height - y
							if abs(x - grid_size / 2) < size and abs(z - grid_size / 2) < size:
								is_in_shape = true
				if is_in_shape:
					target_shape[x][y][z] = 1
				else:
					target_shape[x][y][z] = 0

func initialize_population():
	population.resize(population_size)
	for i in range(population_size):
		population[i] = []
		population[i].resize(27) # 27 rules for the 3D CA
		for j in range(27):
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
			grid[x][y] = []
			grid[x][y].resize(grid_size)
			for z in range(grid_size):
				grid[x][y][z] = 0
	
	grid[grid_size / 2.0][grid_size / 2.0][grid_size / 2.0] = 1
	grids.append(grid.duplicate(true))

	for i in range(10): # Run the CA for 10 generations
		var next_grid = []
		next_grid.resize(grid_size)
		for x in range(grid_size):
			next_grid[x] = []
			next_grid[x].resize(grid_size)
			for y in range(grid_size):
				next_grid[x][y] = []
				next_grid[x][y].resize(grid_size)
				for z in range(grid_size):
					var neighbors = count_neighbors(grid, x, y, z)
					var current_state = grid[x][y][z]
					var rule_index = current_state * 14 + neighbors
					if rule_index < 27:
						next_grid[x][y][z] = rules[rule_index]
					else:
						next_grid[x][y][z] = 0
		grid = next_grid
		grids.append(grid.duplicate(true))
	return grids

func count_neighbors(grid, x, y, z):
	var count = 0
	for i in range(-1, 2):
		for j in range(-1, 2):
			for k in range(-1, 2):
				if i == 0 and j == 0 and k == 0:
					continue
				var nx = x + i
				var ny = y + j
				var nz = z + k
				if nx >= 0 and nx < grid_size and ny >= 0 and ny < grid_size and nz >= 0 and nz < grid_size:
					if grid[nx][ny][nz] == 1:
						count += 1
	return count

func calculate_fitness(grid):
	var score = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if grid[x][y][z] == target_shape[x][y][z]:
					score += 1
	return float(score) / (grid_size * grid_size * grid_size)

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
	child.resize(27)
	var crossover_point = randi() % 27
	for i in range(27):
		if i < crossover_point:
			child[i] = parent1[i]
		else:
			child[i] = parent2[i]
	return child

func mutate(child):
	for i in range(27):
		if randf() < mutation_rate:
			child[i] = 1 - child[i]

func update_multimesh(grid):
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	var cube_scene = CUBE_SCENE.instantiate()
	if not cube_scene:
		return
	var cube_mesh = cube_scene.get_node("CubeBaseStaticBody3D/CubeBaseMesh").mesh
	multimesh.mesh = cube_mesh
	cube_scene.queue_free()

	var instance_count = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if grid[x][y][z] == 1:
					instance_count += 1

	multimesh.instance_count = instance_count
	var instance_index = 0
	for x in range(grid_size):
		for y in range(grid_size):
			for z in range(grid_size):
				if grid[x][y][z] == 1:
					var transform = Transform3D().translated(Vector3(x, y, z)).scaled(Vector3(0.5, 0.5, 0.5))
					multimesh.set_instance_transform(instance_index, transform)
					instance_index += 1

	multimesh_instance.multimesh = multimesh
