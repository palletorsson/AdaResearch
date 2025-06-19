# GameSoundMeter.gd - Universal sound meter system for game objects
extends Control
class_name GameSoundMeter

# Core configuration
@export_group("Audio Source")
@export var auto_find_teleport_audio: bool = true
@export var target_audio_player: AudioStreamPlayer3D
@export var monitor_master_bus: bool = false

@export_group("Visual Settings")
@export var display_style: DisplayStyle = DisplayStyle.SPECTRUM_LINE
@export var bar_count: int = 32
@export var line_color: Color = Color(0, 1, 0, 1)
@export var background_color: Color = Color(0, 0, 0, 0.8)
@export var line_width: float = 2.0
@export var height_multiplier: float = 150.0

@export_group("Performance")
@export var update_fps: float = 30.0
@export var enable_distance_culling: bool = true
@export var max_display_distance: float = 50.0
@export var smoothing_factor: float = 0.8

@export_group("UI Integration")
@export var overlay_mode: bool = true  # Show as UI overlay
@export var world_space_mode: bool = false  # Show in 3D world
@export var auto_size_to_parent: bool = true

enum DisplayStyle {
	SPECTRUM_LINE,      # Green line spectrum
	SPECTRUM_BARS,      # Individual bars
	WAVEFORM,          # Time-domain waveform
	VU_METER,          # Simple level meter
	OSCILLOSCOPE       # Detailed waveform
}

# Internal components
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var frequency_data: PackedFloat32Array
var smoothed_data: PackedFloat32Array
var peak_levels: PackedFloat32Array

# Performance tracking
var update_timer: float = 0.0
var update_interval: float
var frame_skip_counter: int = 0
var player_camera: Camera3D
var teleport_cube_node: Node3D

# Cached calculations
var bar_width: float
var meter_rect: Rect2
var is_initialized: bool = false

func _ready():
	_initialize_meter()
	_setup_audio_analysis()
	_find_game_objects()
	
	if auto_size_to_parent and get_parent():
		_setup_auto_sizing()
	
	print("GameSoundMeter: Initialized - Style: %s, Bars: %d, FPS: %.1f" % [
		DisplayStyle.keys()[display_style], bar_count, update_fps
	])

func _initialize_meter():
	"""Initialize the meter arrays and settings"""
	frequency_data.resize(bar_count)
	smoothed_data.resize(bar_count)
	peak_levels.resize(bar_count)
	
	frequency_data.fill(0.0)
	smoothed_data.fill(0.0)
	peak_levels.fill(0.0)
	
	update_interval = 1.0 / update_fps
	_update_cached_values()
	
	# Connect signals
	resized.connect(_on_resized)
	is_initialized = true

func _setup_audio_analysis():
	"""Setup spectrum analyzer for the target audio source"""
	if monitor_master_bus:
		# Monitor the master bus directly
		var master_bus_index = AudioServer.get_bus_index("Master")
		
		# Setup spectrum analyzer
		spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
		spectrum_analyzer.buffer_length = 2.0  # Longer buffer for better analysis
		spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
		spectrum_analyzer.tap_back_pos = 0.0
		
		# Add analyzer to master bus
		AudioServer.add_bus_effect(master_bus_index, spectrum_analyzer)
		var effect_count = AudioServer.get_bus_effect_count(master_bus_index)
		spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, effect_count - 1) as AudioEffectSpectrumAnalyzerInstance
		
		print("GameSoundMeter: Monitoring Master Bus - analyzing ALL game audio")
	else:
		# Use dedicated analysis bus for specific audio sources
		var bus_name = "GameSoundMeter_Analysis"
		var bus_index = AudioServer.get_bus_index(bus_name)
		
		# Create dedicated analysis bus
		if bus_index == -1:
			AudioServer.add_bus()
			bus_index = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_index, bus_name)
			
			# Route to master for audio output
			AudioServer.set_bus_send(bus_index, "Master")
		
		# Setup spectrum analyzer
		spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
		spectrum_analyzer.buffer_length = 1.0  # Balance between accuracy and performance
		spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		spectrum_analyzer.tap_back_pos = 0.0
		
		AudioServer.add_bus_effect(bus_index, spectrum_analyzer)
		spectrum_instance = AudioServer.get_bus_effect_instance(bus_index, 0) as AudioEffectSpectrumAnalyzerInstance
		
		# Connect target audio player to analysis bus
		if target_audio_player:
			target_audio_player.bus = bus_name
			print("GameSoundMeter: Connected audio player to analysis bus")

