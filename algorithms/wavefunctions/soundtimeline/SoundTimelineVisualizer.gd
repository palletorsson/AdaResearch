# SoundTimelineVisualizer.gd
extends Control

class_name SoundTimelineVisualizer

# Audio processing components
var audio_stream_player: AudioStreamPlayer
var audio_effect_capture: AudioEffectCapture
var audio_bus_index: int = 0

# Visualization parameters
@export_category("Timeline Configuration")
@export var timeline_width: int = 1200
@export var timeline_height: int = 300
@export var waveform_color: Color = Color.CYAN
@export var background_color: Color = Color(0.1, 0.1, 0.1, 1.0)
@export var grid_color: Color = Color(0.3, 0.3, 0.3, 0.5)
@export var playhead_color: Color = Color.WHITE

# Frequency analysis
@export_category("Frequency Analysis")
@export var fft_size: int = 1024
@export var frequency_bands: int = 64
@export var frequency_smoothing: float = 0.8
@export var amplitude_scale: float = 100.0

# Timeline controls
@export_category("Timeline Controls")
@export var zoom_level: float = 1.0
@export var scroll_position: float = 0.0
@export var playback_position: float = 0.0
@export var auto_scroll: bool = true

# Data storage
var audio_buffer: PackedFloat32Array
var frequency_data: PackedFloat32Array
var timeline_data: Array[PackedFloat32Array] = []
var max_timeline_length: int = 10000  # Maximum samples to store

# UI elements
var timeline_rect: Rect2
var playhead_position: float = 0.0
var is_playing: bool = false
var is_recording: bool = false

# Visual effects
var rainbow_colors: Array[Color] = []
var time_markers: Array[float] = []

func _ready():
	setup_audio_system()
	setup_visualization()
	setup_ui()
	generate_rainbow_palette()
	
func setup_audio_system():
	# Create audio stream player
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)
	
	# Set up audio bus for capture
	var audio_server = AudioServer
	audio_bus_index = audio_server.get_bus_index("Master")
	
	# Add capture effect to the bus
	audio_effect_capture = AudioEffectCapture.new()
	audio_server.add_bus_effect(audio_bus_index, audio_effect_capture)
	
	# Initialize buffers
	audio_buffer = PackedFloat32Array()
	frequency_data = PackedFloat32Array()
	frequency_data.resize(frequency_bands)
	
	print("Audio system initialized - Bus index: ", audio_bus_index)

func setup_visualization():
	# Set up the timeline rectangle
	timeline_rect = Rect2(50, 50, timeline_width, timeline_height)
	
	# Set minimum size
	custom_minimum_size = Vector2(timeline_width + 100, timeline_height + 200)
	
	# Initialize timeline data storage
	for i in range(frequency_bands):
		timeline_data.append(PackedFloat32Array())

func setup_ui():
	# Enable drawing
	set_process(true)
	queue_redraw()

func generate_rainbow_palette():
	rainbow_colors.clear()
	for i in range(frequency_bands):
		var hue = float(i) / frequency_bands
		var color = Color.from_hsv(hue, 0.8, 1.0)
		rainbow_colors.append(color)

func _process(delta):
	if is_recording:
		capture_audio_data()
	
	if is_playing:
		update_playback_position(delta)
	
	update_visualization(delta)
	queue_redraw()

func capture_audio_data():
	if not audio_effect_capture:
		return
		
	var frames_available = audio_effect_capture.get_frames_available()
	if frames_available > 0:
		var buffer = audio_effect_capture.get_buffer(frames_available)
		
		# Process stereo to mono
		for frame in buffer:
			var mono_sample = (frame.x + frame.y) * 0.5
			audio_buffer.append(mono_sample)
		
		# Limit buffer size
		if audio_buffer.size() > max_timeline_length:
			var excess = audio_buffer.size() - max_timeline_length
			audio_buffer = audio_buffer.slice(excess)
		
		# Perform FFT analysis
		perform_fft_analysis()

func perform_fft_analysis():
	if audio_buffer.size() < fft_size:
		return
	
	# Get the latest samples for FFT
	var fft_input = audio_buffer.slice(audio_buffer.size() - fft_size)
	
	# Simple frequency analysis (binning)
	var band_size = fft_size / (frequency_bands * 2)
	
	for band in range(frequency_bands):
		var start_idx = int(band * band_size)
		var end_idx = int((band + 1) * band_size)
		
		var magnitude = 0.0
		for i in range(start_idx, min(end_idx, fft_input.size())):
			magnitude += abs(fft_input[i])
		
		magnitude /= band_size
		magnitude *= amplitude_scale
		
		# Apply smoothing
		if timeline_data[band].size() > 0:
			var last_value = timeline_data[band][-1]
			magnitude = lerp(last_value, magnitude, 1.0 - frequency_smoothing)
		
		# Store in timeline data
		timeline_data[band].append(magnitude)
		
		# Limit timeline data size
		if timeline_data[band].size() > max_timeline_length:
			timeline_data[band] = timeline_data[band].slice(1)

