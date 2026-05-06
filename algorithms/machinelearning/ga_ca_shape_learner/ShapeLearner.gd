extends Node3D

## GA + Cellular Automaton Shape Learner (3D VR version).
## Evolves CA rules via a genetic algorithm to grow a target shape from a seed cell.
## Each individual is a set of 10 CA rules that control cell birth/death.

# ──────────────────────────────────────────────
# Tunable parameters
# ──────────────────────────────────────────────
@export_range(10, 80) var grid_size: int = 40
@export_range(10, 500) var population_size: int = 100
@export_range(0.001, 0.1) var mutation_rate: float = 0.01
@export_range(10, 500) var generations: int = 100

var ca_rules: Array = []
var population: Array = []
var fitness: Array = []
var target_shape: Array = []

var current_generation: int = 0
var _best_fitness_ever: float = 0.0

var multimesh_instance: MultiMeshInstance3D
var timer: Timer
var info_label: Label3D
var cell_size: float

func _ready() -> void:
	# Calculate cell size so grid fits within 0.8m
	cell_size = 0.8 / grid_size

	_setup_multimesh()
	_setup_timer()
	_setup_label()

	create_target_shape()
	initialize_population()
	call_deferred("_start_ga")

func _start_ga() -> void:
	await run_ga_loop()

func _exit_tree() -> void:
	if is_instance_valid(multimesh_instance):
		multimesh_instance.queue_free()
	if is_instance_valid(timer):
		timer.queue_free()
	if is_instance_valid(info_label):
		info_label.queue_free()

# ──────────────────────────────────────────────
# Setup
# ──────────────────────────────────────────────

func _setup_multimesh() -> void:
	multimesh_instance = MultiMeshInstance3D.new()
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var box = BoxMesh.new()
	box.size = Vector3(cell_size * 0.9, cell_size * 0.9, cell_size * 0.9)
	mm.mesh = box
	mm.instance_count = 0
	multimesh_instance.multimesh = mm
	add_child(multimesh_instance)

func _setup_timer() -> void:
	timer = Timer.new()
	timer.wait_time = 0.1
	timer.one_shot = true
	add_child(timer)

func _setup_label() -> void:
	info_label = Label3D.new()
	info_label.position = Vector3(0.0, 0.05, -0.42)
	info_label.font_size = 32
	info_label.pixel_size = 0.001
	info_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(info_label)

# ──────────────────────────────────────────────
# GA loop
# ──────────────────────────────────────────────

func run_ga_loop() -> void:
	while current_generation < generations:
		await evaluate_population_async()
		var best_fitness = fitness.max()
		_best_fitness_ever = max(_best_fitness_ever, best_fitness)
		var best_individual_index = fitness.find(best_fitness)
		var best_rules = population[best_individual_index]
		info_label.text = "Gen %d | Fit %.3f | Best %.3f" % [
			current_generation, best_fitness, _best_fitness_ever]
		await display_ca_sequence(run_ca(best_rules))
		if best_fitness >= 1.0:
			info_label.text = "Perfect solution at gen %d!" % current_generation
			break
		select_new_population()
		current_generation += 1
		await get_tree().process_frame
	set_process(false)

func evaluate_population_async() -> void:
	fitness.resize(population_size)
	for i in range(population_size):
		var rules = population[i]
		var grids = run_ca(rules)
		fitness[i] = calculate_fitness(grids.back())
		if i % 5 == 0:
			await get_tree().process_frame

func display_ca_sequence(grids: Array) -> void:
	for grid in grids:
		update_multimesh(grid)
		timer.start()
		await timer.timeout

# ──────────────────────────────────────────────
# Target shape
# ──────────────────────────────────────────────

func create_target_shape() -> void:
	target_shape.resize(grid_size)
	for x in range(grid_size):
		target_shape[x] = []
		target_shape[x].resize(grid_size)
		for y in range(grid_size):
			if x >= 10 and x < 30 and y >= 10 and y < 30:
				target_shape[x][y] = 1
			else:
				target_shape[x][y] = 0

# ──────────────────────────────────────────────
# Population
# ──────────────────────────────────────────────

func initialize_population() -> void:
	population.resize(population_size)
	for i in range(population_size):
		population[i] = []
		population[i].resize(10)
		for j in range(10):
			population[i][j] = randi() % 2

# ──────────────────────────────────────────────
# Cellular automaton
# ──────────────────────────────────────────────

func run_ca(rules: Array) -> Array:
	var grids: Array = []
	var grid: Array = []
	grid.resize(grid_size)
	for x in range(grid_size):
		grid[x] = []
		grid[x].resize(grid_size)
		for y in range(grid_size):
			grid[x][y] = 0

	grid[grid_size / 2][grid_size / 2] = 1
	grids.append(grid.duplicate())

	for _step in range(10):
		var next_grid: Array = []
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

func count_neighbors(grid: Array, x: int, y: int) -> int:
	var count: int = 0
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

func calculate_fitness(grid: Array) -> float:
	var score: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == target_shape[x][y]:
				score += 1
	return float(score) / float(grid_size * grid_size)

# ──────────────────────────────────────────────
# Selection / crossover / mutation
# ──────────────────────────────────────────────

func select_new_population() -> void:
	var new_population: Array = []
	new_population.resize(population_size)
	for i in range(population_size):
		var parent1 = tournament_selection()
		var parent2 = tournament_selection()
		var child = crossover(parent1, parent2)
		mutate(child)
		new_population[i] = child
	population = new_population

func tournament_selection() -> Array:
	var best_individual_index: int = -1
	var best_fitness: float = -1.0
	for _t in range(5):
		var index = randi() % population_size
		if fitness[index] > best_fitness:
			best_fitness = fitness[index]
			best_individual_index = index
	return population[best_individual_index]

func crossover(parent1: Array, parent2: Array) -> Array:
	var child: Array = []
	child.resize(10)
	var crossover_point = randi() % 10
	for i in range(10):
		if i < crossover_point:
			child[i] = parent1[i]
		else:
			child[i] = parent2[i]
	return child

func mutate(child: Array) -> void:
	for i in range(10):
		if randf() < mutation_rate:
			child[i] = 1 - child[i]

# ──────────────────────────────────────────────
# Rendering
# ──────────────────────────────────────────────

func update_multimesh(grid: Array) -> void:
	var mm = multimesh_instance.multimesh

	# Count active cells
	var instance_count: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == 1:
				instance_count += 1

	mm.instance_count = instance_count

	# Half-grid offset to center the display
	var half_grid: float = grid_size * cell_size * 0.5

	var idx: int = 0
	for x in range(grid_size):
		for y in range(grid_size):
			if grid[x][y] == 1:
				# Map grid X → world X, grid Y → world Z, flat on Y=0
				var world_pos = Vector3(
					x * cell_size - half_grid,
					0.0,
					y * cell_size - half_grid)
				mm.set_instance_transform(idx, Transform3D(Basis(), world_pos))
				# Green if matching target, blue otherwise
				var matches_target = (target_shape[x][y] == 1)
				var cell_color = Color(0.3, 0.85, 0.4) if matches_target else Color(0.3, 0.5, 0.9)
				mm.set_instance_color(idx, cell_color)
				idx += 1

# ──────────────────────────────────────────────
# Grid config stub
# ──────────────────────────────────────────────

func apply_grid_config(config: Dictionary) -> void:
	pass
