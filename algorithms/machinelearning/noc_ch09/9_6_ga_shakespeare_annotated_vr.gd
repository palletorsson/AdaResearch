extends Node3D

const CONTROLLER_SCENE := preload("res://spatial_ui/parameter_controller_3d.tscn")

const TARGET_PHRASE := "To be or not to be."
const POPULATION_SIZE := 200
const UPDATE_INTERVAL := 0.2

var mutation_rate: float = 0.01

var _sim_root: Node3D
var _best_label: Label3D
var _stats_label: Label3D
var _samples_label: Label3D
var _controller_root: Node3D

var _population: Array[DNA] = []
var _fitness: Array[float] = []
var _generation: int = 1
var _elapsed: float = 0.0
var _finished: bool = false

func _ready() -> void:
	randomize()
	_setup_environment()
	_init_population()
	_update_texts()
	set_process(true)

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "SimulationRoot"
	add_child(_sim_root)


	_best_label = Label3D.new()
	_best_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_best_label.modulate = Color(1.0, 0.8, 1.0)
	_best_label.font_size = 26
	_best_label.position = Vector3(0, 0.75, 0)
	_sim_root.add_child(_best_label)

	_stats_label = Label3D.new()
	_stats_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_stats_label.modulate = Color(1.0, 0.85, 1.0)
	_stats_label.font_size = 16
	_stats_label.position = Vector3(0, 0.48, 0.05)
	_stats_label.width = 1.4
	_sim_root.add_child(_stats_label)

	_samples_label = Label3D.new()
	_samples_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_samples_label.modulate = Color(1.0, 0.8, 1.0, 0.75)
	_samples_label.font_size = 10
	_samples_label.position = Vector3(0, 0.2, 0.1)
	_samples_label.width = 1.4
	_sim_root.add_child(_samples_label)

	_create_controller()

func _create_controller() -> void:
	_controller_root = Node3D.new()
	_controller_root.position = Vector3(0.75, 0.45, 0)
	add_child(_controller_root)

	var mutation_controller := CONTROLLER_SCENE.instantiate()
	mutation_controller.parameter_name = "Mutation"
	mutation_controller.min_value = 0.0
	mutation_controller.max_value = 0.2
	mutation_controller.default_value = mutation_rate
	mutation_controller.rotation_degrees = Vector3(0, 90, 0)
	_controller_root.add_child(mutation_controller)
	mutation_controller.value_changed.connect(func(v: float) -> void:
		mutation_rate = clamp(v, 0.0, 0.2)
	)
	mutation_controller.set_value(mutation_rate)

func _init_population() -> void:
	_population.resize(POPULATION_SIZE)
	_fitness.resize(POPULATION_SIZE)
	for i in range(POPULATION_SIZE):
		_population[i] = DNA.new(TARGET_PHRASE.length())
		_fitness[i] = 0.0
	_generation = 1
	_finished = false

func _process(delta: float) -> void:
	if _finished:
		return
	_elapsed += delta
	if _elapsed >= UPDATE_INTERVAL:
		_elapsed = 0.0
		_run_generation()

func _run_generation() -> void:
	var best_phrase := ""
	var best_fit := -1.0
	var avg_fit := 0.0

	for i in range(_population.size()):
		_fitness[i] = _population[i].calculate_fitness(TARGET_PHRASE)
		avg_fit += _fitness[i]
		if _fitness[i] > best_fit:
			best_fit = _fitness[i]
			best_phrase = _population[i].get_phrase()

	avg_fit /= _population.size()

	var mating_pool: Array[DNA] = []
	for i in range(_population.size()):
		var n := int(_fitness[i] * 120.0)
		for j in range(n):
			mating_pool.append(_population[i])

	if mating_pool.is_empty():
		for dna in _population:
			mating_pool.append(dna)

	var new_pop: Array[DNA] = []
	for i in range(_population.size()):
		var parent_a := mating_pool[randi() % mating_pool.size()]
		var parent_b := mating_pool[randi() % mating_pool.size()]
		var child := parent_a.crossover(parent_b)
		child.mutate(mutation_rate)
		new_pop.append(child)

	_population = new_pop
	_generation += 1
	_update_texts(best_phrase, best_fit, avg_fit)

	if best_phrase == TARGET_PHRASE:
		_finished = true
		_update_texts(best_phrase, best_fit, avg_fit, true)

func _update_texts(best_phrase: String = "", best_fit: float = 0.0, avg_fit: float = 0.0, finished: bool = false) -> void:
	var phrase := best_phrase if best_phrase != "" else ""
	_best_label.text = "Best: %s" % phrase
	var stats := "Generation: %d\n" % _generation
	stats += "Average fitness: %.2f\n" % avg_fit
	stats += "Population: %d\n" % POPULATION_SIZE
	stats += "Mutation: %.2f%%" % (mutation_rate * 100.0)
	if finished:
		stats += "\nTarget reached!"
	_stats_label.text = stats
	_samples_label.text = _sample_text()

func _sample_text() -> String:
	var builder := PackedStringArray()
	var count: int = min(10, _population.size())
	for i in range(count):
		var idx: int = randi() % _population.size()
		builder.append(_population[idx].get_phrase())
	var result := ""
	for i in range(builder.size()):
		if i > 0:
			result += " \u2022 "
		result += builder[i]
	return result

class DNA:
	var genes: PackedStringArray

	func _init(length: int = 0) -> void:
		genes = PackedStringArray()
		genes.resize(length)
		for i in range(length):
			genes[i] = DNA._random_character()

	func get_phrase() -> String:
		var s := ""
		for i in range(genes.size()):
			s += genes[i]
		return s

	func calculate_fitness(target: String) -> float:
		var score := 0
		for i in range(genes.size()):
			if genes[i] == target.substr(i, 1):
				score += 1
		return pow(float(score) / max(1, target.length()), 4)

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

	static func _random_character() -> String:
		var code := randi_range(32, 126)
		return char(code)
