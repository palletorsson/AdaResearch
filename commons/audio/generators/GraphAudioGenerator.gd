# GraphAudioGenerator.gd
# Generates baked samples for the Graph Music system to improve performance.

extends RefCounted
class_name GraphAudioGenerator

const SAMPLE_RATE = 44100

static func generate_note(frequency: float, duration: float = 2.0) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedByteArray()
	data.resize(sample_count * 2) # 16-bit mono
	
	# ADSR Params (Baked)
	var attack = 0.02
	var decay = 0.1
	var sustain_level = 0.6
	var release = 0.4
	var sustain_time = duration - (attack + decay + release)
	if sustain_time < 0: sustain_time = 0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Envelope
		var amp = 0.0
		if t < attack:
			amp = t / attack
		elif t < attack + decay:
			var dt = t - attack
			amp = 1.0 - (dt / decay) * (1.0 - sustain_level)
		elif t < duration - release:
			amp = sustain_level
		else:
			var rt = t - (duration - release)
			amp = sustain_level * (1.0 - rt / release)
			if amp < 0: amp = 0
			
		# Waveform: Triangle + Saw approximation
		# Triangle approximation: 8/pi^2 * (sin(x) - sin(3x)/9 + sin(5x)/25)
		var ph = 2.0 * PI * frequency * t
		var tri = (sin(ph) - sin(3.0*ph)/9.0 + sin(5.0*ph)/25.0)
		
		# Slight FM detune for richness + Sci-Fi wobble
		var wobble = sin(t * 15.0) * 0.02 # Low freq wobble
		var detune = sin(ph * 0.5) * 0.01 + wobble
		
		# Sci-Fi "Metallic" layer (Ring Mod-ish)
		var metallic = sin(ph * 2.5) * 0.1
		
		var saw_ph = ph * (1.0 + detune)
		var saw = 2.0 * (saw_ph / (2.0 * PI) - floor(saw_ph / (2.0 * PI))) - 1.0
		
		var mix = tri * 0.6 + saw * 0.2 + metallic * 0.2
		
		var sample = mix * amp * 0.5 # Master gain
		
		# 16-bit PCM conversion
		var sample_int = int(clamp(sample, -1.0, 1.0) * 32767.0)
		var byte_idx = i * 2
		data[byte_idx] = sample_int & 0xFF
		data[byte_idx + 1] = (sample_int >> 8) & 0xFF
		
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.data = data
	return stream

