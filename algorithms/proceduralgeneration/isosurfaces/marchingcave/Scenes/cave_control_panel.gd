## Cave Control Panel - 2D UI for controlling marching cubes parameters
extends Control

signal noise_scale_changed(value: float)
signal iso_level_changed(value: float)
signal chunk_scale_changed(value: float)
signal next_preset_pressed()
signal previous_preset_pressed()

@onready var noise_slider : HSlider = $VBoxContainer/NoiseScale/Slider
@onready var noise_label : Label = $VBoxContainer/NoiseScale/Value
@onready var iso_slider : HSlider = $VBoxContainer/IsoLevel/Slider
@onready var iso_label : Label = $VBoxContainer/IsoLevel/Value
@onready var scale_slider : HSlider = $VBoxContainer/ChunkScale/Slider
@onready var scale_label : Label = $VBoxContainer/ChunkScale/Value
@onready var preset_label : Label = $VBoxContainer/Presets/PresetName

func _ready():
	setup_sliders()

func setup_sliders():
	# Noise Scale: 1.0 - 6.0
	noise_slider.min_value = 1.0
	noise_slider.max_value = 6.0
	noise_slider.step = 0.1
	noise_slider.value = 3.8
	
	# Iso Level: 0.0 - 1.0
	iso_slider.min_value = 0.0
	iso_slider.max_value = 1.0
	iso_slider.step = 0.05
	iso_slider.value = 0.88
	
	# Chunk Scale: 50 - 150
	scale_slider.min_value = 50.0
	scale_slider.max_value = 150.0
	scale_slider.step = 5.0
	scale_slider.value = 100.0
	
	update_labels()

func _on_noise_slider_value_changed(value):
	noise_label.text = "%.2f" % value
	emit_signal("noise_scale_changed", value)

func _on_iso_slider_value_changed(value):
	iso_label.text = "%.2f" % value
	emit_signal("iso_level_changed", value)

func _on_scale_slider_value_changed(value):
	scale_label.text = "%.0f" % value
	emit_signal("chunk_scale_changed", value)

func _on_prev_button_pressed():
	emit_signal("previous_preset_pressed")

func _on_next_button_pressed():
	emit_signal("next_preset_pressed")

func update_labels():
	if noise_label:
		noise_label.text = "%.2f" % noise_slider.value
	if iso_label:
		iso_label.text = "%.2f" % iso_slider.value
	if scale_label:
		scale_label.text = "%.0f" % scale_slider.value

func update_preset_name(name: String):
	if preset_label:
		preset_label.text = name

func set_values(noise: float, iso: float, scale: float):
	if noise_slider:
		noise_slider.value = noise
	if iso_slider:
		iso_slider.value = iso
	if scale_slider:
		scale_slider.value = scale
	update_labels()

