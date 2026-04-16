extends Control

var markov_node: Node
var height_slider: Node3D
var random_slider: Node3D
var animate_slider: Node3D

func _ready() -> void:
	markov_node = get_node_or_null("../../MarkovChainsTree")

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("MARKOV CHAIN", [
		[{"type": "slider_h", "label": "HEIGHT", "default": 0.5}],
		[{"type": "slider_h", "label": "RANDOM", "default": 0.5}],
		[{"type": "slider_h", "label": "ANIMATE", "default": 0.0}],
		[{"type": "button", "label": "REGEN"}],
	])
	panel.position = Vector3(0, 0.2, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# HEIGHT slider (Param_0)
	height_slider = panel.find_child("Param_0", true, false)
	if height_slider and height_slider.has_signal("slider_moved"):
		height_slider.slider_moved.connect(_on_height_changed)

	# RANDOM slider (Param_1)
	random_slider = panel.find_child("Param_1", true, false)
	if random_slider and random_slider.has_signal("slider_moved"):
		random_slider.slider_moved.connect(_on_random_changed)

	# ANIMATE slider (Param_2)
	animate_slider = panel.find_child("Param_2", true, false)
	if animate_slider and animate_slider.has_signal("slider_moved"):
		animate_slider.slider_moved.connect(_on_animate_toggled)

	# REGEN button (Btn_0)
	var regen_btn: Node = panel.find_child("Btn_0", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	_update_ui()

func _update_ui() -> void:
	if not markov_node:
		return
	if height_slider:
		height_slider.set_normalized_value(remap(markov_node.tree_height, 1, 10, 0.0, 1.0))
	if random_slider:
		random_slider.set_normalized_value(markov_node.randomness)
	if animate_slider:
		animate_slider.set_normalized_value(1.0 if markov_node.animate_growth else 0.0)

func _on_regenerate_pressed() -> void:
	if not markov_node:
		return
	if height_slider:
		markov_node.tree_height = remap(height_slider.get_normalized_value(), 0.0, 1.0, 1, 10)
	if random_slider:
		markov_node.randomness = random_slider.get_normalized_value()
	if animate_slider:
		markov_node.animate_growth = animate_slider.get_normalized_value() > 0.5
	markov_node.grow_tree()

func _on_height_changed(_value: float) -> void:
	pass

func _on_random_changed(_value: float) -> void:
	pass

func _on_animate_toggled(_value: float) -> void:
	if not markov_node:
		return
	if animate_slider:
		markov_node.animate_growth = animate_slider.get_normalized_value() > 0.5

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
