## Cave Control Panel - VR UI for controlling marching cubes parameters
extends Node3D

signal noise_scale_changed(value: float)
signal iso_level_changed(value: float)
signal chunk_scale_changed(value: float)
signal next_preset_pressed()
signal previous_preset_pressed()

var noise_slider: Node = null
var iso_slider: Node = null
var scale_slider: Node = null
var preset_label: Label3D = null

# Slider ranges for denormalization
var noise_min := 1.0
var noise_max := 6.0
var noise_default := 3.8
var iso_min := 0.0
var iso_max := 1.0
var iso_default := 0.88
var scale_min := 50.0
var scale_max := 150.0
var scale_default := 100.0

func _ready() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	var panel: Node3D = RackTpl.create_panel("CAVE SCULPT", [
		[{"type": "slider_h", "label": "NOISE", "default": inverse_lerp(noise_min, noise_max, noise_default)}],
		[{"type": "slider_h", "label": "ISO", "default": inverse_lerp(iso_min, iso_max, iso_default)}],
		[{"type": "slider_h", "label": "SCALE", "default": inverse_lerp(scale_min, scale_max, scale_default)}],
		[{"type": "button", "label": "PREV"}, {"type": "button", "label": "NEXT"}],
	])
	panel.position = Vector3(0, 0.2, 0)
	panel.rotation_degrees = Vector3(-25, 0, 0)
	add_child(panel)

	# Extract slider refs
	noise_slider = panel.find_child("Param_0", true, false)
	iso_slider = panel.find_child("Param_1", true, false)
	scale_slider = panel.find_child("Param_2", true, false)

	if noise_slider:
		noise_slider.slider_moved.connect(_on_noise_slider_moved)
	if iso_slider:
		iso_slider.slider_moved.connect(_on_iso_slider_moved)
	if scale_slider:
		scale_slider.slider_moved.connect(_on_scale_slider_moved)

	# Preset buttons
	var prev_btn: Node = panel.find_child("Btn_0", true, false)
	if prev_btn:
		var prev_area = prev_btn.get_node_or_null("InteractableAreaButton")
		if prev_area:
			prev_area.button_pressed.connect(_on_prev_button_pressed)

	var next_btn: Node = panel.find_child("Btn_1", true, false)
	if next_btn:
		var next_area = next_btn.get_node_or_null("InteractableAreaButton")
		if next_area:
			next_area.button_pressed.connect(_on_next_button_pressed)

	# Preset label below panel
	preset_label = Label3D.new()
	preset_label.position = Vector3(0, -0.06, 0)
	preset_label.font_size = 24
	preset_label.text = "Preset: Default"
	panel.add_child(preset_label)

func _on_noise_slider_moved(_name: String, value: float) -> void:
	var actual = lerp(noise_min, noise_max, value)
	emit_signal("noise_scale_changed", actual)

func _on_iso_slider_moved(_name: String, value: float) -> void:
	var actual = lerp(iso_min, iso_max, value)
	emit_signal("iso_level_changed", actual)

func _on_scale_slider_moved(_name: String, value: float) -> void:
	var actual = lerp(scale_min, scale_max, value)
	emit_signal("chunk_scale_changed", actual)

func _on_prev_button_pressed() -> void:
	emit_signal("previous_preset_pressed")

func _on_next_button_pressed() -> void:
	emit_signal("next_preset_pressed")

func update_preset_name(preset_name: String) -> void:
	if preset_label:
		preset_label.text = "Preset: %s" % preset_name

func set_values(noise: float, iso: float, chunk_scale: float) -> void:
	if noise_slider:
		noise_slider.set_normalized_value(inverse_lerp(noise_min, noise_max, noise))
	if iso_slider:
		iso_slider.set_normalized_value(inverse_lerp(iso_min, iso_max, iso))
	if scale_slider:
		scale_slider.set_normalized_value(inverse_lerp(scale_min, scale_max, chunk_scale))

func _exit_tree() -> void:
	pass

func apply_grid_config(config: Dictionary) -> void:
	pass
