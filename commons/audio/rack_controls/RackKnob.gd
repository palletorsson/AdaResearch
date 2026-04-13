# RackKnob.gd
# Dieter Rams / Braun style rotary dial — clean black circle on cream,
# thin precise tick marks, copper accent pointer.

extends RackControlBase
class_name RackKnob

const ARC_START_DEG := 135.0
const ARC_SWEEP_DEG := 270.0


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

	# Outer ring — thin black circle (Rams: clean border, no fill)
	draw_arc(center, outer_r, 0, TAU, 64, Color(0.1, 0.1, 0.1), 1.5)

	# Tick marks — 11 precise thin marks around the 270-degree arc
	var tick_color := Color(0.1, 0.1, 0.1, 0.6)
	for i in 11:
		var pct := float(i) / 10.0
		var angle: float = start_rad + sweep_rad * pct
		var is_major := (i == 0 or i == 5 or i == 10)
		var tick_inner := center + Vector2(cos(angle), sin(angle)) * (outer_r + 2.0)
		var tick_outer := center + Vector2(cos(angle), sin(angle)) * (outer_r + (7.0 if is_major else 5.0))
		draw_line(tick_inner, tick_outer, tick_color, 1.0 if is_major else 0.5)

	# Knob body — black filled circle (Rams: solid dark dial)
	draw_circle(center, inner_r + 10.0, Color(0.12, 0.12, 0.12))

	# Inner ring detail — thin lighter circle
	draw_arc(center, inner_r + 10.0, 0, TAU, 48, Color(0.25, 0.25, 0.25), 0.5)

	# Pointer line — thin black from center to edge
	var pointer_start := center + Vector2(cos(value_rad), sin(value_rad)) * (inner_r * 0.5)
	var pointer_end := center + Vector2(cos(value_rad), sin(value_rad)) * (outer_r - 3.0)
	draw_line(pointer_start, pointer_end, Color(0.9, 0.9, 0.85), 2.0)

	# Copper accent dot at pointer tip
	var dot_pos := center + Vector2(cos(value_rad), sin(value_rad)) * (outer_r - 1.0)
	draw_circle(dot_pos, 3.0, _accent)

	# Center hub — small dark dot
	draw_circle(center, 2.5, Color(0.3, 0.3, 0.3))

	# Value text — small, black on cream
	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var val_text := "%.2f" % normalized_value
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, 8.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)


func _on_pointer_pressed(pos: Vector2) -> void:
	_on_pointer_dragged(pos)

func _on_pointer_dragged(pos: Vector2) -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0 + 4.0)
	var angle := center.angle_to_point(pos)  # radians from center to mouse
	# Map angle to 0-1: start at 135 degrees (bottom-left), sweep 270
	var start_rad := deg_to_rad(ARC_START_DEG)
	var sweep_rad := deg_to_rad(ARC_SWEEP_DEG)
	var norm := (angle - start_rad) / sweep_rad
	norm = fmod(norm + 2.0, 1.0)  # Wrap to 0-1
	set_normalized_value(clampf(norm, 0.0, 1.0))
