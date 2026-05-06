# Juno-106 PWM Pad with BBD Chorus
# The classic 80s polysynth pad sound — warm, wide, endlessly usable
extends RefCounted
class_name JunoPad

const VOICE_COUNT = 6
const SAMPLE_RATE = 44100.0

# Oscillator parameters
var pulse_width_base: float = 0.5
var pwm_depth: float = 0.3  # How much the pulse width modulates
var pwm_rate: float = 0.7  # Hz — slow, dreamy modulation
var sub_osc_level: float = 0.3  # Square wave one octave down
var oscillator_drift: float = 3.0  # Cents of random drift (analog character)

# Filter parameters  
var filter_cutoff: float = 2200.0  # Hz
var filter_resonance: float = 0.25  # Gentle, musical resonance
var filter_env_amount: float = 800.0  # Hz of envelope modulation
var filter_env_attack: float = 0.15  # Seconds
var filter_env_decay: float = 0.4
var filter_env_sustain: float = 0.6

# Amp envelope
var amp_attack: float = 0.25  # Slow attack for pad character
var amp_decay: float = 0.3
var amp_sustain: float = 0.8
var amp_release: float = 1.2  # Long release, notes blend

# BBD Chorus (the Juno secret sauce)
var chorus_enabled: bool = true
var chorus_mode: int = 2  # 1 = Chorus I, 2 = Chorus II, 3 = I+II
var chorus_rate_1: float = 0.52  # Hz
var chorus_rate_2: float = 0.82  # Hz (slightly faster for mode 2)
var chorus_depth_1: float = 0.0008  # Seconds (subtle)
var chorus_depth_2: float = 0.0018  # Seconds (thicker)
var chorus_delay_base_l: float = 0.003  # Base delay left
var chorus_delay_base_r: float = 0.0035  # Slightly different for stereo

# Internal state per voice
var voice_phases: Array = []
var voice_sub_phases: Array = []
var voice_drift_offsets: Array = []
var voice_drift_rates: Array = []
var voice_filter_states: Array = []
var voice_amp_envs: Array = []
var voice_filter_envs: Array = []

# Chorus delay buffers
var chorus_buffer_l: PackedFloat32Array
var chorus_buffer_r: PackedFloat32Array
var chorus_buffer_size: int = 4096
var chorus_write_pos: int = 0
var chorus_lfo_phase_1: float = 0.0
var chorus_lfo_phase_2: float = 0.0


func _init():
	_init_voices()
	_init_chorus()


func _init_voices():
	voice_phases.resize(VOICE_COUNT)
	voice_sub_phases.resize(VOICE_COUNT)
	voice_drift_offsets.resize(VOICE_COUNT)
	voice_drift_rates.resize(VOICE_COUNT)
	voice_filter_states.resize(VOICE_COUNT)
	voice_amp_envs.resize(VOICE_COUNT)
	voice_filter_envs.resize(VOICE_COUNT)
	
	for i in VOICE_COUNT:
		voice_phases[i] = randf()  # Random start phase
		voice_sub_phases[i] = randf()
		voice_drift_offsets[i] = randf() * TAU
		voice_drift_rates[i] = 0.05 + randf() * 0.15  # Very slow drift
		voice_filter_states[i] = [0.0, 0.0]  # 2-pole state
		voice_amp_envs[i] = {"phase": "off", "value": 0.0, "time": 0.0}
		voice_filter_envs[i] = {"phase": "off", "value": 0.0, "time": 0.0}


func _init_chorus():
	chorus_buffer_l.resize(chorus_buffer_size)
	chorus_buffer_r.resize(chorus_buffer_size)
	chorus_buffer_l.fill(0.0)
	chorus_buffer_r.fill(0.0)


func trigger_note(voice_index: int, frequency: float, velocity: float):
	if voice_index >= VOICE_COUNT:
		return
	
	voice_amp_envs[voice_index] = {"phase": "attack", "value": 0.0, "time": 0.0, "target": velocity}
	voice_filter_envs[voice_index] = {"phase": "attack", "value": 0.0, "time": 0.0}


func release_note(voice_index: int):
	if voice_index >= VOICE_COUNT:
		return
	voice_amp_envs[voice_index]["phase"] = "release"
	voice_filter_envs[voice_index]["phase"] = "release"


