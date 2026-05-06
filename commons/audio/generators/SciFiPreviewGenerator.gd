extends RefCounted
class_name SciFiPreviewGenerator

# Generates 10-second WAV previews for SoundBank/SoundBox
# Offline rendering of SciFiSynth concepts.

const PREVIEW_RATE = 44100
const PREVIEW_DURATION = 8.0

static func generate_preview(track_request: String) -> AudioStreamWAV:
	# Handle "sci_fi:" prefix
	if track_request.begins_with("sci_fi:"):
		track_request = track_request.replace("sci_fi:", "")
	
	var parts = track_request.split("_")
	var track = parts[0] # "drift", "noir", "neon"
	var layer = parts[ parts.size() - 1 ] # "mix", "bass", "piano", "sax", "drums", "rain"

	match track:
		"drift": return _render_track_1(layer)
		"inter": return _render_track_2(layer) # Interdimensional
		"foundry": return _render_track_3(layer) # Foundry
		"noir":  return _render_track_4(layer)
		"stellar": return _render_track_5(layer) # Stellar Shadowing
		"neon":  return _render_track_6(layer)
		"skyline": return _render_track_7(layer) # Skyline
		"market": return _render_track_8(layer) # Market
		"celestial": return _render_track_9(layer) # Celestial Symphony
		"finale": return _render_track_10(layer) # Finale
		_: return _render_track_1("mix")

