extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var cave_node: Node
var width_slider: Node3D
var height_slider: Node3D
var walkers_slider: Node3D
var steps_slider: Node3D
var seed_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	cave_node = get_node_or_null("../../Caverandomwalk")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Cave Random Walk"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Width slider
	width_slider = VRSlider.instantiate()
	width_slider.position = Vector3(0, 0.3, 0)
	add_child(width_slider)
	width_slider.set_param_name("Grid Width")
	width_slider.slider_moved.connect(_on_width_changed)

	# Height slider
	height_slider = VRSlider.instantiate()
	height_slider.position = Vector3(0, 0.18, 0)
	add_child(height_slider)
	height_slider.set_param_name("Grid Height")
	height_slider.slider_moved.connect(_on_height_changed)

	# Walkers slider
	walkers_slider = VRSlider.instantiate()
	walkers_slider.position = Vector3(0, 0.06, 0)
	add_child(walkers_slider)
	walkers_slider.set_param_name("Walkers")
	walkers_slider.slider_moved.connect(_on_walkers_changed)

	# Steps slider
	steps_slider = VRSlider.instantiate()
	steps_slider.position = Vector3(0, -0.06, 0)
	add_child(steps_slider)
	steps_slider.set_param_name("Steps/Level")
	steps_slider.slider_moved.connect(_on_steps_changed)

	# Seed slider
	seed_slider = VRSlider.instantiate()
	seed_slider.position = Vector3(0, -0.18, 0)
	add_child(seed_slider)
	seed_slider.set_param_name("Seed")
	seed_slider.slider_moved.connect(_on_seed_changed)

	# Generate button
	var gen_btn = VRButton.instantiate()
	gen_btn.position = Vector3(-0.1, -0.34, 0)
	add_child(gen_btn)
	var gen_area = gen_btn.get_node_or_null("InteractableAreaButton")
	if gen_area:
		gen_area.button_pressed.connect(_on_regenerate_pressed)

	# Randomize button
	var rand_btn = VRButton.instantiate()
	rand_btn.position = Vector3(0.1, -0.34, 0)
	add_child(rand_btn)
	var rand_area = rand_btn.get_node_or_null("InteractableAreaButton")
	if rand_area:
		rand_area.button_pressed.connect(_on_randomize_pressed)

	_update_ui()

func _update_ui() -> void:
	if not cave_node:
		return
	width_slider.set_normalized_value(remap(cave_node.grid_size.x, 5, 50, 0.0, 1.0))
	height_slider.set_normalized_value(remap(cave_node.grid_size.y, 5, 50, 0.0, 1.0))
	walkers_slider.set_normalized_value(remap(cave_node.walkers, 1, 20, 0.0, 1.0))
	steps_slider.set_normalized_value(remap(cave_node.steps_per_level, 10, 500, 0.0, 1.0))
	seed_slider.set_normalized_value(0.5)

func _on_regenerate_pressed() -> void:
	if not cave_node:
		return
	cave_node.seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))
	cave_node.regenerate()

func _on_randomize_pressed() -> void:
	if not cave_node:
		return
	cave_node.seed = randi()
	seed_slider.set_normalized_value(randf())
	cave_node.regenerate()

func _on_width_changed(_value: float) -> void:
	if not cave_node:
		return
	var w = int(remap(width_slider.get_normalized_value(), 0.0, 1.0, 5, 50))
	cave_node.grid_size.x = w
	cave_node.grid_size.z = w

func _on_height_changed(_value: float) -> void:
	if not cave_node:
		return
	cave_node.grid_size.y = int(remap(height_slider.get_normalized_value(), 0.0, 1.0, 5, 50))

func _on_walkers_changed(_value: float) -> void:
	if not cave_node:
		return
	cave_node.walkers = int(remap(walkers_slider.get_normalized_value(), 0.0, 1.0, 1, 20))

func _on_steps_changed(_value: float) -> void:
	if not cave_node:
		return
	cave_node.steps_per_level = int(remap(steps_slider.get_normalized_value(), 0.0, 1.0, 10, 500))

func _on_seed_changed(_value: float) -> void:
	if not cave_node:
		return
	cave_node.seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
