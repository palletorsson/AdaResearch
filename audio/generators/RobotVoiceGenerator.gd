extends RefCounted
## Opt-in, sample-free phrase renderer ported from robot_voice_v2.py and
## robot_phrase_articulation.py. All DSP state is local to one render.
## Input is an explicit 44100 Hz voice_plan, not an English text tokenizer.

const SR := 44100
const BLOCK := 48
# Keep headroom for higher registers without normalizing away word stress.
const DEFAULT_GAIN := 0.35
const VOWELS := {
	"a": [[700,1220,2600,3300,3750],[60,90,120,130,140],[0,-7,-9,-12,-14]],
	"i": [[270,2300,3000,3500,4200],[50,100,120,150,160],[0,-13,-10,-14,-18]],
	"u": [[300,870,2250,3300,4100],[50,80,120,140,150],[0,-8,-18,-22,-26]],
	"e": [[390,2150,2700,3300,4000],[55,90,120,130,150],[0,-9,-11,-14,-18]],
	"o": [[400,800,2600,3300,3800],[55,80,120,130,140],[0,-9,-14,-18,-22]],
	"uh": [[500,1500,2500,3300,3850],[60,90,120,130,150],[0,-8,-12,-16,-20]],
	"y": [[235,2100,2700,3300,3850],[50,100,120,130,150],[0,-12,-12,-16,-20]],
	"eu": [[370,1900,2500,3300,3850],[55,90,120,130,150],[0,-10,-12,-16,-20]],
	"ae": [[610,1900,2650,3300,3800],[70,100,120,130,140],[0,-8,-11,-15,-19]],
	"oe": [[585,1710,2550,3300,3850],[65,95,120,130,150],[0,-9,-13,-17,-21]],
	"r": [[450,1200,1600,3300,3850],[60,90,120,130,150],[0,-7,-9,-16,-20]],
	"l": [[360,1300,2600,3300,3850],[55,90,120,130,150],[0,-8,-12,-16,-20]],
	"ih": [[430,1900,2550,3300,4000],[80,120,160,180,200],[0,-7,-10,-17,-22]],
	"er": [[490,1350,1690,3300,3850],[90,130,160,220,250],[0,-7,-5,-20,-25]],
	"aw": [[570,840,2410,3300,3850],[85,100,160,200,230],[0,-7,-16,-21,-25]],
	"ah": [[640,1200,2500,3300,3850],[90,120,160,200,240],[0,-7,-12,-20,-25]],
}
const LOCUS := {
	"l": [400,900], "r": [450,1300], "w": [350,750], "y": [250,2200],
	"n": [300,1600], "m": [300,1000], "ng": [300,2000], "h": [500,1500],
	"s": [400,1700], "sh": [400,1700], "f": [400,1500], "v": [400,1500],
	"th": [400,1400], "dh": [400,1400], "z": [400,1700], "t": [400,1700],
	"d": [400,1700], "k": [400,1500], "g": [400,1500], "p": [400,1100],
	"b": [400,1100], "ch": [400,1700], "j": [400,1700],
}
const FRICATIVE := {"s":7000.0, "z":4000.0, "sh":3000.0, "f":5000.0,
	"v":2500.0, "th":6000.0, "dh":6000.0, "h":3500.0}
const STOPS := {"p":[600.0,1.4], "b":[300.0,1.2], "t":[5500.0,1.0],
	"d":[4000.0,0.8], "k":[2500.0,1.1], "g":[1800.0,0.9]}
const GLIDES := [["a","ih"], ["a","u"]]


static func _number(x: Variant) -> bool:
	return (x is float or x is int) and is_finite(float(x))


static func _integer(x: Variant) -> bool:
	return _number(x) and float(x) == floor(float(x))


