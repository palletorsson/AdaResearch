# AudioVisualizationComponent.gd
# Modular component for real-time audio visualization
# Supports master bus monitoring and waveform/spectrum display

extends Control
class_name AudioVisualizationComponent

@export_group("Audio Source")
@export var monitor_master_bus: bool = true
@export var target_audio_player: AudioStreamPlayer
@export var auto_update: bool = true

@export_group("Visualization Settings")
@export var waveform_enabled: bool = true
@export var spectrum_enabled: bool = true
@export var visualization_sample_count: int = 256
@export var spectrum_bands: int = 64
@export var update_fps: float = 30.0
@export var max_frequency_khz: float = 4.0  # Maximum frequency to display (kHz)
@export var max_amplitude: float = 0.6  # Maximum amplitude to display

@export_group("Visual Style")
@export var waveform_color: Color = Color.CYAN
@export var spectrum_color: Color = Color.GREEN
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.6)
@export var background_color: Color = Color(0.05, 0.05, 0.1, 1.0)

# Audio analysis components
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var master_bus_index: int = -1

# Visualization data
var current_waveform_data: PackedFloat32Array
var current_spectrum_data: PackedFloat32Array
var smoothed_spectrum_data: PackedFloat32Array

# UI components
var visualization_container: HBoxContainer
var waveform_display: Control
var spectrum_display: Control

# Performance tracking
var update_timer: float = 0.0
var update_interval: float
var is_initialized: bool = false

# Signals
signal audio_data_updated(waveform_data: PackedFloat32Array, spectrum_data: PackedFloat32Array)
signal visualization_ready()

func _ready():
	_initialize_visualization()
	_setup_audio_analysis()
	_create_visualization_ui()
	update_interval = 1.0 / update_fps
	is_initialized = true
	visualization_ready.emit()

func _initialize_visualization():
	"""Initialize visualization data arrays"""
	current_waveform_data.resize(visualization_sample_count)
	current_waveform_data.fill(0.0)
	current_spectrum_data.resize(spectrum_bands)
	current_spectrum_data.fill(0.0)
	smoothed_spectrum_data.resize(spectrum_bands)
	smoothed_spectrum_data.fill(0.0)

func _setup_audio_analysis():
	"""Setup spectrum analyzer for master bus or target audio player"""
	if monitor_master_bus:
		_setup_master_bus_monitoring()
	elif target_audio_player:
		_setup_player_monitoring()
	else:
		print("AudioVisualizationComponent: No audio source specified")

func _setup_master_bus_monitoring():
	"""Setup analysis of the master audio bus"""
	master_bus_index = AudioServer.get_bus_index("Master")
	
	# Check if spectrum analyzer already exists on master bus
	var existing_analyzer = null
	var effect_count = AudioServer.get_bus_effect_count(master_bus_index)
	
	for i in range(effect_count):
		var effect = AudioServer.get_bus_effect(master_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			existing_analyzer = effect
			spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, i) as AudioEffectSpectrumAnalyzerInstance
			print("AudioVisualizationComponent: Using existing spectrum analyzer on Master bus")
			return
	
	# Create new spectrum analyzer if none exists
	spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
	spectrum_analyzer.buffer_length = 2.0
	spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	spectrum_analyzer.tap_back_pos = 0.0
	
	AudioServer.add_bus_effect(master_bus_index, spectrum_analyzer)
	effect_count = AudioServer.get_bus_effect_count(master_bus_index)
	spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, effect_count - 1) as AudioEffectSpectrumAnalyzerInstance
	
	print("AudioVisualizationComponent: Created spectrum analyzer on Master bus - monitoring ALL game audio")

func _setup_player_monitoring():
	"""Setup analysis of specific audio player"""
	var bus_name = "AudioVisualization_Analysis"
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	# Create dedicated analysis bus
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		AudioServer.set_bus_send(bus_index, "Master")
	
	# Setup spectrum analyzer
	spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
	spectrum_analyzer.buffer_length = 1.0
	spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	spectrum_analyzer.tap_back_pos = 0.0
	
	AudioServer.add_bus_effect(bus_index, spectrum_analyzer)
	spectrum_instance = AudioServer.get_bus_effect_instance(bus_index, 0) as AudioEffectSpectrumAnalyzerInstance
	
	# Connect target audio player to analysis bus
	target_audio_player.bus = bus_name
	print("AudioVisualizationComponent: Monitoring specific audio player: %s" % target_audio_player.name)

