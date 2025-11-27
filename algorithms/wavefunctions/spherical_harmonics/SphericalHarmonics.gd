extends Node3D

## Spherical Harmonics - Music of the Spheres
## A small sphere orbits a large sphere, creating sound based on position
##
## Concept: Position on sphere (θ, φ) → Sound parameters
## - Theta (latitude): Frequency
## - Phi (longitude): Timbre (harmonic content)
## - Radius: Amplitude
##
## This is the ancient dream: **to hear the geometry of spheres**
## Pythagoras believed celestial spheres made music as they moved
## Here, we make that literal - sphere position = sound

@onready var large_sphere: MeshInstance3D
@onready var small_sphere: MeshInstance3D
@onready var audio_player: AudioStreamPlayer3D
@onready var trail_points: Array[MeshInstance3D] = []

# Spherical coordinates (position of small sphere)
var theta: float = 0.0  # Latitude angle (0 to PI)
var phi: float = 0.0    # Longitude angle (0 to TAU)
var radius: float = 2.0 # Distance from center

# Control parameters
var orbit_speed_theta: float = 0.5  # How fast theta changes
var orbit_speed_phi: float = 1.0    # How fast phi changes
var auto_orbit: bool = true

# Audio synthesis
var audio_stream: AudioStreamGenerator
var audio_phases: Array[float] = []
const SAMPLE_RATE = 44100.0
const NUM_HARMONICS = 8

# Sound parameters controlled by position
var base_frequency: float = 220.0  # A3
var harmonic_amplitudes: Array[float] = []

# Visualization
const TRAIL_LENGTH = 128
var trail_index: int = 0
var time: float = 0.0

func _ready() -> void:
	_create_spheres()
	_create_trail()
	_setup_audio()
	_setup_controls()
	print("SphericalHarmonics: Ready - Hear the geometry of spheres!")
	print("SphericalHarmonics: Theta (latitude) → Frequency, Phi (longitude) → Timbre")

func _create_spheres() -> void:
	# Large sphere (center)
	large_sphere = MeshInstance3D.new()
	var large_mesh = SphereMesh.new()
	large_mesh.radius = 1.0
	large_mesh.height = 2.0
	large_mesh.rings = 32
	large_mesh.radial_segments = 64
	large_sphere.mesh = large_mesh

	var large_material = StandardMaterial3D.new()
	large_material.albedo_color = Color(0.2, 0.3, 0.8, 0.3)
	large_material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	large_material.emission_enabled = true
	large_material.emission = Color(0.1, 0.2, 0.4, 1.0)
	large_material.cull_mode = BaseMaterial3D.CULL_DISABLED
	large_sphere.material_override = large_material

	add_child(large_sphere)

	# Small sphere (orbiting)
	small_sphere = MeshInstance3D.new()
	var small_mesh = SphereMesh.new()
	small_mesh.radius = 0.1
	small_mesh.height = 0.2
	small_sphere.mesh = small_mesh

	var small_material = StandardMaterial3D.new()
	small_material.albedo_color = Color(1, 0.7, 0.2, 1.0)
	small_material.emission_enabled = true
	small_material.emission = Color(1, 0.7, 0.2, 1.0) * 0.8
	small_sphere.material_override = small_material

	add_child(small_sphere)

	# Initial position
	_update_small_sphere_position()

	# Labels
	_create_labels()

func _create_labels() -> void:
	var title = Label3D.new()
	title.text = "Music of the Spheres"
	title.position = Vector3(0, 2.5, 0)
	title.font_size = 32
	title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	title.modulate = Color(1, 1, 1, 1)
	title.outline_size = 4
	title.outline_modulate = Color.BLACK
	add_child(title)

	var hint = Label3D.new()
	hint.name = "PositionLabel"
	hint.text = "θ=0.0° φ=0.0° | F=220Hz"
	hint.position = Vector3(0, -2.0, 0)
	hint.font_size = 20
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	hint.modulate = Color(0.7, 0.7, 0.7, 0.9)
	hint.outline_size = 3
	hint.outline_modulate = Color.BLACK
	add_child(hint)

