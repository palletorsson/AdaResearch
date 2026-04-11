extends Node3D

const SliderScene = preload("res://commons/interactables/slider_horizontal.tscn")
const ButtonScene = preload("res://commons/interactables/push_button.tscn")

var poisson_node: Node = null
var dist_slider: Node = null
var mode_label: Label3D = null
var count_label: Label3D = null

var mode_index := 0
var mode_names := ["Points", "Spheres", "Connections"]

func _ready() -> void:
	poisson_node = get_node_or_null("../../PoissonDiskSampling3D")

	# Count label
	count_label = Label3D.new()
	count_label.position = Vector3(0, 0.5, 0)
	count_label.font_size = 32
	count_label.text = "Poisson Disk Sampling"
	add_child(count_label)

	# Distance slider
	dist_slider = SliderScene.instantiate()
	dist_slider.position = Vector3(0, 0.3, 0)
	add_child(dist_slider)
	dist_slider.set_param_name("Min Distance")
	dist_slider.set_normalized_value(0.5)
	dist_slider.slider_moved.connect(_on_dist_slider_moved)

	# Mode cycle label + button
	mode_label = Label3D.new()
	mode_label.position = Vector3(-0.25, 0.18, 0)
	mode_label.font_size = 24
	mode_label.text = "Mode: %s" % mode_names[mode_index]
	add_child(mode_label)

	var mode_btn = ButtonScene.instantiate()
	mode_btn.position = Vector3(0.25, 0.18, 0)
	add_child(mode_btn)
	var mode_area = mode_btn.get_node_or_null("InteractableAreaButton")
	if mode_area:
		mode_area.button_pressed.connect(_on_mode_next)

	# Regenerate button
	var regen_btn = ButtonScene.instantiate()
	regen_btn.position = Vector3(0, 0.06, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)
	var regen_lbl = Label3D.new()
	regen_lbl.position = Vector3(0, 0.0, 0)
	regen_lbl.font_size = 20
	regen_lbl.text = "Regenerate"
	add_child(regen_lbl)

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
