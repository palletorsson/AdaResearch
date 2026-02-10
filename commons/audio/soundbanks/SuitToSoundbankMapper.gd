# SuitToSoundbankMapper.gd
# Bridges genre synth suites (GenreSynthBrowser) to soundbank-ready runtime payloads.

class_name SuitToSoundbankMapper
extends RefCounted

const GENRE_BROWSER_PATH := "res://commons/audio/catalog/GenreSynthBrowser.gd"

const FALLBACK_GENRE_SUITES := {
	"detroit_techno": {
		"rhythm": ["tr909_kick", "tr909_hihat", "tr909_clap"],
		"bass": ["detroit_bass"],
		"harmony": ["detroit_strings"],
		"hook": ["detroit_stab", "arp_sequence"],
		"fx": ["noise_riser", "noise_fall", "impact_hit"]
	}
}

const ELEMENT_TO_SOUND := {
	# Drum aliases
	"tr909_kick": "kick",
	"tr808_kick": "kick",
	"linn_kick": "kick",
	"four_floor_kick": "kick",
	"tr909_snare": "snare",
	"gated_snare": "snare",
	"tr808_snare": "snare",
	"tr909_clap": "clap",
	"house_clap": "clap",
	"tr909_hihat": "hihat",
	"tr808_hihat": "hihat",
	"disco_hihat": "hihat",
	"ukg_shuff_hat": "hihat",
	"trap_hihat": "hihat",
	"amen_break": "break",
	"lofi_break": "break",
	"bitcrush_drums": "break",
	# Bass aliases
	"detroit_bass": "bass",
	"synthwave_bass": "bass",
	"house_bass": "bass",
	"disco_bass": "bass",
	"808_bass": "bass",
	"jungle_sub": "sub",
	"dub_sub": "sub",
	"ukg_wobble_bass": "bass",
	"reese_bass": "bass",
	"roller_bass": "bass",
	"moog_bass": "bass",
	"neuro_mid_bass": "bass",
	# Harmony
	"detroit_strings": "pad",
	"warm_pad": "pad",
	"granular_pad": "pad",
	"solina_pad": "pad",
	"trap_pad": "pad",
	"dnb_pad": "pad",
	"mellotron_strings": "pad",
	"house_organ": "organ",
	"house_piano": "piano",
	"dub_chord": "pad",
	# Hook
	"detroit_stab": "stab",
	"rave_stab": "stab",
	"jungle_stab": "stab",
	"ukg_organ_stab": "stab",
	"dub_echo_stab": "stab",
	"neuro_stab": "stab",
	"arp_sequence": "sequence",
	"arp_synth": "arp",
	"synthwave_lead": "lead",
	"acid_lead": "lead",
	"minimoog_lead": "lead",
	"ukg_pluck": "lead",
	"ukg_vocal_chop": "vocal",
	"trap_bell": "lead",
	"trancer": "lead",
	"neuro_laser": "lead",
	# FX
	"noise_riser": "sweep_up",
	"noise_fall": "sweep_down",
	"impact_hit": "impact",
	"tape_delay": "fx_delay",
	"sp1200_crunch": "fx_crunch"
}

const DEFAULT_PATTERNS := {
	"kick": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],
	"snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
	"clap": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
	"hihat": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],
	"break": [1,0,1,0, 0,1,0,0, 1,0,0,1, 0,0,1,0],
	"bass": [1,0,0,0, 0,0,1,0, 1,0,0,0, 0,0,1,0],
	"sub": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
	"pad": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
	"organ": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
	"piano": [0,0,1,0, 0,0,0,1, 0,0,1,0, 0,0,0,1],
	"stab": [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],
	"sequence": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
	"arp": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
	"lead": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
	"vocal": [0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
	"sweep_up": [0,0,0,0, 0,0,0,0, 0,0,0,0, 0,0,0,1],
	"sweep_down": [0,0,0,1, 0,0,0,0, 0,0,0,1, 0,0,0,0],
	"impact": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0]
}