static func validate_plan(plan: Dictionary, options: Dictionary = {}) -> String:
	if not _integer(plan.get("frames")) or plan.frames < 2 or plan.frames > SR * 60:
		return "frames must be an integer between 2 and 60 seconds at 44100 Hz"
	for key in ["phones", "syllables", "word_groups"]:
		if not plan.get(key) is Array or plan[key].is_empty():
			return key + " must be a nonempty array"
	if plan.has("offset") and (not _integer(plan.offset) or plan.offset < 0):
		return "offset must be a nonnegative frame"
	for key in ["formant_ratio", "transpose", "gain", "seed"]:
		if options.has(key) and not _number(options[key]):
			return "Invalid numeric option: " + key
	if options.has("seed") and (not _integer(options.seed) or options.seed < -2147483648 or options.seed > 2147483647):
		return "seed must be a signed 32-bit integer"
	if options.get("formant_ratio", 1.0) < 0.8 or options.get("formant_ratio", 1.0) > 1.3:
		return "formant_ratio must be between 0.8 and 1.3"
	if absf(options.get("transpose", 0.0)) > 24.0:
		return "transpose must be between -24 and 24 semitones"
	if options.get("gain", DEFAULT_GAIN) < 0.0 or options.get("gain", DEFAULT_GAIN) > 4.0:
		return "gain must be between 0 and 4"
	var pairs: Variant = options.get("glide_pairs", GLIDES)
	if not pairs is Array:
		return "glide_pairs must be an array"
	for pair in pairs:
		if not pair is Array or pair.size() != 2 or not VOWELS.has(pair[0]) or not VOWELS.has(pair[1]):
			return "Invalid vowel glide pair"
	var collections: Array = [plan.word_groups, plan.phones, plan.syllables]
	if plan.has("reference_syllables"):
		if not plan.reference_syllables is Array or plan.reference_syllables.size() != plan.syllables.size():
			return "reference_syllables must match syllables"
		collections.append(plan.reference_syllables)
	for collection in collections:
		var last_end := 0
		for item in collection:
			if not item is Dictionary or not _integer(item.get("start")) or not _integer(item.get("end")):
				return "Every event needs integer start/end frames"
			if item.start < last_end or item.end <= item.start or item.end > plan.frames:
				return "Events must be sorted, nonoverlapping and inside the phrase"
			last_end = int(item.end)
	for phone in plan.phones:
		if phone.get("kind") not in ["vowel", "consonant"]:
			return "Invalid phoneme kind"
		var table: Dictionary = VOWELS if phone.kind == "vowel" else LOCUS
		if not table.has(phone.get("phoneme")):
			return "Unknown phoneme: " + str(phone.get("phoneme"))
		if not _valid_midi(phone.get("midi"), options):
			return "Invalid phoneme MIDI pitch"
		if not _inside_word(phone.start, phone.end, plan.word_groups):
			return "A phoneme cannot span a written-word boundary"
	for key in ["syllables", "reference_syllables"]:
		for s in plan.get(key, []):
			if not _integer(s.get("vowel")) or s.vowel < s.start or s.vowel >= s.end:
				return "Invalid vowel anchor"
			if not _valid_midi(s.get("midi"), options) or not _number(s.get("gain")) or s.gain <= 0 or s.gain > 2:
				return "Invalid syllable pitch or gain"
			if not _inside_word(s.start, s.end, plan.word_groups):
				return "A syllable cannot span a written-word boundary"
	for i in range(plan.syllables.size()):
		var s: Dictionary = plan.syllables[i]
		var found := false
		for p in plan.phones:
			if p.kind == "vowel" and absf(p.start - s.vowel) <= 1:
				found = true
		if not found:
			return "Syllable vowel anchor does not match a vowel phoneme"
		if plan.has("reference_syllables"):
			for key in ["start", "end", "midi", "gain"]:
				if s[key] != plan.reference_syllables[i][key]:
					return "Reference articulation may move vowel anchors only"
	return ""


static func _valid_midi(value: Variant, options: Dictionary) -> bool:
	return _number(value) and value >= 0 and value <= 127 and value + options.get("transpose", 0) >= 0 and value + options.get("transpose", 0) <= 127


static func _inside_word(a: int, z: int, groups: Array) -> bool:
	for group in groups:
		if group.start <= a and z <= group.end:
			return true
	return false


static func targets(kind: String, symbol: String) -> Array:
	if kind == "vowel":
		var v: Array = VOWELS[symbol].duplicate(true)
		for k in range(5):
			v[2][k] += [0,6,4,1,0][k]
		return v
	if symbol in ["r", "l", "w", "y"]:
		return targets("vowel", {"r":"er", "l":"l", "w":"u", "y":"i"}[symbol])
	if symbol in ["m", "n", "ng"]:
		return [[250,LOCUS[symbol][1],2200,3300,3850],[90,180,250,300,350],[0,-15,-24,-28,-32]]
	return [[LOCUS[symbol][0],LOCUS[symbol][1],2600,3300,3850],[80,100,120,130,150],[0,-9,-12,-16,-20]]


