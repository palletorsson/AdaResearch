# WaveformDisplay.gd - Sine wave visualization from spectral values over time
# Creates a sine wave where the amplitude is modulated by frequency spectrum data
extends Control
class_name WaveformDisplay

@export var line_color: Color = Color(0, 1, 1, 1)  # Cyan for waveform
@export var background_color: Color = Color(0, 0, 0, 0.8)
@export var line_width: float = 3.0
@export var sample_count: int = 256  # Number of waveform samples
@export var amplitude_scale: float = 100.0
@export var time_scale: float = 2.0  # Speed of waveform scrolling

# Audio analysis
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var waveform_data: PackedFloat32Array
var time_offset: float = 0.0

# Display properties
var display_rect: Rect2
var is_initialized: bool = false

func _ready():
	_initialize_waveform()
	_setup_audio_connection()
	resized.connect(_on_resized)
	print("WaveformDisplay: Initialized with %d samples" % sample_count)
	print("WaveformDisplay: Control size: ", size)
	print("WaveformDisplay: Parent viewport: ", get_parent().name if get_parent() else "No parent")

func _initialize_waveform():
	"""Initialize waveform data arrays"""
	waveform_data.resize(sample_count)
	waveform_data.fill(0.0)
	display_rect = Rect2(Vector2.ZERO, size)
	is_initialized = true

func _setup_audio_connection():
	"""Connect to the same audio analysis as the spectrum analyzer"""
	# Try to get the spectrum analyzer from the master bus
	var master_bus_index = AudioServer.get_bus_index("Master")
	var effect_count = AudioServer.get_bus_effect_count(master_bus_index)
	
	# Look for existing spectrum analyzer
	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(master_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_analyzer = effect
			spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, i) as AudioEffectSpectrumAnalyzerInstance
			print("WaveformDisplay: Connected to existing spectrum analyzer")
			return
	
	print("WaveformDisplay: No spectrum analyzer found on master bus")

func _process(delta: float):
	"""Update waveform data and redraw"""
	if not is_initialized:
		return
	
	time_offset += delta * time_scale
	_update_waveform_data()
	queue_redraw()

func _update_waveform_data():
	"""Generate sine wave from spectral values over time"""
	if not spectrum_instance:
		# Generate test sine wave if no audio
		_generate_test_waveform()
		return
	
	# Create sine wave from spectral magnitude values
	for i in range(sample_count):
		# Get time position across the display
		var time_position = float(i) / float(sample_count - 1)
		
		# Calculate which frequency to sample based on position + time offset
		var freq_index = int((time_position + time_offset * 0.5) * 64.0) % 64  # Cycle through 64 frequency bands
		var freq_hz = (float(freq_index) / 64.0) * 8000.0  # Map to 0-8kHz range
		
		# Get the magnitude for this frequency band
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq_hz, freq_hz + 125.0  # 125Hz bands (8000/64)
		).length()
		
		# Convert magnitude to decibels and normalize
		var db = 20.0 * log(magnitude) / log(10.0) if magnitude > 0.0001 else -100.0
		var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)  # Map -60dB to 0dB range
		
		# Create sine wave from the spectral values
		var sine_phase = time_position * PI * 4.0  # 2 cycles across display
		waveform_data[i] = sin(sine_phase + time_offset) * normalized * amplitude_scale

func _generate_test_waveform():
	"""Generate test sine wave modulated by fake spectral values"""
	for i in range(sample_count):
		var time_position = float(i) / float(sample_count - 1)
		
		# Create fake spectral data that varies over time
		var fake_freq_index = int((time_position + time_offset * 0.3) * 32.0) % 32
		var fake_magnitude = (sin(time_offset * 2.0 + fake_freq_index * 0.2) + 1.0) * 0.5
		
		# Create sine wave modulated by fake spectral values
		var sine_phase = time_position * PI * 4.0  # 2 cycles across display
		waveform_data[i] = sin(sine_phase + time_offset) * fake_magnitude * amplitude_scale * 0.6

func _draw():
	"""Draw the waveform"""
	if not is_initialized:
		return
	
	# Draw background
	if background_color.a > 0.0:
		draw_rect(display_rect, background_color)
	
	# Draw center line
	var center_y = display_rect.position.y + display_rect.size.y * 0.5
	draw_line(
		Vector2(display_rect.position.x, center_y),
		Vector2(display_rect.position.x + display_rect.size.x, center_y),
		Color(0.3, 0.3, 0.3, 0.8), 1.0
	)
	
	# Draw waveform
	_draw_waveform_line()
	
	# Draw grid lines
	_draw_grid()
	
	# Draw title and time scale info
	_draw_time_scale_info()