func update_playback_position(delta):
	playback_position += delta
	
	if auto_scroll:
		# Auto-scroll to follow playback
		var timeline_duration = get_timeline_duration()
		if timeline_duration > 0:
			scroll_position = playback_position / timeline_duration

func update_visualization(delta):
	# Update playhead position
	var timeline_duration = get_timeline_duration()
	if timeline_duration > 0:
		playhead_position = (playback_position / timeline_duration) * timeline_width

func get_timeline_duration() -> float:
	if timeline_data.is_empty() or timeline_data[0].is_empty():
		return 1.0
	return timeline_data[0].size() / 60.0  # Assuming ~60 FPS capture rate

func _draw():
	draw_background()
	draw_grid()
	draw_waveform()
	draw_frequency_spectrum()
	draw_timeline_markers()
	draw_playhead()
	draw_ui_elements()

func draw_background():
	# Draw main background
	draw_rect(timeline_rect, background_color)
	
	# Draw border
	draw_rect(timeline_rect, Color.WHITE, false, 2.0)

func draw_grid():
	var grid_spacing_x = timeline_width / 10
	var grid_spacing_y = timeline_height / 8
	
	# Vertical grid lines (time markers)
	for i in range(11):
		var x = timeline_rect.position.x + i * grid_spacing_x
		draw_line(
			Vector2(x, timeline_rect.position.y),
			Vector2(x, timeline_rect.position.y + timeline_height),
			grid_color,
			1.0
		)
	
	# Horizontal grid lines (amplitude markers)
	for i in range(9):
		var y = timeline_rect.position.y + i * grid_spacing_y
		draw_line(
			Vector2(timeline_rect.position.x, y),
			Vector2(timeline_rect.position.x + timeline_width, y),
			grid_color,
			1.0
		)

func draw_waveform():
	if audio_buffer.is_empty():
		return
	
	var samples_per_pixel = max(1, audio_buffer.size() / timeline_width)
	var center_y = timeline_rect.position.y + timeline_height * 0.5
	
	var points: PackedVector2Array = []
	
	for x in range(timeline_width):
		var sample_index = int(x * samples_per_pixel + scroll_position * audio_buffer.size())
		if sample_index >= 0 and sample_index < audio_buffer.size():
			var amplitude = audio_buffer[sample_index]
			var y = center_y - amplitude * timeline_height * 0.4
			points.append(Vector2(timeline_rect.position.x + x, y))
	
	# Draw waveform as connected lines
	if points.size() > 1:
		for i in range(points.size() - 1):
			draw_line(points[i], points[i + 1], waveform_color, 2.0)

func draw_frequency_spectrum():
	if timeline_data.is_empty():
		return
	
	var band_width = float(timeline_width) / frequency_bands
	var timeline_length = get_max_timeline_length()
	
	if timeline_length == 0:
		return
	
	var samples_per_pixel = max(1, timeline_length / timeline_width)
	
	# Draw frequency bands as vertical colored bars over time
	for x in range(timeline_width):
		var time_index = int(x * samples_per_pixel + scroll_position * timeline_length)
		
		for band in range(frequency_bands):
			if time_index >= 0 and time_index < timeline_data[band].size():
				var magnitude = timeline_data[band][time_index]
				var normalized_magnitude = clamp(magnitude / 50.0, 0.0, 1.0)
				
				if normalized_magnitude > 0.01:  # Only draw if there's significant amplitude
					var color = rainbow_colors[band]
					color.a = normalized_magnitude * 0.7
					
					var bar_height = normalized_magnitude * timeline_height * 0.3
					var y_start = timeline_rect.position.y + timeline_height - bar_height
					
					draw_rect(
						Rect2(
							timeline_rect.position.x + x,
							y_start,
							1,
							bar_height
						),
						color
					)

func get_max_timeline_length() -> int:
	var max_length = 0
	for band_data in timeline_data:
		max_length = max(max_length, band_data.size())
	return max_length

func draw_timeline_markers():
	var timeline_duration = get_timeline_duration()
	var marker_interval = 1.0  # 1 second intervals
	
	if timeline_duration > 0:
		var markers_count = int(timeline_duration / marker_interval)
		
		for i in range(markers_count + 1):
			var time = i * marker_interval
			var x = timeline_rect.position.x + (time / timeline_duration) * timeline_width
			
			# Draw marker line
			draw_line(
				Vector2(x, timeline_rect.position.y),
				Vector2(x, timeline_rect.position.y + timeline_height),
				Color.YELLOW,
				1.0
			)
			
			# Draw time label
			var time_text = "%.1fs" % time
			var font = ThemeDB.fallback_font
			var font_size = 12
			draw_string(
				font,
				Vector2(x + 2, timeline_rect.position.y - 5),
				time_text,
				HORIZONTAL_ALIGNMENT_LEFT,
				-1,
				font_size,
				Color.YELLOW
			)

