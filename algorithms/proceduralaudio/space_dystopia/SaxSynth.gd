extends Node
class_name SaxSynth

# Digital Saxophone (Noir Edition)
# Synthesis: PolyBLEP Saw/Pulse + Fixed Formants + Breath Noise + Vibrato
# Designed for: "Deference for Darkness" style leads (Halo ODST)

@onready var generator: AudioStreamGenerator = AudioStreamGenerator.new()
@onready var player: AudioStreamPlayer = AudioStreamPlayer.new()

var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0

# --- Voice State ---
var phase: float = 0.0
var current_freq: float = 220.0
var target_freq: float = 220.0
var velocity: float = 0.0

# Envelope (ADSR)
var env_val: float = 0.0
var env_state: int = 0 # 0:Idle, 1:Attack, 2:Decay, 3:Sustain, 4:Release
var attack_time: float = 0.15 # Slow attack for "swelling" sax
var decay_time: float = 0.1
var sustain_level: float = 0.9
var release_time: float = 0.2

# DSP Parameters
var vibrato_rate: float = 4.5
var vibrato_depth: float = 0.0
var vibrato_phase: float = 0.0
var breath_amount: float = 0.2
var reed_stiffness: float = 0.3 # Pulse width / timbre

# Formants (Alto/Tenor Sax approximations)
# F1 ~ 400Hz, F2 ~ 1800Hz, F3 ~ 2600Hz
var filter1_state = [0.0, 0.0]
var filter2_state = [0.0, 0.0]
var filter3_state = [0.0, 0.0]
var hp_state = [0.0, 0.0] # Highpass for breath

@export var output_bus: String = "Master"

func _ready():
	add_child(player)
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	player.stream = generator
	player.bus = output_bus # Configurable bus
	player.play()
	playback = player.get_stream_playback()

@export var growl_amount: float = 0.0 # 0.0 to 0.5
var growl_phase: float = 0.0

func play_note(freq: float, vel: float = 0.8):
	target_freq = freq
	velocity = vel
	
	# Legato Logic
	if env_state > 0 and env_state < 4:
		# Already playing: smooth glide, no re-trigger
		pass 
	else:
		# New note: reset
		current_freq = freq
		phase = 0.0
		env_state = 1 # Attack
		env_val = 0.0
		reed_stiffness = 0.2 + randf() * 0.2 # New timbre

func stop_note():
	env_state = 4 # Release

func _process(_delta):
	_fill_buffer()

func _fill_buffer():
	if not playback: return
	var frames_available = playback.get_frames_available()
	if frames_available < 1: return
	
	_process_audio_chunk(frames_available)

