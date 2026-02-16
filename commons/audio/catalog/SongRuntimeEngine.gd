extends RefCounted
class_name SongRuntimeEngine

const LayerRenderer = preload("res://commons/audio/catalog/LayerRenderer.gd")

var _last_error: String = ""


func preview_step(song_state_snapshot: Dictionary, track_state: Dictionary, step_context: Dictionary = {}) -> AudioStream:
	var params: Dictionary = _build_preview_params(song_state_snapshot, track_state, step_context, true)
	return _render_preview(song_state_snapshot, track_state, params)


func preview_layer(song_state_snapshot: Dictionary, track_state: Dictionary, layer_params: Dictionary = {}) -> AudioStream:
	var params: Dictionary = _build_preview_params(song_state_snapshot, track_state, layer_params, false)
	return _render_preview(song_state_snapshot, track_state, params)


func render_realtime(song_state_snapshot: Dictionary, options: Dictionary = {}) -> AudioStream:
	_last_error = ""
	var song_id: String = str(song_state_snapshot.get("song_id", ""))
	if song_id.is_empty():
		_last_error = "missing_song_id"
		return null

	var generation_params: Dictionary = {}
	var generation_params_variant: Variant = options.get("generation_params", {})
	if generation_params_variant is Dictionary:
		generation_params = (generation_params_variant as Dictionary).duplicate(true)
	if not generation_params.has("song_id"):
		generation_params["song_id"] = song_id

	var reference_mix_mode: bool = bool(options.get("reference_mix_mode", false))
	if reference_mix_mode:
		var reference_stream: AudioStream = _generate_preview_reference_stream(song_id)
		if reference_stream != null:
			return reference_stream

	var stream: AudioStream = _generate_song_stream(song_id, generation_params)
	if stream == null and _last_error.is_empty():
		_last_error = "generation_failed"
	return stream


func render_offline(song_state_snapshot: Dictionary, quality_mode: String = "draft", options: Dictionary = {}) -> AudioStream:
	var merged_options: Dictionary = options.duplicate(true)
	merged_options["reference_mix_mode"] = false
	var _quality_mode: String = quality_mode
	return render_realtime(song_state_snapshot, merged_options)


func get_last_error() -> String:
	return _last_error


func _render_preview(song_state_snapshot: Dictionary, track_state: Dictionary, params: Dictionary) -> AudioStream:
	var song_id: String = str(song_state_snapshot.get("song_id", ""))
	if song_id.is_empty():
		return null

	var bpm: float = maxf(1.0, float(song_state_snapshot.get("bpm", 120.0)))
	var bars: int = maxi(1, int(params.get("preview_bars", 1)))
	var layer_name: String = _resolve_layer_name(track_state)
	if layer_name.is_empty():
		return null

	return LayerRenderer.render_song_layer_preview(song_id, layer_name, params, bpm, bars)


func _resolve_layer_name(track_state: Dictionary) -> String:
	var layer_name: String = str(track_state.get("layer_name", ""))
	if not layer_name.is_empty():
		return layer_name

	var instrument_id: String = str(track_state.get("instrument_id", ""))
	if not instrument_id.is_empty():
		return instrument_id

	var track_id: String = str(track_state.get("track_id", ""))
	return track_id


func _build_preview_params(song_state_snapshot: Dictionary, track_state: Dictionary, input_params: Dictionary, force_step_preview: bool) -> Dictionary:
	var merged: Dictionary = input_params.duplicate(true)

	if force_step_preview:
		merged["step_preview"] = true
	elif not merged.has("step_preview"):
		merged["step_preview"] = false

	if not merged.has("track_id"):
		merged["track_id"] = str(track_state.get("track_id", ""))
	if not merged.has("instrument_id"):
		merged["instrument_id"] = str(track_state.get("instrument_id", ""))
	if not merged.has("role"):
		merged["role"] = str(track_state.get("role", "generic"))

	var pattern_data_variant: Variant = track_state.get("pattern_data", {})
	if pattern_data_variant is Dictionary:
		var pattern_data: Dictionary = pattern_data_variant as Dictionary
		_copy_if_missing(merged, pattern_data, "pattern")
		_copy_if_missing(merged, pattern_data, "notes")
		_copy_if_missing(merged, pattern_data, "chords")
		_copy_if_missing(merged, pattern_data, "direction")
		_copy_if_missing(merged, pattern_data, "rate")
		_copy_if_missing(merged, pattern_data, "key")
		_copy_if_missing(merged, pattern_data, "scale")

	if not merged.has("pattern"):
		var pattern_variant: Variant = track_state.get("pattern", [])
		if pattern_variant is Array:
			merged["pattern"] = (pattern_variant as Array).duplicate()
	if not merged.has("notes"):
		var notes_variant: Variant = track_state.get("notes", [])
		if notes_variant is Array:
			merged["notes"] = (notes_variant as Array).duplicate()
	if not merged.has("chords"):
		var chords_variant: Variant = track_state.get("chords", [])
		if chords_variant is Array:
			merged["chords"] = (chords_variant as Array).duplicate()

	if not merged.has("key"):
		merged["key"] = str(song_state_snapshot.get("key", "C"))
	if not merged.has("scale"):
		merged["scale"] = str(song_state_snapshot.get("scale", "major"))

	return merged


