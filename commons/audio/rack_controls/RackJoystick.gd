# RackJoystick.gd
# Canonical 2D joystick — circular base with movable stick.
# Maps to joystick_smooth.tscn in 3D. Dual-axis free movement.

extends RackControlBase
class_name RackJoystick

## Second axis value (Y-axis), normalized 0-1
@export_range(0.0, 1.0) var normalized_value_y: float = 0.5 : set = set_normalized_value_y

signal value_y_changed(new_value: float)


func _init() -> void:
	_control_type = "joystick"


func set_normalized_value_y(val: float) -> void:
	var clamped := clampf(val, 0.0, 1.0)
	if normalized_value_y != clamped:
		normalized_value_y = clamped
		value_y_changed.emit(normalized_value_y)
		queue_redraw()


func _draw_control() -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0)
	var base_r := minf(size.x, size.y - label_margin) / 2.0 - 8.0
	var stick_r := 10.0
	var max_deflect := base_r - stick_r - 4.0

	# Base ring (movement boundary)
	draw_arc(center, base_r, 0.0, TAU, 48, _track_groove, 2.0)
	draw_circle(center, base_r, Color(RackDesignTokens.get_color("screen_bg"), 0.5))

	# Crosshair at center
	var cross_color := Color(_label_dim, 0.2)
	draw_line(Vector2(center.x - base_r + 4.0, center.y), Vector2(center.x + base_r - 4.0, center.y), cross_color, 1.0)
	draw_line(Vector2(center.x, center.y - base_r + 4.0), Vector2(center.x, center.y + base_r - 4.0), cross_color, 1.0)

	# Center dot
	draw_circle(center, 2.0, Color(_label_dim, 0.4))

	# Stick position (map normalized 0-1 to -1..+1, then to pixel offset)
	var offset_x := (normalized_value - 0.5) * 2.0 * max_deflect
	var offset_y := -(normalized_value_y - 0.5) * 2.0 * max_deflect  # Invert Y
	# Clamp to circle
	var offset := Vector2(offset_x, offset_y)
	if offset.length() > max_deflect:
		offset = offset.normalized() * max_deflect
	var stick_pos := center + offset

	# Stick shadow/connection line
	draw_line(center, stick_pos, Color(_label_dim, 0.3), 2.0)

	# Stick head
	draw_circle(stick_pos, stick_r, _accent)
	draw_arc(stick_pos, stick_r + 2.0, 0.0, TAU, 24, Color(_accent, 0.3), 1.5)

	# Inner highlight on stick
	var highlight_pos := stick_pos + Vector2(-2.0, -2.0)
	draw_circle(highlight_pos, 3.0, Color(1.0, 1.0, 1.0, 0.15))
