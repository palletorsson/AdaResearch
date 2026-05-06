class_name ProfileCartridge
extends RefCounted

## Base class for Profile substrate algorithm cartridges.
## Produces a 1D continuous curve: an array of Y-values sampled at N points.
## Optionally produces multiple overlaid traces (e.g. harmonics building up).
##
## Step updates the sample buffer. Renderer draws the curve as a ribbon mesh.

## --- Override these ---

## Display name.
func get_name() -> String:
	return "Unknown"

## Number of sample points along X.
func get_sample_count() -> int:
	return 256

## Number of simultaneous traces (1 = single line).
func get_trace_count() -> int:
	return 1

## Color for trace at given index.
func get_trace_color(trace_index: int) -> Color:
	var hues = [0.33, 0.55, 0.08, 0.80, 0.0, 0.15]  # green, cyan, yellow, purple, red, orange
	var h = hues[trace_index % hues.size()]
	return Color.from_hsv(h, 0.8, 1.0)

## Line width for trace at given index (multiplier on base width).
func get_trace_width(trace_index: int) -> float:
	if trace_index == 0:
		return 1.0
	return 0.6  # secondary traces are thinner

## Emission for trace at given index.
func get_trace_emission(trace_index: int) -> float:
	if trace_index == 0:
		return 0.8
	return 0.4

## Y-axis range: [min_y, max_y]. Values outside are clamped.
func get_y_range() -> Vector2:
	return Vector2(-1.0, 1.0)

## Whether the X-axis scrolls (oscilloscope-style) or is fixed.
func is_scrolling() -> bool:
	return false

## Whether grid lines should be drawn.
func show_grid() -> bool:
	return true

## Number of X divisions for grid.
func get_x_divisions() -> int:
	return 10

## Number of Y divisions for grid.
func get_y_divisions() -> int:
	return 8

## X-axis label (empty = none).
func get_x_label() -> String:
	return ""

## Y-axis label.
func get_y_label() -> String:
	return ""

## Called once. Return initial sample buffers.
## Returns Array[PackedFloat32Array] — one buffer per trace, each of length get_sample_count().
## Values in Y-range.
func initialize(sample_count: int) -> Array:
	var traces = []
	for t in range(get_trace_count()):
		var buf = PackedFloat32Array()
		buf.resize(sample_count)
		buf.fill(0.0)
		traces.append(buf)
	return traces

## Advance one step. Update sample buffers in-place or return new ones.
## Returns Dictionary:
## {
##   "traces": Array[PackedFloat32Array] or null (null = unchanged),
##   "markers": Array[Dictionary],  — [{x: float, color: Color, label: String}] vertical markers
##   "done": bool,
##   "description": String
## }
func step(traces: Array, step_index: int, delta_time: float) -> Dictionary:
	return {
		"traces": null,
		"markers": [],
		"done": true,
		"description": ""
	}

## Called when player touches the curve at normalized x position (0..1).
func on_touch(x_normalized: float, traces: Array) -> Array:
	return traces

## Preferred step interval (0 = use substrate default).
func get_preferred_interval() -> float:
	return 0.0

## Pre-compute steps.
func get_warmup_steps() -> int:
	return 0
