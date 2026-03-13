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
##
## OPTIMIZED: Uses WavefunctionResources + MultiMesh (224 nodes → 4 nodes)

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

# Visualization - MultiMesh containers
var waveform_viz: Node3D
var beat_envelope_viz: Node3D
var frequency_labels: Array[Label3D] = []

# MultiMesh instances (replaces 224 individual MeshInstance3D)
var wave1_multimesh: MultiMeshInstance3D
var wave2_multimesh: MultiMeshInstance3D
var combined_multimesh: MultiMeshInstance3D
var envelope_multimesh: MultiMeshInstance3D

const WAVE_RESOLUTION = 64
const ENVELOPE_BARS = 32

func _ready() -> void:
	_setup_audio()
	_create_visualizations()
	_setup_controls()
	_update_frequency_labels()
	print("BeatFrequencies: Ready! Move sliders to hear beating (Optimized)")
	print("BeatFrequencies: Current beat frequency = %.2f Hz" % abs(freq1 - freq2))

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1

	audio_player.stream = audio_stream
	audio_player.volume_db = -6.0
	audio_player.play()
	is_playing = true

	print("BeatFrequencies: Audio synthesis enabled at %.1f Hz" % SAMPLE_RATE)

func _setup_controls() -> void:
	if slider1:
		slider1.slider_moved.connect(_on_slider1_changed)
		var initial1 = inverse_lerp(freq_min, freq_max, freq1)
		slider1.slider_position = initial1

	if slider2:
		slider2.slider_moved.connect(_on_slider2_changed)
		var initial2 = inverse_lerp(freq_min, freq_max, freq2)
		slider2.slider_position = initial2

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

	# OPTIMIZED: Create MultiMesh waveforms instead of individual spheres
	_create_wave_multimesh()
	_create_beat_envelope_multimesh()
	_create_labels()

	print("BeatFrequencies: Using MultiMesh (4 nodes instead of 224)")

func _create_wave_multimesh() -> void:
	var wave_sphere = SphereMesh.new()
	wave_sphere.radius = 0.04
	wave_sphere.height = 0.08
	wave_sphere.radial_segments = 8
	wave_sphere.rings = 4
	
	# Wave 1 (red)
	wave1_multimesh = MultiMeshInstance3D.new()
	wave1_multimesh.name = "Wave1MultiMesh"
	var mm1 = MultiMesh.new()
	mm1.transform_format = MultiMesh.TRANSFORM_3D
	mm1.use_colors = false
	mm1.instance_count = WAVE_RESOLUTION
	mm1.mesh = wave_sphere
	wave1_multimesh.multimesh = mm1
	wave1_multimesh.material_override = WavefunctionResources.get_emissive_material(Color.RED, 1.0, 0.6)
	_init_wave_positions(mm1, 0.5)
	waveform_viz.add_child(wave1_multimesh)
	
	# Wave 2 (blue)
	wave2_multimesh = MultiMeshInstance3D.new()
	wave2_multimesh.name = "Wave2MultiMesh"
	var mm2 = MultiMesh.new()
	mm2.transform_format = MultiMesh.TRANSFORM_3D
	mm2.use_colors = false
	mm2.instance_count = WAVE_RESOLUTION
	mm2.mesh = wave_sphere
	wave2_multimesh.multimesh = mm2
	wave2_multimesh.material_override = WavefunctionResources.get_emissive_material(Color.BLUE, 1.0, 0.6)
	_init_wave_positions(mm2, 0.0)
	waveform_viz.add_child(wave2_multimesh)
	
	# Combined wave (yellow, slightly larger)
	var combined_sphere = SphereMesh.new()
	combined_sphere.radius = 0.06
	combined_sphere.height = 0.12
	combined_sphere.radial_segments = 8
	combined_sphere.rings = 4
	
	combined_multimesh = MultiMeshInstance3D.new()
	combined_multimesh.name = "CombinedMultiMesh"
	var mm3 = MultiMesh.new()
	mm3.transform_format = MultiMesh.TRANSFORM_3D
	mm3.use_colors = false
	mm3.instance_count = WAVE_RESOLUTION
	mm3.mesh = combined_sphere
	combined_multimesh.multimesh = mm3
	combined_multimesh.material_override = WavefunctionResources.get_emissive_material(Color.YELLOW, 1.0, 0.6)
	_init_wave_positions(mm3, -0.8)
	waveform_viz.add_child(combined_multimesh)

func _init_wave_positions(mm: MultiMesh, y_base: float) -> void:
	for i in range(WAVE_RESOLUTION):
		var x_pos = -2.0 + (float(i) / float(WAVE_RESOLUTION)) * 4.0
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x_pos, y_base, 0)))

