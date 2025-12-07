extends Control

@onready var bsp_node: BinarySpacePartitioning = $"../../BinarySpacePartitioning"
@onready var depth_slider: HSlider = $Panel/VBoxContainer/DepthSlider
@onready var min_size_slider: HSlider = $Panel/VBoxContainer/MinSizeSlider
@onready var gradient_option: OptionButton = $Panel/VBoxContainer/GradientOption
@onready var falloff_slider: HSlider = $Panel/VBoxContainer/FalloffSlider
@onready var bias_slider: HSlider = $Panel/VBoxContainer/BiasSlider
@onready var stats_label: Label = $Panel/VBoxContainer/StatsLabel

func _ready():
	_update_ui_from_node()
	bsp_node.generate_bsp()
	_update_stats()

func _update_ui_from_node():
	if not bsp_node: return
	depth_slider.value = bsp_node.max_depth
	min_size_slider.value = bsp_node.min_cell_size
	gradient_option.selected = bsp_node.gradient_type
	falloff_slider.value = bsp_node.gradient_falloff
	bias_slider.value = bsp_node.center_bias

func _on_regenerate_pressed():
	bsp_node.generate_bsp()
	_update_stats()

func _on_depth_changed(value):
	bsp_node.max_depth = int(value)
	$Panel/VBoxContainer/DepthLabel.text = "Max Depth: %d" % int(value)
	bsp_node.generate_bsp()
	_update_stats()

func _on_min_size_changed(value):
	bsp_node.min_cell_size = value
	$Panel/VBoxContainer/MinSizeLabel.text = "Min Cell Size: %.1f" % value
	bsp_node.generate_bsp()
	_update_stats()

func _on_gradient_type_selected(index):
	bsp_node.gradient_type = index
	bsp_node.generate_bsp()
	_update_stats()

func _on_falloff_changed(value):
	bsp_node.gradient_falloff = value
	bsp_node.generate_bsp()

func _on_bias_changed(value):
	bsp_node.center_bias = value
	bsp_node.generate_bsp()

func _update_stats():
	var cell_count = bsp_node.all_cells.size()
	stats_label.text = "Total Cells: %d" % cell_count