func _find_game_objects():
	"""Auto-find teleport cube and audio components"""
	if auto_find_teleport_audio:
		# Look for teleport cube with CubeAudioPlayer
		var teleport_nodes = get_tree().get_nodes_in_group("teleport")
		if teleport_nodes.is_empty():
			teleport_nodes = [get_tree().current_scene.find_child("*Teleport*", true, false)]
		
		for node in teleport_nodes:
			if node:
				var audio_player = node.find_child("TeleportAudio", true, false)
				if audio_player and audio_player is Node3D:
					# Look for AudioStreamPlayer3D children
					for child in audio_player.get_children():
						if child is AudioStreamPlayer3D:
							target_audio_player = child
							teleport_cube_node = node
							_setup_audio_analysis()
							print("GameSoundMeter: Auto-found teleport audio: %s" % child.name)
							break
	
	# Find player camera for distance culling
	var cameras = [
		get_tree().get_first_node_in_group("player_camera"),
		get_tree().current_scene.find_child("Camera3D", true, false),
		get_tree().current_scene.find_child("*Player*", true, false)
	]
	
	for cam in cameras:
		if cam and cam is Camera3D:
			player_camera = cam
			break

func _setup_auto_sizing():
	"""Setup automatic sizing to parent container"""
	if get_parent() is Control:
		var parent = get_parent() as Control
		parent.resized.connect(_resize_to_parent)
		_resize_to_parent()

func _resize_to_parent():
	"""Resize to fit parent container"""
	if get_parent() is Control:
		var parent = get_parent() as Control
		size = parent.size
		position = Vector2.ZERO

func _process(delta: float):
	if not is_initialized or not spectrum_instance:
		return
	
	# Performance culling
	if enable_distance_culling and _should_cull_update():
		frame_skip_counter += 1
		if frame_skip_counter < 30:  # Skip 30 frames when far away
			return
		frame_skip_counter = 0
	
	# Update at specified rate
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_audio_data()
	
	# Smooth the data
	_smooth_audio_data(delta)
	
	# Trigger redraw
	queue_redraw()

func _should_cull_update() -> bool:
	"""Check if we should skip updates for performance"""
	if not player_camera or not target_audio_player:
		return false
	
	var distance = player_camera.global_position.distance_to(target_audio_player.global_position)
	return distance > max_display_distance

func _update_audio_data():
	"""Update audio data from spectrum analyzer"""
	if not spectrum_instance:
		return
	
	match display_style:
		DisplayStyle.SPECTRUM_LINE, DisplayStyle.SPECTRUM_BARS:
			_update_spectrum_data()
		DisplayStyle.VU_METER:
			_update_vu_data()
		DisplayStyle.WAVEFORM, DisplayStyle.OSCILLOSCOPE:
			_update_waveform_data()

func _update_spectrum_data():
	"""Update frequency spectrum data"""
	for i in range(bar_count):
		var freq_ratio = float(i) / float(bar_count - 1)
		var freq_hz = freq_ratio * 8000.0  # Cover up to 8kHz
		
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq_hz, freq_hz + 100.0
		).length()
		
		# Convert to normalized dB with enhanced lower frequency response
		var db = 20.0 * log(magnitude) / log(10.0) if magnitude > 0.0 else -80.0
		var normalized = clamp((db + 50.0) / 50.0, 0.0, 1.0)  # More sensitive range
		
		# Boost lower frequencies for better visibility
		if i < bar_count * 0.3:  # First 30% of spectrum (lower frequencies)
			normalized = normalized * 2.0  # Double the amplitude
		
		frequency_data[i] = normalized
		peak_levels[i] = max(peak_levels[i] * 0.95, normalized)  # Peak hold

