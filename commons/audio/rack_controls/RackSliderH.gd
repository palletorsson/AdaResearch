# RackSliderH.gd
# Dieter Rams style horizontal fader — thin black track, black handle, copper dot.

extends RackControlBase
class_name RackSliderH


func _init() -> void:
	_control_type = "slh"


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 2.0)
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 6.0)
	var label_margin := 16.0

	var track_left := handle_r + 4.0
	var track_right := size.x - handle_r - 4.0
	var track_length := track_right - track_left
	var cy := (size.y - label_margin) / 2.0

	# Track — thin black line
	draw_rect(Rect2(track_left, cy - track_w / 2.0, track_length, track_w), Color(0.1, 0.1, 0.1))

	# End ticks
	draw_line(Vector2(track_left, cy - 5), Vector2(track_left, cy + 5), Color(0.1, 0.1, 0.1, 0.5), 0.5)
	draw_line(Vector2(track_right, cy - 5), Vector2(track_right, cy + 5), Color(0.1, 0.1, 0.1, 0.5), 0.5)

	# Center tick
	var mid_x := (track_left + track_right) / 2.0
	draw_line(Vector2(mid_x, cy - 3), Vector2(mid_x, cy + 3), Color(0.1, 0.1, 0.1, 0.3), 0.5)

	# Handle — black circle with copper center
	var handle_x := track_left + track_length * normalized_value
	draw_circle(Vector2(handle_x, cy), handle_r, Color(0.12, 0.12, 0.12))
	draw_arc(Vector2(handle_x, cy), handle_r, 0, TAU, 24, Color(0.25, 0.25, 0.25), 0.5)
	draw_circle(Vector2(handle_x, cy), 2.0, _accent)


func _on_pointer_pressed(pos: Vector2) -> void:
	_on_pointer_dragged(pos)

func _on_pointer_dragged(pos: Vector2) -> void:
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 6.0)
	var track_left := handle_r + 4.0
	var track_right := size.x - handle_r - 4.0
	var track_length := track_right - track_left
	var norm := (pos.x - track_left) / track_length
	set_normalized_value(clampf(norm, 0.0, 1.0))
