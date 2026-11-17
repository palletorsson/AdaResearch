extends RefCounted
## Recorded turbulence only. Singing voicing, vowels and pitch remain procedural.
## See voice_samples/lj_consonants/manifest.json for source clips and boundaries.
## Construct per render: no shared mutable decoder/cache across worker threads.
const ROOT := "res://audio/voice_samples/lj_consonants/"
const VERSION := "lj-consonants-1"
const Tuning := preload("res://audio/generators/PhonemeArticulation.gd")
const COVERED := ["p", "b", "t", "d", "k", "g", "f", "v", "th", "dh", "s", "z", "sh", "zh", "h", "ch", "j"]
var samples := {}
var rows := {}
var mix := 0.75


func _init(amount := 0.75) -> void:
	mix = clampf(amount, 0.0, 1.0)
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(ROOT + "manifest.json"))
	if not parsed is Dictionary:
		push_warning("LJ consonant manifest missing; using synthesis.")
		return
	rows = parsed.get("samples", {})
	for code: String in COVERED:
		if not rows.has(code): continue
		var path := ROOT + str(rows[code].file)
		# Exports contain imported .sample resources, not necessarily raw WAVs.
		# Source-only desktop runs still read the original PCM directly.
		var wav: AudioStreamWAV
		if ResourceLoader.exists(path):
			wav = load(path) as AudioStreamWAV
		else:
			wav = AudioStreamWAV.load_from_file(path)
		if wav == null or wav.format != AudioStreamWAV.FORMAT_16_BITS or wav.stereo or wav.mix_rate != 44100:
			push_warning("LJ consonant unavailable: " + code)
			continue
		var pcm := PackedFloat64Array()
		var bytes := wav.data
		pcm.resize(bytes.size() / 2)
		for i in pcm.size(): pcm[i] = bytes.decode_s16(i * 2) / 32768.0
		samples[code] = pcm


func blend(code: String, synthetic: PackedFloat64Array) -> PackedFloat64Array:
	if mix <= 0.0 or not samples.has(code) or synthetic.size() < 16:
		return synthetic
	var source: PackedFloat64Array = samples[code]
	var n := synthetic.size()
	var recorded := PackedFloat64Array()
	recorded.resize(n)
	var kind := str(rows[code].kind)
	if kind == "stop":
		# Preserve the burst at native speed. Stretch the closure, not its pitch.
		var peak_frame := int(rows[code].burst_frame)
		var first := maxi(0, peak_frame - 220)
		var at := roundi(n * float(Tuning.STOPS[code][3]))
		for i in mini(source.size() - first, n - at):
			recorded[at + i] = source[first + i]
	else:
		var at := roundi(n * float(Tuning.STOPS[code][3])) if kind == "affricate" else 0
		# Overlap-add unpitched grains at unchanged sample rate. Stretch duration
		# without lowering the consonant's spectrum when singing is slowed down.
		var grain := mini(1764, source.size())
		var hop := maxi(1, grain / 2)
		var weights := PackedFloat64Array()
		weights.resize(n)
		var grain_index := 0
		for start in range(at - hop, n, hop):
			var offset := (grain_index * 997) % maxi(1, source.size() - grain + 1)
			for j in grain:
				var dest := start + j
				if dest < at or dest >= n: continue
				var window := 0.5 - 0.5 * cos(TAU * float(j) / maxi(1, grain - 1))
				recorded[dest] += source[offset + j] * window
				weights[dest] += window
			grain_index += 1
		for i in range(at, n):
			if weights[i] > 0.0001: recorded[i] /= weights[i]
	# All joins are bounded by the scored consonant: never overwrite a vowel.
	var edge := mini(220, n / 4)
	var old_energy := 0.0
	var energy := 0.0
	var old_peak := 0.0
	var peak := 0.0
	for i in n:
		recorded[i] *= minf(1.0, float(mini(i, n - 1 - i)) / edge)
		energy += recorded[i] * recorded[i]
		old_energy += synthetic[i] * synthetic[i]
		peak = maxf(peak, absf(recorded[i]))
		old_peak = maxf(old_peak, absf(synthetic[i]))
	if energy < 0.00000001 or old_energy < 0.00000001: return synthetic
	var level := minf(sqrt(old_energy / energy), old_peak * 1.5 / maxf(peak, 0.000001))
	for i in n: recorded[i] = lerpf(synthetic[i], recorded[i] * level, mix)
	return recorded
