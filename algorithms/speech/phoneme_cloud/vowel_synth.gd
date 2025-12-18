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

# Event Scheduling
class AudioEvent:
	var at_sample: int
	var type: String
	var duration_samples: int
	var amplitude: float

var events: Array[AudioEvent] = []
var sample_clock: int = 0

# Plosive Logic State
enum PlosiveState { NONE, CLOSURE, BURST }
var plosive_state: int = PlosiveState.NONE
var plosive_counter: int = 0
var burst_amp: float = 0.0
var burst_dur_samples: int = 0

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

func trigger_fricative(type: String):
	# "Noise Event" override
	if type == "s":
		audio_target_noise_center = 6000.0
		noise_q = 3.0
	elif type == "sh" or type == "ch":
		audio_target_noise_center = 3500.0
		noise_q = 2.0
	
	# Crossfade: Vowel -> Noise
	voiced_mix_target = 0.0
	noise_mix_target = 1.0
	
	# Ensure envelope is open for the noise to be heard!
	# Fricatives need "lung pressure" too.
	env_target = 1.0 
	is_speaking = true

func release_fricative():
	# Crossfade: Noise -> Vowel (or Silence if stop called)
	voiced_mix_target = 1.0
	noise_mix_target = 0.0

func trigger_plosive():
	var closure_samples = int(0.03 * sample_rate)
	var burst_samples = int(0.015 * sample_rate)
	
	var e1 = AudioEvent.new()
	e1.at_sample = sample_clock
	e1.type = "closure"
	events.append(e1)
	
	var e2 = AudioEvent.new()
	e2.at_sample = sample_clock + closure_samples
	e2.type = "burst"
	e2.duration_samples = burst_samples
	e2.amplitude = 0.35
	events.append(e2)

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
		var fricative_signal = 0.0
		var plosive_noise = 0.0
		
		# A. Burst (Legacy Plosive - "The Pop")
		if plosive_state == PlosiveState.BURST:
			if plosive_counter < burst_dur_samples:
				var t = float(plosive_counter) / float(burst_dur_samples)
				var burst_env = 0.0
				if t < 0.2: burst_env = t / 0.2
				elif t > 0.8: burst_env = (1.0 - t) / 0.2
				else: burst_env = 1.0
				plosive_noise = (randf() * 2.0 - 1.0) * burst_amp * burst_env
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
		
		# C. Fricative Path (Noise)
		# Valid if noise_mix > 0.001
		if noise_mix > 0.001:
			var raw_noise = (randf() * 2.0 - 1.0) * 0.5
			# Apply Envelope (Lung Pressure) to noise too!
			raw_noise *= env 
			
			fricative_signal = _process_filter(raw_noise, noise_filter_state, noise_c)
			fricative_signal *= noise_mix * 2.0 # Boost noise a bit
			
		# D. Envelope (Applied Pre-Filter for Source, but globally for cleanup?)
		# No, we applied it pre-filter.
		# But wait, original code applied it POST filter too.
		# "vowel_signal *= env" was at the end.
		# Now we apply it to source.
		# Should we apply distinct envelope to fricative? Same env.
		
		# E. Mix & Envelope
		var coeff = env_coeff_attack if env_target > env else env_coeff_release
		env = env_target + (env - env_target) * coeff
		
		# Final output
		var output_sample = vowel_signal + fricative_signal + plosive_noise
		
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
