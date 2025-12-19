extends Node3D

# Vowel Synthesizer - Stage C: Full Robust Engine
# - PolyBLEP Band-Limited Oscillator
# - Sample-Accurate Event Scheduling
# - De-zippered Envelopes
# - DC Blocker
# - Block-Rate Parameter Smoothing (Anti-Zipper)
# - Source Gating (Silence Stability)

var playback: AudioStreamGeneratorPlayback
var sample_rate: float = 44100.0
var phase: float = 0.0
var pulse_hz: float = 130.0 

# Field Parameters
var f1: float = 500.0
var delta: float = 1000.0
# Derived
var f2: float = 1500.0

# Constraints
const F1_MIN = 200.0
const F1_MAX = 900.0

# Fixed Q
var q_factor: float = 12.0

# Filter State Class
class FilterState:
	var x1: float = 0.0
	var x2: float = 0.0
	var y1: float = 0.0
	var y2: float = 0.0

var filter1_state = FilterState.new()
var filter2_state = FilterState.new()

# Coefficients
var c1: PackedFloat32Array = PackedFloat32Array([0,0,0,0,0])
var c2: PackedFloat32Array = PackedFloat32Array([0,0,0,0,0])
var g1: float = 1.0
var g2: float = 1.0

# Control Interface
var target_intensity: float = 0.0 
var is_speaking: bool = false
var time_accum: float = 0.0

# Sample-Accurate Envelopes
var env: float = 0.0
var env_target: float = 0.0
var env_coeff_attack: float = 0.0
var env_coeff_release: float = 0.0

@export var attack_ms: float = 20.0
@export var release_ms: float = 40.0

# Parameter Smoothing (Block Rate)
var audio_target_f1: float = 500.0
var audio_target_delta: float = 1000.0
var audio_current_f1: float = 500.0
var audio_current_delta: float = 1000.0

# Fricative / Noise Mix Strategy
var voiced_mix: float = 1.0 # 1.0 = Full Vowel
var noise_mix: float = 0.0  # 0.0 = Silence
var voiced_mix_target: float = 1.0
var noise_mix_target: float = 0.0

# Fricative Filter State
var noise_filter_state = FilterState.new()
var noise_c: PackedFloat32Array = PackedFloat32Array([0,0,0,0,0])
var noise_center: float = 4000.0
var noise_q: float = 3.0
var audio_target_noise_center: float = 4000.0
var audio_current_noise_center: float = 4000.0

const BLOCK_SIZE: int = 32 # Re-calc coeffs every 32 samples (~0.7ms)

# DC Blocker
var dc_x1: float = 0.0
var dc_y1: float = 0.0
const DC_R: float = 0.995

# Noise Source
var noise = FastNoiseLite.new()
var noise_phase: float = 0.0

# Event Scheduling
class AudioEvent:
	var at_sample: int
	var type: String
	var duration_samples: int
	var amplitude: float
	var params: Dictionary = {}

var events: Array[AudioEvent] = []
var sample_clock: int = 0

# Plosive Logic State
enum PlosiveState { NONE, CLOSURE, BURST }
var plosive_state: int = PlosiveState.NONE
var plosive_counter: int = 0
var burst_amp: float = 0.0
var burst_dur_samples: int = 0
var burst_spectrum: float = 2000.0

# === NEW: Fricative State ===
enum FricativeState { NONE, ACTIVE }
var fricative_state: int = FricativeState.NONE
var fricative_counter: int = 0
var fricative_dur_samples: int = 0
var fricative_amp: float = 0.0
var fricative_cutoff: float = 5000.0
var fricative_voiced: bool = false

# === NEW: Nasal State ===
enum NasalState { NONE, ACTIVE }
var nasal_state: int = NasalState.NONE
var nasal_counter: int = 0
var nasal_dur_samples: int = 0
var nasal_f1: float = 250.0
var nasal_delta: float = 800.0

# === NEW: Consonant Parameters ===
const FRICATIVE_PARAMS = {
	"s": {"cutoff": 6000, "amp": 0.8, "voiced": false},
	"z": {"cutoff": 5500, "amp": 0.7, "voiced": true},
	"f": {"cutoff": 4000, "amp": 0.6, "voiced": false},
	"v": {"cutoff": 3500, "amp": 0.5, "voiced": true},
	"sh": {"cutoff": 3000, "amp": 0.7, "voiced": false},
	"th": {"cutoff": 5000, "amp": 0.5, "voiced": false},
	"h": {"cutoff": 2000, "amp": 0.4, "voiced": false},
}

