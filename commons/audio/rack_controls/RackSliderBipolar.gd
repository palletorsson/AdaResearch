# RackSliderBipolar.gd
# Canonical 2D bipolar/center-return vertical slider — fills from center.
# Maps to slider_zero.tscn in 3D. Value 0.5 = center (zero).

extends RackControlBase
class_name RackSliderBipolar


func _init() -> void:
	_control_type = "slz"


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 6.0)
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 8.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)

	var track_top := handle_r
	var track_bottom := size.y - label_margin - handle_r
	var track_height := track_bottom - track_top
	var cx := size.x / 2.0
	var center_y := track_top + track_height / 2.0

	# Groove
	draw_rect(Rect2(cx - track_w / 2.0, track_top, track_w, track_height), _track_groove)

	# Center line (zero mark)
	draw_line(Vector2(cx - 10.0, center_y), Vector2(cx + 10.0, center_y), Color(_label_dim, 0.5), 1.0)

	# Fill from center to value
	var handle_y := track_bottom - track_height * normalized_value
	var fill_top := minf(center_y, handle_y)
	var fill_bottom := maxf(center_y, handle_y)
	var fill_h := fill_bottom - fill_top
	if fill_h > 0.5:
		draw_rect(Rect2(cx - track_w / 2.0, fill_top, track_w, fill_h), _accent)

	# Handle
	draw_circle(Vector2(cx, handle_y), handle_r, _accent)
	draw_arc(Vector2(cx, handle_y), handle_r + 2.0, 0.0, TAU, 32, Color(_accent, 0.3), 2.0)

	# Bipolar value text (-1 to +1)
	var bipolar := (normalized_value - 0.5) * 2.0
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var val_text := "%+.2f" % bipolar
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, track_top - 2.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)
