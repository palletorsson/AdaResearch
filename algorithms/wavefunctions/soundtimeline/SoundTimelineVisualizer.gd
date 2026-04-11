# SoundTimelineVisualizer.gd - Audio timeline visualization (VR/3D)
extends Node3D

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

# Panel size in meters (1200px -> 1.2m, 300px -> 0.3m)
const PX_TO_M := 0.001  # 1px = 1mm
var panel_width: float
var panel_height: float

# Data storage
var audio_buffer: PackedFloat32Array
var frequency_data: PackedFloat32Array
var timeline_data: Array[PackedFloat32Array] = []
var max_timeline_length: int = 10000

# UI elements
var playhead_position_px: float = 0.0
var is_playing: bool = false
var is_recording: bool = false

# Visual effects
var rainbow_colors: Array[Color] = []
var time_markers: Array[float] = []

# ImmediateMesh rendering
var _mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D

# Label3D nodes
var _title_label: Label3D
var _status_labels: Array[Label3D] = []
var _time_marker_labels: Array[Label3D] = []

func _ready() -> void:
	panel_width = timeline_width * PX_TO_M
	panel_height = timeline_height * PX_TO_M

	setup_audio_system()
	setup_visualization()
	_setup_mesh()
	_setup_labels()
	generate_rainbow_palette()

func setup_audio_system() -> void:
	audio_stream_player = AudioStreamPlayer.new()
	add_child(audio_stream_player)

	var audio_server = AudioServer
	audio_bus_index = audio_server.get_bus_index("Master")

	audio_effect_capture = AudioEffectCapture.new()
	audio_server.add_bus_effect(audio_bus_index, audio_effect_capture)

	audio_buffer = PackedFloat32Array()
	frequency_data = PackedFloat32Array()
	frequency_data.resize(frequency_bands)

	print("Audio system initialized - Bus index: ", audio_bus_index)

func setup_visualization() -> void:
	for i in range(frequency_bands):
		timeline_data.append(PackedFloat32Array())

func _setup_mesh() -> void:
	"""Setup ImmediateMesh for 3D rendering"""
	_mesh = ImmediateMesh.new()
	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = _mesh
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.no_depth_test = false
	_mesh_instance.material_override = mat
	add_child(_mesh_instance)

func _setup_labels() -> void:
	"""Create Label3D nodes for title and status"""
	# Title
	_title_label = Label3D.new()
	_title_label.font_size = 42
	_title_label.pixel_size = 0.001
	_title_label.no_depth_test = false
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_title_label.text = "Sound Timeline Visualizer"
	_title_label.modulate = Color.WHITE
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	_title_label.position = Vector3(0.0, 0.025, 0.002)
	add_child(_title_label)

	# Status labels (4 columns)
	var status_texts = ["Status: Stopped", "Samples: 0", "Duration: 0.00s", "Position: 0.00s"]
	for i in range(4):
		var lbl = Label3D.new()
		lbl.font_size = 36
		lbl.pixel_size = 0.001
		lbl.no_depth_test = false
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.text = status_texts[i]
		lbl.modulate = Color.LIGHT_GRAY
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.position = Vector3(i * 0.2, -(panel_height + 0.02), 0.002)
		add_child(lbl)
		_status_labels.append(lbl)

func generate_rainbow_palette() -> void:
	rainbow_colors.clear()
	for i in range(frequency_bands):
		var hue = float(i) / frequency_bands
		var color = Color.from_hsv(hue, 0.8, 1.0)
		rainbow_colors.append(color)

func _process(delta: float) -> void:
	if is_recording:
		capture_audio_data()

	if is_playing:
		update_playback_position(delta)

	update_visualization(delta)
	_update_mesh()

func capture_audio_data() -> void:
	if not audio_effect_capture:
		return

	var frames_available = audio_effect_capture.get_frames_available()
	if frames_available > 0:
		var buffer = audio_effect_capture.get_buffer(frames_available)

		for frame in buffer:
			var mono_sample = (frame.x + frame.y) * 0.5
			audio_buffer.append(mono_sample)

		if audio_buffer.size() > max_timeline_length:
			var excess = audio_buffer.size() - max_timeline_length
			audio_buffer = audio_buffer.slice(excess)

		perform_fft_analysis()

func perform_fft_analysis() -> void:
	if audio_buffer.size() < fft_size:
		return

	var fft_input = audio_buffer.slice(audio_buffer.size() - fft_size)
	var band_size = fft_size / (frequency_bands * 2)

	for band in range(frequency_bands):
		var start_idx = int(band * band_size)
		var end_idx = int((band + 1) * band_size)

		var magnitude = 0.0
		for i in range(start_idx, min(end_idx, fft_input.size())):
			magnitude += abs(fft_input[i])

		magnitude /= band_size
		magnitude *= amplitude_scale

		if timeline_data[band].size() > 0:
			var last_value = timeline_data[band][-1]
			magnitude = lerp(last_value, magnitude, 1.0 - frequency_smoothing)

		timeline_data[band].append(magnitude)

		if timeline_data[band].size() > max_timeline_length:
			timeline_data[band] = timeline_data[band].slice(1)

