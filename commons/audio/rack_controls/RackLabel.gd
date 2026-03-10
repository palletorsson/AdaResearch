# RackLabel.gd
# Canonical 2D text label for rack panels.
# Draws centered text with optional subtitle line.

extends RackControlBase
class_name RackLabel

## Primary text displayed
@export var text: String = "LABEL" : set = set_text

## Optional smaller subtitle
@export var subtitle: String = "" : set = set_subtitle

## Text alignment
@export_enum("left", "center", "right") var text_align: String = "center"


func _init() -> void:
	_control_type = "label"


func set_text(val: String) -> void:
	text = val
	queue_redraw()


func set_subtitle(val: String) -> void:
	subtitle = val
	queue_redraw()


func _draw_control() -> void:
	var font := get_theme_default_font()
	var title_fs := RackDesignTokens.get_font_size("title_font_size")
	var value_fs := RackDesignTokens.get_font_size("value_font_size")

	# Main text
	var ha := _get_alignment()
	var text_size := font.get_string_size(text, ha, -1, title_fs)
	var text_y: float
	if subtitle.is_empty():
		text_y = size.y / 2.0 + text_size.y / 3.0
	else:
		text_y = size.y / 2.0 - 2.0

	var text_x := _get_text_x(text_size.x)
	draw_string(font, Vector2(text_x, text_y), text, HORIZONTAL_ALIGNMENT_LEFT, -1, title_fs, _label_color)

	# Subtitle
	if not subtitle.is_empty():
		var sub_size := font.get_string_size(subtitle, ha, -1, value_fs)
		var sub_x := _get_text_x(sub_size.x)
		var sub_y := text_y + title_fs + 2.0
		draw_string(font, Vector2(sub_x, sub_y), subtitle, HORIZONTAL_ALIGNMENT_LEFT, -1, value_fs, _label_dim)


func _draw_label() -> void:
	# Override: labels don't draw the standard bottom label
	pass


func _get_text_x(text_width: float) -> float:
	match text_align:
		"left":
			return 4.0
		"right":
			return size.x - text_width - 4.0
		_:
			return (size.x - text_width) / 2.0


func _get_alignment() -> HorizontalAlignment:
	match text_align:
		"left": return HORIZONTAL_ALIGNMENT_LEFT
		"right": return HORIZONTAL_ALIGNMENT_RIGHT
		_: return HORIZONTAL_ALIGNMENT_CENTER