func _create_visualization_ui():
	"""Create the visualization UI components"""
	# Main container
	visualization_container = HBoxContainer.new()
	visualization_container.add_theme_constant_override("separation", 15)
	visualization_container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	visualization_container.size_flags_vertical = Control.SIZE_EXPAND_FILL
	add_child(visualization_container)
	
	# Waveform display
	if waveform_enabled:
		waveform_display = _create_waveform_display()
		visualization_container.add_child(waveform_display)
	
	# Spectrum display
	if spectrum_enabled:
		spectrum_display = _create_spectrum_display()
		visualization_container.add_child(spectrum_display)

func _create_waveform_display() -> Control:
	"""Create the waveform (time domain) display"""
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 5)
	
	# Title
	var title = Label.new()
	title.text = "🌊 Waveform (Time Domain)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", waveform_color)
	container.add_child(title)
	
	# Waveform canvas
	var canvas = Control.new()
	canvas.name = "WaveformCanvas"
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(300, 150)
	
	# Style the canvas
	var canvas_bg = StyleBoxFlat.new()
	canvas_bg.bg_color = background_color
	canvas_bg.corner_radius_top_left = 5
	canvas_bg.corner_radius_top_right = 5
	canvas_bg.corner_radius_bottom_left = 5
	canvas_bg.corner_radius_bottom_right = 5
	canvas_bg.border_color = waveform_color
	canvas_bg.border_width_top = 1
	canvas_bg.border_width_bottom = 1
	canvas_bg.border_width_left = 1
	canvas_bg.border_width_right = 1
	canvas.add_theme_stylebox_override("panel", canvas_bg)
	
	container.add_child(canvas)
	
	# Connect drawing signal
	canvas.draw.connect(_draw_waveform.bind(canvas))
	
	return container

func _create_spectrum_display() -> Control:
	"""Create the spectrum (frequency domain) display"""
	var container = VBoxContainer.new()
	container.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	container.add_theme_constant_override("separation", 5)
	
	# Title
	var title = Label.new()
	title.text = "📡 Spectrum (Frequency Domain)"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 14)
	title.add_theme_color_override("font_color", spectrum_color)
	container.add_child(title)
	
	# Spectrum canvas
	var canvas = Control.new()
	canvas.name = "SpectrumCanvas"
	canvas.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	canvas.size_flags_vertical = Control.SIZE_EXPAND_FILL
	canvas.custom_minimum_size = Vector2(300, 150)
	
	# Style the canvas
	var canvas_bg = StyleBoxFlat.new()
	canvas_bg.bg_color = Color(background_color.r, background_color.g * 1.2, background_color.b, background_color.a)
	canvas_bg.corner_radius_top_left = 5
	canvas_bg.corner_radius_top_right = 5
	canvas_bg.corner_radius_bottom_left = 5
	canvas_bg.corner_radius_bottom_right = 5
	canvas_bg.border_color = spectrum_color
	canvas_bg.border_width_top = 1
	canvas_bg.border_width_bottom = 1
	canvas_bg.border_width_left = 1
	canvas_bg.border_width_right = 1
	canvas.add_theme_stylebox_override("panel", canvas_bg)
	
	container.add_child(canvas)
	
	# Connect drawing signal
	canvas.draw.connect(_draw_spectrum.bind(canvas))
	
	return container

func _process(delta: float):
	"""Update visualization data"""
	if not is_initialized or not spectrum_instance or not auto_update:
		return
	
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_visualization_data()
		_refresh_displays()

func _update_visualization_data():
	"""Update both waveform and spectrum data from audio analysis"""
	if not spectrum_instance:
		return
	
	# Update spectrum data
	_update_spectrum_data()
	
	# Generate synthetic waveform from spectrum (since we can't get raw PCM from master bus)
	_generate_waveform_from_spectrum()
	
	# Emit signal for external listeners
	audio_data_updated.emit(current_waveform_data, current_spectrum_data)

