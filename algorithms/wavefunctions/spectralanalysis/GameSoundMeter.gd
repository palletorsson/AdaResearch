# GameSoundMeter.gd - Universal sound meter system for game objects (VR/3D)
extends Node3D
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

enum DisplayStyle {
	SPECTRUM_LINE,      # Green line spectrum
	SPECTRUM_BARS,      # Individual bars
	WAVEFORM,          # Time-domain waveform
	VU_METER,          # Simple level meter
	OSCILLOSCOPE       # Detailed waveform
}

# Panel size in meters (was ~500px Control, now 0.5m x 0.3m)
const PANEL_SIZE := Vector3(0.5, 0.3, 0.0)
const PX_TO_M := 0.5 / 500.0  # Pixel-to-meter ratio

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
var meter_size: Vector2  # In meters
var is_initialized: bool = false

# ImmediateMesh rendering
var _mesh: ImmediateMesh
var _mesh_instance: MeshInstance3D

# Label3D nodes for text
var _title_label: Label3D
var _info_label: Label3D
var _no_audio_label: Label3D
var _freq_labels: Array[Label3D] = []
var _amp_labels: Array[Label3D] = []

func _ready() -> void:
	_initialize_meter()
	_setup_audio_analysis()
	_find_game_objects()
	_setup_mesh()
	_setup_labels()

	print("GameSoundMeter: Initialized - Style: %s, Bars: %d, FPS: %.1f" % [
		DisplayStyle.keys()[display_style], bar_count, update_fps
	])

func _initialize_meter() -> void:
	"""Initialize the meter arrays and settings"""
	frequency_data.resize(bar_count)
	smoothed_data.resize(bar_count)
	peak_levels.resize(bar_count)

	frequency_data.fill(0.0)
	smoothed_data.fill(0.0)
	peak_levels.fill(0.0)

	update_interval = 1.0 / update_fps
	meter_size = Vector2(PANEL_SIZE.x, PANEL_SIZE.y)
	bar_width = meter_size.x / float(bar_count)
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
	_info_label.position = Vector3(0.01, -0.04, 0.002)
	_info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	_info_label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	add_child(_info_label)

	# No audio label (hidden by default)
	_no_audio_label = Label3D.new()
	_no_audio_label.font_size = 56
	_no_audio_label.pixel_size = 0.001
	_no_audio_label.no_depth_test = false
	_no_audio_label.billboard = BaseMaterial3D.BILLBOARD_DISABLED
	_no_audio_label.text = "NO AUDIO - TEST PATTERN"
	_no_audio_label.modulate = Color.WHITE
	_no_audio_label.position = Vector3(meter_size.x * 0.5, -meter_size.y * 0.5, 0.002)
	_no_audio_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_no_audio_label.visible = false
	add_child(_no_audio_label)

	# Frequency labels (for spectrum grid)
	var freq_marks = [20, 100, 1000, 5000, 20000]
	for i in range(freq_marks.size()):
		var freq_hz = freq_marks[i]
		var freq_ratio = log(freq_hz / 20.0) / log(1000.0)
		var x = freq_ratio * meter_size.x

		var lbl = Label3D.new()
		lbl.font_size = 30
		lbl.pixel_size = 0.001
		lbl.no_depth_test = false
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.modulate = Color(0.8, 1.0, 0.8, 0.9)
		lbl.position = Vector3(x + 0.002, -meter_size.y + 0.005, 0.002)

		if freq_hz < 1000:
			lbl.text = "%d Hz" % freq_hz
		else:
			lbl.text = "%.1f kHz" % (freq_hz / 1000.0)

		add_child(lbl)
		_freq_labels.append(lbl)

	# Amplitude labels
	for i in range(4):
		var amplitude = 1.0 - (float(i + 1) / 5.0)
		var y = -(float(i + 1) / 5.0) * meter_size.y

		var lbl = Label3D.new()
		lbl.font_size = 30
		lbl.pixel_size = 0.001
		lbl.no_depth_test = false
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		lbl.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
		lbl.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		lbl.modulate = Color(0.8, 1.0, 0.8, 0.9)
		lbl.text = "%.1f" % amplitude
		lbl.position = Vector3(0.005, y - 0.002, 0.002)
		add_child(lbl)
		_amp_labels.append(lbl)

