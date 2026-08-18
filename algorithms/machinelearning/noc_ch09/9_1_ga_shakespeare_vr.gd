extends Node3D
const ARTIFACT_SCENE_PRESENTER := preload("res://commons/artifacts/ArtifactScenePresenter.gd")

## GA Shakespeare — evolves random strings toward a target phrase using
## a genetic algorithm with fitness-proportional selection and crossover.
## Demonstrates how evolutionary pressure drives convergence.

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

const TARGET_PHRASE := "to be or not to be"
const POPULATION_SIZE := 150
const UPDATE_INTERVAL := 0.25

var mutation_rate: float = 0.01

var _sim_root: Node3D
var _best_label: Label3D
var _target_label: Label3D
var _metrics_label: Label3D
var _sample_label: Label3D
var _controller_root: Node3D

var _population: Array[DNA] = []
var _generation: int = 1
var _elapsed: float = 0.0
var _best_phrase: String = ""
var _best_fitness: float = 0.0
var _solved: bool = false

func _ready() -> void:
	randomize()
	_setup_environment()
	_init_population()
	_update_labels()
	call_deferred("_apply_standard_presentation")
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_target_label = Label3D.new()
	_target_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_target_label.modulate = Color(1.0, 0.7, 0.9)
	_target_label.font_size = 28
	_target_label.text = "Target: " + TARGET_PHRASE
	_target_label.position = Vector3(0, 0.9, 0)
	_sim_root.add_child(_target_label)

	_best_label = Label3D.new()
	_best_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_best_label.modulate = Color(1.0, 0.9, 1.0)
	_best_label.font_size = 30
	_best_label.position = Vector3(0, 0.65, 0)
	_sim_root.add_child(_best_label)

	_metrics_label = Label3D.new()
	_metrics_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_metrics_label.modulate = Color(1.0, 0.8, 1.0, 0.9)
	_metrics_label.font_size = 18
	_metrics_label.position = Vector3(0, 0.45, 0.05)
	_sim_root.add_child(_metrics_label)

	_sample_label = Label3D.new()
	_sample_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_sample_label.modulate = Color(1.0, 0.8, 1.0, 0.7)
	_sample_label.font_size = 14
	_sample_label.position = Vector3(0, 0.2, 0.1)
	_sample_label.width = 1.2
	_sim_root.add_child(_sample_label)

	_create_controller()

func _create_controller() -> void:
	_controller_root = Node3D.new()
	_controller_root.name = "Controllers"
	_controller_root.position = Vector3(0.75, 0.5, 0)
	add_child(_controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.2
	mutation_controller.default_value = mutation_rate
	mutation_controller.position = Vector3(0, 0, 0)
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = clamp(v, 0.0, 0.2)
	)
	mutation_controller.set_value(mutation_rate)

func _init_population() -> void:
	_population.clear()
	for i in range(POPULATION_SIZE):
		_population.append(DNA.new(TARGET_PHRASE.length()))
	_generation = 1

func _process(delta: float) -> void:
	_elapsed += delta
	if _elapsed >= UPDATE_INTERVAL:
		_elapsed = 0.0
		_run_generation()

func _run_generation() -> void:
	if _solved:
		return
	
	var best: String = ""
	var best_fitness := -1.0

	for dna in _population:
		dna.calculate_fitness(TARGET_PHRASE)
		if dna.fitness > best_fitness:
			best_fitness = dna.fitness
			best = dna.get_phrase()

	_best_phrase = best
	_best_fitness = best_fitness
	
	# Check if solved
	if best_fitness >= 1.0:
		_solved = true
		_best_label.modulate = Color(0.3, 0.85, 0.4)  # Green flash for success

	var mating_pool: Array[DNA] = []
	for dna in _population:
		var n := int(dna.fitness * 100.0)
		for j in range(n):
			mating_pool.append(dna)

	if mating_pool.is_empty():
		mating_pool = _population.duplicate()

	var new_population: Array[DNA] = []
	for i in range(_population.size()):
		var parent_a := mating_pool[randi() % mating_pool.size()]
		var parent_b := mating_pool[randi() % mating_pool.size()]
		var child := parent_a.crossover(parent_b)
		child.mutate(mutation_rate)
		new_population.append(child)

	_population = new_population
	_generation += 1
	_update_labels()

func _update_labels() -> void:
	_best_label.text = "Best: " + _best_phrase
	# Colour the best label based on fitness — blue → green as it converges
	var fit_color = Color(0.3, 0.5, 0.9).lerp(Color(0.3, 0.85, 0.4), _best_fitness)
	if _solved:
		fit_color = Color(1.0, 0.85, 0.2)  # Gold when solved
	_best_label.modulate = fit_color
	_metrics_label.text = "Gen %d | Fit %.0f%% | Mutation %.2f" % [_generation, _best_fitness * 100, mutation_rate]
	_sample_label.text = _sample_population_text()

func _sample_population_text() -> String:
	var builder: Array[String] = []
	var sample_count = min(12, _population.size())
	for i in range(sample_count):
		var idx := randi() % _population.size()
		builder.append(_population[idx].get_phrase())
	return " | ".join(builder)

class DNA:
	var genes: Array[String]
	var fitness: float = 0.0

	static func _random_character() -> String:
		var code := randi_range(32, 126)
		return char(code)

	func _init(length: int = 0) -> void:
		genes = []
		genes.resize(length)
		for i in range(length):
			genes[i] = DNA._random_character()

	func get_phrase() -> String:
		return "".join(genes)

	func calculate_fitness(target: String) -> void:
		var score := 0
		for i in range(genes.size()):
			if genes[i] == target.substr(i, 1):
				score += 1
		fitness = float(score) / float(target.length())

	func crossover(partner: DNA) -> DNA:
		var child := DNA.new(genes.size())
		var midpoint := randi() % genes.size()
		for i in range(genes.size()):
			child.genes[i] = genes[i] if i < midpoint else partner.genes[i]
		return child

	func mutate(rate: float) -> void:
		for i in range(genes.size()):
			if randf() < rate:
				genes[i] = DNA._random_character()

func _apply_standard_presentation() -> void:
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	# out-of-tree guard: get_tree() is null once a map is torn down
	if not is_inside_tree():
		await tree_entered
	await get_tree().process_frame
	ARTIFACT_SCENE_PRESENTER.present(self, _sim_root)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass


