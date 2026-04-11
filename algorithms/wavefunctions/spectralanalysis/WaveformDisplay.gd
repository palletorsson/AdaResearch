# WaveformDisplay.gd - Sine wave visualization from spectral values over time (VR/3D)
# Creates a sine wave where the amplitude is modulated by frequency spectrum data
extends Node3D
class_name WaveformDisplay

@export var line_color: Color = Color(0, 1, 1, 1)  # Cyan for waveform
@export var background_color: Color = Color(0, 0, 0, 0.8)
@export var line_width: float = 3.0
@export var sample_count: int = 256  # Number of waveform samples
@export var amplitude_scale: float = 100.0
@export var time_scale: float = 2.0  # Speed of waveform scrolling
@export var source_bus: String = "Master"  # Audio bus to monitor

# Panel size in meters (was ~300px Control, now 0.4m x 0.2m)
const PANEL_SIZE := Vector3(0.4, 0.2, 0.0)
const PX_TO_M := 0.4 / 300.0

# Audio analysis
var spectrum_analyzer: AudioEffectSpectrumAnalyzer
var spectrum_instance: AudioEffectSpectrumAnalyzerInstance
var audio_bus_index: int = -1
var waveform_data: PackedFloat32Array
var time_offset: float = 0.0

# Display properties
var display_size: Vector2  # In meters
var is_initialized: bool = false
var debug_timer: float = 0.0
var _audio_setup_done: bool = false

# ImmediateMesh rendering
var _mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D

# Label3D nodes
var _title_label: Label3D
var _info_label: Label3D
var _grid_labels: Array[Label3D] = []

func _ready() -> void:
	_initialize_waveform()
	_setup_mesh()
	_setup_labels()
	print("WaveformDisplay: Initialized with %d samples" % sample_count)

	# Wait a moment for other audio systems to initialize first
	await get_tree().process_frame
	await get_tree().process_frame
	# Only run default setup if set_source_bus() wasn't already called
	if not _audio_setup_done:
		_setup_audio_analysis()

func _initialize_waveform() -> void:
	"""Initialize waveform data arrays"""
	waveform_data.resize(sample_count)
	waveform_data.fill(0.0)
	display_size = Vector2(PANEL_SIZE.x, PANEL_SIZE.y)
	is_initialized = true

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
	"""Create Label3D nodes for text overlays"""
	# Title label
	_title_label = Label3D.new()
	_title_label.font_size = 48
	_title_label.pixel_size = 0.001
	_title_label.no_depth_test = false
	_title_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_title_label.text = "SPECTRAL SINE WAVE"
	_title_label.modulate = Color(0, 1, 1, 1)
	_title_label.position = Vector3(0.01, -0.02, 0.002)
	_title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_title_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_title_label)

	# Info label
	_info_label = Label3D.new()
	_info_label.font_size = 36
	_info_label.pixel_size = 0.001
	_info_label.no_depth_test = false
	_info_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_info_label.modulate = Color(0.7, 0.9, 0.9, 0.8)
	_info_label.position = Vector3(0.01, -0.04, 0.002)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_info_label)

	# Amplitude grid labels (positive and negative)
	for i in range(3):
		var amplitude_value = (float(i + 1) / 4.0)
		var offset_m = amplitude_value * display_size.y * 0.4

		# Positive
		var lbl_pos = Label3D.new()
		lbl_pos.font_size = 30
		lbl_pos.pixel_size = 0.001
		lbl_pos.no_depth_test = false
		lbl_pos.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl_pos.text = "+%.1f" % amplitude_value
		lbl_pos.modulate = Color(0.8, 1.0, 1.0, 0.9)
		lbl_pos.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl_pos.position = Vector3(0.005, -display_size.y * 0.5 + offset_m, 0.002)
		add_child(lbl_pos)
		_grid_labels.append(lbl_pos)

		# Negative
		var lbl_neg = Label3D.new()
		lbl_neg.font_size = 30
		lbl_neg.pixel_size = 0.001
		lbl_neg.no_depth_test = false
		lbl_neg.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl_neg.text = "-%.1f" % amplitude_value
		lbl_neg.modulate = Color(0.8, 1.0, 1.0, 0.9)
		lbl_neg.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl_neg.position = Vector3(0.005, -display_size.y * 0.5 - offset_m, 0.002)
		add_child(lbl_neg)
		_grid_labels.append(lbl_neg)

	# Time labels
	var time_span = 2.0
	for i in range(6):
		var x = (float(i) / 5.0) * display_size.x
		var time_value = (float(i) / 5.0) * time_span

		var lbl = Label3D.new()
		lbl.font_size = 28
		lbl.pixel_size = 0.001
		lbl.no_depth_test = false
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.text = "%.1fs" % time_value
		lbl.modulate = Color(0.8, 1.0, 1.0, 0.9)
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.position = Vector3(x + 0.002, -display_size.y + 0.005, 0.002)
		add_child(lbl)
		_grid_labels.append(lbl)

