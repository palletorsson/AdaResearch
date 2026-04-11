extends Node3D

## VR UI panel for ContextFreeGrammars
## Provides sliders and buttons to control grammar type, speed, and derivation stepping.

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const PushButton = preload("res://commons/interactables/push_button.tscn")

var cfg_node: Node = null
var speed_slider: Node = null
var status_label: Label3D = null
var grammar_label: Label3D = null
var auto_enabled := true

func _ready() -> void:
	cfg_node = get_parent()
	if not cfg_node or not cfg_node.has_method("next_step"):
		cfg_node = get_node_or_null("../ContextFreeGrammars")
	_build_ui()


func _build_ui() -> void:
	var y_offset := 0.0

	# Title
	var title := Label3D.new()
	title.text = "CFG Controls"
	title.font_size = 40
	title.outline_size = 4
	title.modulate = Color(0.85, 0.9, 1.0)
	title.position = Vector3(0, y_offset, 0)
	add_child(title)
	y_offset -= 0.07

	# Status label
	status_label = Label3D.new()
	status_label.text = "Step: 0"
	status_label.font_size = 32
	status_label.outline_size = 3
	status_label.modulate = Color(0.75, 0.85, 0.95)
	status_label.position = Vector3(0, y_offset, 0)
	add_child(status_label)
	y_offset -= 0.07

	# Grammar type label
	grammar_label = Label3D.new()
	grammar_label.text = ""
	grammar_label.font_size = 24
	grammar_label.outline_size = 3
	grammar_label.modulate = Color(0.6, 0.8, 1.0)
	grammar_label.position = Vector3(0, y_offset, 0)
	add_child(grammar_label)
	y_offset -= 0.09

	# Speed slider
	speed_slider = VRSlider.instantiate()
	speed_slider.position = Vector3(0, y_offset, 0)
	add_child(speed_slider)
	speed_slider.set_param_name("Speed")
	speed_slider.set_normalized_value(0.2)
	speed_slider.slider_moved.connect(_on_speed_changed)
	y_offset -= 0.09

	# Auto-play toggle
	var auto_btn := PushButton.instantiate()
	auto_btn.position = Vector3(0, y_offset, 0)
	add_child(auto_btn)
	var auto_area = auto_btn.get_node_or_null("InteractableAreaButton")
	if auto_area:
		auto_area.button_pressed.connect(_on_auto_toggled)
	var auto_label_node = auto_btn.get_node_or_null("Frame/LabelName")
	if auto_label_node:
		auto_label_node.text = "Auto Play"
	y_offset -= 0.09

	# Step button
	var step_btn := PushButton.instantiate()
	step_btn.position = Vector3(0, y_offset, 0)
	add_child(step_btn)
	var step_area = step_btn.get_node_or_null("InteractableAreaButton")
	if step_area:
		step_area.button_pressed.connect(_on_step_pressed)
	var step_label_node = step_btn.get_node_or_null("Frame/LabelName")
	if step_label_node:
		step_label_node.text = "Step"
	y_offset -= 0.09

	# Grammar cycle button
	var grammar_btn := PushButton.instantiate()
	grammar_btn.position = Vector3(0, y_offset, 0)
	add_child(grammar_btn)
	var grammar_area = grammar_btn.get_node_or_null("InteractableAreaButton")
	if grammar_area:
		grammar_area.button_pressed.connect(_on_grammar_cycle)
	var grammar_btn_label = grammar_btn.get_node_or_null("Frame/LabelName")
	if grammar_btn_label:
		grammar_btn_label.text = "Grammar"
	y_offset -= 0.09

	# Reset button
	var reset_btn := PushButton.instantiate()
	reset_btn.position = Vector3(0, y_offset, 0)
	add_child(reset_btn)
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)
	var reset_label_node = reset_btn.get_node_or_null("Frame/LabelName")
	if reset_label_node:
		reset_label_node.text = "Reset"


func _process(_delta: float) -> void:
	if cfg_node and status_label:
		status_label.text = "Step: %d | Length: %d" % [
			cfg_node.derivation_step,
			cfg_node.current_string.length()
		]
	if cfg_node and grammar_label:
		var idx: int = cfg_node.grammar_index
		if idx < cfg_node.grammar_names.size():
			grammar_label.text = cfg_node.grammar_names[idx]


func _on_auto_toggled() -> void:
	auto_enabled = not auto_enabled
	if cfg_node:
		cfg_node.auto_play = auto_enabled


func _on_speed_changed(_value: float) -> void:
	if cfg_node and speed_slider:
		cfg_node.speed = speed_slider.get_normalized_value() * 10.0


func _on_step_pressed() -> void:
	if cfg_node:
		cfg_node.next_step()


func _on_grammar_cycle() -> void:
	if cfg_node:
		var next_idx: int = (cfg_node.grammar_index + 1) % cfg_node.grammars.size()
		cfg_node.set_grammar(next_idx)


func _on_reset_pressed() -> void:
	if cfg_node:
		cfg_node.reset_derivation()


func apply_grid_config(config: Dictionary) -> void:
	pass


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
