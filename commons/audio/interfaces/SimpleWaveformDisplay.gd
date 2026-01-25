# SimpleWaveformDisplay.gd - Oscilloscope-style sine wave display
# Shows a clean sine wave that animates when audio is playing
extends Control
class_name SimpleWaveformDisplay

@export var line_color: Color = Color(0.2, 1.0, 0.3, 1.0)  # Green like classic oscilloscope
@export var background_color: Color = Color(0.02, 0.05, 0.02, 1.0)  # Dark green tint
@export var grid_color: Color = Color(0.1, 0.2, 0.1, 0.6)
@export var line_width: float = 2.5
@export var source_bus: String = "Master"
@export var num_cycles: float = 4.0  # Number of sine wave cycles to show

# Audio detection
var audio_bus_index: int = -1
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var _audio_setup_done: bool = false

# Animation
var phase_offset: float = 0.0
var current_amplitude: float = 0.0
var target_amplitude: float = 0.0
const SAMPLE_COUNT: int = 256
var display_rect: Rect2

# Direct parameter control (set by controller)
var _direct_frequency: float = 0.0  # If > 0, use this instead of detecting
var _direct_amplitude: float = -1.0  # If >= 0, use this instead of detecting

func _ready():
	display_rect = Rect2(Vector2.ZERO, size)
	resized.connect(_on_resized)

	# Defer audio setup
	await get_tree().process_frame
	await get_tree().process_frame
	if not _audio_setup_done:
		_setup_audio()