func _setup_audio_analysis() -> void:
	"""Setup spectrum analyzer for the target audio source"""
	if monitor_master_bus:
		var master_bus_index = AudioServer.get_bus_index("Master")

		spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
		spectrum_analyzer.buffer_length = 2.0
		spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_2048
		spectrum_analyzer.tap_back_pos = 0.0

		AudioServer.add_bus_effect(master_bus_index, spectrum_analyzer)
		var effect_count = AudioServer.get_bus_effect_count(master_bus_index)
		spectrum_instance = AudioServer.get_bus_effect_instance(master_bus_index, effect_count - 1) as AudioEffectSpectrumAnalyzerInstance

		print("GameSoundMeter: Monitoring Master Bus - analyzing ALL game audio")
	else:
		var bus_name = "GameSoundMeter_Analysis"
		var bus_index = AudioServer.get_bus_index(bus_name)

		if bus_index == -1:
			AudioServer.add_bus()
			bus_index = AudioServer.get_bus_count() - 1
			AudioServer.set_bus_name(bus_index, bus_name)
			AudioServer.set_bus_send(bus_index, "Master")

		spectrum_analyzer = AudioEffectSpectrumAnalyzer.new()
		spectrum_analyzer.buffer_length = 1.0
		spectrum_analyzer.fft_size = AudioEffectSpectrumAnalyzer.FFT_SIZE_1024
		spectrum_analyzer.tap_back_pos = 0.0

		AudioServer.add_bus_effect(bus_index, spectrum_analyzer)
		spectrum_instance = AudioServer.get_bus_effect_instance(bus_index, 0) as AudioEffectSpectrumAnalyzerInstance

		if target_audio_player:
			target_audio_player.bus = bus_name
			print("GameSoundMeter: Connected audio player to analysis bus")

func _find_game_objects() -> void:
	"""Auto-find teleport cube and audio components"""
	if auto_find_teleport_audio:
		var teleport_nodes = get_tree().get_nodes_in_group("teleport")
		if teleport_nodes.is_empty():
			teleport_nodes = [get_tree().current_scene.find_child("*Teleport*", true, false)]

		for node in teleport_nodes:
			if node:
				var audio_player = node.find_child("TeleportAudio", true, false)
				if audio_player and audio_player is Node3D:
					for child in audio_player.get_children():
						if child is AudioStreamPlayer3D:
							target_audio_player = child
							teleport_cube_node = node
							_setup_audio_analysis()
							print("GameSoundMeter: Auto-found teleport audio: %s" % child.name)
							break

	var cameras = [
		get_tree().get_first_node_in_group("player_camera"),
		get_tree().current_scene.find_child("Camera3D", true, false),
		get_tree().current_scene.find_child("*Player*", true, false)
	]

	for cam in cameras:
		if cam and cam is Camera3D:
			player_camera = cam
			break

func _process(delta: float) -> void:
	if not is_initialized or not spectrum_instance:
		return

	# Performance culling
	if enable_distance_culling and _should_cull_update():
		frame_skip_counter += 1
		if frame_skip_counter < 30:
			return
		frame_skip_counter = 0

	# Update at specified rate
	update_timer += delta
	if update_timer >= update_interval:
		update_timer = 0.0
		_update_audio_data()

	# Smooth the data
	_smooth_audio_data(delta)

	# Update 3D mesh
	_update_mesh()

func _should_cull_update() -> bool:
	"""Check if we should skip updates for performance"""
	if not player_camera or not target_audio_player:
		return false

	var distance = player_camera.global_position.distance_to(target_audio_player.global_position)
	return distance > max_display_distance

func _update_audio_data() -> void:
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

func _update_spectrum_data() -> void:
	"""Update frequency spectrum data"""
	for i in range(bar_count):
		var freq_ratio = float(i) / float(bar_count - 1)
		var freq_hz = 20.0 * pow(1000.0, freq_ratio)

		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq_hz, freq_hz + max(100.0, freq_hz * 0.1)
		).length()

		var db = 20.0 * log(magnitude) / log(10.0) if magnitude > 0.0 else -80.0
		var normalized = clamp((db + 50.0) / 50.0, 0.0, 1.0)

		if i < bar_count * 0.3:
			normalized = normalized * 2.0

		frequency_data[i] = normalized
		peak_levels[i] = max(peak_levels[i] * 0.95, normalized)

