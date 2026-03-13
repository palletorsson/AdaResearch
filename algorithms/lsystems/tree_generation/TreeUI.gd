extends Control

@onready var tree_node = $"../../TreeGeneration"
@onready var auto_check = $Panel/VBoxContainer/AutoCheck
@onready var grow_btn = $Panel/VBoxContainer/GrowButton
@onready var reset_btn = $Panel/VBoxContainer/ResetButton
@onready var status_label = $Panel/VBoxContainer/StatusLabel

func _ready() -> void:
	_update_ui()

func _process(_delta):
	if tree_node:
		status_label.text = "Generation: %d / %d" % [tree_node.generation, tree_node.max_generations]

func _update_ui() -> void:
	if not tree_node: return
	auto_check.button_pressed = tree_node.auto_grow
	grow_btn.disabled = tree_node.auto_grow

func _on_auto_toggled(button_pressed) -> void:
	tree_node.auto_grow = button_pressed
	grow_btn.disabled = button_pressed

func _on_grow_pressed() -> void:
	tree_node.grow_step()

func _on_reset_pressed() -> void:
	tree_node.reset_tree()
