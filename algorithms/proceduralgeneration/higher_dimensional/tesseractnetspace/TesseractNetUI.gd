extends Node3D

var net_node: Node = null
var _control_panel: Node3D
var size_slider: Node = null
var spacing_slider: Node = null
var type_label: Label3D = null
var stats_label: Label3D = null
var hollow_on := false

var type_index := 0
var type_names := ["Cross", "T-Shape", "L-Shape", "Zigzag"]

func _ready() -> void:
	net_node = get_node_or_null("../../TesseractNetSpace")

	# Stats label above panel
	stats_label = Label3D.new()
	stats_label.position = Vector3(0, 0.5, 0)
	stats_label.font_size = 32
	stats_label.text = "Tesseract Net Space"
	add_child(stats_label)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("TESSERACT", [
		[
			{"type": "slider_h", "label": "SIZE", "default": 0.5},
			{"type": "slider_h", "label": "SPACING", "default": 0.5},
		],
		[
			{"type": "button", "label": "TYPE"},
			{"type": "button", "label": "HOLLOW"},
			{"type": "button", "label": "REGEN"},
		],
	])
	_control_panel.position = Vector3(0, 0.25, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Type label
	type_label = Label3D.new()
	type_label.position = Vector3(0, 0.15, 0)
	type_label.font_size = 24
	type_label.text = "Type: %s" % type_names[type_index]
	add_child(type_label)

	size_slider = _control_panel.find_child("Param_0", true, false)
	spacing_slider = _control_panel.find_child("Param_1", true, false)

	if size_slider:
		size_slider.slider_moved.connect(_on_size_slider_moved)
	if spacing_slider:
		spacing_slider.slider_moved.connect(_on_spacing_slider_moved)

	var type_btn = _control_panel.find_child("Btn_0", true, false)
	if type_btn:
		var area = type_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_type_next())

	var hollow_btn = _control_panel.find_child("Btn_1", true, false)
	if hollow_btn:
		var area = hollow_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_hollow_pressed())

	var regen_btn = _control_panel.find_child("Btn_2", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

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
