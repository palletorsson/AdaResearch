extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var bsp_node: Node
var depth_slider: Node3D
var min_size_slider: Node3D
var gradient_slider: Node3D
var falloff_slider: Node3D
var bias_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	bsp_node = get_node_or_null("../..")

	# Stats label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "BSP Partitioning"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Depth slider
	depth_slider = VRSlider.instantiate()
	depth_slider.position = Vector3(0, 0.3, 0)
	add_child(depth_slider)
	depth_slider.set_param_name("Max Depth")
	depth_slider.slider_moved.connect(_on_depth_changed)

	# Min cell size slider
	min_size_slider = VRSlider.instantiate()
	min_size_slider.position = Vector3(0, 0.18, 0)
	add_child(min_size_slider)
	min_size_slider.set_param_name("Min Cell Size")
	min_size_slider.slider_moved.connect(_on_min_size_changed)

	# Gradient type slider
	gradient_slider = VRSlider.instantiate()
	gradient_slider.position = Vector3(0, 0.06, 0)
	add_child(gradient_slider)
	gradient_slider.set_param_name("Gradient Type")
	gradient_slider.slider_moved.connect(_on_gradient_type_changed)

	# Falloff slider
	falloff_slider = VRSlider.instantiate()
	falloff_slider.position = Vector3(0, -0.06, 0)
	add_child(falloff_slider)
	falloff_slider.set_param_name("Falloff")
	falloff_slider.slider_moved.connect(_on_falloff_changed)

	# Bias slider
	bias_slider = VRSlider.instantiate()
	bias_slider.position = Vector3(0, -0.18, 0)
	add_child(bias_slider)
	bias_slider.set_param_name("Center Bias")
	bias_slider.slider_moved.connect(_on_bias_changed)

	# Partition button
	var partition_btn = VRButton.instantiate()
	partition_btn.position = Vector3(-0.1, -0.34, 0)
	add_child(partition_btn)
	var part_area = partition_btn.get_node_or_null("InteractableAreaButton")
	if part_area:
		part_area.button_pressed.connect(_on_regenerate_pressed)

	# Random button
	var random_btn = VRButton.instantiate()
	random_btn.position = Vector3(0.1, -0.34, 0)
	add_child(random_btn)
	var rand_area = random_btn.get_node_or_null("InteractableAreaButton")
	if rand_area:
		rand_area.button_pressed.connect(_on_random_pressed)

	_update_ui_from_node()
	if bsp_node:
		bsp_node.generate_bsp()
		_update_stats()

func _update_ui_from_node() -> void:
	if not bsp_node:
		return
	depth_slider.set_normalized_value(remap(bsp_node.max_depth, 1, 10, 0.0, 1.0))
	min_size_slider.set_normalized_value(remap(bsp_node.min_cell_size, 0.5, 5.0, 0.0, 1.0))
	gradient_slider.set_normalized_value(remap(bsp_node.gradient_type, 0, 3, 0.0, 1.0))
	falloff_slider.set_normalized_value(bsp_node.gradient_falloff)
	bias_slider.set_normalized_value(bsp_node.center_bias)

func _on_regenerate_pressed() -> void:
	if not bsp_node:
		return
	bsp_node.generate_bsp()
	_update_stats()

func _on_random_pressed() -> void:
	if not bsp_node:
		return
	depth_slider.set_normalized_value(randf())
	min_size_slider.set_normalized_value(randf())
	_on_depth_changed(0.0)
	_on_min_size_changed(0.0)
	bsp_node.generate_bsp()
	_update_stats()

func _on_depth_changed(_value: float) -> void:
	if not bsp_node:
		return
	bsp_node.max_depth = int(remap(depth_slider.get_normalized_value(), 0.0, 1.0, 1, 10))
	bsp_node.generate_bsp()
	_update_stats()

func _on_min_size_changed(_value: float) -> void:
	if not bsp_node:
		return
	bsp_node.min_cell_size = remap(min_size_slider.get_normalized_value(), 0.0, 1.0, 0.5, 5.0)
	bsp_node.generate_bsp()
	_update_stats()

func _on_gradient_type_changed(_value: float) -> void:
	if not bsp_node:
		return
	bsp_node.gradient_type = int(remap(gradient_slider.get_normalized_value(), 0.0, 1.0, 0, 3))
	bsp_node.generate_bsp()
	_update_stats()

func _on_falloff_changed(_value: float) -> void:
	if not bsp_node:
		return
	bsp_node.gradient_falloff = falloff_slider.get_normalized_value()
	bsp_node.generate_bsp()

func _on_bias_changed(_value: float) -> void:
	if not bsp_node:
		return
	bsp_node.center_bias = bias_slider.get_normalized_value()
	bsp_node.generate_bsp()

func _update_stats() -> void:
	if not bsp_node:
		return
	var cell_count = bsp_node.all_cells.size()
	status_label.text = "BSP — Cells: %d" % cell_count

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
