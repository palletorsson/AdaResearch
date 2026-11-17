extends RefCounted
## Individual desktop tuning, 2026-11-16. These are auditionable design settings,
## not new measurements of the Airway or a claim of native-speaker intelligibility.
## Source/filter separation, closure/burst/aspiration and nasal antiresonances:
## https://uvafon.hum.uva.nl/praat/manual/KlattGrid.html
## Phone-specific transitions: https://espeak.sourceforge.net/phontab.html
const Robot := preload("res://audio/generators/RobotVoiceGenerator.gd")
const SR := 44100
const VERSION := "individual-1"

# F1 F2 F3, their bandwidths, relative phrase level. Upper resonances stay in
# the measured-pilot family. Relative levels are smoothed, before normalization.
const VOWELS := {
	"a": [780, 1660, 3030, 85, 100, 140, 0.94],
	"i": [310, 2670, 3260, 65, 105, 155, 1.12],
	"u": [350, 900, 2550, 70, 90, 135, 1.05],
	"e": [555, 2290, 3060, 85, 110, 145, 0.98],
	"o": [535, 1090, 2680, 85, 95, 135, 0.96],
	"uh": [535, 1650, 2770, 100, 130, 160, 0.88],
	"y": [310, 2070, 2560, 70, 95, 135, 1.08],
	"eu": [465, 1850, 2620, 85, 105, 145, 1.00],
	"ae": [690, 2190, 3210, 95, 115, 160, 0.93],
	"oe": [610, 1730, 2770, 95, 115, 150, 0.96],
	"r": [475, 1450, 1800, 95, 120, 125, 0.93],
	"l": [365, 1190, 2550, 85, 140, 190, 0.86],
	"ih": [455, 2110, 2950, 90, 130, 170, 1.02],
	"er": [510, 1480, 1850, 95, 120, 130, 0.95],
	"aw": [675, 1070, 2770, 95, 105, 155, 0.95],
	"ah": [720, 1430, 2830, 95, 125, 160, 0.94]
}

# F1 F2 F3, voicing, relative phrase level, antiresonance Hz (0 = none).
# The synthetic fold pulse supplies voicing, avoiding an unrelated sine pitch.
const CONSONANTS := {
	"p": [350, 900, 2400, 0.00, 1.00, 0],
	"b": [350, 900, 2400, 0.12, 1.10, 0],
	"t": [380, 1750, 2900, 0.00, 0.95, 0],
	"d": [380, 1750, 2900, 0.15, 1.00, 0],
	"k": [380, 2100, 2550, 0.00, 1.05, 0],
	"g": [380, 2100, 2550, 0.17, 1.05, 0],
	"f": [400, 1450, 2650, 0.00, 1.15, 0],
	"v": [400, 1450, 2650, 0.60, 1.00, 0],
	"th": [410, 1600, 2700, 0.00, 1.25, 0],
	"dh": [410, 1600, 2700, 0.66, 1.05, 0],
	"s": [380, 1800, 2850, 0.00, 0.90, 0],
	"z": [380, 1800, 2850, 0.58, 0.94, 0],
	"sh": [410, 1850, 2650, 0.00, 0.95, 0],
	"zh": [410, 1850, 2650, 0.58, 0.98, 0],
	"h": [500, 1500, 2700, 0.00, 1.18, 0],
	"ch": [380, 1850, 2650, 0.00, 1.00, 0],
	"j": [380, 1850, 2650, 0.32, 1.03, 0],
	"m": [265, 1050, 2250, 0.78, 1.08, 820],
	"n": [280, 1650, 2650, 0.78, 1.03, 1250],
	"ng": [285, 2000, 2850, 0.73, 1.02, 1550],
	"l": [365, 1190, 2550, 0.95, 0.96, 2050],
	"r": [420, 1330, 1700, 0.95, 0.96, 0],
	"w": [300, 760, 2450, 0.88, 1.05, 0],
	"y": [285, 2550, 3100, 0.95, 1.03, 0]
}