func _update_spectrum_data():
	"""Update spectrum data from FFT analysis"""
	if not spectrum_instance:
		return
	
	# Use configurable frequency range instead of full Nyquist
	var max_freq = max_frequency_khz * 1000.0  # Convert to Hz
	var freq_step = max_freq / spectrum_bands
	
	for i in range(spectrum_bands):
		var freq = i * freq_step
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq, 
			freq + freq_step, 
			AudioEffectSpectrumAnalyzerInstance.MAGNITUDE_AVERAGE
		)
		
		# Convert to linear and apply logarithmic scaling for better visualization
		var linear_magnitude = magnitude.length()
		var db_magnitude = linear_to_db(linear_magnitude + 0.0001)  # Avoid log(0)
		var normalized_magnitude = clamp((db_magnitude + 60.0) / 60.0, 0.0, 1.0)  # -60dB to 0dB range
		
		# Scale to max_amplitude instead of 1.0
		var scaled_magnitude = (normalized_magnitude / 1.0) * max_amplitude
		
		# Smooth the data
		smoothed_spectrum_data[i] = lerp(smoothed_spectrum_data[i], scaled_magnitude, 0.3)
		current_spectrum_data[i] = smoothed_spectrum_data[i]

func _generate_waveform_from_spectrum():
	"""Generate a synthetic waveform representation from spectrum data"""
	# This creates a representative waveform by combining the strongest frequencies
	current_waveform_data.fill(0.0)
	
	var sample_rate = 44100.0
	var duration = float(visualization_sample_count) / sample_rate
	
	# Find the strongest frequency components
	var max_components = 8  # Limit for performance
	var strong_frequencies = []
	
	for i in range(spectrum_bands):
		if current_spectrum_data[i] > 0.1:  # Only include significant frequencies
			var freq = (float(i) / spectrum_bands) * (max_frequency_khz * 1000.0)
			strong_frequencies.append({
				"frequency": freq,
				"amplitude": current_spectrum_data[i]
			})
	
	# Sort by amplitude and take the strongest
	strong_frequencies.sort_custom(func(a, b): return a.amplitude > b.amplitude)
	strong_frequencies = strong_frequencies.slice(0, max_components)
	
	# Generate waveform from strongest frequencies
	for i in range(visualization_sample_count):
		var t = float(i) / sample_rate
		var sample_value = 0.0
		
		for freq_data in strong_frequencies:
			var freq = freq_data.frequency
			var amp = freq_data.amplitude
			sample_value += amp * sin(2.0 * PI * freq * t)
		
		# Normalize
		current_waveform_data[i] = clamp(sample_value * 0.3, -1.0, 1.0)

func _refresh_displays():
	"""Trigger redraw of visualization displays"""
	if waveform_display:
		var canvas = waveform_display.get_node("WaveformCanvas")
		if canvas:
			canvas.queue_redraw()
	
	if spectrum_display:
		var canvas = spectrum_display.get_node("SpectrumCanvas")
		if canvas:
			canvas.queue_redraw()

func _draw_waveform(canvas: Control):
	"""Draw the time domain waveform"""
	var rect = Rect2(Vector2.ZERO, canvas.size)
	var center_y = rect.size.y * 0.5
	var padding = 20.0
	
	# Draw grid
	_draw_waveform_grid(canvas, rect, padding)
	
	# Draw waveform if we have data
	if current_waveform_data.size() > 1:
		var points: PackedVector2Array = []
		
		for i in range(current_waveform_data.size()):
			var x = padding + (float(i) / float(current_waveform_data.size() - 1)) * (rect.size.x - padding * 2)
			var amplitude = current_waveform_data[i]
			var y = center_y - amplitude * (center_y - padding)
			points.append(Vector2(x, y))
		
		# Draw waveform with glow effect
		var line_width = 2.0
		
		# Glow passes
		for glow in range(2):
			var glow_width = line_width + glow * 2
			var glow_alpha = 0.3 - glow * 0.1
			var glow_color = Color(waveform_color.r, waveform_color.g, waveform_color.b, glow_alpha)
			
			for i in range(points.size() - 1):
				canvas.draw_line(points[i], points[i + 1], glow_color, glow_width)
		
		# Main line
		for i in range(points.size() - 1):
			canvas.draw_line(points[i], points[i + 1], waveform_color, line_width)

func _draw_spectrum(canvas: Control):
	"""Draw the frequency domain spectrum"""
	var rect = Rect2(Vector2.ZERO, canvas.size)
	var padding = 20.0
	
	# Draw grid
	_draw_spectrum_grid(canvas, rect, padding)
	
	# Draw spectrum if we have data
	if current_spectrum_data.size() > 0:
		var bar_width = (rect.size.x - padding * 2) / float(current_spectrum_data.size())
		
		# Draw spectrum bars with glow effect
		for i in range(current_spectrum_data.size()):
			var x = padding + i * bar_width
			var amplitude = current_spectrum_data[i]
			var height = amplitude * (rect.size.y - padding * 2)
			var y = rect.size.y - padding - height
			
			var bar_rect = Rect2(x, y, bar_width * 0.8, height)
			
			# Glow effect
			var glow_rect = Rect2(x - 1, y - 1, bar_width * 0.8 + 2, height + 2)
			var glow_color = Color(spectrum_color.r, spectrum_color.g, spectrum_color.b, 0.3)
			canvas.draw_rect(glow_rect, glow_color)
			
			# Main bar
			canvas.draw_rect(bar_rect, spectrum_color)