static func _voice_level(p: Dictionary) -> float:
	if p.phoneme in ["p","t","k","s","sh","f","th","h","ch"]:
		return 0.0
	if p.phoneme in ["b","d","g","j"]:
		return 0.12
	if p.phoneme in ["v","z","dh"]:
		return 0.45
	return 1.0 if p.kind == "vowel" or p.phoneme in ["r","l","w","y"] else 0.5


static func _segment(x: Array, frame: int) -> int:
	# Last anchor <= frame, including duplicate anchors (numpy.interp semantics).
	var lo := 0
	var hi := x.size()
	while lo < hi:
		var mid := (lo + hi) / 2
		if x[mid] <= frame:
			lo = mid + 1
		else:
			hi = mid
	return maxi(0, lo - 1)


static func _interpolate(x: Array, y: Array, frame: int) -> float:
	var i := _segment(x, frame)
	if i == x.size() - 1 or frame <= x[0]:
		return float(y[i])
	return lerpf(y[i], y[i+1], float(frame - x[i]) / float(x[i+1] - x[i]))


static func build_controls(plan: Dictionary, options: Dictionary = {}) -> Dictionary:
	var error := validate_plan(plan, options)
	if not error.is_empty():
		return {"error": error}
	var n := int(plan.frames)
	var tract_x: Array = []
	var tract_y: Array = []
	var voice := PackedFloat64Array()
	voice.resize(n)
	for p in plan.phones:
		tract_x.append(int(p.start))
		tract_x.append(maxi(p.start, p.end - mini(roundi(0.012 * SR), (int(p.end) - int(p.start)) / 3)))
		var target := targets(p.kind, p.phoneme)
		tract_y.append(target)
		tract_y.append(target)
		for frame in range(p.start, p.end):
			voice[frame] = _voice_level(p)
	# Smooth each step edge with the same finite Gaussian as Python, without
	# allocating an N x 15 tract matrix or running a convolution per sample.
	var sigma := SR * 0.0015
	var radius := int(4.0 * sigma + 0.5)
	var cdf: Array = []
	var total := 0.0
	for j in range(-radius, radius + 1):
		total += exp(-0.5 * pow(j / sigma, 2.0))
		cdf.append(total)
	for j in range(cdf.size()):
		cdf[j] /= total
	var smooth := voice.duplicate()
	for frame in range(1, n):
		var delta := voice[frame] - voice[frame-1]
		if delta == 0:
			continue
		for j in range(maxi(0, frame-radius), mini(n, frame+radius+1)):
			smooth[j] += delta * (cdf[j-frame+radius] - (1.0 if j >= frame else 0.0))
	var envelope := PackedFloat64Array()
	envelope.resize(n)
	for group in plan.word_groups:
		var size := int(group.end - group.start)
		var attack := mini(roundi(0.006 * SR), size / 2)
		var release := mini(roundi(0.020 * SR), size / 2)
		for j in range(size):
			var level := 1.0
			if j < attack:
				level = float(j) / maxi(1, attack-1)
			if j >= size-release:
				level = float(size-1-j) / maxi(1, release-1)
			envelope[int(group.start)+j] = level
	var syllables: Array = plan.get("reference_syllables", plan.syllables)
	var amp_x: Array = []
	var amp_y: Array = []
	for i in range(syllables.size()):
		var s: Dictionary = syllables[i]
		amp_x.append_array([s.start, s.vowel, s.end])
		amp_y.append_array([s.gain * 0.88, s.gain, s.gain * 0.82])
	var midi := PackedFloat64Array()
	midi.resize(n)
	midi.fill(float(syllables[0].midi))
	for i in range(syllables.size()):
		var end := int(syllables[i+1].vowel) if i+1 < syllables.size() else n
		for frame in range(syllables[i].vowel, end):
			midi[frame] = float(syllables[i].midi)
	for i in range(1, syllables.size()):
		var a := int(syllables[i].vowel)
		var length := mini(roundi(0.012 * SR), a)
		for j in range(length):
			midi[a-length+j] = lerpf(syllables[i-1].midi, syllables[i].midi, float(j)/maxi(1,length-1))
	for frame in range(n):
		midi[frame] += options.get("transpose", 0.0)
		envelope[frame] *= _interpolate(amp_x, amp_y, frame)
	var glides: Array = []
	for i in range(plan.phones.size()-1):
		var left: Dictionary = plan.phones[i]
		var right: Dictionary = plan.phones[i+1]
		if left.kind != "vowel" or right.kind != "vowel" or absf(left.end-right.start) > 1:
			continue
		if [left.phoneme,right.phoneme] not in options.get("glide_pairs", GLIDES):
			continue
		if not _inside_word(left.start, right.end, plan.word_groups):
			return {"error": "A vowel glide cannot cross a written-word boundary"}
		glides.append({"start": left.start, "end": right.end-mini(roundi(0.012*SR), (int(right.end)-int(right.start))/3),
			"from": targets("vowel", left.phoneme), "to": targets("vowel", right.phoneme)})
	return {"tract_x":tract_x, "tract_y":tract_y, "glides":glides,
		"midi":midi, "voicing":smooth, "amplitude":envelope,
		"formant_ratio": options.get("formant_ratio", 1.0)}


