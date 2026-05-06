extends Node3D

var bsp_node: Node
var _control_panel: Node3D
var depth_slider: Node
var min_size_slider: Node
var gradient_slider: Node
var falloff_slider: Node
var bias_slider: Node
var status_label: Label3D

func _ready() -> void:
	bsp_node = get_node_or_null("../..")

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("BSP ROOMS", [
		[
			{"type": "slider_h", "label": "DEPTH", "default": 0.5},
			{"type": "slider_h", "label": "MIN SIZE", "default": 0.5},
			{"type": "slider_h", "label": "GRADIENT", "default": 0.5},
		],
		[
			{"type": "slider_h", "label": "FALLOFF", "default": 0.5},
			{"type": "slider_h", "label": "BIAS", "default": 0.5},
		],
		[
			{"type": "button", "label": "PARTITION"},
			{"type": "button", "label": "RANDOM"},
		],
	])
	_control_panel.position = Vector3(0, 0.35, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Status label above panel
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.font_size = 32
	status_label.text = "BSP Partitioning"
	status_label.modulate = Color.WHITE
	add_child(status_label)

	depth_slider = _control_panel.find_child("Param_0", true, false)
	min_size_slider = _control_panel.find_child("Param_1", true, false)
	gradient_slider = _control_panel.find_child("Param_2", true, false)
	falloff_slider = _control_panel.find_child("Param_3", true, false)
	bias_slider = _control_panel.find_child("Param_4", true, false)

	if depth_slider:
		depth_slider.slider_moved.connect(_on_depth_changed)
	if min_size_slider:
		min_size_slider.slider_moved.connect(_on_min_size_changed)
	if gradient_slider:
		gradient_slider.slider_moved.connect(_on_gradient_type_changed)
	if falloff_slider:
		falloff_slider.slider_moved.connect(_on_falloff_changed)
	if bias_slider:
		bias_slider.slider_moved.connect(_on_bias_changed)

	var part_btn = _control_panel.find_child("Btn_0", true, false)
	if part_btn:
		var area = part_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	var rand_btn = _control_panel.find_child("Btn_1", true, false)
	if rand_btn:
		var area = rand_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_random_pressed())

	_update_ui_from_node()
	if bsp_node:
		bsp_node.generate_bsp()
		_update_stats()

func _update_ui_from_node() -> void:
	if not bsp_node:
		return
	if depth_slider:
		depth_slider.set_normalized_value(remap(bsp_node.max_depth, 1, 10, 0.0, 1.0))
	if min_size_slider:
		min_size_slider.set_normalized_value(remap(bsp_node.min_cell_size, 0.5, 5.0, 0.0, 1.0))
	if gradient_slider:
		gradient_slider.set_normalized_value(remap(bsp_node.gradient_type, 0, 3, 0.0, 1.0))
	if falloff_slider:
		falloff_slider.set_normalized_value(bsp_node.gradient_falloff)
	if bias_slider:
		bias_slider.set_normalized_value(bsp_node.center_bias)

func _on_regenerate_pressed() -> void:
	if not bsp_node:
		return
	bsp_node.generate_bsp()
	_update_stats()

func _on_random_pressed() -> void:
	if not bsp_node:
		return
	if depth_slider:
		depth_slider.set_normalized_value(randf())
	if min_size_slider:
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