const PLOSIVE_PARAMS = {
	"p": {"closure_ms": 50, "burst_ms": 15, "amp": 0.4, "locus": 800},
	"b": {"closure_ms": 30, "burst_ms": 12, "amp": 0.3, "locus": 800, "voiced": true},
	"t": {"closure_ms": 40, "burst_ms": 12, "amp": 0.35, "locus": 1800},
	"d": {"closure_ms": 25, "burst_ms": 10, "amp": 0.25, "locus": 1800, "voiced": true},
	"k": {"closure_ms": 45, "burst_ms": 18, "amp": 0.45, "locus": 2500},
	"g": {"closure_ms": 30, "burst_ms": 15, "amp": 0.35, "locus": 2500, "voiced": true},
}

const NASAL_PARAMS = {
	"m": {"f1": 280, "delta": 800, "amp": 0.4},
	"n": {"f1": 280, "delta": 1400, "amp": 0.35},
	"ng": {"f1": 280, "delta": 2000, "amp": 0.3}
}

const APPROXIMANT_PARAMS = {
	"l": {"f1": 400, "delta": 800, "amp": 0.5},
	"r": {"f1": 450, "delta": 750, "amp": 0.6},
	"w": {"f1": 300, "delta": 300, "amp": 0.5},
	"y": {"f1": 300, "delta": 1800, "amp": 0.5}
}

const AFFRICATE_PARAMS = {
	"ch": {"closure_ms": 40, "burst_ms": 100, "cutoff": 3500, "amp": 0.7, "voiced": false},
	"j": {"closure_ms": 30, "burst_ms": 80, "cutoff": 3000, "amp": 0.6, "voiced": true}
}

# Buffer
var _buffer: PackedVector2Array = PackedVector2Array()

@onready var player: AudioStreamPlayer3D = $AudioStreamPlayer3D

func _ready():
	_buffer.resize(512)
	if not player:
		player = AudioStreamPlayer3D.new()
		add_child(player)
	
	var generator = AudioStreamGenerator.new()
	generator.mix_rate = sample_rate
	generator.buffer_length = 0.2
	player.stream = generator
	player.play()
	playback = player.get_stream_playback()
	
	env_coeff_attack = _ms_to_coeff(attack_ms)
	env_coeff_release = _ms_to_coeff(release_ms)
	
	_update_coefficients()
	
	# Init Smoothing State
	audio_target_f1 = f1
	audio_target_delta = delta
	audio_current_f1 = f1
	audio_current_delta = delta
	
	# Init Noise
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.5
	noise.seed = randi()

func _ms_to_coeff(ms: float) -> float:
	var tau = max(0.001, ms / 1000.0)
	return exp(-1.0 / (sample_rate * tau))

func _process(delta_time):
	# Parameter Drift (Life)
	var time = Time.get_ticks_msec() / 1000.0
	var drift_f1 = sin(time * 1.5) * 3.0
	var drift_delta = sin(time * 2.1) * 5.0
	
	var t_f1 = clamp(f1 + drift_f1, F1_MIN, F1_MAX)
	var t_delta = max(delta + drift_delta, 200.0)
	
	# Jitter
	var jitter = (randf() * 2.0 - 1.0) * 15.0
	t_f1 += jitter
	t_delta += jitter * 0.5
	
	var t_f2 = t_f1 + t_delta
	t_f2 = min(t_f2, sample_rate * 0.45)
	
	# No Control Rate Coeff Update (Done in Audio Loop)
	# Push targets to Audio Loop
	audio_target_f1 = t_f1 
	
	# Note: audio loop calculates f2 dynamically, so we just push delta
	audio_target_delta = t_delta
	
	# We still need to respect Nyquist for safety in loop, but here we just pass rough targets
	
	env_target = target_intensity
	
	_fill_until(2048)

# Anchors for Compatibility (speak_vowel)
const ANCHORS_COMPAT = {
	"i": Vector2(240, 2160),
	"e": Vector2(390, 1910),
	"a": Vector2(850, 760),
	"o": Vector2(360, 280),
	"u": Vector2(250, 345)
}

