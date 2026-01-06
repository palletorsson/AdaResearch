extends Node

# VowelSynth3D
# Synthesis engine for vowel sounds using two resonant filters.
# Ported/extended from SpeechSynth for 3D Phoneme Board.

@onready var generator: AudioStreamGenerator = AudioStreamGenerator.new()
@onready var sound_board = get_parent()

var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var phase: float = 0.0
var pulse_hz: float = 130.0 

# Local Thread-Safe RNG
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()

# Field Parameters
var f1: float = 500.0
var delta: float = 1000.0

# Envelope tracking
var env: float = 0.0
var env_target: float = 0.0
var env_coeff_attack: float = 0.0
var env_coeff_release: float = 0.0

@export var attack_ms: float = 20.0
@export var release_ms: float = 40.0
@export_range(0.0, 1.0) var master_consonant_volume: float = 0.3
@export_range(0.0, 1.0) var vowel_volume: float = 0.15

# Parameter Smoothing (Block Rate)
var audio_target_f1: float = 500.0
var audio_target_delta: float = 1000.0
var audio_current_f1: float = 500.0
var audio_current_delta: float = 1000.0

# Filter States
var filter1_state: Array = [0.0, 0.0]
var filter2_state: Array = [0.0, 0.0]
var noise_filter_state: Array = [0.0, 0.0]
var consonant_filter_state: Array = [0.0, 0.0] # Dedicated for fricatives/plosives

# --- Consonant Logic (Scheduled Events) ---
enum FricativeState { NONE, ACTIVE }
enum PlosiveState { NONE, CLOSURE, BURST }
enum NasalState { NONE, ACTIVE }

var fricative_state = FricativeState.NONE
var fricative_counter = 0
var fricative_dur_samples = 0
var fricative_amp = 0.0
var fricative_cutoff = 4000.0
var fricative_voiced = false

var plosive_state = PlosiveState.NONE
var plosive_counter = 0
var burst_dur_samples = 0
var burst_amp = 0.0
var burst_spectrum = 2000 # Center freq

var nasal_state = NasalState.NONE
var nasal_counter = 0
var nasal_dur_samples = 0

# --- Voice Settings ---
var voiced_mix: float = 1.0 # 1.0 for vowel, lower for breathy
var noise_mix: float = 0.0  # Breathiness

class AudioEvent:
	var type: String
	var sample_time: int
	var duration_samples: int
	var amplitude: float
	var params: Dictionary

var events: Array[AudioEvent] = []
var sample_clock: int = 0

func _ready():
	var player = AudioStreamPlayer3D.new()
	add_child(player)
	
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.1
	player.stream = generator
	player.bus = "Master"
	player.play()
	
	playback = player.get_stream_playback()
	
	# Pre-calculate envelope coefficients
	env_coeff_attack = exp(-1.0 / (attack_ms * 0.001 * sample_rate))
	env_coeff_release = exp(-1.0 / (release_ms * 0.001 * sample_rate))

func _process(_delta_time):
	# Push target values from logic thread to audio thread
	audio_target_f1 = f1
	audio_target_delta = delta
	env_target = target_intensity
	
	_fill_until(2048)

# Control Interface
var target_intensity: float = 0.0 
var is_speaking: bool = false
var time_accum: float = 0.0

func trigger_fricative(type: String, duration_ms: float = 150.0):
	var e = AudioEvent.new()
	e.type = "fricative"
	e.sample_time = sample_clock + 256 # Small buffer
	e.duration_samples = int(duration_ms * 0.001 * sample_rate)
	e.amplitude = 1.0
	
	match type:
		"s": e.params = {"center": 7000, "q": 1.0, "voiced": false}
		"z": e.params = {"center": 4000, "q": 1.5, "voiced": true}
		"sh": e.params = {"center": 3000, "q": 0.8, "voiced": false}
		"f": e.params = {"center": 5000, "q": 0.5, "voiced": false}
		"v": e.params = {"center": 2500, "q": 0.7, "voiced": true}
		"th": e.params = {"center": 6000, "q": 0.6, "voiced": false}
		"h": e.params = {"center": 3500, "q": 0.4, "voiced": false}
	
	events.push_back(e)

