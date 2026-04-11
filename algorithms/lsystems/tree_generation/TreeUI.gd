extends Node3D

const PushButton = preload("res://commons/interactables/push_button.tscn")

var tree_node: Node = null
var auto_toggle_btn: Node = null
var grow_btn: Node = null
var reset_btn: Node = null
var status_label: Label3D = null
var auto_enabled := false

func _ready() -> void:
	tree_node = get_node_or_null("../../TreeGeneration")
	_build_ui()
	_update_ui()

func _build_ui() -> void:
	var y_offset := 0.0

	# Title
	var title := Label3D.new()
	title.text = "Tree Generation"
	title.font_size = 48
	title.position = Vector3(0, y_offset, 0)
	add_child(title)
	y_offset -= 0.08

	# Status label
	status_label = Label3D.new()
	status_label.text = "Generation: 0 / 0"
	status_label.font_size = 36
	status_label.position = Vector3(0, y_offset, 0)
	add_child(status_label)
	y_offset -= 0.1

	# Auto-grow toggle button
	auto_toggle_btn = PushButton.instantiate()
	auto_toggle_btn.position = Vector3(0, y_offset, 0)
	add_child(auto_toggle_btn)
	var auto_area = auto_toggle_btn.get_node_or_null("InteractableAreaButton")
	if auto_area:
		auto_area.button_pressed.connect(_on_auto_toggled)
	var auto_label = auto_toggle_btn.get_node_or_null("Frame/LabelName")
	if auto_label:
		auto_label.text = "Auto Grow"
	y_offset -= 0.1

	# Grow button
	grow_btn = PushButton.instantiate()
	grow_btn.position = Vector3(0, y_offset, 0)
	add_child(grow_btn)
	var grow_area = grow_btn.get_node_or_null("InteractableAreaButton")
	if grow_area:
		grow_area.button_pressed.connect(_on_grow_pressed)
	var grow_label = grow_btn.get_node_or_null("Frame/LabelName")
	if grow_label:
		grow_label.text = "Grow"
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
	if tree_node and status_label:
		status_label.text = "Generation: %d / %d" % [tree_node.generation, tree_node.max_generations]

func _update_ui() -> void:
	if not tree_node:
		return
	auto_enabled = tree_node.auto_grow

func _on_auto_toggled() -> void:
	auto_enabled = not auto_enabled
	if tree_node:
		tree_node.auto_grow = auto_enabled

func _on_grow_pressed() -> void:
	if tree_node:
		tree_node.grow_step()

func _on_reset_pressed() -> void:
	if tree_node:
		tree_node.reset_tree()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()
