extends Node3D

var poisson_node: Node = null
var _control_panel: Node3D
var dist_slider: Node = null
var mode_label: Label3D = null
var count_label: Label3D = null

var mode_index := 0
var mode_names := ["Points", "Spheres", "Connections"]

func _ready() -> void:
	poisson_node = get_node_or_null("../../PoissonDiskSampling3D")

	# Count label above panel
	count_label = Label3D.new()
	count_label.position = Vector3(0, 0.5, 0)
	count_label.font_size = 32
	count_label.text = "Poisson Disk Sampling"
	add_child(count_label)

	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("POISSON DISK", [
		[
			{"type": "slider_h", "label": "DISTANCE", "default": 0.5},
		],
		[
			{"type": "button", "label": "MODE"},
			{"type": "button", "label": "REGEN"},
		],
	])
	_control_panel.position = Vector3(0, 0.25, 0)
	_control_panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(_control_panel)

	dist_slider = _control_panel.find_child("Param_0", true, false)
	if dist_slider:
		dist_slider.slider_moved.connect(_on_dist_slider_moved)

	# Mode label
	mode_label = Label3D.new()
	mode_label.position = Vector3(0, 0.18, 0)
	mode_label.font_size = 24
	mode_label.text = "Mode: %s" % mode_names[mode_index]
	add_child(mode_label)

	var mode_btn = _control_panel.find_child("Btn_0", true, false)
	if mode_btn:
		var area = mode_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_mode_next())

	var regen_btn = _control_panel.find_child("Btn_1", true, false)
	if regen_btn:
		var area = regen_btn.get_node_or_null("InteractableAreaButton")
		if area:
			area.button_pressed.connect(func(_b): _on_regenerate_pressed())

func _on_dist_slider_moved(_name: String, value: float) -> void:
	if not poisson_node: return
	poisson_node.min_distance = lerp(0.1, 3.0, value)

func _on_mode_next() -> void:
	mode_index = (mode_index + 1) % mode_names.size()
	if mode_label:
		mode_label.text = "Mode: %s" % mode_names[mode_index]
	if poisson_node:
		poisson_node.display_mode = mode_index
		poisson_node.visualize_samples()

func _on_regenerate_pressed() -> void:
	if poisson_node:
		poisson_node.generate_samples()
		_update_count()

func _update_count() -> void:
	if poisson_node and count_label:
		count_label.text = "Points: %d" % poisson_node.sample_points.size()

func _exit_tree() -> void:
	poisson_node = null

func apply_grid_config(config: Dictionary) -> void:
	pass