func _create_trail() -> void:
	# Create trail points to visualize path
	for i in range(TRAIL_LENGTH):
		var point = MeshInstance3D.new()
		var sphere = SphereMesh.new()
		sphere.radius = 0.02
		sphere.height = 0.04
		point.mesh = sphere

		var material = StandardMaterial3D.new()
		var age = i / float(TRAIL_LENGTH)
		material.albedo_color = Color(1, 0.7, 0.2, 0.3 * (1.0 - age))
		material.emission_enabled = true
		material.emission = Color(1, 0.7, 0.2, 1.0) * 0.5 * (1.0 - age)
		material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		point.material_override = material

		point.visible = false
		add_child(point)
		trail_points.append(point)

func _setup_audio() -> void:
	audio_stream = AudioStreamGenerator.new()
	audio_stream.mix_rate = SAMPLE_RATE
	audio_stream.buffer_length = 0.1

	audio_player = AudioStreamPlayer3D.new()
	audio_player.stream = audio_stream
	audio_player.volume_db = -3.0
	add_child(audio_player)
	audio_player.play()

	# Initialize arrays
	audio_phases.resize(NUM_HARMONICS)
	harmonic_amplitudes.resize(NUM_HARMONICS)
	for i in range(NUM_HARMONICS):
		audio_phases[i] = 0.0
		harmonic_amplitudes[i] = 0.0

	print("SphericalHarmonics: Audio synthesis enabled")

func _setup_controls() -> void:
	# TODO: Connect to interactables if available
	# For now, auto-orbit mode
	pass

func _update_small_sphere_position() -> void:
	# Convert spherical to Cartesian coordinates
	# x = r·sin(θ)·cos(φ)
	# y = r·cos(θ)
	# z = r·sin(θ)·sin(φ)

	var x = radius * sin(theta) * cos(phi)
	var y = radius * cos(theta)
	var z = radius * sin(theta) * sin(phi)

	small_sphere.position = Vector3(x, y, z)

	# Update trail (safety check first)
	if trail_points.size() == TRAIL_LENGTH:
		trail_points[trail_index].position = small_sphere.position
		trail_points[trail_index].visible = true
		trail_index = (trail_index + 1) % TRAIL_LENGTH

func _update_sound_from_position() -> void:
	# Map theta (0 to TAU) to frequency (110 Hz to 880 Hz, A2 to A5)
	# Use sine wave for smooth up-down frequency motion
	var theta_normalized = (sin(theta) + 1.0) / 2.0  # Maps to 0-1 smoothly
	base_frequency = lerp(110.0, 880.0, theta_normalized)

	# Map phi (0 to TAU) to harmonic content (timbre)
	# Different phi values create different harmonic balances
	var phi_normalized = phi / TAU

	# Create harmonic recipe based on phi (seamless loop)
	# phi = 0:        Pure sine (fundamental only)
	# phi = 0.25:     Triangle wave (odd harmonics, 1/n²)
	# phi = 0.5:      Square wave (odd harmonics, 1/n)
	# phi = 0.75:     Sawtooth wave (all harmonics, 1/n)
	# phi = 1.0 → 0:  Back to pure sine (seamless loop!)

	for i in range(NUM_HARMONICS):
		var harmonic_num = i + 1
		var phase_offset = phi_normalized * TAU * harmonic_num

		# Different harmonic patterns based on phi
		if phi_normalized < 0.25:
			# Pure to triangle
			var mix = phi_normalized / 0.25
			if harmonic_num % 2 == 1:  # Odd harmonics
				harmonic_amplitudes[i] = 1.0 / (harmonic_num * harmonic_num) * mix + (1.0 - mix) * (1.0 if i == 0 else 0.0)
			else:
				harmonic_amplitudes[i] = 0.0
		elif phi_normalized < 0.5:
			# Triangle to square
			var mix = (phi_normalized - 0.25) / 0.25
			if harmonic_num % 2 == 1:
				var triangle_amp = 1.0 / (harmonic_num * harmonic_num)
				var square_amp = 1.0 / harmonic_num
				harmonic_amplitudes[i] = lerp(triangle_amp, square_amp, mix)
			else:
				harmonic_amplitudes[i] = 0.0
		elif phi_normalized < 0.75:
			# Square to sawtooth
			var mix = (phi_normalized - 0.5) / 0.25
			var square_amp = 1.0 / harmonic_num if harmonic_num % 2 == 1 else 0.0
			var saw_amp = 1.0 / harmonic_num
			harmonic_amplitudes[i] = lerp(square_amp, saw_amp, mix)
		else:
			# Sawtooth back to pure sine (completes the loop)
			var mix = (phi_normalized - 0.75) / 0.25
			var saw_amp = 1.0 / harmonic_num
			var pure_amp = 1.0 if i == 0 else 0.0  # Pure sine = only fundamental
			harmonic_amplitudes[i] = lerp(saw_amp, pure_amp, mix)

	# Update label
	var label = get_node_or_null("PositionLabel")
	if label:
		var theta_deg = rad_to_deg(theta)
		var phi_deg = rad_to_deg(phi)
		label.text = "θ=%.1f° φ=%.1f° | F=%.0fHz" % [theta_deg, phi_deg, base_frequency]

