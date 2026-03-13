extends Node3D

# WaveSoundscapeComponent - Subtle Crystalline Wave Sound
# Creates gentle, ethereal tones that follow the wave propagation
# Designed to be subtle and complement other soundscapes

@export var ring_count: int = 4
@export var base_pitch: float = 220.0  # A3 - musical base
@export var master_volume_db: float = -24.0  # Very subtle

var ring_players: Array[AudioStreamPlayer3D] = []
var ring_playbacks: Array[AudioStreamGeneratorPlayback] = []

var sample_rate: float = 44100.0
var phases: Array[float] = []

# Pentatonic scale ratios for musical harmony
var scale_ratios: Array[float] = [1.0, 1.125, 1.25, 1.5, 1.667, 2.0]

func _ready() -> void:
	_setup_ring_sounds()

func _setup_ring_sounds() -> void:
	"""Create subtle pitched tones for each wave ring"""
	for i in range(ring_count):
		var player = AudioStreamPlayer3D.new()
		player.name = "RingSound_%d" % i
		add_child(player)
		
		# 3D audio settings - subtle presence
		player.unit_size = 8.0
		player.max_db = -6.0
		player.volume_db = master_volume_db - (i * 3)  # Fade with ring index
		player.attenuation_model = AudioStreamPlayer3D.ATTENUATION_INVERSE_DISTANCE
		
		var generator = AudioStreamGenerator.new()
		generator.mix_rate = sample_rate
		generator.buffer_length = 0.1
		player.stream = generator
		
		ring_players.append(player)
		phases.append(0.0)
		player.play()
		ring_playbacks.append(player.get_stream_playback())

func update_parameters(frequency: float, amplitude: float, current_time: float, ring_data: Array) -> void:
	"""Called by WavePropagation3D to sync sound with visuals"""
	for i in range(min(ring_players.size(), ring_data.size())):
		var ring_node = ring_data[i]
		var player = ring_players[i]
		
		# Follow ring position
		player.global_position = ring_node.global_position + Vector3(0, 0.5, 0)
		
		# Generate sound based on ring state
		_generate_ring_tone(i, frequency, amplitude, ring_node.radius)

func _process(_delta):
	pass  # All generation happens in update_parameters

func _generate_ring_tone(index: int, freq: float, amp: float, radius: float) -> void:
	"""Generate subtle crystalline tone for a wave ring"""
	var playback = ring_playbacks[index]
	if not playback:
		return
	
	var frames = playback.get_frames_available()
	if frames <= 0:
		return
	
	# Ring fades as it expands
	var fade = clamp(1.0 - (radius / 8.0), 0.0, 1.0)
	if fade < 0.01:
		# Silent when fully expanded
		for j in range(frames):
			playback.push_frame(Vector2.ZERO)
		return
	
	# Musical pitch based on ring index (pentatonic harmony)
	var scale_index = index % scale_ratios.size()
	var pitch = base_pitch * scale_ratios[scale_index]
	
	# Subtle modulation based on wave frequency
	var pitch_mod = 1.0 + sin(freq * 2.0) * 0.02
	pitch *= pitch_mod
	
	# Envelope - smooth attack/release
	var envelope = fade * fade * amp * 0.3  # Quadratic fade for smooth tail
	
	for j in range(frames):
		# Phase accumulation
		phases[index] += pitch / sample_rate
		if phases[index] > 1.0:
			phases[index] -= 1.0
		
		var phase = phases[index] * TAU
		
		# Crystalline synthesis: sine with subtle harmonics
		var fundamental = sin(phase) * 0.7
		var harmonic2 = sin(phase * 2.0) * 0.15  # Octave
		var harmonic3 = sin(phase * 3.0) * 0.08  # Fifth above octave
		var harmonic5 = sin(phase * 5.0) * 0.05  # Two octaves + third
		
		# Combine harmonics for bell-like quality
		var sample = (fundamental + harmonic2 + harmonic3 + harmonic5) * envelope
		
		# Gentle stereo spread based on ring index
		var pan = (float(index) / float(ring_count) - 0.5) * 0.3
		var left = sample * (1.0 - pan)
		var right = sample * (1.0 + pan)
		
		playback.push_frame(Vector2(left, right))

func set_master_volume(volume_db: float) -> void:
	"""Adjust overall volume"""
	master_volume_db = volume_db
	for i in range(ring_players.size()):
		ring_players[i].volume_db = master_volume_db - (i * 3)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()

