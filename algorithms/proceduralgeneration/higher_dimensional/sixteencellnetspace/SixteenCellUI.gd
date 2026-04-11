extends Node3D

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

var net_node: Node = null
var size_slider: Node = null
var spacing_slider: Node = null
var pattern_label: Label3D = null
var stats_label: Label3D = null
var hollow_on := false
var spiral_on := false

# @identity
# essence: VR control panel for sixteen-cell net space — sliders and buttons adjusting size, spacing, hollow, and net pattern
# desire: To give hands-on control over a 4D polytope projection: resize, respace, hollow out, cycle net patterns in real time
# critical_parameter: pattern cycle — Cross, T-Shape, L-Shape, Zigzag, Spiral — each unfolding 16 tetrahedral cells differently
# triggers: Size slider rescales the net; spacing slider separates cells; hollow toggle reveals internal structure; spiral adds twist
# emerges: Intuition for 4D geometry through direct VR manipulation — the polytope becomes tangible through parameter play
# needs: VR sliders [has], push buttons [has], Label3D [has], pattern cycling [has]
# relationships: UI controller for sixteen_cell_net_space_showcase in higher_dimensions. Paired with SixteenCellNetSpace geometry node.
# truth: You cannot see the fourth dimension, but you can adjust its projection until you feel it.

var pattern_index := 0
var pattern_names := ["Cross", "T-Shape", "L-Shape", "Zigzag", "Spiral"]

func _ready() -> void:
	net_node = get_node_or_null("../../SixteenCellNetSpace")

	# Stats label
	stats_label = Label3D.new()
	stats_label.position = Vector3(0, 0.5, 0)
	stats_label.font_size = 32
	stats_label.text = "16-Cell Net Space"
	add_child(stats_label)

	# Pattern cycle label + button
	pattern_label = Label3D.new()
	pattern_label.position = Vector3(-0.25, 0.3, 0)
	pattern_label.font_size = 24
	pattern_label.text = "Pattern: %s" % pattern_names[pattern_index]
	add_child(pattern_label)

	var pattern_btn = ButtonScene.instantiate()
	pattern_btn.position = Vector3(0.25, 0.3, 0)
	add_child(pattern_btn)
	var pattern_area = pattern_btn.get_node_or_null("InteractableAreaButton")
	if pattern_area:
		pattern_area.button_pressed.connect(_on_pattern_next)

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
	hollow_btn.position = Vector3(-0.15, -0.06, 0)
	add_child(hollow_btn)
	var hollow_area = hollow_btn.get_node_or_null("InteractableAreaButton")
	if hollow_area:
		hollow_area.button_pressed.connect(_on_hollow_pressed)
	var hollow_lbl = Label3D.new()
	hollow_lbl.position = Vector3(-0.15, -0.12, 0)
	hollow_lbl.font_size = 20
	hollow_lbl.text = "Hollow"
	add_child(hollow_lbl)

	# Spiral toggle button
	var spiral_btn = ButtonScene.instantiate()
	spiral_btn.position = Vector3(0.15, -0.06, 0)
	add_child(spiral_btn)
	var spiral_area = spiral_btn.get_node_or_null("InteractableAreaButton")
	if spiral_area:
		spiral_area.button_pressed.connect(_on_spiral_pressed)
	var spiral_lbl = Label3D.new()
	spiral_lbl.position = Vector3(0.15, -0.12, 0)
	spiral_lbl.font_size = 20
	spiral_lbl.text = "Spiral"
	add_child(spiral_lbl)

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
