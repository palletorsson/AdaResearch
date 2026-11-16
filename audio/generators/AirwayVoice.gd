extends RefCounted
## Model B's voice as a body: the score's words are looked up, split into syllables, planned as gestures
## (audio/airway/phonetics.gd) and sung by lungs, folds, a throat and a mouth made of air
## (audio/airway/airway_voice.gd). All of it is GDScript; it is the kit's physical voice, ported, with the
## settings of the voice that was approved. It is slow: see `oversample`.
##
## The sound starts LEAD seconds before the phrase's first frame (the first consonants are sung before
## their vowel's beat) and goes on half a second past its last.
##
## Options (all optional): body, pressure, breathiness, tension, brightness, roughness, fry, drift_cents,
## glide_s, vibrato_depth_cents, vibrato_rate, voiced; transpose (semitones); level (the phrase's peak is brought to
## this, 0 leaves the sound as radiated), gain (after that);
## oversample (0: the engine's own, 2 at 44.1 kHz; 1: half the steps and coarser sections, about four
## times faster, the top of the spectrum less exact), min_sections.

const Voice := preload("res://audio/airway/airway_voice.gd")
const Phonetics := preload("res://audio/airway/phonetics.gd")
const WORDS := "res://audio/voice_scores/pronunciations.json"
const RATE := 44100
const LEAD := 0.25
## The voice that was approved (the kit's preset).
const DEFAULTS := {"body": "female", "voiced": true, "pressure": 7.0, "breathiness": 0.18, "tension": 0.28, "brightness": 0.12, "roughness": 0.01,
	"fry": 0.0, "drift_cents": 2.0, "glide_s": 0.05, "vibrato_depth_cents": 12.0, "vibrato_rate": 5.3, "transpose": 0.0, "gain": 1.0, "level": 0.5,
	"oversample": 0, "min_sections": 8}

static var _words := {}
static var _words_read := false
static var _lock := Mutex.new()


static func words() -> Dictionary:
	if _words_read: return _words
	_lock.lock()
	if not _words_read:
		var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(WORDS)) if FileAccess.file_exists(WORDS) else null
		if parsed is Dictionary: _words = parsed.get("words", {})
		_words_read = true
	_lock.unlock()
	return _words


static func _settings(options: Dictionary) -> Dictionary:
	var o := DEFAULTS.duplicate()
	for key in options:
		if DEFAULTS.has(key) and options[key] != null: o[key] = options[key]
	return o


static func _plan(plan: Dictionary, o: Dictionary) -> Dictionary:
	var shifted := plan
	if float(o.transpose) != 0.0:
		shifted = plan.duplicate(true)
		for syllable in shifted.syllables: syllable["midi"] = float(syllable.midi) + float(o.transpose)
	return Phonetics.plan_score_phrase(shifted, words(), str(o.body), float(o.vibrato_depth_cents) if bool(o.voiced) else 0.0, float(RATE))


## Empty when the phrase can be sung, else why not.
static func validate_plan(plan: Dictionary, options: Dictionary = {}) -> String:
	for key in ["frames", "syllables"]:
		if not plan.has(key): return "the plan has no " + key
	var o := _settings(options)
	if not ["male", "female", "child"].has(str(o.body)): return "body must be male, female or child"
	return str(_plan(plan, o).get("error", ""))


## The phrase as samples at 44.1 kHz, mono; empty if it cannot be sung.
static func render_phrase(plan: Dictionary, options: Dictionary = {}) -> PackedFloat32Array:
	var o := _settings(options)
	var planned := _plan(plan, o)
	var out := PackedFloat32Array()
	if planned.has("error"): return out
	var voice := Voice.new(float(RATE), str(o.body), int(o.oversample), int(o.min_sections))
	# the note gestures bring vibrato to held vowels only; short notes and consonants start straight
	voice.set_source({"f0": float(planned.f0), "voiced": bool(o.voiced), "pressure": float(o.pressure), "breathiness": float(o.breathiness),
		"tension": float(o.tension), "brightness": float(o.brightness), "roughness": float(o.roughness), "fry": float(o.fry), "drift": float(o.drift_cents),
		"glide": float(o.glide_s), "vibratoRate": float(o.vibrato_rate), "vibratoDepth": 0.0})
	voice.schedule(planned.gestures, 0.0)
	out.resize((RATE >> 2) + int(plan.frames) + (RATE >> 1))
	voice.render(out, 0, out.size())
	var gain := float(o.gain)
	if float(o.level) > 0.0:
		var peak := 0.0
		for i in out.size(): peak = maxf(peak, absf(out[i]))
		if peak > 0.0: gain *= float(o.level) / peak
	if gain != 1.0:
		for i in out.size(): out[i] *= gain
	return out
