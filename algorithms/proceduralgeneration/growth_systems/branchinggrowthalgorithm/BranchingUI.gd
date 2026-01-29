extends Control

@onready var growth_node = $"../../BranchingGrowthAlgorithm"
@onready var branch_slider = $Panel/VBoxContainer/BranchSlider
@onready var attractor_slider = $Panel/VBoxContainer/AttractorSlider
@onready var rainbow_check = $Panel/VBoxContainer/RainbowCheck
@onready var sparkle_check = $Panel/VBoxContainer/SparkleCheck
@onready var stats_label = $Panel/VBoxContainer/StatsLabel

func _ready():
	_update_ui()

func _update_ui():
	if not growth_node: return
	branch_slider.value = growth_node.max_branches
	attractor_slider.value = growth_node.attractor_count
	rainbow_check.button_pressed = growth_node.enable_pride_colors
	sparkle_check.button_pressed = growth_node.enable_sparkles

func _process(delta):
	if growth_node:
		var stats = growth_node.get_growth_stats()
		stats_label.text = "Branches: %d\nAttractors: %d / %d\nGrowing: %s" % [
			stats.total_branches, 
			stats.total_attractors - stats.reached_attractors,
			stats.total_attractors,
			"Yes" if stats.is_growing else "No"
		]

func _on_restart_pressed():
	growth_node.max_branches = int(branch_slider.value)
	growth_node.attractor_count = int(attractor_slider.value)
	
	growth_node.clear_growth()
	growth_node.add_branch(Vector3.ZERO, Vector3.UP, -1, 0, 0.0)
	growth_node.generate_attractors_vr_optimized()
	growth_node.start_growth()

func _on_branch_changed(value):
	growth_node.max_branches = int(value)
	$Panel/VBoxContainer/BranchLabel.text = "Max Branches: %d" % int(value)

func _on_attractor_changed(value):
	growth_node.attractor_count = int(value)
	$Panel/VBoxContainer/AttractorLabel.text = "Attractors: %d" % int(value)

func _on_rainbow_toggled(button_pressed):
	growth_node.enable_pride_colors = button_pressed

func _on_sparkle_toggled(button_pressed):
	growth_node.enable_sparkles = button_pressed
