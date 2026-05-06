# RackMeter.gd
# Canonical 2D VU level meter — vertical bar with peak hold indicator.
# Draws: groove background, gradient fill (green→yellow→red), peak line.

extends RackControlBase
class_name RackMeter

## Current audio level 0-1 (driven externally, e.g. by spectrum analyzer)
var level: float = 0.0 : set = set_level

## Peak hold state
var _peak_level: float = 0.0
var _peak_hold_timer: float = 0.0
const PEAK_HOLD_DURATION := 1.0
const PEAK_DECAY_SPEED := 0.5
const NEEDLE_START_DEG := 160.0
const NEEDLE_SWEEP_DEG := 220.0


func _init() -> void:
	_control_type = "meter"


func _process(delta: float) -> void:
	_peak_hold_timer -= delta
	if _peak_hold_timer <= 0.0:
		_peak_level = maxf(_peak_level - delta * PEAK_DECAY_SPEED, level)
	queue_redraw()


func set_level(val: float) -> void:
	level = clampf(val, 0.0, 1.0)
	if level > _peak_level:
		_peak_level = level
		_peak_hold_timer = PEAK_HOLD_DURATION
	# Also sync normalized_value for base class
	normalized_value = level


func _draw_control() -> void:
	if style_variant == "needle":
		_draw_needle_meter()
		return

	_draw_bar_meter()


func _draw_bar_meter() -> void:
	var margin := RackDesignTokens.get_layout("meter_bar_margin_px", 4.0)
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var bar_x := margin
	var bar_top := 4.0
	var bar_w := size.x - margin * 2.0
	var bar_h := size.y - label_margin - bar_top

	# Groove background
	draw_rect(Rect2(bar_x, bar_top, bar_w, bar_h), _track_groove)

	# Level fill with gradient color
	var fill_h := bar_h * level
	if fill_h > 0.5:
		var fill_color := _meter_color(level)
		draw_rect(Rect2(bar_x + 1, bar_top + bar_h - fill_h, bar_w - 2, fill_h), fill_color)

	# Peak indicator line
	if _peak_level > 0.01:
		var peak_y := bar_top + bar_h * (1.0 - _peak_level)
		var peak_color := RackDesignTokens.get_color("accent_red")
		draw_rect(Rect2(bar_x + 1, peak_y, bar_w - 2, 2.0), peak_color)

	# Tick marks (0%, 50%, 100%)
	var tick_color := Color(_label_dim, 0.5)
	for pct: float in [0.0, 0.25, 0.5, 0.75, 1.0]:
		var ty: float = bar_top + bar_h * (1.0 - pct)
		draw_line(Vector2(bar_x, ty), Vector2(bar_x + 3, ty), tick_color, 1.0)


func _draw_needle_meter() -> void:
	var label_margin := RackDesignTokens.get_layout("label_bottom_margin_px", 24.0)
	var usable_h := size.y - label_margin
	var center := Vector2(size.x / 2.0, usable_h * 0.78)
	var radius := minf(size.x * 0.42, usable_h * 0.34)
	var start_rad := deg_to_rad(NEEDLE_START_DEG)
	var sweep_rad := deg_to_rad(NEEDLE_SWEEP_DEG)
	var display_level := clampf(level, 0.0, 1.0)
	var peak_level := clampf(_peak_level, 0.0, 1.0)

	draw_arc(center, radius, start_rad, start_rad + sweep_rad * 0.72, 28, Color(0.12, 0.12, 0.12), 1.5)
	draw_arc(
		center,
		radius,
		start_rad + sweep_rad * 0.72,
		start_rad + sweep_rad,
		16,
		RackDesignTokens.get_color("meter_red"),
		1.5
	)

	for i in range(7):
		var pct := float(i) / 6.0
		var angle := start_rad + sweep_rad * pct
		var direction := Vector2(cos(angle), sin(angle))
		var tick_start := center + direction * (radius - 5.0)
		var tick_end := center + direction * (radius + 1.0)
		draw_line(tick_start, tick_end, Color(_label_dim, 0.8), 1.0)
		if i < 6:
			var dot_pos := center + direction * (radius + 4.0)
			draw_circle(dot_pos, 0.9, Color(_label_dim, 0.45))

	var peak_angle := start_rad + sweep_rad * peak_level
	var peak_dir := Vector2(cos(peak_angle), sin(peak_angle))
	draw_line(center, center + peak_dir * (radius - 7.0), Color(1.0, 1.0, 1.0, 0.20), 1.0)

	var needle_angle := start_rad + sweep_rad * display_level
	var needle_dir := Vector2(cos(needle_angle), sin(needle_angle))
	draw_line(center, center + needle_dir * (radius - 4.0), _accent, 2.0)

	var baseline_y := center.y + radius * 0.30
	draw_line(
		Vector2(center.x - radius * 0.85, baseline_y),
		Vector2(center.x + radius * 0.85, baseline_y),
		Color(_label_dim, 0.22),
		1.0
	)

	draw_circle(center, 3.3, Color(0.12, 0.12, 0.12))
	draw_circle(center, 1.8, _accent)

	var font := get_theme_default_font()
	var fs := RackDesignTokens.get_font_size("value_font_size")
	var pct_text := "%02d" % [int(round(display_level * 99.0))]
	var text_w := font.get_string_size(pct_text, HORIZONTAL_ALIGNMENT_CENTER, -1, fs).x
	draw_string(
		font,
		Vector2((size.x - text_w) / 2.0, baseline_y - 4.0),
		pct_text,
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		fs,
		_label_dim
	)


func _meter_color(val: float) -> Color:
	var green := RackDesignTokens.get_color("meter_green")
	var yellow := RackDesignTokens.get_color("meter_yellow")
	var red := RackDesignTokens.get_color("meter_red")
	if val < 0.5:
		return green.lerp(yellow, val * 2.0)
	else:
		return yellow.lerp(red, (val - 0.5) * 2.0)