# TRACK 1: Drift (Stems: mix, bass, piano)
static func _render_track_1(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		
		# Stem 1: Drone
		var drone = 0.0
		if layer == "mix" or layer == "bass":
			drone = sin(TAU * 55.0 * t)
			drone = tanh(drone * 2.0) * 0.4
		
		# Stem 2: Piano (at 2.0s)
		var piano = 0.0
		if layer == "mix" or layer == "piano":
			if t > 2.0:
				var pt = t - 2.0
				var freq = 261.63 # C4
				var mod = sin(TAU * freq * 2.0 * pt) * exp(-pt * 3.0) * 2.0
				var car = sin(TAU * freq * pt + mod) * exp(-pt * 0.8)
				piano = car * 0.5
			
		var out = drone + piano
		_write_sample(data, i, out, out)
	return _create_wav(data)

# TRACK 4: Noir (Stems: mix, pad, sax)
static func _render_track_4(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var sax_phase = 0.0
	var sax_freq = 261.63
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		
		# Stem 1: Pad
		var pad = 0.0
		if layer == "mix" or layer == "pad":
			for k in range(5):
				pad += sin(TAU * 110.0 * (1.0 + k*0.002) * t)
			pad *= 0.1
		
		# Stem 2: Sax
		var sax = 0.0
		if layer == "mix" or layer == "sax":
			if t > 1.0:
				var pt = t - 1.0
				var sax_env = 0.0
				if pt >= 0.0 and pt <= 3.0:
					if pt < 0.5: sax_env = pt / 0.5
					else: sax_env = 1.0 - (pt - 0.5) * 0.2
				
				var vib = sin(TAU * 4.5 * pt) * 0.01
				sax_phase += (sax_freq * (1.0 + vib)) / PREVIEW_RATE
				if sax_phase > 1.0: sax_phase -= 1.0
				var raw = (2.0 * sax_phase) - 1.0
				sax = raw * sax_env * 0.4
			
		var out = pad + sax
		_write_sample(data, i, out, out)
	return _create_wav(data)

# TRACK 6: Neon Rain (Stems: mix, drums, bass, rain)
static func _render_track_6(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var bass_phase = 0.0
	var rng = RandomNumberGenerator.new()
	rng.seed = 12345
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_out = 0.0
		var r_out = 0.0
		
		# Stem 1: Rain/Traffic
		if layer == "mix" or layer == "rain":
			var rain_noise = rng.randf_range(-1.0, 1.0)
			var traffic = sin(TAU * 60.0 * t) * 0.05 * (sin(t * 0.2) + 1.0) # Rumble
			l_out += rain_noise * 0.05 + traffic
			r_out += rain_noise * 0.05 + traffic
			
		# Stem 2: Bass (Pulse Width Mod)
		if layer == "mix" or layer == "bass":
			# Bassline: C - G - Bb - F (Slow)
			var note = 32.70 # C1
			if t > 2.0: note = 49.00 # G1
			if t > 4.0: note = 58.27 # Bb1
			if t > 6.0: note = 43.65 # F1
			
			var pwm_speed = 0.5
			var pulse_width = 0.5 + sin(TAU * pwm_speed * t) * 0.4
			
			bass_phase += note / PREVIEW_RATE
			if bass_phase > 1.0: bass_phase -= 1.0
			
			var osc = 1.0 if bass_phase < pulse_width else -1.0
			# Filter approx (Low Pass)
			osc = osc * 0.2 # Simply volume for preview, real filter too heavy for loop
			
			l_out += osc
			r_out += osc

		# Stem 3: Drums (Trip Hop Beat)
		if layer == "mix" or layer == "drums":
			var beat_t = fmod(t * 1.5, 1.0) # 90 BPM approx
			var measure = int(t * 1.5)
			
			var kick = 0.0
			var snare = 0.0
			var hat = 0.0
			
			# Kick: On 0.0 and some syncopation
			if beat_t < 0.1: kick = exp(-beat_t * 20.0) * sin(TAU * 60.0 * (1.0-beat_t) * beat_t)
			if beat_t > 0.7 and beat_t < 0.8: kick = exp(-(beat_t-0.7) * 20.0) * 0.5
			
			# Rimshot: On 0.5
			if beat_t > 0.5 and beat_t < 0.6: 
				var bt = beat_t - 0.5
				snare = exp(-bt * 50.0) * (sin(TAU * 800.0 * bt) + (rng.randf()-0.5))
			
			# HiHat: 16ths
			var hat_t = fmod(beat_t * 4.0, 1.0)
			if hat_t < 0.1: hat = rng.randf() * exp(-hat_t * 80.0) * 0.3
			
			var drum_mix = kick + snare + hat
			l_out += drum_mix * 0.8
			r_out += drum_mix * 0.8

		_write_sample(data, i, l_out, r_out)
		
	return _create_wav(data)

# TRACK 2: Interdimensional (Stems: mix, wave, blips)
static func _render_track_2(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	# Wavetable State
	var phase = 0.0
	var freq = 55.0 # A1
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_out = 0.0
		
		# Stem 1: Wavetable Sweep
		if layer == "mix" or layer == "wave":
			var sweep = (sin(t * 0.5) + 1.0) * 0.5 # 0 to 1
			# Sim morph: Sine -> Saw -> Pulse
			phase += freq / PREVIEW_RATE
			if phase > 1.0: phase -= 1.0
			
			var sine = sin(TAU * phase)
			var saw = (2.0 * phase) - 1.0
			var pulse = 1.0 if phase < 0.5 else -1.0
			
			var samp = 0.0
			if sweep < 0.5:
				samp = lerp(sine, saw, sweep * 2.0)
			else:
				samp = lerp(saw, pulse, (sweep - 0.5) * 2.0)
				
			l_out += samp * 0.4
			
		# Stem 2: FM Blips
		if layer == "mix" or layer == "blips":
			if t > 2.0 and t < 2.5: # Blip 1
				var bt = t - 2.0
				l_out += sin(TAU * 880.0 * bt) * exp(-bt * 10.0) * 0.3
			if t > 5.0 and t < 5.5: # Blip 2
				var bt = t - 5.0
				l_out += sin(TAU * 1760.0 * bt) * exp(-bt * 10.0) * 0.2
				
		_write_sample(data, i, l_out, l_out)
		
	return _create_wav(data)

# TRACK 5: Stellar Shadowing (Stems: mix, pad, choir, wave)
static func _render_track_5(layer: String) -> AudioStreamWAV:
	# Use EpicSynthEngine for high quality render, then mix
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	
	# Helper to get buffer from EpicSynth (Duration 8s)
	var pad_stream = null
	if layer == "mix" or layer == "pad":
		pad_stream = EpicSynthEngine.generate_patch("cs80_pad_1", {"freq": 146.83, "duration": PREVIEW_DURATION})
		
	var choir_stream = null
	if layer == "mix" or layer == "choir":
		choir_stream = EpicSynthEngine.generate_patch("choir_ensemble", {"freq": 220.0, "duration": PREVIEW_DURATION, "vowel": "ooh"})
		
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_sum = 0.0
		var r_sum = 0.0
		
		# Pad
		if pad_stream:
			var idx = i * 4
			# Very rough manual PCM read (assuming 16-bit stereo)
			var lb = pad_stream.data[idx] + (pad_stream.data[idx+1] << 8)
			var rb = pad_stream.data[idx+2] + (pad_stream.data[idx+3] << 8)
			# Convert back to float -1..1 (approx, avoiding sign issues in GDScript ints nicely)
			if lb > 32767: lb -= 65536
			if rb > 32767: rb -= 65536
			l_sum += (float(lb) / 32768.0) * 0.5
			r_sum += (float(rb) / 32768.0) * 0.5
			
		# Choir
		if choir_stream:
			var idx = i * 4
			if idx < choir_stream.data.size():
				var lb = choir_stream.data[idx] + (choir_stream.data[idx+1] << 8)
				var rb = choir_stream.data[idx+2] + (choir_stream.data[idx+3] << 8)
				if lb > 32767: lb -= 65536
				if rb > 32767: rb -= 65536
				l_sum += (float(lb) / 32768.0) * 0.6
				r_sum += (float(rb) / 32768.0) * 0.6
		
		# Wave (Simple Square)
		if layer == "mix" or layer == "wave":
			var phase = fmod(t * 293.66, 1.0)
			var sq = 1.0 if phase < 0.5 else -1.0
			var morph = (sin(t * 0.5) + 1.0) * 0.5
			var out = sq * morph * 0.2
			l_sum += out
			r_sum += out
			
		_write_sample(data, i, l_sum, r_sum)
		
	return _create_wav(data)

# TRACK 3: Foundry (Stems: mix, drone, hits)
static func _render_track_3(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_out = 0.0
		var r_out = 0.0
		
		# Drone
		if layer == "mix" or layer == "drone":
			var drone = tanh(sin(TAU * 40.0 * t)) * 0.3
			l_out += drone
			r_out += drone
			
		# Hits
		if layer == "mix" or layer == "hits":
			var beat = fmod(t * 0.25, 1.0) # Slow 4s loop
			var hit = 0.0
			if beat < 0.1:
				var hit_t = beat * 4.0 
				var f = 150.0
				var fm = sin(TAU * f * 1.414 * hit_t) * 5.0 * exp(-hit_t * 5.0)
				hit = sin(TAU * f * hit_t + fm) * exp(-hit_t * 3.0)
			
			l_out += hit * 0.5
			r_out += hit * 0.5
			
		_write_sample(data, i, l_out, r_out)
	return _create_wav(data)

# TRACK 7: Skyline (Stems: mix, pedal, piano)
static func _render_track_7(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var pedal_stream = null
	if layer == "mix" or layer == "pedal":
		pedal_stream = EpicSynthEngine.generate_patch("pedal_steel", {"freq": 220.0, "duration": PREVIEW_DURATION})
		
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_sum = 0.0
		var r_sum = 0.0
		
		if pedal_stream:
			var idx = i * 4
			if idx < pedal_stream.data.size():
				var lb = pedal_stream.data[idx] + (pedal_stream.data[idx+1] << 8)
				if lb > 32767: lb -= 65536
				l_sum += (float(lb) / 32768.0) * 0.5
				r_sum = l_sum
			
		# Simple piano layer
		if layer == "mix" or layer == "piano":
			if t > 2.0:
				var pt = t - 2.0
				var p = sin(TAU * 440.0 * pt) * exp(-pt * 2.0) * 0.3
				l_sum += p
				r_sum += p
				
		_write_sample(data, i, l_sum, r_sum)
	return _create_wav(data)

# TRACK 8: Market (Stems: mix, pluck, beat)
static func _render_track_8(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_out = 0.0
		var r_out = 0.0
		
		var beat_16 = int(t * 8.0) % 16
		var beat_t = fmod(t * 8.0, 1.0)
		
		if layer == "mix" or layer == "pluck":
			if beat_16 % 2 == 0:
				var freq = 55.0
				if beat_16 == 4: freq = 82.41
				var saw = (fmod(t * freq, 1.0) * 2.0 - 1.0)
				var env = exp(-beat_t * 10.0)
				var filt = exp(-beat_t * 15.0)
				l_out += saw * env * filt * 0.5
				r_out += saw * env * filt * 0.5
				
		if layer == "mix" or layer == "beat":
			if beat_16 == 0: # Kick
				var k = sin(TAU * 60.0 * beat_t) * exp(-beat_t * 10.0)
				l_out += k * 0.5
				r_out += k * 0.5
				
		_write_sample(data, i, l_out, r_out)
	return _create_wav(data)

# TRACK 10: Finale (Stems: mix)
static func _render_track_10(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l = tanh(sin(TAU * 40.0 * t)) * 0.4
		var w = (fmod(t * 110.0, 1.0) * 2.0 - 1.0) * (sin(t * 10.0) + 1.0) * 0.2
		var mix = l + w
		_write_sample(data, i, mix, mix)
	return _create_wav(data)

# TRACK 9: Celestial Symphony (Stems: mix, strings, bell)
static func _render_track_9(layer: String) -> AudioStreamWAV:
	var frames = int(PREVIEW_DURATION * PREVIEW_RATE)
	var data = PackedByteArray()
	data.resize(frames * 4)
	
	var str_stream = null
	if layer == "mix" or layer == "strings":
		str_stream = EpicSynthEngine.generate_patch("string_machine", {"freq": 196.0, "duration": PREVIEW_DURATION})
		
	for i in range(frames):
		var t = float(i) / PREVIEW_RATE
		var l_sum = 0.0
		var r_sum = 0.0
		
		if str_stream:
			var idx = i * 4
			if idx < str_stream.data.size():
				var lb = str_stream.data[idx] + (str_stream.data[idx+1] << 8)
				var rb = str_stream.data[idx+2] + (str_stream.data[idx+3] << 8)
				if lb > 32767: lb -= 65536
				if rb > 32767: rb -= 65536
				l_sum += (float(lb) / 32768.0) * 0.7
				r_sum += (float(rb) / 32768.0) * 0.7
				
		# Bell (Simple FM)
		if layer == "mix" or layer == "bell":
			if t > 1.0 and t < 4.0:
				var bt = t - 1.0
				var fm = sin(TAU * 880.0 * bt) * exp(-bt * 5.0)
				var car = sin(TAU * 440.0 * bt + fm) * exp(-bt)
				l_sum += car * 0.4
				r_sum += car * 0.4
				
		_write_sample(data, i, l_sum, r_sum)
		
	return _create_wav(data)

static func point_in_range(x, a, b):
	return x >= a and x <= b

static func _write_sample(data: PackedByteArray, i: int, l: float, r: float):
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
	stream.mix_rate = PREVIEW_RATE
	stream.data = data
	return stream