func update_playback_position(delta) -> void:
	playback_position += delta

	if auto_scroll:
		var timeline_duration = get_timeline_duration()
		if timeline_duration > 0:
			scroll_position = playback_position / timeline_duration

func update_visualization(_delta) -> void:
	var timeline_duration = get_timeline_duration()
	if timeline_duration > 0:
		playhead_position_px = (playback_position / timeline_duration) * timeline_width

func get_timeline_duration() -> float:
	if timeline_data.is_empty() or timeline_data[0].is_empty():
		return 1.0
	return timeline_data[0].size() / 60.0

func _update_mesh() -> void:
	"""Render timeline as ImmediateMesh on XY plane"""
	_mesh.clear_surfaces()

	_draw_background_mesh()
	_draw_grid_mesh()
	_draw_waveform_mesh()
	_draw_frequency_spectrum_mesh()
	_draw_timeline_markers_mesh()
	_draw_playhead_mesh()
	_update_status_labels()

func _draw_background_mesh() -> void:
	"""Draw main background and border"""
	# Background fill
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(background_color)
	_mesh.surface_add_vertex(Vector3(0, 0, 0))
	_mesh.surface_add_vertex(Vector3(panel_width, 0, 0))
	_mesh.surface_add_vertex(Vector3(panel_width, -panel_height, 0))
	_mesh.surface_add_vertex(Vector3(0, 0, 0))
	_mesh.surface_add_vertex(Vector3(panel_width, -panel_height, 0))
	_mesh.surface_add_vertex(Vector3(0, -panel_height, 0))
	_mesh.surface_end()

	# Border
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(Color.WHITE)
	_mesh.surface_add_vertex(Vector3(0, 0, 0.001))
	_mesh.surface_add_vertex(Vector3(panel_width, 0, 0.001))
	_mesh.surface_add_vertex(Vector3(panel_width, 0, 0.001))
	_mesh.surface_add_vertex(Vector3(panel_width, -panel_height, 0.001))
	_mesh.surface_add_vertex(Vector3(panel_width, -panel_height, 0.001))
	_mesh.surface_add_vertex(Vector3(0, -panel_height, 0.001))
	_mesh.surface_add_vertex(Vector3(0, -panel_height, 0.001))
	_mesh.surface_add_vertex(Vector3(0, 0, 0.001))
	_mesh.surface_end()

func _draw_grid_mesh() -> void:
	"""Draw grid lines"""
	var grid_spacing_x = panel_width / 10.0
	var grid_spacing_y = panel_height / 8.0

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(grid_color)

	# Vertical grid lines
	for i in range(11):
		var x = i * grid_spacing_x
		_mesh.surface_add_vertex(Vector3(x, 0, 0.0005))
		_mesh.surface_add_vertex(Vector3(x, -panel_height, 0.0005))

	# Horizontal grid lines
	for i in range(9):
		var y = -i * grid_spacing_y
		_mesh.surface_add_vertex(Vector3(0, y, 0.0005))
		_mesh.surface_add_vertex(Vector3(panel_width, y, 0.0005))

	_mesh.surface_end()

func _draw_waveform_mesh() -> void:
	"""Draw audio waveform"""
	if audio_buffer.is_empty():
		return

	var samples_per_pixel = max(1, audio_buffer.size() / timeline_width)
	var center_y = -panel_height * 0.5

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(waveform_color)

	var prev_point := Vector3.ZERO
	var has_prev := false

	for x_px in range(timeline_width):
		var sample_index = int(x_px * samples_per_pixel + scroll_position * audio_buffer.size())
		if sample_index >= 0 and sample_index < audio_buffer.size():
			var amplitude = audio_buffer[sample_index]
			var x = x_px * PX_TO_M
			var y = center_y - amplitude * panel_height * 0.4
			var point = Vector3(x, y, 0.001)

			if has_prev:
				_mesh.surface_add_vertex(prev_point)
				_mesh.surface_add_vertex(point)

			prev_point = point
			has_prev = true
		else:
			has_prev = false

	_mesh.surface_end()

