extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const PushButton = preload("res://commons/interactables/push_button.tscn")

var cfg_node: Node = null
var auto_toggle_btn: Node = null
var speed_slider: Node = null
var step_btn: Node = null
var reset_btn: Node = null
var status_label: Label3D = null
var auto_enabled := false

func _ready() -> void:
	cfg_node = get_node_or_null("../../ContextFreeGrammars")
	_build_ui()
	_update_ui()

func _build_ui() -> void:
	var y_offset := 0.0

	# Title
	var title := Label3D.new()
	title.text = "Context-Free Grammars"
	title.font_size = 48
	title.position = Vector3(0, y_offset, 0)
	add_child(title)
	y_offset -= 0.08

	# Status label
	status_label = Label3D.new()
	status_label.text = "Step: 0\nString Length: 0"
	status_label.font_size = 36
	status_label.position = Vector3(0, y_offset, 0)
	add_child(status_label)
	y_offset -= 0.1

	# Auto-play toggle button
	auto_toggle_btn = PushButton.instantiate()
	auto_toggle_btn.position = Vector3(0, y_offset, 0)
	add_child(auto_toggle_btn)
	var auto_area = auto_toggle_btn.get_node_or_null("InteractableAreaButton")
	if auto_area:
		auto_area.button_pressed.connect(_on_auto_toggled)
	var auto_label = auto_toggle_btn.get_node_or_null("Frame/LabelName")
	if auto_label:
		auto_label.text = "Auto Play"
	y_offset -= 0.1

	# Speed slider
	speed_slider = VRSlider.instantiate()
	speed_slider.position = Vector3(0, y_offset, 0)
	add_child(speed_slider)
	speed_slider.set_param_name("Speed")
	speed_slider.slider_moved.connect(_on_speed_changed)
	y_offset -= 0.1

	# Step button
	step_btn = PushButton.instantiate()
	step_btn.position = Vector3(0, y_offset, 0)
	add_child(step_btn)
	var step_area = step_btn.get_node_or_null("InteractableAreaButton")
	if step_area:
		step_area.button_pressed.connect(_on_step_pressed)
	var step_label = step_btn.get_node_or_null("Frame/LabelName")
	if step_label:
		step_label.text = "Step"
	y_offset -= 0.1

	# Reset button
	reset_btn = PushButton.instantiate()
	reset_btn.position = Vector3(0, y_offset, 0)
	add_child(reset_btn)
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)
	var reset_label = reset_btn.get_node_or_null("Frame/LabelName")
	if reset_label:
		reset_label.text = "Reset"

func _process(_delta: float) -> void:
	if cfg_node and status_label:
		status_label.text = "Step: %d\nString Length: %d" % [cfg_node.derivation_step, cfg_node.current_string.length()]

func _update_ui() -> void:
	if not cfg_node:
		return
	auto_enabled = cfg_node.auto_play
	if speed_slider and cfg_node:
		speed_slider.set_normalized_value(clampf(cfg_node.speed / 10.0, 0.0, 1.0))

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

func _on_reset_pressed() -> void:
	if cfg_node:
		cfg_node.reset_derivation()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
