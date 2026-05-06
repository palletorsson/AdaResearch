# singing_voice.gd
# Synthesized singing voice for Vangelis-style ethereal vocals
# Character: Ethereal, breathy, choir-like with formant vowel synthesis
# Source: Formant synthesis with glottal pulse source
# Processing: Vibrato, natural envelope, vowel morphing

class_name VangelisSingingVoice
extends RefCounted

const SAMPLE_RATE = 44100.0

# Vowel formants (F1, F2, F3)
const VOWELS = {
	"A": [730.0, 1090.0, 2440.0],   # "ah"
	"E": [530.0, 1840.0, 2480.0],   # "eh"  
	"I": [270.0, 2290.0, 3010.0],   # "ee"
	"O": [570.0, 840.0, 2410.0],    # "oh"
	"U": [300.0, 870.0, 2240.0],    # "oo"
}

const BANDWIDTHS = [80.0, 90.0, 150.0]
const LEVEL = 0.15


static func generate(t: float, freq: float, duration: float = 2.0, 
					  trigger_time: float = 0.0) -> float:
	var dt = t - trigger_time
	if dt < 0.0 or dt > duration:
		return 0.0
	
	var progress = dt / duration
	
	# Vowel morph: A -> O -> A (ethereal choir sound)
	var morph = sin(progress * PI * 2) * 0.5 + 0.5
	var formants_a = VOWELS["A"]
	var formants_o = VOWELS["O"]
	
	# Vibrato (slow, expressive)
	var vib_amount = min(1.0, progress * 2.0)
	var vibrato = sin(TAU * 5.5 * dt) * 0.012 * vib_amount
	var current_freq = freq * (1.0 + vibrato)
	
	# Pitch drift
	current_freq *= 1.0 + sin(dt * 0.5) * 0.003
	
	# Glottal pulse source
	var phase = fmod(dt * current_freq, 1.0)
	var pulse: float
	if phase < 0.4:
		pulse = sin(PI * phase / 0.4)
	elif phase < 0.6:
		pulse = sin(PI * (1.0 - (phase - 0.4) / 0.2))
	else:
		pulse = 0.0
	
	# Add breathiness
	var breath = (randf() * 2.0 - 1.0) * 0.15
	var source = pulse * 0.85 + breath
	
	# Apply morphing formants
	var output = 0.0
	for i in range(3):
		var f = lerp(formants_a[i], formants_o[i], morph)
		var bw = BANDWIDTHS[i]
		var amp = 1.0 / (i + 1)
		var resonance = sin(TAU * f * dt)
		output += source * resonance * amp * exp(-bw * 0.0001)
	
	# Envelope
	var env = 1.0
	if progress < 0.1:
		env = progress / 0.1
	elif progress > 0.85:
		env = (1.0 - progress) / 0.15
	
	# Subtle dynamics
	env *= 0.9 + sin(progress * PI) * 0.1
	
	return clampf(output * env * LEVEL, -1.0, 1.0)


static func generate_sample(t: float, freq_source = 220.0) -> float:
	"""Simple sample generation for pattern-based playback"""
	var freq := 220.0
	if freq_source is Array:
		var values: Array = freq_source
		if not values.is_empty():
			freq = maxf(float(values[0]), 1.0)
	else:
		freq = maxf(float(freq_source), 1.0)
	return generate(t, freq, 0.5, 0.0)


static func get_duration() -> float:
	return 2.0


static func get_description() -> String:
	return "Vangelis Singing Voice - Ethereal formant synthesis with vowel morphing (A-O-A), vibrato, and breathy character."
