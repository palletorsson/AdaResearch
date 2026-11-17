extends RefCounted
## Desktop pilot. The reference vowels use formants measured from Airway postures.
## Default individual tuning adjusts those targets and supplies phone-specific
## consonants. individual_tuning=false retains the measured-pilot sound for A/B.
## Model B supplies the fold excitation, singing expression and upper resonators.

const ModelB := preload("res://audio/generators/ModelBVoice.gd")
const Robot := preload("res://audio/generators/RobotVoiceGenerator.gd")
const Articulation := preload("res://audio/generators/PhonemeArticulation.gd")
const Recorded := preload("res://audio/generators/LJConsonants.gd")
const LIBRARY := "res://audio/airway/data/phoneme_tracts.json"
# The score format predates the IPA library. Lateral l is kept in the consonant model.
const IPA := {"a": "a", "i": "i", "u": "u", "e": "e", "o": "o", "uh": "ə", "y": "y",
	"eu": "ø", "ae": "æ", "oe": "œ", "r": "ɝ", "ih": "ɪ", "er": "ɝ", "aw": "ɔ", "ah": "ʌ"}
const CONSONANT_IPA := {"th": "θ", "dh": "ð", "sh": "ʃ", "zh": "ʒ", "ch": "tʃ", "j": "dʒ", "ng": "ŋ", "y": "j", "r": "ɹ"}


static func display_symbol(kind: String, symbol: String) -> String:
	if kind == "vowel":
		return str(IPA.get(symbol, "l̩" if symbol == "l" else symbol))
	return str(CONSONANT_IPA.get(symbol, symbol))


static func _library() -> Dictionary:
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(LIBRARY))
	if parsed is Dictionary and parsed.get("vowels") is Dictionary:
		return parsed.vowels
	return {}


static func validate_plan(plan: Dictionary, options: Dictionary = {}) -> String:
	if not options.get("individual_tuning", true) is bool:
		return "individual_tuning must be true or false"
	var recorded: Variant = options.get("recorded_consonants", 0.0)
	if not (recorded is float or recorded is int) or not is_finite(float(recorded)) or float(recorded) < 0.0 or float(recorded) > 1.0:
		return "recorded_consonants must be between 0 and 1"
	var speed: Variant = options.get("speed", 1.0)
	if not (speed is float or speed is int):
		return "speed must be a number between 0.25 and 1.0"
	if not is_finite(float(speed)) or float(speed) < 0.25 or float(speed) > 1.0:
		return "speed must be between 0.25 and 1.0"
	var settings := options.duplicate()
	settings.erase("speed")
	settings.erase("individual_tuning")
	settings.erase("recorded_consonants")
	var problem := ModelB.validate_plan(plan, settings)
	if not problem.is_empty():
		return problem
	problem = ModelB.validate_plan(timed_plan(plan, float(speed)), settings)
	if not problem.is_empty():
		return problem
	var library := _library()
	for ipa in IPA.values():
		if not library.has(ipa):
			return "The measured vowel library is missing " + str(ipa)
	return ""


## Stretch the score's time coordinates while retaining every note and phoneme.
## The timeline and renderer both use this plan. A normal-speed call keeps the original.
static func timed_plan(plan: Dictionary, speed: float) -> Dictionary:
	if speed == 1.0:
		return plan
	var stretched := plan.duplicate(true)
	for key in ["frames", "offset"]:
		if stretched.has(key):
			stretched[key] = roundi(float(stretched[key]) / speed)
	for collection in ["phones", "syllables", "reference_syllables", "word_groups"]:
		for event: Dictionary in stretched.get(collection, []):
			for key in ["start", "end", "vowel"]:
				if event.has(key):
					event[key] = roundi(float(event[key]) / speed)
	# Scale the short transitions between adjacent phonemes as well as the holds.
	stretched["timing_scale"] = float(plan.get("timing_scale", 1.0)) / speed
	return stretched


static func vowel_tracts(tuned := true) -> Dictionary:
	var library := _library()
	var tracts := {}
	for symbol in IPA:
		var row: Variant = library.get(IPA[symbol])
		if row == null:
			push_error("The measured vowel library is missing " + str(IPA[symbol]))
			return {}
		var target := Robot.targets("vowel", symbol)
		for part in 2:
			for band in 3:
				target[part][band] = row[part][band]
		# Continue the cascade above the third measured resonance.
		target[0][3] = maxf(4300.0, float(target[0][2]) + 500.0)
		target[0][4] = 5500.0
		tracts[symbol] = target
	return Articulation.tracts(tracts) if tuned else tracts


static func render_phrase(plan: Dictionary, options: Dictionary = {}) -> PackedFloat32Array:
	var problem := validate_plan(plan, options)
	if not problem.is_empty():
		push_error(problem)
		return PackedFloat32Array()
	var tuned := bool(options.get("individual_tuning", true))
	var tracts := vowel_tracts(tuned)
	if tracts.is_empty():
		return PackedFloat32Array()
	var settings := {"formant_ratio": 1.0, "f2_lift": 0.0}
	settings.merge(options, true)
	settings.erase("speed")
	settings.erase("individual_tuning")
	settings.erase("recorded_consonants")
	var amount := float(options.get("recorded_consonants", 0.0))
	var recorded := Recorded.new(amount) if amount > 0.0 else null
	return ModelB.render_phrase(timed_plan(plan, float(options.get("speed", 1.0))), settings, tracts, Articulation if tuned else null, recorded)
