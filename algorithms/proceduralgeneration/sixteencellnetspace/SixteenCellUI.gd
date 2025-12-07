extends Control

@onready var net_node = $"../../SixteenCellNetSpace"
@onready var pattern_option = $Panel/VBoxContainer/PatternOption
@onready var size_slider = $Panel/VBoxContainer/SizeSlider
@onready var spacing_slider = $Panel/VBoxContainer/SpacingSlider
@onready var hollow_check = $Panel/VBoxContainer/HollowCheck
@onready var spiral_check = $Panel/VBoxContainer/SpiralCheck
@onready var stats_label = $Panel/VBoxContainer/StatsLabel

func _ready():
	_update_ui()
	_update_stats()

func _update_ui():
	if not net_node: return
	pattern_option.selected = net_node.net_pattern
	size_slider.value = net_node.space_size.x
	spacing_slider.value = net_node.spacing
	hollow_check.button_pressed = net_node.create_hollow_center
	spiral_check.button_pressed = net_node.spiral_arrangement

func _on_regenerate_pressed():
	net_node.generate_16cell_space()
	_update_stats()

func _update_stats():
	if net_node:
		var stats = net_node.get_16cell_space_stats()
		stats_label.text = "Nets: %d\nTetrahedra: %d" % [stats.total_nets, stats.total_tetrahedra]

func _on_pattern_selected(index):
	net_node.net_pattern = index
	net_node.generate_16cell_space()
	_update_stats()

func _on_size_changed(value):
	var s = int(value)
	net_node.space_size = Vector3i(s, max(3, s-2), s)
	$Panel/VBoxContainer/SizeLabel.text = "Size: %d" % s

func _on_size_drag_ended(value_changed):
	if value_changed:
		net_node.generate_16cell_space()
		_update_stats()

func _on_spacing_changed(value):
	net_node.spacing = value
	$Panel/VBoxContainer/SpacingLabel.text = "Spacing: %.2f" % value

func _on_spacing_drag_ended(value_changed):
	if value_changed:
		net_node.generate_16cell_space()

func _on_hollow_toggled(button_pressed):
	net_node.create_hollow_center = button_pressed
	net_node.generate_16cell_space()
	_update_stats()

func _on_spiral_toggled(button_pressed):
	net_node.spiral_arrangement = button_pressed
	net_node.generate_16cell_space()