static func tract_at(c: Dictionary, frame: int) -> Array:
	var index := _segment(c.tract_x, frame)
	var a: Array = c.tract_y[index]
	var b: Array = a
	var blend := 0.0
	if index + 1 < c.tract_x.size() and frame > c.tract_x[0]:
		b = c.tract_y[index+1]
		blend = float(frame-c.tract_x[index]) / float(c.tract_x[index+1]-c.tract_x[index])
	for g in c.glides:
		if g.start <= frame and frame < g.end:
			a = g.from
			b = g.to
			var phase := float(frame-g.start) / maxi(1, int(g.end-g.start)-1)
			blend = 0.5 - 0.5 * cos(PI * clampf((phase-0.30)/0.58, 0, 1))
	var result: Array = [[],[],[]]
	for row in range(3):
		for k in range(5):
			result[row].append(lerpf(a[row][k], b[row][k], blend) * (float(c.formant_ratio) if row < 2 else 1.0))
	return result


static func _coeff(hz: float, q: float, kind: String = "bp") -> Array:
	var omega := TAU * clampf(hz, 20, SR * 0.45) / SR
	var cs := cos(omega)
	var alpha := sin(omega) / (2 * q)
	var b: Array = [alpha, 0.0, -alpha]
	if kind == "hp":
		b = [(1+cs)/2, -1-cs, (1+cs)/2]
	elif kind == "lp":
		b = [(1-cs)/2, 1-cs, (1-cs)/2]
	return [b[0]/(1+alpha), b[1]/(1+alpha), b[2]/(1+alpha), -2*cs/(1+alpha), (1-alpha)/(1+alpha)]


static func _filter(x: float, c: Array, state: Array) -> float:
	var y: float = c[0]*x + state[0]
	state[0] = c[1]*x - c[3]*y + state[1]
	state[1] = c[2]*x - c[4]*y
	return y


static func _noise(state: Array) -> float:
	# Local Park-Miller sequence: reproducible, no changes to the game's RNG.
	state[0] = (int(state[0]) * 16807) % 2147483647
	return float(state[0]) / 1073741823.5 - 1.0


