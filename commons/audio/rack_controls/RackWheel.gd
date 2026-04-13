# RackWheel.gd
# Dieter Rams style tuning dial — like the Braun radio copper wheel.
# Clean circle, fine radial ticks, copper indicator.

extends RackControlBase
class_name RackWheel


func _init() -> void:
	_control_type = "wheel"


func _draw_control() -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0)
	var outer_r := minf(size.x, size.y - label_margin) / 2.0 - 6.0
	var inner_r := outer_r - 8.0

	# Outer ring — thin black circle (Rams: clean border)
	draw_arc(center, outer_r, 0, TAU, 64, Color(0.1, 0.1, 0.1), 1.5)

	# Fine radial tick marks — 24 around full circle
	for i in 24:
		var angle := TAU * float(i) / 24.0
		var is_major := (i % 6 == 0)
		var tick_in := center + Vector2(cos(angle), sin(angle)) * (outer_r + 1.0)
		var tick_out := center + Vector2(cos(angle), sin(angle)) * (outer_r + (6.0 if is_major else 4.0))
		draw_line(tick_in, tick_out, Color(0.1, 0.1, 0.1, 0.5 if is_major else 0.3), 0.5)

	# Wheel body — warm dark circle
	draw_circle(center, inner_r, Color(0.15, 0.14, 0.13))
	draw_arc(center, inner_r, 0, TAU, 48, Color(0.25, 0.24, 0.23), 0.5)

	# Position marker — copper indicator at current angle
	var value_angle := TAU * normalized_value - PI / 2.0
	var marker_inner := center + Vector2(cos(value_angle), sin(value_angle)) * (inner_r * 0.5)
	var marker_outer := center + Vector2(cos(value_angle), sin(value_angle)) * (inner_r - 2.0)
	draw_line(marker_inner, marker_outer, _accent, 2.0)

	# Center hub — small dark dot
	draw_circle(center, 3.0, Color(0.2, 0.2, 0.2))
