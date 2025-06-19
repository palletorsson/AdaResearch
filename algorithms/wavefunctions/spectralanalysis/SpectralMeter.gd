# SpectralMeter.gd - Performant audio spectrum visualizer for game objects
extends Control
class_name SpectralMeter

# Configuration
@export var target_audio_player: AudioStreamPlayer3D
@export var bar_count: int = 64  # Number of frequency bars
@export var update_rate: float = 30.0  # FPS for spectrum updates
@export var line_color: Color = Color(0, 1, 0, 1)  # Green line
@export var background_color: Color = Color(0, 0, 0, 1)  # Black background
@export var line_width: float = 2.0
@export var height_multiplier: float = 200.0
@export var smoothing_factor: float = 0.85  # For smooth animations

# Performance optimization
@export var enabled: bool = true
@export var max_distance_from_player: float = 50.0  # Don't update if too far

# Internal state
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectInstance
var frequency_heights: PackedFloat32Array
var target_heights: PackedFloat32Array
var update_timer: float = 0.0
var update_interval: float
var player_camera: Camera3D

# Cached values for performance
var bar_width: float
var meter_size: Vector2

func _ready():
	# Initialize arrays
	frequency_heights.resize(bar_count)
	target_heights.resize(bar_count)
	frequency_heights.fill(0.0)
	target_heights.fill(0.0)
	
	# Calculate update interval
	update_interval = 1.0 / update_rate
	
	# Setup audio analysis
	_setup_spectrum_analyzer()
	
	# Find player camera for distance optimization
	_find_player_camera()
	
	# Cache meter size
	meter_size = size
	bar_width = meter_size.x / float(bar_count)
	
	# Connect to resize signal
	resized.connect(_on_resized)
	
	print("SpectralMeter: Initialized with %d bars at %d fps" % [bar_count, update_rate])

func _setup_spectrum_analyzer():
	"""Setup the spectrum analyzer on the target audio player"""
	if not target_audio_player:
		print("SpectralMeter: No target audio player assigned")
		return
	
	# Get or create the audio bus for the player
	var bus_name = "SpectrumAnalysis"
	var bus_index = AudioServer.get_bus_index(bus_name)
	
	# Create the bus if it doesn't exist
	if bus_index == -1:
		AudioServer.add_bus()
		bus_index = AudioServer.get_bus_count() - 1
		AudioServer.set_bus_name(bus_index, bus_name)
		print("SpectralMeter: Created audio bus '%s'" % bus_name)
	
	# Add spectrum analyzer effect to the bus
	spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
	spectrum_analyzer.buffer_length = 2.0  # Longer buffer for better frequency resolution
	spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
	spectrum_analyzer.tap_back_pos = 0.01  # Slight delay for better analysis
	
	AudioServer.add_bus_effect(bus_index, spectrum_analyzer)
	print("SpectralMeter: Added spectrum analyzer to bus")
	
	# Set the audio player to use this bus
	target_audio_player.bus = bus_name
	
	# Get the effect instance for reading spectrum data
	spectrum_instance = AudioServer.get_bus_effect_instance(bus_index, 0)

func _find_player_camera():
	"""Find the player camera for distance-based optimization"""
	# Try multiple common camera locations
	var potential_cameras = [
		get_tree().get_first_node_in_group("player_camera"),
		get_tree().current_scene.find_child("Camera3D", true, false),
		get_tree().current_scene.find_child("PlayerCamera", true, false)
	]
	
	for camera in potential_cameras:
		if camera and camera is Camera3D:
			player_camera = camera
			print("SpectralMeter: Found player camera - %s" % camera.name)
			break

func _process(delta: float):
	if not enabled or not spectrum_instance:
		return
	
	# Performance optimization: skip updates if player is too far
	if _should_skip_update():
		return
	
	# Update at specified rate
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_spectrum_data()
	
	# Smooth the frequency heights
	_smooth_heights(delta)
	
	# Trigger redraw
	queue_redraw()

func _should_skip_update() -> bool:
	"""Check if we should skip updating for performance"""
	if not player_camera or not target_audio_player:
		return false
	
	var distance = player_camera.global_position.distance_to(target_audio_player.global_position)
	return distance > max_distance_from_player

func _update_spectrum_data():
	"""Update the spectrum data from the audio analyzer"""
	if not spectrum_instance:
		return
	
	var spectrum = spectrum_instance as AudioEffectSpectrumAnalyzerInstance
	if not spectrum:
		return
	
	# Get magnitude for each frequency bar
	for i in range(bar_count):
		var freq_ratio = float(i) / float(bar_count)
		var freq_hz = freq_ratio * 11000.0  # Cover up to 11kHz (most important audio range)
		
		var magnitude = spectrum.get_magnitude_for_frequency_range(
			freq_hz - 50.0,  # Lower bound
			freq_hz + 50.0   # Upper bound
		).length()
		
		# Convert to decibels and normalize
		var db = 20.0 * log(magnitude) / log(10.0) if magnitude > 0.0 else -80.0
		var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)  # Map -60dB to 0dB -> 0 to 1
		
		target_heights[i] = normalized * height_multiplier

func _smooth_heights(delta: float):
	"""Smooth the height transitions for better visuals"""
	for i in range(bar_count):
		frequency_heights[i] = lerp(frequency_heights[i], target_heights[i], 1.0 - pow(smoothing_factor, delta * 60.0))

func _draw():
	"""Draw the spectrum meter"""
	if not enabled:
		return
	
	# Draw black background
	draw_rect(Rect2(Vector2.ZERO, meter_size), background_color)
	
	# Draw frequency bars as connected line
	if frequency_heights.size() >= 2:
		var points: PackedVector2Array = []
		
		# Add points for the spectrum line
		for i in range(bar_count):
			var x = (float(i) + 0.5) * bar_width
			var y = meter_size.y - frequency_heights[i]
			points.append(Vector2(x, y))
		
		# Draw the spectrum line
		if points.size() >= 2:
			for i in range(points.size() - 1):
				draw_line(points[i], points[i + 1], line_color, line_width)
		
		# Optional: Draw individual frequency peaks as small circles
		for i in range(bar_count):
			if frequency_heights[i] > 5.0:  # Only show significant peaks
				var x = (float(i) + 0.5) * bar_width
				var y = meter_size.y - frequency_heights[i]
				draw_circle(Vector2(x, y), line_width * 0.5, line_color)

func _on_resized():
	"""Handle meter resize"""
	meter_size = size
	bar_width = meter_size.x / float(bar_count)

# Public API
func set_target_audio_player(player: AudioStreamPlayer3D):
	"""Set the audio player to analyze"""
	target_audio_player = player
	_setup_spectrum_analyzer()

func set_enabled(state: bool):
	"""Enable or disable the meter"""
	enabled = state
	if not enabled:
		queue_redraw()  # Clear the display

func set_line_color(color: Color):
	"""Change the line color"""
	line_color = color

func set_update_rate(fps: float):
	"""Change the update rate"""
	update_rate = clamp(fps, 10.0, 60.0)
	update_interval = 1.0 / update_rate

# Performance monitoring
func get_performance_info() -> Dictionary:
	"""Get performance information"""
	return {
		"enabled": enabled,
		"bar_count": bar_count,
		"update_rate": update_rate,
		"has_spectrum_analyzer": spectrum_instance != null,
		"has_target_player": target_audio_player != null,
		"distance_optimization": _should_skip_update()
	}
