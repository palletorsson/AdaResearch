# RackSliderH.gd
# Canonical 2D horizontal slider — track groove, accent fill, circular handle.
# Maps to slider_horizontal.tscn in 3D.

extends RackControlBase
class_name RackSliderH


func _init() -> void:
	_control_type = "slh"


func _draw_control() -> void:
	var track_w := RackDesignTokens.get_layout("track_width_px", 6.0)
	var handle_r := RackDesignTokens.get_layout("handle_radius_px", 8.0)
	var label_margin := 16.0  # Horizontal sliders are short, smaller label space

	var track_left := handle_r
	var track_right := size.x - handle_r
	var track_length := track_right - track_left
	var cy := (size.y - label_margin) / 2.0

	# Groove
	draw_rect(Rect2(track_left, cy - track_w / 2.0, track_length, track_w), _track_groove)

	# Fill (left to right)
	var fill_w := track_length * normalized_value
	if fill_w > 0.5:
		draw_rect(Rect2(track_left, cy - track_w / 2.0, fill_w, track_w), _accent)

	# Handle
	var handle_x := track_left + track_length * normalized_value
	draw_circle(Vector2(handle_x, cy), handle_r, _accent)
	draw_arc(Vector2(handle_x, cy), handle_r + 2.0, 0.0, TAU, 32, Color(_accent, 0.3), 2.0)