func speak_vowel(key: String, burst_intensity: float = 1.0):
	if key in ANCHORS_COMPAT:
		var a = ANCHORS_COMPAT[key]
		# Direct assignment for compatibility. Smoothng handles the rest.
		f1 = a.x
		delta = a.y
		# Update target hooks for smooth engine
		audio_target_f1 = f1
		audio_target_delta = delta
	
	is_speaking = true
	target_intensity = burst_intensity
	env_target = burst_intensity

func stop():
	is_speaking = false
	target_intensity = 0.0
	env_target = 0.0


# === NEW: Fricative Synthesis ===
func trigger_fricative(consonant: String = "s", duration_ms: float = 120):
	if not consonant in FRICATIVE_PARAMS:
		consonant = "s"
	
	var params = FRICATIVE_PARAMS[consonant]
	
	var e = AudioEvent.new()
	e.at_sample = sample_clock
	e.type = "fricative"
	e.duration_samples = int((duration_ms / 1000.0) * sample_rate)
	e.amplitude = params.amp
	e.params = params
	events.append(e)

# === NEW: Plosive Synthesis ===
func trigger_plosive(consonant: String = "t"):
	if not consonant in PLOSIVE_PARAMS:
		consonant = "t"
	
	var params = PLOSIVE_PARAMS[consonant]
	
	var closure_samples = int((params.closure_ms / 1000.0) * sample_rate)
	var burst_samples = int((params.burst_ms / 1000.0) * sample_rate)
	
	# Closure event
	var e1 = AudioEvent.new()
	e1.at_sample = sample_clock
	e1.type = "closure"
	events.append(e1)
	
	# Burst event
	var e2 = AudioEvent.new()
	e2.at_sample = sample_clock + closure_samples
	e2.type = "burst"
	e2.duration_samples = burst_samples
	e2.amplitude = params.amp
	e2.params = {"locus": params.locus, "voiced": params.get("voiced", false)}
	events.append(e2)

# === NEW: Nasal Synthesis ===
func trigger_nasal(consonant: String = "m", duration_ms: float = 150):
	if not consonant in NASAL_PARAMS:
		consonant = "m"
		
	var params = NASAL_PARAMS[consonant]
	var dur_samples = int((duration_ms / 1000.0) * sample_rate)
	
	var e1 = AudioEvent.new()
	e1.at_sample = sample_clock
	e1.type = "nasal_start"
	e1.params = params
	events.append(e1)
	
	var e2 = AudioEvent.new()
	e2.at_sample = sample_clock + dur_samples
	e2.type = "nasal_end"
	events.append(e2)

# === NEW: Approximant (Liquids/Glides) ===
func trigger_approximant(consonant: String = "l", duration_ms: float = 120):
	if not consonant in APPROXIMANT_PARAMS:
		consonant = "l"
		
	var params = APPROXIMANT_PARAMS[consonant]
	var dur_samples = int((duration_ms / 1000.0) * sample_rate)
	
	var e1 = AudioEvent.new()
	e1.at_sample = sample_clock
	e1.type = "approximant_start"
	e1.params = params
	events.append(e1)
	
	var e2 = AudioEvent.new()
	e2.at_sample = sample_clock + dur_samples
	e2.type = "approximant_end"
	events.append(e2)

# === NEW: Affricate (Plosive + Fricative) ===
func trigger_affricate(consonant: String = "ch"):
	if not consonant in AFFRICATE_PARAMS:
		consonant = "ch"
		
	var params = AFFRICATE_PARAMS[consonant]
	var closure_samples = int((params.closure_ms / 1000.0) * sample_rate)
	
	# 1. Closure (Silence)
	var e1 = AudioEvent.new()
	e1.at_sample = sample_clock
	e1.type = "closure"
	events.append(e1)
	
	# 2. Release (Fricative Noise)
	var e2 = AudioEvent.new()
	e2.at_sample = sample_clock + closure_samples
	e2.type = "fricative"
	e2.duration_samples = int((params.burst_ms / 1000.0) * sample_rate)
	e2.amplitude = params.amp
	e2.params = {"cutoff": params.cutoff, "voiced": params.voiced}
	events.append(e2)

func release_fricative():
	print("Synth: Release fricative - Not implemented in Phase 1")
	# Maintain voiced mix for compatibility
	voiced_mix_target = 1.0
	noise_mix_target = 0.0


