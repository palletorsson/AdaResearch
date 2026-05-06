extends Node3D

## Oscillating Wave - Sine Creates Curves
## A sphere oscillates vertically, tracing a sine wave in 3D space
## The wave position controls sound parameters
##
## Concept: Motion (oscillation) → Form (sine curve) → Sound
## - Horizontal position (x): Frequency
## - Vertical position (y): Amplitude
## - Wave phase: Timbre
##
## **This is "sine translates to curves" made literal and audible**
##
## OPTIMIZED: Uses WavefunctionResources + MultiMesh for trails

@onready var oscillating_sphere: MeshInstance3D
@onready var audio_player: AudioStreamPlayer3D

# MultiMesh for wave trail (replaces 200 individual nodes)
var wave_trail_multimesh: MultiMeshInstance3D
var wave_positions: PackedVector3Array

# MultiMesh for reference curve (replaces 100 individual nodes)
var reference_curve_multimesh: MultiMeshInstance3D

# Oscillation parameters
var time: float = 0.0
var oscillation_frequency: float = 1.0  # Hz (cycles per second)
var oscillation_amplitude: float = 1.5  # Vertical range
var horizontal_speed: float = 1.0       # How fast sphere moves forward

# Wave visualization
const WAVE_LENGTH = 200  # Number of trail points
var wave_index: int = 0
var horizontal_position: float = 0.0
const HORIZONTAL_RANGE = 10.0  # Total horizontal distance before reset

# Audio synthesis
var audio_stream: AudioStreamGenerator
var audio_phase: float = 0.0
const SAMPLE_RATE = 44100.0
const NUM_HARMONICS = 6

# Sound parameters controlled by position
var base_frequency: float = 220.0  # A3
var harmonic_amplitudes: Array[float] = []

func _ready() -> void:
	_create_sphere()
	_create_wave_trail()
	_create_reference_sine_curve()
	_setup_audio()
	_setup_controls()
	print("OscillatingWave: Ready - Watch sine create curves! (Optimized)")
	print("OscillatingWave: Horizontal position → Frequency, Vertical position → Amplitude")

func _create_sphere() -> void:
	# Oscillating sphere
	oscillating_sphere = MeshInstance3D.new()
	var sphere_mesh = SphereMesh.new()
	sphere_mesh.radius = 0.15
	sphere_mesh.height = 0.3
	oscillating_sphere.mesh = sphere_mesh

	# Dynamic color - needs own material
	var material = StandardMaterial3D.new()
	material.albedo_color = Color(1, 0.3, 0.8, 1.0)  # Magenta
	material.emission_enabled = true
	material.emission = Color(1, 0.3, 0.8, 1.0) * 0.9
	oscillating_sphere.material_override = material

	add_child(oscillating_sphere)

	# Labels
	_create_labels()

func _create_labels() -> void:
	var title = Label3D.new()
	title.text = "Oscillating Wave"
	title.position = Vector3(0, 3.0, 0)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 1)
	title.outline_size = 4
	title.outline_modulate = Color.BLACK
	add_child(title)

	var subtitle = Label3D.new()
	subtitle.text = "Sine Creates Curves"
	subtitle.position = Vector3(0, 2.5, 0)
	subtitle.font_size = 20
	subtitle.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	subtitle.modulate = Color(0.8, 0.8, 1.0, 0.9)
	subtitle.outline_size = 3
	subtitle.outline_modulate = Color.BLACK
	add_child(subtitle)

	var info = Label3D.new()
	info.name = "InfoLabel"
	info.text = "F=220Hz | A=1.5"
	info.position = Vector3(0, -2.5, 0)
	info.font_size = 18
	info.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	info.modulate = Color(0.7, 0.7, 0.7, 0.9)
	info.outline_size = 3
	info.outline_modulate = Color.BLACK
	add_child(info)