func _copy_if_missing(target: Dictionary, source: Dictionary, key_name: String) -> void:
	if target.has(key_name):
		return
	if not source.has(key_name):
		return
	var value: Variant = source.get(key_name, null)
	if value is Array:
		target[key_name] = (value as Array).duplicate()
	elif value is Dictionary:
		target[key_name] = (value as Dictionary).duplicate(true)
	else:
		target[key_name] = value


func _generate_preview_reference_stream(song_id: String) -> AudioStream:
	match song_id:
		"chromatic_story":
			return SoundbankGenerator.generate_song("chromatic_story", {"bpm": 100})
		"nineties_rnb":
			return SoundbankGenerator.generate_song("nineties_rnb", {"bpm": 92})
		"computer_love":
			return SoundbankGenerator.generate_song("kraftwerk", {"bpm": 129})
		"aphex_twin", "aphex_twin_digital_amber":
			return SoundbankGenerator.generate_song("aphex_twin", {"bpm": 108})
		"ada_theme":
			return SoundbankGenerator.generate_song("ada_theme", {"bpm": 100})
		"prog_synth_70s":
			return AudioSynthesizer.generate_prog_synth_song({})
		"prog_odyssey":
			return AudioSynthesizer.generate_prog_odyssey_song({})
		"kpop_prog":
			return AudioSynthesizer.generate_kpop_prog_song({})
		"pop_generative":
			return AudioSynthesizer.generate_pop_interactive_song({})
		"ambient_works":
			return AudioSynthesizer.generate_ambient_works_song({})
		"i_feel_love", "moroder_disco":
			return SoundbankGenerator.generate_song("moroder_disco", {"bpm": 126})
		"detroit_techno":
			return AudioSynthesizer.generate_detroit_techno_song({})
		"midnight_metroplex":
			return SoundbankGenerator.generate_song("detroit_techno", {})
		"synthwave":
			return AudioSynthesizer.generate_synthwave_song({})
		"rave":
			return AudioSynthesizer.generate_rave_song({})
		"replicants_dawn":
			return SoundbankGenerator.generate_hybrid_song("replicants_dawn", {})
		"foggy_frequencies":
			return SoundbankGenerator.generate_hybrid_song("foggy_frequencies", {})
		"chicago_dusseldorf":
			return SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", {})
		"dub_house_sb", "dub_house":
			return SoundbankGenerator.generate_song("dub_house", {"bpm": 122})
		"k_bass":
			return SoundbankGenerator.generate_song("k_bass", {"bpm": 170})
		"dark_wave_cathedral":
			return SoundbankGenerator.generate_song("dark_wave", {"bpm": 118})
		_:
			return null


