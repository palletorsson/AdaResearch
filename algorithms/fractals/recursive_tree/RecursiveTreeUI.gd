extends Control

@onready var tree_node = $"../../RecursiveTree"
@onready var branch_slider = $Panel/VBoxContainer/BranchSlider
@onready var sub_branch_slider = $Panel/VBoxContainer/SubBranchSlider
@onready var seed_spin = $Panel/VBoxContainer/SeedSpinBox
@onready var complex_check = $Panel/VBoxContainer/ComplexCheck
@onready var stats_label = $Panel/VBoxContainer/StatsLabel

func _ready():
	_update_ui()

func _update_ui():
	if not tree_node: return
	branch_slider.value = tree_node.num_main_branches
	sub_branch_slider.value = tree_node.max_sub_branches
	seed_spin.value = tree_node.random_seed

func _on_regenerate_pressed():
	tree_node.num_main_branches = int(branch_slider.value)
	tree_node.max_sub_branches = int(sub_branch_slider.value)
	tree_node.random_seed = int(seed_spin.value)
	
	if complex_check.button_pressed:
		tree_node.generate_image_style_tree()
	else:
		tree_node.rebuild_tree()
	
	_update_stats()

func _update_stats():
	# Simple stats
	pass

func _on_branch_changed(value):
	$Panel/VBoxContainer/BranchLabel.text = "Main Branches: %d" % int(value)

func _on_sub_changed(value):
	$Panel/VBoxContainer/SubBranchLabel.text = "Max Sub-Branches: %d" % int(value)

func _on_seed_changed(_value):
	pass

func _on_randomize_pressed():
	seed_spin.value = randi()
	_on_regenerate_pressed()
