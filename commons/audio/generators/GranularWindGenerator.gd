extends Node
class_name GranularWindGenerator

# Granular Wind Generator
# Creates desolate wind textures using granular synthesis on a Pink Noise buffer.

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var generator: AudioStreamGenerator = AudioStreamGenerator.new()
var playback: AudioStreamGeneratorPlayback

# Configuration
var sample_rate: float = 44100.0
var buffer_len_seconds: int = 5
var noise_buffer: PackedFloat32Array = PackedFloat32Array()

# Grain Config (Desolate Wind defaults)
var grain_size_sec: float = 0.1
var grain_density: float = 40.0 # Grains per second
var grain_pitch_base: float = 1.0
var grain_pitch_scatter: float = 0.5
var pan_spread: float = 0.8

# State
var grains: Array = [] # List of grain dicts
var time: float = 0.0
var grain_accumulator: float = 0.0

@export var output_bus: String = "Master"

func _ready():
	_generate_pink_noise_buffer()
	
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.2
	
	add_child(player)
	player.stream = generator
	player.bus = output_bus
	player.play()
	
	playback = player.get_stream_playback()

func _generate_pink_noise_buffer():
	# Simple Pink Noise approximation (Voss-McCartney or just layered white)
	# Using the "add multiple octaves of white noise" method
	noise_buffer.resize(int(sample_rate * buffer_len_seconds))
	
	var octaves = 6
	var octave_vals = []
	for k in range(octaves): octave_vals.append(0.0)
	
	for i in range(noise_buffer.size()):
		var white = randf() * 2.0 - 1.0
		
		# Update octaves
		for k in range(octaves):
			if i % (1 << k) == 0:
				octave_vals[k] = randf() * 2.0 - 1.0
		
		var pink = 0.0
		for k in range(octaves): pink += octave_vals[k]
		
		# Normalize roughly
		pink /= float(octaves)
		noise_buffer[i] = pink

func _process(_delta):
	if not playback: return
	var frames_available = playback.get_frames_available()
	if frames_available < 1: return
	
	_process_chunk(frames_available)

func _process_chunk(frames: int):
	for i in range(frames):
		# 1. Spawn Grains
		grain_accumulator += grain_density / sample_rate
		while grain_accumulator >= 1.0:
			_spawn_grain()
			grain_accumulator -= 1.0
			
		# 2. Sum Grains
		var left = 0.0
		var right = 0.0
		
		var k = 0
		while k < grains.size():
			var g = grains[k]
			g.age += 1
			
			if g.age >= g.duration:
				grains.remove_at(k)
				continue
				# Don't increment k
			
			var progress = float(g.age) / float(g.duration)
			# Hanning window
			var env = 0.5 * (1.0 - cos(TAU * progress))
			
			var idx = int(g.pos) % noise_buffer.size()
			var samp = noise_buffer[idx]
			
			g.pos += g.rate
			
			var l_val = samp * env * (1.0 - g.pan * 0.5)
			var r_val = samp * env * (1.0 + g.pan * 0.5)
			
			left += l_val
			right += r_val
			
			grains[k] = g # update struct
			k += 1
			
		# Limiter
		left = clamp(left * 0.5, -1.0, 1.0)
		right = clamp(right * 0.5, -1.0, 1.0)
		
		playback.push_frame(Vector2(left, right))

func _spawn_grain():
	# Random read position
	var start_pos_sec = randf() * buffer_len_seconds
	var start_idx = int(start_pos_sec * sample_rate)
	
	var size = grain_size_sec * (1.0 + randf_range(-0.2, 0.2))
	var dur_samps = int(size * sample_rate)
	
	var pitch = grain_pitch_base + randf_range(-grain_pitch_scatter, grain_pitch_scatter)
	# Negative pitch for reverse grains? No, keep it simple for wind
	
	var pan = randf_range(-pan_spread, pan_spread)
	
	var grain = {
		"pos": float(start_idx),
		"rate": pitch,
		"duration": dur_samps,
		"age": 0,
		"pan": pan
	}
	grains.append(grain)
