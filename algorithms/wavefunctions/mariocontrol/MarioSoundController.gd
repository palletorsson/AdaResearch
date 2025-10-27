extends Node3D

## Mario Sound Controller
## Uses a 3D ball (ValueMapper3D) to control Mario-style pickup sound parameters
## X = Start Frequency (200-800 Hz)
## Y = End Frequency (400-1200 Hz)
## Z = Decay Rate (2.0-12.0 - how fast sound fades)

@onready var value_mapper = $ValueMapper3D
@onready var audio_player = $AudioStreamPlayer3D

# Sound parameters controlled by the ball
var freq_start: float = 440.0
var freq_end: float = 880.0
var decay_rate: float = 8.0

# Audio settings
const SAMPLE_RATE = 44100
var sound_duration: float = 0.5

# Preview cube that shows frequency visually
var preview_cube: MeshInstance3D
var waveform_visualizer: Node3D

func _ready() -> void:
	_create_preview_cube()
	_create_waveform_visualizer()

	if value_mapper:
		value_mapper.values_changed.connect(_on_sound_values_changed)

		# Set initial values
		var initial = value_mapper.get_values()
		_on_sound_values_changed(initial.x, initial.y, initial.z)

	print("MarioSoundController: Ready")

func _create_preview_cube() -> void:
	# Create a cube that pulses with the sound
	preview_cube = MeshInstance3D.new()
	var box_mesh = BoxMesh.new()
	box_mesh.size = Vector3(0.2, 0.2, 0.2)
	preview_cube.mesh = box_mesh

	# Position it below the mapper
	preview_cube.position = Vector3(0, -0.5, 0)

	# Create material
	var preview_material = StandardMaterial3D.new()
	preview_material.albedo_color = Color(1, 0.7, 0.3, 1)
	preview_material.metallic = 0.6
	preview_material.roughness = 0.3
	preview_material.emission_enabled = true
	preview_material.emission = Color(1, 0.7, 0.3, 1) * 0.5
	preview_cube.material_override = preview_material

	add_child(preview_cube)

	# Add label
	var label = Label3D.new()
	label.text = "Mario Sound"
	label.position = Vector3(0, -0.65, 0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.font_size = 24
	label.modulate = Color(1, 1, 1, 0.8)
	label.outline_size = 3
	label.outline_modulate = Color(0, 0, 0, 1)
	label.scale = Vector3.ONE * 0.08
	add_child(label)

func _create_waveform_visualizer() -> void:
	# Create a simple waveform visualizer
	waveform_visualizer = Node3D.new()
	waveform_visualizer.name = "WaveformVisualizer"
	waveform_visualizer.position = Vector3(0, 0, -0.4)
	add_child(waveform_visualizer)

func _on_sound_values_changed(x_val: float, y_val: float, z_val: float) -> void:
	# Map X to start frequency (200-800 Hz)
	freq_start = x_val

	# Map Y to end frequency (400-1200 Hz)
	freq_end = y_val

	# Map Z to decay rate (2.0-12.0)
	decay_rate = z_val

	# Update preview cube color based on frequency
	if preview_cube:
		var preview_mat = preview_cube.material_override as StandardMaterial3D
		if preview_mat:
			# Map frequency to color (low freq = red, high freq = blue)
			var avg_freq = (freq_start + freq_end) * 0.5
			var freq_normalized = clamp((avg_freq - 200.0) / 1000.0, 0.0, 1.0)
			var color = Color(1.0 - freq_normalized, 0.5, freq_normalized, 1.0)
			preview_mat.albedo_color = color
			preview_mat.emission = color * 0.5

	print("MarioSoundController: freq_start=%.1f Hz, freq_end=%.1f Hz, decay=%.2f" % [freq_start, freq_end, decay_rate])

func play_sound() -> void:
	"""Generate and play the Mario-style sound with current parameters"""
	var sound_stream = _generate_mario_sound()
	audio_player.stream = sound_stream
	audio_player.play()

	# Pulse the preview cube
	_pulse_preview_cube()

	print("MarioSoundController: Playing sound")

func _generate_mario_sound() -> AudioStreamWAV:
	"""Generate Mario-style pickup sound with current parameters"""
	var sample_count = int(SAMPLE_RATE * sound_duration)
	var data = PackedByteArray()

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count

		# Rising frequency from freq_start to freq_end
		var freq = freq_start + ((freq_end - freq_start) * progress)

		# Exponential decay envelope
		var envelope = exp(-progress * decay_rate)

		# Square wave for retro Mario feel
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0

		# Apply envelope and convert to 16-bit audio
		var sample_value = wave * envelope * 0.3
		var sample_int = int(sample_value * 32767.0)

		# Append as 16-bit PCM (little endian)
		data.append(sample_int & 0xFF)
		data.append((sample_int >> 8) & 0xFF)

	# Create AudioStreamWAV
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data

	return stream

func _pulse_preview_cube() -> void:
	"""Make the preview cube pulse when sound plays"""
	if not preview_cube:
		return

	# Animate scale pulse
	var tween = create_tween()
	tween.tween_property(preview_cube, "scale", Vector3.ONE * 1.5, 0.1)
	tween.tween_property(preview_cube, "scale", Vector3.ONE, sound_duration - 0.1)

# Public API
func set_sound_duration(duration: float) -> void:
	sound_duration = clamp(duration, 0.1, 2.0)

func get_sound_parameters() -> Dictionary:
	return {
		"freq_start": freq_start,
		"freq_end": freq_end,
		"decay_rate": decay_rate,
		"duration": sound_duration
	}
