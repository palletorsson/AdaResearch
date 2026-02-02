# oscilloscope_display.gd - Multi-mode oscilloscope visualization
# Modes: Waveform (sine/square/saw/triangle), Lissajous, Spectrum, XY
# Classic green phosphor CRT aesthetic with modern features
extends Control
class_name OscilloscopeDisplay

enum Mode { WAVEFORM, LISSAJOUS, XY_PLOT }
enum WaveShape { SINE, SQUARE, SAW, TRIANGLE }

## Display Mode
@export var mode: Mode = Mode.WAVEFORM
@export var wave_shape: WaveShape = WaveShape.SINE

## Visual Style
@export var phosphor_color: Color = Color(0.2, 1.0, 0.4, 1.0)  # Classic green
@export var background_color: Color = Color(0.01, 0.03, 0.01, 1.0)
@export var grid_color: Color = Color(0.08, 0.15, 0.08, 0.7)
@export var line_width: float = 2.5
@export var glow_intensity: float = 1.0
@export var scanlines: bool = true
@export var persistence: float = 0.3  # Phosphor persistence (trail)

## Waveform Parameters
@export var frequency_a: float = 440.0  # Primary frequency (Hz)
@export var frequency_b: float = 440.0  # Secondary frequency (for Lissajous)
@export var amplitude: float = 0.8
@export var phase_offset: float = 0.0  # Radians
@export var time_div: float = 1.0  # Time/division (affects cycles shown)

## Animation
@export var animate: bool = true
@export var sweep_speed: float = 2.0

## Audio Input (optional)
@export var source_bus: String = ""  # Empty = pure mathematical oscillator

# Internal state
var _time: float = 0.0
var _display_rect: Rect2
var _point_history: Array[PackedVector2Array] = []
var _history_max: int = 8
var _spectrum_instance: AudioEffectSpectrumAnalyzerInstance
const SAMPLE_COUNT: int = 512

signal mode_changed(new_mode: Mode)
signal frequency_changed(freq_a: float, freq_b: float)

func _ready() -> void:
	_display_rect = Rect2(Vector2.ZERO, size)
	resized.connect(_on_resized)
	
	if source_bus != "":
		_setup_audio()

func _setup_audio() -> void:
	var bus_idx = AudioServer.get_bus_index(source_bus)
	if bus_idx == -1:
		return
	
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum_instance = AudioServer.get_bus_effect_instance(bus_idx, i)
			return

func _process(delta: float) -> void:
	if animate:
		_time += delta * sweep_speed
	queue_redraw()

func _draw() -> void:
	# Background
	draw_rect(_display_rect, background_color)
	
	# Grid
	_draw_grid()
	
	# Scanlines effect
	if scanlines:
		_draw_scanlines()
	
	# Main visualization based on mode
	match mode:
		Mode.WAVEFORM:
			_draw_waveform()
		Mode.LISSAJOUS:
			_draw_lissajous()
		Mode.XY_PLOT:
			_draw_xy_plot()
	
	# Info overlay
	_draw_info()
	
	# CRT bezel vignette
	_draw_vignette()

func _draw_grid() -> void:
	var w = _display_rect.size.x
	var h = _display_rect.size.y
	var center = _display_rect.size / 2.0
	
	# Major divisions (8x10 standard oscilloscope grid)
	var h_div = 8
	var v_div = 10
	
	# Horizontal lines
	for i in range(h_div + 1):
		var y = (float(i) / h_div) * h
		var alpha = 0.9 if i == h_div / 2 else 0.4
		draw_line(Vector2(0, y), Vector2(w, y), Color(grid_color, alpha), 1.0)
	
	# Vertical lines
	for i in range(v_div + 1):
		var x = (float(i) / v_div) * w
		var alpha = 0.9 if i == v_div / 2 else 0.4
		draw_line(Vector2(x, 0), Vector2(x, h), Color(grid_color, alpha), 1.0)
	
	# Center tick marks (minor divisions)
	var tick_size = 4.0
	for i in range(v_div * 5 + 1):
		var x = (float(i) / (v_div * 5)) * w
		var ts = tick_size if i % 5 == 0 else tick_size * 0.5
		draw_line(Vector2(x, center.y - ts), Vector2(x, center.y + ts), grid_color, 1.0)
	
	for i in range(h_div * 5 + 1):
		var y = (float(i) / (h_div * 5)) * h
		var ts = tick_size if i % 5 == 0 else tick_size * 0.5
		draw_line(Vector2(center.x - ts, y), Vector2(center.x + ts, y), grid_color, 1.0)

