extends Control

@onready var net_node = $"../../TesseractNetSpace"
@onready var type_option = $Panel/VBoxContainer/TypeOption
@onready var size_slider = $Panel/VBoxContainer/SizeSlider
@onready var spacing_slider = $Panel/VBoxContainer/SpacingSlider
@onready var hollow_check = $Panel/VBoxContainer/HollowCheck
@onready var stats_label = $Panel/VBoxContainer/StatsLabel

func _ready():
	_update_ui()
	_update_stats()

func _update_ui():
	if not net_node: return
	type_option.selected = net_node.net_type
	size_slider.value = net_node.space_size.x # Assuming uniform for slider
	spacing_slider.value = net_node.spacing
	hollow_check.button_pressed = net_node.create_hollow_center

func _on_regenerate_pressed():
	net_node.generate_net_space()
	_update_stats()

func _update_stats():
	if net_node:
		var stats = net_node.get_net_space_stats()
		stats_label.text = "Nets: %d\nCubes: %d" % [stats.total_nets, stats.total_cubes]

func _on_type_selected(index):
	net_node.net_type = index
	net_node.generate_net_space()
	_update_stats()

func _on_size_changed(value):
	var s = int(value)
	net_node.space_size = Vector3i(s, max(3, s-2), s)
	$Panel/VBoxContainer/SizeLabel.text = "Size: %d" % s
	# Don't regen on drag

func _on_size_drag_ended(value_changed):
	if value_changed:
		net_node.generate_net_space()
		_update_stats()

func _on_spacing_changed(value):
	net_node.spacing = value
	$Panel/VBoxContainer/SpacingLabel.text = "Spacing: %.2f" % value

func _on_spacing_drag_ended(value_changed):
	if value_changed:
		net_node.generate_net_space()

func _on_hollow_toggled(button_pressed):
	net_node.create_hollow_center = button_pressed
	net_node.generate_net_space()
	_update_stats()