func _update_vu_data():
	"""Update VU meter data"""
	var total_magnitude = 0.0
	for i in range(10):  # Sample lower frequencies for VU
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			i * 200.0, (i + 1) * 200.0
		).length()
		total_magnitude += magnitude
	
	var avg_magnitude = total_magnitude / 10.0
	var db = 20.0 * log(avg_magnitude) / log(10.0) if avg_magnitude > 0.0 else -80.0
	var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)
	
	frequency_data[0] = normalized  # Use first element for VU level

func _update_waveform_data():
	"""Update waveform data (simplified)"""
	# For waveform, we sample across the spectrum and create a time-like representation
	for i in range(bar_count):
		var freq_ratio = float(i) / float(bar_count - 1)
		var freq_hz = freq_ratio * 4000.0
		
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq_hz, freq_hz + 50.0
		).length()
		
		frequency_data[i] = magnitude * 100.0  # Scale for waveform display

func _smooth_audio_data(delta: float):
	"""Apply smoothing to audio data"""
	var smooth_speed = 1.0 - pow(smoothing_factor, delta * 60.0)
	
	for i in range(bar_count):
		smoothed_data[i] = lerp(smoothed_data[i], frequency_data[i], smooth_speed)

func _draw():
	"""Draw the sound meter based on selected style"""
	if not is_initialized:
		return
	
	# Draw background
	if background_color.a > 0.0:
		draw_rect(meter_rect, background_color)
	
	# If no spectrum instance, show test pattern
	if not spectrum_instance:
		_draw_test_pattern()
		return
	
	match display_style:
		DisplayStyle.SPECTRUM_LINE:
			_draw_spectrum_line()
		DisplayStyle.SPECTRUM_BARS:
			_draw_spectrum_bars()
		DisplayStyle.VU_METER:
			_draw_vu_meter()
		DisplayStyle.WAVEFORM:
			_draw_waveform()
		DisplayStyle.OSCILLOSCOPE:
			_draw_oscilloscope()

func _draw_spectrum_line():
	"""Draw spectrum as connected line"""
	if smoothed_data.size() < 2:
		return
	
	var points: PackedVector2Array = []
	
	# Add some padding to ensure full visibility
	var padding = 10.0
	var draw_rect = Rect2(meter_rect.position + Vector2(padding, padding), 
						 meter_rect.size - Vector2(padding * 2, padding * 2))
	
	for i in range(bar_count):
		var x = draw_rect.position.x + (float(i) / float(bar_count - 1)) * draw_rect.size.x
		var y = draw_rect.position.y + draw_rect.size.y - (smoothed_data[i] * (draw_rect.size.y - padding))
		points.append(Vector2(x, y))
	
	# Draw glow effect (multiple passes)
	for glow_pass in range(3):
		var glow_width = line_width + (glow_pass * 2)
		var glow_alpha = 0.3 - (glow_pass * 0.1)
		var glow_color = Color(line_color.r, line_color.g, line_color.b, glow_alpha)
		
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], glow_color, glow_width)
	
	# Draw the main spectrum line (bright and solid)
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, line_width)

func _draw_spectrum_bars():
	"""Draw spectrum as individual bars"""
	for i in range(bar_count):
		var x = meter_rect.position.x + i * bar_width
		var height = smoothed_data[i] * height_multiplier
		var y = meter_rect.position.y + meter_rect.size.y - height
		
		var bar_rect = Rect2(x, y, bar_width * 0.8, height)
		draw_rect(bar_rect, line_color)
		
		# Draw peak hold
		var peak_y = meter_rect.position.y + meter_rect.size.y - (peak_levels[i] * height_multiplier)
		draw_line(Vector2(x, peak_y), Vector2(x + bar_width * 0.8, peak_y), Color.WHITE, 1.0)

