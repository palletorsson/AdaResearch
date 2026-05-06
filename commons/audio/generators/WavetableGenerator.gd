extends Node
class_name WavetableGenerator

# Wavetable Synth (PPG Style)
# Interpolates between multiple single-cycle waveforms.

@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()
@onready var generator: AudioStreamGenerator = AudioStreamGenerator.new()
var playback: AudioStreamGeneratorPlayback

# Config
var sample_rate: float = 44100.0
var table_size: int = 512

# State
var phase: float = 0.0
var current_freq: float = 110.0
var target_freq: float = 110.0
var current_amp: float = 0.0
var target_amp: float = 0.0 # Gate
var velocity: float = 0.0

# Wavetable State
var table_pos: float = 0.0 # 0.0 to (num_frames - 1)
var wave_frames: Array = [] # Array of PackedFloat32Array

@export var output_bus: String = "Master"

func _ready():
	_generate_tables()
	
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	
	add_child(player)
	player.stream = generator
	player.bus = output_bus
	player.play()
	
	playback = player.get_stream_playback()

func _generate_tables():
	# Procedural PPG-style sweep: Sine -> Tri -> Saw -> Square -> Pulse
	var shapes = ["sine", "tri", "saw", "square", "pulse"]
	
	for shape in shapes:
		var frame = PackedFloat32Array()
		frame.resize(table_size)
		
		for i in range(table_size):
			var t = float(i) / float(table_size)
			var phase_rad = t * TAU
			var samp = 0.0
			
			match shape:
				"sine": samp = sin(phase_rad)
				"tri": samp = 1.0 - 4.0 * abs(fmod(t + 0.75, 1.0) - 0.5) # approx
				"saw": samp = 2.0 * (t - 0.5)
				"square": samp = 1.0 if t < 0.5 else -1.0
				"pulse": samp = 1.0 if t < 0.25 else -1.0
			
			frame[i] = samp
			
		wave_frames.append(frame)

func play_note(freq: float, vel: float, pos: float = 0.0):
	target_freq = freq
	current_freq = freq # simplistic
	velocity = vel
	target_amp = 1.0
	table_pos = clamp(pos, 0.0, float(wave_frames.size() - 1.001))

func stop_note():
	target_amp = 0.0

func _process(delta):
	# Smooth amp
	current_amp = lerp(current_amp, target_amp, delta * 10.0)
	
	if not playback: return
	var frames_available = playback.get_frames_available()
	if frames_available < 1: return
	
	_process_chunk(frames_available)

func _process_chunk(frames: int):
	var table_len = float(table_size)
	var max_idx = wave_frames.size() - 1
	
	# Pre-calc interpolation indices
	var idx_a = int(table_pos)
	var idx_b = min(idx_a + 1, max_idx)
	var mix = table_pos - float(idx_a)
	
	var frame_a = wave_frames[idx_a]
	var frame_b = wave_frames[idx_b]
	
	for i in range(frames):
		var dt = current_freq / sample_rate
		phase += dt
		if phase >= 1.0: phase -= 1.0
		
		# Table lookup
		var read_idx_f = phase * table_len
		var r_idx = int(read_idx_f) % table_size
		
		var samp_a = frame_a[r_idx]
		var samp_b = frame_b[r_idx]
		
		var out = lerp(samp_a, samp_b, mix)
		
		# Velocity & Amp
		out *= current_amp * velocity
		
		playback.push_frame(Vector2(out, out))
