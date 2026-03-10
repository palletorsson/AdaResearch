# RackSliderV.gd
# Canonical 2D vertical slider — track groove, accent fill, circular handle.
# Maps to slider_smooth.tscn / slider_axis.tscn in 3D.

extends RackControlBase
class_name RackSliderV


func _init() -> void:
	_control_type = "slv"


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 6.0)
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 8.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)

	var track_top := handle_r
	var track_bottom := size.y - label_margin - handle_r
	var track_height := track_bottom - track_top
	var cx := size.x / 2.0

	# Groove
	draw_rect(Rect2(cx - track_w / 2.0, track_top, track_w, track_height), _track_groove)

	# Fill (bottom up)
	var fill_h := track_height * normalized_value
	if fill_h > 0.5:
		draw_rect(Rect2(cx - track_w / 2.0, track_bottom - fill_h, track_w, fill_h), _accent)

	# Handle
	var handle_y := track_bottom - track_height * normalized_value
	draw_circle(Vector2(cx, handle_y), handle_r, _accent)
	# Glow ring
	draw_arc(Vector2(cx, handle_y), handle_r + 2.0, 0.0, TAU, 32, Color(_accent, 0.3), 2.0)

	# Value text
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var val_text := "%.2f" % normalized_value
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, track_top - 2.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)