func _fill_until(min_free: int):
	if not playback: return
	var available = playback.get_frames_available()
	while available > min_free:
		var chunk = min(available - min_free, 512)
		if chunk <= 0: break
		if _buffer.size() != chunk: _buffer.resize(chunk)
		_process_audio_chunk(chunk)
		playback.push_buffer(_buffer)
		available -= chunk

func _process_audio_chunk(frames: int):
	var phase_inc = pulse_hz / sample_rate
	
	for i in range(frames):
		# 0. Block-Rate Parameter Smoothing
		if sample_clock % BLOCK_SIZE == 0:
			# Frequencies
			audio_current_f1 += (audio_target_f1 - audio_current_f1) * 0.1
			audio_current_delta += (audio_target_delta - audio_current_delta) * 0.1
			audio_current_noise_center += (audio_target_noise_center - audio_current_noise_center) * 0.1
			
			var curr_f2 = audio_current_f1 + audio_current_delta
			curr_f2 = min(curr_f2, sample_rate * 0.45)
			
			# Vowel Filters
			_recalculate_filter_coeffs(audio_current_f1, c1)
			_recalculate_filter_coeffs(curr_f2, c2)
			
			# Noise Filter
			_recalculate_filter_coeffs_noise(audio_current_noise_center, noise_q, noise_c)
			
			# Recalc Gain
			g1 = 1.0
			g2 = 1.0 + (curr_f2 / 2000.0)

		# 1. Process Events
		for j in range(events.size() - 1, -1, -1):
			var e = events[j]
			if sample_clock >= e.at_sample:
				_apply_event(e)
				events.remove_at(j)
		
		# 1.5 Smooth Mixes (Simple Lowpass per sample for silky crossfade)
		# Time constant ~10ms -> coeff ~0.005
		voiced_mix += (voiced_mix_target - voiced_mix) * 0.005
		noise_mix += (noise_mix_target - noise_mix) * 0.005
		
		var vowel_signal = 0.0
		var noise_signal = 0.0
		var plosive_noise = 0.0
		
		# === NEW: Fricative Generation (Triggered) ===
		if fricative_state == FricativeState.ACTIVE:
			if fricative_counter < fricative_dur_samples:
				var t = float(fricative_counter) / float(fricative_dur_samples)
				var fric_env = sin(t * PI)
				
				noise_phase += 1.0
				var noise_val = noise.get_noise_2d(
					cos(noise_phase * 0.05) * 100.0,
					sin(noise_phase * 0.05) * 100.0
				)
				
				var shaped = noise_val * (fricative_cutoff / 10000.0)
				
				if fricative_voiced:
					var voice_phase = (sample_clock * pulse_hz / sample_rate)
					shaped += sin(voice_phase * TAU) * 0.2
				
				noise_signal += shaped * fricative_amp * fric_env
				fricative_counter += 1
			else:
				fricative_state = FricativeState.NONE
				
		# A. Burst (Legacy Plosive - "The Pop")
		if plosive_state == PlosiveState.BURST:
			if plosive_counter < burst_dur_samples:
				var t = float(plosive_counter) / float(burst_dur_samples)
				var burst_env = 0.0
				if t < 0.2: burst_env = t / 0.2
				elif t > 0.8: burst_env = (1.0 - t) / 0.2
				else: burst_env = 1.0
				
				# Use F2 locus resonance if available
				var locus_res = sin(plosive_counter * burst_spectrum * TAU / sample_rate) * 0.2
				noise_signal += ((randf() * 2.0 - 1.0) + locus_res) * burst_amp * burst_env
				plosive_counter += 1
			else:
				plosive_state = PlosiveState.NONE
				
		# B. Vowel Path (Voiced)
		var source = 0.0
		if env > 0.0001 or env_target > 0.0001:
			phase += phase_inc
			if phase >= 1.0: phase -= 1.0
			var naive_saw = (phase * 2.0) - 1.0
			var poly = _poly_blep(phase, phase_inc)
			source = (naive_saw - poly) * 0.5 
			source *= env # Pre-filter envelope (pressure)
		
		var out1 = _process_filter(source, filter1_state, c1) * g1
		var out2 = _process_filter(source, filter2_state, c2) * g2
		vowel_signal = (out1 + out2) * 0.15 * voiced_mix
		
		# C. Legacy Fricative / Breath Path (noise_mix)
		if noise_mix > 0.001:
			var raw_noise = (randf() * 2.0 - 1.0) * 0.5
			raw_noise *= env 
			var filtered_noise = _process_filter(raw_noise, noise_filter_state, noise_c)
			noise_signal += filtered_noise * noise_mix * 2.0
			
		# D. Envelope Tracking
		var coeff = env_coeff_attack if env_target > env else env_coeff_release
		env = env_target + (env - env_target) * coeff
		
		# Final output
		var output_sample = vowel_signal + noise_signal
		
		# DC Blocker
		var y = output_sample - dc_x1 + DC_R * dc_y1
		dc_x1 = output_sample
		dc_y1 = y
		output_sample = y
		
		_buffer[i] = Vector2(output_sample, output_sample)
		sample_clock += 1

