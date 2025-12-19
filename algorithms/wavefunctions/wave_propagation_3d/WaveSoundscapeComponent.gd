extends Node3D

# WaveSoundscapeComponent (Humpback Whale Aesthetic)
# Inspired by "Songs of the Humpback Whale" by Roger Payne.
# 
# Features:
# - Deep Brownian Drone (Ocean Rumble)
# - Unit-based Vocalizations: Complex sweeps, harmonic moans, and gritty whoops.
# - Rhythmic Theme: The wave frequency drives the "song" pulse.

@export var ring_count: int = 4
@export var base_pitch: float = 30.0 # Deep rumble

var drone_player: AudioStreamPlayer
var ring_players: Array[AudioStreamPlayer3D] = []
var ring_playbacks: Array[AudioStreamGeneratorPlayback] = []

var sample_rate: float = 44100.0
var time: float = 0.0

# State for synthesis
var whale_phases: Array[float] = [0.0, 0.0, 0.0, 0.0]
var brown_noise_state: float = 0.0

# Humpbacks use "units" - rhythmic patterns.
# We'll map the wave frequency to a "song tempo".
var last_unit_trigger: float = 0.0

func _ready():
	_setup_drone()
	_setup_rings()

func _setup_drone():
	drone_player = AudioStreamPlayer.new()
	add_child(drone_player)
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	drone_player.stream = generator
	drone_player.volume_db = -10.0
	drone_player.play()

func _setup_rings():
	for i in range(ring_count):
		var player = AudioStreamPlayer3D.new()
		add_child(player)
		player.unit_size = 30.0
		player.max_db = 0.0 # Stronger presence for the "vocal" units
		
		var generator = AudioStreamGenerator.new()
		generator.mix_rate = sample_rate
		generator.buffer_length = 0.1
		player.stream = generator
		
		ring_players.append(player)
		player.play()
		ring_playbacks.append(player.get_stream_playback())

func update_parameters(frequency: float, amplitude: float, current_time: float, ring_data: Array):
	time = current_time
	
	# 1. Update Drone (Submerged Floor)
	drone_player.volume_db = lerp(-30.0, -12.0, clamp(amplitude * 1.2, 0.0, 1.0))
	
	# 2. Update Vocalization Units (The Whale Songs)
	for i in range(ring_players.size()):
		if i < ring_data.size():
			var ring_node = ring_data[i]
			ring_players[i].global_position = ring_node.global_position
			
			# Humpback-specific synthesis logic
			_generate_humpback_unit(i, frequency, amplitude, ring_node.radius)

func _process(_delta):
	_generate_ocean_rumble()

func _generate_ocean_rumble():
	var playback = drone_player.get_stream_playback()
	if not playback: return
	
	var frames = playback.get_frames_available()
	for i in range(frames):
		# Deep, slow-moving Brownian rumble
		var random_step = (randf() * 2.0 - 1.0) * 0.015
		brown_noise_state = clamp(brown_noise_state * 0.999 + random_step, -0.7, 0.7)
		
		# Fundamental oceanic resonance
		var fundamental = sin(time * TAU * base_pitch) * 0.4
		
		# Combine and push
		var sample = (brown_noise_state + fundamental) * 0.4
		playback.push_frame(Vector2(sample, sample))

func _generate_humpback_unit(index: int, freq: float, amp: float, radius: float):
	var playback = ring_playbacks[index]
	if not playback: return
	
	var frames = playback.get_frames_available()
	if frames <= 0: return
	
	# HUMPBACK SYNTHESIS LOGIC
	# -------------------------
	# Complex sweeps: Glissando is often non-linear
	var song_phase = time * freq * 0.4 + (index * 0.8)
	var sweep = sin(song_phase) * cos(song_phase * 0.5) # More organic glissando shape
	
	# Base target pitch (Mid-low moans to high whoops)
	var target_pitch = 120.0 + (sweep * 180.0) 
	
	# Add organic jitter (vocal flutter)
	var jitter = sin(time * 25.0) * (2.0 + (amp * 10.0))
	target_pitch += jitter
	
	# Distance/Radius attenuation (Unit fades as it spreads)
	var intensity = clamp(1.0 - (radius / 10.0), 0.0, 1.0) * amp
	
	# "Units" are often rhythmic bursts. Apply a slow envelope based on intensity.
	var envelope = clamp(intensity * 1.5, 0.0, 1.0)
	
	for j in range(frames):
		# Cumulative phase
		whale_phases[index] += target_pitch / sample_rate
		if whale_phases[index] > 1.0: whale_phases[index] -= 1.0
		
		# HARMONIC RICHNESS
		# Humpbacks sound moany because of their harmonic content.
		# f, 2f (dominant), 3f (breathier)
		var f_phase = whale_phases[index] * TAU
		var s1 = sin(f_phase) * 0.6
		var s2 = sin(f_phase * 2.0) * 0.3 # Stronger octave
		var s3 = sin(f_phase * 3.0) * 0.1 # Some edge
		
		# Grittiness/Texture - add a tiny bit of filtered noise during peaks
		var noise_grit = (randf() * 2.0 - 1.0) * 0.02 * envelope
		
		var sample = (s1 + s2 + s3 + noise_grit) * envelope * 0.4
		
		playback.push_frame(Vector2(sample, sample))
