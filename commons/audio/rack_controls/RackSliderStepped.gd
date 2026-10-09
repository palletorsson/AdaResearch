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
	set_normalized_value(normalized_value)
	queue_redraw()


## Quantize the stored/emitted value too, so the receiver agrees with the handle.
func set_normalized_value(val: float) -> void:
	var intervals := maxi(steps - 1, 1)
	super.set_normalized_value(float(roundi(clampf(val, 0.0, 1.0) * intervals)) / intervals)


func _track_limits() -> Vector2:
	return Vector2(30.0, maxf(31.0, size.y - 38.0))


func _on_pointer_pressed(pos: Vector2) -> void:
	_on_pointer_dragged(pos)


func _on_pointer_dragged(pos: Vector2) -> void:
	var limits := _track_limits()
	set_normalized_value(inverse_lerp(limits.y, limits.x, pos.y))


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 6.0)
	var track_top := _track_limits().x
	var track_bottom := _track_limits().y
	var track_height := track_bottom - track_top
	var cx := size.x / 2.0

	# Groove
	draw_rect(Rect2(cx - track_w / 2.0, track_top, track_w, track_height), _track_groove)

	# Tick marks for each step
	var tick_color := Color(_label_color, 0.65)
	for i in range(steps):
		var pct := float(i) / float(steps - 1)
		var ty := track_bottom - track_height * pct
		draw_line(Vector2(cx - 16.0, ty), Vector2(cx + 16.0, ty), tick_color, 1.5)

	# Snap value to nearest step
	var step_index := roundi(normalized_value * (steps - 1))
	var snapped := float(step_index) / float(steps - 1)

	# Fill
	var fill_h := track_height * snapped
	if fill_h > 0.5:
		draw_rect(Rect2(cx - track_w / 2.0, track_bottom - fill_h, track_w, fill_h), _accent)

	# Handle at snapped position
	var handle_y := track_bottom - track_height * snapped
	draw_style_box(_thumb_style(), Rect2(cx - 14, handle_y - 7, 28, 14))
	draw_line(Vector2(cx - 9, handle_y), Vector2(cx + 9, handle_y), _accent, 3.0)

	# Step number text
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("label_font_size")
	var step_text := "%d/%d" % [step_index + 1, steps]
	var tw := font.get_string_size(step_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_rect(Rect2(4, 4, size.x - 8, 18), Color(0.10, 0.10, 0.10))
	draw_string(font, Vector2((size.x - tw) / 2.0, 17.0), step_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color(0.93, 0.94, 0.87))
	var mode := "STAYS"
	var mode_w := font.get_string_size(mode, HORIZONTAL_ALIGNMENT_LEFT, -1, 9).x
	draw_string(font, Vector2((size.x - mode_w) / 2.0, size.y - 22), mode,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 9, _label_color)


func _thumb_style() -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = Color(.10, .12, .13)
	style.set_corner_radius_all(3)
	return style
