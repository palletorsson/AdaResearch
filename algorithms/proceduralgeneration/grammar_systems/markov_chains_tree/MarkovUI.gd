extends Control

@onready var markov_node = $"../../MarkovChainsTree"
@onready var height_slider = $Panel/VBoxContainer/HeightSlider
@onready var random_slider = $Panel/VBoxContainer/RandomSlider
@onready var animate_check = $Panel/VBoxContainer/AnimateCheck

func _ready() -> void:
	_update_ui()

func _update_ui() -> void:
	if not markov_node: return
	height_slider.value = markov_node.tree_height
	random_slider.value = markov_node.randomness
	animate_check.button_pressed = markov_node.animate_growth

func _on_regenerate_pressed() -> void:
	markov_node.tree_height = height_slider.value
	markov_node.randomness = random_slider.value
	markov_node.animate_growth = animate_check.button_pressed
	markov_node.grow_tree()

func _on_height_changed(value) -> void:
	$Panel/VBoxContainer/HeightLabel.text = "Tree Height: %.1f" % value

func _on_random_changed(value) -> void:
	$Panel/VBoxContainer/RandomLabel.text = "Randomness: %.2f" % value

func _on_animate_toggled(button_pressed) -> void:
	markov_node.animate_growth = button_pressed