func _draw_waveform_grid(canvas: Control, rect: Rect2, padding: float):
	"""Draw grid for waveform display"""
	var center_y = rect.size.y * 0.5
	
	# Horizontal lines (amplitude)
	for i in range(3):
		var offset = (float(i + 1) / 4.0) * (center_y - padding)
		
		# Positive amplitude
		var y_pos = center_y - offset
		canvas.draw_line(Vector2(padding, y_pos), Vector2(rect.size.x - padding, y_pos), grid_color)
		
		# Negative amplitude
		var y_neg = center_y + offset
		canvas.draw_line(Vector2(padding, y_neg), Vector2(rect.size.x - padding, y_neg), grid_color)
	
	# Center line
	canvas.draw_line(Vector2(padding, center_y), Vector2(rect.size.x - padding, center_y), 
		Color(grid_color.r * 1.5, grid_color.g * 1.5, grid_color.b * 1.5, grid_color.a), 2.0)
	
	# Vertical lines (time)
	for i in range(5):
		var x = padding + (float(i) / 4.0) * (rect.size.x - padding * 2)
		canvas.draw_line(Vector2(x, padding), Vector2(x, rect.size.y - padding), grid_color)

func _draw_spectrum_grid(canvas: Control, rect: Rect2, padding: float):
	"""Draw grid for spectrum display with scale labels"""
	
	# Horizontal lines (amplitude) with labels
	for i in range(4):
		var y = padding + (float(i + 1) / 5.0) * (rect.size.y - padding * 2)
		canvas.draw_line(Vector2(padding, y), Vector2(rect.size.x - padding, y), grid_color)
		
		# Amplitude labels
		var amplitude_value = max_amplitude * (1.0 - float(i + 1) / 5.0)
		var amp_text = "%.1f" % amplitude_value
		var font = ThemeDB.fallback_font
		var font_size = 10
		var text_size = font.get_string_size(amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		canvas.draw_string(font, Vector2(5, y + text_size.y * 0.5), amp_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)
	
	# Vertical lines (frequency) with labels
	for i in range(5):
		var x = padding + (float(i) / 4.0) * (rect.size.x - padding * 2)
		canvas.draw_line(Vector2(x, padding), Vector2(x, rect.size.y - padding), grid_color)
		
		# Frequency labels
		var freq_khz = (float(i) / 4.0) * max_frequency_khz
		var freq_text = "%.1f kHz" % freq_khz
		var font = ThemeDB.fallback_font
		var font_size = 10
		var text_size = font.get_string_size(freq_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size)
		canvas.draw_string(font, Vector2(x - text_size.x * 0.5, rect.size.y - 5), freq_text, HORIZONTAL_ALIGNMENT_LEFT, -1, font_size, Color.WHITE)

# Public API
func set_monitor_master_bus(enabled: bool):
	"""Switch between master bus and player monitoring"""
	if enabled != monitor_master_bus:
		monitor_master_bus = enabled
		_setup_audio_analysis()

func set_target_audio_player(player: AudioStreamPlayer):
	"""Change the target audio player"""
	target_audio_player = player
	if not monitor_master_bus:
		_setup_audio_analysis()

func get_current_spectrum_data() -> PackedFloat32Array:
	"""Get the current spectrum data"""
	return current_spectrum_data.duplicate()

func get_current_waveform_data() -> PackedFloat32Array:
	"""Get the current waveform data"""
	return current_waveform_data.duplicate()

func set_update_rate(fps: float):
	"""Change the visualization update rate"""
	update_fps = clamp(fps, 1.0, 60.0)
	update_interval = 1.0 / update_fps

func enable_waveform(enabled: bool):
	"""Enable/disable waveform display"""
	waveform_enabled = enabled
	if waveform_display:
		waveform_display.visible = enabled

func enable_spectrum(enabled: bool):
	"""Enable/disable spectrum display"""
	spectrum_enabled = enabled
	if spectrum_display:
		spectrum_display.visible = enabled 