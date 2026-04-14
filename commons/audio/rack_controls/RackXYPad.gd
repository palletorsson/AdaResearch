# RackXYPad.gd
# Canonical 2D XY pad — grid surface with crosshair cursor.
# Maps to slider_plane.tscn in 3D. Dual-axis control.

extends RackControlBase
class_name RackXYPad

## Second axis value (Y-axis), normalized 0-1
@export_range(0.0, 1.0) var normalized_value_y: float = 0.5 : set = set_normalized_value_y

signal value_y_changed(new_value: float)


func _init() -> void:
	_control_type = "xy"


func set_normalized_value_y(val: float) -> void:
	var clamped := clampf(val, 0.0, 1.0)
	if normalized_value_y != clamped:
		normalized_value_y = clamped
		value_y_changed.emit(normalized_value_y)
		queue_redraw()


func get_normalized_value_y() -> float:
	return normalized_value_y


func _draw_control() -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var pad_margin := 6.0
	var pad_x := pad_margin
	var pad_y := pad_margin
	var pad_w := size.x - pad_margin * 2.0
	var pad_h := size.y - label_margin - pad_margin

	# Pad background (darker than cell)
	draw_rect(Rect2(pad_x, pad_y, pad_w, pad_h), RackDesignTokens.get_color("screen_bg"))

	# Grid lines
	var grid_color := Color(RackDesignTokens.get_color("screen_grid"), 0.3)
	var grid_count := 4
	for i in range(1, grid_count):
		var gx := pad_x + pad_w * float(i) / float(grid_count)
		draw_line(Vector2(gx, pad_y), Vector2(gx, pad_y + pad_h), grid_color, 1.0)
		var gy := pad_y + pad_h * float(i) / float(grid_count)
		draw_line(Vector2(pad_x, gy), Vector2(pad_x + pad_w, gy), grid_color, 1.0)

	# Center crosshair (dimmer)
	var center_x := pad_x + pad_w / 2.0
	var center_y := pad_y + pad_h / 2.0
	var center_color := Color(_label_dim, 0.2)
	draw_line(Vector2(center_x, pad_y), Vector2(center_x, pad_y + pad_h), center_color, 1.0)
	draw_line(Vector2(pad_x, center_y), Vector2(pad_x + pad_w, center_y), center_color, 1.0)

	# Cursor position
	var cursor_x := pad_x + pad_w * normalized_value
	var cursor_y := pad_y + pad_h * (1.0 - normalized_value_y)  # Invert Y (up = high)

	# Crosshair lines to cursor
	draw_line(Vector2(cursor_x, pad_y), Vector2(cursor_x, pad_y + pad_h), Color(_accent, 0.2), 1.0)
	draw_line(Vector2(pad_x, cursor_y), Vector2(pad_x + pad_w, cursor_y), Color(_accent, 0.2), 1.0)

	# Cursor dot
	draw_circle(Vector2(cursor_x, cursor_y), 5.0, _accent)
	draw_arc(Vector2(cursor_x, cursor_y), 7.0, 0.0, TAU, 24, Color(_accent, 0.3), 1.5)

	# Border
	draw_rect(Rect2(pad_x, pad_y, pad_w, pad_h), Color(_track_groove, 0.6), false, 1.0)


func _on_pointer_pressed(pos: Vector2) -> void:
	_on_pointer_dragged(pos)


func _on_pointer_dragged(pos: Vector2) -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var pad_margin := 6.0
	var pad_x := pad_margin
	var pad_y := pad_margin
	var pad_w := size.x - pad_margin * 2.0
	var pad_h := size.y - label_margin - pad_margin

	var norm_x := clampf((pos.x - pad_x) / pad_w, 0.0, 1.0)
	var norm_y := clampf(1.0 - (pos.y - pad_y) / pad_h, 0.0, 1.0)
	set_normalized_value(norm_x)
	set_normalized_value_y(norm_y)