func _create_beat_envelope_multimesh() -> void:
	# Create bar mesh for envelope visualization
	var bar_mesh = BoxMesh.new()
	bar_mesh.size = Vector3(0.1, 0.5, 0.05)
	
	envelope_multimesh = MultiMeshInstance3D.new()
	envelope_multimesh.name = "EnvelopeMultiMesh"
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = ENVELOPE_BARS
	mm.mesh = bar_mesh
	envelope_multimesh.multimesh = mm
	
	# Use vertex colors for per-bar coloring
	var mat = StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.emission_enabled = true
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	envelope_multimesh.material_override = mat
	
	# Initialize bar positions
	for i in range(ENVELOPE_BARS):
		var x_pos = -2.0 + (float(i) / float(ENVELOPE_BARS)) * 4.0
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x_pos, 0.25, 0)))
		mm.set_instance_color(i, Color(0, 1, 0.5, 0.7))
	
	beat_envelope_viz.add_child(envelope_multimesh)

func _create_labels() -> void:
	var title = Label3D.new()
	title.text = "Beat Frequencies"
	title.position = Vector3(0, 1.5, -1.0)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 1)
	title.outline_size = 4
	title.outline_modulate = Color(0, 0, 0, 1)
	add_child(title)

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

		if beat_freq < 1.0:
			frequency_labels[2].modulate = Color(0, 1, 0, 1)
		elif beat_freq < 5.0:
			frequency_labels[2].modulate = Color(1, 1, 0, 1)
		else:
			frequency_labels[2].modulate = Color(1, 0.5, 0, 1)

func _on_slider1_changed(value: float) -> void:
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

	if is_playing:
		_generate_audio_samples()

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
		# Generate two sine waves using lookup table
		var phase1 = fposmod(audio_phase1 / TAU, 1.0)
		var phase2 = fposmod(audio_phase2 / TAU, 1.0)
		var sample1 = WavefunctionResources.fast_sine(phase1)
		var sample2 = WavefunctionResources.fast_sine(phase2)

		var combined = (sample1 + sample2) * 0.4
		combined = clamp(combined, -1.0, 1.0)

		playback.push_frame(Vector2(combined, combined))

		audio_phase1 += freq1 * TAU / SAMPLE_RATE
		audio_phase2 += freq2 * TAU / SAMPLE_RATE

		if audio_phase1 > TAU:
			audio_phase1 -= TAU
		if audio_phase2 > TAU:
			audio_phase2 -= TAU

func _update_waveform_visualization() -> void:
	if not wave1_multimesh or not wave2_multimesh or not combined_multimesh:
		return
	
	var mm1 = wave1_multimesh.multimesh
	var mm2 = wave2_multimesh.multimesh
	var mm3 = combined_multimesh.multimesh
	
	for i in range(WAVE_RESOLUTION):
		var x_pos = -2.0 + (float(i) / float(WAVE_RESOLUTION)) * 4.0
		var x_normalized = float(i) / float(WAVE_RESOLUTION)
		var phase = x_normalized * TAU * 4.0 + time * 2.0

		# Wave 1
		var val1 = sin(phase)
		var y1 = 0.5 + val1 * 0.3
		var scale1 = 0.7 + abs(val1) * 0.3
		mm1.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * scale1), Vector3(x_pos, y1, 0)))

		# Wave 2 (different frequency ratio)
		var freq_ratio = freq2 / freq1
		var val2 = sin(phase * freq_ratio)
		var y2 = 0.0 + val2 * 0.3
		var scale2 = 0.7 + abs(val2) * 0.3
		mm2.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * scale2), Vector3(x_pos, y2, 0)))

		# Combined wave
		var combined_val = (val1 + val2) * 0.5
		var y3 = -0.8 + combined_val * 0.3
		var scale3 = 0.8 + abs(combined_val) * 0.4
		mm3.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * scale3), Vector3(x_pos, y3, 0)))

func _update_beat_envelope() -> void:
	if not envelope_multimesh:
		return
	
	var mm = envelope_multimesh.multimesh
	var beat_freq = abs(freq1 - freq2)
	if beat_freq < 0.01:
		beat_freq = 0.01

	for i in range(ENVELOPE_BARS):
		var x_pos = -2.0 + (float(i) / float(ENVELOPE_BARS)) * 4.0
		var x_normalized = float(i) / float(ENVELOPE_BARS)

		var envelope_phase = x_normalized * beat_freq * 8.0 + time * beat_freq
		var envelope = abs(cos(envelope_phase * PI))

		var height = 0.2 + envelope * 0.8
		var y_pos = height / 2.0
		
		# Scale the bar by adjusting Y basis
		var basis = Basis()
		basis = basis.scaled(Vector3(1.0, height / 0.5, 1.0))  # Original height is 0.5
		mm.set_instance_transform(i, Transform3D(basis, Vector3(x_pos, y_pos, 0)))

		var brightness = 0.3 + envelope * 0.7
		mm.set_instance_color(i, Color(0, brightness, brightness * 0.5, 0.7))

# Public API

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

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