func _update_vu_data() -> void:
	"""Update VU meter data"""
	var total_magnitude = 0.0
	for i in range(10):
		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			i * 200.0, (i + 1) * 200.0
		).length()
		total_magnitude += magnitude

	var avg_magnitude = total_magnitude / 10.0
	var db = 20.0 * log(avg_magnitude) / log(10.0) if avg_magnitude > 0.0 else -80.0
	var normalized = clamp((db + 60.0) / 60.0, 0.0, 1.0)

	frequency_data[0] = normalized

func _update_waveform_data() -> void:
	"""Update waveform data (simplified)"""
	for i in range(bar_count):
		var freq_ratio = float(i) / float(bar_count - 1)
		var freq_hz = freq_ratio * 4000.0

		var magnitude = spectrum_instance.get_magnitude_for_frequency_range(
			freq_hz, freq_hz + 50.0
		).length()

		frequency_data[i] = magnitude * 100.0

func _smooth_audio_data(delta: float) -> void:
	"""Apply smoothing to audio data"""
	var smooth_speed = 1.0 - pow(smoothing_factor, delta * 60.0)

	for i in range(bar_count):
		smoothed_data[i] = lerp(smoothed_data[i], frequency_data[i], smooth_speed)

func _update_mesh() -> void:
	"""Render the sound meter as ImmediateMesh on XY plane"""
	if not is_initialized:
		return

	_mesh.clear_surfaces()

	# Draw background
	if background_color.a > 0.0:
		_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
		_mesh.surface_set_color(background_color)
		_mesh.surface_add_vertex(Vector3(0, 0, 0))
		_mesh.surface_add_vertex(Vector3(meter_size.x, 0, 0))
		_mesh.surface_add_vertex(Vector3(meter_size.x, -meter_size.y, 0))
		_mesh.surface_add_vertex(Vector3(0, 0, 0))
		_mesh.surface_add_vertex(Vector3(meter_size.x, -meter_size.y, 0))
		_mesh.surface_add_vertex(Vector3(0, -meter_size.y, 0))
		_mesh.surface_end()

	# If no spectrum instance, show test pattern
	if not spectrum_instance:
		_draw_test_pattern_mesh()
		_no_audio_label.visible = true
		_title_label.visible = false
		_info_label.visible = false
		return
	else:
		_no_audio_label.visible = false

	match display_style:
		DisplayStyle.SPECTRUM_LINE:
			_draw_spectrum_line_mesh()
		DisplayStyle.SPECTRUM_BARS:
			_draw_spectrum_bars_mesh()
		DisplayStyle.VU_METER:
			_draw_vu_meter_mesh()
		DisplayStyle.WAVEFORM:
			_draw_waveform_mesh()
		DisplayStyle.OSCILLOSCOPE:
			_draw_oscilloscope_mesh()

func _draw_spectrum_line_mesh() -> void:
	"""Draw spectrum as connected line with grid"""
	if smoothed_data.size() < 2:
		return

	var padding = 0.01  # 10px -> 0.01m
	var draw_x = padding
	var draw_y = -padding
	var draw_w = meter_size.x - padding * 2
	var draw_h = meter_size.y - padding * 2

	# Draw grid lines
	_draw_spectrum_grid_mesh(draw_x, draw_y, draw_w, draw_h)

	# Draw spectrum line with glow passes
	for glow_pass in range(3):
		var glow_alpha = 0.3 - (glow_pass * 0.1)
		var glow_color = Color(line_color.r, line_color.g, line_color.b, glow_alpha)
		if glow_pass == 2:
			glow_color = line_color  # Main line is solid

		_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
		_mesh.surface_set_color(glow_color)

		for i in range(bar_count - 1):
			var x0 = draw_x + (float(i) / float(bar_count - 1)) * draw_w
			var y0 = draw_y - draw_h + smoothed_data[i] * (draw_h - padding)
			var x1 = draw_x + (float(i + 1) / float(bar_count - 1)) * draw_w
			var y1 = draw_y - draw_h + smoothed_data[i + 1] * (draw_h - padding)

			_mesh.surface_add_vertex(Vector3(x0, y0, 0.001))
			_mesh.surface_add_vertex(Vector3(x1, y1, 0.001))

		_mesh.surface_end()

	# Update labels
	_title_label.text = "FREQUENCY SPECTRUM"
	_title_label.modulate = Color(0, 1, 0, 1)
	_title_label.visible = true

	_info_label.text = "Range: 20Hz-20kHz | Bars: %d | Log Scale | Master Bus" % bar_count
	_info_label.modulate = Color(0.7, 0.9, 0.7, 0.8)
	_info_label.visible = true

