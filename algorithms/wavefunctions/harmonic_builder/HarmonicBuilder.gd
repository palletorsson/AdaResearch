extends Node3D

## Harmonic Series Interactive Synthesizer
## Build musical tones by adding harmonics - demonstrates Fourier synthesis
##
## Concept: ANY periodic sound = sum of harmonics (integer multiples of fundamental)
## - Fundamental (1×): Base pitch
## - 2nd harmonic (2×): Octave above
## - 3rd harmonic (3×): Perfect fifth above octave
## - etc...
##
## Controls:
## - 8 vertical sliders: Control amplitude of each harmonic (1× through 8×)
## - Wheel: Change fundamental frequency (pitch)
## - Buttons: Preset waveforms (Sine, Square, Sawtooth, Triangle)
##
## Musical application: Different harmonic balances = different instrument timbres

const NUM_HARMONICS = 8

# Slider references (will be set in scene)
var harmonic_sliders: Array[Node] = []

# Frequency control
@onready var frequency_wheel = $FrequencyWheel
@onready var audio_player = $AudioStreamPlayer3D

# Preset buttons
var preset_buttons: Dictionary = {}

# Audio synthesis
var fundamental_freq: float = 220.0  # A3
var freq_min: float = 110.0  # A2
var freq_max: float = 880.0  # A5
var harmonic_amplitudes: Array[float] = []
var audio_phases: Array[float] = []

var audio_stream: AudioStreamGenerator
const SAMPLE_RATE = 44100.0
var is_playing: bool = true

# Visualization
var harmonic_bars: Array[MeshInstance3D] = []
var waveform_display: Array[MeshInstance3D] = []
const WAVEFORM_RESOLUTION = 128

# Presets (Fourier series for common waveforms)
var waveform_presets = {
	"sine": [1.0, 0, 0, 0, 0, 0, 0, 0],
	"square": [1.0, 0, 0.333, 0, 0.2, 0, 0.143, 0],  # Odd harmonics: 1, 1/3, 1/5, 1/7
	"sawtooth": [1.0, 0.5, 0.333, 0.25, 0.2, 0.167, 0.143, 0.125],  # All harmonics: 1/n
	"triangle": [1.0, 0, 0.111, 0, 0.04, 0, 0.02, 0],  # Odd harmonics: 1/n²
	"organ": [1.0, 0.3, 0.5, 0.2, 0.4, 0.15, 0.25, 0.1],  # Rich harmonic content
	"clarinet": [1.0, 0, 0.75, 0, 0.5, 0, 0.14, 0],  # Odd harmonics (hollow sound)
	"brass": [1.0, 0.7, 0.8, 0.5, 0.6, 0.3, 0.4, 0.2],  # Strong harmonics (bright)
	"flute": [1.0, 0.2, 0.05, 0.02, 0.01, 0, 0, 0]  # Weak harmonics (pure)
}

func _ready() -> void:
	_initialize_arrays()
	_setup_audio()
	_create_visualizations()
	_setup_controls()
	_apply_preset("sine")  # Start with pure sine
	print("HarmonicBuilder: Ready! Adjust sliders to build your sound")
	print("HarmonicBuilder: %d harmonics available" % NUM_HARMONICS)

func _initialize_arrays() -> void:
	harmonic_amplitudes.resize(NUM_HARMONICS)
	audio_phases.resize(NUM_HARMONICS)
	for i in range(NUM_HARMONICS):
		harmonic_amplitudes[i] = 0.0
		audio_phases[i] = 0.0

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1

	audio_player.stream = audio_stream
	audio_player.volume_db = -3.0  # Comfortable level
	audio_player.play()

	print("HarmonicBuilder: Audio synthesis enabled")

func _setup_controls() -> void:
	# Find sliders (assuming named Slider1, Slider2, etc.)
	for i in range(NUM_HARMONICS):
		var slider_name = "Slider%d/SliderOrigin/InteractableSlider" % (i + 1)
		var slider = get_node_or_null(slider_name)
		if slider and slider.has_signal("slider_moved"):
			harmonic_sliders.append(slider)
			slider.slider_moved.connect(_on_harmonic_slider_changed.bind(i))
			# Set initial value
			slider.slider_position = 0.0
		else:
			push_error("HarmonicBuilder: Slider not found: %s" % slider_name)

	# Setup frequency wheel (check if it has inner structure or is direct)
	var wheel_node = get_node_or_null("FrequencyWheel/SliderOrigin/InteractableSlider")
	if not wheel_node:
		wheel_node = frequency_wheel  # Try direct access as fallback

	if wheel_node and wheel_node.has_signal("slider_moved"):
		frequency_wheel = wheel_node
		frequency_wheel.slider_moved.connect(_on_frequency_changed)
		# Set to middle (A3 = 220 Hz)
		var initial_freq_value = inverse_lerp(freq_min, freq_max, fundamental_freq)
		frequency_wheel.slider_position = initial_freq_value

	# Setup preset buttons
	_setup_preset_buttons()

