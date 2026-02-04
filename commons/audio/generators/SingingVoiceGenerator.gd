# SingingVoiceGenerator.gd
# Procedural singing voice using formant synthesis
#
# Based on existing formant code in AudioSynthesizer (_generate_choir_pad, _generate_space_choir_pad)
# Extended with: multiple vowels, consonants, melody following, expression
#
# Technical approach:
# - Source: Pulse wave with glottal characteristics (vocal folds)
# - Filter: Formant resonators (F1, F2, F3) for vowel shaping
# - Expression: Vibrato, pitch drift, amplitude envelope

class_name SingingVoiceGenerator
extends RefCounted

const SAMPLE_RATE = 44100.0

# =============================================================================
# VOWEL FORMANT FREQUENCIES (Hz)
# Source: Peterson & Barney vowel measurements
# =============================================================================

const VOWELS = {
	# Vowel: [F1, F2, F3, F4] - first 4 formant frequencies
	"A": [730.0, 1090.0, 2440.0, 3400.0],   # "ah" as in "father"
	"E": [530.0, 1840.0, 2480.0, 3520.0],   # "eh" as in "bed"
	"I": [270.0, 2290.0, 3010.0, 3640.0],   # "ee" as in "beet"
	"O": [570.0, 840.0, 2410.0, 3400.0],    # "oh" as in "boat"  
	"U": [300.0, 870.0, 2240.0, 3400.0],    # "oo" as in "boot"
	
	# Additional vowels
	"AE": [660.0, 1720.0, 2410.0, 3400.0],  # "a" as in "cat"
	"UH": [640.0, 1190.0, 2390.0, 3400.0],  # "uh" as in "but"
	"ER": [490.0, 1350.0, 1690.0, 3400.0],  # "er" as in "bird"
}

# Formant bandwidths (resonance width)
const BANDWIDTHS = [80.0, 90.0, 150.0, 200.0]

# =============================================================================
# CONSONANT PATTERNS
# =============================================================================

const CONSONANTS = {
	# Consonant: {type, duration_ms, noise_level, formant_transition}
	"M": {"type": "nasal", "duration": 80, "freq": 250.0},
	"N": {"type": "nasal", "duration": 60, "freq": 350.0},
	"L": {"type": "liquid", "duration": 50, "freq": 400.0},
	"S": {"type": "fricative", "duration": 100, "noise_band": [4000.0, 8000.0]},
	"SH": {"type": "fricative", "duration": 120, "noise_band": [2000.0, 6000.0]},
	"F": {"type": "fricative", "duration": 80, "noise_band": [1500.0, 5000.0]},
	"T": {"type": "plosive", "duration": 30, "burst_freq": 3000.0},
	"K": {"type": "plosive", "duration": 40, "burst_freq": 1500.0},
	"P": {"type": "plosive", "duration": 25, "burst_freq": 800.0},
	"B": {"type": "voiced_plosive", "duration": 30, "burst_freq": 500.0},
	"D": {"type": "voiced_plosive", "duration": 35, "burst_freq": 2000.0},
}


# =============================================================================
# MAIN GENERATION FUNCTIONS
# =============================================================================

static func generate_note(freq: float, duration: float, vowel: String = "A", 
						   params: Dictionary = {}) -> PackedFloat32Array:
	"""Generate a single sung note with specified vowel"""
	var sample_count = int(duration * SAMPLE_RATE)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	var vibrato_rate = params.get("vibrato_rate", 5.5)  # Hz
	var vibrato_depth = params.get("vibrato_depth", 0.015)  # semitones as ratio
	var breathiness = params.get("breathiness", 0.1)
	var expression = params.get("expression", 0.8)
	
	var formants = VOWELS.get(vowel, VOWELS["A"])
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Vibrato (delayed onset, natural)
		var vib_amount = min(1.0, progress * 3.0)  # Fade in vibrato
		var vibrato = sin(TAU * vibrato_rate * t) * vibrato_depth * vib_amount
		var current_freq = freq * (1.0 + vibrato)
		
		# Pitch drift (slight natural wavering)
		current_freq *= 1.0 + sin(t * 0.7) * 0.002
		
		# Glottal source (pulse-like waveform simulating vocal folds)
		var source = _glottal_pulse(t, current_freq, breathiness)
		
		# Apply formant filtering
		var output = _apply_formants(source, t, formants)
		
		# Amplitude envelope (natural singing shape)
		var env = _singing_envelope(progress, duration)
		
		# Expression dynamics
		var dynamics = 0.8 + sin(progress * PI) * 0.2 * expression
		
		data[i] = clampf(output * env * dynamics * 0.5, -1.0, 1.0)
	
	return data


