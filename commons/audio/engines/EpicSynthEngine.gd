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
		"choir_ensemble":
			return _generate_choir_ensemble(params)
		"string_machine":
			return _generate_string_machine(params)
		"metallic_hit":
			return _generate_metallic_hit(params)
		"pedal_steel":
			return _generate_pedal_steel(params)
		"analog_pluck":
			return _generate_analog_pluck(params)
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

# Patch 4: Choir Ensemble (Formant Filtered SuperSaw)
# Airy, vocal, sacred.
static func _generate_choir_ensemble(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 12.0)
	var freq = params.get("freq", 220.0) # Root note
	var vowel = params.get("vowel", "ooh") # "aah" or "ooh"
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	# Formants (Approximate)
	# Ooh: 300, 800, 2500
	# Aah: 600, 1000, 2500
	var f1 = 300.0; var f2 = 800.0; var f3 = 2500.0
	if vowel == "aah": f1=600.0; f2=1000.0; f3=2500.0
	
	# State for parallel filters
	# We need 3 BP filters per channel = 6 states
	var bp_l1 = {"y1":0.0, "y2":0.0, "x1":0.0, "x2":0.0}
	var bp_l2 = {"y1":0.0, "y2":0.0, "x1":0.0, "x2":0.0}
	var bp_l3 = {"y1":0.0, "y2":0.0, "x1":0.0, "x2":0.0}
	
	var bp_r1 = {"y1":0.0, "y2":0.0, "x1":0.0, "x2":0.0}
	var bp_r2 = {"y1":0.0, "y2":0.0, "x1":0.0, "x2":0.0}
	var bp_r3 = {"y1":0.0, "y2":0.0, "x1":0.0, "x2":0.0}
	
	# Pre-calc coeffs (Static formants for now)
	var c1 = _calc_bp_coeffs(f1, 5.0) # High Q for resonance
	var c2 = _calc_bp_coeffs(f2, 8.0)
	var c3 = _calc_bp_coeffs(f3, 10.0)
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# 1. Modulators
		var vib = sin(t * 4.0) * 0.005 # Pitch wobble
		var swell = sin(progress * PI)
		
		# 2. Source: SuperSaw Stack (Rich harmonics)
		var raw_l = _super_saw_stack(freq * (1.0 + vib), t, 0.3)
		var raw_r = _super_saw_stack(freq * (1.0 - vib), t, 0.4)
		
		# 3. Formant Filtering (Parallel)
		# Left
		var l1 = _run_biquad(raw_l, c1, bp_l1)
		var l2 = _run_biquad(raw_l, c2, bp_l2)
		var l3 = _run_biquad(raw_l, c3, bp_l3)
		var out_l = l1*1.5 + l2*1.0 + l3*0.5
		
		# Right
		var r1 = _run_biquad(raw_r, c1, bp_r1)
		var r2 = _run_biquad(raw_r, c2, bp_r2)
		var r3 = _run_biquad(raw_r, c3, bp_r3)
		var out_r = r1*1.5 + r2*1.0 + r3*0.5
		
		# 4. Saturation (Warmth)
		out_l = tanh(out_l * 2.0)
		out_r = tanh(out_r * 2.0)
		
		_write_sample16_stereo(data, i, out_l * swell * 0.4, out_r * swell * 0.4)
		
	return _create_stream(data)

