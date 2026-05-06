extends Node3D

## GA + Cellular Automaton Shape Learner (3D).
## Evolves 3D CA rules to grow target shapes (cube, sphere, pyramid) from a single seed voxel.
## Uses MultiMesh for fast instanced rendering of the voxel grid.

const CUBE_SCENE = preload("res://commons/primitives/cubes/cube_scene.tscn")

# ──────────────────────────────────────────────
# Tunable parameters
# ──────────────────────────────────────────────
@export_range(5, 30) var grid_size = 10
@export_range(5, 100) var population_size = 20
@export_range(0.001, 0.1) var mutation_rate = 0.01
@export_range(10, 200) var generations = 50
@export_range(1, 20) var ca_generations = 5
@export_range(1, 20) var individuals_per_frame = 5

enum TargetShape { CUBE, SPHERE, PYRAMID }
@export var target_shape_enum: TargetShape = TargetShape.CUBE

var population = []
var fitness = []
var target_shape = []

var multimesh_instance: MultiMeshInstance3D

var current_generation = 0
var ca_grids = []
var ca_grid_index = 0
var _best_fitness_ever: float = 0.0
var _status_label: Label3D

# Async evaluation state
var is_evaluating = false
var current_eval_index = 0

func _ready() -> void:
	multimesh_instance = $MultiMeshInstance3D
	$Timer.wait_time = 0.1
	$Timer.timeout.connect(stamp_ca_generation)
	
	# 3D HUD label
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 42
	_status_label.modulate = Color(1.0, 0.85, 0.2)
	_status_label.outline_modulate = Color(0, 0, 0, 0.6)
	_status_label.outline_size = 4
	_status_label.position = Vector3(grid_size * 0.25, grid_size + 2, grid_size * 0.25)
	_status_label.text = "GA Shape Learner 3D — Gen 0"
	add_child(_status_label)
	
	create_target_shape()
	initialize_population()
	run_ga_generation()

func _process(_delta):
	# Process evaluation asynchronously
	if is_evaluating:
		evaluate_population_async()

func run_ga_generation() -> void:
	if current_generation < generations:
		# Start async evaluation
		is_evaluating = true
		current_eval_index = 0
		fitness.resize(population_size)
		fitness.fill(0.0)
	else:
		set_process(false)

func finish_ga_generation() -> void:
	var best_fitness = fitness.max()
	_best_fitness_ever = max(_best_fitness_ever, best_fitness)
	print("Gen %d | Best %.4f | Record %.4f" % [current_generation, best_fitness, _best_fitness_ever])
	
	# Update HUD
	if _status_label:
		_status_label.text = "Gen %d | Fit %.2f%% | Record %.2f%%" % [current_generation, best_fitness * 100, _best_fitness_ever * 100]
	
	if best_fitness == 1.0:
		is_evaluating = false
		set_process(false)
		if _status_label:
			_status_label.text = "🎉 Perfect shape at Gen %d!" % current_generation
			_status_label.modulate = Color(0.3, 0.85, 0.4)
		return

	select_new_population()

	var best_individual_index = fitness.find(fitness.max())
	var best_rules = population[best_individual_index]
	ca_grids = run_ca(best_rules)
	ca_grid_index = 0
	$Timer.start()

func stamp_ca_generation() -> void:
	if ca_grid_index < ca_grids.size():
		update_multimesh(ca_grids[ca_grid_index])
		ca_grid_index += 1
		$Timer.start()
	else:
		current_generation += 1
		run_ga_generation()

func create_target_shape() -> void:
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

func initialize_population() -> void:
	population.resize(population_size)
	for i in range(population_size):
		population[i] = []
		population[i].resize(27) # 27 rules for the 3D CA
		for j in range(27):
			population[i][j] = randi() % 2

func evaluate_population_async() -> void:
	# Evaluate a few individuals per frame to avoid freezing
	var end_index = min(current_eval_index + individuals_per_frame, population_size)

	for i in range(current_eval_index, end_index):
		var rules = population[i]
		var grids = run_ca(rules)
		fitness[i] = calculate_fitness(grids.back())

	current_eval_index = end_index

	# Check if we're done evaluating all individuals
	if current_eval_index >= population_size:
		is_evaluating = false
		finish_ga_generation()

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
	
	grid[grid_size / 2][grid_size / 2][grid_size / 2] = 1
	grids.append(grid.duplicate(true))

	for i in range(ca_generations):
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
	# Pre-calculate bounds to avoid repeated checks
	var x_start = max(0, x - 1)
	var x_end = min(grid_size - 1, x + 1)
	var y_start = max(0, y - 1)
	var y_end = min(grid_size - 1, y + 1)
	var z_start = max(0, z - 1)
	var z_end = min(grid_size - 1, z + 1)

	for i in range(x_start, x_end + 1):
		for j in range(y_start, y_end + 1):
			for k in range(z_start, z_end + 1):
				if i == x and j == y and k == z:
					continue
				if grid[i][j][k] == 1:
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

func select_new_population() -> void:
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

func mutate(child) -> void:
	for i in range(27):
		if randf() < mutation_rate:
			child[i] = 1 - child[i]

func update_multimesh(grid) -> void:
	var multimesh = MultiMesh.new()
	multimesh.transform_format = MultiMesh.TRANSFORM_3D
	multimesh.use_colors = true  # Per-instance colour coding
	var cube_scene = CUBE_SCENE.instantiate()
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
					# Green = matches target, blue = extra cell, red = wrong spot
					var in_target = (x < target_shape.size() and y < target_shape[x].size() and z < target_shape[x][y].size() and target_shape[x][y][z] == 1)
					var cell_color = Color(0.3, 0.85, 0.4) if in_target else Color(0.9, 0.3, 0.3, 0.7)
					multimesh.set_instance_color(instance_index, cell_color)
					instance_index += 1

	multimesh_instance.multimesh = multimesh

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