func _draw_frequency_spectrum_mesh() -> void:
	"""Draw frequency bands as colored bars over time"""
	if timeline_data.is_empty():
		return

	var timeline_length = get_max_timeline_length()
	if timeline_length == 0:
		return

	var samples_per_pixel = max(1, timeline_length / timeline_width)

	# Use triangles for filled bars
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for x_px in range(0, timeline_width, 2):  # Step by 2 for performance
		var time_index = int(x_px * samples_per_pixel + scroll_position * timeline_length)

		for band in range(frequency_bands):
			if time_index >= 0 and time_index < timeline_data[band].size():
				var magnitude = timeline_data[band][time_index]
				var normalized_magnitude = clamp(magnitude / 50.0, 0.0, 1.0)

				if normalized_magnitude > 0.01:
					var color = rainbow_colors[band]
					color.a = normalized_magnitude * 0.7

					var bar_height = normalized_magnitude * panel_height * 0.3
					var x = x_px * PX_TO_M
					var y_start = -panel_height + bar_height
					var w = 2.0 * PX_TO_M

					_mesh.surface_set_color(color)
					_mesh.surface_add_vertex(Vector3(x, -panel_height, 0.0008))
					_mesh.surface_add_vertex(Vector3(x + w, -panel_height, 0.0008))
					_mesh.surface_add_vertex(Vector3(x + w, y_start, 0.0008))
					_mesh.surface_add_vertex(Vector3(x, -panel_height, 0.0008))
					_mesh.surface_add_vertex(Vector3(x + w, y_start, 0.0008))
					_mesh.surface_add_vertex(Vector3(x, y_start, 0.0008))

	_mesh.surface_end()

func get_max_timeline_length() -> int:
	var max_length = 0
	for band_data in timeline_data:
		max_length = max(max_length, band_data.size())
	return max_length

func _draw_timeline_markers_mesh() -> void:
	"""Draw time marker lines"""
	var timeline_duration = get_timeline_duration()
	var marker_interval = 1.0

	if timeline_duration <= 0:
		return

	var markers_count = int(timeline_duration / marker_interval)

	# Clean up old time marker labels
	for lbl in _time_marker_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	_time_marker_labels.clear()

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(Color.YELLOW)

	for i in range(markers_count + 1):
		var time = i * marker_interval
		var x = (time / timeline_duration) * panel_width

		_mesh.surface_add_vertex(Vector3(x, 0, 0.0012))
		_mesh.surface_add_vertex(Vector3(x, -panel_height, 0.0012))

		# Create time label
		var lbl = Label3D.new()
		lbl.font_size = 30
		lbl.pixel_size = 0.001
		lbl.no_depth_test = false
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.text = "%.1fs" % time
		lbl.modulate = Color.YELLOW
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.position = Vector3(x + 0.002, 0.005, 0.002)
		add_child(lbl)
		_time_marker_labels.append(lbl)

	_mesh.surface_end()

func _draw_playhead_mesh() -> void:
	"""Draw playhead line and triangle"""
	if not is_playing:
		return

	var x = playhead_position_px * PX_TO_M

	# Playhead line
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(playhead_color)
	_mesh.surface_add_vertex(Vector3(x, 0, 0.0015))
	_mesh.surface_add_vertex(Vector3(x, -panel_height, 0.0015))
	_mesh.surface_end()

	# Playhead triangle
	var tri_size = 0.008
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(playhead_color)
	_mesh.surface_add_vertex(Vector3(x - tri_size, tri_size, 0.0015))
	_mesh.surface_add_vertex(Vector3(x + tri_size, tri_size, 0.0015))
	_mesh.surface_add_vertex(Vector3(x, 0, 0.0015))
	_mesh.surface_end()

func _update_status_labels() -> void:
	"""Update status text labels"""
	if _status_labels.size() >= 4:
		var status_str = "Recording" if is_recording else ("Playing" if is_playing else "Stopped")
		_status_labels[0].text = "Status: " + status_str
		_status_labels[1].text = "Samples: " + str(audio_buffer.size())
		_status_labels[2].text = "Duration: %.2fs" % get_timeline_duration()
		_status_labels[3].text = "Position: %.2fs" % playback_position

# Control functions
func start_recording() -> void:
	is_recording = true
	is_playing = true
	playback_position = 0.0
	print("Started recording audio timeline")

func stop_recording() -> void:
	is_recording = false
	print("Stopped recording audio timeline")

func start_playback() -> void:
	is_playing = true
	print("Started timeline playback")

func stop_playback() -> void:
	is_playing = false
	print("Stopped timeline playback")

func clear_timeline() -> void:
	audio_buffer.clear()
	for band_data in timeline_data:
		band_data.clear()
	playback_position = 0.0
	scroll_position = 0.0
	print("Cleared timeline data")

func set_zoom(new_zoom: float) -> void:
	zoom_level = clamp(new_zoom, 0.1, 10.0)

func set_scroll(new_scroll: float) -> void:
	scroll_position = clamp(new_scroll, 0.0, 1.0)

# Audio file loading
func load_audio_file(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		print("Failed to open audio file: ", file_path)
		return
	print("Loading audio file: ", file_path)
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

func import_timeline_data(data: Dictionary) -> void:
	if data.has("audio_buffer"):
		audio_buffer = data["audio_buffer"]
	if data.has("timeline_data"):
		timeline_data = data["timeline_data"]

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	for lbl in _status_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	for lbl in _time_marker_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	if _title_label and is_instance_valid(_title_label):
		_title_label.queue_free()
	if _mesh_instance and is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()