static func list_genre_ids() -> Array:
	var constants := _get_browser_constants()
	var suites: Dictionary = constants.get("GENRE_SUITES", {})
	var ids: Array = suites.keys()
	for fallback_id in FALLBACK_GENRE_SUITES.keys():
		_append_unique(ids, fallback_id)
	return ids


static func get_genre_suite(genre_id: String) -> Dictionary:
	var constants := _get_browser_constants()
	var suites: Dictionary = constants.get("GENRE_SUITES", {})
	if suites.has(genre_id):
		return suites[genre_id].duplicate(true)
	if FALLBACK_GENRE_SUITES.has(genre_id):
		return FALLBACK_GENRE_SUITES[genre_id].duplicate(true)
	return {}


static func to_soundbank_layout(genre_id: String, soundbank_id: String = "") -> Dictionary:
	var suite := get_genre_suite(genre_id)
	if suite.is_empty():
		return {}

	var resolved_bank := soundbank_id if not soundbank_id.is_empty() else genre_id
	var bank := SoundbankLoader.load_genre(resolved_bank)
	if bank == null:
		return {}

	var available: Array = bank.get_available_sounds()
	var role_mappings := {}
	var mapped_sounds: Array = []
	var missing: Array = []

	for role in suite.keys():
		var role_elements: Array = suite.get(role, [])
		var mapped_role: Array = []
		for element_id_variant in role_elements:
			var element_id := str(element_id_variant)
			var mapped_sound := element_to_sound_name(element_id)
			if mapped_sound.is_empty():
				missing.append({
					"role": role,
					"element_id": element_id,
					"reason": "no_mapping"
				})
				continue
			if mapped_sound not in available:
				missing.append({
					"role": role,
					"element_id": element_id,
					"sound_name": mapped_sound,
					"reason": "not_in_soundbank"
				})
				continue

			_append_unique(mapped_role, mapped_sound)
			_append_unique(mapped_sounds, mapped_sound)
		role_mappings[role] = mapped_role

	return {
		"genre_id": genre_id,
		"soundbank_id": resolved_bank,
		"roles": role_mappings,
		"mapped_sounds": mapped_sounds,
		"missing": missing,
		"available_sounds": available,
		"sections": _build_sections(role_mappings)
	}


static func build_runtime_suite(genre_id: String, suite_id: String = "", soundbank_id: String = "") -> Dictionary:
	var layout := to_soundbank_layout(genre_id, soundbank_id)
	if layout.is_empty():
		return {}

	var mapped_sounds: Array = layout.get("mapped_sounds", [])
	if mapped_sounds.is_empty():
		return {}

	var resolved_suite_id := suite_id if not suite_id.is_empty() else genre_id
	var resolved_bank: String = layout.get("soundbank_id", genre_id)

	var bank := SoundbankLoader.load_genre(resolved_bank)
	var bpm := 120.0
	if bank != null:
		bpm = bank.get_bpm()

	var sounds := {}
	for sound_name_variant in mapped_sounds:
		var sound_name := str(sound_name_variant)
		sounds[sound_name] = {
			"generator": "soundbank_script",
			"soundbank_id": resolved_bank,
			"sound_name": sound_name,
			"default_params": _default_params_for(sound_name)
		}

	return {
		"id": resolved_suite_id,
		"source_genre": genre_id,
		"soundbank_id": resolved_bank,
		"bpm": bpm,
		"sounds": sounds,
		"patterns": {
			"main": _build_pattern(mapped_sounds, false),
			"sparse": _build_pattern(mapped_sounds, true)
		},
		"default_pattern": "main",
		"sections": layout.get("sections", {}),
		"mapping": layout
	}