static func generate_melody(notes: Array, params: Dictionary = {}) -> PackedFloat32Array:
	"""
	Generate a sung melody from note data.
	notes = [{"freq": 440.0, "duration": 0.5, "vowel": "A"}, ...]
	"""
	var total_samples = 0
	for note in notes:
		total_samples += int(note.get("duration", 0.5) * SAMPLE_RATE)
	
	var data = PackedFloat32Array()
	data.resize(total_samples)
	data.fill(0.0)
	
	var offset = 0
	for note in notes:
		var freq = note.get("freq", 440.0)
		var duration = note.get("duration", 0.5)
		var vowel = note.get("vowel", "A")
		
		var note_data = generate_note(freq, duration, vowel, params)
		
		# Apply crossfade for legato
		var crossfade_samples = min(int(0.02 * SAMPLE_RATE), note_data.size() / 4)
		
		for i in range(note_data.size()):
			if offset + i < data.size():
				var fade = 1.0
				if i < crossfade_samples and offset > 0:
					fade = float(i) / crossfade_samples
				data[offset + i] += note_data[i] * fade
		
		offset += note_data.size() - crossfade_samples
	
	return data


static func generate_syllables(syllables: Array, base_freq: float, 
								params: Dictionary = {}) -> PackedFloat32Array:
	"""
	Generate sung syllables with consonant-vowel patterns.
	syllables = [{"cv": "LA", "duration": 0.3, "pitch_offset": 0}, ...]
	pitch_offset in semitones from base_freq
	"""
	var total_duration = 0.0
	for syl in syllables:
		total_duration += syl.get("duration", 0.3)
	
	var total_samples = int(total_duration * SAMPLE_RATE)
	var data = PackedFloat32Array()
	data.resize(total_samples)
	data.fill(0.0)
	
	var offset = 0
	for syl in syllables:
		var cv = syl.get("cv", "A")
		var duration = syl.get("duration", 0.3)
		var pitch_offset = syl.get("pitch_offset", 0)
		var freq = base_freq * pow(2.0, pitch_offset / 12.0)
		
		var syl_data = _generate_syllable(cv, freq, duration, params)
		
		for i in range(syl_data.size()):
			if offset + i < data.size():
				data[offset + i] = syl_data[i]
		
		offset += syl_data.size()
	
	return data


# =============================================================================
# INTERNAL SYNTHESIS FUNCTIONS
# =============================================================================

static func _glottal_pulse(t: float, freq: float, breathiness: float) -> float:
	"""Generate glottal pulse waveform (vocal fold vibration)"""
	var phase = fmod(t * freq, 1.0)
	
	# LF model approximation (Liljencrants-Fant glottal flow)
	var pulse: float
	if phase < 0.4:
		# Opening phase
		pulse = sin(PI * phase / 0.4)
	elif phase < 0.6:
		# Closing phase (faster)
		pulse = sin(PI * (1.0 - (phase - 0.4) / 0.2))
	else:
		# Closed phase
		pulse = 0.0
	
	# Add aspiration noise (breathiness)
	var noise = (randf() * 2.0 - 1.0) * breathiness
	
	# Mix
	return pulse * (1.0 - breathiness * 0.5) + noise


static func _apply_formants(source: float, t: float, formants: Array) -> float:
	"""Apply formant resonances to shape vowel"""
	var output = 0.0
	
	for i in range(min(formants.size(), BANDWIDTHS.size())):
		var f = formants[i]
		var bw = BANDWIDTHS[i]
		
		# Resonant bandpass approximation
		# Higher formants have less amplitude
		var amp = 1.0 / (i + 1)
		
		# Formant resonance (simplified)
		var resonance = sin(TAU * f * t)
		
		# Bandwidth affects decay
		var decay = exp(-bw * 0.0001)
		
		output += source * resonance * amp * decay
	
	return output * 0.4


static func _singing_envelope(progress: float, duration: float) -> float:
	"""Natural singing amplitude envelope"""
	var attack = 0.05 / duration  # 50ms attack
	var release = 0.1 / duration  # 100ms release
	
	if progress < attack:
		return progress / attack
	elif progress > 1.0 - release:
		return (1.0 - progress) / release
	else:
		# Subtle amplitude variation (natural breathing)
		return 1.0 + sin(progress * PI * 4) * 0.05


