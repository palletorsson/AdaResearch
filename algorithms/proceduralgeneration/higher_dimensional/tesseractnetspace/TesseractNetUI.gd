extends Node3D

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

var net_node: Node = null
var size_slider: Node = null
var spacing_slider: Node = null
var type_label: Label3D = null
var stats_label: Label3D = null
var hollow_on := false

var type_index := 0
var type_names := ["Cross", "T-Shape", "L-Shape", "Zigzag"]

func _ready() -> void:
	net_node = get_node_or_null("../../TesseractNetSpace")

	# Stats label
	stats_label = Label3D.new()
	stats_label.position = Vector3(0, 0.5, 0)
	stats_label.font_size = 32
	stats_label.text = "Tesseract Net Space"
	add_child(stats_label)

	# Type cycle label + button
	type_label = Label3D.new()
	type_label.position = Vector3(-0.25, 0.3, 0)
	type_label.font_size = 24
	type_label.text = "Type: %s" % type_names[type_index]
	add_child(type_label)

	var type_btn = ButtonScene.instantiate()
	type_btn.position = Vector3(0.25, 0.3, 0)
	add_child(type_btn)
	var type_area = type_btn.get_node_or_null("InteractableAreaButton")
	if type_area:
		type_area.button_pressed.connect(_on_type_next)

	# Size slider
	size_slider = SliderScene.instantiate()
	size_slider.position = Vector3(0, 0.18, 0)
	add_child(size_slider)
	size_slider.set_param_name("Size")
	size_slider.set_normalized_value(0.5)
	size_slider.slider_moved.connect(_on_size_slider_moved)

	# Spacing slider
	spacing_slider = SliderScene.instantiate()
	spacing_slider.position = Vector3(0, 0.06, 0)
	add_child(spacing_slider)
	spacing_slider.set_param_name("Spacing")
	spacing_slider.set_normalized_value(0.5)
	spacing_slider.slider_moved.connect(_on_spacing_slider_moved)

	# Hollow toggle button
	var hollow_btn = ButtonScene.instantiate()
	hollow_btn.position = Vector3(0, -0.06, 0)
	add_child(hollow_btn)
	var hollow_area = hollow_btn.get_node_or_null("InteractableAreaButton")
	if hollow_area:
		hollow_area.button_pressed.connect(_on_hollow_pressed)
	var hollow_lbl = Label3D.new()
	hollow_lbl.position = Vector3(0, -0.12, 0)
	hollow_lbl.font_size = 20
	hollow_lbl.text = "Hollow"
	add_child(hollow_lbl)

	# Regenerate button
	var regen_btn = ButtonScene.instantiate()
	regen_btn.position = Vector3(0, -0.24, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)
	var regen_lbl = Label3D.new()
	regen_lbl.position = Vector3(0, -0.30, 0)
	regen_lbl.font_size = 20
	regen_lbl.text = "Regenerate"
	add_child(regen_lbl)

	_update_stats()

func _on_type_next() -> void:
	type_index = (type_index + 1) % type_names.size()
	if type_label:
		type_label.text = "Type: %s" % type_names[type_index]
	if net_node:
		net_node.net_type = type_index
		net_node.generate_net_space()
		_update_stats()

func _on_size_slider_moved(_name: String, value: float) -> void:
	if not net_node: return
	var s = int(lerp(3.0, 12.0, value))
	net_node.space_size = Vector3i(s, max(3, s - 2), s)

func _on_spacing_slider_moved(_name: String, value: float) -> void:
	if not net_node: return
	net_node.spacing = lerp(0.5, 3.0, value)

func _on_hollow_pressed() -> void:
	hollow_on = !hollow_on
	if net_node:
		net_node.create_hollow_center = hollow_on
		net_node.generate_net_space()
		_update_stats()

func _on_regenerate_pressed() -> void:
	if net_node:
		net_node.generate_net_space()
		_update_stats()

func _update_stats() -> void:
	if net_node and stats_label:
		var stats = net_node.get_net_space_stats()
		stats_label.text = "Nets: %d | Cubes: %d" % [stats.total_nets, stats.total_cubes]

func _exit_tree() -> void:
	net_node = null

func apply_grid_config(config: Dictionary) -> void:
	pass