func _draw_spectrum_grid_mesh(draw_x: float, draw_y: float, draw_w: float, draw_h: float) -> void:
	"""Draw grid lines for spectrum display"""
	var grid_color = Color(0.2, 0.5, 0.2, 0.6)

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(grid_color)

	# Horizontal grid lines
	for i in range(4):
		var y = draw_y - (float(i + 1) / 5.0) * draw_h
		_mesh.surface_add_vertex(Vector3(draw_x, y, 0.0005))
		_mesh.surface_add_vertex(Vector3(draw_x + draw_w, y, 0.0005))

	# Vertical grid lines (frequency marks)
	var freq_marks = [20, 100, 1000, 5000, 20000]
	for freq_hz in freq_marks:
		var freq_ratio = log(freq_hz / 20.0) / log(1000.0)
		var x = draw_x + freq_ratio * draw_w
		_mesh.surface_add_vertex(Vector3(x, draw_y, 0.0005))
		_mesh.surface_add_vertex(Vector3(x, draw_y - draw_h, 0.0005))

	_mesh.surface_end()

func _draw_spectrum_bars_mesh() -> void:
	"""Draw spectrum as individual bars"""
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(bar_count):
		var x = i * bar_width
		var height = smoothed_data[i] * height_multiplier * PX_TO_M
		var y = -meter_size.y
		var w = bar_width * 0.8

		# Bar rect (two triangles)
		_mesh.surface_set_color(line_color)
		_mesh.surface_add_vertex(Vector3(x, y, 0.001))
		_mesh.surface_add_vertex(Vector3(x + w, y, 0.001))
		_mesh.surface_add_vertex(Vector3(x + w, y + height, 0.001))
		_mesh.surface_add_vertex(Vector3(x, y, 0.001))
		_mesh.surface_add_vertex(Vector3(x + w, y + height, 0.001))
		_mesh.surface_add_vertex(Vector3(x, y + height, 0.001))

	_mesh.surface_end()

	# Peak hold lines
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(Color.WHITE)
	for i in range(bar_count):
		var x = i * bar_width
		var peak_y = -meter_size.y + peak_levels[i] * height_multiplier * PX_TO_M
		_mesh.surface_add_vertex(Vector3(x, peak_y, 0.0015))
		_mesh.surface_add_vertex(Vector3(x + bar_width * 0.8, peak_y, 0.0015))
	_mesh.surface_end()

func _draw_vu_meter_mesh() -> void:
	"""Draw VU style meter"""
	var level = smoothed_data[0] if smoothed_data.size() > 0 else 0.0
	var fill_width = level * meter_size.x

	# Background
	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	_mesh.surface_set_color(Color(0.2, 0.2, 0.2, 1.0))
	_mesh.surface_add_vertex(Vector3(0, 0, 0.001))
	_mesh.surface_add_vertex(Vector3(meter_size.x, 0, 0.001))
	_mesh.surface_add_vertex(Vector3(meter_size.x, -meter_size.y, 0.001))
	_mesh.surface_add_vertex(Vector3(0, 0, 0.001))
	_mesh.surface_add_vertex(Vector3(meter_size.x, -meter_size.y, 0.001))
	_mesh.surface_add_vertex(Vector3(0, -meter_size.y, 0.001))

	# Level fill
	var level_color = Color.GREEN if level < 0.7 else (Color.YELLOW if level < 0.9 else Color.RED)
	_mesh.surface_set_color(level_color)
	_mesh.surface_add_vertex(Vector3(0, 0, 0.002))
	_mesh.surface_add_vertex(Vector3(fill_width, 0, 0.002))
	_mesh.surface_add_vertex(Vector3(fill_width, -meter_size.y, 0.002))
	_mesh.surface_add_vertex(Vector3(0, 0, 0.002))
	_mesh.surface_add_vertex(Vector3(fill_width, -meter_size.y, 0.002))
	_mesh.surface_add_vertex(Vector3(0, -meter_size.y, 0.002))
	_mesh.surface_end()