func _create_wave_trail() -> void:
	# OPTIMIZED: Use MultiMesh instead of 200 individual MeshInstance3D nodes
	wave_positions.resize(WAVE_LENGTH)
	
	wave_trail_multimesh = MultiMeshInstance3D.new()
	wave_trail_multimesh.name = "WaveTrailMultiMesh"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.instance_count = WAVE_LENGTH
	
	# Use slightly larger trail sphere for visibility
	var trail_mesh = SphereMesh.new()
	trail_mesh.radius = 0.04
	trail_mesh.height = 0.08
	trail_mesh.radial_segments = 8
	trail_mesh.rings = 4
	mm.mesh = trail_mesh
	
	wave_trail_multimesh.multimesh = mm
	wave_trail_multimesh.material_override = WavefunctionResources.get_emissive_material(
		Color(1, 0.3, 0.8), 1.0, 0.7
	)
	
	# Initialize all instances as hidden
	for i in range(WAVE_LENGTH):
		mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ZERO), Vector3.ZERO))
		var age = float(i) / float(WAVE_LENGTH)
		mm.set_instance_color(i, Color(1, 0.3, 0.8, 0.6 * (1.0 - age)))
	
	add_child(wave_trail_multimesh)
	print("OscillatingWave: Wave trail using MultiMesh (1 node instead of 200)")

func _create_reference_sine_curve() -> void:
	# OPTIMIZED: Use MultiMesh instead of 100 individual MeshInstance3D nodes
	var num_reference_points = 100
	
	reference_curve_multimesh = MultiMeshInstance3D.new()
	reference_curve_multimesh.name = "ReferenceSineCurve"
	
	var mm = MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = false
	mm.instance_count = num_reference_points
	mm.mesh = WavefunctionResources.get_trail_sphere()
	
	reference_curve_multimesh.multimesh = mm
	reference_curve_multimesh.material_override = WavefunctionResources.get_emissive_material(
		Color(0.3, 0.7, 1.0), 0.2, 0.3
	)
	
	# Position all reference points along the sine curve
	for i in range(num_reference_points):
		var x = (float(i) / float(num_reference_points)) * HORIZONTAL_RANGE - HORIZONTAL_RANGE / 2
		var y = oscillation_amplitude * sin((x / HORIZONTAL_RANGE) * TAU * 2)  # 2 complete cycles
		var t = Transform3D(Basis(), Vector3(x, y, 0))
		mm.set_instance_transform(i, t)
	
	add_child(reference_curve_multimesh)
	print("OscillatingWave: Reference curve using MultiMesh (1 node instead of 100)")

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1

	audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -3.0
	add_child(audio_player)
	audio_player.play()

	# Initialize harmonic amplitudes
	harmonic_amplitudes.resize(NUM_HARMONICS)
	for i in range(NUM_HARMONICS):
		harmonic_amplitudes[i] = 1.0 / (i + 1)  # Sawtooth-like (1/n)

	print("OscillatingWave: Audio synthesis enabled")

func _setup_controls() -> void:
	# TODO: Connect to interactables if available
	pass

func _update_sphere_position() -> void:
	# Calculate vertical position (y) using sine function
	var y = oscillation_amplitude * sin(oscillation_frequency * TAU * time)

	# Calculate horizontal position (x) moving forward
	horizontal_position = fmod(horizontal_position + horizontal_speed * get_process_delta_time(), HORIZONTAL_RANGE)
	var x = horizontal_position - HORIZONTAL_RANGE / 2  # Center at 0

	oscillating_sphere.position = Vector3(x, y, 0)

	# Update trail using MultiMesh
	if wave_trail_multimesh and wave_trail_multimesh.multimesh:
		var mm = wave_trail_multimesh.multimesh
		var pos = oscillating_sphere.position
		wave_positions[wave_index] = pos
		
		# Show this trail point
		mm.set_instance_transform(wave_index, Transform3D(Basis(), pos))
		
		# Update colors for fading effect
		for i in range(WAVE_LENGTH):
			var age_offset = (wave_index - i + WAVE_LENGTH) % WAVE_LENGTH
			var alpha = 0.6 * (1.0 - float(age_offset) / float(WAVE_LENGTH))
			mm.set_instance_color(i, Color(1, 0.3, 0.8, alpha))
		
		wave_index = (wave_index + 1) % WAVE_LENGTH

	# Update audio position
	audio_player.position = oscillating_sphere.position

