extends Node3D

var space_node: Node
var points_slider: Node3D
var influence_slider: Node3D
var kill_slider: Node3D
var animate_slider: Node3D
var type_slider: Node3D

func _ready() -> void:
	space_node = get_node_or_null("../../SpaceColonizationAlgorithm")

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("COLONIZATION", [
		[
			{"type": "slider_h", "label": "POINTS", "default": 0.5},
			{"type": "slider_h", "label": "INFLUENCE", "default": 0.5},
		],
		[
			{"type": "slider_h", "label": "KILL DIST", "default": 0.5},
			{"type": "slider_h", "label": "ANIMATE", "default": 0.0},
		],
		[{"type": "slider_h", "label": "DIST TYPE", "default": 0.0}],
		[
			{"type": "button", "label": "REGEN"},
			{"type": "button", "label": "RESET"},
		],
	])
	panel.position = Vector3(0, 0.1, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# POINTS slider (Param_0)
	points_slider = panel.find_child("Param_0", true, false)
	if points_slider and points_slider.has_signal("slider_moved"):
		points_slider.slider_moved.connect(_on_points_changed)

	# INFLUENCE slider (Param_1)
	influence_slider = panel.find_child("Param_1", true, false)
	if influence_slider and influence_slider.has_signal("slider_moved"):
		influence_slider.slider_moved.connect(_on_influence_changed)

	# KILL DIST slider (Param_2)
	kill_slider = panel.find_child("Param_2", true, false)
	if kill_slider and kill_slider.has_signal("slider_moved"):
		kill_slider.slider_moved.connect(_on_kill_changed)

	# ANIMATE slider (Param_3)
	animate_slider = panel.find_child("Param_3", true, false)
	if animate_slider and animate_slider.has_signal("slider_moved"):
		animate_slider.slider_moved.connect(_on_animation_toggled)

	# DIST TYPE slider (Param_4)
	type_slider = panel.find_child("Param_4", true, false)
	if type_slider and type_slider.has_signal("slider_moved"):
		type_slider.slider_moved.connect(_on_type_changed)

	# REGEN button (Btn_0)
	var regen_btn: Node = panel.find_child("Btn_0", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	# RESET button (Btn_1)
	var reset_btn: Node = panel.find_child("Btn_1", true, false)
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_reset_pressed())

	_update_ui()

func _update_ui() -> void:
	if not space_node:
		return
	if points_slider:
		points_slider.set_normalized_value(remap(space_node.attraction_points_count, 10, 500, 0.0, 1.0))
	if influence_slider:
		influence_slider.set_normalized_value(remap(space_node.influence_distance, 0.1, 5.0, 0.0, 1.0))
	if kill_slider:
		kill_slider.set_normalized_value(remap(space_node.kill_distance, 0.01, 2.0, 0.0, 1.0))
	if animate_slider:
		animate_slider.set_normalized_value(1.0 if space_node.show_growth_animation else 0.0)
	if type_slider:
		type_slider.set_normalized_value(remap(space_node.distribution_type, 0, 3, 0.0, 1.0))

func _on_regenerate_pressed() -> void:
	if not space_node:
		return
	if points_slider:
		space_node.attraction_points_count = int(remap(points_slider.get_normalized_value(), 0.0, 1.0, 10, 500))
	if influence_slider:
		space_node.influence_distance = remap(influence_slider.get_normalized_value(), 0.0, 1.0, 0.1, 5.0)
	if kill_slider:
		space_node.kill_distance = remap(kill_slider.get_normalized_value(), 0.0, 1.0, 0.01, 2.0)
	if type_slider:
		space_node.distribution_type = int(remap(type_slider.get_normalized_value(), 0.0, 1.0, 0, 3))
	if animate_slider:
		space_node.show_growth_animation = animate_slider.get_normalized_value() > 0.5
	space_node.regenerate = true

func _on_reset_pressed() -> void:
	if not space_node:
		return
	space_node.regenerate = true

func _on_points_changed(_value: float) -> void:
	pass

func _on_influence_changed(_value: float) -> void:
	pass

func _on_kill_changed(_value: float) -> void:
	pass

func _on_animation_toggled(_value: float) -> void:
	if not space_node:
		return
	if animate_slider:
		space_node.show_growth_animation = animate_slider.get_normalized_value() > 0.5

func _on_type_changed(_value: float) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