# Same-place voiced/unvoiced pairs share the noise spectrum. Distinction comes
# from fold voicing and frication strength, not an arbitrary spectral shift.
# Center, Q, noise amplitude, broad unfiltered mix.
const FRICATIVES := {
	"s": [6500, 1.65, 0.29, 0.00], "z": [6500, 1.65, 0.13, 0.00],
	"sh": [2900, 1.50, 0.25, 0.06], "zh": [2900, 1.50, 0.13, 0.06],
	"f": [3300, 0.65, 0.13, 0.35], "v": [3300, 0.65, 0.065, 0.35],
	"th": [4800, 0.55, 0.10, 0.48], "dh": [4800, 0.55, 0.045, 0.48]
}
# Burst center, Q, gain, closure fraction, burst ms, aspiration gain.
const STOPS := {
	"p": [850, 0.65, 0.65, 0.42, 8.0, 0.13],
	"b": [650, 0.70, 0.45, 0.55, 7.0, 0.01],
	"t": [5200, 1.40, 0.68, 0.45, 6.0, 0.12],
	"d": [4400, 1.20, 0.45, 0.55, 6.0, 0.01],
	"k": [2300, 1.70, 0.75, 0.42, 11.0, 0.16],
	"g": [2100, 1.60, 0.52, 0.55, 10.0, 0.015],
	"ch": [4400, 1.20, 0.50, 0.28, 6.0, 0.0],
	"j": [4200, 1.10, 0.40, 0.33, 6.0, 0.0]
}
# Relative to the cascade's fold output, not raw white-noise full scale.
# Audited in /a C a/: the previous unvoiced middle was roughly 30 dB below /a/.
const NOISE_GAIN := {"p": 6.0, "b": 3.5, "t": 5.5, "d": 3.5, "k": 5.0, "g": 3.2,
	"s": 6.0, "z": 3.0, "sh": 6.2, "zh": 3.0, "f": 7.0, "v": 3.0,
	"th": 8.0, "dh": 3.0, "h": 7.0, "ch": 6.0, "j": 4.0}
const NOTES := {
	"a": "Open vowel: clearer back/front separation from ae.",
	"i": "Lower first resonance; brighter high-front vowel, distinct from ih.",
	"u": "Lower first and second resonances; separates rounded u from o.",
	"e": "Raised first resonance and lower second; separates e from ih.",
	"o": "Open the rounded vowel relative to u; soften narrow resonances.",
	"uh": "Quieter, broader neutral vowel for unstressed syllables.",
	"y": "Low first resonance with a front rounded second resonance.",
	"eu": "Mid front-rounded target, between y and oe.",
	"ae": "More open front vowel; distinct from a and e.",
	"oe": "Open front-rounded target with broader resonances.",
	"r": "Lower third resonance gives the rhotic vowel its characteristic colour.",
	"l": "Lateral resonance and a spectral notch, not an ordinary vowel.",
	"ih": "Lower second resonance separates the lax vowel from i and e.",
	"er": "Rhotic sustained target; a little more open than the legacy r target.",
	"aw": "More open back-rounded vowel, separated from o.",
	"ah": "Open central/back vowel, separated from a and neutral uh.",
	"consonant:p": "Lip closure, diffuse low burst, then aspiration.",
	"consonant:b": "Voiced lip closure, softer low burst, little aspiration.",
	"consonant:t": "Quiet closure and a sharp high burst with aspiration.",
	"consonant:d": "Voiced closure, shorter high burst, little aspiration.",
	"consonant:k": "Back-of-mouth closure, longer compact burst and aspiration.",
	"consonant:g": "Voiced back closure, compact burst with a short release.",
	"consonant:f": "Diffuse sustained lip/teeth noise, without the sharp s whistle.",
	"consonant:v": "Same noise region as f with fold voicing underneath.",
	"consonant:th": "Weak diffuse dental noise; given enough presence to survive singing.",
	"consonant:dh": "Dental noise with stronger voicing; distinct from th.",
	"consonant:s": "High sibilant noise with a sustained middle.",
	"consonant:z": "Same high noise region as s, plus voicing.",
	"consonant:sh": "Lower, broader sibilant noise than s.",
	"consonant:zh": "New voiced sh-like frication, as in measure.",
	"consonant:h": "Breath filtered toward the following vowel's resonances.",
	"consonant:ch": "Closure and burst flowing into sh frication.",
	"consonant:j": "Voiced closure flowing into zh frication, replacing the old z tail.",
	"consonant:m": "Low nasal murmur with a lip-closure antiresonance.",
	"consonant:n": "Nasal murmur with a higher tongue-tip resonance and notch.",
	"consonant:ng": "Back nasal resonance and a distinct higher antiresonance.",
	"consonant:l": "Lateral resonance and notch, distinct from the rhotic r.",
	"consonant:r": "Lowered third resonance, with voiced approach and release.",
	"consonant:w": "Low rounded resonance gliding into the adjacent vowel.",
	"consonant:y": "High front resonance gliding into the adjacent vowel."
}