func trigger_plosive(type: String):
	# 1. Closure (Silence)
	var e1 = AudioEvent.new()
	e1.type = "closure"
	e1.sample_time = sample_clock + 256
	e1.duration_samples = int(60 * 0.001 * sample_rate)
	events.push_back(e1)
	
	# 2. Burst (Release)
	var e2 = AudioEvent.new()
	e2.type = "burst"
	e2.sample_time = e1.sample_time + e1.duration_samples
	e2.duration_samples = int(40 * 0.001 * sample_rate)
	
	match type:
		"p": e2.params = {"center": 600, "q": 1.0, "amp": 1.4}
		"b": e2.params = {"center": 300, "q": 1.5, "amp": 1.2}
		"t": e2.params = {"center": 5500, "q": 2.0, "amp": 1.0}
		"d": e2.params = {"center": 4000, "q": 1.2, "amp": 0.8}
		"k": e2.params = {"center": 2500, "q": 1.5, "amp": 1.1}
		"g": e2.params = {"center": 1800, "q": 1.0, "amp": 0.9}
	
	e2.amplitude = e2.params["amp"]
	events.push_back(e2)

func trigger_nasal(type: String, duration_ms: float = 100.0):
	var e = AudioEvent.new()
	e.type = "nasal"
	e.sample_time = sample_clock + 256
	e.duration_samples = int(duration_ms * 0.001 * sample_rate)
	e.amplitude = 0.5
	events.push_back(e)

func trigger_affricate(type: String):
	# ch = t + sh
	trigger_plosive("t")
	trigger_fricative("sh", 100)

func stop():
	is_speaking = false
	target_intensity = 0.0
	env_target = 0.0

func _fill_until(frames_requested: int):
	var space = playback.get_frames_available()
	if space < frames_requested: return
	
	_process_audio_chunk(space)

func _process_audio_chunk(frames: int):
	# Parameter smoothing (Block Rate for F1/Delta)
	var f1_inc = (audio_target_f1 - audio_current_f1) / float(frames)
	var delta_inc = (audio_target_delta - audio_current_delta) / float(frames)
	
	for i in range(frames):
		sample_clock += 1
		audio_current_f1 += f1_inc
		audio_current_delta += delta_inc
		
		# Process Timeline Events
		var next_events: Array[AudioEvent] = []
		for e in events:
			if e.sample_time <= sample_clock:
				_apply_event(e)
			else:
				next_events.append(e)
		events = next_events
		
		# Envelope Follower (Zipper filter)
		var coeff = env_coeff_attack if env_target > env else env_coeff_release
		env = env * coeff + env_target * (1.0 - coeff)
		
		# Filter Params
		var cf1 = audio_current_f1
		var cf2 = cf1 + audio_current_delta
		
		var q = 10.0 # Standard Vowel Q
		var c1 = _get_filter_coeff(cf1, q)
		var c2 = _get_filter_coeff(cf2, q * 1.5)
		
		var g1 = 1.0
		var g2 = 0.5 # F2 is usually weaker
		
		var noise_c = _get_filter_coeff(4000.0, 0.7)
		
		# Signal Generation
		var vowel_signal = 0.0
		var noise_signal = 0.0
		
		# A. Fricative Path
		if fricative_state == FricativeState.ACTIVE:
			if fricative_counter < fricative_dur_samples:
				var t = float(fricative_counter) / float(fricative_dur_samples)
				var fric_env = sin(t * PI)
				var noise_val = _rng.randf_range(-1.0, 1.0)
				
				# Band-pass filtering
				var c_bp = _get_bp_coeff(fricative_cutoff, fricative_voiced and 1.5 or 0.8)
				var shaped = _process_filter(noise_val, consonant_filter_state, c_bp)
				
				if fricative_voiced:
					var voice_phase = (sample_clock * pulse_hz / sample_rate)
					shaped += sin(voice_phase * TAU) * 0.2
				
				noise_signal += shaped * fricative_amp * fric_env * master_consonant_volume
				fricative_counter += 1
			else:
				fricative_state = FricativeState.NONE
				consonant_filter_state = [0.0, 0.0]
				
		# Nasal Path
		var nasal_damp = 1.0
		if nasal_state == NasalState.ACTIVE:
			if nasal_counter < nasal_dur_samples:
				nasal_damp = 0.5
				nasal_counter += 1
			else:
				nasal_state = NasalState.NONE
				
		# B. Plosive Burst
		if plosive_state == PlosiveState.BURST:
			if plosive_counter < burst_dur_samples:
				var t = float(plosive_counter) / float(burst_dur_samples)
				var burst_env = 0.0
				if t < 0.2: burst_env = t / 0.2
				elif t > 0.8: burst_env = (1.0 - t) / 0.2
				else: burst_env = 1.0
				
				var noise_val = _rng.randf_range(-1.0, 1.0)
				var c_bp = _get_bp_coeff(burst_spectrum, 2.0)
				var shaped = _process_filter(noise_val, consonant_filter_state, c_bp)
				
				var locus_res = sin(plosive_counter * burst_spectrum * TAU / sample_rate) * 0.1
				noise_signal += (shaped + locus_res) * burst_amp * burst_env * master_consonant_volume
				plosive_counter += 1
			else:
				plosive_state = PlosiveState.NONE
				consonant_filter_state = [0.0, 0.0]
				
		# C. Vowel Source
		var phase_inc = pulse_hz / sample_rate
		var source = 0.0
		if env > 0.0001 or env_target > 0.0001:
			phase += phase_inc
			if phase >= 1.0: phase -= 1.0
			var naive_saw = (phase * 2.0) - 1.0
			var poly = _poly_blep(phase, phase_inc)
			source = (naive_saw - poly) * 0.5 
			source *= env
		
		var out1 = _process_filter(source, filter1_state, c1) * g1 * nasal_damp
		var out2 = _process_filter(source, filter2_state, c2) * g2 * nasal_damp
		vowel_signal = (out1 + out2) * vowel_volume * voiced_mix
		
		# Final Mix
		var frame = Vector2(vowel_signal + noise_signal, vowel_signal + noise_signal)
		playback.push_frame(frame)

