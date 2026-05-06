extends Node

const SAMPLE_RATE = 44100

static func generate_sax(note_freq: float = 261.63, duration: float = 2.0) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# FM Synthesis for Saxophone growl
		# Carrier: Sawtooth-ish (Pulse)
		# Modulator: Sine
		
		var growl_mod = sin(2.0 * PI * 0.5 * t) * 0.05 + 1.0
		var freq = note_freq * growl_mod
		
		# Modulator (Breath/Reed noise)
		var mod_freq = freq * 0.5
		var mod_index = 2.0 * (1.0 - progress) # More breath at start
		var modulator = sin(2.0 * PI * mod_freq * t) * mod_index
		
		# Carrier (Pulse wave with variable width)
		var phase = fmod(freq * t + modulator, 1.0)
		var width = 0.4 + sin(2.0 * PI * 4.0 * t) * 0.1 # Vibrato on width
		var wave = 1.0 if phase < width else -1.0
		
		# Formant Filter simulation (Low pass + Band pass)
		# Sax has strong mids
		var filter_cutoff = 800.0 + sin(2.0 * PI * freq * t) * 200.0 # AM simulated filter
		var filter_factor = clamp(filter_cutoff / 2000.0, 0.4, 1.0)
		wave *= filter_factor
		
		# Envelope (Swelling)
		var envelope = 1.0
		if progress < 0.2:
			envelope = progress / 0.2
		elif progress > 0.8:
			envelope = (1.0 - progress) / 0.2
			
		# Add breath noise
		var breath = (randf() * 2.0 - 1.0) * 0.1 * exp(-progress * 5.0)
		
		data[i] = (wave + breath) * envelope * 0.4

	return _create_stream(data)

static func generate_pluck(note_freq: float = 440.0, duration: float = 1.0) -> AudioStreamWAV:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Karplus-Strong-ish / Pluck synthesis
		# Short burst of noise/saw fed into delay line? 
		# Here we simulate with Sawtooth + Sharp Lowpass Decay
		
		var wave = 2.0 * (note_freq * t - floor(note_freq * t)) - 1.0
		
		# Filter Envelope (The Pluck)
		var filter_env = exp(-progress * 15.0)
		
		# Low pass filter simulation
		# As filter env drops, we reduce high frequency content (amplitude of saw)
		# Sines are cleaner for this
		var fundamental = sin(2.0 * PI * note_freq * t)
		var overtone = sin(2.0 * PI * note_freq * 2.0 * t) * filter_env * 0.5
		
		var plucked = fundamental + overtone
		
		# Amp Envelope
		var amp_env = exp(-progress * 3.0)
		
		data[i] = plucked * amp_env * 0.5

	return _create_stream(data)

static func _create_stream(data: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.data = _float_to_byte_array(data)
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	return stream

static func _float_to_byte_array(data: PackedFloat32Array) -> PackedByteArray:
	var bytes = PackedByteArray()
	bytes.resize(data.size() * 2)
	for i in range(data.size()):
		var val = int(clamp(data[i], -1.0, 1.0) * 32767.0)
		bytes[i*2] = val & 0xFF
		bytes[i*2+1] = (val >> 8) & 0xFF
	return bytes