func draw_playhead():
	if is_playing:
		var x = timeline_rect.position.x + playhead_position
		
		# Draw playhead line
		draw_line(
			Vector2(x, timeline_rect.position.y),
			Vector2(x, timeline_rect.position.y + timeline_height),
			playhead_color,
			3.0
		)
		
		# Draw playhead triangle
		var triangle_points = PackedVector2Array([
			Vector2(x - 8, timeline_rect.position.y - 10),
			Vector2(x + 8, timeline_rect.position.y - 10),
			Vector2(x, timeline_rect.position.y)
		])
		draw_colored_polygon(triangle_points, playhead_color)

func draw_ui_elements():
	var font = ThemeDB.fallback_font
	var font_size = 14
	
	# Draw title
	draw_string(
		font,
		Vector2(timeline_rect.position.x, timeline_rect.position.y - 25),
		"Sound Timeline Visualizer",
		HORIZONTAL_ALIGNMENT_LEFT,
		-1,
		font_size,
		Color.WHITE
	)
	
	# Draw status information
	var status_y = timeline_rect.position.y + timeline_height + 20
	var status_texts = [
		"Status: " + ("Recording" if is_recording else ("Playing" if is_playing else "Stopped")),
		"Samples: " + str(audio_buffer.size()),
		"Duration: %.2fs" % get_timeline_duration(),
		"Position: %.2fs" % playback_position
	]
	
	for i in range(status_texts.size()):
		draw_string(
			font,
			Vector2(timeline_rect.position.x + i * 200, status_y),
			status_texts[i],
			HORIZONTAL_ALIGNMENT_LEFT,
			-1,
			12,
			Color.LIGHT_GRAY
		)

# Control functions
func start_recording():
	is_recording = true
	is_playing = true
	playback_position = 0.0
	print("Started recording audio timeline")

func stop_recording():
	is_recording = false
	print("Stopped recording audio timeline")

func start_playback():
	is_playing = true
	print("Started timeline playback")

func stop_playback():
	is_playing = false
	print("Stopped timeline playback")

func clear_timeline():
	audio_buffer.clear()
	for band_data in timeline_data:
		band_data.clear()
	playback_position = 0.0
	scroll_position = 0.0
	print("Cleared timeline data")

func set_zoom(new_zoom: float):
	zoom_level = clamp(new_zoom, 0.1, 10.0)
	queue_redraw()

func set_scroll(new_scroll: float):
	scroll_position = clamp(new_scroll, 0.0, 1.0)
	queue_redraw()

# Audio file loading
func load_audio_file(file_path: String):
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open audio file: ", file_path)
		return
	
	print("Loading audio file: ", file_path)
	# Note: This is a simplified example - you'd need proper audio format parsing
	file.close()

# Export functionality
func export_timeline_data() -> Dictionary:
	var export_data = {
		"audio_buffer": audio_buffer,
		"timeline_data": timeline_data,
		"duration": get_timeline_duration(),
		"frequency_bands": frequency_bands,
		"sample_rate": 44100
	}
	return export_data

func import_timeline_data(data: Dictionary):
	if data.has("audio_buffer"):
		audio_buffer = data["audio_buffer"]
	if data.has("timeline_data"):
		timeline_data = data["timeline_data"]
	queue_redraw()

# Input handling
func _gui_input(event):
	if event is InputEventMouseButton:
		if event.pressed and timeline_rect.has_point(event.position):
			# Click to set playback position
			var click_x = event.position.x - timeline_rect.position.x
			var relative_position = click_x / timeline_width
			playback_position = relative_position * get_timeline_duration()
			playhead_position = click_x
			queue_redraw()
	
	elif event is InputEventMouseMotion:
		if event.button_mask == MOUSE_BUTTON_LEFT and timeline_rect.has_point(event.position):
			# Drag to scrub through timeline
			var click_x = event.position.x - timeline_rect.position.x
			var relative_position = click_x / timeline_width
			playback_position = relative_position * get_timeline_duration()
			playhead_position = click_x
			queue_redraw()

# Keyboard shortcuts
func _unhandled_input(event):
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_SPACE:
				if is_playing:
					stop_playback()
				else:
					start_playback()
			KEY_R:
				if is_recording:
					stop_recording()
				else:
					start_recording()
			KEY_C:
				clear_timeline()
			KEY_ESCAPE:
				stop_playback()
				stop_recording()
