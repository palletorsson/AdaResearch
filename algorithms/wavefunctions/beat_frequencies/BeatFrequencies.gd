extends Node3D

## Beat Frequencies Interactive Demo
## Educational demonstration of interference between close frequencies
##
## Concept: When two frequencies are close (e.g., 440 Hz and 442 Hz),
## they interfere to create a "beat" pattern - periodic loudness variation
## Beat frequency = |f1 - f2| (e.g., |440-442| = 2 Hz = 2 beats per second)
##
## Controls:
## - Slider 1 (left): Frequency 1 (400-500 Hz)
## - Slider 2 (right): Frequency 2 (400-500 Hz)
## - Push Button: Toggle sound on/off
##
## Use case: Tuning instruments - when beats slow down, frequencies are matching

@onready var slider1 = $Slider1/SliderOrigin/InteractableSlider
@onready var slider2 = $Slider2/SliderOrigin/InteractableSlider
@onready var toggle_button = $ToggleButton/InteractableAreaButton
@onready var audio_player = $AudioStreamPlayer3D

# Frequency parameters
var freq1: float = 440.0  # A4 concert pitch
var freq2: float = 442.0  # Slightly sharp
var freq_min: float = 400.0
var freq_max: float = 500.0

# Audio synthesis
var audio_stream: AudioStreamGenerator
var audio_phase1: float = 0.0
var audio_phase2: float = 0.0
const SAMPLE_RATE = 44100.0
var is_playing: bool = false

# Visualization
var waveform_viz: Node3D
var beat_envelope_viz: Node3D
var frequency_labels: Array[Label3D] = []

# Wave visualization arrays
var wave1_points: Array[MeshInstance3D] = []
var wave2_points: Array[MeshInstance3D] = []
var combined_points: Array[MeshInstance3D] = []
const WAVE_RESOLUTION = 64

func _ready() -> void:
	_setup_audio()
	_create_visualizations()
	_setup_controls()
	_update_frequency_labels()
	print("BeatFrequencies: Ready! Move sliders to hear beating")
	print("BeatFrequencies: Current beat frequency = %.2f Hz" % abs(freq1 - freq2))

func _setup_audio() -> void:
	# Create audio stream generator
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1  # 100ms buffer

	audio_player.stream = audio_stream
	audio_player.volume_db = -6.0  # Comfortable listening level
	audio_player.play()
	is_playing = true

	print("BeatFrequencies: Audio synthesis enabled at %.1f Hz" % SAMPLE_RATE)

func _setup_controls() -> void:
	# Setup slider 1
	if slider1:
		slider1.slider_moved.connect(_on_slider1_changed)
		# Set initial value (440 Hz mapped to slider range 0-1)
		var initial1 = inverse_lerp(freq_min, freq_max, freq1)
		slider1.slider_position = initial1

	# Setup slider 2
	if slider2:
		slider2.slider_moved.connect(_on_slider2_changed)
		var initial2 = inverse_lerp(freq_min, freq_max, freq2)
		slider2.slider_position = initial2

	# Setup toggle button
	if toggle_button:
		toggle_button.button_pressed.connect(_on_toggle_pressed)

func _create_visualizations() -> void:
	# Create container nodes
	waveform_viz = Node3D.new()
	waveform_viz.name = "WaveformVisualization"
	waveform_viz.position = Vector3(0, 0, -1.0)
	add_child(waveform_viz)

	beat_envelope_viz = Node3D.new()
	beat_envelope_viz.name = "BeatEnvelope"
	beat_envelope_viz.position = Vector3(0, -1.5, -1.0)
	add_child(beat_envelope_viz)

	# Create waveform visualization points
	for i in range(WAVE_RESOLUTION):
		var x_pos = -2.0 + (i / float(WAVE_RESOLUTION)) * 4.0

		# Wave 1 (red)
		var point1 = _create_wave_point(Vector3(x_pos, 0.5, 0), Color.RED)
		waveform_viz.add_child(point1)
		wave1_points.append(point1)

		# Wave 2 (blue)
		var point2 = _create_wave_point(Vector3(x_pos, 0, 0), Color.BLUE)
		waveform_viz.add_child(point2)
		wave2_points.append(point2)

		# Combined wave (yellow)
		var point_combined = _create_wave_point(Vector3(x_pos, -0.8, 0), Color.YELLOW, 0.06)
		waveform_viz.add_child(point_combined)
		combined_points.append(point_combined)

	# Create beat envelope visualization
	_create_beat_envelope_viz()

	# Create labels
	_create_labels()

