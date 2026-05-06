extends SceneTree

const SONG_DIR := "res://commons/audio/parameters/songs"
const DEFAULT_OUT_DIR := "res://exports/all_tracks"

const SOUNDBANK_MAP := {
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


func _init() -> void:
	var options := _parse_args(OS.get_cmdline_user_args())
	var out_dir: String = options.get("out", DEFAULT_OUT_DIR)
	var only: Array = options.get("only", [])
	var include_extras: bool = options.get("include_extras", true)
	
	var audio_synth = load("res://commons/audio/generators/AudioSynthesizer.gd")
	var soundbank_gen = load("res://commons/audio/generators/SoundbankGenerator.gd")
	var exporter = load("res://commons/audio/generators/SongExporter.gd")
	
	if audio_synth == null or soundbank_gen == null or exporter == null:
		printerr("export_all_tracks: failed to load generator scripts")
		quit(1)
		return
	
	var song_ids := _load_song_ids()
	if include_extras:
		for extra_id in ["aphex_twin", "vangelis_cs80", "replicants_dawn", "foggy_frequencies", "chicago_dusseldorf"]:
			if not song_ids.has(extra_id):
				song_ids.append(extra_id)
	
	song_ids.sort()
	if not only.is_empty():
		song_ids = song_ids.filter(func(id): return id in only)
	
	if song_ids.is_empty():
		printerr("export_all_tracks: no song ids to export")
		quit(1)
		return
	
	_ensure_dir(out_dir)
	
	var ok_count := 0
	var fail_count := 0
	var skipped: Array = []
	
	print("EXPORT_START")
	print("out_dir=", ProjectSettings.globalize_path(out_dir), " count=", song_ids.size())
	
	for song_id in song_ids:
		var params := _build_generation_params(song_id)
		var stream: AudioStream = _generate_stream(song_id, params, audio_synth, soundbank_gen)
		if stream == null:
			skipped.append(song_id)
			print("SKIP ", song_id, " (no generator)")
			continue
		
		if not (stream is AudioStreamInteractive):
			fail_count += 1
			print("FAIL ", song_id, " (not interactive stream)")
			continue
		
		var wav_path := "%s/%s.wav" % [out_dir, song_id]
		var err: int = exporter.export_interactive_to_wav(stream as AudioStreamInteractive, wav_path)
		if err == OK:
			ok_count += 1
			print("OK   ", song_id, " -> ", ProjectSettings.globalize_path(wav_path))
		else:
			fail_count += 1
			print("FAIL ", song_id, " (export err=", err, ")")
	
	print("EXPORT_DONE ok=", ok_count, " fail=", fail_count, " skipped=", skipped.size())
	if not skipped.is_empty():
		print("SKIPPED_LIST=", ",".join(skipped))
	
	quit(0 if fail_count == 0 else 2)


func _parse_args(args: PackedStringArray) -> Dictionary:
	var out := DEFAULT_OUT_DIR
	var only: Array = []
	var include_extras := true
	
	for arg in args:
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		elif arg.begins_with("--only="):
			var raw = arg.trim_prefix("--only=")
			if not raw.is_empty():
				for token in raw.split(","):
					var clean = token.strip_edges()
					if not clean.is_empty():
						only.append(clean)
		elif arg == "--no-extras":
			include_extras = false
	
	return {
		"out": out,
		"only": only,
		"include_extras": include_extras,
	}


func _load_song_ids() -> Array:
	var ids: Array = []
	var dir := DirAccess.open(SONG_DIR)
	if dir == null:
		return ids
	
	dir.list_dir_begin()
	while true:
		var name := dir.get_next()
		if name.is_empty():
			break
		if dir.current_is_dir():
			continue
		if not name.ends_with(".json"):
			continue
		ids.append(name.get_basename())
	dir.list_dir_end()
	return ids


func _ensure_dir(path: String) -> void:
	var global = ProjectSettings.globalize_path(path)
	DirAccess.make_dir_recursive_absolute(global)


func _build_generation_params(song_id: String) -> Dictionary:
	var params: Dictionary = {
		"song_id": song_id,
	}
	var json_path := "%s/%s.json" % [SONG_DIR, song_id]
	if not FileAccess.file_exists(json_path):
		return params
	
	var file := FileAccess.open(json_path, FileAccess.READ)
	if file == null:
		return params
	
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK:
		return params
	var data = parser.data
	if not (data is Dictionary):
		return params
	
	var cfg: Dictionary = data
	var p = cfg.get("parameters", {})
	if p is Dictionary:
		if p.has("bpm") and p["bpm"] is Dictionary and p["bpm"].has("value"):
			params["bpm"] = float(p["bpm"]["value"])
		if p.has("key") and p["key"] is Dictionary and p["key"].has("value"):
			params["key"] = str(p["key"]["value"])
	
	if cfg.has("arrangement"):
		params["arrangement"] = cfg["arrangement"]
	if cfg.has("chord_progressions"):
		params["chord_progressions"] = cfg["chord_progressions"]
	
	return params


func _generate_stream(song_id: String, generation_params: Dictionary, audio_synth, soundbank_gen) -> AudioStream:
	if song_id.ends_with("_sb"):
		var bank_id = SOUNDBANK_MAP.get(song_id, "")
		if bank_id != "":
			return soundbank_gen.generate_song(bank_id, generation_params)
	
	match song_id:
		"acid_house", "acid_techno_303":
			return audio_synth.generate_acid_house_song(generation_params)
		"prog_synth_70s":
			return audio_synth.generate_prog_synth_song(generation_params)
		"kpop_prog_remix", "kpop_prog":
			return audio_synth.generate_kpop_prog_song(generation_params)
		"pop_generative":
			return audio_synth.generate_pop_interactive_song(generation_params)
		"ambient_works":
			return audio_synth.generate_ambient_works_song(generation_params)
		"moroder_disco":
			return audio_synth.generate_moroder_disco_song(generation_params)
		"detroit_techno":
			return audio_synth.generate_detroit_techno_song(generation_params)
		"midnight_metroplex":
			return soundbank_gen.generate_song("detroit_techno", generation_params)
		"synthwave":
			return audio_synth.generate_synthwave_song(generation_params)
		"rave":
			return audio_synth.generate_rave_song(generation_params)
		"french_touch":
			return audio_synth.generate_french_touch_song(generation_params)
		"supersaw_trance":
			return audio_synth.generate_supersaw_trance_song(generation_params)
		"lofi_house":
			return audio_synth.generate_lofi_house_song(generation_params)
		"reese_jungle":
			return audio_synth.generate_reese_jungle_song(generation_params)
		"ambient_techno":
			return audio_synth.generate_ambient_techno_song(generation_params)
		"blade_runner":
			return audio_synth.generate_blade_runner_song(generation_params)
		"boards_of_canada":
			return audio_synth.generate_boards_of_canada_song(generation_params)
		"burial":
			return audio_synth.generate_burial_song(generation_params)
		"kraftwerk":
			return audio_synth.generate_kraftwerk_song(generation_params)
		"boards_of_canada_v2":
			return audio_synth.generate_boards_of_canada_v2_song(generation_params)
		"burial_v2":
			return audio_synth.generate_burial_v2_song(generation_params)
		"kraftwerk_v2":
			return audio_synth.generate_kraftwerk_v2_song(generation_params)
		"prog_synth_v2":
			return audio_synth.generate_prog_synth_v2_song(generation_params)
		"pop_v2":
			return audio_synth.generate_pop_v2_song(generation_params)
		"pop_madonna":
			return audio_synth.generate_pop_madonna_song(generation_params)
		"gypsy_woman_house":
			return audio_synth.generate_gypsy_woman_house_song(generation_params)
		"aphex_twin", "aphex_twin_digital_amber":
			return soundbank_gen.generate_song("aphex_twin", generation_params)
		"ada_theme":
			return soundbank_gen.generate_song("ada_theme", generation_params)
		"chromatic_story":
			return soundbank_gen.generate_song("chromatic_story", generation_params)
		"nineties_rnb":
			return soundbank_gen.generate_song("nineties_rnb", generation_params)
		"k_bass":
			return soundbank_gen.generate_song("k_bass", generation_params)
		"vangelis_cs80":
			return soundbank_gen.generate_song("vangelis_cs80", generation_params)
		"chicago_dusseldorf":
			return soundbank_gen.generate_hybrid_song("chicago_dusseldorf", generation_params)
		"replicants_dawn":
			return soundbank_gen.generate_hybrid_song("replicants_dawn", generation_params)
		"foggy_frequencies":
			return soundbank_gen.generate_hybrid_song("foggy_frequencies", generation_params)
		_:
			return null
