# RackSliderV.gd
# Dieter Rams style vertical fader — thin black track, black handle, copper dot.

extends RackControlBase
class_name RackSliderV


func _init() -> void:
	_control_type = "slv"


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 2.0)
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 6.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)

	var track_top := handle_r + 4.0
	var track_bottom := size.y - label_margin - handle_r - 4.0
	var track_height := track_bottom - track_top
	var cx := size.x / 2.0

	# Track — thin black line (Rams: minimal)
	draw_rect(Rect2(cx - track_w / 2.0, track_top, track_w, track_height), Color(0.1, 0.1, 0.1))

	# End tick marks (top and bottom)
	draw_line(Vector2(cx - 6, track_top), Vector2(cx + 6, track_top), Color(0.1, 0.1, 0.1, 0.5), 0.5)
	draw_line(Vector2(cx - 6, track_bottom), Vector2(cx + 6, track_bottom), Color(0.1, 0.1, 0.1, 0.5), 0.5)

	# Center tick
	var mid_y := (track_top + track_bottom) / 2.0
	draw_line(Vector2(cx - 4, mid_y), Vector2(cx + 4, mid_y), Color(0.1, 0.1, 0.1, 0.3), 0.5)

	# Handle — black circle with copper center
	var handle_y := track_bottom - track_height * normalized_value
	draw_circle(Vector2(cx, handle_y), handle_r, Color(0.12, 0.12, 0.12))
	draw_arc(Vector2(cx, handle_y), handle_r, 0, TAU, 24, Color(0.25, 0.25, 0.25), 0.5)
	# Copper center dot
	draw_circle(Vector2(cx, handle_y), 2.5, _accent)

	# Value text — small black
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var val_text := "%.2f" % normalized_value
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, track_top - 4.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)


func _on_pointer_pressed(pos: Vector2) -> void:
	_on_pointer_dragged(pos)

func _on_pointer_dragged(pos: Vector2) -> void:
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 6.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var track_top := handle_r + 4.0
	var track_bottom := size.y - label_margin - handle_r - 4.0
	var track_height := track_bottom - track_top
	var norm := 1.0 - (pos.y - track_top) / track_height  # Inverted: top=1, bottom=0
	set_normalized_value(clampf(norm, 0.0, 1.0))