func _setup_preset_buttons() -> void:
	# Find preset buttons (assuming named PresetSine, PresetSquare, etc.)
	var preset_names = ["Sine", "Square", "Sawtooth", "Triangle", "Organ", "Clarinet", "Brass", "Flute"]

	for preset_name in preset_names:
		var button_name = "Preset%s/InteractableAreaButton" % preset_name
		var button = get_node_or_null(button_name)
		if button and button.has_signal("button_pressed"):
			preset_buttons[preset_name.to_lower()] = button
			button.button_pressed.connect(_apply_preset.bind(preset_name.to_lower()))

func _create_visualizations() -> void:
	# Create harmonic amplitude bars
	var bars_container = Node3D.new()
	bars_container.name = "HarmonicBars"
	bars_container.position = Vector3(0, 0, -1.5)
	add_child(bars_container)

	for i in range(NUM_HARMONICS):
		var bar = MeshInstance3D.new()
		var box = BoxMesh.new()
		box.size = Vector3(0.15, 1.0, 0.1)
		bar.mesh = box

		# Color based on harmonic number (low=red, high=blue)
		var color_t = i / float(NUM_HARMONICS - 1)
		var color = Color(1.0 - color_t, 0.5, color_t, 1.0)

		var material = StandardMaterial3D.new()
		material.albedo_color = color
		material.emission_enabled = true
		material.emission = color * 0.5
		bar.material_override = material

		var x_pos = -2.0 + i * 0.57
		bar.position = Vector3(x_pos, 0, 0)
		bars_container.add_child(bar)
		harmonic_bars.append(bar)

		# Add harmonic number label
		var label = Label3D.new()
		label.text = "%d×" % (i + 1)
		label.position = Vector3(x_pos, -0.7, 0)
		label.font_size = 16
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.modulate = color
		label.outline_size = 2
		label.outline_modulate = Color.BLACK
		bars_container.add_child(label)

	# Create waveform display
	_create_waveform_display()

	# Create title and info labels
	_create_labels()

func _create_waveform_display() -> void:
	var waveform_container = Node3D.new()
	waveform_container.name = "WaveformDisplay"
	waveform_container.position = Vector3(0, 1.5, -1.5)
	add_child(waveform_container)

	for i in range(WAVEFORM_RESOLUTION):
		var x_pos = -3.0 + (i / float(WAVEFORM_RESOLUTION)) * 6.0

		var point = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.03
		sphere.height = 0.06
		point.mesh = sphere

		var material = StandardMaterial3D.new()
		material.albedo_color = Color(1, 0.8, 0.2, 1)
		material.emission_enabled = true
		material.emission = Color(1, 0.8, 0.2, 1) * 0.7
		material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		point.material_override = material

		point.position = Vector3(x_pos, 0, 0)
		waveform_container.add_child(point)
		waveform_display.append(point)

func _create_labels() -> void:
	# Title
	var title = Label3D.new()
	title.text = "Harmonic Series Builder"
	title.position = Vector3(0, 2.5, -1.5)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 1)
	title.outline_size = 4
	title.outline_modulate = Color.BLACK
	add_child(title)

	# Frequency display
	var freq_label = Label3D.new()
	freq_label.name = "FrequencyLabel"
	freq_label.text = "F0: 220.0 Hz (A3)"
	freq_label.position = Vector3(0, -1.5, -1.5)
	freq_label.font_size = 20
	freq_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	freq_label.modulate = Color(0.3, 1, 0.3, 1)
	freq_label.outline_size = 3
	freq_label.outline_modulate = Color.BLACK
	add_child(freq_label)

	# Instruction
	var hint = Label3D.new()
	hint.text = "Adjust sliders to shape timbre | Try presets"
	hint.position = Vector3(0, -2.0, -1.5)
	hint.font_size = 16
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.modulate = Color(0.7, 0.7, 0.7, 0.9)
	hint.outline_size = 2
	hint.outline_modulate = Color.BLACK
	add_child(hint)

func _on_harmonic_slider_changed(value: float, harmonic_index: int) -> void:
	harmonic_amplitudes[harmonic_index] = value
	_update_harmonic_bars()
	#print("HarmonicBuilder: Harmonic %d = %.2f" % [harmonic_index + 1, value])

func _on_frequency_changed(value: float) -> void:
	fundamental_freq = lerp(freq_min, freq_max, value)
	_update_frequency_label()
	print("HarmonicBuilder: Fundamental = %.1f Hz" % fundamental_freq)