func _create_wave_point(pos: Vector3, color: Color, size: float = 0.04) -> MeshInstance3D:
	var point = MeshInstance3D.new()
	var sphere = SphereMesh.new()
	sphere.radius = size
	sphere.height = size * 2.0
	point.mesh = sphere

	var material = StandardMaterial3D.new()
	material.albedo_color = color
	material.emission_enabled = true
	material.emission = color * 0.6
	material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	point.material_override = material

	point.position = pos
	return point

func _create_beat_envelope_viz() -> void:
	# Create visual representation of beat envelope
	for i in range(32):
		var x_pos = -2.0 + (i / 32.0) * 4.0
		var bar = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.1, 0.5, 0.05)
		bar.mesh = box

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0, 1, 0.5, 0.7)
		material.emission_enabled = true
		material.emission = Color(0, 0.5, 0.25, 1)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		bar.material_override = material

		bar.position = Vector3(x_pos, 0, 0)
		beat_envelope_viz.add_child(bar)

func _create_labels() -> void:
	# Title label
	var title = Label3D.new()
	title.text = "Beat Frequencies"
	title.position = Vector3(0, 1.5, -1.0)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 1)
	title.outline_size = 4
	title.outline_modulate = Color(0, 0, 0, 1)
	add_child(title)

	# Frequency 1 label
	var label1 = Label3D.new()
	label1.text = "F1: 440.0 Hz"
	label1.position = Vector3(-1.0, 1.0, -1.0)
	label1.font_size = 20
	label1.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label1.modulate = Color(1, 0.3, 0.3, 1)
	label1.outline_size = 3
	label1.outline_modulate = Color(0, 0, 0, 1)
	add_child(label1)
	frequency_labels.append(label1)

	# Frequency 2 label
	var label2 = Label3D.new()
	label2.text = "F2: 442.0 Hz"
	label2.position = Vector3(1.0, 1.0, -1.0)
	label2.font_size = 20
	label2.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label2.modulate = Color(0.3, 0.3, 1, 1)
	label2.outline_size = 3
	label2.outline_modulate = Color(0, 0, 0, 1)
	add_child(label2)
	frequency_labels.append(label2)

	# Beat frequency label
	var beat_label = Label3D.new()
	beat_label.text = "Beat: 2.0 Hz"
	beat_label.position = Vector3(0, 0.5, -1.0)
	beat_label.font_size = 24
	beat_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	beat_label.modulate = Color(1, 1, 0, 1)
	beat_label.outline_size = 4
	beat_label.outline_modulate = Color(0, 0, 0, 1)
	add_child(beat_label)
	frequency_labels.append(beat_label)

	# Educational hint
	var hint = Label3D.new()
	hint.text = "Slow beats = frequencies match (tuning)"
	hint.position = Vector3(0, -2.0, -1.0)
	hint.font_size = 16
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.modulate = Color(0.7, 0.7, 0.7, 0.9)
	hint.outline_size = 2
	hint.outline_modulate = Color(0, 0, 0, 1)
	add_child(hint)

func _update_frequency_labels() -> void:
	if frequency_labels.size() >= 3:
		frequency_labels[0].text = "F1: %.1f Hz" % freq1
		frequency_labels[1].text = "F2: %.1f Hz" % freq2
		var beat_freq = abs(freq1 - freq2)
		frequency_labels[2].text = "Beat: %.2f Hz" % beat_freq

		# Color code beat label based on how close frequencies are
		if beat_freq < 1.0:
			frequency_labels[2].modulate = Color(0, 1, 0, 1)  # Green - very close
		elif beat_freq < 5.0:
			frequency_labels[2].modulate = Color(1, 1, 0, 1)  # Yellow - close
		else:
			frequency_labels[2].modulate = Color(1, 0.5, 0, 1)  # Orange - far apart

func _on_slider1_changed(value: float) -> void:
	# Map slider value (0-1) to frequency range
	freq1 = lerp(freq_min, freq_max, value)
	_update_frequency_labels()
	print("BeatFrequencies: F1 = %.1f Hz, Beat = %.2f Hz" % [freq1, abs(freq1 - freq2)])

func _on_slider2_changed(value: float) -> void:
	freq2 = lerp(freq_min, freq_max, value)
	_update_frequency_labels()
	print("BeatFrequencies: F2 = %.1f Hz, Beat = %.2f Hz" % [freq2, abs(freq1 - freq2)])

func _on_toggle_pressed() -> void:
	is_playing = !is_playing
	print("BeatFrequencies: Sound %s" % ("ON" if is_playing else "OFF"))

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta

	# Generate audio samples
	if is_playing:
		_generate_audio_samples()

	# Update visualizations
	_update_waveform_visualization()
	_update_beat_envelope()

