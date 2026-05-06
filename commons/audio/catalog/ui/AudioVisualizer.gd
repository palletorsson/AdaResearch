# AudioVisualizer.gd
# Real-time audio visualization - oscilloscope and spectrum analyzer
# Can be used standalone or embedded in other UI

extends Control
class_name AudioVisualizer

enum Mode { SPECTRUM, OSCILLOSCOPE, BOTH }

@export var mode: Mode = Mode.BOTH
@export var spectrum_color: Color = Color(0.3, 0.7, 0.9)
@export var oscilloscope_color: Color = Color(0.9, 0.5, 0.3)
@export var background_color: Color = Color(0.02, 0.02, 0.03)
@export var grid_color: Color = Color(0.1, 0.1, 0.12)
@export var bar_count: int = 64
@export var smoothing: float = 0.8
@export var sensitivity: float = 1.0

var _spectrum: AudioEffectSpectrumAnalyzerInstance
var _prev_magnitudes: PackedFloat32Array
var _bus_name: String = "Master"

func _ready():
	_prev_magnitudes.resize(bar_count)
	_setup_spectrum_analyzer()
	custom_minimum_size = Vector2(200, 80)


func _setup_spectrum_analyzer():
	var bus_idx = AudioServer.get_bus_index(_bus_name)
	if bus_idx < 0:
		push_warning("AudioVisualizer: Bus '%s' not found" % _bus_name)
		return
	
	# Check if analyzer already exists
	for i in range(AudioServer.get_bus_effect_count(bus_idx)):
		var effect = AudioServer.get_bus_effect(bus_idx, i)
		if effect is AudioEffectSpectrumAnalyzer:
			_spectrum = AudioServer.get_bus_effect_instance(bus_idx, i)
			return
	
	# Add new analyzer
	var analyzer = AudioEffectSpectrumAnalyzer.new()
	analyzer.buffer_length = 0.05
	analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	AudioServer.add_bus_effect(bus_idx, analyzer)
	_spectrum = AudioServer.get_bus_effect_instance(bus_idx, AudioServer.get_bus_effect_count(bus_idx) - 1)


func set_bus(bus_name: String):
	_bus_name = bus_name
	_setup_spectrum_analyzer()


func _process(_delta):
	queue_redraw()


func _draw():
	var rect = get_rect()
	var w = rect.size.x
	var h = rect.size.y
	
	# Background
	draw_rect(Rect2(0, 0, w, h), background_color)
	
	# Grid lines
	_draw_grid(w, h)
	
	if _spectrum == null:
		_draw_no_signal(w, h)
		return
	
	match mode:
		Mode.SPECTRUM:
			_draw_spectrum(w, h)
		Mode.OSCILLOSCOPE:
			_draw_oscilloscope(w, h)
		Mode.BOTH:
			_draw_spectrum(w, h * 0.6)
			_draw_oscilloscope_at(w, h * 0.6, h * 0.4)


func _draw_grid(w: float, h: float):
	# Vertical lines
	var v_lines = 8
	for i in range(1, v_lines):
		var x = (i / float(v_lines)) * w
		draw_line(Vector2(x, 0), Vector2(x, h), grid_color, 1.0)
	
	# Horizontal center line
	draw_line(Vector2(0, h / 2), Vector2(w, h / 2), grid_color, 1.0)
	
	# Horizontal quarter lines
	draw_line(Vector2(0, h / 4), Vector2(w, h / 4), grid_color.darkened(0.3), 1.0)
	draw_line(Vector2(0, h * 3 / 4), Vector2(w, h * 3 / 4), grid_color.darkened(0.3), 1.0)


func _draw_no_signal(w: float, h: float):
	draw_string(
		ThemeDB.fallback_font,
		Vector2(w / 2 - 40, h / 2 + 5),
		"No Signal",
		HORIZONTAL_ALIGNMENT_CENTER,
		-1, 14,
		Color(0.4, 0.4, 0.45)
	)


func _draw_spectrum(w: float, h: float):
	var bar_width = w / float(bar_count)
	
	for i in range(bar_count):
		# Logarithmic frequency mapping
		var freq_low = 20.0 * pow(2.0, i * 10.0 / bar_count)
		var freq_high = 20.0 * pow(2.0, (i + 1) * 10.0 / bar_count)
		
		var magnitude = _spectrum.get_magnitude_for_frequency_range(freq_low, freq_high)
		var mag_linear = magnitude.length() * sensitivity
		var mag_db = linear_to_db(mag_linear)
		var normalized = clamp((mag_db + 60.0) / 60.0, 0.0, 1.0)
		
		# Smoothing
		_prev_magnitudes[i] = lerp(_prev_magnitudes[i], normalized, 1.0 - smoothing)
		normalized = _prev_magnitudes[i]
		
		var bar_height = normalized * h
		var bar_x = i * bar_width
		
		# Color based on frequency and amplitude
		var hue = 0.55 - normalized * 0.25  # Blue to cyan to green
		var color = Color.from_hsv(hue, 0.7, 0.4 + normalized * 0.6)
		
		draw_rect(Rect2(bar_x, h - bar_height, bar_width - 1, bar_height), color)
		
		# Peak indicator
		if normalized > 0.8:
			draw_rect(Rect2(bar_x, h - bar_height - 3, bar_width - 1, 2), Color.WHITE)


func _draw_oscilloscope(w: float, h: float):
	_draw_oscilloscope_at(w, 0, h)


func _draw_oscilloscope_at(w: float, y_offset: float, h: float):
	var mid_y = y_offset + h / 2.0
	
	# Sample visualization using spectrum phase data
	# This is an approximation - true oscilloscope would need audio buffer access
	var points = PackedVector2Array()
	var sample_count = int(w / 2)
	
	for i in range(sample_count):
		var freq = 100.0 + i * 50.0
		var mag = _spectrum.get_magnitude_for_frequency_range(freq, freq + 50.0)
		var amplitude = mag.length() * sensitivity * 2.0
		
		# Create waveform approximation
		var phase = float(i) / sample_count * TAU * 4.0 + Time.get_ticks_msec() * 0.01
		var y = mid_y + sin(phase) * amplitude * h * 0.4
		y = clamp(y, y_offset, y_offset + h)
		
		points.append(Vector2(i * 2, y))
	
	if points.size() > 1:
		draw_polyline(points, oscilloscope_color, 2.0, true)
	
	# Draw zero line
	draw_line(Vector2(0, mid_y), Vector2(w, mid_y), oscilloscope_color.darkened(0.5), 1.0)


# Get current peak level (0.0 - 1.0)
func get_peak_level() -> float:
	if _spectrum == null:
		return 0.0
	
	var mag = _spectrum.get_magnitude_for_frequency_range(20.0, 20000.0)
	var db = linear_to_db(mag.length())
	return clamp((db + 60.0) / 60.0, 0.0, 1.0)


# Get magnitude for a specific frequency band
func get_band_magnitude(low_freq: float, high_freq: float) -> float:
	if _spectrum == null:
		return 0.0
	
	var mag = _spectrum.get_magnitude_for_frequency_range(low_freq, high_freq)
	var db = linear_to_db(mag.length())
	return clamp((db + 60.0) / 60.0, 0.0, 1.0)