func _process_audio_chunk(frames: int):
	# Pre-calculate coeffs for static formants
	var c1 = _get_bp_coeff(450.0, 4.0) 
	var c2 = _get_bp_coeff(1900.0, 2.5) 
	var c3 = _get_bp_coeff(2800.0, 3.0) 
	var c_breath = _get_hp_coeff(800.0)
	
	# Portamento (Exponential smoothing)
	var glide_speed = 5.0 # Hz (reach target in ~0.2s)
	# Per-sample alpha not needed, we can drift per sample or per chunk?
	# Better per sample for smooth pitch
	
	for i in range(frames):
		# 0. Portamento
		var diff = target_freq - current_freq
		if abs(diff) > 0.1:
			current_freq += diff * 0.0005 # Slow glide
		else:
			current_freq = target_freq
		
		# 1. Envelope Logic
		var env_inc = 0.0
		if env_state == 1: # Attack
			env_val += (1.0 / (attack_time * sample_rate))
			if env_val >= 1.0:
				env_val = 1.0
				env_state = 2
		elif env_state == 2: # Decay
			env_val -= (1.0 / (decay_time * sample_rate)) * (1.0 - sustain_level)
			if env_val <= sustain_level:
				env_val = sustain_level
				env_state = 3
		elif env_state == 3: # Sustain
			env_val = sustain_level
		elif env_state == 4: # Release
			env_val -= (1.0 / (release_time * sample_rate))
			if env_val <= 0.0:
				env_val = 0.0
				env_state = 0
		
		var amp = env_val * velocity
		if amp <= 0.001:
			playback.push_frame(Vector2.ZERO)
			continue
			
		# 2. Vibrato (LFO)
		vibrato_phase += (vibrato_rate * TAU) / sample_rate
		if vibrato_phase > TAU: vibrato_phase -= TAU
		var vib = sin(vibrato_phase) * vibrato_depth * (env_val * 0.02)
		
		# 3. Growl (AM LFO) - 30Hz flutter
		growl_phase += (30.0 * TAU) / sample_rate
		if growl_phase > TAU: growl_phase -= TAU
		var growl_mod = 1.0 + sin(growl_phase) * growl_amount * env_val
		
		# 4. Oscillator (PolyBLEP Saw)
		var f = current_freq * (1.0 + vib)
		var dt = f / sample_rate
		phase += dt
		if phase >= 1.0: phase -= 1.0
		
		var saw = (2.0 * phase) - 1.0 - _poly_blep(phase, dt)
		
		# 5. Noise (Breath)
		var noise = (randf() * 2.0 - 1.0) * breath_amount * (1.0 - env_val * 0.5)
		var filtered_noise = _process_filter(noise, hp_state, c_breath)
		
		# 6. Formant Filtering
		var raw = saw + filtered_noise * 0.5
		
		var o1 = _process_filter(raw, filter1_state, c1)
		var o2 = _process_filter(raw, filter2_state, c2)
		var o3 = _process_filter(raw, filter3_state, c3)
		
		var out = (o1 * 1.5 + o2 * 1.0 + o3 * 0.5)
		
		# Apply Growl & Amp
		out = out * amp * growl_mod
		
		# Saturation
		out = tanh(out * 1.5) * 0.8
		
		playback.push_frame(Vector2(out, out))

# --- DSP Utils (Reused from VowelSynth) ---

func _poly_blep(t: float, dt: float) -> float:
	if t < dt:
		t /= dt
		return t + t - t * t - 1.0
	elif t > 1.0 - dt:
		t = (t - 1.0) / dt
		return t * t + t + t + 1.0
	else:
		return 0.0

func _get_bp_coeff(freq: float, q: float) -> Array:
	var omega = 2.0 * PI * freq / sample_rate
	var sn = sin(omega)
	var cs = cos(omega)
	var alpha = sn / (2.0 * q)
	var b0 = alpha
	var b1 = 0.0
	var b2 = -alpha
	var a0 = 1.0 + alpha
	var a1 = -2.0 * cs
	var a2 = 1.0 - alpha
	return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0]

func _get_hp_coeff(freq: float) -> Array:
	# Simple Highpass 
	var omega = 2.0 * PI * freq / sample_rate
	var sn = sin(omega)
	var cs = cos(omega)
	var alpha = sn / 2.0 # Q=1 approx
	var a0 = 1.0 + alpha
	
	var b0 = (1.0 + cs) / 2.0
	var b1 = -(1.0 + cs)
	var b2 = (1.0 + cs) / 2.0
	var a1 = -2.0 * cs
	var a2 = 1.0 - alpha
	return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0]

func _process_filter(x: float, s: Array, c: Array) -> float:
	var out = c[0]*x + c[1]*s[0] + c[2]*s[1] - c[3]*s[0] - c[4]*s[1]
	# Direct Form I/II fix? 
	# Trying standard biquad recurrence from VowelSynth
	# VowelSynth used: out = c[0]*x + s[0]; s[0] = ...
	# Let's stick to the VowelSynth one exactly if possible, but I used standard coefs here.
	# Actually VowelSynth implementation:
	# var out = c[0]*x + s[0]
	# s[0] = c[1]*x - c[3]*out + s[1]
	# s[1] = c[2]*x - c[4]*out
	# This is Transposed Direct Form II.
	# My coeff generation returns b0, b1, b2, a1, a2 normalized by a0.
	# So c[0]=b0, c[1]=b1, c[2]=b2, c[3]=a1, c[4]=a2.
	
	# Lets just use the VowelSynth TDF-II structure with my coefficients
	var y = c[0]*x + s[0]
	s[0] = c[1]*x - c[3]*y + s[1]
	s[1] = c[2]*x - c[4]*y
	return y