func _update_frequency_label() -> void:
	var freq_label = get_node_or_null("FrequencyLabel")
	if freq_label:
		var note_name = _frequency_to_note_name(fundamental_freq)
		freq_label.text = "F0: %.1f Hz (%s)" % [fundamental_freq, note_name]

func _frequency_to_note_name(freq: float) -> String:
	# Simple frequency to note conversion (A440 reference)
	var notes = ["C", "C#", "D", "D#", "E", "F", "F#", "G", "G#", "A", "A#", "B"]
	var a4_freq = 440.0
	var half_steps_from_a4 = round(12.0 * log(freq / a4_freq) / log(2.0))
	var note_index = int(9 + half_steps_from_a4) % 12
	var octave = 4 + int((9 + half_steps_from_a4) / 12)
	return "%s%d" % [notes[note_index], octave]

func _apply_preset(preset_name: String) -> void:
	if not waveform_presets.has(preset_name):
		return

	var preset = waveform_presets[preset_name]
	for i in range(min(NUM_HARMONICS, preset.size())):
		harmonic_amplitudes[i] = preset[i]

		# Update slider visually
		if i < harmonic_sliders.size():
			var slider = harmonic_sliders[i]
			slider.slider_position = preset[i]

	_update_harmonic_bars()
	print("HarmonicBuilder: Applied preset '%s'" % preset_name)

func _update_harmonic_bars() -> void:
	for i in range(harmonic_bars.size()):
		var bar = harmonic_bars[i]
		var amplitude = harmonic_amplitudes[i]

		# Scale bar height based on amplitude
		var height = 0.1 + amplitude * 1.5
		var mesh = bar.mesh as BoxMesh
		if mesh:
			mesh.size.y = height
			bar.position.y = height / 2.0

		# Brighten emission based on amplitude
		var material = bar.material_override as StandardMaterial3D
		if material:
			var base_color = material.albedo_color
			material.emission = base_color * (0.2 + amplitude * 0.8)

var time: float = 0.0

func _process(delta: float) -> void:
	time += delta

	if is_playing:
		_generate_audio_samples()

	_update_waveform_visualization()

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
		var sample: float = 0.0

		# Add each harmonic
		for i in range(NUM_HARMONICS):
			if harmonic_amplitudes[i] > 0.001:
				var harmonic_freq = fundamental_freq * (i + 1)
				var harmonic_sample = sin(audio_phases[i]) * harmonic_amplitudes[i]
				sample += harmonic_sample

				# Update phase
				audio_phases[i] += harmonic_freq * TAU / SAMPLE_RATE
				if audio_phases[i] > TAU:
					audio_phases[i] -= TAU

		# Normalize by number of active harmonics
		var active_count = 0
		for amp in harmonic_amplitudes:
			if amp > 0.001:
				active_count += 1

		if active_count > 0:
			sample = sample / sqrt(active_count) * 0.5

		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func _update_waveform_visualization() -> void:
	# Safety check - make sure visualization is created
	if waveform_display.size() != WAVEFORM_RESOLUTION:
		return

	# Visualize the combined waveform
	for i in range(WAVEFORM_RESOLUTION):
		var x_normalized = i / float(WAVEFORM_RESOLUTION)
		var phase = x_normalized * TAU * 2.0 + time * fundamental_freq * 0.05

		# Calculate waveform value by summing harmonics
		var waveform_value = 0.0
		for j in range(NUM_HARMONICS):
			if harmonic_amplitudes[j] > 0.001:
				waveform_value += sin(phase * (j + 1)) * harmonic_amplitudes[j]

		# Normalize
		var active_count = 0
		for amp in harmonic_amplitudes:
			if amp > 0.001:
				active_count += 1
		if active_count > 0:
			waveform_value = waveform_value / sqrt(active_count)

		# Position point
		waveform_display[i].position.y = waveform_value * 0.5

		# Scale based on amplitude
		var scale = 0.5 + abs(waveform_value) * 0.5
		waveform_display[i].scale = Vector3.ONE * scale

# Public API

func get_audio_parameters() -> Dictionary:
	return {
		"fundamental_freq": fundamental_freq,
		"harmonic_amplitudes": harmonic_amplitudes.duplicate(),
		"freq_min": freq_min,
		"freq_max": freq_max,
		"num_harmonics": NUM_HARMONICS
	}

func save_preset(preset_name: String) -> void:
	waveform_presets[preset_name] = harmonic_amplitudes.duplicate()
	print("HarmonicBuilder: Saved custom preset '%s'" % preset_name)

func save_to_json(file_path: String) -> void:
	var params = get_audio_parameters()
	var json_string = JSON.stringify(params, "\t")
	var file = FileAccess.open(file_path, FileAccess.WRITE)
	if file:
		file.store_string(json_string)
		file.close()
		print("HarmonicBuilder: Saved to %s" % file_path)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