# Patch 5: String Machine (Solina Style)
static func _generate_string_machine(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 12.0)
	var freq = params.get("freq", 220.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	# Chorus state (3 delay lines)
	var delay_buffer = []
	delay_buffer.resize(4096)
	delay_buffer.fill(0.0)
	var write_head = 0
	
	var delay_time_1 = 0.005 # 5ms
	var delay_time_2 = 0.007 # 7ms
	var delay_time_3 = 0.010 # 10ms
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		
		# Solina Source: Sawtooth + Upper Octave
		var saw = _saw_wave(freq, t)
		var saw_oct = _saw_wave(freq * 2.0, t) * 0.5
		var raw = (saw + saw_oct) * 0.5
		
		# Write to delay
		delay_buffer[write_head] = raw
		
		# Modulate Delay Times (Ensemble LFOs)
		var lfo1 = sin(t * 0.6) * 0.001
		var lfo2 = sin(t * 0.83) * 0.001
		var lfo3 = sin(t * 1.1) * 0.001
		
		var tap1 = _read_delay_cubic(delay_buffer, write_head, (delay_time_1 + lfo1) * MIX_RATE)
		var tap2 = _read_delay_cubic(delay_buffer, write_head, (delay_time_2 + lfo2) * MIX_RATE)
		var tap3 = _read_delay_cubic(delay_buffer, write_head, (delay_time_3 + lfo3) * MIX_RATE)
		
		# Mix Taps (Stereo Spread)
		var left = (raw * 0.4) + tap1 * 0.5 + tap2 * 0.2 - tap3 * 0.2
		var right = (raw * 0.4) - tap1 * 0.2 + tap2 * 0.5 + tap3 * 0.2
		
		# Increment
		write_head = (write_head + 1) % 4096
		
		_write_sample16_stereo(data, i, left * 0.6, right * 0.6)
		
	return _create_stream(data)

# Patch 6: Metallic Hit (FM Percussion)
static func _generate_metallic_hit(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 2.0)
	var freq = params.get("freq", 200.0)
	var mod_ratio = params.get("ratio", 1.414)
	var mod_amount = params.get("mod", 5.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		
		var m_phase = t * freq * mod_ratio
		var c_phase = t * freq
		var env = exp(-t * 3.0)
		
		var mod = sin(TAU * m_phase) * mod_amount * env
		var car = sin(TAU * c_phase + mod) * env
		
		_write_sample16_stereo(data, i, car * 0.6, car * 0.6)
		
	return _create_stream(data)

# Patch 7: Pedal Steel (Synth Simulation)
# Swelling, gliding, crying.
static func _generate_pedal_steel(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 12.0)
	var freq = params.get("freq", 200.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	# slide logic: approach target freq from below or above
	var start_freq = freq * 0.9 # Slide up into note
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		var progress = t / duration
		
		# 1. Slide Envelope (Portamento)
		var slide_env = 1.0 - exp(-t * 2.0)
		var f = lerp(start_freq, freq, slide_env)
		
		# 2. Vibrato (Delayed)
		var vib_amount = clamp((t - 1.0) * 0.005, 0.0, 0.01) # Fade in
		var vib = sin(t * 5.0) * vib_amount
		f = f * (1.0 + vib)
		
		# 3. Source: Bright Pulse/Saw mix
		var saw = _saw_wave(f, t)
		var pulse = _pulse_wave(f, t, 0.3)
		var raw = (saw + pulse) * 0.5
		
		# 4. Filter (Bandpass-ish for "Amp" tone)
		# Just a static LP for now
		# ... skipped for simplicity/perf, relies on raw brightness
		
		# 5. Volume Swell (Volume Pedal)
		var swell = 0.0
		if t < 2.0: swell = t / 2.0
		else: swell = 1.0 - (t - 2.0) * 0.1 # Slow decay
		if swell < 0: swell = 0
		
		# 6. Chorus-y doubling
		var raw2 = (saw + pulse) * 0.5 # actually just mono for now
		
		_write_sample16_stereo(data, i, raw * swell * 0.4, raw * swell * 0.4)
		
	return _create_stream(data)

# Patch 8: Analog Pluck (Sequencer Synth)
# Short, snappy, filtered.
static func _generate_analog_pluck(params: Dictionary) -> AudioStreamWAV:
	var duration = params.get("duration", 0.5) # Short notes usually
	var freq = params.get("freq", 440.0)
	
	var sample_count = int(duration * MIX_RATE)
	var data = PackedByteArray()
	data.resize(sample_count * 4)
	
	# Filter State
	var filt_state = _create_ladder_filter_state()
	
	for i in range(sample_count):
		var t = float(i) / MIX_RATE
		
		# 1. Envelopes
		# Amp: Instant attack, exp decay
		var amp_env = exp(-t * 10.0)
		# Filter: Instant attack, fast decay
		var filter_env = exp(-t * 15.0)
		
		# 2. Source: Saw/Square Mix
		var saw = _saw_wave(freq, t)
		var sq = _pulse_wave(freq, t, 0.5)
		var raw = saw * 0.6 + sq * 0.4
		
		# 3. Filter
		var cutoff = 400.0 + (3000.0 * filter_env)
		var res = 0.4
		var filtered = _run_ladder_filter(raw, cutoff, res, filt_state)
		
		# 4. Out
		var out = filtered * amp_env
		
		_write_sample16_stereo(data, i, out * 0.7, out * 0.7)
		
	return _create_stream(data)

# ----- DSP UTILS FOR CHOIR -----

static func _read_delay_cubic(buffer: Array, head: int, delay_samples: float) -> float:
	var read_pos = float(head) - delay_samples
	while read_pos < 0: read_pos += buffer.size()
	while read_pos >= buffer.size(): read_pos -= buffer.size()
	
	var i_part = int(read_pos)
	var f_part = read_pos - i_part
	
	var i0 = (i_part - 1 + buffer.size()) % buffer.size()
	var i1 = i_part
	var i2 = (i_part + 1) % buffer.size()
	var i3 = (i_part + 2) % buffer.size()
	
	var y0 = buffer[i0]
	var y1 = buffer[i1]
	var y2 = buffer[i2]
	var y3 = buffer[i3]
	
	return _cubic_interp(y0, y1, y2, y3, f_part)

static func _cubic_interp(y0, y1, y2, y3, x):
	var a = y3 - y2 - y0 + y1
	var b = y0 - y1 - a
	var c = y2 - y0
	var d = y1
	return a*x*x*x + b*x*x + c*x + d


static func _calc_bp_coeffs(freq: float, q: float) -> Array:
	var omega = 2.0 * PI * freq / MIX_RATE
	var alpha = sin(omega) / (2.0 * q)
	var a0 = 1.0 + alpha
	return [
		alpha / a0,       # b0
		0.0,              # b1
		-alpha / a0,      # b2
		-2.0 * cos(omega) / a0, # a1
		(1.0 - alpha) / a0      # a2
	]

static func _run_biquad(in_samp: float, c: Array, s: Dictionary) -> float:
	# Direct Form I
	var out = c[0] * in_samp + c[1] * s.x1 + c[2] * s.x2 - c[3] * s.y1 - c[4] * s.y2
	# Shift state
	s.x2 = s.x1
	s.x1 = in_samp
	s.y2 = s.y1
	s.y1 = out
	return out

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
