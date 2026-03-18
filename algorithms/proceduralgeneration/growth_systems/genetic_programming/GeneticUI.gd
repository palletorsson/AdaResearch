extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var gp_node: Node
var pop_slider: Node3D
var gen_slider: Node3D
var type_slider: Node3D
var auto_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	gp_node = get_node_or_null("../../GeneticProgramming")

	# Status / generation label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Genetic Programming"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Population slider
	pop_slider = VRSlider.instantiate()
	pop_slider.position = Vector3(0, 0.3, 0)
	add_child(pop_slider)
	pop_slider.set_param_name("Population")
	pop_slider.slider_moved.connect(_on_pop_changed)

	# Generations slider
	gen_slider = VRSlider.instantiate()
	gen_slider.position = Vector3(0, 0.18, 0)
	add_child(gen_slider)
	gen_slider.set_param_name("Generations")
	gen_slider.slider_moved.connect(_on_gen_changed)

	# Type slider (discrete steps)
	type_slider = VRSlider.instantiate()
	type_slider.position = Vector3(0, 0.06, 0)
	add_child(type_slider)
	type_slider.set_param_name("Genome Type")
	type_slider.slider_moved.connect(_on_type_changed)

	# Auto-evolve toggle slider
	auto_slider = VRSlider.instantiate()
	auto_slider.position = Vector3(0, -0.06, 0)
	add_child(auto_slider)
	auto_slider.set_param_name("Auto Evolve")
	auto_slider.slider_moved.connect(_on_auto_toggled)

	# Evolve button
	var evolve_btn = VRButton.instantiate()
	evolve_btn.position = Vector3(-0.1, -0.22, 0)
	add_child(evolve_btn)
	var evolve_area = evolve_btn.get_node_or_null("InteractableAreaButton")
	if evolve_area:
		evolve_area.button_pressed.connect(_on_evolve_pressed)

	# Reset button
	var reset_btn = VRButton.instantiate()
	reset_btn.position = Vector3(0.1, -0.22, 0)
	add_child(reset_btn)
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)

	_update_ui()

func _update_ui() -> void:
	if not gp_node:
		return
	pop_slider.set_normalized_value(remap(gp_node.population_size, 10, 200, 0.0, 1.0))
	gen_slider.set_normalized_value(remap(gp_node.max_generations, 1, 100, 0.0, 1.0))
	type_slider.set_normalized_value(remap(gp_node.genome_type, 0, 3, 0.0, 1.0))
	auto_slider.set_normalized_value(1.0 if gp_node.auto_evolve else 0.0)

func _process(_delta: float) -> void:
	if gp_node and status_label:
		var txt = "Generation: %d" % gp_node.current_generation
		if gp_node.best_genome:
			txt += "\nBest Fitness: %.2f" % gp_node.best_genome.fitness
		status_label.text = txt

func _on_reset_pressed() -> void:
	if not gp_node:
		return
	gp_node.population_size = int(remap(pop_slider.get_normalized_value(), 0.0, 1.0, 10, 200))
	gp_node.max_generations = int(remap(gen_slider.get_normalized_value(), 0.0, 1.0, 1, 100))
	gp_node.genome_type = int(remap(type_slider.get_normalized_value(), 0.0, 1.0, 0, 3))
	gp_node.auto_evolve = auto_slider.get_normalized_value() > 0.5
	gp_node.initialize_population()

func _on_evolve_pressed() -> void:
	if not gp_node:
		return
	gp_node.evolve_generation()

func _on_auto_toggled(_value: float) -> void:
	if not gp_node:
		return
	gp_node.auto_evolve = auto_slider.get_normalized_value() > 0.5

func _on_pop_changed(_value: float) -> void:
	pass

func _on_gen_changed(_value: float) -> void:
	pass

func _on_type_changed(_value: float) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
