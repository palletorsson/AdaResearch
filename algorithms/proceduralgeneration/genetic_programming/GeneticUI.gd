extends Control

@onready var gp_node = $"../../GeneticProgramming"
@onready var pop_slider = $Panel/VBoxContainer/PopSlider
@onready var gen_slider = $Panel/VBoxContainer/GenSlider
@onready var type_option = $Panel/VBoxContainer/TypeOption
@onready var auto_check = $Panel/VBoxContainer/AutoCheck
@onready var evolve_btn = $Panel/VBoxContainer/EvolveButton
@onready var generation_label = $Panel/VBoxContainer/GenerationLabel

func _ready():
	_update_ui()

func _update_ui():
	if not gp_node: return
	pop_slider.value = gp_node.population_size
	gen_slider.value = gp_node.max_generations
	type_option.selected = gp_node.genome_type
	auto_check.button_pressed = gp_node.auto_evolve

func _process(_delta):
	if gp_node:
		generation_label.text = "Generation: %d" % gp_node.current_generation
		if gp_node.best_genome:
			generation_label.text += "\nBest Fitness: %.2f" % gp_node.best_genome.fitness

func _on_reset_pressed():
	gp_node.population_size = int(pop_slider.value)
	gp_node.max_generations = int(gen_slider.value)
	gp_node.genome_type = type_option.selected
	gp_node.auto_evolve = auto_check.button_pressed
	gp_node.initialize_population()

func _on_evolve_pressed():
	gp_node.evolve_generation()

func _on_auto_toggled(button_pressed):
	gp_node.auto_evolve = button_pressed
	evolve_btn.disabled = button_pressed

func _on_pop_changed(value):
	$Panel/VBoxContainer/PopLabel.text = "Population: %d" % int(value)
