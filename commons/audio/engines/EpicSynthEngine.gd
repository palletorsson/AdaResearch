extends Node
class_name EpicSynthEngine

# EpicSynthEngine - Domain A: Analog Epic
# A modular DSP architecture for creating massive, cinematic analog sounds.
# Features: 7-voice SuperSaw Unison, Moog-style Ladder Filters, Analog Drift.

const SAMPLE_RATE: int = 44100
const MIX_RATE: int = 44100

# ----- PUBLIC API -----

static func generate_patch(patch_name: String, params: Dictionary = {}) -> AudioStreamWAV:
	match patch_name:
		"cs80_pad_1":
			return _generate_cs80_pad_1(params)
		"cs80_lead_1":
			return _generate_cs80_lead_1(params)
		"sub_bass":
			return _generate_sub_bass(params)
		_:
			push_warning("EpicSynthEngine: Unknown patch '%s'" % patch_name)
			return null

# ----- PATCH DEFINITIONS -----

# Patch 1: CS-80 Pad (The "Blade Runner" Foundation)
# Massive, swelling, drifting.
static func _generate_cs80_pad_1(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 12.0)
	var freq = params.get("freq", 110.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4) # Stereo
	
	# State
	var filter_l = _create_ladder_filter_state()
	var filter_r = _create_ladder_filter_state()
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# 1. Modulators
		var drift_lfo = sin(t * 0.2) * 0.005 # Slow pitch drift
		var pwm_lfo = sin(t * 1.5) * 0.3
		var swell_env = sin(progress * PI) # Simple swell for now
		
		# 2. Oscillators (SuperSaw Stack)
		# 7 voices per channel, detuned
		var osc_l = _super_saw_stack(freq * (1.0 + drift_lfo), t, 0.25)
		var osc_r = _super_saw_stack(freq * (1.0 - drift_lfo), t, 0.25) # Inverted drift for width
		
		# 3. Filter (24dB Ladder)
		# Cutoff modulated by envelope + velocity (simulated)
		var cutoff = lerp(300.0, 2500.0, swell_env)
		var res = 0.1
		
		var filt_l = _run_ladder_filter(osc_l, cutoff, res, filter_l)
		var filt_r = _run_ladder_filter(osc_r, cutoff, res, filter_r)
		
		# 4. Amp Envelope
		var amp = swell_env
		
		# 5. Effects (Chorus/Saturation)
		# Simple saturation
		filt_l = tanh(filt_l * 1.2)
		filt_r = tanh(filt_r * 1.2)
		
		_write_sample16_stereo(data, i, filt_l * amp * 0.3, filt_r * amp * 0.3)
		
	return _create_stream(data)

# Patch 2: CS-80 Lead (The "Vangelis" Voice)
# Expressive, singing, fragile.
static func _generate_cs80_lead_1(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 15.0)
	var freq = params.get("freq", 220.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	var filter_l = _create_ladder_filter_state()
	var filter_r = _create_ladder_filter_state()
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# 1. Modulators
		var vibrato = sin(t * 5.5) * 0.015 * clamp(progress * 4.0, 0.0, 1.0) # Delayed vibrato
		var drift = sin(t * 0.15) * 0.003
		
		var f = freq * (1.0 + vibrato + drift)
		
		# 2. Oscillators (Saw + Pulse)
		var saw = _saw_wave(f, t)
		var pulse = _pulse_wave(f, t, 0.4 + sin(t)*0.1) # PWM
		var raw = saw * 0.6 + pulse * 0.4
		
		# 3. Filter
		var cutoff = lerp(800.0, 4000.0, sin(progress * PI))
		var res = 0.2
		
		var filt_l = _run_ladder_filter(raw, cutoff, res, filter_l)
		var filt_r = _run_ladder_filter(raw, cutoff, res, filter_r) # Mono source, stereo filter
		
		# 4. Amp
		var amp = 1.0
		if progress < 0.1: amp = progress / 0.1
		elif progress > 0.9: amp = (1.0 - progress) / 0.1
		
		_write_sample16_stereo(data, i, filt_l * amp * 0.3, filt_r * amp * 0.3)
		
	return _create_stream(data)

# Patch 3: Sub Bass (The Foundation)
# Deep, clean, saturated.
static func _generate_sub_bass(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 10.0)
	var freq = params.get("freq", 55.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		
		# Sine + Saturation = Warm Sub
		var raw = sin(2.0 * PI * freq * t)
		var sat = tanh(raw * 2.0) * 0.8
		
		# Mono center
		_write_sample16_stereo(data, i, sat * 0.5, sat * 0.5)
		
	return _create_stream(data)

# ----- DSP MODULES -----

# SuperSaw Stack: 7 voices
# Returns a single float (mono sum of stack)
static func _super_saw_stack(freq: float, t: float, detune_amount: float) -> float:
	var sum = 0.0
	# Center
	sum += _saw_wave(freq, t)
	# Detuned pairs
	sum += _saw_wave(freq * (1.0 - 0.01 * detune_amount), t) * 0.8
	sum += _saw_wave(freq * (1.0 + 0.01 * detune_amount), t) * 0.8
	sum += _saw_wave(freq * (1.0 - 0.02 * detune_amount), t) * 0.6
	sum += _saw_wave(freq * (1.0 + 0.02 * detune_amount), t) * 0.6
	sum += _saw_wave(freq * (1.0 - 0.035 * detune_amount), t) * 0.4
	sum += _saw_wave(freq * (1.0 + 0.035 * detune_amount), t) * 0.4
	
	return sum * 0.25 # Normalize

# Moog-style Ladder Filter (4-pole, 24dB/oct)
# Returns filtered sample. Updates state in-place (simulated via dictionary).
static func _create_ladder_filter_state() -> Dictionary:
	return {"s1": 0.0, "s2": 0.0, "s3": 0.0, "s4": 0.0}

static func _run_ladder_filter(input: float, cutoff: float, resonance: float, state: Dictionary) -> float:
	var f = clamp(2.0 * cutoff / MIX_RATE, 0.0, 1.0)
	var k = 3.6 * f - 1.6 * f * f - 1.0 # Empirical tuning
	var p = (k + 1.0) * 0.5
	var scale = exp((1.0 - p) * 1.386249)
	var r = resonance * scale
	
	# Cascade
	var x = input - r * state.s4
	
	# 4 poles
	state.s1 = state.s1 + f * (tanh(x) - tanh(state.s1))
	state.s2 = state.s2 + f * (tanh(state.s1) - tanh(state.s2))
	state.s3 = state.s3 + f * (tanh(state.s2) - tanh(state.s3))
	state.s4 = state.s4 + f * (tanh(state.s3) - tanh(state.s4))
	
	return state.s4

# Basic Waveforms
static func _saw_wave(freq: float, t: float) -> float:
	return 2.0 * (t * freq - floor(t * freq + 0.5))

static func _pulse_wave(freq: float, t: float, width: float) -> float:
	var phase = t * freq - floor(t * freq)
	return 1.0 if phase < width else -1.0

# Helpers
static func _write_sample16_stereo(data: PackedByteArray, index: int, l: float, r: float):
	var l_int = int(clamp(l * 32767.0, -32768.0, 32767.0))
	var r_int = int(clamp(r * 32767.0, -32768.0, 32767.0))
	var offset = index * 4
	data[offset] = l_int & 0xFF
	data[offset + 1] = (l_int >> 8) & 0xFF
	data[offset + 2] = r_int & 0xFF
	data[offset + 3] = (r_int >> 8) & 0xFF

static func _create_stream(data: PackedByteArray) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = true
	stream.data = data
	return stream
