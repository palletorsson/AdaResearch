extends Node3D

var gp_node: Node
var pop_slider: Node
var gen_slider: Node
var type_slider: Node
var auto_slider: Node
var status_label: Label3D
var _control_panel: Node3D

func _ready() -> void:
	gp_node = get_node_or_null("../../GeneticProgramming")

	# Status / generation label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Genetic Programming"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# RackTemplates panel with 4 sliders
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_parameter_panel(
		4, ["POPULATION", "GENERATIONS", "GENOME TYPE", "AUTO EVOLVE"],
		[0.5, 0.3, 0.33, 1.0]
	)
	_control_panel.position = Vector3(0, 0.1, 0)
	add_child(_control_panel)

	pop_slider = _control_panel.get_node_or_null("Param_0")
	gen_slider = _control_panel.get_node_or_null("Param_1")
	type_slider = _control_panel.get_node_or_null("Param_2")
	auto_slider = _control_panel.get_node_or_null("Param_3")

	if pop_slider and pop_slider.has_signal("slider_moved"):
		pop_slider.slider_moved.connect(_on_pop_changed)
	if gen_slider and gen_slider.has_signal("slider_moved"):
		gen_slider.slider_moved.connect(_on_gen_changed)
	if type_slider and type_slider.has_signal("slider_moved"):
		type_slider.slider_moved.connect(_on_type_changed)
	if auto_slider and auto_slider.has_signal("slider_moved"):
		auto_slider.slider_moved.connect(_on_auto_toggled)

	# Reset button (built into panel) → evolve
	var reset_btn: Node = _control_panel.get_node_or_null("ResetButton")
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_evolve_pressed())

	_update_ui()

func _update_ui() -> void:
	if not gp_node:
		return
	if pop_slider and pop_slider.has_method("set_normalized_value"):
		pop_slider.set_normalized_value(remap(gp_node.population_size, 10, 200, 0.0, 1.0))
	if gen_slider and gen_slider.has_method("set_normalized_value"):
		gen_slider.set_normalized_value(remap(gp_node.max_generations, 1, 100, 0.0, 1.0))
	if type_slider and type_slider.has_method("set_normalized_value"):
		type_slider.set_normalized_value(remap(gp_node.genome_type, 0, 3, 0.0, 1.0))
	if auto_slider and auto_slider.has_method("set_normalized_value"):
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
	if pop_slider and pop_slider.has_method("get_normalized_value"):
		gp_node.population_size = int(remap(pop_slider.get_normalized_value(), 0.0, 1.0, 10, 200))
	if gen_slider and gen_slider.has_method("get_normalized_value"):
		gp_node.max_generations = int(remap(gen_slider.get_normalized_value(), 0.0, 1.0, 1, 100))
	if type_slider and type_slider.has_method("get_normalized_value"):
		gp_node.genome_type = int(remap(type_slider.get_normalized_value(), 0.0, 1.0, 0, 3))
	if auto_slider and auto_slider.has_method("get_normalized_value"):
		gp_node.auto_evolve = auto_slider.get_normalized_value() > 0.5
	gp_node.initialize_population()

func _on_evolve_pressed() -> void:
	if not gp_node:
		return
	gp_node.evolve_generation()

func _on_auto_toggled(_value) -> void:
	if not gp_node:
		return
	if auto_slider and auto_slider.has_method("get_normalized_value"):
		gp_node.auto_evolve = auto_slider.get_normalized_value() > 0.5

func _on_pop_changed(_value) -> void:
	pass

func _on_gen_changed(_value) -> void:
	pass

func _on_type_changed(_value) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
