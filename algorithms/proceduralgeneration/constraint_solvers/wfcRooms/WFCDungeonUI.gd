extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var wfc_node: Node
var width_slider: Node3D
var height_slider: Node3D
var seed_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	wfc_node = get_node_or_null("../../WFC_DungeonGenerator")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "WFC Dungeon"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Width slider
	width_slider = VRSlider.instantiate()
	width_slider.position = Vector3(0, 0.3, 0)
	add_child(width_slider)
	width_slider.set_param_name("Width")
	width_slider.slider_moved.connect(_on_width_changed)

	# Height slider
	height_slider = VRSlider.instantiate()
	height_slider.position = Vector3(0, 0.18, 0)
	add_child(height_slider)
	height_slider.set_param_name("Height")
	height_slider.slider_moved.connect(_on_height_changed)

	# Seed slider
	seed_slider = VRSlider.instantiate()
	seed_slider.position = Vector3(0, 0.06, 0)
	add_child(seed_slider)
	seed_slider.set_param_name("Seed")
	seed_slider.slider_moved.connect(_on_seed_changed)

	# Regenerate button
	var regen_btn = VRButton.instantiate()
	regen_btn.position = Vector3(-0.1, -0.1, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)

	# Randomize button
	var rand_btn = VRButton.instantiate()
	rand_btn.position = Vector3(0.1, -0.1, 0)
	add_child(rand_btn)
	var rand_area = rand_btn.get_node_or_null("InteractableAreaButton")
	if rand_area:
		rand_area.button_pressed.connect(_on_randomize_pressed)

	_update_ui()

func _update_ui() -> void:
	if not wfc_node:
		return
	width_slider.set_normalized_value(remap(wfc_node.grid_width, 3, 20, 0.0, 1.0))
	height_slider.set_normalized_value(remap(wfc_node.grid_height, 3, 20, 0.0, 1.0))
	seed_slider.set_normalized_value(0.5)

func _on_regenerate_pressed() -> void:
	if not wfc_node:
		return
	status_label.text = "Generating..."
	await get_tree().process_frame

	wfc_node.generation_seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))
	var success = wfc_node.generate_dungeon()

	if success:
		status_label.text = "Status: Success"
	else:
		status_label.text = "Status: Failed (Contradiction)"

func _on_randomize_pressed() -> void:
	if not wfc_node:
		return
	seed_slider.set_normalized_value(randf())
	_on_regenerate_pressed()

func _on_width_changed(_value: float) -> void:
	if not wfc_node:
		return
	var w = int(remap(width_slider.get_normalized_value(), 0.0, 1.0, 3, 20))
	wfc_node.grid_width = w

func _on_height_changed(_value: float) -> void:
	if not wfc_node:
		return
	var h = int(remap(height_slider.get_normalized_value(), 0.0, 1.0, 3, 20))
	wfc_node.grid_height = h

func _on_seed_changed(_value: float) -> void:
	if not wfc_node:
		return
	wfc_node.generation_seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
