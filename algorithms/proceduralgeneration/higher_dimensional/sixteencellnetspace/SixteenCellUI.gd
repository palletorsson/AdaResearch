extends Node3D

# @identity
# essence: VR control panel for sixteen-cell net space — sliders and buttons adjusting size, spacing, hollow, and net pattern
# desire: To give hands-on control over a 4D polytope projection: resize, respace, hollow out, cycle net patterns in real time
# critical_parameter: pattern cycle — Cross, T-Shape, L-Shape, Zigzag, Spiral — each unfolding 16 tetrahedral cells differently
# triggers: Size slider rescales the net; spacing slider separates cells; hollow toggle reveals internal structure; spiral adds twist
# emerges: Intuition for 4D geometry through direct VR manipulation — the polytope becomes tangible through parameter play
# needs: VR sliders [has], push buttons [has], Label3D [has], pattern cycling [has]
# relationships: UI controller for sixteen_cell_net_space_showcase in higher_dimensions. Paired with SixteenCellNetSpace geometry node.
# truth: You cannot see the fourth dimension, but you can adjust its projection until you feel it.

var net_node: Node = null
var _control_panel: Node3D
var size_slider: Node = null
var spacing_slider: Node = null
var pattern_label: Label3D = null
var stats_label: Label3D = null
var hollow_on := false
var spiral_on := false

var pattern_index := 0
var pattern_names := ["Cross", "T-Shape", "L-Shape", "Zigzag", "Spiral"]

func _ready() -> void:
	net_node = get_node_or_null("../../SixteenCellNetSpace")

	# Stats label above panel
	stats_label = Label3D.new()
	stats_label.position = Vector3(0, 0.5, 0)
	stats_label.font_size = 32
	stats_label.text = "16-Cell Net Space"
	add_child(stats_label)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("16-CELL", [
		[
			{"type": "slider_h", "label": "SIZE", "default": 0.5},
			{"type": "slider_h", "label": "SPACING", "default": 0.5},
		],
		[
			{"type": "button", "label": "PATTERN"},
			{"type": "button", "label": "HOLLOW"},
			{"type": "button", "label": "SPIRAL"},
			{"type": "button", "label": "REGEN"},
		],
	])
	_control_panel.position = Vector3(0, 0.25, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	# Pattern label
	pattern_label = Label3D.new()
	pattern_label.position = Vector3(0, 0.15, 0)
	pattern_label.font_size = 24
	pattern_label.text = "Pattern: %s" % pattern_names[pattern_index]
	add_child(pattern_label)

	size_slider = _control_panel.find_child("Param_0", true, false)
	spacing_slider = _control_panel.find_child("Param_1", true, false)

	if size_slider:
		size_slider.slider_moved.connect(_on_size_slider_moved)
	if spacing_slider:
		spacing_slider.slider_moved.connect(_on_spacing_slider_moved)

	var pattern_btn = _control_panel.find_child("Btn_0", true, false)
	if pattern_btn:
		var area = pattern_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_pattern_next())

	var hollow_btn = _control_panel.find_child("Btn_1", true, false)
	if hollow_btn:
		var area = hollow_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_hollow_pressed())

	var spiral_btn = _control_panel.find_child("Btn_2", true, false)
	if spiral_btn:
		var area = spiral_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_spiral_pressed())

	var regen_btn = _control_panel.find_child("Btn_3", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

	_update_stats()

func _on_pattern_next() -> void:
	pattern_index = (pattern_index + 1) % pattern_names.size()
	if pattern_label:
		pattern_label.text = "Pattern: %s" % pattern_names[pattern_index]
	if net_node:
		net_node.net_pattern = pattern_index
		net_node.generate_16cell_space()
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
		net_node.generate_16cell_space()
		_update_stats()

func _on_spiral_pressed() -> void:
	spiral_on = !spiral_on
	if net_node:
		net_node.spiral_arrangement = spiral_on
		net_node.generate_16cell_space()

func _on_regenerate_pressed() -> void:
	if net_node:
		net_node.generate_16cell_space()
		_update_stats()

func _update_stats() -> void:
	if net_node and stats_label:
		var stats = net_node.get_16cell_space_stats()
		stats_label.text = "Nets: %d | Tetrahedra: %d" % [stats.total_nets, stats.total_tetrahedra]

func _exit_tree() -> void:
	net_node = null

func apply_grid_config(config: Dictionary) -> void:
	pass
