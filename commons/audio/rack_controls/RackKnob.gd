# RackKnob.gd
# Canonical 2D rotary dial — 270-degree arc with pointer line.
# Maps to dial_smooth.tscn in 3D.

extends RackControlBase
class_name RackKnob

## Arc sweep range in degrees (centered at bottom)
const ARC_START_DEG := 135.0   # Bottom-left
const ARC_SWEEP_DEG := 270.0   # Total range


func _init() -> void:
	_control_type = "knob"


func _draw_control() -> void:
	var outer_r := RackDesignTokens.get_layout("knob_outer_radius_px", 32.0)
	var inner_r := RackDesignTokens.get_layout("knob_inner_radius_px", 12.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0 + 4.0)

	var start_rad := deg_to_rad(ARC_START_DEG)
	var sweep_rad := deg_to_rad(ARC_SWEEP_DEG)
	var value_rad := start_rad + sweep_rad * normalized_value

	# Background arc (full range groove)
	draw_arc(center, outer_r, start_rad, start_rad + sweep_rad, 64, _track_groove, 4.0)

	# Value arc (filled portion)
	if normalized_value > 0.01:
		draw_arc(center, outer_r, start_rad, value_rad, 64, _accent, 4.0)

	# Tick marks — 11 ticks around arc (more visible)
	var tick_color := Color(_label_dim, 0.7)
	for i in 11:
		var pct := float(i) / 10.0
		var angle: float = start_rad + sweep_rad * pct
		var is_major := (i == 0 or i == 5 or i == 10)
		var tick_inner := center + Vector2(cos(angle), sin(angle)) * (outer_r + 3.0)
		var tick_outer := center + Vector2(cos(angle), sin(angle)) * (outer_r + (9.0 if is_major else 6.0))
		draw_line(tick_inner, tick_outer, tick_color, 1.5 if is_major else 1.0)

	# Knob body (filled circle)
	draw_circle(center, inner_r + 8.0, RackDesignTokens.get_color("panel_dark"))
	draw_arc(center, inner_r + 8.0, 0.0, TAU, 32, Color(_track_groove, 0.8), 1.0)

	# Pointer line from center to value angle
	var pointer_start := center + Vector2(cos(value_rad), sin(value_rad)) * inner_r
	var pointer_end := center + Vector2(cos(value_rad), sin(value_rad)) * (outer_r - 2.0)
	draw_line(pointer_start, pointer_end, _accent, 3.5)

	# Center dot
	draw_circle(center, 3.0, _accent)

	# Value text above
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var val_text := "%.2f" % normalized_value
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, 8.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)