func _apply_event(e: AudioEvent):
	if e.type == "closure":
		plosive_state = PlosiveState.CLOSURE
		env_target = 0.0
	elif e.type == "burst":
		plosive_state = PlosiveState.BURST
		plosive_counter = 0
		burst_dur_samples = e.duration_samples
		burst_amp = e.amplitude
		burst_spectrum = e.params.get("locus", 2000)
	elif e.type == "fricative":
		fricative_state = FricativeState.ACTIVE
		fricative_counter = 0
		fricative_dur_samples = e.duration_samples
		fricative_amp = e.amplitude
		fricative_cutoff = e.params.get("cutoff", 5000)
		fricative_voiced = e.params.get("voiced", false)
	elif e.type == "nasal_start":
		nasal_state = NasalState.ACTIVE
		audio_target_f1 = e.params.f1
		audio_target_delta = e.params.delta
		target_intensity = e.params.amp
		is_speaking = true
	elif e.type == "nasal_end":
		nasal_state = NasalState.NONE
		# We don't stop here, we leave it to the next vowel or manual stop
	elif e.type == "approximant_start":
		audio_target_f1 = e.params.f1
		audio_target_delta = e.params.delta
		target_intensity = e.params.amp
		is_speaking = true
	elif e.type == "approximant_end":
		# We don't stop, just leave the state (can glide into vowels)
		pass
		
func _poly_blep(t: float, dt: float) -> float:
	if t < dt:
		t /= dt
		return t+t - t*t - 1.0
	elif t > 1.0 - dt:
		t = (t - 1.0) / dt
		return t*t + t+t + 1.0
	else:
		return 0.0

func _update_coefficients():
	_recalculate_filter_coeffs(f1, c1)
	_recalculate_filter_coeffs(f1 + delta, c2)

func _recalculate_filter_coeffs(freq: float, c: PackedFloat32Array):
	var w0 = TAU * freq / sample_rate
	var alpha = sin(w0) / (2.0 * q_factor)
	var cos_w0 = cos(w0)
	var a0 = 1.0 + alpha
	var inv_a0 = 1.0 / a0
	c[0] = alpha * inv_a0
	c[1] = 0.0
	c[2] = -alpha * inv_a0
	c[3] = (-2.0 * cos_w0) * inv_a0
	c[4] = (1.0 - alpha) * inv_a0

func _recalculate_filter_coeffs_noise(freq: float, q_val: float, c: PackedFloat32Array):
	# BandPass Filter (Biquad)
	# H(s) = s / (s^2 + s/Q + 1) -> normalized BPF
	# Check Audio Eq Cookbook
	
	var w0 = TAU * freq / sample_rate
	var alpha = sin(w0) / (2.0 * q_val)
	var a0 = 1.0 + alpha
	var inv_a0 = 1.0 / a0
	
	c[0] = alpha * inv_a0
	c[1] = 0.0
	c[2] = -alpha * inv_a0
	c[3] = (-2.0 * cos(w0)) * inv_a0
	c[4] = (1.0 - alpha) * inv_a0

func _process_filter(input: float, s: FilterState, c: PackedFloat32Array) -> float:
	var output = c[0]*input + c[1]*s.x1 + c[2]*s.x2 - c[3]*s.y1 - c[4]*s.y2
	# Soft Saturation
	if output > 4.0: output = 4.0 + (output - 4.0) / (1.0 + (output - 4.0))
	elif output < -4.0: output = -4.0 + (output + 4.0) / (1.0 - (output + 4.0))
	if abs(output) < 1e-20: output = 0.0
	s.x2 = s.x1; s.x1 = input; s.y2 = s.y1; s.y1 = output
	return output
