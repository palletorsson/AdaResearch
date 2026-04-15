extends Node3D

var wfc_node: Node
var width_slider: Node
var height_slider: Node
var seed_slider: Node
var status_label: Label3D
var _control_panel: Node3D

func _ready() -> void:
	wfc_node = get_node_or_null("../../WFC_DungeonGenerator")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "WFC Dungeon"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# RackTemplates panel with 3 sliders
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_parameter_panel(
		3, ["WIDTH", "HEIGHT", "SEED"],
		[0.5, 0.5, 0.5]
	)
	_control_panel.position = Vector3(0, 0.1, 0)
	add_child(_control_panel)

	width_slider = _control_panel.get_node_or_null("Param_0")
	height_slider = _control_panel.get_node_or_null("Param_1")
	seed_slider = _control_panel.get_node_or_null("Param_2")

	if width_slider and width_slider.has_signal("slider_moved"):
		width_slider.slider_moved.connect(_on_width_changed)
	if height_slider and height_slider.has_signal("slider_moved"):
		height_slider.slider_moved.connect(_on_height_changed)
	if seed_slider and seed_slider.has_signal("slider_moved"):
		seed_slider.slider_moved.connect(_on_seed_changed)

	# Reset button (built into panel) → regenerate
	var reset_btn: Node = _control_panel.get_node_or_null("ResetButton")
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	_update_ui()

func _update_ui() -> void:
	if not wfc_node:
		return
	if width_slider and width_slider.has_method("set_normalized_value"):
		width_slider.set_normalized_value(remap(wfc_node.grid_width, 3, 20, 0.0, 1.0))
	if height_slider and height_slider.has_method("set_normalized_value"):
		height_slider.set_normalized_value(remap(wfc_node.grid_height, 3, 20, 0.0, 1.0))
	if seed_slider and seed_slider.has_method("set_normalized_value"):
		seed_slider.set_normalized_value(0.5)

func _on_regenerate_pressed() -> void:
	if not wfc_node:
		return
	status_label.text = "Generating..."
	await get_tree().process_frame

	if seed_slider and seed_slider.has_method("get_normalized_value"):
		wfc_node.generation_seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))
	var success = wfc_node.generate_dungeon()

	if success:
		status_label.text = "Status: Success"
	else:
		status_label.text = "Status: Failed (Contradiction)"

func _on_width_changed(_value) -> void:
	if not wfc_node:
		return
	if width_slider and width_slider.has_method("get_normalized_value"):
		var w = int(remap(width_slider.get_normalized_value(), 0.0, 1.0, 3, 20))
		wfc_node.grid_width = w

func _on_height_changed(_value) -> void:
	if not wfc_node:
		return
	if height_slider and height_slider.has_method("get_normalized_value"):
		var h = int(remap(height_slider.get_normalized_value(), 0.0, 1.0, 3, 20))
		wfc_node.grid_height = h

func _on_seed_changed(_value) -> void:
	if not wfc_node:
		return
	if seed_slider and seed_slider.has_method("get_normalized_value"):
		wfc_node.generation_seed = int(remap(seed_slider.get_normalized_value(), 0.0, 1.0, 0, 99999))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