func _draw_waveform_line():
	"""Draw the main waveform line"""
	if waveform_data.size() < 2:
		return
	
	var points: PackedVector2Array = []
	var center_y = display_rect.position.y + display_rect.size.y * 0.5
	
	# Generate waveform points
	for i in range(sample_count):
		var x = display_rect.position.x + (float(i) / float(sample_count - 1)) * display_rect.size.x
		var y = center_y - waveform_data[i]
		
		# Clamp to display area
		y = clamp(y, display_rect.position.y + 5, display_rect.position.y + display_rect.size.y - 5)
		points.append(Vector2(x, y))
	
	# Draw glow effect
	for glow_pass in range(2):
		var glow_width = line_width + (glow_pass * 2)
		var glow_alpha = 0.4 - (glow_pass * 0.2)
		var glow_color = Color(line_color.r, line_color.g, line_color.b, glow_alpha)
		
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], glow_color, glow_width)
	
	# Draw main waveform line
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, line_width)

func _draw_grid():
	"""Draw amplitude grid lines and time scale labels"""
	var grid_color = Color(0.2, 0.4, 0.4, 0.5)
	var text_color = Color(0.8, 1.0, 1.0, 0.9)
	var center_y = display_rect.position.y + display_rect.size.y * 0.5
	
	# Horizontal grid lines (amplitude levels)
	for i in range(3):
		var offset = (float(i + 1) / 4.0) * display_rect.size.y * 0.4
		var amplitude_value = (float(i + 1) / 4.0)
		
		# Positive amplitude
		var y_pos = center_y - offset
		draw_line(
			Vector2(display_rect.position.x, y_pos),
			Vector2(display_rect.position.x + display_rect.size.x, y_pos),
			grid_color, 1.0
		)
		
		# Amplitude labels (positive)
		var amp_text = "+%.1f" % amplitude_value
		draw_string(get_theme_default_font(), Vector2(display_rect.position.x + 5, y_pos - 2), 
					amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_color)
		
		# Negative amplitude
		var y_neg = center_y + offset
		draw_line(
			Vector2(display_rect.position.x, y_neg),
			Vector2(display_rect.position.x + display_rect.size.x, y_neg),
			grid_color, 1.0
		)
		
		# Amplitude labels (negative)
		var neg_text = "-%.1f" % amplitude_value
		draw_string(get_theme_default_font(), Vector2(display_rect.position.x + 5, y_neg + 12), 
					neg_text, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, text_color)
	
	# Vertical grid lines (time divisions) with time scale labels
	var time_span = 2.0  # 2 seconds across the display
	for i in range(6):
		var x = display_rect.position.x + (float(i) / 5.0) * display_rect.size.x
		
		# Draw vertical grid line
		draw_line(
			Vector2(x, display_rect.position.y),
			Vector2(x, display_rect.position.y + display_rect.size.y),
			grid_color, 1.0
		)
		
		# Calculate time value at this position
		var time_value = (time_offset + (float(i) / 5.0) * time_span) * time_scale
		var time_text = "%.1fs" % fmod(time_value, 10.0)  # Show time modulo 10 seconds
		
		# Draw time scale label at bottom
		var text_pos = Vector2(x - 15, display_rect.position.y + display_rect.size.y - 5)
		draw_string(get_theme_default_font(), text_pos, time_text, 
					HORIZONTAL_ALIGNMENT_CENTER, -1, 12, text_color)

func _on_resized():
	"""Handle control resize"""
	display_rect = Rect2(Vector2.ZERO, size)

# Public API
func set_time_scale(scale: float):
	"""Set the speed of waveform scrolling"""
	time_scale = scale

func set_amplitude_scale(scale: float):
	"""Set the amplitude scaling"""
	amplitude_scale = scale

func _draw_time_scale_info():
	"""Draw time scale information and title"""
	var info_color = Color(0.9, 1.0, 1.0, 1.0)
	var title_color = Color(0, 1, 1, 1)
	
	# Title
	var title_text = "TIME DOMAIN WAVEFORM"
	var title_pos = Vector2(display_rect.size.x * 0.5 - 80, display_rect.position.y + 15)
	draw_string(get_theme_default_font(), title_pos, title_text, 
				HORIZONTAL_ALIGNMENT_CENTER, -1, 14, title_color)
	
	# Time scale info
	var scale_text = "Scale: %.1fx | Span: 2.0s" % time_scale
	var scale_pos = Vector2(display_rect.position.x + 5, display_rect.position.y + 35)
	draw_string(get_theme_default_font(), scale_pos, scale_text, 
				HORIZONTAL_ALIGNMENT_LEFT, -1, 10, info_color)
	
	# Current time
	var current_time_text = "Time: %.1fs" % (time_offset * time_scale)
	var time_pos = Vector2(display_rect.position.x + display_rect.size.x - 60, display_rect.position.y + 35)
	draw_string(get_theme_default_font(), time_pos, current_time_text, 
				HORIZONTAL_ALIGNMENT_RIGHT, -1, 10, info_color) 