func _setup_audio_analysis() -> void:
	"""Setup spectrum analyzer for audio analysis"""
	audio_bus_index = AudioServer.get_bus_index(source_bus)

	if audio_bus_index == -1:
		print("WaveformDisplay: Bus '%s' not found, falling back to Master" % source_bus)
		audio_bus_index = AudioServer.get_bus_index("Master")

	print("WaveformDisplay: Monitoring audio bus '%s' (index %d)" % [source_bus, audio_bus_index])

	# Try to find existing spectrum analyzer first
	for i in range(AudioServer.get_bus_effect_count(audio_bus_index)):
		var effect = AudioServer.get_bus_effect(audio_bus_index, i)
		if effect is AudioEffectSpectrumAnalyzer:
			spectrum_instance = AudioServer.get_bus_effect_instance(audio_bus_index, i) as AudioEffectSpectrumAnalyzerInstance
			print("WaveformDisplay: Connected to existing spectrum analyzer on '%s'" % source_bus)
			return

	print("WaveformDisplay: Creating spectrum analyzer on '%s' bus" % source_bus)
	spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
	spectrum_analyzer.buffer_length = 0.5
	spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
	spectrum_analyzer.tap_back_pos = 0.0
	AudioServer.add_bus_effect(audio_bus_index, spectrum_analyzer)

	var new_effect_count = AudioServer.get_bus_effect_count(audio_bus_index)
	spectrum_instance = AudioServer.get_bus_effect_instance(audio_bus_index, new_effect_count - 1) as AudioEffectSpectrumAnalyzerInstance
	print("WaveformDisplay: Created spectrum analyzer on '%s' bus" % source_bus)

func set_source_bus(bus_name: String) -> void:
	"""Change the audio bus being monitored"""
	source_bus = bus_name
	_audio_setup_done = true
	_setup_audio_analysis()

func _process(delta: float) -> void:
	"""Update waveform data and redraw"""
	if not is_initialized:
		return

	time_offset += delta * time_scale
	_update_waveform_data()
	_update_mesh()

func _update_waveform_data() -> void:
	"""Generate sine wave from spectral values over time"""
	if not spectrum_instance:
		_generate_test_waveform()
		return

	var total_magnitude = 0.0
	var active_bands = 0

	for i in range(sample_count):
		var time_position = float(i) / float(sample_count - 1)
		var freq_index = int((time_position + time_offset * 0.5) * 64.0) % 64
		var freq_hz = (float(freq_index) / 64.0) * 8000.0

		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq_hz, freq_hz + 125.0
		).length()

		total_magnitude += magnitude
		if magnitude > 0.001:
			active_bands += 1

		var boosted_magnitude = magnitude * 50.0
		var db = 20.0 * log(boosted_magnitude) / log(10.0) if boosted_magnitude > 0.0001 else -100.0
		var normalized = clamp((db + 40.0) / 40.0, 0.0, 1.0)
		var baseline = 0.1 + normalized * 0.9

		var sine_phase = time_position * PI * 4.0
		waveform_data[i] = sin(sine_phase + time_offset) * baseline * amplitude_scale

	debug_timer += get_process_delta_time()
	if debug_timer > 2.0:
		debug_timer = 0.0

func _generate_test_waveform() -> void:
	"""Generate test sine wave modulated by fake spectral values"""
	for i in range(sample_count):
		var time_position = float(i) / float(sample_count - 1)
		var fake_freq_index = int((time_position + time_offset * 0.3) * 32.0) % 32
		var fake_magnitude = (sin(time_offset * 2.0 + fake_freq_index * 0.2) + 1.0) * 0.5
		var enhanced_magnitude = 0.3 + fake_magnitude * 0.7
		var sine_phase = time_position * PI * 4.0
		waveform_data[i] = sin(sine_phase + time_offset) * enhanced_magnitude * amplitude_scale

