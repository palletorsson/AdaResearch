extends RefCounted
class_name PhonemeGenerator

# Phoneme Generator
# Synthesizes looping vowel and consonant textures for the Phoneme Cloud.

const SAMPLE_RATE = 44100
const DURATION = 2.0 # 2 seconds per loop is sufficient

static func generate_phoneme_stream(phoneme: String) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	
	var data = PackedFloat32Array()
	data.resize(int(SAMPLE_RATE * DURATION))
	
	match phoneme.to_lower():
		"a": _generate_vowel_a(data)
		"i": _generate_vowel_i(data)
		"u": _generate_vowel_u(data)
		"s": _generate_consonant_s(data)
		"t": _generate_consonant_t(data)
		_: _generate_silence(data)
		
	# Convert to 16-bit PCM (byte array)
	var byte_data = PackedByteArray()
	byte_data.resize(data.size() * 2)
	
	for i in range(data.size()):
		var sample = clampf(data[i], -1.0, 1.0)
		var value = int(sample * 32767.0)
		byte_data.encode_s16(i * 2, value)
		
	stream.data = byte_data
	stream.loop_end = data.size()
	
	return stream

static func _generate_silence(data: PackedFloat32Array):
	data.fill(0.0)

# Vowels: Approximated using formant frequencies (sine wave synthesis)
# frequencies from standard IPA formant charts (approximate)

static func _generate_vowel_a(data: PackedFloat32Array):
	# "a" (as in father) -> F1: 850Hz, F2: 1200Hz, F3: 2400Hz
	_add_sine(data, 130.0, 0.4) # Fundamental (Voice)
	_add_sine(data, 850.0, 0.3) # F1
	_add_sine(data, 1200.0, 0.2) # F2
	_add_sine(data, 2400.0, 0.1) # F3
	_apply_flutter(data, 5.0, 0.02) # Organic variation

static func _generate_vowel_i(data: PackedFloat32Array):
	# "i" (as in see) -> F1: 270Hz, F2: 2300Hz, F3: 3000Hz
	_add_sine(data, 130.0, 0.4)
	_add_sine(data, 270.0, 0.3)
	_add_sine(data, 2300.0, 0.2)
	_add_sine(data, 3000.0, 0.1)
	_apply_flutter(data, 5.2, 0.02)

static func _generate_vowel_u(data: PackedFloat32Array):
	# "u" (as in moon) -> F1: 300Hz, F2: 870Hz, F3: 2240Hz
	_add_sine(data, 130.0, 0.4)
	_add_sine(data, 300.0, 0.3)
	_add_sine(data, 870.0, 0.2)
	_add_sine(data, 2240.0, 0.1)
	_apply_flutter(data, 4.8, 0.02)

# Consonants: Noise based

static func _generate_consonant_s(data: PackedFloat32Array):
	# "s" -> High frequency noise (sibilance) start around 4-5kHz
	for i in range(data.size()):
		var noise = randf_range(-1.0, 1.0)
		# Simple High Pass Filter simulation (difference between samples)
		# Actually, just adding high freq noise is enough for this prototype
		data[i] = noise * 0.15
	
	# Apply cheap high pass (remove lows)
	var prev = 0.0
	for i in range(data.size()):
		var sample = data[i]
		data[i] = sample - prev
		prev = sample

static func _generate_consonant_t(data: PackedFloat32Array):
	# "t" -> Burst of noise, but here treated as a texture
	# More gritty/transient noise
	for i in range(data.size()):
		if randf() < 0.2: # Sparse noise (crackles)
			data[i] = randf_range(-0.5, 0.5)
		else:
			data[i] = 0.0

# Helpers

static func _add_sine(data: PackedFloat32Array, freq: float, amp: float):
	for i in range(data.size()):
		var t = float(i) / SAMPLE_RATE
		data[i] += sin(2.0 * PI * freq * t) * amp

static func _apply_flutter(data: PackedFloat32Array, rate: float, depth: float):
	# Amplitude modulation for "life"
	for i in range(data.size()):
		var t = float(i) / SAMPLE_RATE
		var mod = 1.0 + sin(2.0 * PI * rate * t) * depth
		data[i] *= mod
