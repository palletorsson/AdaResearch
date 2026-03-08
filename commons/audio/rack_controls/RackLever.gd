# RackLever.gd
# Canonical 2D throw lever — vertical stick with pivot at bottom.
# Maps to lever_smooth.tscn in 3D.

extends RackControlBase
class_name RackLever

## Max angle in degrees from center (both directions)
const MAX_ANGLE_DEG := 35.0


func _init() -> void:
	_control_type = "lever"


func _draw_control() -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var cx := size.x / 2.0
	var pivot_y := size.y - label_margin - 10.0
	var stick_length := pivot_y - 16.0

	# Angle from value: 0=left, 0.5=center, 1=right
	var angle_deg := (normalized_value - 0.5) * 2.0 * MAX_ANGLE_DEG
	var angle_rad := deg_to_rad(angle_deg)

	# Slot arc (movement range indicator)
	var slot_start := deg_to_rad(-90.0 - MAX_ANGLE_DEG)
	var slot_end := deg_to_rad(-90.0 + MAX_ANGLE_DEG)
	var slot_r := 16.0
	draw_arc(Vector2(cx, pivot_y), slot_r, slot_start, slot_end, 32, Color(_track_groove, 0.6), 3.0)

	# Pivot base
	draw_circle(Vector2(cx, pivot_y), 6.0, _track_groove)

	# Stick
	var stick_end_x := cx + sin(angle_rad) * stick_length
	var stick_end_y := pivot_y - cos(angle_rad) * stick_length
	draw_line(Vector2(cx, pivot_y), Vector2(stick_end_x, stick_end_y), Color(_label_dim, 0.8), 3.0)

	# Handle ball at top of stick
	draw_circle(Vector2(stick_end_x, stick_end_y), 7.0, _accent)
	draw_arc(Vector2(stick_end_x, stick_end_y), 9.0, 0.0, TAU, 24, Color(_accent, 0.3), 1.5)

	# Position indicator dot on slot arc
	var indicator_angle := deg_to_rad(-90.0 + angle_deg)
	var dot_pos := Vector2(cx, pivot_y) + Vector2(cos(indicator_angle), sin(indicator_angle)) * slot_r
	draw_circle(dot_pos, 3.0, _accent)
