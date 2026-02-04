# Donna Summer Singing Voice - "I Feel Love" style
# Character: Breathy, high, repetitive, ecstatic
# Source: Formant synthesis inspired by the iconic vocal
#
# The vocal in "I Feel Love" is:
# - High register (around C5-G5)
# - Very breathy (aspirated)
# - Simple melodic phrase repeating
# - Slightly processed with delay/reverb

class_name DonnaSummerVoice
extends RefCounted

const SAMPLE_RATE = 44100.0
const LEVEL = 0.12

# Vowel formants for the phrase "I feel love"
# "I" (ah-ee diphthong), "feel" (ee), "love" (uh)
const FORMANTS = {
	"I": {"f1": 400.0, "f2": 2000.0, "f3": 2800.0},     # "ah" -> "ee"
	"ee": {"f1": 270.0, "f2": 2300.0, "f3": 3000.0},    # "ee" as in feel
	"uh": {"f1": 640.0, "f2": 1200.0, "f3": 2400.0},    # "uh" as in love
}

const BANDWIDTHS = [90.0, 110.0, 170.0]

# Vibrato settings (characteristic of the recording)
const VIBRATO_RATE = 5.8
const VIBRATO_DEPTH = 0.018


static func generate(t: float, freq: float, duration: float = 0.5, trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > duration:
		return 0.0
	
	var progress = dt / duration
	
	# High breathiness is key to Donna Summer's sound
	var breathiness = 0.25
	
	# Vibrato (delayed onset, natural)
	var vib_amount = clampf((progress - 0.15) * 3.0, 0.0, 1.0)
	var vibrato = sin(TAU * VIBRATO_RATE * dt) * VIBRATO_DEPTH * vib_amount
	var current_freq = freq * (1.0 + vibrato)
	
	# Slight pitch drift (human quality)
	current_freq *= 1.0 + sin(dt * 0.8) * 0.003
	
	# Glottal pulse source (breathy)
	var source = _glottal_pulse(dt, current_freq, breathiness)
	
	# Default to "ee" vowel (most common in the phrase)
	var formants = FORMANTS["ee"]
	
	# Apply formant filtering
	var output = _apply_formants(source, dt, formants)
	
	# Singing envelope (smooth attack, sustain, gentle release)
	var env = 1.0
	if progress < 0.08:
		env = progress / 0.08
	elif progress > 0.85:
		env = (1.0 - progress) / 0.15
	
	# Subtle dynamics
	env *= 0.9 + sin(progress * PI) * 0.1
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_phrase(t: float, freq: float, word: String = "ee", duration: float = 0.5, trigger_time: float = 0.0) -> float:
	"""Generate a specific vowel sound for the phrase"""
	var dt = t - trigger_time
	if dt < 0.0 or dt > duration:
		return 0.0
	
	var progress = dt / duration
	var breathiness = 0.25
	
	# Vibrato
	var vib_amount = clampf((progress - 0.15) * 3.0, 0.0, 1.0)
	var vibrato = sin(TAU * VIBRATO_RATE * dt) * VIBRATO_DEPTH * vib_amount
	var current_freq = freq * (1.0 + vibrato)
	
	# Get formants for this word/vowel
	var formants = FORMANTS.get(word, FORMANTS["ee"])
	
	# Morphing for diphthongs (like "I" = ah->ee)
	if word == "I":
		var morph = clampf(progress * 2.0, 0.0, 1.0)
		formants = {
			"f1": lerp(600.0, 270.0, morph),  # ah -> ee
			"f2": lerp(1200.0, 2300.0, morph),
			"f3": lerp(2600.0, 3000.0, morph)
		}
	
	var source = _glottal_pulse(dt, current_freq, breathiness)
	var output = _apply_formants(source, dt, formants)
	
	# Envelope
	var env = 1.0
	if progress < 0.08:
		env = progress / 0.08
	elif progress > 0.85:
		env = (1.0 - progress) / 0.15
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func _glottal_pulse(t: float, freq: float, breathiness: float) -> float:
	"""Breathy glottal pulse"""
	var phase = fmod(t * freq, 1.0)
	
	# LF glottal model (simplified)
	var pulse: float
	if phase < 0.35:
		pulse = sin(PI * phase / 0.35)
	elif phase < 0.55:
		pulse = sin(PI * (1.0 - (phase - 0.35) / 0.2))
	else:
		pulse = 0.0
	
	# High breathiness for Donna Summer sound
	var noise = (randf() * 2.0 - 1.0) * breathiness
	
	# Aspiration filtered
	var aspiration = noise * (1.0 - phase * 0.5)
	
	return pulse * (1.0 - breathiness * 0.4) + aspiration


static func _apply_formants(source: float, t: float, formants: Dictionary) -> float:
	"""Apply formant resonances"""
	var output = 0.0
	
	var f_array = [formants.get("f1", 500.0), formants.get("f2", 1500.0), formants.get("f3", 2500.0)]
	
	for i in range(f_array.size()):
		var f = f_array[i]
		var bw = BANDWIDTHS[i]
		var amp = 1.0 / (i + 1)
		
		# Resonance
		var resonance = sin(TAU * f * t)
		output += source * resonance * amp * exp(-bw * 0.0001)
	
	return output * 0.5


static func get_duration() -> float:
	return 0.5


static func get_description() -> String:
	return "Donna Summer Voice - Breathy, high register formant synthesis for 'I Feel Love' style vocals"
