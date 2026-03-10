# RackSliderStepped.gd
# Canonical 2D stepped/snapped vertical slider — discrete positions with tick marks.
# Maps to slider_snap.tscn in 3D.

extends RackControlBase
class_name RackSliderStepped

## Number of discrete steps (includes endpoints)
@export var steps: int = 5 : set = set_steps


func _init() -> void:
	_control_type = "sls"


func set_steps(val: int) -> void:
	steps = maxi(val, 2)
	queue_redraw()


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

	# Tick marks for each step
	var tick_color := Color(_label_dim, 0.6)
	for i in range(steps):
		var pct := float(i) / float(steps - 1)
		var ty := track_bottom - track_height * pct
		draw_line(Vector2(cx - 8.0, ty), Vector2(cx - track_w / 2.0 - 2.0, ty), tick_color, 1.0)
		draw_line(Vector2(cx + track_w / 2.0 + 2.0, ty), Vector2(cx + 8.0, ty), tick_color, 1.0)

	# Snap value to nearest step
	var step_index := roundi(normalized_value * (steps - 1))
	var snapped := float(step_index) / float(steps - 1)

	# Fill
	var fill_h := track_height * snapped
	if fill_h > 0.5:
		draw_rect(Rect2(cx - track_w / 2.0, track_bottom - fill_h, track_w, fill_h), _accent)

	# Handle at snapped position
	var handle_y := track_bottom - track_height * snapped
	draw_circle(Vector2(cx, handle_y), handle_r, _accent)
	draw_arc(Vector2(cx, handle_y), handle_r + 2.0, 0.0, TAU, 32, Color(_accent, 0.3), 2.0)

	# Step number text
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var step_text := "%d/%d" % [step_index + 1, steps]
	var tw := font.get_string_size(step_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, track_top - 2.0), step_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)