func generate_sample(frequency: float, time: float, voice_index: int = 0) -> Dictionary:
	if voice_index >= VOICE_COUNT:
		return {"left": 0.0, "right": 0.0}
	
	var dt = 1.0 / SAMPLE_RATE
	
	# Update envelopes
	var amp_env = _update_envelope(voice_amp_envs[voice_index], amp_attack, amp_decay, amp_sustain, amp_release, dt)
	var filter_env = _update_envelope(voice_filter_envs[voice_index], filter_env_attack, filter_env_decay, filter_env_sustain, 0.5, dt)
	
	if amp_env <= 0.001:
		return {"left": 0.0, "right": 0.0}
	
	# Analog drift
	voice_drift_offsets[voice_index] += voice_drift_rates[voice_index] * dt
	var drift_cents = sin(voice_drift_offsets[voice_index]) * oscillator_drift
	var drifted_freq = frequency * pow(2.0, drift_cents / 1200.0)
	
	# PWM LFO
	var pwm_lfo = sin(time * TAU * pwm_rate)
	var current_pw = clamp(pulse_width_base + pwm_lfo * pwm_depth, 0.1, 0.9)
	
	# Main oscillator (pulse wave with PWM)
	voice_phases[voice_index] += drifted_freq / SAMPLE_RATE
	voice_phases[voice_index] = fmod(voice_phases[voice_index], 1.0)
	var pulse = 1.0 if voice_phases[voice_index] < current_pw else -1.0
	
	# Sub oscillator (square, one octave down)
	voice_sub_phases[voice_index] += (drifted_freq * 0.5) / SAMPLE_RATE
	voice_sub_phases[voice_index] = fmod(voice_sub_phases[voice_index], 1.0)
	var sub = 1.0 if voice_sub_phases[voice_index] < 0.5 else -1.0
	
	# Mix oscillators
	var osc_mix = pulse * 0.7 + sub * sub_osc_level
	
	# Filter with envelope
	var current_cutoff = filter_cutoff + filter_env * filter_env_amount
	var filtered = _lowpass_filter(osc_mix, current_cutoff, filter_resonance, voice_index)
	
	# Apply amp envelope
	var output = filtered * amp_env * 0.4
	
	# Stereo output (before chorus)
	var left = output
	var right = output
	
	# BBD Chorus processing
	if chorus_enabled:
		var chorus_result = _process_chorus(output, dt)
		left = chorus_result["left"]
		right = chorus_result["right"]
	
	return {"left": left, "right": right}


func _update_envelope(env: Dictionary, attack: float, decay: float, sustain: float, release: float, dt: float) -> float:
	match env["phase"]:
		"attack":
			env["time"] += dt
			env["value"] = env["time"] / attack
			if env["value"] >= 1.0:
				env["value"] = 1.0
				env["phase"] = "decay"
				env["time"] = 0.0
		"decay":
			env["time"] += dt
			var t = env["time"] / decay
			env["value"] = lerp(1.0, sustain, min(t, 1.0))
			if t >= 1.0:
				env["phase"] = "sustain"
		"sustain":
			env["value"] = sustain
		"release":
			env["time"] += dt
			var t = env["time"] / release
			env["value"] = lerp(env.get("release_start", sustain), 0.0, min(t, 1.0))
			if t >= 1.0:
				env["phase"] = "off"
				env["value"] = 0.0
		"off":
			env["value"] = 0.0
	
	return env["value"]


func _lowpass_filter(input: float, cutoff: float, resonance: float, voice_index: int) -> float:
	# Simple 2-pole lowpass (SVF style)
	var f = clamp(cutoff / SAMPLE_RATE, 0.001, 0.499)
	var q = 1.0 - resonance
	
	var state = voice_filter_states[voice_index]
	var lp = state[0]
	var bp = state[1]
	
	lp += f * bp
	var hp = input - lp - q * bp
	bp += f * hp
	
	voice_filter_states[voice_index] = [lp, bp]
	return lp


func _process_chorus(input: float, dt: float) -> Dictionary:
	# Write to delay buffer
	chorus_buffer_l[chorus_write_pos] = input
	chorus_buffer_r[chorus_write_pos] = input
	
	# Update LFOs
	chorus_lfo_phase_1 += chorus_rate_1 * dt
	chorus_lfo_phase_2 += chorus_rate_2 * dt
	
	var lfo1 = sin(chorus_lfo_phase_1 * TAU)
	var lfo2 = sin(chorus_lfo_phase_2 * TAU)
	
	var left = input
	var right = input
	
	# Chorus I
	if chorus_mode == 1 or chorus_mode == 3:
		var delay_l = chorus_delay_base_l + lfo1 * chorus_depth_1
		var delay_r = chorus_delay_base_r + lfo1 * chorus_depth_1
		left += _read_delay(chorus_buffer_l, delay_l) * 0.5
		right += _read_delay(chorus_buffer_r, delay_r) * 0.5
	
	# Chorus II
	if chorus_mode == 2 or chorus_mode == 3:
		var delay_l = chorus_delay_base_l + lfo2 * chorus_depth_2
		var delay_r = chorus_delay_base_r - lfo2 * chorus_depth_2  # Inverted for width
		left += _read_delay(chorus_buffer_l, delay_l) * 0.5
		right += _read_delay(chorus_buffer_r, delay_r) * 0.5
	
	# Advance write position
	chorus_write_pos = (chorus_write_pos + 1) % chorus_buffer_size
	
	return {"left": left * 0.7, "right": right * 0.7}


func _read_delay(buffer: PackedFloat32Array, delay_seconds: float) -> float:
	var delay_samples = delay_seconds * SAMPLE_RATE
	var read_pos = chorus_write_pos - int(delay_samples)
	if read_pos < 0:
		read_pos += chorus_buffer_size
	return buffer[read_pos % chorus_buffer_size]