func _draw_vu_meter():
	"""Draw VU style meter"""
	var level = smoothed_data[0] if smoothed_data.size() > 0 else 0.0
	var fill_width = level * meter_rect.size.x
	
	# Background
	draw_rect(meter_rect, Color(0.2, 0.2, 0.2, 1.0))
	
	# Level fill
	var level_rect = Rect2(meter_rect.position, Vector2(fill_width, meter_rect.size.y))
	var level_color = Color.GREEN if level < 0.7 else (Color.YELLOW if level < 0.9 else Color.RED)
	draw_rect(level_rect, level_color)

func _draw_waveform():
	"""Draw waveform representation"""
	var center_y = meter_rect.position.y + meter_rect.size.y * 0.5
	var points: PackedVector2Array = []
	
	for i in range(bar_count):
		var x = meter_rect.position.x + (float(i) / float(bar_count - 1)) * meter_rect.size.x
		var amplitude = smoothed_data[i] * meter_rect.size.y * 0.4
		var y = center_y + sin(float(i) * 0.5) * amplitude  # Create wave-like pattern
		points.append(Vector2(x, y))
	
	for i in range(points.size() - 1):
		draw_line(points[i], points[i + 1], line_color, line_width)

func _draw_oscilloscope():
	"""Draw oscilloscope style display"""
	# Draw grid
	var grid_color = Color(0, 0.3, 0, 0.5)
	for i in range(5):
		var y = meter_rect.position.y + (float(i) / 4.0) * meter_rect.size.y
		draw_line(Vector2(meter_rect.position.x, y), 
				 Vector2(meter_rect.position.x + meter_rect.size.x, y), grid_color)
	
	_draw_waveform()  # Use waveform drawing for oscilloscope

func _update_cached_values():
	"""Update cached calculation values"""
	meter_rect = Rect2(Vector2.ZERO, size)
	bar_width = meter_rect.size.x / float(bar_count)
	print("GameSoundMeter: Meter rect updated - ", meter_rect)

func _on_resized():
	"""Handle control resize"""
	_update_cached_values()

# Public API
func set_audio_target(player: AudioStreamPlayer3D):
	"""Set the target audio player"""
	target_audio_player = player
	_setup_audio_analysis()

func set_display_style(style: DisplayStyle):
	"""Change the display style"""
	display_style = style

func get_performance_stats() -> Dictionary:
	"""Get performance statistics"""
	return {
		"initialized": is_initialized,
		"has_spectrum": spectrum_instance != null,
		"has_target": target_audio_player != null,
		"update_fps": update_fps,
		"frame_skip_count": frame_skip_counter,
		"distance_culled": _should_cull_update() if enable_distance_culling else false
	}

func _draw_test_pattern():
	"""Draw a test pattern when no audio is available"""
	var time = Time.get_time_dict_from_system()
	var seconds = time.second + time.minute * 60.0
	
	# Draw animated test bars
	for i in range(bar_count):
		var x = meter_rect.position.x + i * bar_width
		var height = (sin(seconds * 2.0 + i * 0.3) * 0.5 + 0.5) * height_multiplier * 0.5
		var y = meter_rect.position.y + meter_rect.size.y - height
		
		var bar_rect = Rect2(x, y, bar_width * 0.8, height)
		var color = Color(0.5, 1.0, 0.5, 0.8)  # Dimmed green
		draw_rect(bar_rect, color)
	
	# Draw "NO AUDIO" text
	var font_size = 20
	var text = "NO AUDIO - TEST PATTERN"
	var text_pos = Vector2(meter_rect.size.x * 0.5 - 100, meter_rect.size.y * 0.5)
	draw_string(get_theme_default_font(), text_pos, text, HORIZONTAL_ALIGNMENT_CENTER, -1, font_size, Color.WHITE)