func _update_mesh() -> void:
	"""Render the waveform as ImmediateMesh on XY plane"""
	if not is_initialized:
		return

	_mesh.clear_surfaces()

	# Draw background
	if background_color.a > 0.0:
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_mesh.surface_set_color(background_color)
		_mesh.surface_add_vertex(Vector3(0, 0, 0))
		_mesh.surface_add_vertex(Vector3(display_size.x, 0, 0))
		_mesh.surface_add_vertex(Vector3(display_size.x, -display_size.y, 0))
		_mesh.surface_add_vertex(Vector3(0, 0, 0))
		_mesh.surface_add_vertex(Vector3(display_size.x, -display_size.y, 0))
		_mesh.surface_add_vertex(Vector3(0, -display_size.y, 0))
		_mesh.surface_end()

	# Draw center line
	var center_y = -display_size.y * 0.5
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(Color(0.3, 0.3, 0.3, 0.8))
	_mesh.surface_add_vertex(Vector3(0, center_y, 0.0005))
	_mesh.surface_add_vertex(Vector3(display_size.x, center_y, 0.0005))
	_mesh.surface_end()

	# Draw grid
	_draw_grid_mesh()

	# Draw waveform line with glow
	_draw_waveform_line_mesh()

	# Update info label
	var current_time = fmod(time_offset, 100.0)
	_info_label.text = "Time: %.1fs | Scale: %.1fx | Freq Range: 0-8kHz" % [current_time, time_scale]

func _draw_waveform_line_mesh() -> void:
	"""Draw the main waveform line"""
	if waveform_data.size() < 2:
		return

	var center_y = -display_size.y * 0.5

	# Glow passes + main line
	for glow_pass in range(3):
		var glow_alpha = 0.4 - (glow_pass * 0.15)
		var glow_color = Color(line_color.r, line_color.g, line_color.b, glow_alpha)
		if glow_pass == 2:
			glow_color = line_color

		_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		_mesh.surface_set_color(glow_color)

		for i in range(sample_count - 1):
			var x0 = (float(i) / float(sample_count - 1)) * display_size.x
			var y0_raw = waveform_data[i] * PX_TO_M
			var y0 = clamp(center_y - y0_raw, -display_size.y + 0.005, -0.005)

			var x1 = (float(i + 1) / float(sample_count - 1)) * display_size.x
			var y1_raw = waveform_data[i + 1] * PX_TO_M
			var y1 = clamp(center_y - y1_raw, -display_size.y + 0.005, -0.005)

			_mesh.surface_add_vertex(Vector3(x0, y0, 0.001))
			_mesh.surface_add_vertex(Vector3(x1, y1, 0.001))

		_mesh.surface_end()

func _draw_grid_mesh() -> void:
	"""Draw amplitude and time grid lines"""
	var grid_color = Color(0.2, 0.4, 0.4, 0.5)
	var center_y = -display_size.y * 0.5

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(grid_color)

	# Horizontal grid lines (amplitude)
	for i in range(3):
		var offset_m = (float(i + 1) / 4.0) * display_size.y * 0.4

		# Positive
		var y_pos = center_y + offset_m
		_mesh.surface_add_vertex(Vector3(0, y_pos, 0.0005))
		_mesh.surface_add_vertex(Vector3(display_size.x, y_pos, 0.0005))

		# Negative
		var y_neg = center_y - offset_m
		_mesh.surface_add_vertex(Vector3(0, y_neg, 0.0005))
		_mesh.surface_add_vertex(Vector3(display_size.x, y_neg, 0.0005))

	# Vertical grid lines (time)
	for i in range(6):
		var x = (float(i) / 5.0) * display_size.x
		_mesh.surface_add_vertex(Vector3(x, 0, 0.0005))
		_mesh.surface_add_vertex(Vector3(x, -display_size.y, 0.0005))

	_mesh.surface_end()

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	if _mesh_instance and is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()
	if _title_label and is_instance_valid(_title_label):
		_title_label.queue_free()
	if _info_label and is_instance_valid(_info_label):
		_info_label.queue_free()
	for lbl in _grid_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