func _draw_scanlines() -> void:
	var h = _display_rect.size.y
	var scanline_color = Color(0, 0, 0, 0.15)
	for y in range(0, int(h), 3):
		draw_line(Vector2(0, y), Vector2(_display_rect.size.x, y), scanline_color, 1.0)

func _draw_waveform() -> void:
	var w = _display_rect.size.x
	var h = _display_rect.size.y
	var center_y = h / 2.0
	var amp_px = h * 0.4 * amplitude
	
	# Calculate cycles based on frequency and time_div
	var num_cycles = (frequency_a / 100.0) * time_div
	num_cycles = clamp(num_cycles, 0.5, 20.0)
	
	var points = PackedVector2Array()
	
	for i in range(SAMPLE_COUNT):
		var t = float(i) / (SAMPLE_COUNT - 1)
		var x = t * w
		var phase = t * TAU * num_cycles + _time * TAU + phase_offset
		
		var value: float
		match wave_shape:
			WaveShape.SINE:
				value = sin(phase)
			WaveShape.SQUARE:
				value = sign(sin(phase))
			WaveShape.SAW:
				value = 2.0 * (fmod(phase / TAU + 0.5, 1.0)) - 1.0
			WaveShape.TRIANGLE:
				value = 2.0 * abs(2.0 * (fmod(phase / TAU + 0.25, 1.0)) - 1.0) - 1.0
		
		var y = center_y - value * amp_px
		points.append(Vector2(x, y))
	
	_draw_phosphor_trace(points)

func _draw_lissajous() -> void:
	var center = _display_rect.size / 2.0
	var radius = min(_display_rect.size.x, _display_rect.size.y) * 0.4 * amplitude
	
	# Frequency ratio for Lissajous pattern
	var ratio = frequency_b / frequency_a if frequency_a > 0 else 1.0
	
	var points = PackedVector2Array()
	
	for i in range(SAMPLE_COUNT):
		var t = float(i) / (SAMPLE_COUNT - 1) * TAU * 2.0 + _time
		
		# Lissajous: x = sin(at + δ), y = sin(bt)
		var x_val = sin(t + phase_offset) * radius
		var y_val = sin(t * ratio) * radius
		
		points.append(center + Vector2(x_val, -y_val))
	
	# Update history for persistence
	_point_history.push_front(points)
	if _point_history.size() > _history_max:
		_point_history.pop_back()
	
	# Draw trails (persistence)
	if persistence > 0:
		for i in range(_point_history.size() - 1, 0, -1):
			var alpha = (1.0 - float(i) / _history_max) * persistence
			var trail_color = Color(phosphor_color.r, phosphor_color.g, phosphor_color.b, alpha * 0.3)
			_draw_trace(_point_history[i], trail_color, line_width * 0.5)
	
	_draw_phosphor_trace(points)

func _draw_xy_plot() -> void:
	# Real-time XY plot - could be connected to external inputs
	# For now, shows phase relationship between two frequencies
	var center = _display_rect.size / 2.0
	var radius = min(_display_rect.size.x, _display_rect.size.y) * 0.4 * amplitude
	
	var points = PackedVector2Array()
	var num_points = 64
	
	for i in range(num_points):
		var t = _time + float(i) * 0.02
		var x_val = sin(t * (frequency_a / 100.0) + phase_offset) * radius
		var y_val = sin(t * (frequency_b / 100.0)) * radius
		points.append(center + Vector2(x_val, -y_val))
	
	# Draw dot trail
	for i in range(points.size()):
		var alpha = float(i) / points.size()
		var dot_color = Color(phosphor_color.r, phosphor_color.g, phosphor_color.b, alpha)
		var dot_size = 2.0 + alpha * 4.0
		draw_circle(points[i], dot_size, dot_color)

func _draw_phosphor_trace(points: PackedVector2Array) -> void:
	if points.size() < 2:
		return
	
	# Outer glow (multiple passes)
	for glow in range(4):
		var glow_width = line_width + (4 - glow) * 2.5 * glow_intensity
		var glow_alpha = 0.08 * (glow + 1) * glow_intensity
		var glow_color = Color(phosphor_color.r, phosphor_color.g, phosphor_color.b, glow_alpha)
		_draw_trace(points, glow_color, glow_width)
	
	# Main trace
	_draw_trace(points, phosphor_color, line_width)
	
	# Hot center
	var hot_color = Color(
		min(phosphor_color.r + 0.4, 1.0),
		min(phosphor_color.g + 0.3, 1.0),
		min(phosphor_color.b + 0.3, 1.0),
		1.0
	)
	_draw_trace(points, hot_color, line_width * 0.4)

