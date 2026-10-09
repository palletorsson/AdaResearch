# RackSliderBipolar.gd
# Canonical 2D bipolar/center-return vertical slider — fills from center.
# Maps to slider_zero.tscn in 3D. Value 0.5 = center (zero).

extends RackControlBase
class_name RackSliderBipolar

## Signed range and release behaviour are separate. False retains the signed value.
@export var return_to_center: bool = true:
	set(value):
		return_to_center = value
		queue_redraw()


func get_signed_value() -> float:
	return normalized_value * 2.0 - 1.0


func _track_limits() -> Vector2:
	return Vector2(30.0, maxf(31.0, size.y - 38.0))


func _on_pointer_pressed(pos: Vector2) -> void:
	_on_pointer_dragged(pos)


func _on_pointer_dragged(pos: Vector2) -> void:
	var limits := _track_limits()
	set_normalized_value(inverse_lerp(limits.y, limits.x, pos.y))


func _on_pointer_released(_pos: Vector2) -> void:
	if return_to_center:
		set_normalized_value(0.5)


func _init() -> void:
	_control_type = "slz"


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 6.0)
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 8.0)
	var track_top := _track_limits().x
	var track_bottom := _track_limits().y
	var track_height := track_bottom - track_top
	var cx := size.x / 2.0
	var center_y := track_top + track_height / 2.0

	# Groove
	draw_rect(Rect2(cx - track_w / 2.0, track_top, track_w, track_height), _track_groove)

	# Center line (zero mark)
	draw_line(Vector2(cx - 16.0, center_y), Vector2(cx + 16.0, center_y), _label_color, 2.0)
	for ty in [track_top, track_bottom]:
		draw_line(Vector2(cx - 10.0, ty), Vector2(cx + 10.0, ty), Color(_label_color, .65), 1.0)

	# Fill from center to value
	var handle_y := track_bottom - track_height * normalized_value
	var fill_top := minf(center_y, handle_y)
	var fill_bottom := maxf(center_y, handle_y)
	var fill_h := fill_bottom - fill_top
	if fill_h > 0.5:
		draw_rect(Rect2(cx - track_w / 2.0, fill_top, track_w, fill_h), _accent)

	# Handle
	draw_circle(Vector2(cx, handle_y), handle_r + 3, Color(.10, .12, .13))
	draw_circle(Vector2(cx, handle_y), handle_r, _accent)

	# Bipolar value text (-1 to +1)
	var bipolar := get_signed_value()
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("label_font_size")
	var val_text := "%+.2f" % bipolar
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_rect(Rect2(4, 4, size.x - 8, 18), Color(0.10, 0.10, 0.10))
	draw_string(font, Vector2((size.x - tw) / 2.0, 17.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.93, 0.94, 0.87))
	var mode := "RETURNS" if return_to_center else "STAYS"
	var mode_w := font.get_string_size(mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(font, Vector2((size.x - mode_w) / 2.0, size.y - 22), mode,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, _label_color)
