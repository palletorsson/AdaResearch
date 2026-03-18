extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var markov_node: Node
var height_slider: Node3D
var random_slider: Node3D
var animate_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	markov_node = get_node_or_null("../../MarkovChainsTree")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Markov Chain Tree"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Height slider
	height_slider = VRSlider.instantiate()
	height_slider.position = Vector3(0, 0.3, 0)
	add_child(height_slider)
	height_slider.set_param_name("Tree Height")
	height_slider.slider_moved.connect(_on_height_changed)

	# Randomness slider
	random_slider = VRSlider.instantiate()
	random_slider.position = Vector3(0, 0.18, 0)
	add_child(random_slider)
	random_slider.set_param_name("Randomness")
	random_slider.slider_moved.connect(_on_random_changed)

	# Animate toggle (slider as 0/1 toggle)
	animate_slider = VRSlider.instantiate()
	animate_slider.position = Vector3(0, 0.06, 0)
	add_child(animate_slider)
	animate_slider.set_param_name("Animate")
	animate_slider.slider_moved.connect(_on_animate_toggled)

	# Regenerate button
	var regen_btn = VRButton.instantiate()
	regen_btn.position = Vector3(0, -0.1, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)

	_update_ui()

func _update_ui() -> void:
	if not markov_node:
		return
	height_slider.set_normalized_value(remap(markov_node.tree_height, 1, 10, 0.0, 1.0))
	random_slider.set_normalized_value(markov_node.randomness)
	animate_slider.set_normalized_value(1.0 if markov_node.animate_growth else 0.0)

func _on_regenerate_pressed() -> void:
	if not markov_node:
		return
	markov_node.tree_height = remap(height_slider.get_normalized_value(), 0.0, 1.0, 1, 10)
	markov_node.randomness = random_slider.get_normalized_value()
	markov_node.animate_growth = animate_slider.get_normalized_value() > 0.5
	markov_node.grow_tree()

func _on_height_changed(_value: float) -> void:
	pass

func _on_random_changed(_value: float) -> void:
	pass

func _on_animate_toggled(_value: float) -> void:
	if not markov_node:
		return
	markov_node.animate_growth = animate_slider.get_normalized_value() > 0.5

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
