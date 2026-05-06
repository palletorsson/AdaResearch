# SpaceDystopiaGenerator.gd
# Improved Space Dystopia album track generator
# Uses beat-synced generation and new synthesis techniques

extends RefCounted
class_name SpaceDystopiaGenerator

const SAMPLE_RATE = 44100
const PREVIEW_DURATION = 8.0

# ============================================================================
# PUBLIC API
# ============================================================================

static func generate_track(track_name: String, layer: String = "mix") -> AudioStreamWAV:
	# Handle "sci_fi:" prefix
	if track_name.begins_with("sci_fi:"):
		track_name = track_name.replace("sci_fi:", "")
	
	var parts = track_name.split("_")
	var track = parts[0]
	if layer == "":
		layer = parts[parts.size() - 1] if parts.size() > 1 else "mix"
	
	match track:
		"drift": return _render_drift(layer)
		"inter": return _render_interdimensional(layer)
		"foundry": return _render_foundry(layer)
		"noir": return _render_noir(layer)
		"stellar": return _render_stellar(layer)
		"neon": return _render_neon(layer)
		"skyline": return _render_skyline(layer)
		"market": return _render_market(layer)
		"celestial": return _render_celestial(layer)
		"finale": return _render_finale(layer)
		_: return _render_drift("mix")


# ============================================================================
# TRACK 1: DRIFT - Melancholic space drift
# ============================================================================

