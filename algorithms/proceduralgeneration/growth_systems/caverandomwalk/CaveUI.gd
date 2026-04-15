extends Node3D

var cave_node: Node
var width_slider: Node
var height_slider: Node
var walkers_slider: Node
var steps_slider: Node
var seed_slider: Node
var status_label: Label3D
var _control_panel: Node3D

func _ready() -> void:
	cave_node = get_node_or_null("../../Caverandomwalk")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Cave Random Walk"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("CAVE WALK", [
		[
			{"type": "slider_h", "label": "WIDTH", "default": 0.5},
			{"type": "slider_h", "label": "HEIGHT", "default": 0.5},
			{"type": "slider_h", "label": "WALKERS", "default": 0.5},
		],
		[
			{"type": "slider_h", "label": "STEPS", "default": 0.5},
			{"type": "slider_h", "label": "SEED", "default": 0.5},
		],
		[
			{"type": "button", "label": "GENERATE"},
			{"type": "button", "label": "RANDOM"},
		],
	])
	_control_panel.position = Vector3(0, 0.15, 0.3)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Extract slider references
	width_slider = _control_panel.find_child("Param_0", true, false)
	height_slider = _control_panel.find_child("Param_1", true, false)
	walkers_slider = _control_panel.find_child("Param_2", true, false)
	steps_slider = _control_panel.find_child("Param_3", true, false)
	seed_slider = _control_panel.find_child("Param_4", true, false)

	# Connect slider signals
	if width_slider and width_slider.has_signal("slider_moved"):
		width_slider.slider_moved.connect(_on_width_changed)
	if height_slider and height_slider.has_signal("slider_moved"):
		height_slider.slider_moved.connect(_on_height_changed)
	if walkers_slider and walkers_slider.has_signal("slider_moved"):
		walkers_slider.slider_moved.connect(_on_walkers_changed)
	if steps_slider and steps_slider.has_signal("slider_moved"):
		steps_slider.slider_moved.connect(_on_steps_changed)
	if seed_slider and seed_slider.has_signal("slider_moved"):
		seed_slider.slider_moved.connect(_on_seed_changed)

	# Connect button signals
	var gen_btn = _control_panel.find_child("Btn_0", true, false)
	if gen_btn:
		var gen_area = gen_btn.get_node_or_null("InteractableAreaButton")
		if gen_area:
			gen_area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	var rand_btn = _control_panel.find_child("Btn_1", true, false)
	if rand_btn:
		var rand_area = rand_btn.get_node_or_null("InteractableAreaButton")
		if rand_area:
			rand_area.button_pressed.connect(func(_b): _on_randomize_pressed())

	_update_ui()

func _update_ui() -> void:
	if not cave_node:
		return
	if width_slider and width_slider.has_method("set_normalized_value"):
		width_slider.set_normalized_value(remap(cave_node.grid_size.x, 5, 50, 0.0, 1.0))
	if height_slider and height_slider.has_method("set_normalized_value"):
		height_slider.set_normalized_value(remap(cave_node.grid_size.y, 5, 50, 0.0, 1.0))
	if walkers_slider and walkers_slider.has_method("set_normalized_value"):
		walkers_slider.set_normalized_value(remap(cave_node.walkers, 1, 20, 0.0, 1.0))
	if steps_slider and steps_slider.has_method("set_normalized_value"):
		steps_slider.set_normalized_value(remap(cave_node.steps_per_level, 10, 500, 0.0, 1.0))
	if seed_slider and seed_slider.has_method("set_normalized_value"):
		seed_slider.set_normalized_value(0.5)

func _on_regenerate_pressed() -> void:
	if not cave_node:
		return
	if seed_slider and seed_slider.has_method("get_normalized_value"):
		cave_node.seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))
	cave_node.regenerate()

func _on_randomize_pressed() -> void:
	if not cave_node:
		return
	cave_node.seed = randi()
	if seed_slider and seed_slider.has_method("set_normalized_value"):
		seed_slider.set_normalized_value(randf())
	cave_node.regenerate()

func _on_width_changed(_value: float) -> void:
	if not cave_node:
		return
	if width_slider and width_slider.has_method("get_normalized_value"):
		var w = int(remap(width_slider.get_normalized_value(), 0.0, 1.0, 5, 50))
		cave_node.grid_size.x = w
		cave_node.grid_size.z = w

func _on_height_changed(_value: float) -> void:
	if not cave_node:
		return
	if height_slider and height_slider.has_method("get_normalized_value"):
		cave_node.grid_size.y = int(remap(height_slider.get_normalized_value(), 0.0, 1.0, 5, 50))

func _on_walkers_changed(_value: float) -> void:
	if not cave_node:
		return
	if walkers_slider and walkers_slider.has_method("get_normalized_value"):
		cave_node.walkers = int(remap(walkers_slider.get_normalized_value(), 0.0, 1.0, 1, 20))

func _on_steps_changed(_value: float) -> void:
	if not cave_node:
		return
	if steps_slider and steps_slider.has_method("get_normalized_value"):
		cave_node.steps_per_level = int(remap(steps_slider.get_normalized_value(), 0.0, 1.0, 10, 500))

func _on_seed_changed(_value: float) -> void:
	if not cave_node:
		return
	if seed_slider and seed_slider.has_method("get_normalized_value"):
		cave_node.seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
