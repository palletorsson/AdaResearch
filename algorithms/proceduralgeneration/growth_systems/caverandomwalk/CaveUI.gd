extends Control

@onready var cave_node: CaveGenerator = $"../../Caverandomwalk"
@onready var width_slider = $Panel/VBoxContainer/WidthSlider
@onready var height_slider = $Panel/VBoxContainer/HeightSlider
@onready var walkers_slider = $Panel/VBoxContainer/WalkersSlider
@onready var steps_slider = $Panel/VBoxContainer/StepsSlider
@onready var seed_spin = $Panel/VBoxContainer/SeedSpinBox

func _ready():
	_update_ui()

func _update_ui():
	if not cave_node: return
	width_slider.value = cave_node.grid_size.x
	height_slider.value = cave_node.grid_size.y
	walkers_slider.value = cave_node.walkers
	steps_slider.value = cave_node.steps_per_level
	seed_spin.value = cave_node.seed

func _on_regenerate_pressed():
	cave_node.seed = int(seed_spin.value) # Use current spinbox value
	cave_node.regenerate()

func _on_randomize_pressed():
	cave_node.seed = randi()
	seed_spin.value = cave_node.seed
	cave_node.regenerate()

func _on_width_changed(value):
	cave_node.grid_size.x = int(value)
	cave_node.grid_size.z = int(value) # Keep square for simplicity in UI
	$Panel/VBoxContainer/WidthLabel.text = "Grid Width: %d" % int(value)

func _on_height_changed(value):
	cave_node.grid_size.y = int(value)
	$Panel/VBoxContainer/HeightLabel.text = "Grid Height: %d" % int(value)

func _on_walkers_changed(value):
	cave_node.walkers = int(value)
	$Panel/VBoxContainer/WalkersLabel.text = "Walkers: %d" % int(value)

func _on_steps_changed(value):
	cave_node.steps_per_level = int(value)
	$Panel/VBoxContainer/StepsLabel.text = "Steps/Level: %d" % int(value)

func _on_seed_changed(value):
	cave_node.seed = int(value)