func _apply_event(e: AudioEvent):
	if e.type == "closure":
		plosive_state = PlosiveState.CLOSURE
		env_target = 0.0
	elif e.type == "burst":
		plosive_state = PlosiveState.BURST
		plosive_counter = 0
		burst_dur_samples = e.duration_samples
		burst_amp = e.amplitude
		burst_spectrum = e.params.get("center", 2000)
	elif e.type == "fricative":
		fricative_state = FricativeState.ACTIVE
		fricative_counter = 0
		fricative_dur_samples = e.duration_samples
		fricative_amp = e.amplitude
		fricative_cutoff = e.params.get("center", 4000)
		fricative_voiced = e.params.get("voiced", false)
	elif e.type == "nasal":
		nasal_state = NasalState.ACTIVE
		nasal_counter = 0
		nasal_dur_samples = e.duration_samples

# --- DSP Utilities ---

func _get_filter_coeff(freq: float, q: float) -> Array:
	freq = clamp(freq, 20.0, sample_rate * 0.45)
	var omega = 2.0 * PI * freq / sample_rate
	var sn = sin(omega)
	var cs = cos(omega)
	var alpha = sn / (2.0 * q)
	
	var b0 = (1.0 - cs) / 2.0
	var b1 = 1.0 - cs
	var b2 = (1.0 - cs) / 2.0
	var a0 = 1.0 + alpha
	var a1 = -2.0 * cs
	var a2 = 1.0 - alpha
	
	return [b0/a0, b1/a0, b2/a0, a1/a0, a2/a0]

func _get_bp_coeff(freq: float, q: float) -> Array:
	freq = clamp(freq, 20.0, sample_rate * 0.45)
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

func _process_filter(x: float, s: Array, c: Array) -> float:
	var out = c[0]*x + s[0]
	s[0] = c[1]*x - c[3]*out + s[1]
	s[1] = c[2]*x - c[4]*out
	return out

func _poly_blep(t: float, dt: float) -> float:
	if t < dt:
		t /= dt
		return t + t - t * t - 1.0
	elif t > 1.0 - dt:
		t = (t - 1.0) / dt
		return t * t + t + t + 1.0
	else:
		return 0.0