func _process(delta: float) -> void:
	time += delta

	# Auto-orbit (can be disabled for manual control)
	if auto_orbit:
		# Let theta wrap continuously for smooth orbit
		theta = wrapf(theta + orbit_speed_theta * delta, 0.0, TAU)
		phi = wrapf(phi + orbit_speed_phi * delta, 0.0, TAU)

	_update_small_sphere_position()
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

		# Add each harmonic
		for i in range(NUM_HARMONICS):
			if harmonic_amplitudes[i] > 0.001:
				var harmonic_freq = base_frequency * (i + 1)
				sample += sin(audio_phases[i]) * harmonic_amplitudes[i]

				audio_phases[i] += harmonic_freq * TAU / SAMPLE_RATE
				if audio_phases[i] > TAU:
					audio_phases[i] -= TAU

		# Normalize
		var active_count = 0
		for amp in harmonic_amplitudes:
			if amp > 0.001:
				active_count += 1

		if active_count > 0:
			sample = sample / sqrt(active_count) * 0.5

		sample = clamp(sample, -1.0, 1.0)
		playback.push_frame(Vector2(sample, sample))

func _update_visualizations() -> void:
	# Pulse small sphere based on sound
	var intensity = 0.0
	for amp in harmonic_amplitudes:
		intensity += amp
	intensity = intensity / NUM_HARMONICS

	var scale = 1.0 + intensity * 0.5
	small_sphere.scale = Vector3.ONE * scale

	# Update emission based on frequency
	var freq_normalized = (base_frequency - 110.0) / 770.0
	var color = Color(1.0 - freq_normalized * 0.5, 0.7, 0.2 + freq_normalized * 0.6, 1.0)
	var material = small_sphere.material_override as StandardMaterial3D
	if material:
		material.albedo_color = color
		material.emission = color * (0.5 + intensity * 0.5)

# Public API

func set_orbit_speed(theta_speed: float, phi_speed: float) -> void:
	orbit_speed_theta = theta_speed
	orbit_speed_phi = phi_speed

func set_position_spherical(new_theta: float, new_phi: float) -> void:
	theta = clamp(new_theta, 0.0, PI)
	phi = wrapf(new_phi, 0.0, TAU)
	_update_small_sphere_position()
	_update_sound_from_position()

func toggle_auto_orbit() -> void:
	auto_orbit = !auto_orbit
	print("SphericalHarmonics: Auto-orbit %s" % ("ON" if auto_orbit else "OFF"))
