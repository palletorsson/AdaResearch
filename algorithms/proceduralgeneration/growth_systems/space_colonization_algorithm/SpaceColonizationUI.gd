extends Node3D

const VRSlider = preload("res://commons/interactables/slider_horizontal.tscn")
const VRButton = preload("res://commons/interactables/push_button.tscn")

var space_node: Node
var points_slider: Node3D
var influence_slider: Node3D
var kill_slider: Node3D
var animate_slider: Node3D
var type_slider: Node3D
var status_label: Label3D

func _ready() -> void:
	space_node = get_node_or_null("../../SpaceColonizationAlgorithm")

	# Status label
	status_label = Label3D.new()
	status_label.position = Vector3(0, 0.5, 0)
	status_label.text = "Space Colonization"
	status_label.font_size = 48
	status_label.modulate = Color.WHITE
	add_child(status_label)

	# Attraction points slider
	points_slider = VRSlider.instantiate()
	points_slider.position = Vector3(0, 0.3, 0)
	add_child(points_slider)
	points_slider.set_param_name("Attraction Points")
	points_slider.slider_moved.connect(_on_points_changed)

	# Influence distance slider
	influence_slider = VRSlider.instantiate()
	influence_slider.position = Vector3(0, 0.18, 0)
	add_child(influence_slider)
	influence_slider.set_param_name("Influence Dist")
	influence_slider.slider_moved.connect(_on_influence_changed)

	# Kill distance slider
	kill_slider = VRSlider.instantiate()
	kill_slider.position = Vector3(0, 0.06, 0)
	add_child(kill_slider)
	kill_slider.set_param_name("Kill Dist")
	kill_slider.slider_moved.connect(_on_kill_changed)

	# Animation toggle slider
	animate_slider = VRSlider.instantiate()
	animate_slider.position = Vector3(0, -0.06, 0)
	add_child(animate_slider)
	animate_slider.set_param_name("Animate")
	animate_slider.slider_moved.connect(_on_animation_toggled)

	# Distribution type slider
	type_slider = VRSlider.instantiate()
	type_slider.position = Vector3(0, -0.18, 0)
	add_child(type_slider)
	type_slider.set_param_name("Distribution Type")
	type_slider.slider_moved.connect(_on_type_changed)

	# Regenerate button
	var regen_btn = VRButton.instantiate()
	regen_btn.position = Vector3(-0.1, -0.34, 0)
	add_child(regen_btn)
	var regen_area = regen_btn.get_node_or_null("InteractableAreaButton")
	if regen_area:
		regen_area.button_pressed.connect(_on_regenerate_pressed)

	# Reset button
	var reset_btn = VRButton.instantiate()
	reset_btn.position = Vector3(0.1, -0.34, 0)
	add_child(reset_btn)
	var reset_area = reset_btn.get_node_or_null("InteractableAreaButton")
	if reset_area:
		reset_area.button_pressed.connect(_on_reset_pressed)

	_update_ui()

func _update_ui() -> void:
	if not space_node:
		return
	points_slider.set_normalized_value(remap(space_node.attraction_points_count, 10, 500, 0.0, 1.0))
	influence_slider.set_normalized_value(remap(space_node.influence_distance, 0.1, 5.0, 0.0, 1.0))
	kill_slider.set_normalized_value(remap(space_node.kill_distance, 0.01, 2.0, 0.0, 1.0))
	animate_slider.set_normalized_value(1.0 if space_node.show_growth_animation else 0.0)
	type_slider.set_normalized_value(remap(space_node.distribution_type, 0, 3, 0.0, 1.0))

func _on_regenerate_pressed() -> void:
	if not space_node:
		return
	space_node.attraction_points_count = int(remap(points_slider.get_normalized_value(), 0.0, 1.0, 10, 500))
	space_node.influence_distance = remap(influence_slider.get_normalized_value(), 0.0, 1.0, 0.1, 5.0)
	space_node.kill_distance = remap(kill_slider.get_normalized_value(), 0.0, 1.0, 0.01, 2.0)
	space_node.distribution_type = int(remap(type_slider.get_normalized_value(), 0.0, 1.0, 0, 3))
	space_node.show_growth_animation = animate_slider.get_normalized_value() > 0.5
	space_node.regenerate = true

func _on_reset_pressed() -> void:
	if not space_node:
		return
	space_node.regenerate = true

func _on_points_changed(_value: float) -> void:
	pass

func _on_influence_changed(_value: float) -> void:
	pass

func _on_kill_changed(_value: float) -> void:
	pass

func _on_animation_toggled(_value: float) -> void:
	if not space_node:
		return
	space_node.show_growth_animation = animate_slider.get_normalized_value() > 0.5

func _on_type_changed(_value: float) -> void:
	pass

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

func apply_grid_config(config: Dictionary) -> void:
	pass
