extends Control

@onready var poisson_node = $"../../PoissonDiskSampling3D"
@onready var dist_slider = $Panel/VBoxContainer/DistSlider
@onready var mode_option = $Panel/VBoxContainer/ModeOption
@onready var count_label = $Panel/VBoxContainer/CountLabel

func _ready():
	_update_ui()

func _update_ui():
	if not poisson_node: return
	dist_slider.value = poisson_node.min_distance
	mode_option.selected = poisson_node.display_mode

func _on_regenerate_pressed():
	poisson_node.min_distance = dist_slider.value
	poisson_node.display_mode = mode_option.selected
	poisson_node.generate_samples()
	_update_count()

func _update_count():
	count_label.text = "Points: %d" % poisson_node.sample_points.size()

func _on_dist_changed(value):
	$Panel/VBoxContainer/DistLabel.text = "Min Distance: %.1f" % value

func _on_mode_selected(index):
	poisson_node.display_mode = index
	poisson_node.visualize_samples()