func _update_sound_from_position() -> void:
	# Map horizontal position to frequency
	# x = -5 to +5 → frequency 110 to 880 Hz (A2 to A5)
	var x_normalized = (oscillating_sphere.position.x + HORIZONTAL_RANGE / 2) / HORIZONTAL_RANGE
	base_frequency = lerp(110.0, 880.0, x_normalized)

	# Map vertical position to overall amplitude (volume)
	var y_normalized = (oscillating_sphere.position.y / oscillation_amplitude + 1.0) / 2.0  # [0, 1]
	var volume_db = lerp(-12.0, 0.0, y_normalized)
	audio_player.volume_db = volume_db

	# Map wave phase to harmonic content (timbre)
	var phase_normalized = fmod(oscillation_frequency * time, 1.0)

	# Vary harmonic balance based on wave phase
	for i in range(NUM_HARMONICS):
		var harmonic_num = i + 1
		var base_amp = 1.0 / harmonic_num

		# Modulate harmonics based on phase
		var modulation = 0.5 + 0.5 * sin(phase_normalized * TAU * harmonic_num)
		harmonic_amplitudes[i] = base_amp * modulation

	# Update label
	var label = get_node_or_null("InfoLabel")
	if label:
		label.text = "F=%.0fHz | A=%.2f | Phase=%.2f" % [base_frequency, oscillation_amplitude, phase_normalized]

func _process(delta: float) -> void:
	time += delta

	_update_sphere_position()
	_update_sound_from_position()
	_generate_audio_samples()
	_update_visualizations()

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

		# Add each harmonic using lookup table
		for i in range(NUM_HARMONICS):
			if harmonic_amplitudes[i] > 0.001:
				var harmonic_freq = base_frequency * (i + 1)
				var phase = fposmod(audio_phase * (i + 1), 1.0)
				sample += WavefunctionResources.fast_sine(phase) * harmonic_amplitudes[i]

		# Advance phase
		audio_phase += base_frequency / SAMPLE_RATE
		if audio_phase > 1.0:
			audio_phase -= 1.0

		# Normalize
		var active_count = 0
		for amp in harmonic_amplitudes:
			if amp > 0.001:
				active_count += 1

		if active_count > 0:
			sample = sample / sqrt(active_count) * 0.4

		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func _update_visualizations() -> void:
	# Pulse sphere based on sound intensity
	var intensity = 0.0
	for amp in harmonic_amplitudes:
		intensity += amp
	intensity = intensity / NUM_HARMONICS

	var scale_factor = 1.0 + intensity * 0.3
	oscillating_sphere.scale = Vector3.ONE * scale_factor

	# Update color based on frequency
	var freq_normalized = (base_frequency - 110.0) / 770.0
	var color = Color(1.0, 0.3 + freq_normalized * 0.5, 0.8 - freq_normalized * 0.3, 1.0)

	var material = oscillating_sphere.material_override as StandardMaterial3D
	if material:
		material.albedo_color = color
		material.emission = color * (0.7 + intensity * 0.3)

# Public API

func set_oscillation_frequency(freq: float) -> void:
	oscillation_frequency = clamp(freq, 0.1, 5.0)
	print("OscillatingWave: Oscillation frequency set to %.2f Hz" % oscillation_frequency)

func set_oscillation_amplitude(amp: float) -> void:
	oscillation_amplitude = clamp(amp, 0.5, 3.0)
	# Update reference curve when amplitude changes
	_update_reference_curve()
	print("OscillatingWave: Oscillation amplitude set to %.2f" % oscillation_amplitude)

func _update_reference_curve() -> void:
	if not reference_curve_multimesh or not reference_curve_multimesh.multimesh:
		return
	var mm = reference_curve_multimesh.multimesh
	var num_points = mm.instance_count
	for i in range(num_points):
		var x = (float(i) / float(num_points)) * HORIZONTAL_RANGE - HORIZONTAL_RANGE / 2
		var y = oscillation_amplitude * sin((x / HORIZONTAL_RANGE) * TAU * 2)
		mm.set_instance_transform(i, Transform3D(Basis(), Vector3(x, y, 0)))

func set_horizontal_speed(speed: float) -> void:
	horizontal_speed = clamp(speed, 0.1, 3.0)
	print("OscillatingWave: Horizontal speed set to %.2f" % horizontal_speed)

func toggle_reference_curve() -> void:
	if reference_curve_multimesh:
		reference_curve_multimesh.visible = !reference_curve_multimesh.visible
		print("OscillatingWave: Reference curve %s" % ("visible" if reference_curve_multimesh.visible else "hidden"))

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	pass
