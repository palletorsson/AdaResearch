# FMPianoGenerator.gd
# Generates high-quality FM Electric Piano samples.
# Optimized for "Music for Airports" style ambient loops.

extends RefCounted
class_name FMPianoGenerator

const SAMPLE_RATE = 44100

# FM Parameters (Matching FMPianoSynth.gd)
const MOD_RATIO = 4.0
const MOD_INDEX_BASE = 0.1
const MOD_INDEX_VEL = 0.6

static func generate_note(frequency: float, velocity: float = 0.7, sustain_time: float = 4.0) -> AudioStreamWAV:
	# Total duration needs to cover the attack + sustain/release tail
	# In FMPianoSynth, decay & release are both set to 'sustain_time'
	# And attack is 0.05.
	# We need enough buffer for the sound to fade to near silence.
	# Let's assume 2 * sustain_time is enough for a full fade out if we treat it as release.
	# But simpler: just generate 'sustain_time + 2.0' seconds and ensure the envelope fades out.
	
	var duration = sustain_time + 1.0
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Envelopes
	var attack = 0.05
	var decay = sustain_time # As per FMPianoSynth logic
	# We treat 'decay' as the main body fade time here since Sustain level is 0.0 in FMPianoSynth
	# (env_carrier = Envelope.new(0.05, 2.0, 0.0, 2.0)) -> Sustain level is 0.0!
	# So it's just Attack -> Decay to 0.
	
	var mod_decay = 0.5 # Modulator has short decay for "Ring" at start
	
	# LPF State
	var last_lpf = 0.0
	var lp_alpha = 0.15
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# 1. Carrier Envelope (AD to 0)
		var car_amp = 0.0
		if t < attack:
			# Quadratic attack
			var x = t / attack
			car_amp = x * x
		else:
			# Exponential decay to 0
			var dt = t - attack
			if dt < decay:
				# Lerp approximation from FMPianoSynth: level = lerp(1.0, sustain=0.0, t/decay)
				# This is linear decay!
				car_amp = 1.0 - (dt / decay)
			else:
				car_amp = 0.0
		
		if car_amp < 0: car_amp = 0
		
		# 2. Modulator Envelope
		var mod_amp = 0.0
		if t < attack:
			var x = t / attack
			mod_amp = x * x
		else:
			var dt = t - attack
			# Modulator also has sustain 0.0 in FMPianoSynth logic
			if dt < mod_decay:
				mod_amp = 1.0 - (dt / mod_decay)
			else:
				mod_amp = 0.0
				
		if mod_amp < 0: mod_amp = 0
		
		# 3. FM Synthesis
		var mod_idx = MOD_INDEX_BASE + (MOD_INDEX_VEL * velocity)
		
		# Note: We can't use accumulated phase variables easily in a loop without state.
		# But since frequency is constant, phase = freq * t
		var phase = frequency * t
		var fm_phase = frequency * MOD_RATIO * t
		
		var mod_out = sin(fm_phase * TAU) * mod_idx * mod_amp
		var carrier = sin((phase * TAU) + mod_out)
		
		var sample_mix = carrier * car_amp * velocity
		
		# 4. Low Pass Filter
		last_lpf = lerp(last_lpf, sample_mix, lp_alpha)
		sample_mix = last_lpf
		
		# Gain Compensation & Limiter
		sample_mix *= 1.5
		sample_mix = clamp(sample_mix, -1.0, 1.0)
		
		# Convert to 16-bit
		var sample_int = int(sample_mix * 32767.0)
		var byte_idx = i * 2
		data[byte_idx] = sample_int & 0xFF
		data[byte_idx + 1] = (sample_int >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