func _generate_audio_samples() -> void:
	if not audio_player or not audio_player.playing:
		return

	var playback = audio_player.get_stream_playback()
	if not playback:
		return

	var frames_available = playback.get_frames_available()
	if frames_available < 256:
		return

	var frames_to_fill = min(frames_available, 256)

	for _frame in range(frames_to_fill):
		# Generate two sine waves
		var sample1 = sin(audio_phase1)
		var sample2 = sin(audio_phase2)

		# Combine (superposition)
		var combined = (sample1 + sample2) * 0.4  # Scale down to prevent clipping

		# Clamp
		combined = clamp(combined, -1.0, 1.0)

		# Push stereo sample
		playback.push_frame(Vector2(combined, combined))

		# Update phases
		audio_phase1 += freq1 * TAU / SAMPLE_RATE
		audio_phase2 += freq2 * TAU / SAMPLE_RATE

		# Wrap phases
		if audio_phase1 > TAU:
			audio_phase1 -= TAU
		if audio_phase2 > TAU:
			audio_phase2 -= TAU

func _update_waveform_visualization() -> void:
	# Safety check - make sure visualization is created
	if wave1_points.size() != WAVE_RESOLUTION or wave2_points.size() != WAVE_RESOLUTION or combined_points.size() != WAVE_RESOLUTION:
		return

	# Visualize the two waves and their combination
	for i in range(WAVE_RESOLUTION):
		var x_normalized = i / float(WAVE_RESOLUTION)
		var phase = x_normalized * TAU * 4.0 + time * 2.0  # Show 4 cycles

		# Wave 1
		var val1 = sin(phase)
		wave1_points[i].position.y = 0.5 + val1 * 0.3

		# Wave 2 (slightly different frequency creates the visible beat pattern)
		var freq_ratio = freq2 / freq1
		var val2 = sin(phase * freq_ratio)
		wave2_points[i].position.y = 0.0 + val2 * 0.3

		# Combined wave (shows interference)
		var combined = (val1 + val2) * 0.5
		combined_points[i].position.y = -0.8 + combined * 0.3

		# Pulse size based on amplitude
		var scale1 = 0.7 + abs(val1) * 0.3
		wave1_points[i].scale = Vector3.ONE * scale1

		var scale2 = 0.7 + abs(val2) * 0.3
		wave2_points[i].scale = Vector3.ONE * scale2

		var scale_combined = 0.8 + abs(combined) * 0.4
		combined_points[i].scale = Vector3.ONE * scale_combined

func _update_beat_envelope() -> void:
	# Visualize the beat envelope (amplitude modulation)
	var beat_freq = abs(freq1 - freq2)
	if beat_freq < 0.01:
		beat_freq = 0.01  # Avoid division by zero

	for i in range(beat_envelope_viz.get_child_count()):
		var bar = beat_envelope_viz.get_child(i) as MeshInstance3D
		if bar:
			var x_normalized = i / float(beat_envelope_viz.get_child_count())

			# Beat envelope: amplitude = 2 * |cos(pi * beat_freq * t)|
			var envelope_phase = x_normalized * beat_freq * 8.0 + time * beat_freq
			var envelope = abs(cos(envelope_phase * PI))

			# Scale bar height
			var height = 0.2 + envelope * 0.8
			var mesh = bar.mesh as BoxMesh
			if mesh:
				mesh.size.y = height
				bar.position.y = height / 2.0

			# Color based on envelope
			var material = bar.material_override as StandardMaterial3D
			if material:
				var brightness = 0.3 + envelope * 0.7
				material.albedo_color = Color(0, brightness, brightness * 0.5, 0.7)
				material.emission = Color(0, brightness * 0.5, brightness * 0.25, 1)

# Public API for saving parameters

func get_audio_parameters() -> Dictionary:
	return {
		"freq1": freq1,
		"freq2": freq2,
		"freq_min": freq_min,
		"freq_max": freq_max,
		"beat_frequency": abs(freq1 - freq2),
		"is_playing": is_playing
	}

func save_to_json(file_path: String) -> void:
	var params = get_audio_parameters()
	var json_string = JSON.stringify(params, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("BeatFrequencies: Saved parameters to %s" % file_path)
	else:
		push_error("BeatFrequencies: Failed to save parameters")

func load_from_json(file_path: String) -> void:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_string)
		if parse_result == OK:
			var params = json.data
			freq1 = params.get("freq1", freq1)
			freq2 = params.get("freq2", freq2)
			freq_min = params.get("freq_min", freq_min)
			freq_max = params.get("freq_max", freq_max)
			_update_frequency_labels()
			print("BeatFrequencies: Loaded parameters from %s" % file_path)
		else:
			push_error("BeatFrequencies: Failed to parse JSON")
	else:
		push_error("BeatFrequencies: Failed to load parameters")
