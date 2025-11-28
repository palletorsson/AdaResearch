extends Node3D

## Spherical Harmonics - Music of the Spheres (Mario Edition)
## A small sphere orbits a large sphere, creating a retro "Coin" sound rhythmically
##
## Concept: Position on sphere (θ, φ) → Sound parameters
## - Theta (latitude): Pitch (Frequency Range)
## - Phi (longitude): Snappiness (Decay Rate)
## - Radius: Amplitude
##
## This version uses a square wave synthesizer with a frequency chirp and exponential decay
## to emulate the classic 8-bit "pick up" sound effect.

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
var playback: AudioStreamGeneratorPlayback
const SAMPLE_RATE = 44100.0

# Mario Sound Parameters (Controlled by position)
var freq_start: float = 440.0
var freq_end: float = 880.0
var decay_rate: float = 8.0
var sound_duration: float = 0.5

# Trigger state
var last_quadrant: int = 0
var current_time_in_sound: float = 0.0
var is_playing_sound: bool = false

# Visualization
const TRAIL_LENGTH = 128
var trail_index: int = 0
var time: float = 0.0

func _ready() -> void:
	_create_spheres()
	_create_trail()
	_setup_audio()
	_setup_controls()
	print("SphericalHarmonics: Ready - Mario Mode Activated!")

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
	audio_player.volume_db = -6.0
	add_child(audio_player)
	audio_player.play()
	
	# Get playback immediately
	playback = audio_player.get_stream_playback()

	print("SphericalHarmonics: Audio synthesis enabled (Mario Mode)")

func _setup_controls() -> void:
	# TODO: Connect to interactables if available
	# For now, auto-orbit mode
	pass

func _update_small_sphere_position() -> void:
	var x = radius * sin(theta) * cos(phi)
	var y = radius * cos(theta)
	var z = radius * sin(theta) * sin(phi)

	small_sphere.position = Vector3(x, y, z)

	if trail_points.size() == TRAIL_LENGTH:
		trail_points[trail_index].position = small_sphere.position
		trail_points[trail_index].visible = true
		trail_index = (trail_index + 1) % TRAIL_LENGTH

func _update_sound_from_position() -> void:
	# Map theta to start frequency (Pitch)
	var theta_normalized = (sin(theta) + 1.0) / 2.0
	freq_start = lerp(220.0, 880.0, theta_normalized)
	freq_end = freq_start * 2.0 # Classic octave jump

	# Map phi to decay rate (Duration/Snappiness)
	# 0 = Long decay (ringing), 1 = Short decay (pluck)
	var phi_normalized = (sin(phi) + 1.0) / 2.0
	decay_rate = lerp(4.0, 12.0, phi_normalized)

	# Update label
	var label = get_node_or_null("PositionLabel")
	if label:
		var theta_deg = rad_to_deg(theta)
		var phi_deg = rad_to_deg(phi)
		label.text = "Mario Mode: F_Start=%.0fHz Decay=%.1f" % [freq_start, decay_rate]

func _process(delta: float) -> void:
	time += delta

	if auto_orbit:
		theta = wrapf(theta + orbit_speed_theta * delta, 0.0, TAU)
		phi = wrapf(phi + orbit_speed_phi * delta, 0.0, TAU)

	_update_small_sphere_position()
	_update_sound_from_position()
	
	# --- Rhythmic Trigger Logic ---
	# Trigger sound every time theta crosses a quadrant (0, 90, 180, 270 degrees)
	# This creates a rhythmic "Bling... Bling... Bling..." as it orbits
	var current_quadrant = int((theta / TAU) * 4.0) % 4
	if current_quadrant != last_quadrant:
		_trigger_sound()
		last_quadrant = current_quadrant
	
	_generate_audio_samples()
	_update_visualizations()

func _trigger_sound() -> void:
	current_time_in_sound = 0.0
	is_playing_sound = true
	
	# Visual flair on trigger
	var tween = create_tween()
	tween.tween_property(small_sphere, "scale", Vector3.ONE * 2.0, 0.05)
	tween.tween_property(small_sphere, "scale", Vector3.ONE, 0.2)

func _generate_audio_samples() -> void:
	if not playback:
		return

	var frames_available = playback.get_frames_available()
	if frames_available < 256:
		return

	var frames_to_fill = min(frames_available, 512)

	for _frame in range(frames_to_fill):
		var sample: float = 0.0
		
		if is_playing_sound:
			# Mario Sound Synthesis Logic
			current_time_in_sound += 1.0 / SAMPLE_RATE
			var progress = current_time_in_sound / sound_duration
			
			if progress >= 1.0:
				is_playing_sound = false
				sample = 0.0
			else:
				# Rising frequency chirp
				var freq = freq_start + ((freq_end - freq_start) * progress)
				
				# Exponential decay
				var envelope = exp(-progress * decay_rate)
				
				# Square wave
				var wave = 1.0 if sin(2.0 * PI * freq * current_time_in_sound) > 0 else -1.0
				
				sample = wave * envelope * 0.5

		playback.push_frame(Vector2(sample, sample))

func _update_visualizations() -> void:
	# Pulse color based on audio envelope
	var intensity = 0.0
	if is_playing_sound:
		var progress = current_time_in_sound / sound_duration
		intensity = exp(-progress * decay_rate)

	var freq_normalized = (freq_start - 220.0) / 660.0
	var color = Color(1.0 - freq_normalized * 0.5, 0.5 + intensity * 0.5, 0.2 + freq_normalized * 0.6, 1.0)
	var material = small_sphere.material_override as StandardMaterial3D
	if material:
		material.albedo_color = color
		material.emission = color * (0.5 + intensity * 2.0)

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