static func tracts(base: Dictionary) -> Dictionary:
	var result := base.duplicate(true)
	for symbol: String in VOWELS:
		var row: Array = VOWELS[symbol]
		var target: Array = result.get(symbol, Robot.targets("vowel", symbol)).duplicate(true)
		for i in 3:
			target[0][i] = row[i]
			target[1][i] = row[i + 3]
		result[symbol] = target
	for symbol: String in CONSONANTS:
		var row: Array = CONSONANTS[symbol]
		var nasal := symbol in ["m", "n", "ng"]
		result["consonant:" + symbol] = [[row[0], row[1], row[2], 3800, 4900],
			[100 if nasal else 85, 180 if nasal else 130, 220 if nasal else 150, 240, 300], [0, -8, -12, -16, -22]]
	return result

static func gain_for(phone: Dictionary) -> float:
	return float(VOWELS[phone.phoneme][6] if phone.kind == "vowel" else CONSONANTS[phone.phoneme][4])

static func voicing(phone: Dictionary, phase: float) -> float:
	if phone.kind == "vowel": return 1.0
	var symbol := str(phone.phoneme)
	var value := float(CONSONANTS[symbol][3])
	if STOPS.has(symbol) and phase < float(STOPS[symbol][3]):
		value *= 0.4
	return value

static func notch_for(phone: Dictionary) -> float:
	if phone.kind == "vowel": return 2050.0 if phone.phoneme == "l" else 0.0
	return float(CONSONANTS[phone.phoneme][5])

static func notch_coeff(hz: float) -> Array:
	var omega := TAU * hz / SR
	var alpha := sin(omega) / 3.0
	var c := cos(omega)
	return [1.0 / (1.0 + alpha), -2.0 * c / (1.0 + alpha), 1.0 / (1.0 + alpha), -2.0 * c / (1.0 + alpha), (1.0 - alpha) / (1.0 + alpha)]

static func _frication(symbol: String, frames: int, rng: Array) -> PackedFloat64Array:
	var row: Array = FRICATIVES[symbol]
	var bp := Robot._coeff(float(row[0]), float(row[1]))
	var hp := Robot._coeff(650.0, 0.707, "hp")
	var state := [0.0, 0.0]
	var high := [0.0, 0.0]
	var output := PackedFloat64Array()
	output.resize(frames)
	for i in frames:
		var white := Robot._filter(Robot._noise(rng), hp, high)
		var noise := lerpf(Robot._filter(white, bp, state), white, float(row[3]))
		var env := minf(1.0, minf(float(i) / maxi(1, mini(441, frames / 5)), float(frames - 1 - i) / maxi(1, mini(662, frames / 4))))
		output[i] = noise * float(row[2]) * maxf(0.0, env)
	return output

static func consonant(symbol: String, frames: int, _hz: float, rng: Array, next_tract: Array) -> PackedFloat64Array:
	var output := PackedFloat64Array()
	output.resize(frames)
	if FRICATIVES.has(symbol):
		output = _frication(symbol, frames, rng)
	elif symbol == "h":
		var low := Robot._coeff(float(next_tract[0][0]), 0.9)
		var high := Robot._coeff(float(next_tract[0][1]), 1.1)
		var s1 := [0.0, 0.0]
		var s2 := [0.0, 0.0]
		for i in frames:
			var noise := Robot._noise(rng)
			output[i] = (Robot._filter(noise, low, s1) * 0.7 + Robot._filter(noise, high, s2) * 0.3) * 0.24 * sin(PI * float(i) / maxi(1, frames - 1))
	elif STOPS.has(symbol):
		var row: Array = STOPS[symbol]
		var closure := roundi(frames * float(row[3]))
		var burst := mini(roundi(float(row[4]) * SR / 1000.0), maxi(1, (frames - closure) / 3))
		var c := Robot._coeff(float(row[0]), float(row[1]))
		var state := [0.0, 0.0]
		for i in burst:
			var envelope := sin(PI * float(i) / maxi(1, burst - 1))
			output[closure + i] = Robot._filter(Robot._noise(rng), c, state) * envelope * float(row[2])
		var start := closure + burst
		if symbol in ["ch", "j"]:
			var tail := _frication("sh" if symbol == "ch" else "zh", frames - start, rng)
			for i in tail.size(): output[start + i] = tail[i]
		else:
			c = Robot._coeff(1400.0, 0.707, "hp")
			state = [0.0, 0.0]
			for i in range(frames - start):
				var env := exp(-float(i) / (0.025 * SR)) * minf(1.0, float(frames - start - 1 - i) / 88.0)
				output[start + i] = Robot._filter(Robot._noise(rng), c, state) * float(row[5]) * env
	var noise_gain := float(NOISE_GAIN.get(symbol, 1.0))
	for i in output.size(): output[i] *= noise_gain
	return output
