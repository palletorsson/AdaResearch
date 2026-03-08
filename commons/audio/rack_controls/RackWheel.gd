# RackWheel.gd
# Canonical 2D scroll wheel — circular dial with position marker.
# Maps to wheel_smooth.tscn in 3D. Supports continuous 360-degree rotation.

extends RackControlBase
class_name RackWheel


func _init() -> void:
	_control_type = "wheel"


func _draw_control() -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0)
	var outer_r := minf(size.x, size.y - label_margin) / 2.0 - 6.0
	var inner_r := outer_r - 10.0

	# Outer ring
	draw_arc(center, outer_r, 0.0, TAU, 64, _track_groove, 3.0)

	# Grip notches (8 evenly spaced)
	var notch_color := Color(_label_dim, 0.3)
	for i in range(8):
		var angle := TAU * float(i) / 8.0
		var p1 := center + Vector2(cos(angle), sin(angle)) * (inner_r + 2.0)
		var p2 := center + Vector2(cos(angle), sin(angle)) * outer_r
		draw_line(p1, p2, notch_color, 1.0)

	# Wheel body
	draw_circle(center, inner_r, RackDesignTokens.get_color("panel_dark"))
	draw_arc(center, inner_r, 0.0, TAU, 48, Color(_track_groove, 0.6), 1.0)

	# Position marker (value maps to full rotation)
	var value_angle := TAU * normalized_value - PI / 2.0  # Start at top
	var marker_pos := center + Vector2(cos(value_angle), sin(value_angle)) * (inner_r - 6.0)
	draw_circle(marker_pos, 4.0, _accent)
	# Glow
	draw_arc(marker_pos, 6.0, 0.0, TAU, 16, Color(_accent, 0.3), 1.5)

	# Center hub
	draw_circle(center, 4.0, _track_groove)
