# SoundCard.gd
# Small clickable card for sound effect board

extends PanelContainer
class_name SoundCard

signal pressed(sound_key: String)

var sound_key: String = ""
var display_name: String = ""
var category: String = ""

var _name_label: Label
var _category_label: Label
var _overlay_button: Button
var _normal_style: StyleBoxFlat
var _selected_style: StyleBoxFlat


func _ready():
	_build_ui()


func setup(entry: Dictionary) -> void:
	sound_key = entry.get("sound_key", "")
	display_name = entry.get("display_name", sound_key)
	category = entry.get("category", "")
	_build_ui()
	_name_label.text = display_name
	_category_label.text = category


func set_selected(selected: bool) -> void:
	if selected:
		add_theme_stylebox_override("panel", _selected_style)
	else:
		add_theme_stylebox_override("panel", _normal_style)


func _build_ui() -> void:
	if _name_label:
		return

	custom_minimum_size = Vector2(160, 92)
	mouse_filter = Control.MOUSE_FILTER_PASS

	_normal_style = StyleBoxFlat.new()
	_normal_style.bg_color = Color(0.12, 0.12, 0.16)
	_normal_style.corner_radius_top_left = 6
	_normal_style.corner_radius_top_right = 6
	_normal_style.corner_radius_bottom_left = 6
	_normal_style.corner_radius_bottom_right = 6
	_normal_style.set_border_width_all(1)
	_normal_style.border_color = Color(0.2, 0.2, 0.28)

	_selected_style = _normal_style.duplicate()
	_selected_style.border_color = Color(0.2, 0.85, 1.0)

	add_theme_stylebox_override("panel", _normal_style)

	var vbox := VBoxContainer.new()
	vbox.mouse_filter = Control.MOUSE_FILTER_PASS
	vbox.add_theme_constant_override("separation", 4)
	vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	vbox.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(vbox)

	_name_label = Label.new()
	_name_label.text = "Sound"
	_name_label.autowrap_mode = TextServer.AUTOWRAP_WORD
	_name_label.add_theme_font_size_override("font_size", 18)
	_name_label.add_theme_color_override("font_color", Color(0.9, 0.9, 0.95))
	_name_label.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(_name_label)

	_category_label = Label.new()
	_category_label.text = ""
	_category_label.add_theme_font_size_override("font_size", 14)
	_category_label.add_theme_color_override("font_color", Color(0.6, 0.6, 0.7))
	vbox.add_child(_category_label)

	_overlay_button = Button.new()
	_overlay_button.text = ""
	_overlay_button.flat = true
	_overlay_button.focus_mode = Control.FOCUS_NONE
	_overlay_button.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	var empty := StyleBoxEmpty.new()
	_overlay_button.add_theme_stylebox_override("normal", empty)
	_overlay_button.add_theme_stylebox_override("hover", empty)
	_overlay_button.add_theme_stylebox_override("pressed", empty)
	_overlay_button.pressed.connect(_on_pressed)
	add_child(_overlay_button)


func _on_pressed() -> void:
	if not sound_key.is_empty():
		pressed.emit(sound_key)