func _draw_waveform_mesh() -> void:
	"""Draw waveform representation"""
	var center_y = -meter_size.y * 0.5

	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(line_color)

	for i in range(bar_count - 1):
		var x0 = (float(i) / float(bar_count - 1)) * meter_size.x
		var amplitude0 = smoothed_data[i] * meter_size.y * 0.4
		var y0 = center_y + sin(float(i) * 0.5) * amplitude0 * PX_TO_M

		var x1 = (float(i + 1) / float(bar_count - 1)) * meter_size.x
		var amplitude1 = smoothed_data[i + 1] * meter_size.y * 0.4
		var y1 = center_y + sin(float(i + 1) * 0.5) * amplitude1 * PX_TO_M

		_mesh.surface_add_vertex(Vector3(x0, y0, 0.001))
		_mesh.surface_add_vertex(Vector3(x1, y1, 0.001))

	_mesh.surface_end()

func _draw_oscilloscope_mesh() -> void:
	"""Draw oscilloscope style display"""
	var grid_color = Color(0, 0.3, 0, 0.5)

	# Draw grid
	_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	_mesh.surface_set_color(grid_color)
	for i in range(5):
		var y = -(float(i) / 4.0) * meter_size.y
		_mesh.surface_add_vertex(Vector3(0, y, 0.0005))
		_mesh.surface_add_vertex(Vector3(meter_size.x, y, 0.0005))
	_mesh.surface_end()

	# Waveform on top
	_draw_waveform_mesh()

func _draw_test_pattern_mesh() -> void:
	"""Draw a test pattern when no audio is available"""
	var time = Time.get_time_dict_from_system()
	var seconds = time.second + time.minute * 60.0

	_mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)

	for i in range(bar_count):
		var x = i * bar_width
		var height = (sin(seconds * 2.0 + i * 0.3) * 0.5 + 0.5) * height_multiplier * 0.5 * PX_TO_M
		var y = -meter_size.y
		var w = bar_width * 0.8

		var color = Color(0.5, 1.0, 0.5, 0.8)
		_mesh.surface_set_color(color)
		_mesh.surface_add_vertex(Vector3(x, y, 0.001))
		_mesh.surface_add_vertex(Vector3(x + w, y, 0.001))
		_mesh.surface_add_vertex(Vector3(x + w, y + height, 0.001))
		_mesh.surface_add_vertex(Vector3(x, y, 0.001))
		_mesh.surface_add_vertex(Vector3(x + w, y + height, 0.001))
		_mesh.surface_add_vertex(Vector3(x, y + height, 0.001))

	_mesh.surface_end()

# Public API
func set_audio_target(player: AudioStreamPlayer3D) -> void:
	"""Set the target audio player"""
	target_audio_player = player
	_setup_audio_analysis()

func set_display_style(style: DisplayStyle) -> void:
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

func apply_grid_config(config: Dictionary) -> void:
	pass

func _exit_tree() -> void:
	if _mesh_instance and is_instance_valid(_mesh_instance):
		_mesh_instance.queue_free()
	for lbl in _freq_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	for lbl in _amp_labels:
		if is_instance_valid(lbl):
			lbl.queue_free()
	if _title_label and is_instance_valid(_title_label):
		_title_label.queue_free()
	if _info_label and is_instance_valid(_info_label):
		_info_label.queue_free()
	if _no_audio_label and is_instance_valid(_no_audio_label):
		_no_audio_label.queue_free()
