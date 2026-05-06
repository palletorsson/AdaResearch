extends Node3D

var tree_node: Node = null
var status_label: Label3D = null
var auto_enabled := false
var _control_panel: Node3D

func _ready() -> void:
	tree_node = get_node_or_null("../../TreeGeneration")
	_build_ui()
	_update_ui()

func _build_ui() -> void:
	# Title
	var title := Label3D.new()
	title.text = "Tree Generation"
	title.font_size = 48
	title.position = Vector3(0, 0, 0)
	add_child(title)

	# Status label
	status_label = Label3D.new()
	status_label.text = "Generation: 0 / 0"
	status_label.font_size = 36
	status_label.position = Vector3(0, -0.08, 0)
	add_child(status_label)

	# Button grid: AUTO, GROW, RESET
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_button_grid(3, 1, ["AUTO", "GROW", "RESET"])
	_control_panel.position = Vector3(0, -0.22, 0)
	add_child(_control_panel)

	var auto_btn: Node = _control_panel.get_node_or_null("Btn_0")
	var grow_btn: Node = _control_panel.get_node_or_null("Btn_1")
	var reset_btn: Node = _control_panel.get_node_or_null("Btn_2")

	if auto_btn:
		var area = auto_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_auto_toggled())
	if grow_btn:
		var area = grow_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_grow_pressed())
	if reset_btn:
		var area = reset_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_reset_pressed())

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
