# DiscreetAudioGenerator.gd
# Generates baked samples for the Discreet Music system.
# Hybrid Saw/Sine with vibrato and LPF.

extends RefCounted
class_name DiscreetAudioGenerator

const SAMPLE_RATE = 44100

static func generate_note(frequency: float, duration: float) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2)
	
	# Params
	var saw_mix = 0.5
	var vibrato_rate = 5.0
	var vibrato_amount = 0.005
	var attack = 0.5
	var decay = 0.0 # Not used in sustain mode
	var sustain = 1.0
	var release = 4.0
	
	# Since duration in trigger_note includes the note held time, 
	# we should bake the HOLD part + the RELEASE part.
	# If duration is the total time including release, we handle that.
	# But usually 'duration' means "gate time".
	# So total sample length = duration + release.
	
	var gate_time = duration
	var total_duration = gate_time + release
	sample_count = int(SAMPLE_RATE * total_duration)
	data.resize(sample_count * 2)
	
	var last_filter = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Envelope
		var amp = 0.0
		if t < attack:
			amp = t / attack
		elif t < gate_time:
			amp = sustain
		else:
			var release_t = t - gate_time
			if release_t < release:
				amp = sustain * (1.0 - release_t / release)
			else:
				amp = 0.0
				
		# Vibrato
		var vib = sin(t * TAU * vibrato_rate) * vibrato_amount
		var f = frequency * (1.0 + vib)
		
		# Oscillators (using phase integration for FM/Vibrato)
		# Phase = integral of freq * dt
		# With constant vibrato: phase = freq * t + (freq * amount / rate) * cos(...)
		# But simpler to just integrate in loop if we had state.
		# For baking, we can approximate phase:
		# phase ~= freq * t - (freq * vib_amt / (2*PI*vib_rate)) * cos(2*PI*vib_rate*t)
		
		var phase = frequency * t - (frequency * vibrato_amount / (TAU * vibrato_rate)) * cos(TAU * vibrato_rate * t)
		
		# Saw/Sine Mix
		var ph_rad = phase * TAU
		var sine_out = sin(ph_rad)
		var saw_out = 2.0 * (phase - floor(0.5 + phase))
		var osc_out = lerp(sine_out, saw_out, saw_mix)
		
		var sample = osc_out * amp
		
		# LPF
		last_filter = lerp(last_filter, sample, 0.2)
		sample = last_filter
		
		sample = clamp(sample, -1.0, 1.0)
		
		var sample_int = int(sample * 32767.0)
		var byte_idx = i * 2
		data[byte_idx] = sample_int & 0xFF
		data[byte_idx + 1] = (sample_int >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

