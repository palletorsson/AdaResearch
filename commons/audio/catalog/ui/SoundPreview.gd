# SoundPreview.gd
# Sound preview panel with waveform display and play controls
# Used in AudioCatalogUI

extends Control
class_name SoundPreview

signal play_pressed(sound_key: String)
signal stop_pressed()

@export var waveform_color: Color = Color(0.2, 0.85, 1.0)
@export var waveform_bg_color: Color = Color(0.1, 0.1, 0.15)
@export var center_line_color: Color = Color(0.3, 0.3, 0.35)

var _name_label: Label
var _waveform_panel: Control
var _play_btn: Button
var _stop_btn: Button
var _tags_label: Label
var _description_label: RichTextLabel

var _samples: PackedFloat32Array = PackedFloat32Array()
var _current_sound_key: String = ""
var _is_playing: bool = false


func _ready():
	_setup_ui()


func _setup_ui():
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_PASS

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 16)
	add_child(vbox)

	# Sound name
	_name_label = Label.new()
	_name_label.text = "SELECT A SOUND"
	_name_label.add_theme_font_size_override("font_size", 36)
	_name_label.add_theme_color_override("font_color", Color(0.2, 0.85, 1.0))
	_name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(_name_label)

	# Waveform display - ignore mouse events
	_waveform_panel = Control.new()
	_waveform_panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_waveform_panel.custom_minimum_size = Vector2(0, 160)
	_waveform_panel.draw.connect(_on_waveform_draw)
	vbox.add_child(_waveform_panel)

	# Play controls
	var controls_hbox := HBoxContainer.new()
	controls_hbox.mouse_filter = Control.MOUSE_FILTER_PASS
	controls_hbox.alignment = BoxContainer.ALIGNMENT_CENTER
	controls_hbox.add_theme_constant_override("separation", 20)
	vbox.add_child(controls_hbox)

	_play_btn = Button.new()
	_play_btn.text = "  PLAY  "
	_play_btn.pressed.connect(_on_play_pressed)
	_style_button(_play_btn, Color(0.2, 0.6, 0.3))
	controls_hbox.add_child(_play_btn)

	_stop_btn = Button.new()
	_stop_btn.text = "  STOP  "
	_stop_btn.pressed.connect(_on_stop_pressed)
	_style_button(_stop_btn, Color(0.6, 0.3, 0.3))
	controls_hbox.add_child(_stop_btn)

	# Description
	_description_label = RichTextLabel.new()
	_description_label.bbcode_enabled = true
	_description_label.fit_content = true
	_description_label.custom_minimum_size = Vector2(0, 80)
	_description_label.add_theme_color_override("default_color", Color(0.7, 0.7, 0.7))
	vbox.add_child(_description_label)

	# Tags
	_tags_label = Label.new()
	_tags_label.text = ""
	_tags_label.add_theme_font_size_override("font_size", 24)
	_tags_label.add_theme_color_override("font_color", Color(0.5, 0.5, 0.6))
	_tags_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	vbox.add_child(_tags_label)


func _style_button(btn: Button, color: Color) -> void:
	var style := StyleBoxFlat.new()
	style.bg_color = color
	style.corner_radius_top_left = 4
	style.corner_radius_top_right = 4
	style.corner_radius_bottom_left = 4
	style.corner_radius_bottom_right = 4
	style.content_margin_left = 24
	style.content_margin_right = 24
	style.content_margin_top = 12
	style.content_margin_bottom = 12
	btn.add_theme_stylebox_override("normal", style)

	var hover_style := style.duplicate()
	hover_style.bg_color = color.lightened(0.2)
	btn.add_theme_stylebox_override("hover", hover_style)

	var pressed_style := style.duplicate()
	pressed_style.bg_color = color.darkened(0.2)
	btn.add_theme_stylebox_override("pressed", pressed_style)


func show_sound(sound: Dictionary) -> void:
	if sound.is_empty():
		_name_label.text = "SELECT A SOUND"
		_description_label.text = ""
		_tags_label.text = ""
		_current_sound_key = ""
		_samples.clear()
		_waveform_panel.queue_redraw()
		return

	_current_sound_key = sound.sound_key
	_name_label.text = sound.display_name.to_upper()

	var metadata: Dictionary = sound.get("metadata", {})
	var description: String = metadata.get("description", "")
	_description_label.text = description

	var tags: String = metadata.get("tags", "")
	if not tags.is_empty():
		_tags_label.text = "Tags: " + tags
	else:
		_tags_label.text = ""

	_waveform_panel.queue_redraw()


func set_waveform_data(samples: PackedFloat32Array) -> void:
	_samples = samples
	_waveform_panel.queue_redraw()


func set_playing(playing: bool) -> void:
	_is_playing = playing
	_play_btn.disabled = playing
	_stop_btn.disabled = not playing


func _on_waveform_draw() -> void:
	var rect := _waveform_panel.get_rect()
	var w := rect.size.x
	var h := rect.size.y

	# Background
	_waveform_panel.draw_rect(Rect2(Vector2.ZERO, rect.size), waveform_bg_color)

	# Center line
	var center_y := h / 2.0
	_waveform_panel.draw_line(Vector2(0, center_y), Vector2(w, center_y), center_line_color, 1.0)

	# Waveform
	if _samples.is_empty():
		# Draw placeholder
		_waveform_panel.draw_string(
			ThemeDB.fallback_font,
			Vector2(w / 2 - 40, center_y + 5),
			"No waveform",
			HORIZONTAL_ALIGNMENT_CENTER,
			-1, 12, Color(0.4, 0.4, 0.45)
		)
		return

	# Draw waveform as line
	var points := PackedVector2Array()
	var sample_count := _samples.size()
	var step := maxi(1, sample_count / int(w))

	for i in range(0, sample_count, step):
		var x := float(i) / float(sample_count) * w
		var amplitude: float = _samples[i]
		var y := center_y - amplitude * (h * 0.4)
		points.append(Vector2(x, y))

	if points.size() >= 2:
		_waveform_panel.draw_polyline(points, waveform_color, 1.5, true)


func _on_play_pressed() -> void:
	if not _current_sound_key.is_empty():
		play_pressed.emit(_current_sound_key)


func _on_stop_pressed() -> void:
	stop_pressed.emit()