func _draw_trace(points: PackedVector2Array, color: Color, width: float) -> void:
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], color, width, true)

func _draw_info() -> void:
	var font = get_theme_default_font()
	var info_color = Color(phosphor_color.r * 0.7, phosphor_color.g * 0.7, phosphor_color.b * 0.5, 0.9)
	
	# Mode indicator (top-left)
	var mode_text = ["WAVEFORM", "LISSAJOUS", "XY"][mode]
	draw_string(font, Vector2(8, 18), mode_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 14, info_color)
	
	# Frequency info
	match mode:
		Mode.WAVEFORM:
			var shape_names = ["SIN", "SQR", "SAW", "TRI"]
			draw_string(font, Vector2(8, 34), "%s %.1f Hz" % [shape_names[wave_shape], frequency_a], 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, info_color)
		Mode.LISSAJOUS:
			var ratio = frequency_b / frequency_a if frequency_a > 0 else 1.0
			draw_string(font, Vector2(8, 34), "A:%.0f B:%.0f (%.2f:1)" % [frequency_a, frequency_b, ratio],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 11, info_color)
		Mode.XY_PLOT:
			draw_string(font, Vector2(8, 34), "X:%.0f Y:%.0f Hz" % [frequency_a, frequency_b],
				HORIZONTAL_ALIGNMENT_LEFT, -1, 12, info_color)
	
	# Amplitude (top-right)
	var amp_text = "%.0f%%" % (amplitude * 100)
	var text_w = font.get_string_size(amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
	draw_string(font, Vector2(_display_rect.size.x - text_w - 8, 18), amp_text,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 12, info_color)
	
	# Phase (bottom-left)
	var phase_deg = rad_to_deg(phase_offset)
	draw_string(font, Vector2(8, _display_rect.size.y - 8), "φ %.1f°" % phase_deg,
		HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(info_color, 0.7))

func _draw_vignette() -> void:
	# Subtle CRT vignette effect
	var center = _display_rect.size / 2.0
	var max_dist = center.length()
	
	# Draw corner shadows
	var corner_size = 40.0
	var corners = [
		Vector2(0, 0),
		Vector2(_display_rect.size.x, 0),
		Vector2(0, _display_rect.size.y),
		_display_rect.size
	]
	
	for corner in corners:
		for i in range(10):
			var alpha = 0.03 * (10 - i)
			var rad = corner_size * (float(i) / 10.0)
			draw_circle(corner, rad, Color(0, 0, 0, alpha))

func _on_resized() -> void:
	_display_rect = Rect2(Vector2.ZERO, size)

# Public API

func set_mode(new_mode: Mode) -> void:
	mode = new_mode
	_point_history.clear()
	mode_changed.emit(new_mode)

func cycle_mode() -> void:
	set_mode((mode + 1) % Mode.size() as Mode)

func set_wave_shape(shape: WaveShape) -> void:
	wave_shape = shape

func cycle_wave_shape() -> void:
	wave_shape = ((wave_shape + 1) % WaveShape.size()) as WaveShape

func set_frequency_a(freq: float) -> void:
	frequency_a = clamp(freq, 1.0, 5000.0)
	frequency_changed.emit(frequency_a, frequency_b)

func set_frequency_b(freq: float) -> void:
	frequency_b = clamp(freq, 1.0, 5000.0)
	frequency_changed.emit(frequency_a, frequency_b)

func set_frequencies(freq_a: float, freq_b: float) -> void:
	frequency_a = clamp(freq_a, 1.0, 5000.0)
	frequency_b = clamp(freq_b, 1.0, 5000.0)
	frequency_changed.emit(frequency_a, frequency_b)

func set_amplitude_value(amp: float) -> void:
	amplitude = clamp(amp, 0.0, 1.0)

func set_phase(phase_rad: float) -> void:
	phase_offset = fmod(phase_rad, TAU)

func set_phosphor_style(style: String) -> void:
	match style:
		"green":
			phosphor_color = Color(0.2, 1.0, 0.4, 1.0)
		"amber":
			phosphor_color = Color(1.0, 0.7, 0.1, 1.0)
		"blue":
			phosphor_color = Color(0.3, 0.7, 1.0, 1.0)
		"white":
			phosphor_color = Color(0.9, 0.95, 1.0, 1.0)
