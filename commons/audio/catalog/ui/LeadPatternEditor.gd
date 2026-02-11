# LeadPatternEditor.gd
# Scaffold editor for melodic lead lines.
# Reuses BassPatternEditor piano-roll interaction and adds melody-oriented defaults.

extends BassPatternEditor
class_name LeadPatternEditor

var _snap_to_scale: bool = true
var _scale_name: String = "minor"
var _scale_dropdown: OptionButton
var _snap_toggle: CheckBox


func _get_editor_title() -> String:
	return "LEAD MELODY EDITOR"


func _get_editor_color() -> Color:
	return Color(0.9, 0.45, 0.6)


func _on_extra_controls_setup(container: HBoxContainer):
	super._on_extra_controls_setup(container)

	var spacer = Control.new()
	spacer.custom_minimum_size.x = 8
	container.add_child(spacer)

	_snap_toggle = CheckBox.new()
	_snap_toggle.text = "Snap Scale"
	_snap_toggle.button_pressed = _snap_to_scale
	_snap_toggle.toggled.connect(_on_snap_toggled)
	container.add_child(_snap_toggle)

	var scale_label = Label.new()
	scale_label.text = "Scale:"
	scale_label.add_theme_font_size_override("font_size", 12)
	container.add_child(scale_label)

	_scale_dropdown = OptionButton.new()
	var scale_names = ["minor", "major", "dorian", "phrygian", "mixolydian"]
	for scale_name in scale_names:
		_scale_dropdown.add_item(scale_name.capitalize())
	var current_idx = scale_names.find(_scale_name)
	_scale_dropdown.selected = current_idx if current_idx >= 0 else 0
	_scale_dropdown.item_selected.connect(_on_scale_changed)
	container.add_child(_scale_dropdown)

	# Lead default: one octave above bass center.
	_octave_spin.value = 4
	_on_octave_changed(4.0)
	_base_octave = 3
	_visible_octaves = 3


func _on_snap_toggled(pressed: bool):
	_snap_to_scale = pressed


func _on_scale_changed(index: int):
	var scale_names = ["minor", "major", "dorian", "phrygian", "mixolydian"]
	if index >= 0 and index < scale_names.size():
		_scale_name = scale_names[index]


func get_lead_settings() -> Dictionary:
	return {
		"snap_to_scale": _snap_to_scale,
		"scale": _scale_name,
	}