func _generate_song_stream(song_id: String, generation_params: Dictionary) -> AudioStream:
	if song_id.ends_with("_sb"):
		var soundbank_map: Dictionary = {
			"detroit_sb": "detroit_techno",
			"synthwave_sb": "synthwave",
			"burial_sb": "burial",
			"boc_sb": "boards_of_canada",
			"rave_sb": "rave",
			"kraftwerk_sb": "kraftwerk",
			"madonna_sb": "madonna_80s",
			"gypsy_sb": "gypsy_woman_house",
			"dub_house_sb": "dub_house",
			"moroder_disco_sb": "moroder_disco",
		}
		var bank_id: String = str(soundbank_map.get(song_id, ""))
		if not bank_id.is_empty():
			return SoundbankGenerator.generate_song(bank_id, generation_params)

	match song_id:
		"acid_house":
			return AudioSynthesizer.generate_acid_house_song(generation_params)
		"acid_techno_303":
			return AudioSynthesizer.generate_acid_house_song(generation_params)
		"prog_synth_70s":
			return AudioSynthesizer.generate_prog_synth_song(generation_params)
		"prog_odyssey":
			return AudioSynthesizer.generate_prog_odyssey_song(generation_params)
		"kpop_prog_remix":
			return AudioSynthesizer.generate_kpop_prog_song(generation_params)
		"pop_generative":
			return AudioSynthesizer.generate_pop_interactive_song(generation_params)
		"ambient_works":
			return AudioSynthesizer.generate_ambient_works_song(generation_params)
		"moroder_disco":
			return AudioSynthesizer.generate_moroder_disco_song(generation_params)
		"detroit_techno":
			return AudioSynthesizer.generate_detroit_techno_song(generation_params)
		"midnight_metroplex":
			return SoundbankGenerator.generate_song("detroit_techno", generation_params)
		"synthwave":
			return AudioSynthesizer.generate_synthwave_song(generation_params)
		"rave":
			return AudioSynthesizer.generate_rave_song(generation_params)
		"french_touch":
			return AudioSynthesizer.generate_french_touch_song(generation_params)
		"supersaw_trance":
			return AudioSynthesizer.generate_supersaw_trance_song(generation_params)
		"lofi_house":
			return AudioSynthesizer.generate_lofi_house_song(generation_params)
		"reese_jungle":
			return AudioSynthesizer.generate_reese_jungle_song(generation_params)
		"ambient_techno":
			return AudioSynthesizer.generate_ambient_techno_song(generation_params)
		"blade_runner":
			return AudioSynthesizer.generate_blade_runner_song(generation_params)
		"boards_of_canada":
			return AudioSynthesizer.generate_boards_of_canada_song(generation_params)
		"burial":
			return AudioSynthesizer.generate_burial_song(generation_params)
		"kraftwerk":
			return AudioSynthesizer.generate_kraftwerk_song(generation_params)
		"dark_kraftwerk_ambience":
			return AudioSynthesizer.generate_dark_kraftwerk_ambience_song(generation_params)
		"boards_of_canada_v2":
			return AudioSynthesizer.generate_boards_of_canada_v2_song(generation_params)
		"burial_v2":
			return AudioSynthesizer.generate_burial_v2_song(generation_params)
		"kraftwerk_v2":
			return AudioSynthesizer.generate_kraftwerk_v2_song(generation_params)
		"prog_synth_v2":
			return AudioSynthesizer.generate_prog_synth_v2_song(generation_params)
		"pop_v2":
			return AudioSynthesizer.generate_pop_v2_song(generation_params)
		"pop_madonna":
			return AudioSynthesizer.generate_pop_madonna_song(generation_params)
		"gypsy_woman_house":
			return AudioSynthesizer.generate_gypsy_woman_house_song(generation_params)
		"aphex_twin", "aphex_twin_digital_amber":
			return SoundbankGenerator.generate_song("aphex_twin", generation_params)
		"ada_theme":
			return SoundbankGenerator.generate_song("ada_theme", generation_params)
		"chromatic_story":
			return SoundbankGenerator.generate_song("chromatic_story", generation_params)
		"nineties_rnb":
			return SoundbankGenerator.generate_song("nineties_rnb", generation_params)
		"k_bass":
			return SoundbankGenerator.generate_song("k_bass", generation_params)
		"vangelis_cs80":
			return SoundbankGenerator.generate_song("vangelis_cs80", generation_params)
		"dark_wave_cathedral":
			return SoundbankGenerator.generate_song("dark_wave", generation_params)
		"chicago_dusseldorf":
			return SoundbankGenerator.generate_hybrid_song("chicago_dusseldorf", generation_params)
		"replicants_dawn":
			return SoundbankGenerator.generate_hybrid_song("replicants_dawn", generation_params)
		"foggy_frequencies":
			return SoundbankGenerator.generate_hybrid_song("foggy_frequencies", generation_params)
		_:
			_last_error = "config_only"
			return null