static func element_to_sound_name(element_id: String) -> String:
	var normalized := element_id.to_lower().strip_edges()
	if ELEMENT_TO_SOUND.has(normalized):
		return ELEMENT_TO_SOUND[normalized]

	if normalized.ends_with("_kick"):
		return "kick"
	if normalized.ends_with("_snare"):
		return "snare"
	if normalized.ends_with("_clap"):
		return "clap"
	if normalized.ends_with("_hihat") or normalized.ends_with("_hat"):
		return "hihat"
	if normalized.ends_with("_bass") or normalized.ends_with("_sub"):
		return "bass"
	if normalized.ends_with("_pad") or normalized.ends_with("_strings"):
		return "pad"
	if normalized.ends_with("_stab"):
		return "stab"
	if normalized.ends_with("_arp") or normalized.ends_with("_sequence"):
		return "sequence"
	if normalized.ends_with("_lead"):
		return "lead"
	if normalized.contains("riser"):
		return "sweep_up"
	if normalized.contains("fall"):
		return "sweep_down"
	if normalized.contains("impact"):
		return "impact"

	return ""


static func _build_sections(role_mappings: Dictionary) -> Dictionary:
	var rhythm: Array = role_mappings.get("rhythm", [])
	var bass: Array = role_mappings.get("bass", [])
	var harmony: Array = role_mappings.get("harmony", [])
	var hook: Array = role_mappings.get("hook", [])
	var fx: Array = role_mappings.get("fx", [])

	var intro: Array = []
	_append_many_unique(intro, harmony)
	_append_many_unique(intro, fx)
	if intro.is_empty():
		_append_many_unique(intro, rhythm)

	var build: Array = []
	_append_many_unique(build, rhythm)
	_append_many_unique(build, bass)
	_append_many_unique(build, hook)

	var main: Array = []
	_append_many_unique(main, rhythm)
	_append_many_unique(main, bass)
	_append_many_unique(main, harmony)
	_append_many_unique(main, hook)
	_append_many_unique(main, fx)

	var breakdown: Array = []
	_append_many_unique(breakdown, harmony)
	_append_many_unique(breakdown, hook)
	_append_many_unique(breakdown, fx)
	if breakdown.is_empty():
		_append_many_unique(breakdown, bass)

	var outro: Array = []
	_append_many_unique(outro, harmony)
	_append_many_unique(outro, fx)
	if outro.is_empty():
		_append_many_unique(outro, rhythm)

	return {
		"intro": intro,
		"build": build,
		"main": main,
		"breakdown": breakdown,
		"outro": outro
	}


static func _build_pattern(sound_names: Array, sparse: bool) -> Dictionary:
	var pattern := {"length": 16}
	for sound_name_variant in sound_names:
		var sound_name := str(sound_name_variant)
		var base: Array = DEFAULT_PATTERNS.get(sound_name, DEFAULT_PATTERNS.get("lead", [])).duplicate()
		if sparse:
			base = _sparsify(base)
		pattern[sound_name] = base
	return pattern


static func _sparsify(values: Array) -> Array:
	var out: Array = []
	out.resize(values.size())
	for i in range(values.size()):
		var v: float = float(values[i])
		if i % 2 == 1:
			v = 0.0
		elif i > 0 and i % 8 == 0:
			v *= 0.5
		out[i] = v
	return out


static func _default_params_for(sound_name: String) -> Dictionary:
	match sound_name:
		"kick", "snare", "clap", "hihat", "impact", "sweep_up", "sweep_down", "break":
			return {"duration": 0.35, "gain": 1.0}
		"bass", "sub":
			return {"duration": 0.5, "gain": 1.0, "frequency_hz": 55.0}
		"pad", "organ", "piano":
			return {"duration": 0.8, "gain": 0.9, "frequency_hz": 220.0}
		"stab":
			return {"duration": 0.4, "gain": 1.0, "frequency_hz": 220.0}
		"sequence", "arp", "lead", "vocal":
			return {"duration": 0.25, "gain": 1.0, "frequency_hz": 220.0}
		_:
			return {"duration": 0.3, "gain": 1.0}


static func _append_unique(target: Array, value) -> void:
	if value not in target:
		target.append(value)


static func _append_many_unique(target: Array, values: Array) -> void:
	for value in values:
		_append_unique(target, value)


static func _get_browser_constants() -> Dictionary:
	if not ResourceLoader.exists(GENRE_BROWSER_PATH):
		return {}

	var script = load(GENRE_BROWSER_PATH)
	if script == null:
		return {}
	if not script.has_method("get_script_constant_map"):
		return {}

	return script.get_script_constant_map()