static func _render_drift(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * SAMPLE_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var bpm = 70.0
	var beat_dur = 60.0 / bpm
	
	# Filter state for bass
	var bass_filter = 0.0
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = t / PREVIEW_DURATION
		var l_out = 0.0
		var r_out = 0.0
		
		# Layer: Pad (CS-80 style swell)
		if layer == "mix" or layer == "pad":
			var pad = _cs80_pad(t, 110.0, progress)
			l_out += pad * 0.4
			r_out += pad * 0.4
		
		# Layer: Bass (sub bass pulse on beats)
		if layer == "mix" or layer == "bass":
			var beat_pos = fmod(t, beat_dur * 2)
			var beat_t = beat_pos
			if beat_t < 0.3:
				var bass_raw = sin(TAU * 55.0 * beat_t) * exp(-beat_t * 5.0)
				# Simple lowpass
				bass_filter += 0.1 * (bass_raw - bass_filter)
				l_out += bass_filter * 0.5
				r_out += bass_filter * 0.5
		
		# Layer: Piano (DX7 style, sparse)
		if layer == "mix" or layer == "piano":
			if t > 2.0:
				var piano = _fm_piano(t - 2.0, 261.63)
				l_out += piano * 0.3
				r_out += piano * 0.3
		
		_write_stereo(data, i, l_out, r_out)
	
	return _create_wav(data)


# ============================================================================
# TRACK 4: NOIR - Cyberpunk jazz
# ============================================================================

static func _render_noir(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * SAMPLE_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var bpm = 85.0
	var beat_dur = 60.0 / bpm
	var rng = RandomNumberGenerator.new()
	rng.seed = 4444
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = t / PREVIEW_DURATION
		var l_out = 0.0
		var r_out = 0.0
		
		# Layer: Warm pad bed
		if layer == "mix" or layer == "pad":
			var pad = 0.0
			for v in range(5):
				var detune = 1.0 + (v - 2) * 0.003
				pad += sin(TAU * 146.83 * detune * t)
			pad /= 5.0
			pad *= sin(progress * PI) * 0.3  # Swell
			l_out += pad
			r_out += pad
		
		# Layer: Noir sax (with vibrato)
		if layer == "mix" or layer == "sax":
			if t > 1.5:
				var sax = _noir_sax_voice(t - 1.5, 293.66, progress)
				l_out += sax * 0.4
				r_out += sax * 0.4
		
		# Layer: Trip-hop drums
		if layer == "mix" or layer == "drums":
			var drums = _trip_hop_drums(t, bpm, rng)
			l_out += drums * 0.5
			r_out += drums * 0.5
		
		# Layer: Rain ambience
		if layer == "mix" or layer == "rain":
			var rain = rng.randf_range(-0.05, 0.05)
			l_out += rain
			r_out += rain * 0.95  # Slight stereo
		
		_write_stereo(data, i, l_out, r_out)
	
	return _create_wav(data)


# ============================================================================
# TRACK 6: NEON RAIN - Cyberpunk cityscape
# ============================================================================

static func _render_neon(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * SAMPLE_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var bpm = 90.0
	var beat_dur = 60.0 / bpm
	var rng = RandomNumberGenerator.new()
	rng.seed = 6666
	
	var bass_phase = 0.0
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = t / PREVIEW_DURATION
		var l_out = 0.0
		var r_out = 0.0
		
		# Layer: Rain + traffic
		if layer == "mix" or layer == "rain":
			var rain = rng.randf_range(-0.08, 0.08)
			var traffic_rumble = sin(TAU * 40.0 * t) * 0.03 * (1.0 + sin(t * 0.2))
			l_out += rain + traffic_rumble
			r_out += rain * 0.9 + traffic_rumble
		
		# Layer: PWM Bass (Blade Runner style)
		if layer == "mix" or layer == "bass":
			# Bass notes: C - G - Bb - F
			var bass_freq = 32.70
			var measure = int(t / 2.0)
			match measure % 4:
				1: bass_freq = 49.00
				2: bass_freq = 58.27
				3: bass_freq = 43.65
			
			var pwm = 0.5 + sin(t * 0.5) * 0.35
			bass_phase += bass_freq / SAMPLE_RATE
			if bass_phase > 1.0: bass_phase -= 1.0
			
			var bass = 1.0 if bass_phase < pwm else -1.0
			bass = tanh(bass * 0.5) * 0.2
			l_out += bass
			r_out += bass
		
		# Layer: Drums (trip-hop)
		if layer == "mix" or layer == "drums":
			var drums = _trip_hop_drums(t, bpm, rng)
			l_out += drums * 0.6
			r_out += drums * 0.6
		
		# Layer: Synth stabs (Juno-style)
		if layer == "mix" or layer == "stabs":
			var beat_in_bar = int(t / beat_dur) % 8
			var stab_t = fmod(t, beat_dur)
			if beat_in_bar == 3 or beat_in_bar == 7:
				if stab_t < 0.1:
					var stab = _juno_stab(stab_t, 220.0)
					l_out += stab * 0.3
					r_out += stab * 0.3
		
		_write_stereo(data, i, l_out, r_out)
	
	return _create_wav(data)


# ============================================================================
# TRACK 3: FOUNDRY - Industrial
# ============================================================================

static func _render_foundry(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * SAMPLE_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var rng = RandomNumberGenerator.new()
	rng.seed = 3333
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = t / PREVIEW_DURATION
		var l_out = 0.0
		var r_out = 0.0
		
		# Layer: Industrial drone
		if layer == "mix" or layer == "drone":
			var drone = tanh(sin(TAU * 40.0 * t) * 0.7) * 0.2
			drone += sin(TAU * 80.0 * t) * 0.08
			l_out += drone
			r_out += drone
		
		# Layer: Metallic hits (anvil)
		if layer == "mix" or layer == "hits":
			var hit_interval = 1.0  # Every second
			var hit_t = fmod(t, hit_interval)
			if hit_t < 0.2:
				var anvil = _industrial_anvil(hit_t)
				l_out += anvil * 0.5
				r_out += anvil * 0.5
		
		# Layer: Mechanical rhythm
		if layer == "mix" or layer == "mech":
			var mech_t = fmod(t * 2.0, 1.0)  # Double time
			if mech_t < 0.05:
				var click = rng.randf_range(-0.3, 0.3) * (1.0 - mech_t / 0.05)
				l_out += click
				r_out += click
		
		_write_stereo(data, i, l_out, r_out)
	
	return _create_wav(data)


# ============================================================================
# TRACK 10: FINALE - Epic conclusion
# ============================================================================

static func _render_finale(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * SAMPLE_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	for i in range(frames):
		var t = float(i) / SAMPLE_RATE
		var progress = t / PREVIEW_DURATION
		var l_out = 0.0
		var r_out = 0.0
		
		# Section 1 (0-2s): Heartbeat tension
		if t < 2.0:
			var heart_t = fmod(t, 0.8)
			if heart_t < 0.1:
				l_out += sin(TAU * 40.0 * heart_t) * exp(-heart_t * 20.0) * 0.4
				r_out = l_out
			if heart_t > 0.15 and heart_t < 0.25:
				var ht2 = heart_t - 0.15
				l_out += sin(TAU * 50.0 * ht2) * exp(-ht2 * 25.0) * 0.3
				r_out = l_out
		
		# Section 2 (2-5s): Building brass swell
		if t >= 2.0 and t < 5.0:
			var sec_t = t - 2.0
			var sec_prog = sec_t / 3.0
			var brass = _blade_runner_brass(sec_t, 110.0, sec_prog)
			l_out += brass * 0.5
			r_out += brass * 0.5
		
		# Section 3 (5-7s): Full climax with all elements
		if t >= 5.0 and t < 7.0:
			var sec_t = t - 5.0
			# Massive brass
			var brass = _blade_runner_brass(sec_t, 110.0, 1.0)
			l_out += brass * 0.4
			r_out += brass * 0.4
			# Choir
			var choir = _choir_voice(sec_t, 220.0, 0.5)
			l_out += choir * 0.3
			r_out += choir * 0.3
			# Sub
			l_out += sin(TAU * 55.0 * sec_t) * 0.3
			r_out = l_out
		
		# Section 4 (7-8s): Fade to single note
		if t >= 7.0:
			var fade = (PREVIEW_DURATION - t) / 1.0
			var final_note = sin(TAU * 110.0 * t) * fade * 0.3
			l_out += final_note
			r_out += final_note
		
		_write_stereo(data, i, l_out, r_out)
	
	return _create_wav(data)


# ============================================================================
# REMAINING TRACKS (stubs - to be expanded)
# ============================================================================

static func _render_interdimensional(layer: String) -> AudioStreamWAV:
	return SciFiPreviewGenerator._render_track_2(layer)

static func _render_stellar(layer: String) -> AudioStreamWAV:
	return SciFiPreviewGenerator._render_track_5(layer)

static func _render_skyline(layer: String) -> AudioStreamWAV:
	return SciFiPreviewGenerator._render_track_7(layer)

static func _render_market(layer: String) -> AudioStreamWAV:
	return SciFiPreviewGenerator._render_track_8(layer)

static func _render_celestial(layer: String) -> AudioStreamWAV:
	return SciFiPreviewGenerator._render_track_9(layer)


# ============================================================================
# SYNTHESIS HELPERS
# ============================================================================

static func _cs80_pad(t: float, freq: float, progress: float) -> float:
	# CS-80 style pad with filter sweep
	var output = 0.0
	for v in range(7):
		var detune = 1.0 + (v - 3) * 0.006
		var f = freq * detune
		var phase = fmod(t * f, 1.0)
		output += (2.0 * phase - 1.0)  # Sawtooth
	output /= 7.0
	
	# Filter sweep
	var cutoff = lerp(300.0, 2000.0, sin(progress * PI))
	output *= clamp(cutoff / 2000.0, 0.2, 1.0)
	
	# Envelope
	var env = sin(progress * PI)
	return tanh(output * 0.8) * env


static func _fm_piano(t: float, freq: float) -> float:
	# DX7-style FM electric piano
	var mod_ratio = 2.0
	var mod_index = exp(-t * 3.0) * 3.0
	var mod = sin(TAU * freq * mod_ratio * t) * mod_index
	var carrier = sin(TAU * freq * t + mod)
	return carrier * exp(-t * 1.5)


static func _noir_sax_voice(t: float, freq: float, _progress: float) -> float:
	# Sax with vibrato and breath
	var vibrato = sin(TAU * 5.0 * t) * 0.015 * clamp(t * 2.0, 0.0, 1.0)
	var f = freq * (1.0 + vibrato)
	
	var phase = fmod(t * f, 1.0)
	var reed = tanh((phase * 2.0 - 1.0) * 1.2)
	
	var env = 1.0
	if t < 0.1: env = t / 0.1
	elif t > 3.0: env = exp(-(t - 3.0) * 2.0)
	
	return reed * env


static func _trip_hop_drums(t: float, bpm: float, rng: RandomNumberGenerator) -> float:
	var beat_dur = 60.0 / bpm
	var beat_pos = fmod(t, beat_dur * 4.0)
	var beat_num = int(beat_pos / beat_dur)
	var beat_t = fmod(beat_pos, beat_dur)
	
	var output = 0.0
	
	# Kick: 1 and 3.5
	if beat_num == 0 or (beat_num == 3 and beat_t > beat_dur * 0.5):
		var k_t = beat_t if beat_num == 0 else beat_t - beat_dur * 0.5
		if k_t < 0.15:
			var pitch = 60.0 * exp(-k_t * 30.0) + 35.0
			output += sin(TAU * pitch * k_t) * exp(-k_t * 12.0) * 0.8
	
	# Snare: 2
	if beat_num == 1 and beat_t < 0.15:
		var noise = rng.randf_range(-1.0, 1.0)
		var tone = sin(TAU * 180.0 * beat_t)
		output += (noise * 0.5 + tone * 0.3) * exp(-beat_t * 15.0)
	
	# Hi-hat: 8ths with variation
	var eighth_t = fmod(beat_t, beat_dur * 0.5)
	if eighth_t < 0.02:
		var vel = 0.2 + rng.randf() * 0.2
		output += rng.randf_range(-1.0, 1.0) * exp(-eighth_t * 150.0) * vel
	
	return output


static func _juno_stab(t: float, freq: float) -> float:
	# Juno-106 brass stab
	var output = 0.0
	for v in range(4):
		var detune = 1.0 + (v - 1.5) * 0.008
		var phase = fmod(t * freq * detune, 1.0)
		output += (phase * 2.0 - 1.0) * 0.5
		output += (1.0 if phase < 0.5 else -1.0) * 0.5
	output /= 4.0
	
	# Fast attack, medium decay
	var env = exp(-t * 8.0)
	return tanh(output * 1.0) * env


static func _industrial_anvil(t: float) -> float:
	# Metallic hit with inharmonic partials
	var output = 0.0
	var partials = [1.0, 2.4, 3.8, 5.1, 7.2]
	var base = 180.0
	
	for p in partials:
		var decay = exp(-t * (10.0 + p * 3.0))
		output += sin(TAU * base * p * t) * decay / p
	
	# Impact noise
	if t < 0.01:
		output += (randf() * 2.0 - 1.0) * (1.0 - t / 0.01)
	
	return output * exp(-t * 8.0)


static func _blade_runner_brass(t: float, freq: float, intensity: float) -> float:
	# CS-80 massive brass
	var output = 0.0
	for v in range(7):
		var detune = 1.0 + (v - 3) * 0.01
		var phase = fmod(t * freq * detune, 1.0)
		output += (2.0 * phase - 1.0)
	output /= 7.0
	
	# Sub
	output += sin(TAU * freq * 0.5 * t) * 0.4
	
	# Filter sweep based on intensity
	var cutoff = lerp(300.0, 4000.0, intensity)
	output *= clamp(cutoff / 4000.0, 0.1, 1.0)
	
	return tanh(output * 0.7) * intensity


static func _choir_voice(t: float, freq: float, vowel: float) -> float:
	# Simple choir formant
	var f1 = lerp(300.0, 800.0, vowel)
	var f2 = lerp(800.0, 1200.0, vowel)
	
	var output = 0.0
	for v in range(4):
		var detune = 1.0 + (v - 1.5) * 0.004
		var phase = fmod(t * freq * detune, 1.0)
		var source = sin(TAU * phase)
		output += source
	output /= 4.0
	
	output += sin(TAU * f1 * t) * 0.2
	output += sin(TAU * f2 * t) * 0.1
	
	return output


# ============================================================================
# UTILITY
# ============================================================================

static func _write_stereo(data: PackedByteArray, i: int, l: float, r: float):
	var sl = int(clamp(l, -1.0, 1.0) * 32767.0)
	var sr = int(clamp(r, -1.0, 1.0) * 32767.0)
	var off = i * 4
	data[off] = sl & 0xFF
	data[off+1] = (sl >> 8) & 0xFF
	data[off+2] = sr & 0xFF
	data[off+3] = (sr >> 8) & 0xFF


static func _create_wav(data: PackedByteArray) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.stereo = true
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = data
	return stream
