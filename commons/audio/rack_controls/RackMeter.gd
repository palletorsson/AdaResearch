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


func _meter_color(val: float) -> Color:
	var green := RackDesignTokens.get_color("meter_green")
	var yellow := RackDesignTokens.get_color("meter_yellow")
	var red := RackDesignTokens.get_color("meter_red")
	if val < 0.5:
		return green.lerp(yellow, val * 2.0)
	else:
		return yellow.lerp(red, (val - 0.5) * 2.0)