func _setup_audio():
	audio_bus_index = AudioServer.get_bus_index(source_bus)

	if audio_bus_index == -1:
		print("SimpleWaveformDisplay: Bus '%s' not found, using Master" % source_bus)
		audio_bus_index = AudioServer.get_bus_index("Master")

	print("SimpleWaveformDisplay: Monitoring bus '%s' (index %d)" % [source_bus, audio_bus_index])

	# Find or create spectrum analyzer
	for i in range(AudioServer.get_bus_effect_count(audio_bus_index)):
		var effect = AudioServer.get_bus_effect(audio_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_instance = AudioServer.get_bus_effect_instance(audio_bus_index, i)
			return

	# Create new analyzer
	spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
	spectrum_analyzer.buffer_length = 0.1
	spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_512
	AudioServer.add_bus_effect(audio_bus_index, spectrum_analyzer)

	var effect_idx = AudioServer.get_bus_effect_count(audio_bus_index) - 1
	spectrum_instance = AudioServer.get_bus_effect_instance(audio_bus_index, effect_idx)

func set_source_bus(bus_name: String):
	source_bus = bus_name
	_audio_setup_done = true
	_setup_audio()

func set_frequency(freq: float):
	"""Set displayed frequency directly (affects wave cycles shown)"""
	_direct_frequency = freq
	# Linear scale with wide range for clear visual difference
	# 20Hz → 1 cycle (one full wave), 2000Hz → 20 cycles (compressed waves)
	if freq > 0:
		num_cycles = clamp(freq / 100.0, 0.5, 20.0)
	else:
		num_cycles = 2.0

func set_amplitude(amp: float):
	"""Set displayed amplitude directly (0-1)"""
	_direct_amplitude = clamp(amp, 0.0, 1.0)

func _process(delta: float):
	# Use direct amplitude if set, otherwise detect from audio
	if _direct_amplitude >= 0.0:
		target_amplitude = _direct_amplitude
	elif spectrum_instance:
		# Sample across wider frequency range to detect audio (up to 8000Hz)
		var total_magnitude = 0.0
		for freq in [100.0, 200.0, 400.0, 800.0, 1200.0, 1600.0, 2000.0, 3000.0, 4000.0, 6000.0, 8000.0]:
			var mag = spectrum_instance.get_magnitude_for_frequency_range(freq * 0.9, freq * 1.1)
			total_magnitude += mag.length()
		target_amplitude = clamp(total_magnitude * 15.0, 0.0, 1.0)
	else:
		target_amplitude = 0.0

	# Smooth amplitude changes
	current_amplitude = lerp(current_amplitude, target_amplitude, delta * 10.0)

	# Animate phase when audio is playing (or direct amplitude > 0)
	if current_amplitude > 0.05:
		# Scroll speed based on frequency if set
		var scroll_speed = 2.0
		if _direct_frequency > 0:
			scroll_speed = clamp(_direct_frequency / 200.0, 1.0, 8.0)
		phase_offset += delta * TAU * scroll_speed

	queue_redraw()

func _draw():
	# Background
	draw_rect(display_rect, background_color)

	# Draw grid
	_draw_grid()

	# Draw sine wave
	_draw_sine_wave()

	# Info display in corners
	var info_color = Color(0.5, 0.8, 0.5, 0.7)
	var font = get_theme_default_font()

	# Frequency display (top-left)
	if _direct_frequency > 0:
		var freq_text = "%.0f Hz" % _direct_frequency
		draw_string(font, Vector2(8, 16), freq_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, info_color)

	# Amplitude display (top-right)
	if _direct_amplitude >= 0:
		var amp_text = "%.0f%%" % (_direct_amplitude * 100)
		var text_width = font.get_string_size(amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(font, Vector2(display_rect.size.x - text_width - 8, 16), amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, info_color)

	# Cycles display (bottom-left)
	var cycles_text = "%.1f cycles" % num_cycles
	draw_string(font, Vector2(8, display_rect.size.y - 6), cycles_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 10, Color(0.4, 0.6, 0.4, 0.5))

func _draw_grid():
	var w = display_rect.size.x
	var h = display_rect.size.y
	var center_y = h * 0.5

	# Horizontal grid lines
	var h_divisions = 8
	for i in range(h_divisions + 1):
		var y = (float(i) / h_divisions) * h
		var alpha = 0.8 if i == h_divisions / 2 else 0.4  # Center line brighter
		draw_line(Vector2(0, y), Vector2(w, y), Color(grid_color, alpha), 1.0)

	# Vertical grid lines
	var v_divisions = 10
	for i in range(v_divisions + 1):
		var x = (float(i) / v_divisions) * w
		draw_line(Vector2(x, 0), Vector2(x, h), grid_color, 1.0)

	# Small tick marks on center line
	var tick_count = 50
	for i in range(tick_count + 1):
		var x = (float(i) / tick_count) * w
		var tick_size = 3.0 if i % 5 == 0 else 1.5
		draw_line(Vector2(x, center_y - tick_size), Vector2(x, center_y + tick_size), Color(grid_color, 0.8), 1.0)

func _draw_sine_wave():
	var w = display_rect.size.x
	var h = display_rect.size.y
	var center_y = h * 0.5
	# Use current amplitude, with minimum visibility when there's signal
	var amp_factor = current_amplitude if current_amplitude > 0.02 else 0.02
	var amplitude = h * 0.4 * amp_factor  # Max 40% of height each direction

	var points: PackedVector2Array = []

	for i in range(SAMPLE_COUNT):
		var t = float(i) / (SAMPLE_COUNT - 1)
		var x = t * w

		# Calculate sine value with phase offset for animation
		var sine_value = sin(t * TAU * num_cycles + phase_offset)
		var y = center_y - sine_value * amplitude

		points.append(Vector2(x, y))

	# Draw glow effect (multiple passes with decreasing alpha)
	for glow in range(3):
		var glow_width = line_width + (3 - glow) * 2
		var glow_alpha = 0.15 * (glow + 1)
		var glow_color = Color(line_color.r, line_color.g, line_color.b, glow_alpha)
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], glow_color, glow_width)

	# Draw main sine wave
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, line_width)

	# Draw bright center of line
	var bright_color = Color(line_color.r + 0.3, line_color.g + 0.2, line_color.b + 0.2, 1.0).clamp()
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], bright_color, line_width * 0.5)

func _on_resized():
	display_rect = Rect2(Vector2.ZERO, size)
