extends Control

@onready var space_node = $"../../SpaceColonizationAlgorithm"
@onready var points_slider = $Panel/VBoxContainer/PointsSlider
@onready var influence_slider = $Panel/VBoxContainer/InfluenceSlider
@onready var kill_slider = $Panel/VBoxContainer/KillSlider
@onready var animation_check = $Panel/VBoxContainer/AnimationCheck
@onready var type_option = $Panel/VBoxContainer/TypeOption

func _ready():
	_update_ui()

func _update_ui():
	if not space_node: return
	points_slider.value = space_node.attraction_points_count
	influence_slider.value = space_node.influence_distance
	kill_slider.value = space_node.kill_distance
	animation_check.button_pressed = space_node.show_growth_animation
	type_option.selected = space_node.distribution_type

func _on_regenerate_pressed():
	space_node.attraction_points_count = int(points_slider.value)
	space_node.influence_distance = influence_slider.value
	space_node.kill_distance = kill_slider.value
	space_node.distribution_type = type_option.selected
	space_node.show_growth_animation = animation_check.button_pressed
	
	space_node.regenerate = true

func _on_points_changed(value):
	$Panel/VBoxContainer/PointsLabel.text = "Attraction Points: %d" % int(value)

func _on_influence_changed(value):
	$Panel/VBoxContainer/InfluenceLabel.text = "Influence Dist: %.2f" % value

func _on_kill_changed(value):
	$Panel/VBoxContainer/KillLabel.text = "Kill Dist: %.2f" % value

func _on_animation_toggled(button_pressed):
	space_node.show_growth_animation = button_pressed
