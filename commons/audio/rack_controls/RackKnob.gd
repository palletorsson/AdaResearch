# RackKnob.gd
# Dieter Rams / Braun style rotary dial — clean black circle on cream,
# thin precise tick marks, copper accent pointer.

extends RackControlBase
class_name RackKnob

const ARC_START_DEG := 135.0
const ARC_SWEEP_DEG := 270.0

@export var step_count: int = 0 : set = set_step_count


func _init() -> void:
	_control_type = "knob"


func set_step_count(value: int) -> void:
	step_count = maxi(value, 0)
	queue_redraw()


func _draw_control() -> void:
	if style_variant == "selector":
		_draw_selector_control()
		return

	_draw_standard_knob()


func _draw_standard_knob() -> void:
	var outer_r := RackDesignTokens.get_layout("knob_outer_radius_px", 32.0)
	var inner_r := RackDesignTokens.get_layout("knob_inner_radius_px", 12.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0 + 4.0)

	var start_rad := deg_to_rad(ARC_START_DEG)
	var sweep_rad := deg_to_rad(ARC_SWEEP_DEG)
	var display_value := _get_display_value()
	var value_rad := start_rad + sweep_rad * display_value

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
	var val_text := "%.2f" % display_value
	var tw := font.get_string_size(val_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(font, Vector2((size.x - tw) / 2.0, 8.0), val_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, fs, _label_dim)


func _draw_selector_control() -> void:
	var outer_r := RackDesignTokens.get_layout("knob_outer_radius_px", 32.0)
	var body_r := RackDesignTokens.get_layout("knob_inner_radius_px", 12.0) + 11.0
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var center := Vector2(size.x / 2.0, (size.y - label_margin) / 2.0 + 6.0)
	var start_rad := deg_to_rad(ARC_START_DEG)
	var sweep_rad := deg_to_rad(ARC_SWEEP_DEG)
	var steps := _get_effective_step_count()
	var display_value := _get_display_value()
	var selected_index := roundi(display_value * float(steps - 1))
	var value_rad := start_rad + sweep_rad * display_value

	draw_arc(center, outer_r + 1.5, start_rad, start_rad + sweep_rad, 48, Color(0.08, 0.08, 0.08), 2.0)

	for i in range(steps):
		var pct := float(i) / float(steps - 1)
		var angle := start_rad + sweep_rad * pct
		var is_selected := i == selected_index
		var dot_pos := center + Vector2(cos(angle), sin(angle)) * (outer_r + 2.5)
		var dot_color := _accent if is_selected else Color(_label_dim, 0.75)
		draw_circle(dot_pos, 2.6 if is_selected else 1.5, dot_color)

	draw_circle(center, body_r, Color(0.11, 0.11, 0.11))
	draw_arc(center, body_r, 0, TAU, 48, Color(0.25, 0.25, 0.25), 0.8)

	var direction := Vector2(cos(value_rad), sin(value_rad))
	var tangent := Vector2(-direction.y, direction.x)
	var indicator := PackedVector2Array([
		center + direction * (body_r - 3.0),
		center + tangent * 4.0 + direction * 2.0,
		center - tangent * 4.0 + direction * 2.0,
	])
	draw_colored_polygon(indicator, _accent.lightened(0.05))

	draw_line(
		center + direction * 4.0,
		center + direction * (outer_r - 5.0),
		Color(0.95, 0.93, 0.88),
		1.6
	)
	draw_circle(center, 3.0, Color(0.32, 0.32, 0.32))

	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var step_text := str(selected_index)
	var text_width := font.get_string_size(step_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(
		font,
		Vector2((size.x - text_width) / 2.0, 10.0),
		step_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		_label_dim
	)


func _get_effective_step_count() -> int:
	if step_count > 1:
		return step_count
	if style_variant == "selector":
		return 8
	return 0


func _get_display_value() -> float:
	var steps := _get_effective_step_count()
	if steps > 1:
		var step_index := roundi(normalized_value * float(steps - 1))
		return float(step_index) / float(steps - 1)
	return normalized_value


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
	norm = fposmod(norm, 1.0)

	var steps := _get_effective_step_count()
	if steps > 1:
		var snapped_index := roundi(norm * float(steps - 1))
		norm = float(snapped_index) / float(steps - 1)

	set_normalized_value(clampf(norm, 0.0, 1.0))