static func _fricative(symbol: String, frames: int, hz: float, rng: Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	out.resize(frames)
	var center: float = FRICATIVE[symbol]
	var sib := symbol in ["s","z","sh"]
	var voiced := symbol in ["z","v"]
	var q := (2.4 if sib else 1.5) if voiced else (1.8 if sib else 0.8)
	var bp := _coeff(center, q)
	var hp := _coeff(center * 0.55, sqrt(0.5), "hp")
	var states: Array = [[0.0,0.0],[0.0,0.0],[0.0,0.0]]
	for i in range(frames):
		var x := _noise(rng)
		if sib:
			x = _filter(x, hp, states[0])
		x = _filter(x, bp, states[1])
		if sib:
			x = 2.2 * _filter(x, bp, states[2])
		if voiced:
			var carrier := sin(TAU * hz * i / SR)
			x = x * (0.45 + 0.55 * 0.5 * (1+carrier)) + carrier*0.18
		out[i] = x * sin(PI * i / maxi(1, frames-1)) * 0.3 * (0.30 if symbol == "dh" else 0.8)
	return out


static func consonant(symbol: String, frames: int, hz: float, seed_value: int = 7241) -> PackedFloat64Array:
	var rng: Array = [posmod(seed_value, 2147483646) + 1]
	return _consonant(symbol, frames, hz, rng)


static func _consonant(symbol: String, frames: int, hz: float, rng: Array) -> PackedFloat64Array:
	var out := PackedFloat64Array()
	if frames <= 0:
		return out
	out.resize(frames)
	if FRICATIVE.has(symbol):
		out = _fricative(symbol, frames, hz, rng)
	elif STOPS.has(symbol) or symbol in ["ch", "j"]:
		var stop: String = {"ch":"t", "j":"d"}.get(symbol, symbol)
		var center: float = STOPS[stop][0]
		var closure := mini(roundi(0.018 * SR), frames / 3) if symbol == "t" else 0
		var count := mini(roundi(0.012 * SR), frames-closure)
		var c := _coeff(center, 2.0)
		var state: Array = [0.0,0.0]
		# Native 12 ms burst, rather than SciPy's 40 -> 12 ms resampling.
		for i in range(count):
			var phase := float(i) / maxi(1, count-1)
			var env := minf(1.0, minf(phase/0.2, (1-phase)/0.2))
			out[closure+i] = (_filter(_noise(rng), c, state) + 0.1*sin(TAU*center*i/SR)) * float(STOPS[stop][1]) * env * 0.3 * 0.8
		var start := closure + count
		if symbol in ["ch", "j"] and start < frames:
			var tail := _fricative("sh" if symbol == "ch" else "z", frames-start, hz, rng)
			for i in range(tail.size()):
				out[start+i] = tail[i]
		elif stop in ["p","t","k"]:
			c = _coeff(1800, sqrt(0.5), "hp")
			state = [0.0,0.0]
			for i in range(mini(frames-start, roundi(0.05*SR))):
				out[start+i] = _filter(_noise(rng), c, state) * exp(-i/(0.025*SR)) * 0.55 * 0.3 * 0.6
	var fade := mini(roundi(0.004*SR), frames/2)
	for i in range(fade):
		out[i] *= float(i)/maxi(1, fade-1)
		out[frames-1-i] *= float(i)/maxi(1, fade-1)
	return out


static func render_phrase(plan: Dictionary, options: Dictionary = {}) -> PackedFloat32Array:
	var c := build_controls(plan, options)
	if c.has("error"):
		push_error(c.error)
		return PackedFloat32Array()
	var n := int(plan.frames)
	var noise := PackedFloat64Array()
	noise.resize(n)
	var rng: Array = [posmod(int(options.get("seed",7241)), 2147483646)+1]
	for p in plan.phones:
		if p.kind == "consonant":
			var hz := 440.0 * pow(2, (float(p.midi)+options.get("transpose",0.0)-69)/12)
			var part := _consonant(p.phoneme, p.end-p.start, hz, rng)
			for i in range(part.size()):
				noise[int(p.start)+i] += part[i]
	var out := PackedFloat32Array()
	out.resize(n)
	var phase := 0.0
	var source_state := 0.0
	var warped := tan(PI * 1800.0 / SR)
	var source_b := warped/(1+warped)
	var source_a := (warped-1)/(warped+1)
	var states: Array = []
	for k in range(5):
		states.append([0.0,0.0])
	var coeffs: Array = []
	var gains: Array = []
	var highpass := _coeff(85, sqrt(0.5), "hp")
	var lowpass := _coeff(9000, sqrt(0.5), "lp")
	var hp_state: Array = [0.0,0.0]
	var lp_state: Array = [0.0,0.0]
	for i in range(n):
		if i % BLOCK == 0:
			var tract := tract_at(c, i)
			coeffs.clear()
			gains.clear()
			for k in range(5):
				var f: float = tract[0][k]
				coeffs.append(_coeff(f, minf(10, f/maxf(70, tract[1][k]))))
				gains.append(pow(10, float(tract[2][k])/20))
		var step := 440.0 * pow(2, (c.midi[i]-69)/12) / SR
		phase = fposmod(phase + step, 1.0)
		var blep := 0.0
		if phase < step:
			var u := phase / step
			blep = 2*u - u*u - 1
		elif phase > 1-step:
			var u := (phase-1) / step
			blep = u*u + 2*u + 1
		var saw := (2*phase-1-blep)*0.5
		var soft := source_b*saw + source_state
		source_state = source_b*saw - source_a*soft
		var source: float = (0.28*saw + 0.72*soft)*c.voicing[i]
		var voiced := 0.0
		for k in range(5):
			voiced += _filter(source, coeffs[k], states[k]) * float(gains[k])
		var signal_value: float = (voiced*8.0*0.65 + noise[i]*0.7)*c.amplitude[i]
		signal_value = _filter(_filter(signal_value, highpass, hp_state), lowpass, lp_state)
		var fade := minf(1, float(mini(i,n-1-i))/roundi(0.005*SR))
		# Word gates remain exact even while filter state decays through a rest.
		if c.amplitude[i] == 0:
			signal_value = 0
		out[i] = clampf(signal_value * fade * options.get("gain",DEFAULT_GAIN), -1, 1)
	return out