static func _generate_syllable(cv: String, freq: float, duration: float, 
								params: Dictionary) -> PackedFloat32Array:
	"""Generate a consonant-vowel syllable"""
	var sample_count = int(duration * SAMPLE_RATE)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	data.fill(0.0)
	
	# Parse consonant and vowel
	var consonant = ""
	var vowel = "A"
	
	if cv.length() >= 2:
		consonant = cv.substr(0, cv.length() - 1).to_upper()
		vowel = cv.substr(cv.length() - 1, 1).to_upper()
	else:
		vowel = cv.to_upper()
	
	if not VOWELS.has(vowel):
		vowel = "A"
	
	# Generate consonant (if any)
	var consonant_samples = 0
	if CONSONANTS.has(consonant):
		var cons_info = CONSONANTS[consonant]
		consonant_samples = int(cons_info.duration * SAMPLE_RATE / 1000.0)
		
		for i in range(min(consonant_samples, sample_count)):
			var t = float(i) / SAMPLE_RATE
			data[i] = _generate_consonant(consonant, t, cons_info, freq)
	
	# Generate vowel
	var formants = VOWELS[vowel]
	var breathiness = params.get("breathiness", 0.1)
	var vibrato_rate = params.get("vibrato_rate", 5.5)
	var vibrato_depth = params.get("vibrato_depth", 0.015)
	
	for i in range(consonant_samples, sample_count):
		var t = float(i - consonant_samples) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Vibrato
		var vib_amount = min(1.0, (progress - 0.2) * 2.0)
		vib_amount = max(0.0, vib_amount)
		var vibrato = sin(TAU * vibrato_rate * t) * vibrato_depth * vib_amount
		var current_freq = freq * (1.0 + vibrato)
		
		# Source + formants
		var source = _glottal_pulse(t, current_freq, breathiness)
		var output = _apply_formants(source, t, formants)
		
		# Envelope with consonant transition
		var env = _singing_envelope(progress, duration)
		if i < consonant_samples + int(0.03 * SAMPLE_RATE):
			var trans = float(i - consonant_samples) / (0.03 * SAMPLE_RATE)
			env *= trans
		
		data[i] = clampf(output * env * 0.5, -1.0, 1.0)
	
	return data


static func _generate_consonant(consonant: String, t: float, info: Dictionary, 
								 base_freq: float) -> float:
	"""Generate consonant sound"""
	var cons_type = info.get("type", "")
	var duration_s = info.get("duration", 50) / 1000.0
	var progress = t / duration_s
	var env = 1.0 - progress if progress < 1.0 else 0.0
	
	match cons_type:
		"nasal":
			var f = info.get("freq", 300.0)
			return sin(TAU * f * t) * sin(TAU * base_freq * t) * env * 0.3
		
		"liquid":
			var f = info.get("freq", 400.0)
			return sin(TAU * f * t) * env * 0.4
		
		"fricative":
			var band = info.get("noise_band", [2000.0, 6000.0])
			var noise = randf() * 2.0 - 1.0
			# Bandpass approximation
			noise *= sin(TAU * (band[0] + band[1]) * 0.5 * t)
			return noise * env * 0.2
		
		"plosive":
			var burst_freq = info.get("burst_freq", 2000.0)
			if t < 0.01:
				return sin(TAU * burst_freq * t) * exp(-t * 200) * 0.5
			return 0.0
		
		"voiced_plosive":
			var burst_freq = info.get("burst_freq", 1000.0)
			var voiced = sin(TAU * base_freq * t) * 0.3
			if t < 0.01:
				return sin(TAU * burst_freq * t) * exp(-t * 150) * 0.4 + voiced
			return voiced * env
	
	return 0.0


# =============================================================================
# UTILITY: Convert to AudioStreamWAV
# =============================================================================

static func to_audio_stream(data: PackedFloat32Array) -> AudioStreamWAV:
	"""Convert float array to AudioStreamWAV"""
	var wav = AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = int(SAMPLE_RATE)
	wav.stereo = false
	
	var byte_data = PackedByteArray()
	byte_data.resize(data.size() * 2)
	
	for i in range(data.size()):
		var sample_16 = int(clampf(data[i], -1.0, 1.0) * 32767)
		byte_data[i * 2] = sample_16 & 0xFF
		byte_data[i * 2 + 1] = (sample_16 >> 8) & 0xFF
	
	wav.data = byte_data
	return wav


# =============================================================================
# DEMO/TEST FUNCTIONS
# =============================================================================

static func demo_vowels() -> AudioStreamWAV:
	"""Demo: Sing through all vowels on A4 (440Hz)"""
	var notes = []
	for vowel in ["A", "E", "I", "O", "U"]:
		notes.append({"freq": 440.0, "duration": 0.6, "vowel": vowel})
	
	var data = generate_melody(notes, {"vibrato_depth": 0.02})
	return to_audio_stream(data)


static func demo_scale() -> AudioStreamWAV:
	"""Demo: Sing a major scale on 'La'"""
	var base = 261.63  # C4
	var scale = [0, 2, 4, 5, 7, 9, 11, 12]  # Major scale semitones
	
	var syllables = []
	for semitone in scale:
		syllables.append({
			"cv": "LA",
			"duration": 0.4,
			"pitch_offset": semitone
		})
	
	var data = generate_syllables(syllables, base, {})
	return to_audio_stream(data)


static func demo_phrase(text: String = "LA LA LA", base_freq: float = 261.63) -> AudioStreamWAV:
	"""Demo: Sing a simple phrase"""
	var syllables = []
	var words = text.split(" ")
	var pitch = 0
	
	for word in words:
		syllables.append({
			"cv": word,
			"duration": 0.35,
			"pitch_offset": pitch
		})
		pitch = (pitch + 2) % 12  # Simple ascending pattern
	
	var data = generate_syllables(syllables, base_freq, {"breathiness": 0.15})
	return to_audio_stream(data)
