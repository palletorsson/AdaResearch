# AudioSynthesizer.gd
# Path: res://commons/audio/AudioSynthesizer.gd
# Procedural Audio Synthesizer for generating sound effects and music
# Generates 16-bit PCM WAV data based on mathematical functions

extends Node
class_name AudioSynthesizer

const SAMPLE_RATE = 44100
const BAR_DURATION = 2.0 # Seconds per bar at 120 BPM (4/4)

# Threading
static var generation_thread: Thread
static var mutex: Mutex = Mutex.new()
static var is_generating = false

# signal song_ready(stream: AudioStreamInteractive) - Unused

# Audio configuration
# const SAMPLE_RATE = 44100.0 # This was replaced by the new SAMPLE_RATE above
const CHANNELS = 1

static func _idiv(a: int, b: int) -> int:
	return int(float(a) / float(b))

# Constants
const BPM = 100.0
# const BAR_DURATION = 240.0 / BPM # This was replaced by the new BAR_DURATION above

static func _merge_with_song_research_parameters(default_song_id: String, runtime_parameters: Dictionary) -> Dictionary:
	var requested_song_id = str(runtime_parameters.get("song_id", default_song_id)).strip_edges()
	if requested_song_id.is_empty():
		requested_song_id = default_song_id
	
	var merged = _load_song_research_defaults(default_song_id)
	if requested_song_id != default_song_id:
		var requested_defaults = _load_song_research_defaults(requested_song_id)
		for key in requested_defaults.keys():
			merged[key] = requested_defaults[key]
	for key in runtime_parameters.keys():
		merged[key] = runtime_parameters[key]
	
	merged["song_id"] = requested_song_id
	
	if not merged.has("progression_name"):
		var progression_data = merged.get("chord_progressions", null)
		if progression_data is Array and progression_data.size() > 0 and progression_data[0] is Dictionary:
			merged["progression_name"] = str(progression_data[0].get("name", ""))
	
	return merged


static func _load_song_research_defaults(song_id: String) -> Dictionary:
	var alias_map = {
		"kpop_prog": "kpop_prog_remix",
		"computer_love": "kraftwerk",
	}
	var lookup_song_id = alias_map.get(song_id, song_id)
	var config_path = "res://commons/audio/parameters/songs/%s.json" % lookup_song_id
	if not FileAccess.file_exists(config_path):
		return {"song_id": song_id}
	
	var file = FileAccess.open(config_path, FileAccess.READ)
	if file == null:
		return {"song_id": song_id}
	
	var parsed = JSON.parse_string(file.get_as_text())
	if not parsed is Dictionary:
		return {"song_id": song_id}
	
	var config: Dictionary = parsed
	var defaults: Dictionary = {"song_id": song_id}
	
	var config_params = config.get("parameters", {})
	if config_params is Dictionary:
		for param_name in config_params.keys():
			var param_info = config_params[param_name]
			if param_info is Dictionary:
				if param_info.has("value"):
					defaults[param_name] = param_info["value"]
				elif param_info.has("default"):
					defaults[param_name] = param_info["default"]
	
	if config.has("arrangement") and config["arrangement"] is Dictionary:
		defaults["arrangement"] = config["arrangement"]
	
	if config.has("chord_progressions"):
		defaults["chord_progressions"] = config["chord_progressions"]
	
	return defaults


static func _resolve_progression_from_parameters(parameters: Dictionary, fallback: Array, scale: Array) -> Array:
	var progression_data = parameters.get("chord_progressions", null)
	if progression_data == null:
		return fallback
	
	var progression_name = str(parameters.get("progression_name", ""))
	var chords = _extract_chords_from_progressions(progression_data, progression_name)
	if chords.is_empty():
		return fallback
	
	var degrees = _chords_to_degrees(chords, scale)
	if not degrees.is_empty():
		return degrees
	
	# If absolute chord names don't match the current random key, infer degrees from the configured song key.
	var key_value = str(parameters.get("key", "")).strip_edges()
	if not key_value.is_empty():
		var root = _extract_chord_root(key_value)
		if not root.is_empty():
			var key_scale = PopMusicTheory.get_minor_scale_notes(root + "3") if _is_minor_key(key_value) else PopMusicTheory.get_major_scale_notes(root + "3")
			degrees = _chords_to_degrees(chords, key_scale)
			if not degrees.is_empty():
				return degrees
	
	return fallback


static func _extract_chords_from_progressions(progressions, preferred_name: String) -> Array:
	var target_name = preferred_name.to_lower()
	
	if progressions is Array:
		if progressions.is_empty():
			return []
		if progressions[0] is Dictionary:
			var fallback: Array = []
			for progression in progressions:
				var progression_name = str(progression.get("name", "")).to_lower()
				var chords = progression.get("chords", [])
				if fallback.is_empty() and chords is Array:
					fallback = _expand_progression_chords(chords, progression)
				if not target_name.is_empty() and progression_name == target_name and chords is Array:
					return _expand_progression_chords(chords, progression)
			return fallback
		return progressions
	
	if progressions is Dictionary:
		if progressions.has("chords") and progressions["chords"] is Array:
			return _expand_progression_chords(progressions["chords"], progressions)
		for key in progressions.keys():
			var value = progressions[key]
			if value is Dictionary and value.has("chords") and value["chords"] is Array:
				if target_name.is_empty() or str(key).to_lower() == target_name or str(value.get("name", "")).to_lower() == target_name:
					return _expand_progression_chords(value["chords"], value)
	
	return []


static func _expand_progression_chords(chords: Array, progression_info: Dictionary) -> Array:
	var bars_per_chord = maxi(1, int(progression_info.get("bars_per_chord", 1)))
	if bars_per_chord <= 1:
		return chords
	
	var expanded: Array = []
	for chord in chords:
		for _repeat_idx in range(bars_per_chord):
			expanded.append(chord)
	return expanded


static func _chords_to_degrees(chords: Array, scale: Array) -> Array:
	var degrees: Array = []
	for chord_value in chords:
		var chord_name = str(chord_value).strip_edges()
		if chord_name.is_empty():
			continue
		var degree = _roman_to_degree(chord_name)
		if degree == -1:
			var root = _extract_chord_root(chord_name)
			if root.is_empty():
				continue
			degree = _find_scale_degree(root, scale)
		if degree >= 0:
			degrees.append(degree)
	return degrees


static func _roman_to_degree(symbol: String) -> int:
	var core = symbol.strip_edges()
	if core.is_empty():
		return -1
	
	while core.begins_with("b") or core.begins_with("#"):
		core = core.substr(1)
	
	var roman = ""
	for i in range(core.length()):
		var ch = core[i]
		if ch in ["I", "V", "i", "v"]:
			roman += ch
		else:
			break
	
	match roman.to_upper():
		"I":
			return 0
		"II":
			return 1
		"III":
			return 2
		"IV":
			return 3
		"V":
			return 4
		"VI":
			return 5
		"VII":
			return 6
		_:
			return -1


static func _extract_chord_root(chord_name: String) -> String:
	var token = chord_name.strip_edges()
	if token.is_empty():
		return ""
	
	var slash_idx = token.find("/")
	if slash_idx != -1:
		token = token.substr(0, slash_idx)
	
	var first = token[0].to_upper()
	if not first in ["A", "B", "C", "D", "E", "F", "G"]:
		return ""
	
	var root = first
	if token.length() > 1:
		var accidental = token[1]
		if accidental == "#" or accidental == "b":
			root += accidental
	
	return _normalize_note_name(root)


static func _normalize_note_name(note_name: String) -> String:
	var flat_map = {
		"Db": "C#",
		"Eb": "D#",
		"Gb": "F#",
		"Ab": "G#",
		"Bb": "A#",
		"Cb": "B",
		"Fb": "E",
	}
	return flat_map.get(note_name, note_name)


static func _find_scale_degree(root_note: String, scale: Array) -> int:
	for i in range(scale.size()):
		var note = str(scale[i])
		if note.is_empty():
			continue
		var octave_idx = note.length() - 1
		var scale_root = note.substr(0, octave_idx)
		if scale_root == root_note:
			return i
	
	var root_idx = PopMusicTheory.NOTES.find(root_note)
	if root_idx == -1:
		return -1
	
	var best_idx = -1
	var best_dist = 99
	for i in range(scale.size()):
		var note = str(scale[i])
		if note.is_empty():
			continue
		var octave_idx = note.length() - 1
		var scale_root = note.substr(0, octave_idx)
		var scale_idx = PopMusicTheory.NOTES.find(scale_root)
		if scale_idx == -1:
			continue
		var dist = abs(scale_idx - root_idx)
		dist = mini(dist, 12 - dist)
		if dist < best_dist:
			best_dist = dist
			best_idx = i
	
	return best_idx


static func _is_minor_key(key_value: String) -> bool:
	var lowered = key_value.to_lower()
	if lowered.find("maj") != -1:
		return false
	return lowered.ends_with("m") or lowered.find(" minor") != -1


static func _default_progression_for_song(song_id: String) -> Array:
	match song_id:
		"pop_generative":
			return PopMusicTheory.PROG_POP_4
		"ambient_works":
			return [1, 5, 6, 4]
		"prog_synth_70s":
			return [0, 6, 5, 4]
		"moroder_disco":
			return [1, 1, 5, 5]
		"detroit_techno":
			return [0, 0, 5, 4]
		"synthwave":
			return [0, 5, 3, 4]
		"rave":
			return [0, 0, 5, 5]
		"acid_house":
			return [0, 0, 0, 0]
		"french_touch":
			return [0, 5, 3, 4]
		"supersaw_trance":
			return [0, 5, 3, 4]
		"lofi_house":
			return [0, 3, 5, 4]
		"reese_jungle":
			return [0, 0, 5, 3]
		"ambient_techno":
			return [0, 3, 5, 0]
		"blade_runner":
			return [0, 5, 3, 4]
		"boards_of_canada":
			return [1, 4, 6, 5]
		"burial":
			return [1, 6, 4, 5]
		"kraftwerk":
			return [1, 4, 5, 1]
		"boards_of_canada_v2":
			return [0, 5, 3, 4]
		"burial_v2":
			return [0, 5, 3, 4]
		"kraftwerk_v2":
			return [0, 0, 4, 3]
		"gypsy_woman_house":
			return [0, 1, 2, 1]
		"pop_madonna":
			return [0, 4, 5, 3]
		"pop_v2":
			return [0, 4, 5, 3]
		"prog_synth_v2":
			return [0, 5, 3, 0]
		_:
			return [0, 5, 3, 4]


static func generate_pop_interactive_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("pop_generative", parameters)
	# 1. Pick Key and Progression
	randomize()
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "4"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Pop Song in ", root_note)
	
	# Create Interactive Stream
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 3
	playback.initial_clip = 0
	
	# 2. Generate Sections
	# Intro: Pad only
	var intro_stream = _generate_pop_section_stream(progression, scale, ["pad"])
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED) # Intro -> Verse
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Verse: Bass + Keys + Drums
	var verse_stream = _generate_pop_section_stream(progression, scale, ["bass", "keys", "drums"])
	playback.set_clip_stream(1, verse_stream)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED) # Verse -> Chorus
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Chorus: Full Mix
	var chorus_stream = _generate_pop_section_stream(progression, scale, ["bass", "keys", "pad", "lead", "drums"])
	playback.set_clip_stream(2, chorus_stream)
	playback.set_clip_name(2, "Chorus")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED) # Chorus -> Verse (Loop back)
	playback.set_clip_auto_advance_next_clip(2, 1)
	
	# 3. Transitions
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 1.0)
	playback.add_transition(2, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	
	return playback

static func generate_ambient_works_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("ambient_works", parameters)
	# Aphex Twin "Ambient Works 85-92" Style Generator
	# Characteristics: Warm analogue pads, lo-fi breakbeats, tape drift, acid bass
	
	randomize()
	# Slower tempo for ambient techno (85-95 BPM)
	var bpm = 90.0
	var bar_duration = 240.0 / bpm
	
	# Key selection (often minor/dorean for this style)
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3" # Lower register
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Ambient Works Song in ", root_note)
	
	# Create Interactive Stream
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4 # Intro, Build, Main, Outro
	playback.initial_clip = 0
	
	# 1. Intro: Tape Keys + Drift
	var intro_stream = _generate_ambient_section_stream(progression, scale, ["keys", "noise"], bar_duration)
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)  # Auto-advance to Build
	playback.set_clip_auto_advance_next_clip(0, 1)

	# 2. Build: Add Warm Pad, Bass, and Drums (Groove starts)
	var build_stream = _generate_ambient_section_stream(progression, scale, ["keys", "pad", "bass", "drums", "noise"], bar_duration)
	playback.set_clip_stream(1, build_stream)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)  # Auto-advance to Main
	playback.set_clip_auto_advance_next_clip(1, 2)

	# 3. Main: Full Groove (Breakbeat + Acid Bass)
	var main_stream = _generate_ambient_section_stream(progression, scale, ["keys", "pad", "bass", "drums", "noise"], bar_duration)
	playback.set_clip_stream(2, main_stream)
	playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)  # Auto-advance to Outro
	playback.set_clip_auto_advance_next_clip(2, 3)

	# 4. Outro: Fade to Pad
	var outro_stream = _generate_ambient_section_stream(progression, scale, ["pad", "noise"], bar_duration)
	playback.set_clip_stream(3, outro_stream)
	playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)  # Auto-advance back to Intro (loop)
	playback.set_clip_auto_advance_next_clip(3, 0)

	# Transitions (Long crossfades for ambient feel)
	var xfade = 4.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback

static func generate_prog_synth_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("prog_synth_70s", parameters)
	# 70s Progressive Rock Synthesizer - ELP, Kraftwerk, Yes, Pink Floyd style
	# Features: Minimoog bass, ELP-style leads with portamento, Kraftwerk sequences
	# Warm analog pads, motorik drums
	
	randomize()
	var bpm = 110.0  # Classic prog tempo
	var bar_duration = 240.0 / bpm
	
	# Key selection - prog rock often uses minor keys
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)
	
	# Prog rock loves unusual progressions (indices 0-6 for 7-note scale)
	var progressions = [
		[0, 6, 5, 4],     # i - VII - VI - V (descending minor)
		[0, 3, 6, 3],     # i - iv - VII - iv (classic prog)
		[0, 5, 2, 6],     # i - VI - iii - VII (emotive)
		[0, 4, 5, 3],     # i - V - VI - iv (pop-prog)
	]

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating 70s Prog Synth Track in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 5
	playback.initial_clip = 0
	
	# 1. Intro: Atmospheric pad + Kraftwerk sequence fading in
	var intro_stream = _generate_prog_section_stream(progression, scale, ["moog_pad"], bar_duration)
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# 2. Verse: Add Minimoog bass + motorik drums
	var verse_stream = _generate_prog_section_stream(progression, scale, ["moog_pad", "moog_bass", "motorik_drums"], bar_duration)
	playback.set_clip_stream(1, verse_stream)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# 3. Build: Add sequencer pattern (Kraftwerk style)
	var build_stream = _generate_prog_section_stream(progression, scale, ["moog_pad", "moog_bass", "kraftwerk_seq", "motorik_drums"], bar_duration)
	playback.set_clip_stream(2, build_stream)
	playback.set_clip_name(2, "Build")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# 4. Solo: ELP-style screaming Moog lead
	var solo_stream = _generate_prog_section_stream(progression, scale, ["moog_pad", "moog_bass", "elp_lead", "motorik_drums"], bar_duration)
	playback.set_clip_stream(3, solo_stream)
	playback.set_clip_name(3, "Solo")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 4)
	
	# 5. Outro: Fade back to pad
	var outro_stream = _generate_prog_section_stream(progression, scale, ["moog_pad", "kraftwerk_seq"], bar_duration)
	playback.set_clip_stream(4, outro_stream)
	playback.set_clip_name(4, "Outro")
	playback.set_clip_auto_advance(4, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(4, 0)
	
	# Transitions
	var xfade = 3.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 4, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(4, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback

static func generate_moroder_disco_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("moroder_disco", parameters)
	# Giorgio Moroder "I Feel Love" style - the synth as motor
	# Hypnotic 16th-note sequencer, 4-on-floor kick, pulsing bass, space pads
	
	randomize()
	var bpm = 125.0  # Classic disco tempo
	var bar_duration = 240.0 / bpm
	
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "2"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Moroder Disco Track in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	# 1. Intro: Just the sequencer pulse
	var intro_stream = _generate_disco_section_stream(progression, scale, ["sequencer"], bar_duration, bpm)
	playback.set_clip_stream(0, intro_stream)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# 2. Build: Add kick and bass
	var build_stream = _generate_disco_section_stream(progression, scale, ["sequencer", "kick", "bass"], bar_duration, bpm)
	playback.set_clip_stream(1, build_stream)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# 3. Main: Full groove with pad
	var main_stream = _generate_disco_section_stream(progression, scale, ["sequencer", "kick", "bass", "pad", "hats"], bar_duration, bpm)
	playback.set_clip_stream(2, main_stream)
	playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# 4. Outro: Strip back
	var outro_stream = _generate_disco_section_stream(progression, scale, ["sequencer", "pad"], bar_duration, bpm)
	playback.set_clip_stream(3, outro_stream)
	playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 2.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback

static func _generate_disco_section_stream(progression: Array, scale: Array, instruments: Array, bar_duration: float, bpm: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	var step_duration = 60.0 / bpm / 4.0  # 16th notes
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		if "sequencer" in instruments:
			# Moroder 16th note sequencer
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var step = int(t / step_duration) % 16
				var step_phase = fmod(t, step_duration) / step_duration
				
				var pattern = [0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12]
				var note_offset = pattern[step]
				var freq = root_freq * pow(2.0, note_offset / 12.0)
				
				var env = exp(-step_phase * 10.0)
				var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
				chord_mix[j] += saw * env * 0.25
		
		if "kick" in instruments:
			# 4-on-floor kick
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			for beat in range(_idiv(samples_per_chord, beat_samples) + 1):
				var start = beat * beat_samples
				for j in range(min(_idiv(beat_samples, 3), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kfreq = 55.0 + exp(-kt * 30.0) * 100.0
					var kick = sin(2.0 * PI * kfreq * kt) * exp(-kt * 8.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.5
		
		if "bass" in instruments:
			# Pulsing sub bass
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var sub = sin(2.0 * PI * root_freq * 0.5 * t)
				var pulse = abs(sin(2.0 * PI * 2.0 * t))
				chord_mix[j] += sub * pulse * 0.35
		
		if "pad" in instruments:
			# Space pad
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					pad += sin(2.0 * PI * freq * t)
				pad /= chord_freqs.size()
				var env = 1.0
				if progress < 0.2: env = progress / 0.2
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				chord_mix[j] += pad * env * 0.2
		
		if "hats" in instruments:
			# 8th note hats
			var eighth_samples = int(60.0 / bpm / 2.0 * SAMPLE_RATE)
			for beat in range(_idiv(samples_per_chord, eighth_samples) + 1):
				var start = beat * eighth_samples
				for j in range(min(int(SAMPLE_RATE * 0.02), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					var hat = sin(ht * 12000.0 + randf()) * exp(-ht * 80.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += hat * 0.15
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


static func generate_detroit_techno_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("detroit_techno", parameters)
	# Detroit Techno - Juan Atkins, Derrick May style
	# Cold machine funk, minimal, hypnotic
	randomize()
	var bpm = 125.0
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "2"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Detroit Techno in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_detroit_section(progression, scale, ["kick", "hihat"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var build = _generate_detroit_section(progression, scale, ["kick", "hihat", "bass", "stab"], bar_duration)
	playback.set_clip_stream(1, build); playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var main = _generate_detroit_section(progression, scale, ["kick", "hihat", "clap", "bass", "stab", "pad"], bar_duration)
	playback.set_clip_stream(2, main); playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var outro = _generate_detroit_section(progression, scale, ["pad", "hihat"], bar_duration)
	playback.set_clip_stream(3, outro); playback.set_clip_name(3, "Breakdown")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 2.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_detroit_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	# DETROIT TECHNO - Research: 909 punch, clean/dry, ZERO detune, machine funk
	var bpm = 125.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# 909 KICK - Punchy with click transient (research: fast attack, triangle-ish)
		if "kick" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			for beat in range(_idiv(samples_per_chord, beat_samples) + 1):
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					# 909: faster pitch drop, click transient
					var kfreq = 55.0 + exp(-kt * 50.0) * 120.0
					var body = sin(2.0 * PI * kfreq * kt)
					# Add click transient (909 characteristic)
					var click = 0.0
					if kt < 0.003: click = sin(kt * 8000.0) * (1.0 - kt / 0.003)
					var kick = (body + click * 0.4) * exp(-kt * 14.0)
					if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.55
		
		# 909 HIHAT - Metallic, crisp (research: +2dB high shelf)
		if "hihat" in instruments:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			for step in range(_idiv(samples_per_chord, sixteenth) + 1):
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.025), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					# Multiple high frequencies for metallic character
					var hat = sin(ht * 12000.0) * 0.5 + sin(ht * 15000.0) * 0.3 + (randf() - 0.5) * 0.4
					hat *= exp(-ht * 90.0)
					if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.14
		
		# 909 CLAP - Layered noise bursts
		if "clap" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			for beat in [1, 3]:
				var start = beat * beat_samples
				if start < samples_per_chord:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var ct = float(j) / SAMPLE_RATE
						# Multiple micro-transients (909 clap characteristic)
						var clap = 0.0
						for layer in [0.0, 0.008, 0.016, 0.024]:
							if ct >= layer:
								clap += (randf() - 0.5) * exp(-(ct - layer) * 40.0) * 0.4
						if start + j < samples_per_chord: chord_mix[start + j] += clap * 0.32
		
		# SUB + SQUARE BASS (research: 808-style sub with square harmonic)
		if "bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var bass_freq = root_freq * 0.5
				var sub = sin(2.0 * PI * bass_freq * t)
				# Add square wave harmonic for Detroit character
				var sq = sign(sin(2.0 * PI * bass_freq * t)) * 0.25
				chord_mix[j] += (sub * 0.35 + sq * 0.1)
		
		# CHORD STAB - Very short decay (research: 0.08s, percussive)
		if "stab" in instruments:
			var stab_times = [0, int(samples_per_chord * 0.5)]
			for start in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs: stab += sin(2.0 * PI * freq * 2.0 * st)
					stab /= chord_freqs.size()
					stab *= exp(-st * 25.0)  # Faster decay than before
					if start + j < samples_per_chord: chord_mix[start + j] += stab * 0.28
		
		# CLEAN DIGITAL PAD - ZERO detune, ZERO drift (research: clean, precise)
		if "pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				# Pure sines, NO detune (Detroit = clean digital)
				for freq in chord_freqs: pad += sin(2.0 * PI * freq * t)
				pad /= chord_freqs.size()
				var env = 1.0
				if progress < 0.12: env = progress / 0.12
				elif progress > 0.88: env = (1.0 - progress) / 0.12
				chord_mix[j] += pad * env * 0.18
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


static func generate_synthwave_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("synthwave", parameters)
	# Synthwave - The Weeknd, Kavinsky style
	# 80s gated drums, detuned leads, arpeggios
	randomize()
	var bpm = 118.0
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Synthwave in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_synthwave_section(progression, scale, ["arp", "pad"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var verse = _generate_synthwave_section(progression, scale, ["arp", "pad", "drums", "bass"], bar_duration)
	playback.set_clip_stream(1, verse); playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var chorus = _generate_synthwave_section(progression, scale, ["arp", "pad", "drums", "bass", "lead"], bar_duration)
	playback.set_clip_stream(2, chorus); playback.set_clip_name(2, "Chorus")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var outro = _generate_synthwave_section(progression, scale, ["pad", "arp"], bar_duration)
	playback.set_clip_stream(3, outro); playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 3.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_synthwave_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	# SYNTHWAVE - Research: LinnDrum gated reverb (150ms), 7-voice supersaw, fat Moog bass
	var bpm = 118.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# JUNO-STYLE ARP with chorus
		if "arp" in instruments:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			var arp_pattern = [0, 4, 7, 12, 7, 4]
			for step in range(_idiv(samples_per_chord, sixteenth)):
				var start = step * sixteenth
				var note_idx = step % arp_pattern.size()
				var freq = root_freq * pow(2.0, arp_pattern[note_idx] / 12.0)
				for j in range(min(sixteenth, samples_per_chord - start)):
					var at = float(j) / SAMPLE_RATE
					var env = exp(-at * 10.0)
					# Juno-style chorus (3 voices slightly detuned)
					var arp = fmod(at * freq, 1.0) * 2.0 - 1.0
					arp += fmod(at * freq * 1.004, 1.0) * 2.0 - 1.0
					arp += fmod(at * freq * 0.996, 1.0) * 2.0 - 1.0
					arp /= 3.0
					if start + j < samples_per_chord: chord_mix[start + j] += arp * env * 0.18
		
		# 7-VOICE SUPERSAW PAD (research: JP-8000 style, 25 cent detune)
		if "pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					# 7 detuned saws per note
					for voice in range(7):
						var detune_cents = (float(voice) / 6.0 - 0.5) * 25.0  # ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±12.5 cents
						var detune_ratio = pow(2.0, detune_cents / 1200.0)
						var saw = fmod(t * freq * detune_ratio, 1.0) * 2.0 - 1.0
						pad += saw / 7.0
				pad /= chord_freqs.size()
				var env = 1.0
				if progress < 0.15: env = progress / 0.15
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				chord_mix[j] += pad * env * 0.22
		
		# LINNDRUM GATED REVERB (research: 150ms reverb cut)
		if "drums" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			var gate_samples = int(0.15 * SAMPLE_RATE)  # 150ms gate
			# Gated kick
			for beat in range(4):
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick = sin(2.0 * PI * 50.0 * kt) * exp(-kt * 12.0)
					# Add room reverb that gets gated
					if j < gate_samples:
						kick += sin(2.0 * PI * 50.0 * kt * 0.5) * exp(-kt * 8.0) * 0.3
					if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.48
			# GATED SNARE (the 80s sound!)
			for beat in [1, 3]:
				var start = beat * beat_samples
				for j in range(min(gate_samples, samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					# Snare body
					var snare = sin(2.0 * PI * 180.0 * st) * exp(-st * 15.0) * 0.5
					snare += (randf() - 0.5) * exp(-st * 12.0) * 0.4
					# Gated reverb tail (cut at 150ms)
					var gate_env = 1.0 if j < gate_samples * 0.9 else (float(gate_samples - j) / (gate_samples * 0.1))
					if start + j < samples_per_chord: chord_mix[start + j] += snare * gate_env * 0.4
		
		# FAT MOOG BASS (research: saw+square, warm saturation)
		if "bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var bass_freq = root_freq * 0.5
				var saw = fmod(t * bass_freq, 1.0) * 2.0 - 1.0
				var square = sign(sin(2.0 * PI * bass_freq * t))
				var bass = saw * 0.6 + square * 0.4
				bass = tanh(bass * 1.4)  # Warm saturation
				chord_mix[j] += bass * 0.32
		
		# SUPERSAW LEAD (7 voices)
		if "lead" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var lead_freq = chord_freqs[0] * 2.0
				var lead = 0.0
				for voice in range(7):
					var detune_cents = (float(voice) / 6.0 - 0.5) * 20.0
					var detune_ratio = pow(2.0, detune_cents / 1200.0)
					lead += fmod(t * lead_freq * detune_ratio, 1.0) * 2.0 - 1.0
				lead /= 7.0
				var env = sin(PI * progress)
				chord_mix[j] += lead * env * 0.16
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


static func generate_rave_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("rave", parameters)
	# 90s Rave - The Prodigy, SL2 style
	# Aggressive breakbeats, hoover bass, stabs
	randomize()
	var bpm = 140.0
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "2"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Rave Track in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_rave_section(progression, scale, ["breakbeat"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var build = _generate_rave_section(progression, scale, ["breakbeat", "hoover", "stab"], bar_duration)
	playback.set_clip_stream(1, build); playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var drop = _generate_rave_section(progression, scale, ["breakbeat", "hoover", "stab", "lead"], bar_duration)
	playback.set_clip_stream(2, drop); playback.set_clip_name(2, "Drop")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var breakdown = _generate_rave_section(progression, scale, ["pad", "stab"], bar_duration)
	playback.set_clip_stream(3, breakdown); playback.set_clip_name(3, "Breakdown")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 1.5
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_rave_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	# RAVE - Research: Hoover ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±3% detune, Amen breaks, Mentasm stabs, DISTORTION
	var bpm = 140.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# AMEN-STYLE BREAKBEAT (research: chopped, iconic pattern)
		if "breakbeat" in instruments:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			var kick_steps = [0, 6, 10]
			var snare_steps = [4, 12]
			var hat_steps = [2, 6, 10, 14]
			
			for step in range(16):
				var start = step * sixteenth
				if step in kick_steps:
					for j in range(min(int(SAMPLE_RATE * 0.07), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						# Punchy breakbeat kick
						var kick = sin(2.0 * PI * (65.0 + exp(-kt * 45.0) * 90.0) * kt) * exp(-kt * 15.0)
						kick = tanh(kick * 1.8)  # Distortion!
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.5
				if step in snare_steps:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						# Crunchy snare
						var snare = sin(2.0 * PI * 200.0 * st) * exp(-st * 20.0) * 0.4
						snare += (randf() - 0.5) * exp(-st * 18.0) * 0.6
						snare = tanh(snare * 2.0)  # Distortion!
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.42
				if step in hat_steps:
					for j in range(min(int(SAMPLE_RATE * 0.02), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 100.0)
						if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.18
		
		# HOOVER BASS - ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±3% detuned saws with filter LFO (research: Mentasm sound)
		if "hoover" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var hoover = 0.0
				# 5 detuned saws for thick hoover
				for detune in [-0.035, -0.015, 0.0, 0.015, 0.035]:
					var freq = root_freq * 0.5 * (1.0 + detune)
					var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
					hoover += saw
				hoover /= 5.0
				# Filter LFO (hoover "wobble")
				var filter_mod = 0.4 + sin(2.0 * PI * 3.0 * t) * 0.3
				hoover *= filter_mod
				# HEAVY saturation (rave distortion)
				hoover = tanh(hoover * 2.5)
				chord_mix[j] += hoover * 0.38
		
		# MENTASM STAB - Detuned saw chords (research: 25 cent detune)
		if "stab" in instruments:
			var stab_times = [0, int(samples_per_chord * 0.25), int(samples_per_chord * 0.75)]
			for start in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs:
						# Detuned saws per note (Mentasm character)
						var saw1 = fmod(st * freq * 2.0, 1.0) * 2.0 - 1.0
						var saw2 = fmod(st * freq * 2.0 * 1.015, 1.0) * 2.0 - 1.0  # 25 cent detune
						stab += (saw1 + saw2) * 0.5
					stab /= chord_freqs.size()
					stab *= exp(-st * 18.0)
					stab = tanh(stab * 1.8)  # Distortion
					if start + j < samples_per_chord: chord_mix[start + j] += stab * 0.32
		
		# AGGRESSIVE LEAD
		if "lead" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var lead_freq = chord_freqs[0] * 2.0
				var saw = fmod(t * lead_freq, 1.0) * 2.0 - 1.0
				saw = tanh(saw * 1.5)  # Distortion
				var env = sin(PI * progress * 2.0) if progress < 0.5 else 0.0
				chord_mix[j] += saw * env * 0.22
		
		# DARK PAD
		if "pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					# Slight detune for width
					pad += sin(2.0 * PI * freq * t)
					pad += sin(2.0 * PI * freq * 1.003 * t) * 0.5
				pad /= chord_freqs.size() * 1.5
				var env = 1.0
				if progress < 0.25: env = progress / 0.25
				elif progress > 0.75: env = (1.0 - progress) / 0.25
				chord_mix[j] += pad * env * 0.22
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			# Global distortion for rave character
			var sample = tanh(chord_mix[j] * 1.3)
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# ACID HOUSE - Chicago 1987 style (Phuture, DJ Pierre)
# The TB-303 is acid house. High resonance, filter sweeps, slides, accents.
# ============================================================================
static func generate_acid_house_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("acid_house", parameters)
	# Acid House - Phuture, DJ Pierre, 808 State style
	# Squelchy 303, 808/909 drums, hypnotic repetition
	randomize()
	var bpm = 124.0
	var bar_duration = 240.0 / bpm
	# Use low octave for proper acid bass (A1 = 55Hz, classic acid frequency)
	var root_note = "A1"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)
	# Acid house often uses minimal harmonic movement

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Acid House Track in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	# Intro: Drums only, building anticipation
	var intro = _generate_acid_house_section(progression, scale, ["kick", "hihat"], bar_duration, 0.3)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Build: 303 enters, filter closed
	var build = _generate_acid_house_section(progression, scale, ["kick", "hihat", "acid303"], bar_duration, 0.5)
	playback.set_clip_stream(1, build); playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Peak: Full squelch, claps, maximum energy
	var peak = _generate_acid_house_section(progression, scale, ["kick", "hihat", "clap", "acid303", "cowbell"], bar_duration, 0.9)
	playback.set_clip_stream(2, peak); playback.set_clip_name(2, "Peak")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	# Breakdown: 303 solo with filter play
	var breakdown = _generate_acid_house_section(progression, scale, ["acid303"], bar_duration, 0.7)
	playback.set_clip_stream(3, breakdown); playback.set_clip_name(3, "Breakdown")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 2.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_acid_house_section(progression: Array, scale: Array, instruments: Array, bar_duration: float, filter_intensity: float) -> AudioStreamWAV:
	# ACID HOUSE - Research: 303 18dB filter, high resonance, slide + accent
	var bpm = 124.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	# 303 filter state (persists across samples for resonance)
	var filter_state = [0.0, 0.0, 0.0]
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# 808/909 KICK - 4-on-floor, punchy
		if "kick" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			for beat in range(_idiv(samples_per_chord, beat_samples) + 1):
				var start = beat * beat_samples
				for j in range(mini(int(SAMPLE_RATE * 0.15), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					# 808-style kick with pitch drop
					var kfreq = 50.0 + exp(-kt * 35.0) * 80.0
					var kick = sin(2.0 * PI * kfreq * kt) * exp(-kt * 10.0)
					if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.38
		
		# 808 HIHAT - 16th notes
		if "hihat" in instruments:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			for step in range(_idiv(samples_per_chord, sixteenth) + 1):
				var start = step * sixteenth
				var is_open = (step % 4 == 2)  # Open hat on offbeats
				var decay = 80.0 if not is_open else 25.0
				for j in range(mini(int(SAMPLE_RATE * 0.05), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-ht * decay)
					# High-pass character
					hat += sin(ht * 12000.0) * 0.3 * exp(-ht * decay)
					if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.12
		
		# 808 CLAP - On 2 and 4
		if "clap" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			for beat in [1, 3]:
				var start = beat * beat_samples
				if start < samples_per_chord:
					for j in range(mini(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
						var ct = float(j) / SAMPLE_RATE
						# 808 clap: layered noise bursts
						var clap = 0.0
						for layer in [0.0, 0.01, 0.02]:
							if ct >= layer:
								clap += (randf() - 0.5) * exp(-(ct - layer) * 35.0) * 0.5
						if start + j < samples_per_chord: chord_mix[start + j] += clap * 0.28
		
		# 808 COWBELL - Chicago flavor
		if "cowbell" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			# Syncopated cowbell pattern
			var cowbell_beats = [0.5, 1.5, 2.5, 3.5]  # Offbeats
			for cb in cowbell_beats:
				var start = int(cb * beat_samples)
				if start < samples_per_chord:
					for j in range(mini(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
						var ct = float(j) / SAMPLE_RATE
						# 808 cowbell: two detuned square waves
						var cw = 0.0
						cw += (1.0 if fmod(ct * 587.0, 1.0) < 0.5 else -1.0) * 0.5
						cw += (1.0 if fmod(ct * 845.0, 1.0) < 0.5 else -1.0) * 0.5
						cw *= exp(-ct * 25.0)
						if start + j < samples_per_chord: chord_mix[start + j] += cw * 0.08
		
		# TB-303 ACID BASS - The heart of acid house!
		if "acid303" in instruments:
			var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
			
			# Generate acid pattern with slides and accents
			# Classic pattern: root with octave jumps, strategic slides
			var acid_pattern = []
			var base_note = root_freq
			for step in range(16):
				var note_data = {"freq": base_note, "slide": false, "accent": false, "rest": false}
				# Pattern: mostly root, occasional octave up
				if step in [3, 8, 13]:
					note_data.freq = base_note * 2.0  # Octave up
					note_data.slide = true
				elif step in [1, 5, 9]:
					note_data.rest = true
				# Accents on certain beats (NOT step 0 - avoid spike when 303 enters)
				if step in [4, 7, 10, 14]:
					note_data.accent = true
				acid_pattern.append(note_data)
			
			var current_freq = base_note
			for step in range(16):
				var start = step * sixteenth
				var note = acid_pattern[step]
				
				if note.rest:
					continue
				
				var target_freq = note.freq
				
				for j in range(mini(sixteenth, samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					var _step_phase = float(j) / float(sixteenth)
					
					# Portamento (slide)
					if note.slide:
						current_freq = lerp(current_freq, target_freq, 0.08)
					else:
						current_freq = lerp(current_freq, target_freq, 0.5)
					
					# Sawtooth oscillator
					var phase = fmod(t * current_freq + float(start) / SAMPLE_RATE * current_freq, 1.0)
					var saw = phase * 2.0 - 1.0
					
					# Filter envelope
					var env_decay = 8.0 if not note.accent else 5.0
					var env = exp(-t * env_decay)
					
					# Accent boosts filter envelope (moderate boost to avoid spikes)
					var accent_mult = 1.0 if not note.accent else 1.25
					
					# Calculate filter cutoff (THE ACID SOUND)
					var base_cutoff = 200.0 + filter_intensity * 600.0
					var env_mod = 3000.0 * filter_intensity
					var filter_cutoff = base_cutoff + env * env_mod * accent_mult
					
					# Slow filter sweep over time for movement
					var sweep = sin(float(start + j) / SAMPLE_RATE * 0.5) * 0.3 + 0.7
					filter_cutoff *= sweep
					
					# Moderate resonance (0.5-0.65 range, tamed to avoid squealing)
					var resonance = 0.5 + filter_intensity * 0.15
					
					# Simple resonant lowpass approximation
					var f = clampf(filter_cutoff / SAMPLE_RATE * 2.0, 0.01, 0.99)
					var fb = resonance + resonance / (1.0 - f + 0.001)
					
					filter_state[0] += f * (saw - filter_state[0] + fb * (filter_state[0] - filter_state[2]))
					filter_state[1] += f * (filter_state[0] - filter_state[1])
					filter_state[2] += f * (filter_state[1] - filter_state[2])
					
					var filtered = filter_state[2]
					
					# Amp envelope
					var amp_env = exp(-t * 4.0) * 0.8 + 0.2
					if note.accent:
						amp_env *= 1.15  # Subtle accent boost (avoid spikes)
					
					var acid = filtered * amp_env * 0.22  # Much lower level - 303 should sit in mix
					
					if start + j < samples_per_chord: chord_mix[start + j] += acid
		
		# Mix into final buffer
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			# Soft clip for warmth (reduced to prevent clipping)
			var sample = tanh(chord_mix[j] * 0.85)
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# FRENCH TOUCH - Daft Punk "Discovery" style
# Based on research: Resonant bandpass "duck" leads, wavetable chiffs, filter disco
# ============================================================================
static func generate_french_touch_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("french_touch", parameters)
	randomize()
	var bpm = 120.0
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating French Touch in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_french_touch_section(progression, scale, ["filter_bass", "duck_lead"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var verse = _generate_french_touch_section(progression, scale, ["filter_bass", "duck_lead", "chiff", "drums"], bar_duration)
	playback.set_clip_stream(1, verse); playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var chorus = _generate_french_touch_section(progression, scale, ["filter_bass", "duck_lead", "chiff", "drums", "vocoder_pad"], bar_duration)
	playback.set_clip_stream(2, chorus); playback.set_clip_name(2, "Chorus")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var outro = _generate_french_touch_section(progression, scale, ["filter_bass", "vocoder_pad"], bar_duration)
	playback.set_clip_stream(3, outro); playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 1.5
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_french_touch_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var bpm = 120.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# FILTER BASS - Disco sidechained bass
		if "filter_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var beat_pos = fmod(t * bpm / 60.0, 1.0)
				var sidechain = 1.0 - exp(-beat_pos * 8.0) * 0.6  # Duck on beat
				var saw = fmod(t * root_freq * 0.5, 1.0) * 2.0 - 1.0
				var filter_env = 0.3 + 0.7 * exp(-fmod(t, bar_duration) * 3.0)
				saw = tanh(saw * 2.0) * filter_env
				chord_mix[j] += saw * sidechain * 0.4
		
		# DUCK LEAD - Resonant bandpass "quack" (Daft Punk signature)
		if "duck_lead" in instruments:
			var lead_freq = chord_freqs[0] * 2.0
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				# Bandpass resonance simulation
				var saw = fmod(t * lead_freq, 1.0) * 2.0 - 1.0
				var resonance = sin(2.0 * PI * 1200.0 * t) * 0.3  # Resonant peak
				var env = exp(-fmod(t, 0.25) * 8.0)  # Short envelope per beat
				var duck = (saw + resonance) * env * 0.25
				chord_mix[j] += duck
		
		# CHIFF - Wavetable double-hit (from research)
		if "chiff" in instruments:
			var chiff_times = [0, int(samples_per_chord * 0.5)]
			for start in chiff_times:
				for j in range(min(int(SAMPLE_RATE * 0.15), samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					var chiff = 0.0
					for freq in chord_freqs:
						var wave = sin(2.0 * PI * freq * 2.0 * t)
						chiff += wave
					chiff /= chord_freqs.size()
					# Double envelope (attack + release tail)
					var env1 = exp(-t * 15.0)
					var env2 = exp(-(0.15 - t) * 10.0) if t > 0.1 else 0.0
					if start + j < samples_per_chord: chord_mix[start + j] += chiff * (env1 + env2 * 0.3) * 0.2
		
		# DRUMS - 4 on floor disco
		if "drums" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			for step in range(16):
				var start = step * sixteenth
				# Kick on 1, 5, 9, 13
				if step % 4 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick = sin(2.0 * PI * (55.0 + exp(-kt * 30.0) * 60.0) * kt) * exp(-kt * 10.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.5
				# Open hat on offbeats
				if step % 2 == 1:
					for j in range(min(int(SAMPLE_RATE * 0.05), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 40.0)
						if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.15
		
		# VOCODER PAD - Warm filtered pad
		if "vocoder_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					pad += sin(2.0 * PI * freq * t)
					pad += sin(2.0 * PI * freq * 1.01 * t) * 0.5  # Detune
				pad /= chord_freqs.size() * 1.5
				var env = 1.0
				if progress < 0.2: env = progress / 0.2
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				chord_mix[j] += pad * env * 0.2
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# SUPERSAW TRANCE - Based on research: 8-voice detuned saws, layered octaves
# Big uplifting chords with long attack/release
# ============================================================================
static func generate_supersaw_trance_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("supersaw_trance", parameters)
	randomize()
	var bpm = 138.0  # Classic trance tempo
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Supersaw Trance in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_supersaw_section(progression, scale, ["supersaw_pad"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var build = _generate_supersaw_section(progression, scale, ["supersaw_pad", "trance_bass", "buildup_drums"], bar_duration)
	playback.set_clip_stream(1, build); playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var drop = _generate_supersaw_section(progression, scale, ["supersaw_pad", "supersaw_lead", "trance_bass", "trance_drums"], bar_duration)
	playback.set_clip_stream(2, drop); playback.set_clip_name(2, "Drop")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var breakdown = _generate_supersaw_section(progression, scale, ["supersaw_pad", "arp"], bar_duration)
	playback.set_clip_stream(3, breakdown); playback.set_clip_name(3, "Breakdown")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 2.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_supersaw_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var bpm = 138.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# SUPERSAW PAD - 8 detuned voices per note (from research)
		if "supersaw_pad" in instruments:
			var detune_amounts = [-0.06, -0.04, -0.02, -0.01, 0.01, 0.02, 0.04, 0.06]
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var supersaw = 0.0
				for freq in chord_freqs:
					for detune in detune_amounts:
						var detuned_freq = freq * (1.0 + detune * 0.1)
						var saw = fmod(t * detuned_freq, 1.0) * 2.0 - 1.0
						supersaw += saw
				supersaw /= chord_freqs.size() * detune_amounts.size()
				# Long attack and release (from research)
				var env = 1.0
				if progress < 0.15: env = progress / 0.15
				elif progress > 0.7: env = (1.0 - progress) / 0.3
				chord_mix[j] += supersaw * env * 0.35
		
		# SUPERSAW LEAD - Octave up, brighter
		if "supersaw_lead" in instruments:
			var lead_freq = chord_freqs[0] * 2.0
			var detunes = [-0.03, 0.0, 0.03]
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var lead = 0.0
				for detune in detunes:
					lead += fmod(t * lead_freq * (1.0 + detune), 1.0) * 2.0 - 1.0
				lead /= detunes.size()
				var env = sin(PI * progress) if progress < 0.5 else sin(PI * (1.0 - progress))
				chord_mix[j] += lead * env * 0.2
		
		# TRANCE BASS - Sub with punch
		if "trance_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var beat_pos = fmod(t * bpm / 60.0, 1.0)
				var sidechain = 1.0 - exp(-beat_pos * 10.0) * 0.5
				var bass = sin(2.0 * PI * root_freq * 0.25 * t)
				bass = tanh(bass * 1.5)
				chord_mix[j] += bass * sidechain * 0.4
		
		# TRANCE DRUMS - Punchy kick, offbeat hats
		if "trance_drums" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			for step in range(16):
				var start = step * sixteenth
				if step % 4 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick = sin(2.0 * PI * (50.0 + exp(-kt * 50.0) * 100.0) * kt) * exp(-kt * 15.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.55
				if step % 2 == 1:
					for j in range(min(int(SAMPLE_RATE * 0.03), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 80.0)
						if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.18
		
		# BUILDUP DRUMS - Snare roll buildup
		if "buildup_drums" in instruments:
			var roll_density = 4 + int(float(i) / progression.size() * 12)
			var roll_step = _idiv(samples_per_chord, roll_density)
			for r in range(roll_density):
				var start = int(r * roll_step)
				for j in range(min(int(SAMPLE_RATE * 0.05), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(2.0 * PI * 200.0 * st) * exp(-st * 25.0) * 0.4
					snare += (randf() - 0.5) * exp(-st * 30.0) * 0.3
					if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.3
		
		# ARP - 16th note arpeggio
		if "arp" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			for step in range(16):
				var note_idx = step % chord_freqs.size()
				var arp_freq = chord_freqs[note_idx] * 2.0
				var start = step * sixteenth
				for j in range(min(sixteenth, samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					var arp = sin(2.0 * PI * arp_freq * t) * exp(-t * 20.0)
					if start + j < samples_per_chord: chord_mix[start + j] += arp * 0.15
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# LO-FI HOUSE - Based on Juno-60 research: DCO bass, PWM, filter envelope pluck
# Dusty drums, tape warmth, classic house groove
# ============================================================================
static func generate_lofi_house_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("lofi_house", parameters)
	randomize()
	var bpm = 118.0
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "2"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Lo-Fi House in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_lofi_house_section(progression, scale, ["dusty_drums", "juno_pad"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var groove = _generate_lofi_house_section(progression, scale, ["dusty_drums", "juno_bass", "juno_pad"], bar_duration)
	playback.set_clip_stream(1, groove); playback.set_clip_name(1, "Groove")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var main = _generate_lofi_house_section(progression, scale, ["dusty_drums", "juno_bass", "juno_pad", "stab", "vocal_chop"], bar_duration)
	playback.set_clip_stream(2, main); playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var outro = _generate_lofi_house_section(progression, scale, ["dusty_drums", "juno_pad"], bar_duration)
	playback.set_clip_stream(3, outro); playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 1.5
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_lofi_house_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var bpm = 118.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# JUNO BASS - DCO with filter envelope pluck (from research)
		if "juno_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var note_pos = fmod(t * bpm / 60.0, 1.0)
				# Saw + Square blend (Juno style)
				var saw = fmod(t * root_freq * 0.5, 1.0) * 2.0 - 1.0
				var pwm = sin(2.0 * PI * 0.5 * t) * 0.3 + 0.5  # PWM modulation
				var square = 1.0 if fmod(t * root_freq * 0.5, 1.0) < pwm else -1.0
				var sub = sin(2.0 * PI * root_freq * 0.25 * t)  # Sub oscillator
				var bass = saw * 0.5 + square * 0.3 + sub * 0.4
				# Filter envelope pluck (short decay)
				var filter_env = 0.3 + 0.7 * exp(-note_pos * 8.0)
				bass = tanh(bass * filter_env * 1.5)
				chord_mix[j] += bass * 0.4
		
		# JUNO PAD - Chorus detuned pad
		if "juno_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					# Juno chorus: slight detune + modulation
					var chorus_mod = sin(2.0 * PI * 0.5 * t) * 0.005
					pad += sin(2.0 * PI * freq * (1.0 + chorus_mod) * t)
					pad += sin(2.0 * PI * freq * (1.0 - chorus_mod) * t) * 0.7
				pad /= chord_freqs.size() * 1.7
				var env = 1.0
				if progress < 0.1: env = progress / 0.1
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				chord_mix[j] += pad * env * 0.2
		
		# DUSTY DRUMS - Lo-fi filtered drums
		if "dusty_drums" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			for step in range(16):
				var start = step * sixteenth
				# Kick on 1, 5, 9, 13
				if step % 4 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick = sin(2.0 * PI * (45.0 + exp(-kt * 25.0) * 50.0) * kt) * exp(-kt * 8.0)
						kick = tanh(kick * 1.3)  # Tape saturation
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.45
				# Clap on 4, 12
				if step == 4 or step == 12:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var ct = float(j) / SAMPLE_RATE
						var clap = (randf() - 0.5) * exp(-ct * 15.0) * 0.6
						clap += sin(2.0 * PI * 150.0 * ct) * exp(-ct * 20.0) * 0.3
						if start + j < samples_per_chord: chord_mix[start + j] += clap * 0.35
				# Dusty hat
				if step % 2 == 1:
					for j in range(min(int(SAMPLE_RATE * 0.04), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 50.0)
						hat *= 0.7 + randf() * 0.3  # Dusty variation
						if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.12
		
		# STAB - Filtered chord stab
		if "stab" in instruments:
			var stab_times = [0, int(samples_per_chord * 0.375)]
			for start in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs:
						stab += sin(2.0 * PI * freq * 2.0 * st)
					stab /= chord_freqs.size()
					stab *= exp(-st * 25.0)
					if start + j < samples_per_chord: chord_mix[start + j] += stab * 0.2
		
		# VOCAL CHOP - Simple pitched "ah" sample simulation
		if "vocal_chop" in instruments:
			var chop_start = int(samples_per_chord * 0.25)
			for j in range(min(int(SAMPLE_RATE * 0.3), samples_per_chord - chop_start)):
				var vt = float(j) / SAMPLE_RATE
				var formant1 = sin(2.0 * PI * 800.0 * vt) * 0.5
				var formant2 = sin(2.0 * PI * 1200.0 * vt) * 0.3
				var vocal = (formant1 + formant2) * exp(-vt * 5.0)
				if chop_start + j < samples_per_chord: chord_mix[chop_start + j] += vocal * 0.15
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# REESE JUNGLE - Kevin Saunderson's classic: 2 detuned saws + sub
# Based on research: ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±0.07 semitone detune, 64 unison voices, metal filter
# ============================================================================
static func generate_reese_jungle_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("reese_jungle", parameters)
	randomize()
	var bpm = 170.0  # Classic jungle tempo
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "2"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Reese Jungle in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_reese_jungle_section(progression, scale, ["amen_break"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var build = _generate_reese_jungle_section(progression, scale, ["amen_break", "reese_bass", "stab"], bar_duration)
	playback.set_clip_stream(1, build); playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var drop = _generate_reese_jungle_section(progression, scale, ["amen_break", "reese_bass", "stab", "pad"], bar_duration)
	playback.set_clip_stream(2, drop); playback.set_clip_name(2, "Drop")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var breakdown = _generate_reese_jungle_section(progression, scale, ["pad", "reese_bass"], bar_duration)
	playback.set_clip_stream(3, breakdown); playback.set_clip_name(3, "Breakdown")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 1.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_reese_jungle_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var _bpm = 170.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# REESE BASS - Two detuned saws + sub (from research: ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±0.07 semitones)
		if "reese_bass" in instruments:
			var detune_semitones = 0.07
			var detune_ratio = pow(2.0, detune_semitones / 12.0)
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				# Two detuned saws
				var saw1 = fmod(t * root_freq * 0.5 * detune_ratio, 1.0) * 2.0 - 1.0
				var saw2 = fmod(t * root_freq * 0.5 / detune_ratio, 1.0) * 2.0 - 1.0
				# Sub sine
				var sub = sin(2.0 * PI * root_freq * 0.25 * t)
				# Combine with filter sweep
				var reese = (saw1 + saw2) * 0.4 + sub * 0.5
				# LFO on filter (slow wobble)
				var filter_mod = 0.5 + 0.5 * sin(2.0 * PI * 0.25 * t)
				reese = tanh(reese * (1.0 + filter_mod * 0.5))
				chord_mix[j] += reese * 0.4
		
		# AMEN BREAK - Chopped breakbeat simulation
		if "amen_break" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			# Classic amen pattern approximation
			var kick_steps = [0, 6, 10]
			var snare_steps = [4, 12]
			var hat_steps = [0, 2, 4, 6, 8, 10, 12, 14]
			for step in range(16):
				var start = step * sixteenth
				if step in kick_steps:
					for j in range(min(int(SAMPLE_RATE * 0.06), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick = sin(2.0 * PI * (55.0 + exp(-kt * 50.0) * 80.0) * kt) * exp(-kt * 15.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.5
				if step in snare_steps:
					for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						var snare = sin(2.0 * PI * 200.0 * st) * exp(-st * 20.0) * 0.5
						snare += (randf() - 0.5) * exp(-st * 25.0) * 0.6
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.4
				if step in hat_steps:
					for j in range(min(int(SAMPLE_RATE * 0.02), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 100.0)
						if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.15
		
		# STAB - Jungle chord stab with bitcrush character
		if "stab" in instruments:
			var stab_times = [0, int(samples_per_chord * 0.5)]
			for start in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs:
						stab += sin(2.0 * PI * freq * 2.0 * st)
						stab += sin(2.0 * PI * freq * 4.0 * st) * 0.3  # Harmonics
					stab /= chord_freqs.size() * 1.3
					stab *= exp(-st * 15.0)
					# Bitcrush simulation
					stab = floor(stab * 16.0) / 16.0
					if start + j < samples_per_chord: chord_mix[start + j] += stab * 0.25
		
		# PAD - Atmospheric pad
		if "pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					pad += sin(2.0 * PI * freq * t)
				pad /= chord_freqs.size()
				var env = 1.0
				if progress < 0.2: env = progress / 0.2
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				chord_mix[j] += pad * env * 0.15
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# AMBIENT TECHNO - Based on research: 4 oscillators, 5-sec attack, LFOs on sync
# Carl Craig, The Orb style immersive pads
# ============================================================================
static func generate_ambient_techno_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("ambient_techno", parameters)
	randomize()
	var bpm = 110.0  # Slower ambient tempo
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Ambient Techno in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_ambient_techno_section(progression, scale, ["ambient_pad"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var evolve = _generate_ambient_techno_section(progression, scale, ["ambient_pad", "texture", "minimal_kick"], bar_duration)
	playback.set_clip_stream(1, evolve); playback.set_clip_name(1, "Evolve")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var peak = _generate_ambient_techno_section(progression, scale, ["ambient_pad", "texture", "minimal_kick", "arp"], bar_duration)
	playback.set_clip_stream(2, peak); playback.set_clip_name(2, "Peak")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var dissolve = _generate_ambient_techno_section(progression, scale, ["ambient_pad", "texture"], bar_duration)
	playback.set_clip_stream(3, dissolve); playback.set_clip_name(3, "Dissolve")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 3.0  # Longer crossfade for ambient
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_ambient_techno_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var bpm = 110.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var _root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# AMBIENT PAD - 4 oscillators at different octaves (from research)
		if "ambient_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					# 4 octave layers: +2, 0, +1, -1
					var osc_high = sin(2.0 * PI * freq * 4.0 * t) * 0.15
					var osc_mid = sin(2.0 * PI * freq * t) * 0.3
					var osc_upper = sin(2.0 * PI * freq * 2.0 * t) * 0.25
					var osc_low = sin(2.0 * PI * freq * 0.5 * t) * 0.2
					# Sync modulation (LFO)
					var sync_mod = sin(2.0 * PI * 0.1 * t) * 0.1
					pad += (osc_high + osc_mid + osc_upper + osc_low) * (1.0 + sync_mod)
				pad /= chord_freqs.size()
				# VERY slow envelope (5 sec attack from research)
				var env = 1.0
				var attack_time = 0.4  # 40% of section = ~5 sec
				if progress < attack_time: env = progress / attack_time
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				chord_mix[j] += pad * env * 0.25
		
		# TEXTURE - Granular-like evolving texture
		if "texture" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				# Multiple slow LFOs creating evolving texture
				var lfo1 = sin(2.0 * PI * 0.07 * t)
				var lfo2 = sin(2.0 * PI * 0.13 * t + 1.5)
				var texture = lfo1 * lfo2 * 0.3
				texture += (randf() - 0.5) * 0.05 * (1.0 - abs(lfo1))  # Subtle noise
				var env = sin(PI * progress)  # Smooth arc
				chord_mix[j] += texture * env * 0.1
		
		# MINIMAL KICK - Soft, sidechaining kick
		if "minimal_kick" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			for beat in range(_idiv(samples_per_chord, beat_samples) + 1):
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.15), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick = sin(2.0 * PI * (40.0 + exp(-kt * 20.0) * 40.0) * kt) * exp(-kt * 6.0)
					if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.35
		
		# ARP - Slow evolving arpeggio
		if "arp" in instruments:
			var eighth = _idiv(samples_per_chord, 8)
			for step in range(8):
				var note_idx = step % chord_freqs.size()
				var arp_freq = chord_freqs[note_idx]
				var start = step * eighth
				for j in range(min(eighth, samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					var arp = sin(2.0 * PI * arp_freq * t) * exp(-t * 3.0)
					if start + j < samples_per_chord: chord_mix[start + j] += arp * 0.1
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# BLADE RUNNER - Vangelis style: Juno saw, high resonance, velocity-sensitive
# Lush keys with ensemble chorus and plate reverb feel
# ============================================================================
static func generate_blade_runner_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("blade_runner", parameters)
	randomize()
	var bpm = 70.0  # Slow cinematic tempo
	var bar_duration = 240.0 / bpm
	var root_note = PopMusicTheory.NOTES[randi() % PopMusicTheory.NOTES.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	print("AudioSynthesizer: Generating Blade Runner in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	var intro = _generate_blade_runner_section(progression, scale, ["vangelis_keys"], bar_duration)
	playback.set_clip_stream(0, intro); playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(0, 1)
	
	var theme = _generate_blade_runner_section(progression, scale, ["vangelis_keys", "string_pad", "bass_pulse"], bar_duration)
	playback.set_clip_stream(1, theme); playback.set_clip_name(1, "Theme")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(1, 2)
	
	var climax = _generate_blade_runner_section(progression, scale, ["vangelis_keys", "string_pad", "bass_pulse", "lead"], bar_duration)
	playback.set_clip_stream(2, climax); playback.set_clip_name(2, "Climax")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(2, 3)
	
	var outro = _generate_blade_runner_section(progression, scale, ["string_pad", "vangelis_keys"], bar_duration)
	playback.set_clip_stream(3, outro); playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED); playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 2.5
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	return playback


static func _generate_blade_runner_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var _bpm = 70.0
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# VANGELIS KEYS - Juno saw with high resonance (from research)
		if "vangelis_keys" in instruments:
			var note_times = [0, int(samples_per_chord * 0.25), int(samples_per_chord * 0.5), int(samples_per_chord * 0.75)]
			for n in range(note_times.size()):
				var start = note_times[n]
				var note_freq = chord_freqs[n % chord_freqs.size()]
				for j in range(min(int(SAMPLE_RATE * 1.5), samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					# Saw with high resonance filter simulation
					var saw = fmod(t * note_freq, 1.0) * 2.0 - 1.0
					var resonance = sin(2.0 * PI * note_freq * 1.5 * t) * 0.3 * exp(-t * 2.0)
					var key = (saw + resonance) * 0.5
					# Plucky envelope (short decay from research)
					var env = exp(-t * 2.5)
					# Ensemble chorus simulation
					var chorus = sin(2.0 * PI * note_freq * 1.003 * t) * 0.2 * env
					if start + j < samples_per_chord: chord_mix[start + j] += (key * env + chorus) * 0.25
		
		# STRING PAD - Lush evolving strings
		if "string_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var strings = 0.0
				for freq in chord_freqs:
					# Multiple detuned oscillators for ensemble
					strings += sin(2.0 * PI * freq * t)
					strings += sin(2.0 * PI * freq * 1.002 * t) * 0.7
					strings += sin(2.0 * PI * freq * 0.998 * t) * 0.7
				strings /= chord_freqs.size() * 2.4
				var env = 1.0
				if progress < 0.3: env = progress / 0.3
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				chord_mix[j] += strings * env * 0.2
		
		# BASS PULSE - Deep pulsing bass
		if "bass_pulse" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var pulse = sin(2.0 * PI * 0.5 * t)  # Slow pulse
				var bass = sin(2.0 * PI * root_freq * 0.25 * t)
				bass *= 0.5 + pulse * 0.3
				chord_mix[j] += bass * 0.3
		
		# LEAD - Soaring expressive lead
		if "lead" in instruments:
			var lead_freq = chord_freqs[0] * 2.0
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				# Vibrato
				var vibrato = sin(2.0 * PI * 5.0 * t) * 0.01
				var lead = sin(2.0 * PI * lead_freq * (1.0 + vibrato) * t)
				var env = sin(PI * progress)  # Arc envelope
				chord_mix[j] += lead * env * 0.15
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


static func _generate_prog_section_stream(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	# Generate one section of the prog track
	var total_duration = progression.size() * bar_duration * 2  # Double bars for prog feel
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# MOOG PAD - Warm detuned oscillators
		if "moog_pad" in instruments:
			var data = PackedFloat32Array()
			data.resize(samples_per_chord)
			_generate_moog_warm_pad(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.5)
		
		# MOOG BASS - Fat Minimoog bass with filter envelope
		if "moog_bass" in instruments:
			var data = PackedFloat32Array()
			data.resize(samples_per_chord)
			_generate_minimoog_fat_bass(data, samples_per_chord, root_freq * 0.5)
			_mix_into(chord_mix, data, 0.7)
		
		# KRAFTWERK SEQUENCE - 8-note arpeggio pattern
		if "kraftwerk_seq" in instruments:
			var data = PackedFloat32Array()
			data.resize(samples_per_chord)
			_generate_kraftwerk_sequence(data, samples_per_chord, chord_freqs, scale)
			_mix_into(chord_mix, data, 0.4)
		
		# ELP LEAD - Screaming Moog with portamento
		if "elp_lead" in instruments:
			var data = PackedFloat32Array()
			data.resize(samples_per_chord)
			_generate_elp_moog_lead(data, samples_per_chord, chord_freqs, scale)
			_mix_into(chord_mix, data, 0.5)
		
		# MOTORIK DRUMS - Kraftwerk/Neu! style driving beat
		if "motorik_drums" in instruments:
			var data = PackedFloat32Array()
			data.resize(samples_per_chord)
			_generate_motorik_beat(data, samples_per_chord)
			_mix_into(chord_mix, data, 0.6)
		
		# Mix into final buffer
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				if is_nan(sample) or is_inf(sample):
					sample = 0.0
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix)

# === PROG SYNTH INSTRUMENT GENERATORS ===

static func _generate_moog_warm_pad(data: PackedFloat32Array, sample_count: int, chord_freqs: Array):
	# Classic Moog pad: 3 detuned oscillators per note, slow filter movement
	# Inspired by the "accidental warmth" of unstable Minimoog oscillators
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		var output = 0.0
		
		# Slow attack envelope
		var env = 1.0
		if progress < 0.15:
			env = progress / 0.15
		elif progress > 0.85:
			env = (1.0 - progress) / 0.15
		
		for freq in chord_freqs:
			# Three slightly detuned oscillators (the Moog "warmth")
			var detune = [0.995, 1.0, 1.007]
			for d in detune:
				var f = freq * d
				# Slow LFO on pitch (subtle vibrato)
				f *= 1.0 + sin(2.0 * PI * 0.15 * t) * 0.003
				# Sawtooth oscillator
				var phase = fmod(t * f, 1.0)
				var saw = 2.0 * phase - 1.0
				output += saw / (chord_freqs.size() * 3.0)
		
		# Moog-style lowpass filter with slow modulation
		var filter_mod = sin(2.0 * PI * 0.08 * t) * 0.3 + 0.7
		# Simple lowpass approximation (will smooth out harshness)
		output = tanh(output * filter_mod * 1.2) * 0.6
		
		data[i] = output * env * 0.5

static func _generate_minimoog_fat_bass(data: PackedFloat32Array, sample_count: int, freq: float):
	# Classic Minimoog bass: saw + saw (detuned) + sub square
	# Fast filter envelope attack, slower decay
	
	var filter_state = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Oscillator 1: Sawtooth
		var phase1 = fmod(t * freq, 1.0)
		var osc1 = 2.0 * phase1 - 1.0
		
		# Oscillator 2: Sawtooth slightly detuned
		var phase2 = fmod(t * freq * 0.998, 1.0)
		var osc2 = 2.0 * phase2 - 1.0
		
		# Oscillator 3: Sub square one octave down
		var phase3 = fmod(t * freq * 0.5, 1.0)
		var osc3 = 1.0 if phase3 < 0.5 else -1.0
		
		var mix = osc1 * 0.4 + osc2 * 0.35 + osc3 * 0.3
		
		# Filter envelope: fast attack, medium decay
		var filter_env = exp(-progress * 6.0)
		var cutoff_norm = 0.15 + filter_env * 0.4  # 0.15 to 0.55
		
		# Simple 1-pole lowpass (repeated for steeper rolloff)
		filter_state += cutoff_norm * (mix - filter_state)
		var filtered = filter_state
		filter_state += cutoff_norm * (filtered - filter_state)
		filtered = filter_state
		
		# Amp envelope
		var amp_env = 1.0
		if progress < 0.01:
			amp_env = progress / 0.01
		elif progress > 0.7:
			amp_env = (1.0 - progress) / 0.3
		
		# Soft saturation (the Moog "warmth")
		filtered = tanh(filtered * 1.8)
		
		data[i] = filtered * amp_env * 0.7

static func _generate_kraftwerk_sequence(data: PackedFloat32Array, sample_count: int, chord_freqs: Array, scale: Array):
	# Kraftwerk "Autobahn" style: 8-note sequence, square wave, filter modulation
	# Based on the 8-note Synthi AKS technique from Pink Floyd's "On the Run"
	
	# Build an 8-note sequence from the scale
	var seq_notes: Array[float] = []
	var root = chord_freqs[0]
	# Arpeggio pattern: root, 3rd, 5th, octave(root*2), 5th, 3rd, root, 6th
	var degrees = [0, 2, 4, 0, 4, 2, 0, 5]  # Using 0-6 (scale has 7 notes)
	for idx in range(degrees.size()):
		var deg = degrees[idx]
		var freq = PopMusicTheory.get_freq(scale[deg])
		# Octave up for the 4th note (index 3)
		if idx == 3:
			freq *= 2.0
		seq_notes.append(freq)
	
	var notes_per_bar = 16  # 16th notes
	var samples_per_note = _idiv(sample_count, notes_per_bar)
	var filter_state = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_idx = _idiv(i, samples_per_note) % seq_notes.size()
		var freq = seq_notes[note_idx]
		
		# Square wave oscillator
		var phase = fmod(t * freq, 1.0)
		var osc = 1.0 if phase < 0.5 else -1.0
		
		# Note envelope (slight decay per note for rhythmic feel)
		var note_progress = fmod(float(i), samples_per_note) / samples_per_note
		var note_env = exp(-note_progress * 3.0)
		
		osc *= note_env
		
		# Filter with slow sweep (like Kraftwerk's evolving textures)
		var filter_sweep = sin(2.0 * PI * 0.1 * t) * 0.2 + 0.35
		filter_state += filter_sweep * (osc - filter_state)
		var filtered = filter_state
		
		# Overall envelope
		var progress = float(i) / sample_count
		var env = 1.0
		if progress < 0.05:
			env = progress / 0.05
		elif progress > 0.9:
			env = (1.0 - progress) / 0.1
		
		data[i] = filtered * env * 0.5

static func _generate_elp_moog_lead(data: PackedFloat32Array, sample_count: int, chord_freqs: Array, scale: Array):
	# Keith Emerson "Lucky Man" style: screaming lead with portamento
	# High resonance filter, pitch glides between notes
	
	# Create a melodic phrase from the scale
	var melody: Array[float] = []
	for j in range(8):
		var note_idx = (randi() % 5) + 2  # Upper part of scale
		if note_idx < scale.size():
			melody.append(PopMusicTheory.get_freq(scale[note_idx]) * 2.0)  # Octave up
		else:
			melody.append(chord_freqs[0] * 2.0)
	
	var notes_per_section = 4
	var samples_per_note = _idiv(sample_count, notes_per_section)
	
	var current_freq = melody[0]
	var target_freq = melody[0]
	var filter_state1 = 0.0
	var filter_state2 = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_idx = _idiv(i, samples_per_note) % melody.size()
		target_freq = melody[note_idx]
		
		# PORTAMENTO - the signature ELP glide
		var glide_speed = 0.0008  # Slow glide
		current_freq = current_freq + (target_freq - current_freq) * glide_speed
		
		# Sawtooth + pulse for that cutting lead tone
		var phase_saw = fmod(t * current_freq, 1.0)
		var saw = 2.0 * phase_saw - 1.0
		
		var phase_pulse = fmod(t * current_freq, 1.0)
		var pulse = 1.0 if phase_pulse < 0.3 else -1.0  # 30% pulse width
		
		var mix = saw * 0.6 + pulse * 0.4
		
		# High resonance filter (the "screaming" quality)
		var cutoff = 0.25 + sin(2.0 * PI * 5.0 * t) * 0.1  # Fast vibrato on filter
		
		# 2-pole with resonance approximation
		var resonance = 0.7
		var feedback = filter_state2 * resonance * 3.5
		filter_state1 += cutoff * (mix - filter_state1 - feedback)
		filter_state2 += cutoff * (filter_state1 - filter_state2)
		var filtered = filter_state2
		
		# Drive it hard (Emerson pushed his Moog)
		filtered = tanh(filtered * 2.5)
		
		# Envelope
		var progress = float(i) / sample_count
		var env = 1.0
		if progress < 0.02:
			env = progress / 0.02
		elif progress > 0.85:
			env = (1.0 - progress) / 0.15
		
		data[i] = filtered * env * 0.55

static func _generate_motorik_beat(data: PackedFloat32Array, sample_count: int):
	# Kraftwerk/Neu! "motorik" beat: steady 4/4, driving hi-hats
	# Kick on 1 and 3, snare on 2 and 4, constant 8th note hats
	
	var bpm = 110.0
	var samples_per_beat = int(SAMPLE_RATE * 60.0 / bpm)
	var samples_per_8th = _idiv(samples_per_beat, 2)
	
	for i in range(sample_count):
		var _t = float(i) / SAMPLE_RATE
		var beat_in_bar = _idiv(i, samples_per_beat) % 4
		var pos_in_beat = i % samples_per_beat
		var pos_in_8th = i % samples_per_8th
		
		var output = 0.0
		
		# KICK on beats 1 and 3
		if beat_in_bar == 0 or beat_in_bar == 2:
			if pos_in_beat < int(SAMPLE_RATE * 0.15):
				var kick_t = float(pos_in_beat) / SAMPLE_RATE
				var kick_env = exp(-kick_t * 25.0)
				var kick_pitch = 55.0 + exp(-kick_t * 40.0) * 80.0  # Pitch drop
				output += sin(2.0 * PI * kick_pitch * kick_t) * kick_env * 0.8
		
		# SNARE on beats 2 and 4
		if beat_in_bar == 1 or beat_in_bar == 3:
			if pos_in_beat < int(SAMPLE_RATE * 0.12):
				var snare_t = float(pos_in_beat) / SAMPLE_RATE
				var snare_env = exp(-snare_t * 20.0)
				# Body (pitched)
				output += sin(2.0 * PI * 180.0 * snare_t) * snare_env * 0.3
				# Noise (snares)
				output += (randf() - 0.5) * snare_env * 0.5
		
		# HI-HAT on every 8th note
		if pos_in_8th < int(SAMPLE_RATE * 0.04):
			var hat_t = float(pos_in_8th) / SAMPLE_RATE
			var hat_env = exp(-hat_t * 80.0)
			# Metallic noise
			var hat_noise = (randf() - 0.5)
			# High-pass approximation (just use the noise, it's mostly high freq)
			output += hat_noise * hat_env * 0.25
		
		data[i] = clampf(output, -1.0, 1.0)

static func _generate_ambient_section_stream(progression: Array, scale: Array, instruments: Array, bar_duration: float, panning: String = "center") -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2 # Double length bars for slower feel
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# INSTRUMENTS
		
		if "pad" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_warm_juno_pad(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.6)
			
		if "keys" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_tape_drift_keys(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.5)
			
		if "bass" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_acid_bass_sub(data, samples_per_chord, root_freq)
			_mix_into(chord_mix, data, 0.7)
			
		if "drums" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_lofi_breakbeat(data, samples_per_chord)
			_mix_into(chord_mix, data, 0.8)
			
		if "noise" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_tape_hiss(data, samples_per_chord)
			_mix_into(chord_mix, data, 0.15) # Subtle background texture

		# Mix into final buffer
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				# Sanitize NaN/Inf values that would kill audio
				if is_nan(sample) or is_inf(sample):
					sample = 0.0
				# Clamp to prevent clipping
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)

	# Anti-Pop Fade (10ms fade in/out)
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))

	if panning == "right_to_left":
		# Create stereo mix with panning (Right -> Left)
		var stereo_mix = PackedFloat32Array()
		stereo_mix.resize(total_samples * 2)
		
		for i in range(total_samples):
			var t_prog = float(i) / float(total_samples)
			var pan_l = t_prog        # 0.0 -> 1.0 (Left channel gain)
			var pan_r = 1.0 - t_prog  # 1.0 -> 0.0 (Right channel gain)
			
			var mono_sample = final_mix[i]
			stereo_mix[i * 2] = mono_sample * pan_l     # Left
			stereo_mix[i * 2 + 1] = mono_sample * pan_r # Right
			
		return _create_stereo_audio_stream(stereo_mix, AudioStreamWAV.LOOP_DISABLED)
	else:
		# Center panning: Duplicate mono to L/R for consistent Stereo output
		var stereo_mix = PackedFloat32Array()
		stereo_mix.resize(total_samples * 2)
		
		for i in range(total_samples):
			var sample = final_mix[i]
			stereo_mix[i * 2] = sample      # Left
			stereo_mix[i * 2 + 1] = sample  # Right
			
		return _create_stereo_audio_stream(stereo_mix, AudioStreamWAV.LOOP_DISABLED)


# === BOARDS OF CANADA ===
# Lo-fi, nostalgic, tape-warped Scottish duo sound
static func generate_boards_of_canada_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("boards_of_canada", parameters)
	randomize()
	var bpm = 100.0  # BoC typical tempo
	var bar_duration = 240.0 / bpm
	
	var root_note = ["C", "D", "F", "G"][randi() % 4] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Boards of Canada in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 3
	playback.initial_clip = 0
	
	# Intro: Warbly pad + texture
	var intro = _generate_boc_section(progression, scale, ["warbly_pad", "texture"], bar_duration)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Main: Full arrangement
	var main = _generate_boc_section(progression, scale, ["warbly_pad", "melody", "bass", "drums", "texture"], bar_duration)
	playback.set_clip_stream(1, main)
	playback.set_clip_name(1, "Main")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Outro: Fade out
	var outro = _generate_boc_section(progression, scale, ["warbly_pad", "texture"], bar_duration)
	playback.set_clip_stream(2, outro)
	playback.set_clip_name(2, "Outro")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 0)
	
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 3.0)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 3.0)
	playback.add_transition(2, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 3.0)
	
	return playback


static func _generate_boc_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# WARBLY PAD - Tape-degraded, drifting
		if "warbly_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				for freq in chord_freqs:
					# Heavy pitch drift (tape wow)
					var drift = sin(2.0 * PI * 0.15 * t + freq * 0.01) * 0.02
					var drift2 = sin(2.0 * PI * 0.08 * t) * 0.015
					var drifted_freq = freq * (1.0 + drift + drift2)
					# Multiple detuned voices
					pad += sin(2.0 * PI * drifted_freq * t)
					pad += sin(2.0 * PI * drifted_freq * 1.008 * t) * 0.6
					pad += sin(2.0 * PI * drifted_freq * 0.992 * t) * 0.6
				pad /= chord_freqs.size() * 2.2
				# Slow attack, warm filter simulation (reduce highs)
				var env = 1.0
				if progress < 0.15: env = progress / 0.15
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				# Add subtle "tape hiss" via filtered noise
				var hiss = (randf() - 0.5) * 0.02
				chord_mix[j] += (pad * env + hiss) * 0.25
		
		# MELODIC SEQUENCE - Simple, detuned, nostalgic
		if "melody" in instruments:
			var note_length = _idiv(samples_per_chord, 8)
			var melody_notes = [0, 2, 4, 2, 0, -1, 0, 2]  # Simple pattern
			for n in range(8):
				var start = n * note_length
				var note_offset = melody_notes[n]
				var note_freq = chord_freqs[0] * pow(2.0, note_offset / 12.0) * 2.0
				for j in range(note_length):
					var t = float(j) / SAMPLE_RATE
					# Pitch drift
					var drift = sin(2.0 * PI * 0.2 * t + n) * 0.01
					var freq = note_freq * (1.0 + drift)
					var mel = sin(2.0 * PI * freq * t)
					mel += sin(2.0 * PI * freq * 2.01 * t) * 0.3  # Slightly detuned harmonic
					# Plucky envelope with long tail
					var env = exp(-t * 3.0) * 0.7 + exp(-t * 0.8) * 0.3
					if start + j < samples_per_chord: chord_mix[start + j] += mel * env * 0.15
		
		# BASS - Warm, simple sub
		if "bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var bass_freq = root_freq * 0.5
				var drift = sin(2.0 * PI * 0.1 * t) * 0.008
				var bass = sin(2.0 * PI * bass_freq * (1.0 + drift) * t)
				bass += sin(2.0 * PI * bass_freq * 2.0 * t) * 0.3  # Warm harmonic
				var env = 1.0 - exp(-t * 8.0)  # Slow attack
				if progress > 0.9: env *= (1.0 - progress) / 0.1
				chord_mix[j] += bass * env * 0.35
		
		# DRUMS - Lo-fi hip-hop style
		if "drums" in instruments:
			var beat_samples = _idiv(samples_per_chord, 8)
			for beat in range(8):
				var start = beat * beat_samples
				# Kick on 1 and 5
				if beat == 0 or beat == 4:
					for j in range(min(int(SAMPLE_RATE * 0.15), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var kick_freq = 55.0 * exp(-t * 20.0) + 40.0
						var kick = sin(2.0 * PI * kick_freq * t) * exp(-t * 12.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.4
				# Snare on 3 and 7
				if beat == 2 or beat == 6:
					for j in range(min(int(SAMPLE_RATE * 0.12), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var snare = (randf() - 0.5) * exp(-t * 15.0)
						snare += sin(2.0 * PI * 180.0 * t) * exp(-t * 25.0) * 0.5
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.25
				# Hi-hat (lo-fi filtered)
				if beat % 2 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.05), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-t * 40.0) * 0.15
						if start + j < samples_per_chord: chord_mix[start + j] += hat
		
		# TEXTURE - Tape noise, vinyl crackle simulation
		if "texture" in instruments:
			for j in range(samples_per_chord):
				var noise = (randf() - 0.5) * 0.015
				# Occasional crackle
				if randf() < 0.001:
					noise += (randf() - 0.5) * 0.1
				chord_mix[j] += noise
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === BURIAL ===
# Dark UK garage, vinyl atmosphere, pitched vocals
static func generate_burial_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("burial", parameters)
	randomize()
	var bpm = 130.0  # UK garage tempo
	var bar_duration = 240.0 / bpm
	
	var root_note = ["D", "E", "G", "A"][randi() % 4] + "2"  # Dark, low
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Burial in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 3
	playback.initial_clip = 0
	
	# Intro: Atmosphere + crackle
	var intro = _generate_burial_section(progression, scale, ["atmosphere", "crackle"], bar_duration)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Main: Full 2-step
	var main = _generate_burial_section(progression, scale, ["atmosphere", "sub_bass", "garage_stab", "drums", "crackle"], bar_duration)
	playback.set_clip_stream(1, main)
	playback.set_clip_name(1, "Main")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Outro
	var outro = _generate_burial_section(progression, scale, ["atmosphere", "crackle"], bar_duration)
	playback.set_clip_stream(2, outro)
	playback.set_clip_name(2, "Outro")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 0)
	
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 4.0)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 4.0)
	playback.add_transition(2, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 4.0)
	
	return playback


static func _generate_burial_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# ATMOSPHERE PAD - Dark, reverb-drenched
		if "atmosphere" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var atmos = 0.0
				for freq in chord_freqs:
					# Dark, filtered pad
					atmos += sin(2.0 * PI * freq * t)
					atmos += sin(2.0 * PI * freq * 0.5 * t) * 0.5  # Sub octave
				atmos /= chord_freqs.size() * 1.5
				# Very slow envelope (huge reverb simulation)
				var env = 1.0
				if progress < 0.25: env = progress / 0.25
				elif progress > 0.7: env = (1.0 - progress) / 0.3
				# Simulate reverb tail with decay
				var reverb_sim = sin(2.0 * PI * chord_freqs[0] * 0.5 * t) * exp(-t * 0.3) * 0.2
				chord_mix[j] += (atmos * env + reverb_sim) * 0.2
		
		# SUB BASS - UK garage style, mono
		if "sub_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var sub_freq = root_freq * 0.5
				var sub = sin(2.0 * PI * sub_freq * t)
				# Slight movement
				sub += sin(2.0 * PI * sub_freq * 2.0 * t) * 0.15 * exp(-t * 2.0)
				var env = 1.0
				if progress < 0.02: env = progress / 0.02
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				chord_mix[j] += sub * env * 0.45
		
		# GARAGE STAB - Organ-like
		if "garage_stab" in instruments:
			var stab_times = [0, int(samples_per_chord * 0.35), int(samples_per_chord * 0.7)]
			for st in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.15), samples_per_chord - st)):
					var t = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs:
						stab += sin(2.0 * PI * freq * 2.0 * t)
					stab /= chord_freqs.size()
					var env = exp(-t * 8.0)
					if st + j < samples_per_chord: chord_mix[st + j] += stab * env * 0.12
		
		# DRUMS - 2-step shuffled garage
		if "drums" in instruments:
			var beat_samples = _idiv(samples_per_chord, 16)  # 16th notes
			for beat in range(16):
				var start = beat * beat_samples
				# Kick: offbeat pattern (not on 1)
				if beat == 2 or beat == 6 or beat == 10 or beat == 14:
					for j in range(min(int(SAMPLE_RATE * 0.1), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var kick_freq = 50.0 * exp(-t * 25.0) + 35.0
						var kick = sin(2.0 * PI * kick_freq * t) * exp(-t * 15.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.5
				# Snare/clap: 4 and 12
				if beat == 4 or beat == 12:
					for j in range(min(int(SAMPLE_RATE * 0.08), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var clap = (randf() - 0.5) * exp(-t * 20.0)
						if start + j < samples_per_chord: chord_mix[start + j] += clap * 0.2
				# Hi-hats: shuffled
				if beat % 2 == 1 or beat % 4 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.03), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-t * 50.0) * 0.08
						if start + j < samples_per_chord: chord_mix[start + j] += hat
		
		# CRACKLE - Vinyl noise
		if "crackle" in instruments:
			for j in range(samples_per_chord):
				var crackle = 0.0
				# Constant low hiss
				crackle += (randf() - 0.5) * 0.008
				# Random pops and crackles
				if randf() < 0.003:
					crackle += (randf() - 0.5) * 0.15
				if randf() < 0.0005:
					crackle += (randf() - 0.5) * 0.3  # Bigger pop
				chord_mix[j] += crackle
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === KRAFTWERK ===
# German electronic pioneers - precise, mechanical, clean
static func generate_kraftwerk_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("kraftwerk", parameters)
	randomize()
	var bpm = 110.0  # Kraftwerk typical tempo
	var bar_duration = 240.0 / bpm
	
	var root_note = ["C", "D", "E", "G"][randi() % 4] + "3"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)  # Often major/bright

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Kraftwerk in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 3
	playback.initial_clip = 0
	
	# Intro: Sequence + bass
	var intro = _generate_kraftwerk_section(progression, scale, ["sequence", "moog_bass"], bar_duration)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Main: Full arrangement
	var main = _generate_kraftwerk_section(progression, scale, ["sequence", "moog_bass", "vocoder_pad", "lead", "drums"], bar_duration)
	playback.set_clip_stream(1, main)
	playback.set_clip_name(1, "Main")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Outro
	var outro = _generate_kraftwerk_section(progression, scale, ["sequence", "vocoder_pad"], bar_duration)
	playback.set_clip_stream(2, outro)
	playback.set_clip_name(2, "Outro")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 0)
	
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	playback.add_transition(2, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 2.0)
	
	return playback


static func _generate_kraftwerk_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array(); final_mix.resize(total_samples); final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array(); chord_mix.resize(samples_per_chord); chord_mix.fill(0.0)
		
		# SEQUENCER LINE - Precise, repetitive 16th notes
		if "sequence" in instruments:
			var note_length = _idiv(samples_per_chord, 16)
			var seq_pattern = [0, 0, 7, 0, 0, 0, 7, 0, 0, 0, 7, 0, 5, 0, 7, 0]  # Simple pattern
			for n in range(16):
				var start = n * note_length
				var note_offset = seq_pattern[n]
				if note_offset >= 0:
					var note_freq = chord_freqs[0] * pow(2.0, note_offset / 12.0)
					for j in range(note_length):
						var t = float(j) / SAMPLE_RATE
						# Clean sawtooth
						var saw = fmod(t * note_freq, 1.0) * 2.0 - 1.0
						# Resonant filter simulation
						var filtered = saw * 0.7 + sin(2.0 * PI * note_freq * 1.5 * t) * 0.3
						# Short, precise envelope
						var env = exp(-t * 12.0)
						if start + j < samples_per_chord: chord_mix[start + j] += filtered * env * 0.18
		
		# MOOG BASS - Clean Minimoog bass
		if "moog_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var bass_freq = root_freq * 0.5
				# Saw + square mix (Minimoog character)
				var saw = fmod(t * bass_freq, 1.0) * 2.0 - 1.0
				var square = sign(sin(2.0 * PI * bass_freq * t))
				var bass = saw * 0.6 + square * 0.4
				# Filter envelope
				var filter_env = exp(-t * 3.0)
				bass *= 0.5 + filter_env * 0.5  # Simulate filter closing
				var env = 1.0
				if progress < 0.01: env = progress / 0.01
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				chord_mix[j] += bass * env * 0.3
		
		# VOCODER PAD - Robot voice simulation
		if "vocoder_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var vocoder = 0.0
				for freq in chord_freqs:
					# Multiple formant-like bands
					vocoder += sin(2.0 * PI * freq * t) * 0.5
					vocoder += sin(2.0 * PI * freq * 2.0 * t) * 0.3
					vocoder += sin(2.0 * PI * freq * 3.0 * t) * 0.2
				vocoder /= chord_freqs.size() * 1.0
				# Slow amplitude modulation (breathing)
				var mod = sin(2.0 * PI * 0.5 * t) * 0.2 + 0.8
				var env = 1.0
				if progress < 0.1: env = progress / 0.1
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				chord_mix[j] += vocoder * mod * env * 0.15
		
		# LEAD - Simple Moog melody with subtle vibrato
		if "lead" in instruments:
			var lead_pattern = [0, 0, 2, 0, 4, 0, 2, 0]  # Simple melody
			var note_length = _idiv(samples_per_chord, 8)
			for n in range(8):
				var start = n * note_length
				var note_offset = lead_pattern[n]
				var lead_freq = chord_freqs[0] * 2.0 * pow(2.0, note_offset / 12.0)
				for j in range(note_length):
					var t = float(j) / SAMPLE_RATE
					# Subtle vibrato (comes in late)
					var vib_amount = clamp((float(j) / note_length - 0.3) * 2.0, 0.0, 1.0)
					var vibrato = sin(2.0 * PI * 5.0 * t) * 0.008 * vib_amount
					var lead = sin(2.0 * PI * lead_freq * (1.0 + vibrato) * t)
					var env = 1.0 - exp(-t * 15.0)  # Quick attack
					env *= exp(-t * 2.0) * 0.3 + 0.7  # Slight decay to sustain
					if t > (note_length / SAMPLE_RATE) * 0.8: env *= 1.0 - (t - (note_length / SAMPLE_RATE) * 0.8) / ((note_length / SAMPLE_RATE) * 0.2)
					if start + j < samples_per_chord: chord_mix[start + j] += lead * env * 0.12
		
		# DRUMS - Electronic, precise (TR-808 style)
		if "drums" in instruments:
			var beat_samples = _idiv(samples_per_chord, 8)
			for beat in range(8):
				var start = beat * beat_samples
				# Kick on 1, 3, 5, 7 (four on floor)
				if beat % 2 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.12), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var kick_freq = 60.0 * exp(-t * 30.0) + 45.0
						var kick = sin(2.0 * PI * kick_freq * t) * exp(-t * 10.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.35
				# Snare on 2 and 6
				if beat == 2 or beat == 6:
					for j in range(min(int(SAMPLE_RATE * 0.1), beat_samples)):
						var t = float(j) / SAMPLE_RATE
						var snare = sin(2.0 * PI * 200.0 * t) * exp(-t * 20.0) * 0.4
						snare += (randf() - 0.5) * exp(-t * 25.0) * 0.4
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.2
				# Hi-hat on every beat
				for j in range(min(int(SAMPLE_RATE * 0.04), beat_samples)):
					var t = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-t * 60.0) * 0.1
					if start + j < samples_per_chord: chord_mix[start + j] += hat
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples: final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# ============================================================================
# V2 ENHANCED TRACKS - Based on deep research from music_tracks/*.md
# These versions incorporate more accurate synthesis techniques
# ============================================================================

# === BOARDS OF CANADA V2 ===
# Enhanced with research: 15-cent detune, 0.15Hz LFO, bit crushing, dotted delay
static func generate_boards_of_canada_v2_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("boards_of_canada_v2", parameters)
	randomize()
	var bpm = 95.0  # Slightly slower, more hypnotic
	var bar_duration = 240.0 / bpm
	
	var root_note = ["C", "D", "E", "G"][randi() % 4] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Boards of Canada V2 in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	# Intro: Warbly pad fading in with texture
	var intro = _generate_boc_v2_section(progression, scale, ["warbly_pad", "texture"], bar_duration, bpm)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Build: Add melody and bass
	var build = _generate_boc_v2_section(progression, scale, ["warbly_pad", "melody", "warm_bass", "texture"], bar_duration, bpm)
	playback.set_clip_stream(1, build)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Main: Full lo-fi groove with drums
	var main = _generate_boc_v2_section(progression, scale, ["warbly_pad", "melody", "warm_bass", "lofi_drums", "texture"], bar_duration, bpm)
	playback.set_clip_stream(2, main)
	playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# Outro: Fade to texture
	var outro = _generate_boc_v2_section(progression, scale, ["warbly_pad", "texture"], bar_duration, bpm)
	playback.set_clip_stream(3, outro)
	playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 4.0  # Long crossfades for dreamy feel
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_boc_v2_section(progression: Array, scale: Array, instruments: Array, bar_duration: float, _bpm: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	# Pre-generate delay buffer for dotted eighth delay
	var delay_time = 0.333  # Dotted eighth at ~90 BPM
	var delay_samples = int(delay_time * SAMPLE_RATE)
	var delay_buffer = PackedFloat32Array()
	delay_buffer.resize(delay_samples)
	delay_buffer.fill(0.0)
	var delay_write_pos = 0
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# WARBLY PAD - Research: 15-cent detune, 0.15Hz LFO, high shelf cut
		if "warbly_pad" in instruments:
			var detune_cents = 15.0  # From research
			var lfo_rate = 0.15  # Very slow LFO from research
			var lfo_depth = 0.08  # 8% pitch modulation
			
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				
				# Very slow LFO for tape wow/flutter
				var global_drift = sin(2.0 * PI * lfo_rate * t) * lfo_depth
				
				for freq in chord_freqs:
					# Apply drift + heavy detune (4 voices per note)
					var detune_ratio = pow(2.0, detune_cents / 1200.0)
					var drifted = freq * (1.0 + global_drift)
					
					# 4 detuned voices (research: heavy detune)
					pad += sin(2.0 * PI * drifted * t)
					pad += sin(2.0 * PI * drifted * detune_ratio * t) * 0.7
					pad += sin(2.0 * PI * drifted / detune_ratio * t) * 0.7
					pad += sin(2.0 * PI * drifted * 0.995 * t) * 0.5
				
				pad /= chord_freqs.size() * 2.9
				
				# Tape saturation (soft clip)
				pad = tanh(pad * 1.3)
				
				# Slow envelope
				var env = 1.0
				if progress < 0.2: env = progress / 0.2
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				
				# High shelf cut simulation (reduce brightness)
				# Simple approach: mix with slightly filtered version
				chord_mix[j] += pad * env * 0.28
		
		# MELODY - Dotted eighth delay, pitch drift, simple childlike melody
		if "melody" in instruments:
			var note_length = _idiv(samples_per_chord, 8)
			var melody_notes = [0, 0, 4, 0, 7, 4, 0, -3]  # Pentatonic-ish
			
			for n in range(8):
				var start = n * note_length
				var note_offset = melody_notes[n]
				var note_freq = chord_freqs[0] * 2.0 * pow(2.0, note_offset / 12.0)
				
				for j in range(note_length):
					var t = float(j) / SAMPLE_RATE
					
					# Pitch drift
					var drift = sin(2.0 * PI * 0.3 * t + n * 1.5) * 0.012
					var freq = note_freq * (1.0 + drift)
					
					# Simple sine with slight harmonic
					var mel = sin(2.0 * PI * freq * t)
					mel += sin(2.0 * PI * freq * 2.01 * t) * 0.25
					
					# Plucky with long decay
					var env = exp(-t * 4.0)
					
					# Tape saturation
					mel = tanh(mel * 1.2)
					
					var sample = mel * env * 0.12
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += sample
						# Write to delay buffer
						delay_buffer[delay_write_pos] = sample * 0.35  # Delay feedback
						delay_write_pos = (delay_write_pos + 1) % delay_samples
		
		# WARM BASS - Gentle, filtered
		if "warm_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var bass_freq = root_freq * 0.25  # Deep
				
				# Slight drift
				var drift = sin(2.0 * PI * 0.08 * t) * 0.006
				var bass = sin(2.0 * PI * bass_freq * (1.0 + drift) * t)
				
				# Warm harmonic
				bass += sin(2.0 * PI * bass_freq * 2.0 * t) * 0.25
				
				# Soft distortion
				bass = tanh(bass * 1.1)
				
				# Gentle envelope
				var env = 1.0
				if progress < 0.05: env = progress / 0.05
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				
				chord_mix[j] += bass * env * 0.3
		
		# LOFI DRUMS - Hip-hop influenced, humanized timing
		if "lofi_drums" in instruments:
			var beat_samples = _idiv(samples_per_chord, 8)
			
			for beat in range(8):
				# Humanize timing (ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±10ms)
				var timing_offset = int((randf() - 0.5) * SAMPLE_RATE * 0.01)
				var start = beat * beat_samples + timing_offset
				start = clampi(start, 0, samples_per_chord - 1)
				
				# Kick on 1, 5 (with slight variation)
				if beat == 0 or beat == 4:
					for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick_freq = 50.0 * exp(-kt * 18.0) + 38.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 10.0)
						# Bit crush simulation
						kick = floor(kick * 64.0) / 64.0
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.38
				
				# Snare on 3, 7
				if beat == 2 or beat == 6:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						var snare = (randf() - 0.5) * exp(-st * 12.0) * 0.6
						snare += sin(2.0 * PI * 170.0 * st) * exp(-st * 18.0) * 0.4
						# Bit crush
						snare = floor(snare * 48.0) / 48.0
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.22
				
				# Lo-fi hats
				if beat % 2 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.04), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 35.0) * 0.12
						# Heavy filtering
						hat *= 0.7
						if start + j < samples_per_chord: chord_mix[start + j] += hat
		
		# TEXTURE - Research: 10-bit crushing, tape noise
		if "texture" in instruments:
			for j in range(samples_per_chord):
				# Tape hiss (filtered noise)
				var hiss = (randf() - 0.5) * 0.012
				
				# Occasional crackle (VHS/cassette)
				if randf() < 0.002:
					hiss += (randf() - 0.5) * 0.08
				if randf() < 0.0003:
					hiss += (randf() - 0.5) * 0.2
				
				chord_mix[j] += hiss
		
		# Mix delay buffer into output
		for j in range(samples_per_chord):
			var delay_read_pos = (delay_write_pos + j) % delay_samples
			chord_mix[j] += delay_buffer[delay_read_pos] * 0.25
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				# Final bit crushing (10-bit from research)
				var sample = chord_mix[j]
				sample = floor(sample * 512.0) / 512.0  # ~10-bit
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.03))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === BURIAL V2 ===
# Enhanced with research: Sound Forge loose timing, vinyl crackle, 2-step garage patterns
static func generate_burial_v2_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("burial_v2", parameters)
	randomize()
	var bpm = 130.0
	var bar_duration = 240.0 / bpm
	
	var root_note = ["D", "E", "F", "G"][randi() % 4] + "2"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Burial V2 in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	# Intro: Rain, crackle, distant pad
	var intro = _generate_burial_v2_section(progression, scale, ["atmosphere", "crackle", "rain"], bar_duration, bpm)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Build: Add bass, stabs
	var build = _generate_burial_v2_section(progression, scale, ["atmosphere", "sub_bass", "garage_stab", "crackle", "rain"], bar_duration, bpm)
	playback.set_clip_stream(1, build)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Main: Full 2-step with vocals
	var main = _generate_burial_v2_section(progression, scale, ["atmosphere", "sub_bass", "garage_stab", "twostep_drums", "pitched_vocal", "crackle"], bar_duration, bpm)
	playback.set_clip_stream(2, main)
	playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# Outro: Fade to rain
	var outro = _generate_burial_v2_section(progression, scale, ["atmosphere", "crackle", "rain"], bar_duration, bpm)
	playback.set_clip_stream(3, outro)
	playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 5.0  # Long, atmospheric fades
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_burial_v2_section(progression: Array, scale: Array, instruments: Array, bar_duration: float, _bpm: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# ATMOSPHERE - Research: long reverb, dark, evolving
		if "atmosphere" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var atmos = 0.0
				
				for freq in chord_freqs:
					# Dark, filtered tones
					atmos += sin(2.0 * PI * freq * 0.5 * t) * 0.6  # Octave down
					atmos += sin(2.0 * PI * freq * t) * 0.4
				atmos /= chord_freqs.size()
				
				# Very long envelope (reverb tail simulation)
				var env = 1.0
				if progress < 0.3: env = progress / 0.3
				elif progress > 0.6: env = (1.0 - progress) / 0.4
				
				# Add phaser-like movement (cobwebs from research)
				var phaser = sin(2.0 * PI * 0.3 * t) * 0.15
				atmos *= (1.0 + phaser)
				
				chord_mix[j] += atmos * env * 0.18
		
		# SUB BASS - Research: "warm and earthy, like underground train"
		if "sub_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var sub_freq = root_freq * 0.25  # Very deep
				
				var sub = sin(2.0 * PI * sub_freq * t)
				
				# Warm harmonic layer
				sub += sin(2.0 * PI * sub_freq * 2.0 * t) * 0.2
				
				# "Distorted and heavy, yet warm"
				sub = tanh(sub * 1.4)
				
				# Gentle envelope
				var env = 1.0
				if progress < 0.02: env = progress / 0.02
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				
				chord_mix[j] += sub * env * 0.42
		
		# GARAGE STAB - Organ-like, reverb tail
		if "garage_stab" in instruments:
			# Offbeat placement (UK garage style)
			var stab_times = [
				int(samples_per_chord * 0.1),
				int(samples_per_chord * 0.4),
				int(samples_per_chord * 0.65)
			]
			
			for st in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.3), samples_per_chord - st)):
					var t = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs:
						# Organ-like harmonics
						stab += sin(2.0 * PI * freq * t)
						stab += sin(2.0 * PI * freq * 2.0 * t) * 0.5
						stab += sin(2.0 * PI * freq * 3.0 * t) * 0.25
					stab /= chord_freqs.size() * 1.75
					
					# Long reverb tail
					var env = exp(-t * 4.0) * 0.6 + exp(-t * 1.5) * 0.4
					
					if st + j < samples_per_chord: chord_mix[st + j] += stab * env * 0.1
		
		# TWO-STEP DRUMS - Research: "intuitively arranged, not quantized"
		if "twostep_drums" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			
			# 2-step pattern: kick avoids 1, shuffled timing
			var kick_steps = [2, 5, 10, 13]  # Offbeat kicks
			var snare_steps = [4, 12]
			var hat_steps = [0, 3, 6, 8, 11, 14]  # Shuffled
			
			for step in range(16):
				# Research: "minute hesitations and slippages"
				var timing_humanize = int((randf() - 0.5) * SAMPLE_RATE * 0.015)  # ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±15ms
				var start = step * sixteenth + timing_humanize
				start = clampi(start, 0, samples_per_chord - 1)
				
				if step in kick_steps:
					# Velocity variation
					var vel = 0.8 + randf() * 0.2
					for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick_freq = 48.0 * exp(-kt * 22.0) + 32.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 12.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.45 * vel
				
				if step in snare_steps:
					# "Snares covered in fuzz" from research
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						var snare = (randf() - 0.5) * exp(-st * 15.0)
						# Add "fuzz" via waveshaping
						snare = tanh(snare * 2.0) * 0.5
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.18
				
				if step in hat_steps:
					# "Covered in fuzz and phaser"
					for j in range(min(int(SAMPLE_RATE * 0.025), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 45.0)
						# Phaser simulation
						hat *= sin(2.0 * PI * 2000.0 * ht + sin(ht * 10.0) * 3.0)
						if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.08
		
		# PITCHED VOCAL - Research: "pitch-shifted voices", ghostly
		if "pitched_vocal" in instruments:
			# Simulate pitched-down vocal sample
			var vocal_start = int(samples_per_chord * 0.3)
			var vocal_length = int(SAMPLE_RATE * 0.8)
			
			for j in range(min(vocal_length, samples_per_chord - vocal_start)):
				var t = float(j) / SAMPLE_RATE
				
				# Formant-like simulation (pitched down)
				var formant1 = sin(2.0 * PI * 300.0 * t)  # Lower formant
				var formant2 = sin(2.0 * PI * 700.0 * t) * 0.5
				var formant3 = sin(2.0 * PI * 1200.0 * t) * 0.25
				
				var vocal = formant1 + formant2 + formant3
				vocal *= sin(2.0 * PI * chord_freqs[0] * 0.5 * t)  # Carrier
				
				# Timestretched artifacts (slow amplitude modulation)
				vocal *= sin(2.0 * PI * 0.8 * t) * 0.3 + 0.7
				
				# Heavy reverb
				var env = exp(-t * 1.5)
				
				if vocal_start + j < samples_per_chord:
					chord_mix[vocal_start + j] += vocal * env * 0.06
		
		# CRACKLE - Research: "vinyl crackle throughout"
		if "crackle" in instruments:
			for j in range(samples_per_chord):
				# Constant low hiss
				var crackle = (randf() - 0.5) * 0.01
				
				# Random pops (vinyl surface noise)
				if randf() < 0.004:
					crackle += (randf() - 0.5) * 0.12
				if randf() < 0.001:
					crackle += (randf() - 0.5) * 0.25
				
				chord_mix[j] += crackle
		
		# RAIN - Urban atmosphere
		if "rain" in instruments:
			for j in range(samples_per_chord):
				# Filtered pink noise (rain)
				var rain = (randf() - 0.5) * 0.025
				# Occasional heavier drops
				if randf() < 0.01:
					rain += (randf() - 0.5) * 0.04
				chord_mix[j] += rain
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.03))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === KRAFTWERK V2 ===
# Enhanced with research: Motorik beat, vocoder, precise sequencer, Autobahn sounds
static func generate_kraftwerk_v2_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("kraftwerk_v2", parameters)
	randomize()
	var bpm = 110.0  # Motorik tempo
	var bar_duration = 240.0 / bpm
	
	var root_note = ["C", "D", "E", "F"][randi() % 4] + "3"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)  # Kraftwerk often major

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Kraftwerk V2 in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	# Intro: Car engine starting, sequence fading in
	var intro = _generate_kraftwerk_v2_section(progression, scale, ["car_sounds", "sequence"], bar_duration, bpm)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Build: Add bass and motorik drums
	var build = _generate_kraftwerk_v2_section(progression, scale, ["sequence", "moog_bass", "motorik_drums"], bar_duration, bpm)
	playback.set_clip_stream(1, build)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Main: Full arrangement with vocoder and lead
	var main = _generate_kraftwerk_v2_section(progression, scale, ["sequence", "moog_bass", "vocoder_pad", "moog_lead", "motorik_drums"], bar_duration, bpm)
	playback.set_clip_stream(2, main)
	playback.set_clip_name(2, "Main")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# Outro: Fade to sequence
	var outro = _generate_kraftwerk_v2_section(progression, scale, ["sequence", "vocoder_pad", "car_sounds"], bar_duration, bpm)
	playback.set_clip_stream(3, outro)
	playback.set_clip_name(3, "Outro")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 0)
	
	var xfade = 2.5
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_kraftwerk_v2_section(progression: Array, scale: Array, instruments: Array, bar_duration: float, _bpm: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# CAR SOUNDS - Autobahn style (engine drone, road noise)
		if "car_sounds" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				
				# Engine drone (low frequency oscillation)
				var engine = sin(2.0 * PI * 55.0 * t) * 0.2
				engine += sin(2.0 * PI * 110.0 * t) * 0.1
				engine += sin(2.0 * PI * 82.5 * t) * 0.15
				
				# Road/tire noise (filtered noise)
				var road = (randf() - 0.5) * 0.08
				
				# Fade in/out
				var env = 1.0
				if progress < 0.1: env = progress / 0.1
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				
				chord_mix[j] += (engine + road) * env * 0.15
		
		# SEQUENCE - Research: "Zero modulation, precise, stable pitch"
		if "sequence" in instruments:
			var step_samples = _idiv(samples_per_chord, 16)  # 16th notes
			var seq_pattern = [0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12, 5, 12, 7, 12]
			
			for step in range(16):
				var start = step * step_samples
				var note_offset = seq_pattern[step]
				var seq_freq = chord_freqs[0] * pow(2.0, note_offset / 12.0)
				
				for j in range(step_samples):
					var t = float(j) / SAMPLE_RATE
					
					# Clean square wave (research: zero modulation)
					var square = sign(sin(2.0 * PI * seq_freq * t))
					
					# Very short envelope (percussive)
					var env = exp(-t * 15.0)
					
					# Research: "Filter cutoff 2000Hz with resonance"
					# Simulate with harmonic content
					var filtered = square * 0.6 + sin(2.0 * PI * seq_freq * t) * 0.4
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += filtered * env * 0.15
		
		# MOOG BASS - Research: "Dual detuned sawtooth, ladder filter"
		if "moog_bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var bass_freq = root_freq * 0.5
				
				# Dual detuned saws (research: 2 cents drift)
				var drift_cents = 2.0
				var drift_ratio = pow(2.0, drift_cents / 1200.0)
				var saw1 = fmod(t * bass_freq, 1.0) * 2.0 - 1.0
				var saw2 = fmod(t * bass_freq * drift_ratio, 1.0) * 2.0 - 1.0
				
				var bass = (saw1 + saw2) * 0.5
				
				# Research: "Filter 600Hz cutoff, moderate resonance"
				# Simulate with slight warmth
				bass = tanh(bass * 0.9)
				
				# Clean envelope
				var env = 1.0
				if progress < 0.005: env = progress / 0.005
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				
				chord_mix[j] += bass * env * 0.28
		
		# VOCODER PAD - Research: "16 vocoder bands, filter 3000Hz"
		if "vocoder_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				
				var vocoder = 0.0
				for freq in chord_freqs:
					# Multiple formant bands (simulating vocoder)
					vocoder += sin(2.0 * PI * freq * t) * 0.5
					vocoder += sin(2.0 * PI * freq * 2.0 * t) * 0.3
					vocoder += sin(2.0 * PI * freq * 3.0 * t) * 0.2
					vocoder += sin(2.0 * PI * freq * 4.0 * t) * 0.1
				vocoder /= chord_freqs.size() * 1.1
				
				# Research: "Subtle chorus for width"
				var chorus = sin(2.0 * PI * chord_freqs[0] * 1.003 * t) * 0.2
				vocoder += chorus
				
				# Slow attack, long sustain
				var env = 1.0
				if progress < 0.15: env = progress / 0.15
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				
				chord_mix[j] += vocoder * env * 0.12
		
		# MOOG LEAD - Research: "Bright filter 3500Hz, subtle vibrato 5Hz"
		if "moog_lead" in instruments:
			var lead_pattern = [0, 2, 4, 2, 0, -1, 0, 2]
			var note_length = _idiv(samples_per_chord, 8)
			
			for n in range(8):
				var start = n * note_length
				var note_offset = lead_pattern[n]
				var lead_freq = chord_freqs[0] * 2.0 * pow(2.0, note_offset / 12.0)
				
				for j in range(note_length):
					var t = float(j) / SAMPLE_RATE
					var note_progress = float(j) / note_length
					
					# Research: "Vibrato 5Hz LFO at very low depth 0.008"
					var vibrato = 0.0
					if note_progress > 0.3:  # Vibrato comes in late
						var vib_amount = (note_progress - 0.3) / 0.7
						vibrato = sin(2.0 * PI * 5.0 * t) * 0.008 * vib_amount
					
					var lead = sin(2.0 * PI * lead_freq * (1.0 + vibrato) * t)
					
					# Research: "Slight pitch drift 1.5 cents"
					lead += sin(2.0 * PI * lead_freq * 1.001 * t) * 0.3
					
					# Clean envelope
					var env = 1.0
					if note_progress < 0.02: env = note_progress / 0.02
					elif note_progress > 0.8: env = (1.0 - note_progress) / 0.2
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += lead * env * 0.1
		
		# MOTORIK DRUMS - Research: "Steady 4/4 with driving 8th-note hi-hats"
		if "motorik_drums" in instruments:
			var eighth_samples = _idiv(samples_per_chord, 8)
			
			for beat in range(8):
				var start = beat * eighth_samples
				
				# Kick on 1, 3, 5, 7 (four on floor)
				if beat % 2 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.1), eighth_samples)):
						var kt = float(j) / SAMPLE_RATE
						# Research: "Custom electronic drums with pitch envelope"
						var kick_freq = 65.0 * exp(-kt * 28.0) + 48.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 9.0)
						if start + j < samples_per_chord: chord_mix[start + j] += kick * 0.32
				
				# Snare on 2 and 6
				if beat == 2 or beat == 6:
					for j in range(min(int(SAMPLE_RATE * 0.08), eighth_samples)):
						var st = float(j) / SAMPLE_RATE
						# Research: "Resonant filter for pitched 'boing' sounds"
						var snare = sin(2.0 * PI * 220.0 * st) * exp(-st * 22.0) * 0.4
						snare += (randf() - 0.5) * exp(-st * 28.0) * 0.35
						if start + j < samples_per_chord: chord_mix[start + j] += snare * 0.18
				
				# Hi-hat on EVERY 8th note (motorik signature)
				for j in range(min(int(SAMPLE_RATE * 0.035), eighth_samples)):
					var ht = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-ht * 55.0)
					# Clean, precise
					if start + j < samples_per_chord: chord_mix[start + j] += hat * 0.1
		
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				final_mix[start_idx + j] = clampf(chord_mix[j], -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.015))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === GYPSY WOMAN HOUSE 90s ===
# Crystal Waters "Gypsy Woman" (1991) style - Classic NYC/Chicago house
# Key: piano stabs, bouncy filtered bass, 909 drums, soulful groove
static func generate_gypsy_woman_house_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("gypsy_woman_house", parameters)
	randomize()
	var bpm = 120.0  # Classic house tempo
	var bar_duration = 240.0 / bpm
	
	# F major is the iconic key for this track
	var root_note = "F3"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)
	
	# Gypsy Woman chord progression: Fmaj7 - Gm7 - Am7 - Gm7

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Gypsy Woman House in F major")
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 4
	playback.initial_clip = 0
	
	# Intro: Just drums building
	var intro = _generate_gypsy_house_section(progression, scale, ["drums"], bar_duration)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# Verse: Add bass and piano stabs
	var verse = _generate_gypsy_house_section(progression, scale, ["drums", "bass", "piano_stab"], bar_duration)
	playback.set_clip_stream(1, verse)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# Chorus: Full arrangement with pads
	var chorus = _generate_gypsy_house_section(progression, scale, ["drums", "bass", "piano_stab", "pad"], bar_duration)
	playback.set_clip_stream(2, chorus)
	playback.set_clip_name(2, "Chorus")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# Breakdown: Piano and pad only
	var breakdown = _generate_gypsy_house_section([0, 2], scale, ["piano_stab", "pad"], bar_duration)
	playback.set_clip_stream(3, breakdown)
	playback.set_clip_name(3, "Breakdown")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 1)  # Back to verse
	
	var xfade = 1.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_gypsy_house_section(progression: Array, scale: Array, instruments: Array, bar_duration: float) -> AudioStreamWAV:
	var bpm = 120.0
	var total_duration = progression.size() * bar_duration * 2  # 2 bars per chord
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# 909-STYLE HOUSE DRUMS
		if "drums" in instruments:
			var beat_samples = int(bar_duration * SAMPLE_RATE / 16)  # 16th note grid (16 steps per bar)
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var beat_in_bar = int(fmod(j, bar_duration * SAMPLE_RATE) / beat_samples)
				var sample_in_beat = j % beat_samples
				var _beat_t = float(sample_in_beat) / beat_samples
				
				# Kick on 1, 5, 9, 13 (4-on-floor)
				if beat_in_bar % 4 == 0 and sample_in_beat < int(SAMPLE_RATE * 0.15):
					var kick_t = float(sample_in_beat) / SAMPLE_RATE
					var kick_freq = 55.0 * exp(-kick_t * 30.0) + 45.0  # Pitch drop
					var kick = sin(2.0 * PI * kick_freq * kick_t)
					kick *= exp(-kick_t * 15.0)  # Amplitude decay
					kick = tanh(kick * 2.5)  # Soft saturation
					chord_mix[j] += kick * 0.5
				
				# Clap/Snare on 5, 13 (beats 2 and 4)
				if (beat_in_bar == 4 or beat_in_bar == 12) and sample_in_beat < int(SAMPLE_RATE * 0.12):
					var clap_t = float(sample_in_beat) / SAMPLE_RATE
					var noise = randf() * 2.0 - 1.0
					var clap_env = exp(-clap_t * 25.0)
					# Bandpass filter simulation for clap
					chord_mix[j] += noise * clap_env * 0.25
				
				# Hi-hats: 16th notes with velocity variation
				if sample_in_beat < int(SAMPLE_RATE * 0.03):
					var hat_t = float(sample_in_beat) / SAMPLE_RATE
					var hat_noise = randf() * 2.0 - 1.0
					var hat_env = exp(-hat_t * 80.0)
					var hat_vel = 0.15 if beat_in_bar % 2 == 0 else 0.08  # Accent on offbeats
					# Open hat on 2.5 and 6.5 (offbeats)
					if beat_in_bar == 2 or beat_in_bar == 6 or beat_in_bar == 10 or beat_in_bar == 14:
						hat_env = exp(-hat_t * 20.0)  # Longer decay for open hat
						hat_vel = 0.12
					chord_mix[j] += hat_noise * hat_env * hat_vel
		
		# HOUSE BASS - Bouncy filtered saw
		if "bass" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var beat_pos = fmod(t * bpm / 60.0, 1.0)
				
				# Octave bounce pattern (root, root+octave alternating)
				var bass_freq = root_freq * 0.5
				if int(t * bpm / 60.0 * 2) % 2 == 1:
					bass_freq *= 2.0  # Octave up on offbeats
				
				# Sawtooth oscillator
				var saw = fmod(t * bass_freq, 1.0) * 2.0 - 1.0
				
				# Filter envelope (opens and closes with each note)
				var note_t = fmod(t, 60.0 / bpm / 2)
				var filter_env = 0.2 + 0.6 * exp(-note_t * 12.0)
				saw = tanh(saw * (1.0 + filter_env))
				
				# Sidechain ducking from kick
				var sidechain = 1.0 - exp(-beat_pos * 8.0) * 0.4
				
				chord_mix[j] += saw * sidechain * filter_env * 0.3
		
		# PIANO STABS - Classic house piano
		if "piano_stab" in instruments:
			# Stab on beats 1, 2.5, 3, 4.5 (syncopated)
			var stab_times = [0.0, 0.375, 0.5, 0.875]  # In bar fractions
			for stab_time in stab_times:
				var stab_start = int(stab_time * bar_duration * 2 * SAMPLE_RATE)
				var stab_duration = int(SAMPLE_RATE * 0.25)  # Short stab
				
				for j in range(stab_duration):
					if stab_start + j >= samples_per_chord:
						break
					var t = float(j) / SAMPLE_RATE
					var stab = 0.0
					
					# Play full chord (add 7th for that house flavor)
					for k in range(min(4, chord_freqs.size())):
						var freq = chord_freqs[k]
						# Complex tone (fundamental + harmonics)
						stab += sin(2.0 * PI * freq * t) * 0.5
						stab += sin(2.0 * PI * freq * 2.0 * t) * 0.25
						stab += sin(2.0 * PI * freq * 3.0 * t) * 0.1
					
					# Sharp attack, quick decay (stab envelope)
					var env = exp(-t * 8.0)
					chord_mix[stab_start + j] += stab * env * 0.15
		
		# WARM PAD - Strings/synth pad
		if "pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var pad = 0.0
				
				# Detuned oscillators for warmth
				for k in range(min(3, chord_freqs.size())):
					var freq = chord_freqs[k]
					pad += sin(2.0 * PI * freq * t)
					pad += sin(2.0 * PI * freq * 1.003 * t) * 0.7  # Slight detune
					pad += sin(2.0 * PI * freq * 0.997 * t) * 0.7
				
				# Slow filter LFO
				var lfo = 0.5 + 0.5 * sin(2.0 * PI * 0.1 * t)
				pad *= 0.3 + 0.7 * lfo
				
				# Soft envelope
				var progress = float(j) / samples_per_chord
				var env = sin(progress * PI)  # Fade in and out
				
				chord_mix[j] += pad * env * 0.08
		
		# Mix this chord's audio into final
		var offset = i * samples_per_chord
		for j in range(samples_per_chord):
			if offset + j < total_samples:
				final_mix[offset + j] += chord_mix[j]
	
	# Soft clip the final mix
	for i in range(total_samples):
		final_mix[i] = tanh(final_mix[i])
	
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_FORWARD)


# === POP MADONNA 80s ===
# "Holiday", "Into the Groove" era - Jellybean Benitez production style
# Key: gated reverb snare, octave bass, bright Juno stabs, 4-on-floor
static func generate_pop_madonna_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("pop_madonna", parameters)
	randomize()
	var bpm = 118.0  # Classic 80s dance-pop
	var bar_duration = 240.0 / bpm
	
	# Major keys (bright, uplifting)
	var roots = ["C", "D", "F", "G"]
	var root_note = roots[randi() % roots.size()] + "4"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)
	
	# Classic 80s progressions
	var progressions = [
		[0, 4, 5, 3],  # I - V - vi - IV
		[0, 3, 4, 4],  # I - IV - V - V
		[0, 5, 3, 4],  # I - vi - IV - V
	]

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Madonna 80s Pop in ", root_note)
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 5
	playback.initial_clip = 0
	
	# 0. INTRO: Beat + bass hook
	var intro = _generate_madonna_section(progression, scale,
		["gated_drums", "octave_bass", "synth_stab"], bar_duration, bpm, 0.7)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# 1. VERSE
	var verse = _generate_madonna_section(progression, scale,
		["gated_drums", "octave_bass", "juno_pad", "synth_stab"], bar_duration, bpm, 0.8)
	playback.set_clip_stream(1, verse)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# 2. PRE-CHORUS: Build
	var pre = _generate_madonna_section(progression, scale,
		["gated_drums", "octave_bass", "juno_pad", "synth_stab", "hook_melody"], bar_duration, bpm, 0.9)
	playback.set_clip_stream(2, pre)
	playback.set_clip_name(2, "Pre-Chorus")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# 3. CHORUS: Full energy
	var chorus = _generate_madonna_section(progression, scale,
		["gated_drums", "octave_bass", "juno_pad", "synth_stab", "hook_melody", "string_hits"], bar_duration, bpm, 1.0)
	playback.set_clip_stream(3, chorus)
	playback.set_clip_name(3, "Chorus")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 4)
	
	# 4. OUTRO
	var outro = _generate_madonna_section(progression, scale,
		["gated_drums", "octave_bass", "synth_stab"], bar_duration, bpm, 0.7)
	playback.set_clip_stream(4, outro)
	playback.set_clip_name(4, "Outro")
	playback.set_clip_auto_advance(4, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(4, 0)
	
	var xfade = 1.5
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 1.0)
	playback.add_transition(3, 4, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(4, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_madonna_section(progression: Array, scale: Array, instruments: Array,
		bar_duration: float, bpm: float, energy: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for chord_idx in range(progression.size()):
		var degree = progression[chord_idx]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# === GATED DRUMS ===
		# The defining 80s sound: tight kick, GATED REVERB snare, crisp hats
		if "gated_drums" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			
			for step in range(16):
				var start = step * sixteenth
				
				# KICK - 4 on floor, punchy
				if step % 4 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick_freq = 60.0 * exp(-kt * 30.0) + 50.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 8.0)
						# Click transient
						kick += sin(2.0 * PI * 2500.0 * kt) * exp(-kt * 200.0) * 0.15
						kick = tanh(kick * 1.4)
						if start + j < samples_per_chord:
							chord_mix[start + j] += kick * 0.4 * energy
				
				# GATED REVERB SNARE - the 80s sound
				if step == 4 or step == 12:
					# Snare hit
					for j in range(min(int(SAMPLE_RATE * 0.2), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						
						# Snare body
						var snare = sin(2.0 * PI * 200.0 * st) * exp(-st * 25.0) * 0.3
						# Snare noise
						snare += (randf() - 0.5) * exp(-st * 20.0) * 0.4
						
						# GATED REVERB - rises then cuts off sharply
						var gate_length = 0.15
						var reverb_env = 0.0
						if st < gate_length:
							# Reverb builds up
							reverb_env = (1.0 - exp(-st * 15.0)) * (1.0 - st / gate_length)
						# Reverb tail (noise)
						var reverb = (randf() - 0.5) * reverb_env * 0.4
						
						if start + j < samples_per_chord:
							chord_mix[start + j] += (snare + reverb) * 0.28 * energy
				
				# HI-HATS - 8ths, crisp
				if step % 2 == 0:
					var is_open = step % 8 == 6
					var decay = 35.0 if not is_open else 18.0
					for j in range(min(int(SAMPLE_RATE * 0.05), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * decay)
						# Brighter 80s hats
						hat += sin(2.0 * PI * 8000.0 * ht) * exp(-ht * 100.0) * 0.1
						if start + j < samples_per_chord:
							chord_mix[start + j] += hat * 0.08 * energy
		
		# === OCTAVE BASS ===
		# Synth bass that jumps octaves - very 80s
		if "octave_bass" in instruments:
			var bass_freq = root_freq * 0.25
			var eighth = _idiv(samples_per_chord, 8)
			
			for beat in range(8):
				var start = beat * eighth
				# Octave pattern: low-low-HIGH-low
				var octave_mult = 2.0 if beat % 4 == 2 else 1.0
				var note_freq = bass_freq * octave_mult
				
				for j in range(min(int(eighth * 0.9), samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					var progress = float(j) / eighth
					
					# Saw bass with filter
					var bass = fmod(t * note_freq, 1.0) * 2.0 - 1.0
					bass += fmod(t * note_freq * 1.003, 1.0) * 2.0 - 1.0
					bass *= 0.5
					
					# Filter envelope
					var filt = 0.4 + exp(-progress * 4.0) * 0.4
					bass = tanh(bass * filt * 1.5)
					
					# Envelope
					var env = 1.0
					if progress < 0.02: env = progress / 0.02
					elif progress > 0.85: env = (1.0 - progress) / 0.15
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += bass * env * 0.32 * energy
		
		# === JUNO PAD ===
		# Lush, bright 80s pad (Roland Juno style)
		if "juno_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				
				for freq in chord_freqs:
					# PWM square waves (Juno character)
					var pwm = 0.3 + sin(2.0 * PI * 0.3 * t) * 0.2
					var wave1 = 1.0 if fmod(t * freq, 1.0) < pwm else -1.0
					var wave2 = 1.0 if fmod(t * freq * 1.007, 1.0) < (pwm + 0.05) else -1.0
					pad += (wave1 + wave2) * 0.5
				pad /= chord_freqs.size()
				
				# Bright filter (80s shimmer)
				pad = tanh(pad * 0.7)
				
				# Chorus effect (stereo spread simulation)
				pad += sin(2.0 * PI * chord_freqs[0] * 1.002 * t) * 0.15
				
				# Envelope
				var env = 1.0
				if progress < 0.1: env = progress / 0.1
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				
				chord_mix[j] += pad * env * 0.15 * energy
		
		# === SYNTH STAB ===
		# Bright brass-like stab (DX7 / Juno style)
		if "synth_stab" in instruments:
			var stab_times = [0, int(samples_per_chord * 0.5)]
			
			for st in stab_times:
				for j in range(min(int(SAMPLE_RATE * 0.15), samples_per_chord - st)):
					var t = float(j) / SAMPLE_RATE
					var stab = 0.0
					
					for freq in chord_freqs:
						# Bright, brassy tone
						stab += sin(2.0 * PI * freq * t)
						stab += sin(2.0 * PI * freq * 2.0 * t) * 0.5
						stab += sin(2.0 * PI * freq * 3.0 * t) * 0.25
						stab += sin(2.0 * PI * freq * 4.0 * t) * 0.12
					stab /= chord_freqs.size() * 1.9
					
					# Fast attack, quick decay (stabby)
					var env = exp(-t * 12.0)
					
					if st + j < samples_per_chord:
						chord_mix[st + j] += stab * env * 0.1 * energy
		
		# === HOOK MELODY ===
		# Catchy, singable synth hook (Madonna-style: stepwise with resolution)
		if "hook_melody" in instruments:
			# Hooky pattern with call-response feel
			var melody = [0, 2, 4, 2, 0, 0, 5, 4]  # Rising then falling
			var eighth = _idiv(samples_per_chord, 8)
			
			for n in range(8):
				var start = n * eighth
				var offset = melody[n]
				var mel_freq = chord_freqs[0] * 2.0 * pow(2.0, offset / 12.0)
				
				for j in range(int(eighth * 0.9)):
					var t = float(j) / SAMPLE_RATE
					var note_progress = float(j) / eighth
					
					# Bright lead sound
					var lead = sin(2.0 * PI * mel_freq * t)
					lead += sin(2.0 * PI * mel_freq * 2.0 * t) * 0.3
					lead += fmod(t * mel_freq, 1.0) * 2.0 - 1.0  # Add saw
					lead *= 0.5
					
					lead = tanh(lead * 0.9)
					
					# Envelope
					var env = 1.0
					if note_progress < 0.05: env = note_progress / 0.05
					elif note_progress > 0.8: env = (1.0 - note_progress) / 0.2
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += lead * env * 0.1 * energy
		
		# === STRING HITS ===
		# Orchestral stab on downbeats (very 80s)
		if "string_hits" in instruments:
			for j in range(min(int(SAMPLE_RATE * 0.4), samples_per_chord)):
				var t = float(j) / SAMPLE_RATE
				var strings = 0.0
				
				for freq in chord_freqs:
					# Multiple harmonics for string-like tone
					strings += sin(2.0 * PI * freq * t) * 0.4
					strings += sin(2.0 * PI * freq * 2.0 * t) * 0.3
					strings += sin(2.0 * PI * freq * 3.0 * t) * 0.2
					strings += sin(2.0 * PI * freq * 4.0 * t) * 0.1
				strings /= chord_freqs.size()
				
				# Attack + sustain + release
				var env = 1.0
				if t < 0.02: env = t / 0.02
				elif t > 0.3: env = exp(-(t - 0.3) * 8.0)
				
				chord_mix[j] += strings * env * 0.12 * energy
		
		# Mix into final
		var start_idx = chord_idx * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				sample = tanh(sample * 0.85)
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.015))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === POP V2 ===
# Modern synth-pop / chillwave with distinct palette
# Optimized for: identity token, frequency allocation, loop durability, VO safety
static func generate_pop_v2_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("pop_v2", parameters)
	randomize()
	var bpm = 118.0  # Upbeat pop tempo
	var bar_duration = 240.0 / bpm
	
	# Major key for pop brightness
	var roots = ["C", "G", "D", "F", "A"]
	var root_note = roots[randi() % roots.size()] + "4"
	var scale = PopMusicTheory.get_major_scale_notes(root_note)
	
	# Classic pop progression with emotional lift

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	print("AudioSynthesizer: Generating Pop V2 in ", root_note, " (modern synth-pop)")
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 5
	playback.initial_clip = 0
	
	# Clear arc: Intro ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Verse ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Pre-Chorus ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Chorus ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Outro
	
	# 0. INTRO: Pluck motif + beat hint (establish identity with energy)
	var intro = _generate_pop_v2_section(progression, scale,
		["pluck_motif", "shimmer_arp", "snap_beat"], bar_duration, bpm, 0.6)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# 1. VERSE: Full groove
	var verse = _generate_pop_v2_section(progression, scale,
		["pluck_motif", "sub_808", "full_beat", "sidechain_pad"], bar_duration, bpm, 0.75)
	playback.set_clip_stream(1, verse)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# 2. PRE-CHORUS: Build tension
	var pre = _generate_pop_v2_section(progression, scale,
		["pluck_motif", "sub_808", "full_beat", "sidechain_pad", "shimmer_arp", "vocal_chop"], bar_duration, bpm, 0.85)
	playback.set_clip_stream(2, pre)
	playback.set_clip_name(2, "Pre-Chorus")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# 3. CHORUS: Full energy
	var chorus = _generate_pop_v2_section(progression, scale,
		["pluck_motif", "sub_808", "full_beat", "sidechain_pad", "shimmer_arp", "synth_lead", "vocal_chop"], bar_duration, bpm, 1.0)
	playback.set_clip_stream(3, chorus)
	playback.set_clip_name(3, "Chorus")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 4)
	
	# 4. OUTRO: Return to intro energy (loop seam)
	var outro = _generate_pop_v2_section(progression, scale,
		["pluck_motif", "shimmer_arp", "snap_beat"], bar_duration, bpm, 0.6)
	playback.set_clip_stream(4, outro)
	playback.set_clip_name(4, "Outro")
	playback.set_clip_auto_advance(4, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(4, 0)
	
	var xfade = 2.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, 1.5)
	playback.add_transition(3, 4, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(4, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_pop_v2_section(progression: Array, scale: Array, instruments: Array,
		bar_duration: float, bpm: float, energy: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	# Pre-calculate sidechain envelope for the whole section
	var sidechain_env = PackedFloat32Array()
	sidechain_env.resize(total_samples)
	var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
	for i in range(total_samples):
		var beat_pos = fmod(float(i), beat_samples) / beat_samples
		# Sidechain: duck on beat, recover quickly
		sidechain_env[i] = 0.3 + 0.7 * (1.0 - exp(-beat_pos * 8.0))
	
	for chord_idx in range(progression.size()):
		var degree = progression[chord_idx]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# === PLUCK MOTIF ===
		# Identity token: clean digital pluck with signature rhythm
		# Frequency: mid (500-2kHz)
		if "pluck_motif" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			# Signature rhythm pattern (recognizable)
			var pattern = [1, 0, 1, 0, 1, 1, 0, 1, 1, 0, 1, 0, 1, 0, 1, 1]
			var note_offsets = [0, 0, 4, 4, 7, 0, 0, 4, 7, 7, 4, 4, 0, 0, 7, 4]
			
			for step in range(16):
				if pattern[step] == 0:
					continue
				var start = step * sixteenth
				var offset = note_offsets[step]
				var pluck_freq = chord_freqs[0] * pow(2.0, offset / 12.0)
				
				for j in range(min(int(SAMPLE_RATE * 0.3), samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					
					# Clean digital pluck: sine + harmonics with fast decay
					var pluck = sin(2.0 * PI * pluck_freq * t)
					pluck += sin(2.0 * PI * pluck_freq * 2.0 * t) * 0.3 * exp(-t * 10.0)
					pluck += sin(2.0 * PI * pluck_freq * 3.0 * t) * 0.15 * exp(-t * 15.0)
					
					# Pluck envelope
					var env = exp(-t * 6.0)
					
					# Slight filter sweep
					pluck *= 0.7 + 0.3 * exp(-t * 8.0)
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += pluck * env * 0.12 * energy
		
		# === SHIMMER ARP ===
		# Frequency: high (4-8kHz) - "air" band, sparkle
		if "shimmer_arp" in instruments:
			var eighth = _idiv(samples_per_chord, 8)
			var arp_notes = [0, 4, 7, 12, 7, 4, 0, 4]  # Up and down
			
			for step in range(8):
				var start = step * eighth
				var offset = arp_notes[step]
				var arp_freq = chord_freqs[0] * 2.0 * pow(2.0, offset / 12.0)  # 2 octaves up
				
				for j in range(min(int(SAMPLE_RATE * 0.15), samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					
					# Pure sine with slight detune for shimmer
					var shimmer = sin(2.0 * PI * arp_freq * t)
					shimmer += sin(2.0 * PI * arp_freq * 1.003 * t) * 0.5
					shimmer += sin(2.0 * PI * arp_freq * 0.997 * t) * 0.5
					shimmer /= 2.0
					
					# Soft envelope
					var env = exp(-t * 8.0)
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += shimmer * env * 0.06 * energy
		
		# === SUB 808 ===
		# Frequency: sub only (30-60Hz) - clean separation
		if "sub_808" in instruments:
			var bass_freq = root_freq * 0.25  # Deep sub
			
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				
				# 808 character: sine with pitch envelope on attack
				var pitch_env = 1.0 + exp(-t * 30.0) * 0.5
				var sub = sin(2.0 * PI * bass_freq * pitch_env * t)
				
				# Slight saturation
				sub = tanh(sub * 1.2)
				
				# Long sustain, soft release
				var env = 1.0
				if progress < 0.01: env = progress / 0.01
				elif progress > 0.85: env = (1.0 - progress) / 0.15
				
				chord_mix[j] += sub * env * 0.35 * energy
		
		# === SIDECHAIN PAD ===
		# Frequency: low-mid to mid (200-1500Hz)
		# Pumping feel from sidechain
		if "sidechain_pad" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				
				for freq in chord_freqs:
					# Soft saw waves
					var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
					saw += fmod(t * freq * 1.005, 1.0) * 2.0 - 1.0
					pad += saw * 0.5
				pad /= chord_freqs.size()
				
				# Lowpass for warmth
				pad = tanh(pad * 0.8)
				
				# Envelope
				var env = 1.0
				if progress < 0.1: env = progress / 0.1
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				
				# Apply sidechain
				var global_idx = chord_idx * samples_per_chord + j
				var sc = sidechain_env[global_idx] if global_idx < sidechain_env.size() else 1.0
				
				chord_mix[j] += pad * env * sc * 0.18 * energy
		
		# === VOCAL CHOP ===
		# Simulated pitched vocal hits - rhythmic interest
		# Frequency: presence (2-4kHz) - but sparse, VO-safe
		if "vocal_chop" in instruments:
			var chop_times = [int(samples_per_chord * 0.25), int(samples_per_chord * 0.75)]
			
			for ct in chop_times:
				# Formant-like synthesis
				var formant_freqs = [800.0, 1200.0, 2500.0]  # "ah" vowel-ish
				var carrier_freq = chord_freqs[0]
				
				for j in range(min(int(SAMPLE_RATE * 0.2), samples_per_chord - ct)):
					var t = float(j) / SAMPLE_RATE
					var chop = 0.0
					
					for ff in formant_freqs:
						chop += sin(2.0 * PI * ff * t) * sin(2.0 * PI * carrier_freq * t)
					chop /= formant_freqs.size()
					
					# Short, percussive
					var env = exp(-t * 8.0)
					
					if ct + j < samples_per_chord:
						chord_mix[ct + j] += chop * env * 0.07 * energy
		
		# === SYNTH LEAD ===
		# Frequency: mid-presence (1-3kHz)
		# Modern pop: sparse, rhythmic, space between notes
		if "synth_lead" in instruments:
			# -100 = rest, sparse pattern (modern pop has space)
			var lead_pattern = [0, -100, 4, -100, 7, 4, -100, 0]
			var note_samples = _idiv(samples_per_chord, 8)
			
			for n in range(8):
				var start = n * note_samples
				var offset = lead_pattern[n]
				
				# Skip rests
				if offset <= -100:
					continue
				
				var lead_freq = chord_freqs[0] * 2.0 * pow(2.0, offset / 12.0)
				
				for j in range(note_samples):
					var t = float(j) / SAMPLE_RATE
					var note_progress = float(j) / note_samples
					
					# Supersaw-lite (3 voices)
					var lead = 0.0
					for d in [-0.01, 0.0, 0.01]:
						lead += fmod(t * lead_freq * (1.0 + d), 1.0) * 2.0 - 1.0
					lead /= 3.0
					
					# Filter
					lead = tanh(lead * 0.9)
					
					# Envelope with slight attack
					var env = 1.0
					if note_progress < 0.05: env = note_progress / 0.05
					elif note_progress > 0.7: env = (1.0 - note_progress) / 0.3
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += lead * env * 0.1 * energy
		
		# === SNAP BEAT ===
		# Punchy: kick + snaps + offbeat hats (upbeat feel)
		if "snap_beat" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			
			for step in range(16):
				var start = step * sixteenth
				# Tight humanize
				start += int((randf() - 0.5) * SAMPLE_RATE * 0.004)
				start = clampi(start, 0, samples_per_chord - 1)
				
				# KICK on 1, 5, 9, 13 (four on floor)
				if step % 4 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick_freq = 55.0 * exp(-kt * 28.0) + 45.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 8.0)
						kick = tanh(kick * 1.4)  # Punchy
						if start + j < samples_per_chord:
							chord_mix[start + j] += kick * 0.38 * energy
				
				# SNAP on 4, 12 (backbeat)
				if step == 4 or step == 12:
					for j in range(min(int(SAMPLE_RATE * 0.06), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						# Layered snap for punch
						var snap = (randf() - 0.5) * exp(-st * 50.0) * 0.6
						snap += sin(2.0 * PI * 1100.0 * st) * exp(-st * 35.0) * 0.4
						snap += (randf() - 0.5) * exp(-st * 80.0) * 0.3  # Extra layer
						if start + j < samples_per_chord:
							chord_mix[start + j] += snap * 0.18 * energy
				
				# HATS - offbeat for groove (not on kick)
				if step % 2 == 1:
					for j in range(min(int(SAMPLE_RATE * 0.025), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 55.0)
						if start + j < samples_per_chord:
							chord_mix[start + j] += hat * 0.07 * energy
		
		# === FULL BEAT ===
		# Driving, energetic beat for verse/chorus
		if "full_beat" in instruments:
			var sixteenth = _idiv(samples_per_chord, 16)
			
			for step in range(16):
				var start = step * sixteenth
				start += int((randf() - 0.5) * SAMPLE_RATE * 0.003)
				start = clampi(start, 0, samples_per_chord - 1)
				
				# KICK - punchy, slightly more attack
				if step % 4 == 0 or step == 10:  # Extra kick for drive
					for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						var kick_freq = 60.0 * exp(-kt * 25.0) + 48.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 7.0)
						kick = tanh(kick * 1.5)  # More punch
						if start + j < samples_per_chord:
							chord_mix[start + j] += kick * 0.42 * energy
				
				# CLAP on 4, 12 - thick layered
				if step == 4 or step == 12:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var ct = float(j) / SAMPLE_RATE
						var clap = (randf() - 0.5) * exp(-ct * 22.0) * 0.5
						clap += (randf() - 0.5) * exp(-(ct + 0.008) * 28.0) * 0.3
						clap += (randf() - 0.5) * exp(-(ct + 0.015) * 35.0) * 0.2
						if start + j < samples_per_chord:
							chord_mix[start + j] += clap * 0.2 * energy
				
				# HATS - every 8th with accents
				if step % 2 == 0:
					var accent = 1.2 if step % 4 == 2 else 1.0  # Accent offbeats
					for j in range(min(int(SAMPLE_RATE * 0.03), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 50.0)
						if start + j < samples_per_chord:
							chord_mix[start + j] += hat * 0.065 * energy * accent
		
		# Mix into final
		var start_idx = chord_idx * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				sample = tanh(sample * 0.85)  # Soft limit
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.015))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === PROG SYNTH 70s V2 ===
# Optimized for 10-point rubric: identity token, arc legibility, frequency allocation, loop durability
# Based on Tangerine Dream, Kraftwerk, ELP research
static func generate_prog_synth_v2_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("prog_synth_v2", parameters)
	randomize()
	var bpm = 105.0  # Slightly slower for hypnotic feel
	var bar_duration = 240.0 / bpm
	
	# Modal root (prog loves Dorian, Aeolian)
	var roots = ["D", "E", "A", "B"]
	var root_note = roots[randi() % roots.size()] + "3"
	var scale = PopMusicTheory.get_minor_scale_notes(root_note)
	
	# Prog progression: modal, with a clear return point

	var progression = _resolve_progression_from_parameters(parameters, _default_progression_for_song(str(parameters.get("song_id", ""))), scale)
	
	# Identity token: a signature motif interval (perfect 5th rise)
	var motif_interval = 7  # Perfect 5th - recognizable, prog-like
	
	print("AudioSynthesizer: Generating Prog Synth V2 in ", root_note, " (optimized)")
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 5
	playback.initial_clip = 0
	
	# Section design for clear ARC:
	# Intro (sparse) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Build (add rhythm) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Peak (full + lead) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Release ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Loop-friendly outro
	
	# 0. INTRO: Mellotron pad + motif hint (sparse, establish identity)
	var intro = _generate_prog_v2_section(progression, scale, 
		["mellotron_pad", "motif_bell"], bar_duration, bpm, motif_interval, 0.4)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# 1. BUILD: Add bass + motorik (energy rises)
	var build = _generate_prog_v2_section(progression, scale,
		["mellotron_pad", "moog_bass_v2", "motorik_v2", "motif_bell"], bar_duration, bpm, motif_interval, 0.6)
	playback.set_clip_stream(1, build)
	playback.set_clip_name(1, "Build")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# 2. PEAK: Full arrangement with sequence + lead (climax)
	var peak = _generate_prog_v2_section(progression, scale,
		["mellotron_pad", "moog_bass_v2", "arp_sequence", "prog_lead", "motorik_v2"], bar_duration, bpm, motif_interval, 1.0)
	playback.set_clip_stream(2, peak)
	playback.set_clip_name(2, "Peak")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# 3. RELEASE: Pull back to pad + bass (tension release)
	var release = _generate_prog_v2_section(progression, scale,
		["mellotron_pad", "moog_bass_v2", "motif_bell"], bar_duration, bpm, motif_interval, 0.5)
	playback.set_clip_stream(3, release)
	playback.set_clip_name(3, "Release")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 4)
	
	# 4. OUTRO: Match intro energy (loop-friendly seam)
	var outro = _generate_prog_v2_section(progression, scale,
		["mellotron_pad", "motif_bell"], bar_duration, bpm, motif_interval, 0.4)
	playback.set_clip_stream(4, outro)
	playback.set_clip_name(4, "Outro")
	playback.set_clip_auto_advance(4, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(4, 0)
	
	# Long crossfades for prog feel
	var xfade = 4.0
	playback.add_transition(0, 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(1, 2, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(2, 3, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(3, 4, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(4, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_prog_v2_section(progression: Array, scale: Array, instruments: Array, 
		bar_duration: float, bpm: float, motif_interval: int, energy_level: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# === MELLOTRON PAD ===
		# Frequency: mid-range (300-2000Hz) - leaves room for bass
		# Research: 6-voice, 10-cent detune, 2s attack, chorus
		if "mellotron_pad" in instruments:
			var detune_cents = 10.0
			var detune_ratio = pow(2.0, detune_cents / 1200.0)
			
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				
				# Analog drift (research: 5 cents slow drift)
				var drift = sin(2.0 * PI * 0.12 * t) * 0.003
				
				for freq in chord_freqs:
					# 4 detuned voices (string machine character)
					var f = freq * (1.0 + drift)
					pad += sin(2.0 * PI * f * t) * 0.4
					pad += sin(2.0 * PI * f * detune_ratio * t) * 0.3
					pad += sin(2.0 * PI * f / detune_ratio * t) * 0.3
					# Slight square for organ-ish character
					pad += sign(sin(2.0 * PI * f * 0.5 * t)) * 0.15
				
				pad /= chord_freqs.size() * 1.15
				
				# Long attack (2s from research), smooth release
				var env = 1.0
				var attack_time = 0.18  # ~18% of section = ~2s at 105bpm
				if progress < attack_time:
					env = progress / attack_time
				elif progress > 0.85:
					env = (1.0 - progress) / 0.15
				
				# Soft saturation (tape warmth)
				pad = tanh(pad * 1.1)
				
				# Chorus simulation (slow detuned copy)
				var chorus = sin(2.0 * PI * chord_freqs[0] * 1.002 * t + sin(t * 0.5) * 0.3) * 0.1
				
				chord_mix[j] += (pad + chorus) * env * 0.22 * energy_level
		
		# === MOTIF BELL ===
		# Identity token: recurring bell/mallet hit with signature interval
		# Appears every 2 bars, provides instant recognition
		if "motif_bell" in instruments:
			# Play motif at bar start and midpoint (recurrence)
			var motif_times = [0, int(samples_per_chord * 0.5)]
			
			for mt in motif_times:
				# Signature: root then 5th (perfect 5th = identity)
				var motif_freqs = [
					chord_freqs[0] * 2.0,  # Root, octave up
					chord_freqs[0] * 2.0 * pow(2.0, motif_interval / 12.0)  # 5th above
				]
				
				for note_idx in range(2):
					var note_start = mt + note_idx * int(SAMPLE_RATE * 0.15)
					var note_freq = motif_freqs[note_idx]
					var note_length = int(SAMPLE_RATE * 1.2)
					
					for j in range(min(note_length, samples_per_chord - note_start)):
						var t = float(j) / SAMPLE_RATE
						
						# Bell: sine + harmonics with fast decay
						var bell = sin(2.0 * PI * note_freq * t)
						bell += sin(2.0 * PI * note_freq * 2.0 * t) * 0.5 * exp(-t * 3.0)
						bell += sin(2.0 * PI * note_freq * 3.0 * t) * 0.25 * exp(-t * 5.0)
						bell += sin(2.0 * PI * note_freq * 4.1 * t) * 0.15 * exp(-t * 7.0)  # Inharmonic
						
						# Envelope: sharp attack, long decay (bell character)
						var env = exp(-t * 1.8)
						
						if note_start + j < samples_per_chord:
							chord_mix[note_start + j] += bell * env * 0.08 * energy_level
		
		# === MOOG BASS V2 ===
		# Frequency: sub + bass only (20-200Hz) - clear ownership
		# Research: dual saw + sub square, ladder filter, 8-cent drift
		if "moog_bass_v2" in instruments:
			var bass_freq = root_freq * 0.25  # Deep
			var filter_state = 0.0
			
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				
				# Analog drift (8 cents from research)
				var drift = sin(2.0 * PI * 0.08 * t + i * 1.5) * 0.005
				var f = bass_freq * (1.0 + drift)
				
				# Dual detuned saws
				var saw1 = fmod(t * f, 1.0) * 2.0 - 1.0
				var saw2 = fmod(t * f * 0.996, 1.0) * 2.0 - 1.0
				# Sub square
				var sub = sign(sin(2.0 * PI * f * 0.5 * t))
				
				var bass = saw1 * 0.35 + saw2 * 0.35 + sub * 0.3
				
				# Ladder filter envelope (research: 800Hz cutoff, 0.4 resonance)
				var filter_env = 0.4 + exp(-progress * 5.0) * 0.4
				filter_state += filter_env * 0.3 * (bass - filter_state)
				bass = filter_state
				
				# Warm saturation
				bass = tanh(bass * 1.5)
				
				# Envelope
				var env = 1.0
				if progress < 0.01: env = progress / 0.01
				elif progress > 0.8: env = (1.0 - progress) / 0.2
				
				chord_mix[j] += bass * env * 0.32 * energy_level
		
		# === ARP SEQUENCE ===
		# Frequency: presence range (2-4kHz) - clarity without VO conflict
		# 16th notes, filter movement, recognizable pattern
		if "arp_sequence" in instruments:
			var step_samples = _idiv(samples_per_chord, 16)
			# Pattern: root, 5th, octave, 5th (ascending feel)
			var seq_offsets = [0, 7, 12, 7, 0, 7, 12, 7, 0, 7, 12, 7, 5, 7, 12, 7]
			
			for step in range(16):
				var start = step * step_samples
				var offset = seq_offsets[step]
				var seq_freq = chord_freqs[0] * pow(2.0, offset / 12.0)
				
				for j in range(step_samples):
					var t = float(j) / SAMPLE_RATE
					var step_progress = float(j) / step_samples
					
					# Square wave with PWM (research)
					var pwm = 0.3 + sin(2.0 * PI * 0.5 * t) * 0.15
					var square = 1.0 if fmod(t * seq_freq, 1.0) < pwm else -1.0
					
					# Resonant filter sweep
					var filter_mod = 0.5 + sin(2.0 * PI * 2.0 * t) * 0.2
					square = tanh(square * filter_mod)
					
					# Percussive envelope
					var env = exp(-step_progress * 8.0) * 0.5 + 0.5 * exp(-step_progress * 2.0)
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += square * env * 0.1 * energy_level
		
		# === PROG LEAD ===
		# Frequency: mid-presence (1-3kHz)
		# Research: saw, bright filter 3500Hz, 5Hz vibrato, portamento
		# Prog uses bigger intervals: 4ths, 5ths, octaves
		if "prog_lead" in instruments:
			var lead_pattern = [0, 5, 7, 5, 0, 4, 7, 12]  # Modal, uses 4ths/5ths
			var note_samples = _idiv(samples_per_chord, 8)
			var prev_freq = chord_freqs[0] * 2.0
			
			for n in range(8):
				var start = n * note_samples
				var offset = lead_pattern[n]
				var target_freq = chord_freqs[0] * 2.0 * pow(2.0, offset / 12.0)
				
				for j in range(note_samples):
					var t = float(j) / SAMPLE_RATE
					var note_progress = float(j) / note_samples
					
					# Portamento (glide from previous note)
					var glide_amount = exp(-note_progress * 15.0)
					var freq = target_freq + (prev_freq - target_freq) * glide_amount
					
					# Vibrato (5Hz, delayed onset)
					var vib = 0.0
					if note_progress > 0.25:
						vib = sin(2.0 * PI * 5.0 * t) * 0.012 * (note_progress - 0.25) / 0.75
					freq *= (1.0 + vib)
					
					# Bright sawtooth
					var lead = fmod(t * freq, 1.0) * 2.0 - 1.0
					lead += fmod(t * freq * 1.003, 1.0) * 2.0 - 1.0  # Slight detune
					lead *= 0.5
					
					# Filter (bright, research: 3500Hz)
					lead = tanh(lead * 1.3)
					
					# Envelope
					var env = 1.0
					if note_progress < 0.03: env = note_progress / 0.03
					elif note_progress > 0.85: env = (1.0 - note_progress) / 0.15
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += lead * env * 0.12 * energy_level
				
				prev_freq = target_freq
		
		# === MOTORIK V2 ===
		# Frequency: sub (kick), presence (snare), air (hats)
		# Research: 4/4 kick, 8th hats (driving), humanized
		if "motorik_v2" in instruments:
			var eighth_samples = _idiv(samples_per_chord, 8)
			
			for beat in range(8):
				# Humanize timing (ÃƒÆ’Ã¢â‚¬Å¡Ãƒâ€šÃ‚Â±5ms - less than other genres, prog is tighter)
				var humanize = int((randf() - 0.5) * SAMPLE_RATE * 0.005)
				var start = beat * eighth_samples + humanize
				start = clampi(start, 0, samples_per_chord - 1)
				
				# Velocity humanization
				var vel = 0.9 + randf() * 0.1
				
				# KICK on every beat (4/4)
				if beat % 2 == 0:
					for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
						var kt = float(j) / SAMPLE_RATE
						# Pitch envelope
						var kick_freq = 55.0 * exp(-kt * 25.0) + 42.0
						var kick = sin(2.0 * PI * kick_freq * kt) * exp(-kt * 9.0)
						if start + j < samples_per_chord:
							chord_mix[start + j] += kick * 0.28 * vel * energy_level
				
				# SNARE on 3 and 7
				if beat == 2 or beat == 6:
					for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
						var st = float(j) / SAMPLE_RATE
						var snare = sin(2.0 * PI * 200.0 * st) * exp(-st * 20.0) * 0.4
						snare += (randf() - 0.5) * exp(-st * 22.0) * 0.35
						if start + j < samples_per_chord:
							chord_mix[start + j] += snare * 0.15 * vel * energy_level
				
				# HI-HAT on every 8th (motorik signature)
				# Vary open/closed for interest without fatigue
				var is_open = beat % 4 == 2
				var hat_decay = 40.0 if not is_open else 20.0
				var hat_length = SAMPLE_RATE * 0.03 if not is_open else SAMPLE_RATE * 0.06
				
				for j in range(min(int(hat_length), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-ht * hat_decay)
					if start + j < samples_per_chord:
						chord_mix[start + j] += hat * 0.07 * vel * energy_level
		
		# Mix into final buffer with soft limiting
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				# Soft limit
				sample = tanh(sample * 0.9)
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.02))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


# === K-POP PROG REMIX ===
# 70s Progressive Rock (ELP, Kraftwerk, Yes) meets K-Pop (BTS, BLACKPINK, aespa)
# CONSTANT BEAT - groove NEVER stops, same kick/snare throughout
# Key modulation: Em ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ G major (lift) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Fm (climax) ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ loops
# Research: ada_the_research/music_tracks/kpop_prog_remix.md
static func generate_kpop_prog_song(parameters: Dictionary = {}) -> AudioStreamInteractive:
	parameters = _merge_with_song_research_parameters("kpop_prog_remix", parameters)
	randomize()
	var bpm = 118.0  # Classic K-pop tempo
	var bar_duration = 240.0 / bpm
	
	# E minor - prog classic
	var root_note = "E3"
	var scale_em = PopMusicTheory.get_minor_scale_notes(root_note)  # E minor
	var scale_g = PopMusicTheory.get_major_scale_notes("G3")  # G major (relative major - KEY CHANGE 1)
	var scale_fm = PopMusicTheory.get_minor_scale_notes("F3")  # F minor (half step up - KEY CHANGE 2)
	
	# Progressions
	var main_prog = [0, 5, 3, 4]  # i - VI - iv - V
	var lift_prog = [0, 2, 5, 4]  # Ascending feel
	
	print("AudioSynthesizer: Generating K-Pop Prog Remix - CONSTANT BEAT - Em ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ G ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ Fm")
	
	var playback = AudioStreamInteractive.new()
	playback.clip_count = 5
	playback.initial_clip = 0
	
	# === CONSTANT BEAT STRUCTURE ===
	# ALL sections have "constant_beat" - same 4/4 kick+snare+hats throughout
	# Only melodic/harmonic content changes
	
	# 0. INTRO: Beat + sequence (Em)
	var intro = _generate_kpop_prog_section(main_prog, scale_em, 
		["constant_beat", "kraftwerk_seq"], bar_duration, bpm, 0.7)
	playback.set_clip_stream(0, intro)
	playback.set_clip_name(0, "Intro")
	playback.set_clip_auto_advance(0, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(0, 1)
	
	# 1. VERSE: Beat + mellotron + bass (Em)
	var verse = _generate_kpop_prog_section(main_prog, scale_em, 
		["constant_beat", "mellotron_kpop", "sub_808"], bar_duration, bpm, 0.8)
	playback.set_clip_stream(1, verse)
	playback.set_clip_name(1, "Verse")
	playback.set_clip_auto_advance(1, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(1, 2)
	
	# 2. CHORUS: Beat + supersaw + bass + stabs (G major - KEY CHANGE 1)
	var chorus = _generate_kpop_prog_section(lift_prog, scale_g,
		["constant_beat", "supersaw_kpop", "sub_808", "chant_stab", "kraftwerk_seq"], bar_duration, bpm, 1.0)
	playback.set_clip_stream(2, chorus)
	playback.set_clip_name(2, "Chorus (G)")
	playback.set_clip_auto_advance(2, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(2, 3)
	
	# 3. KILL PART: Beat + Moog lead (Em - resolves back)
	var kill_part = _generate_kpop_prog_section(main_prog, scale_em,
		["constant_beat", "neomoog_lead", "sub_808", "kraftwerk_seq"], bar_duration, bpm, 1.0)
	playback.set_clip_stream(3, kill_part)
	playback.set_clip_name(3, "Kill Part")
	playback.set_clip_auto_advance(3, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(3, 4)
	
	# 4. FINAL: Beat + everything (Fm - KEY CHANGE 2, half step up)
	var final_chorus = _generate_kpop_prog_section(lift_prog, scale_fm,
		["constant_beat", "supersaw_kpop", "sub_808", "chant_stab", "neomoog_lead"], bar_duration, bpm, 1.1)
	playback.set_clip_stream(4, final_chorus)
	playback.set_clip_name(4, "Final (Fm)")
	playback.set_clip_auto_advance(4, AudioStreamInteractive.AUTO_ADVANCE_ENABLED)
	playback.set_clip_auto_advance_next_clip(4, 0)  # Loops back to intro
	
	# Tight crossfades (beat continuous)
	var xfade = 0.5  # Very short - beat doesn't break
	for i in range(4):
		playback.add_transition(i, i + 1, AudioStreamInteractive.TRANSITION_FROM_TIME_END, 
			AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	playback.add_transition(4, 0, AudioStreamInteractive.TRANSITION_FROM_TIME_END, 
		AudioStreamInteractive.TRANSITION_TO_TIME_START, AudioStreamInteractive.FADE_CROSS, xfade)
	
	return playback


static func _generate_kpop_prog_section(progression: Array, scale: Array, instruments: Array,
		bar_duration: float, bpm: float, energy: float) -> AudioStreamWAV:
	var total_duration = progression.size() * bar_duration * 2
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	var samples_per_chord = int(bar_duration * 2 * SAMPLE_RATE)
	var sixteenth = int(60.0 / bpm / 4.0 * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		# === KRAFTWERK SEQUENCE (Intro/Outro/Pre-Chorus) ===
		# 16th note pulse arp, Autobahn meets EDM build
		if "kraftwerk_seq" in instruments:
			var arp_pattern = [0, 12, 7, 12, 0, 12, 7, 12, 0, 7, 12, 7, 0, 12, 7, 0]
			for step in range(16):
				var start = step * sixteenth
				var note_offset = arp_pattern[step]
				var freq = root_freq * pow(2.0, note_offset / 12.0)
				
				for j in range(min(sixteenth, samples_per_chord - start)):
					var t = float(j) / SAMPLE_RATE
					var step_progress = float(j) / sixteenth
					
					# Pulse wave (Kraftwerk character)
					var pulse_width = 0.5 + sin(t * 3.0) * 0.1
					var pulse = 1.0 if fmod(t * freq, 1.0) < pulse_width else -1.0
					
					# Filter sweep (slow LFO)
					var filter_mod = 0.5 + 0.5 * sin(t * 0.25 * TAU)
					pulse *= 0.3 + filter_mod * 0.5
					
					# Sharp decay envelope
					var env = exp(-step_progress * 8.0)
					
					if start + j < samples_per_chord:
						chord_mix[start + j] += pulse * env * 0.18 * energy
		
		# === MELLOTRON PAD (Verse atmosphere - prog DNA) ===
		if "mellotron_kpop" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				
				# Tape wow/flutter (prog character)
				var wow = sin(t * 0.2 * TAU) * 0.004
				
				for freq in chord_freqs:
					var f = freq * (1.0 + wow)
					# Filtered saw + noise = Mellotron strings
					var saw = fmod(t * f, 1.0) * 2.0 - 1.0
					var noise = (randf() - 0.5) * 0.1
					pad += (saw * 0.7 + noise) * 0.33
				
				pad /= chord_freqs.size()
				
				# Slow attack (Mellotron character)
				var env = 1.0
				if progress < 0.15: env = progress / 0.15
				elif progress > 0.9: env = (1.0 - progress) / 0.1
				
				chord_mix[j] += pad * env * 0.2 * energy
		
		# === SUPERSAW PAD (Chorus lift - K-pop DNA) ===
		if "supersaw_kpop" in instruments:
			for j in range(samples_per_chord):
				var t = float(j) / SAMPLE_RATE
				var progress = float(j) / samples_per_chord
				var pad = 0.0
				
				for freq in chord_freqs:
					# 7-voice supersaw (JP-8000 style)
					for voice in range(7):
						var detune_cents = (float(voice) / 6.0 - 0.5) * 25.0
						var detune_ratio = pow(2.0, detune_cents / 1200.0)
						var saw = fmod(t * freq * detune_ratio, 1.0) * 2.0 - 1.0
						pad += saw / 7.0
				
				pad /= chord_freqs.size()
				
				# Sidechain pumping (K-pop character)
				var beat_phase = fmod(t * bpm / 60.0, 1.0)
				var sidechain = 0.4 + 0.6 * (1.0 - exp(-beat_phase * 6.0))
				
				var env = sin(PI * progress) * 0.8 + 0.2
				chord_mix[j] += pad * env * sidechain * 0.22 * energy
		
		# === 808 SUB BASS (K-pop foundation) ===
		if "sub_808" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			# Sub hits pattern: [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,1]
			var sub_steps = [0, 8, 15]
			for step in sub_steps:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.4), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					# Pitch drop
					var sub_freq = 60.0 * pow(2.0, -st * 0.3)
					var sub = sin(TAU * sub_freq * st) * exp(-st * 2.5)
					# Warm saturation
					sub = tanh(sub * 1.3)
					if start + j < samples_per_chord:
						chord_mix[start + j] += sub * 0.35 * energy
		
		# === TRAP DRUMS (Verse - K-pop DNA) ===
		if "trap_drums" in instruments:
			# Kick pattern: [1,0,0,0, 0,0,0,0, 1,0,1,0, 0,0,0,0]
			var kick_steps = [0, 8, 10]
			for step in kick_steps:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick_freq = 55.0 + exp(-kt * 40.0) * 100.0
					var kick = sin(TAU * kick_freq * kt) * exp(-kt * 10.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.45 * energy
			
			# Snare on 4 and 12
			for step in [4, 12]:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(TAU * 180.0 * st) * exp(-st * 18.0) * 0.4
					snare += (randf() - 0.5) * exp(-st * 20.0) * 0.4
					if start + j < samples_per_chord:
						chord_mix[start + j] += snare * 0.28 * energy
		
		# === HI-HAT ROLLS (Trap character) ===
		if "hihat_rolls" in instruments:
			for step in range(16):
				var start = step * sixteenth
				# Velocity roll pattern
				var vel = 0.5 + (float(step % 4) / 4.0) * 0.5
				for j in range(min(int(SAMPLE_RATE * 0.025), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-ht * 80.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += hat * 0.1 * vel * energy
		
		# === MOTORIK DRUMS (Pre-Chorus - prog DNA) ===
		if "motorik_kpop" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			# 4-on-floor kick
			for beat in range(4):
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick_freq = 55.0 + exp(-kt * 35.0) * 80.0
					var kick = sin(TAU * kick_freq * kt) * exp(-kt * 12.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.42 * energy
			
			# Snare on 2 and 4
			for beat in [1, 3]:
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(TAU * 200.0 * st) * exp(-st * 20.0) * 0.35
					snare += (randf() - 0.5) * exp(-st * 25.0) * 0.35
					if start + j < samples_per_chord:
						chord_mix[start + j] += snare * 0.22 * energy
			
			# Offbeat hi-hats (Kraftwerk signature)
			for beat in range(8):
				if beat % 2 == 1:
					var start = _idiv(beat * beat_samples, 2)
					for j in range(min(int(SAMPLE_RATE * 0.03), samples_per_chord - start)):
						var ht = float(j) / SAMPLE_RATE
						var hat = (randf() - 0.5) * exp(-ht * 60.0)
						if start + j < samples_per_chord:
							chord_mix[start + j] += hat * 0.12 * energy
		
		# === CONSTANT BEAT (Same groove in EVERY section - never stops) ===
		if "constant_beat" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			
			# KICK: Solid 4-on-floor - never changes
			for beat in range(4):
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick_freq = 55.0 + exp(-kt * 35.0) * 85.0
					var kick = sin(TAU * kick_freq * kt) * exp(-kt * 11.0)
					kick = tanh(kick * 1.3)  # Warm saturation
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.48 * energy
			
			# SNARE: 2 and 4 - always
			for beat in [1, 3]:
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.09), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(TAU * 190.0 * st) * exp(-st * 18.0) * 0.4
					snare += (randf() - 0.5) * exp(-st * 20.0) * 0.45
					if start + j < samples_per_chord:
						chord_mix[start + j] += snare * 0.3 * energy
			
			# HI-HATS: Steady 8ths with offbeat accent - constant pulse
			for eighth in range(8):
				var start = _idiv(eighth * beat_samples, 2)
				var is_offbeat = eighth % 2 == 1
				var hat_vol = 0.12 if is_offbeat else 0.08  # Offbeat accent
				for j in range(min(int(SAMPLE_RATE * 0.03), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-ht * 65.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += hat * hat_vol * energy
		
		# === MOTORIK LIGHT (Intro groove - keeps beat but lighter) ===
		if "motorik_light" in instruments:
			var beat_samples = int(60.0 / bpm * SAMPLE_RATE)
			# Softer 4-on-floor kick
			for beat in range(4):
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick_freq = 50.0 + exp(-kt * 30.0) * 60.0
					var kick = sin(TAU * kick_freq * kt) * exp(-kt * 14.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.28 * energy
			
			# Light snare on 2 and 4 (quieter)
			for beat in [1, 3]:
				var start = beat * beat_samples
				for j in range(min(int(SAMPLE_RATE * 0.06), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(TAU * 200.0 * st) * exp(-st * 25.0) * 0.25
					snare += (randf() - 0.5) * exp(-st * 30.0) * 0.25
					if start + j < samples_per_chord:
						chord_mix[start + j] += snare * 0.15 * energy
		
		# === CHORUS DRUMS (Full power) ===
		if "chorus_drums" in instruments:
			# Kick: [1,0,0,0, 0,0,1,0, 1,0,0,0, 0,0,1,0]
			var kick_steps = [0, 6, 8, 14]
			for step in kick_steps:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.12), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick_freq = 55.0 + exp(-kt * 45.0) * 110.0
					var kick = sin(TAU * kick_freq * kt) * exp(-kt * 11.0)
					kick = tanh(kick * 1.5)
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.5 * energy
			
			# Snare + Clap layered: [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,1]
			for step in [4, 12, 15]:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(TAU * 185.0 * st) * exp(-st * 16.0) * 0.45
					snare += (randf() - 0.5) * exp(-st * 18.0) * 0.45
					if start + j < samples_per_chord:
						chord_mix[start + j] += snare * 0.3 * energy
			
			# Glitchy hi-hats: [1,0,1,1, 0,1,1,0, 1,0,1,1, 0,1,1,0]
			var hat_steps = [0, 2, 3, 5, 6, 8, 10, 11, 13, 14]
			for step in hat_steps:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.025), samples_per_chord - start)):
					var ht = float(j) / SAMPLE_RATE
					var hat = (randf() - 0.5) * exp(-ht * 70.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += hat * 0.1 * energy
		
		# === PROG DRUMS (Dance Break - syncopated) ===
		if "prog_drums" in instruments:
			# Complex kick: [1,0,1,0, 0,1,0,0, 1,0,1,0, 0,1,0,1]
			var kick_steps = [0, 2, 5, 8, 10, 13, 15]
			for step in kick_steps:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.1), samples_per_chord - start)):
					var kt = float(j) / SAMPLE_RATE
					var kick_freq = 55.0 + exp(-kt * 38.0) * 90.0
					var kick = sin(TAU * kick_freq * kt) * exp(-kt * 11.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += kick * 0.45 * energy
			
			# Complex snare: [0,0,0,0, 1,0,0,1, 0,0,0,0, 1,0,1,0]
			for step in [4, 7, 12, 14]:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var snare = sin(TAU * 200.0 * st) * exp(-st * 20.0) * 0.4
					snare += (randf() - 0.5) * exp(-st * 22.0) * 0.4
					if start + j < samples_per_chord:
						chord_mix[start + j] += snare * 0.25 * energy
		
		# === NEO-MOOG LEAD (Kill Part - screaming prog lead) ===
		if "neomoog_lead" in instruments:
			# Melody pattern: ascending prog run
			var melody_notes = [0, 2, 4, 7, 9, 12, 9, 7]  # Dorian ascending
			var prev_freq = root_freq * 2.0
			
			for note_idx in range(melody_notes.size()):
				var note_start = _idiv(note_idx * samples_per_chord, melody_notes.size())
				var note_samples = _idiv(samples_per_chord, melody_notes.size())
				var target_freq = root_freq * 2.0 * pow(2.0, melody_notes[note_idx] / 12.0)
				
				for j in range(note_samples):
					if note_start + j >= samples_per_chord:
						break
					var t = float(j) / SAMPLE_RATE
					var note_progress = float(j) / note_samples
					
					# Portamento (80ms glide - ELP character)
					var porta_time = 0.08
					var freq = prev_freq
					if t < porta_time:
						freq = prev_freq + (target_freq - prev_freq) * (t / porta_time)
					else:
						freq = target_freq
					
					# 3 detuned saws
					var lead = 0.0
					for voice in range(3):
						var detune = [0.0, 7.0, -7.0][voice]
						var d_ratio = pow(2.0, detune / 1200.0)
						lead += fmod(t * freq * d_ratio, 1.0) * 2.0 - 1.0
					lead /= 3.0
					
					# Filter envelope (bright attack)
					var filter_env = 0.4 + 0.6 * exp(-note_progress * 3.0)
					lead *= filter_env
					
					# Amplitude envelope
					var env = 1.0
					if note_progress < 0.05: env = note_progress / 0.05
					elif note_progress > 0.85: env = (1.0 - note_progress) / 0.15
					
					chord_mix[note_start + j] += lead * env * 0.2 * energy
				
				prev_freq = target_freq
		
		# === CHANT STAB (Hook accent - "Moog-a-Moog-a") ===
		if "chant_stab" in instruments:
			# Stab pattern: syncopated on chord hits
			var stab_steps = [0, 3, 6, 8, 11]
			for step in stab_steps:
				var start = step * sixteenth
				for j in range(min(int(SAMPLE_RATE * 0.08), samples_per_chord - start)):
					var st = float(j) / SAMPLE_RATE
					var stab = 0.0
					for freq in chord_freqs:
						stab += sin(TAU * freq * 2.0 * st)
					stab /= chord_freqs.size()
					stab *= exp(-st * 18.0)
					if start + j < samples_per_chord:
						chord_mix[start + j] += stab * 0.2 * energy
		
		# === BUILD RISER (Pre-Chorus tension) ===
		if "build_riser" in instruments:
			for j in range(samples_per_chord):
				var progress = float(j) / samples_per_chord
				var t = float(j) / SAMPLE_RATE
				# Noise sweep up
				var noise = (randf() - 0.5)
				# High-pass that opens (build character)
				var hp_amount = progress * 0.5
				noise *= hp_amount * progress
				chord_mix[j] += noise * 0.08 * energy
		
		# Mix into final with soft limiting
		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				sample = tanh(sample * 0.9)
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)
	
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.015))
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)


static func generate_pop_song_async(parameters: Dictionary, callback_object: Object, callback_method: String):
	if is_generating:
		print("AudioSynthesizer: Already generating sound")
		return

	if not generation_thread:
		generation_thread = Thread.new()
	
	is_generating = true
	print("AudioSynthesizer: Starting background generation...")
	
	# Pass data as a single dictionary to the thread function
	var thread_data = {
		"params": parameters,
		"callback_obj": callback_object,
		"callback_method": callback_method
	}
	
	generation_thread.start(_thread_generate_pop_song.bind(thread_data))

static func _thread_generate_pop_song(data: Dictionary):
	print("AudioSynthesizer: Thread started")
	var stream = null
	var song_type = data.params.get("type", "POP")
	
	match song_type:
		"AMBIENT":
			stream = generate_ambient_works_song(data.params)
		"PROG_SYNTH":
			stream = generate_prog_synth_song(data.params)
		_:
			stream = generate_pop_interactive_song(data.params)
	
	_on_generation_complete.call_deferred(stream, data)

static func _on_generation_complete(stream: AudioStreamInteractive, data: Dictionary):
	print("AudioSynthesizer: Background generation complete")
	
	if generation_thread.is_alive():
		generation_thread.wait_to_finish()
	
	is_generating = false
	
	if data.callback_obj and data.callback_obj.has_method(data.callback_method):
		data.callback_obj.call(data.callback_method, stream)

static func _generate_pop_section_stream(progression: Array, scale: Array, instruments: Array) -> AudioStreamWAV:
	var total_duration = progression.size() * BAR_DURATION
	var total_samples = int(total_duration * SAMPLE_RATE)
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)
	
	var samples_per_chord = int(BAR_DURATION * SAMPLE_RATE)
	
	for i in range(progression.size()):
		var degree = progression[i]
		var chord_freqs = PopMusicTheory.get_chord_frequencies(scale, degree)
		var root_freq = chord_freqs[0]
		var bass_freq = root_freq * 0.25
		
		var chord_mix = PackedFloat32Array()
		chord_mix.resize(samples_per_chord)
		chord_mix.fill(0.0)
		
		if "pad" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_juno_chorus_pad(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.5)
			
		if "keys" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_dx7_ballad_keys(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.6)
			
		if "bass" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_funk_bass(data, samples_per_chord, bass_freq)
			_mix_into(chord_mix, data, 0.7)

		if "lead" in instruments:
			var data = PackedFloat32Array(); data.resize(samples_per_chord)
			_generate_obxa_brass(data, samples_per_chord, chord_freqs)
			_mix_into(chord_mix, data, 0.4)

		if "drums" in instruments:
			var beat_samples = int(samples_per_chord / 4.0)
			var kick_data = PackedFloat32Array(); kick_data.resize(int(SAMPLE_RATE * 0.2))
			_generate_tr909_kick(kick_data, kick_data.size())
			var hat_data = PackedFloat32Array(); hat_data.resize(int(SAMPLE_RATE * 0.1))
			_generate_acid_606_hihat(hat_data, hat_data.size())
			
			var drum_mix = PackedFloat32Array(); drum_mix.resize(samples_per_chord); drum_mix.fill(0.0)
			_mix_at_offset(drum_mix, kick_data, 0, 0.8)
			_mix_at_offset(drum_mix, kick_data, beat_samples * 2, 0.8)
			var hat_offset = int(beat_samples * 0.5)
			for b in range(4):
				_mix_at_offset(drum_mix, hat_data, b * beat_samples + hat_offset, 0.4)
			_mix_into(chord_mix, drum_mix, 1.0)

		var start_idx = i * samples_per_chord
		for j in range(samples_per_chord):
			if start_idx + j < total_samples:
				var sample = chord_mix[j]
				if is_nan(sample) or is_inf(sample):
					sample = 0.0
				final_mix[start_idx + j] = clampf(sample, -1.0, 1.0)

	# Anti-Pop Fade (10ms fade in/out) ensures zero-crossing at clip boundaries
	_apply_fade_envelope(final_mix, int(SAMPLE_RATE * 0.01))
				
	return _create_audio_stream(final_mix, AudioStreamWAV.LOOP_DISABLED)

static func _apply_fade_envelope(buffer: PackedFloat32Array, fade_length: int):
	var size = buffer.size()
	if size < fade_length * 2:
		fade_length = size / 2
		
	for i in range(fade_length):
		var t = float(i) / float(fade_length)
		# Fade In
		buffer[i] *= t
		# Fade Out
		buffer[size - 1 - i] *= t


static func _mix_into(target: PackedFloat32Array, source: PackedFloat32Array, level: float):
	for i in range(min(target.size(), source.size())):
		target[i] += source[i] * level

static func _mix_at_offset(target: PackedFloat32Array, source: PackedFloat32Array, offset: int, level: float):
	var end = min(target.size(), offset + source.size())
	for i in range(offset, end):
		target[i] += source[i - offset] * level

# Sound type definitions
enum SoundType {
	BASIC_SINE_WAVE,   # Simple sine wave - perfect for learning
	PICKUP_MARIO,      # Mario-style pickup sound
	TELEPORT_DRONE,    # Electrostatic synth drone
	LIFT_BASS_PULSE,   # Bass pulse for lifts
	GHOST_DRONE,       # Ghostly atmospheric drone
	MELODIC_DRONE,     # Beautiful melodic drone
	LASER_SHOT,        # Sci-fi laser beam - frequency sweeps
	POWER_UP_JINGLE,   # Achievement/reward - musical harmony
	EXPLOSION,         # Impact/destruction - multi-band synthesis
	RETRO_JUMP,        # Classic platformer jump - pitch bend
	SHIELD_HIT,        # Metallic impact - ring modulation
	AMBIENT_WIND,      # Atmospheric texture - filtered noise
	ARTIFACT_REVEAL_SHIMMER, # Shimmering artifact reveal cue
	DARK_808_KICK,     # Deep 808 kick with pitch envelope and click attack
	ACID_606_HIHAT,    # Filtered noise hi-hat with metallic ring characteristic of 606
	DARK_808_SUB_BASS, # Deep sub bass with slow modulation and dark character
	AMBIENT_AMIGA_DRONE, # Multi-layered ambient drone with slow modulation and detuning
	MOOG_BASS_LEAD,    # Classic Moog lead/bass with ladder filter and oscillator sync
	TB303_ACID_BASS,   # Roland TB-303 acid bass with characteristic filter sweep
	DX7_ELECTRIC_PIANO, # Yamaha DX7 FM electric piano - the sound of the 80s
	C64_SID_LEAD,      # Commodore 64 SID chip lead sound with PWM and ring modulation
	AMIGA_MOD_SAMPLE,  # Amiga ProTracker style sample with Paula chip characteristics
	# Additional vintage synthesizer sounds
	PPG_WAVE_PAD,      # PPG Wave 2.2 wavetable pad
	TR909_KICK,        # Roland TR-909 kick drum
	JUPITER_8_STRINGS, # Roland Jupiter-8 string ensemble
	KORG_M1_PIANO,     # Korg M1 digital piano
	ARP_2600_LEAD,     # ARP 2600 analog lead synthesizer
	SYNARE_3_DISCO_TOM, # Star Instruments Synare 3 disco tom
	SYNARE_3_COSMIC_FX, # Star Instruments Synare 3 cosmic FX
	MOOG_KRAFTWERK_SEQUENCER, # Moog-style Kraftwerk sequencer
	HERBIE_HANCOCK_MOOG_FUSION, # Herbie Hancock jazz-fusion Moog
	APHEX_TWIN_MODULAR, # Aphex Twin experimental modular synthesis
	FLYING_LOTUS_SAMPLER, # Flying Lotus beat machine sampler-synth
	# Sci-Fi / Half-Life inspired sounds
	SCI_FI_LAB_HUM_CLEAN,    # Sterile, multi-layered sine wave hum
	SCI_FI_RESONANT_DRONE,   # Evolving metallic swells (FM)
	SCI_FI_DATA_CHIRPS,      # Randomized computer activity
	SCI_FI_VENTILATION,      # Filtered air texture
	SCI_FI_ELECTROMAGNETIC,  # Subtle tech interference
	# Cinematic / Movie-inspired sounds
	CS80_BRASS_LEAD,         # Vangelis-style CS-80 brass lead
	CINEMATIC_432HZ_PAD,      # Warm pad tuned to 432Hz base
	# Pop Music / Synth Legends
	POP_JUNO_CHORUS_PAD,     # Roland Juno-106 Lush Pad
	POP_DX7_BALLAD_KEYS,     # Yamaha DX7 E-Piano
	POP_OBXA_BRASS,          # Oberheim OB-Xa Jump Brass
	POP_PROPHET_LEAD,        # Prophet-5 Sync Lead
	POP_FUNK_BASS,           # Minimoog Funk Bass
	POP_INTERACTIVE_SONG,    # Procedural Pop Song (Interactive Stream)
	AMBIENT_WORKS_SONG,      # Aphex Twin Style Ambient (Interactive Stream)
	# Biological / Ambient sounds
	HEARTBEAT,               # Biological heartbeat with lub-dub rhythm
	LAB_HUM,                 # Sterile lab ambience with multi-layered sine hum
	# Space Dystopia Album - New sounds
	PROCESSED_VOCAL_PAD,     # Arrival-style alien processed voice texture
	INDUSTRIAL_ANVIL,        # Terminator-style metallic industrial hit
	TRIP_HOP_BEAT,           # Massive Attack style slow breakbeat
	ETHNIC_TABLA,            # Tabla-style hand drum synthesis
	GAMELAN_BELL,            # Indonesian gamelan metallic bell
	ORGAN_SWELL,             # Interstellar-style church organ pad
	NOIR_SAX,                # Jazz noir saxophone with breath modeling
	CHOIR_PAD,               # Ethereal choir vowel morph (ooh-aah)
	REVERSED_SWELL,          # Pre-echo reversed reverb effect
	BLADE_RUNNER_BRASS,      # CS-80 style massive brass swell
	# Classic Synth Era
	PROG_SYNTH_SONG,         # 70s Prog Rock - ELP/Kraftwerk/Yes style (Interactive Stream)
	# Experimental / Algorithmic Pioneers
	RADIOPHONIC_WORKSHOP,    # BBC Radiophonic Workshop - Delia Derbyshire style
	XENAKIS_STOCHASTIC,      # Iannis Xenakis - mathematical/stochastic composition
	SPIEGEL_INTELLIGENT,     # Laurie Spiegel - Music Mouse algorithmic harmony
	AUTECHRE_FLUTTER,        # Autechre - non-repetitive rhythms, glitch
	IKEDA_DATAPLEX,          # Ryoji Ikeda - data sonification, minimal sine/noise
	ECCOJAM_DRIFT,           # OPN/Chuck Person - slowed loops, vaporwave
	CELLULAR_AUTOMATA,       # Wolfram/Conway - generative cellular automata music
	# Pop & EDM Genre-Defining Sounds
	MORODER_DISCO_BASS,      # Giorgio Moroder - "I Feel Love" sequenced bass
	PROPHET_PAD,             # Prophet-5 warm pad (Thriller era)
	PRINCE_SYNC_LEAD,        # Prince - aggressive sync lead
	ELECTRO_808,             # Afrika Bambaataa - Planet Rock electro
	DETROIT_TECHNO,          # Juan Atkins - cold machine funk
	HOUSE_ORGAN,             # Frankie Knuckles - Chicago house organ stab
	RAVE_STAB,               # The Prodigy - aggressive rave stab
	SUPERSAW_PROGRESSIVE,    # Deadmau5 - sidechain supersaw
	WOBBLE_BASS,             # Skrillex - dubstep wobble
	SYNTHWAVE_LEAD,          # The Weeknd - retro-futurist synthwave
	# Space Dystopia Soundscape Pop
	SPACE_CHOIR_PAD,         # Sacred choir vowel pad
	CINEMATIC_STRINGS,       # Slow attack string ensemble
	INDUSTRIAL_CLANK,        # Metal factory hit
	RAIN_ATMOSPHERE,         # Rain and urban ambience
	WAVETABLE_MORPH,         # Slowly evolving wavetable
	PEDAL_STEEL_SWELL,       # Country/ambient steel guitar
	GLITCH_CHAOS,            # Digital chaos and artifacts
	NOIR_SAX_BREATH,         # Breathy jazz saxophone
	SPACE_SUB_DRONE,         # Deep sub bass drone
	# Expressive Lead & Melodic Sounds
	SUPERSAW_LEAD,           # Trance/EDM - 7 detuned saws, wide stereo
	SYNC_LEAD,               # Aggressive - oscillator sync, harmonically rich
	FM_BELL,                 # DX7 style - metallic, harmonic FM synthesis
	SQUARE_LEAD,             # Chiptune/retro - hollow, punchy
	PORTAMENTO_LEAD,         # Smooth gliding between notes
	VOCAL_FORMANT,           # Vowel sounds - formant filter, "ooh"/"aah"
	BRASS_STAB,              # House/funk - fast attack, filter sweep
	STRING_ENSEMBLE,         # Lush strings that can play melodies
	PLUCK_LEAD,              # Kalimba/marimba style - fast decay, melodic
	GLASS_LEAD,              # Crystalline, bell-like FM
	DISTORTED_LEAD,          # Rock/industrial - tube/fuzz saturation
	BITCRUSHED_LEAD,         # Lo-fi character - bit reduction, aliasing
	# Genre-Defining Bass Sounds
	REESE_BASS,              # DnB essential - detuned saws, phasing movement, dark
	WOBBLE_BASS_CUSTOM,      # Dubstep - LFO on filter cutoff, aggressive (custom impl)
	PLUCK_BASS,              # House/pop - fast attack, medium decay, punchy
	SUB_BASS_SINE,           # Pure sub - clean sine, no harmonics, foundation
	DISTORTED_BASS,          # Rock/industrial - tube saturation, grit
	JUNO_BASS,               # 80s pop - chorus, warmth, Roland character
	MINIMOOG_BASS,           # Funk/soul - ladder filter, fat
	SH101_BASS,              # Acid/electro - single osc, resonant, slidey
	PROPHET_BASS,            # Synthwave - poly aftertouch response, lush
	UPRIGHT_BASS,            # Jazz/lo-fi - body resonance, finger noise
	SLAP_BASS,               # Funk - attack transient, string slap
	PICKED_BASS,             # Rock - pick attack, string vibration
	# Essential Drum Sounds (Production Quality)
	CLAP,                    # TR-909 style layered noise bursts with room character
	OPEN_HIHAT,              # TR-909/808 style long decay metallic hi-hat
	SNARE_ACOUSTIC,          # Layered acoustic snare with body, wires, and air
	RIMSHOT,                 # Wood + metal click for dub/reggae
	# Production Polish Drums
	SHAKER,                  # 16th note groove texture with filtered noise
	TAMBOURINE,              # Pop/disco essential with jingles + shell hit
	RIDE_CYMBAL,             # Jazz/ambient long metallic shimmer
	CRASH_CYMBAL,            # Transition cymbal with noise burst + metallic decay
	# Genre-Specific Drums
	TOM_LOW,                 # Low floor tom for fills and tribal beats
	TOM_MID,                 # Mid rack tom for fills
	TOM_HIGH,                # High rack tom for fills
	CONGA,                   # Latin/house grooves with slap transient
	BONGO                    # Higher pitched percussion fills
}

# Sound generation functions
static func generate_sound(type: SoundType, duration: float = 1.0, parameters: Dictionary = {}) -> AudioStream:
	var sample_count = int(SAMPLE_RATE * duration)
	var data = PackedFloat32Array()
	data.resize(sample_count)
	
	match type:
		SoundType.POP_INTERACTIVE_SONG:
			return generate_pop_interactive_song(parameters)
		SoundType.AMBIENT_WORKS_SONG:
			return generate_ambient_works_song(parameters)
		SoundType.PROG_SYNTH_SONG:
			return generate_prog_synth_song(parameters)
		SoundType.RADIOPHONIC_WORKSHOP:
			_generate_radiophonic_workshop(data, sample_count, parameters)
		SoundType.XENAKIS_STOCHASTIC:
			_generate_xenakis_stochastic(data, sample_count, parameters)
		SoundType.SPIEGEL_INTELLIGENT:
			_generate_spiegel_intelligent(data, sample_count, parameters)
		SoundType.AUTECHRE_FLUTTER:
			_generate_autechre_flutter(data, sample_count, parameters)
		SoundType.IKEDA_DATAPLEX:
			_generate_ikeda_dataplex(data, sample_count, parameters)
		SoundType.ECCOJAM_DRIFT:
			_generate_eccojam_drift(data, sample_count, parameters)
		SoundType.CELLULAR_AUTOMATA:
			_generate_cellular_automata(data, sample_count, parameters)
		SoundType.MORODER_DISCO_BASS:
			_generate_moroder_disco_bass(data, sample_count, parameters)
		SoundType.PROPHET_PAD:
			_generate_prophet_pad(data, sample_count, parameters)
		SoundType.PRINCE_SYNC_LEAD:
			_generate_prince_sync_lead(data, sample_count, parameters)
		SoundType.ELECTRO_808:
			_generate_electro_808(data, sample_count, parameters)
		SoundType.DETROIT_TECHNO:
			_generate_detroit_techno(data, sample_count, parameters)
		SoundType.HOUSE_ORGAN:
			_generate_house_organ(data, sample_count, parameters)
		SoundType.RAVE_STAB:
			_generate_rave_stab(data, sample_count, parameters)
		SoundType.SUPERSAW_PROGRESSIVE:
			_generate_supersaw_progressive(data, sample_count, parameters)
		SoundType.WOBBLE_BASS:
			_generate_wobble_bass(data, sample_count, parameters)
		SoundType.SYNTHWAVE_LEAD:
			_generate_synthwave_lead(data, sample_count, parameters)
		# Space Dystopia sounds
		SoundType.SPACE_CHOIR_PAD:
			_generate_space_choir_pad(data, sample_count, parameters)
		SoundType.CINEMATIC_STRINGS:
			_generate_cinematic_strings(data, sample_count, parameters)
		SoundType.INDUSTRIAL_CLANK:
			_generate_industrial_clank(data, sample_count, parameters)
		SoundType.RAIN_ATMOSPHERE:
			_generate_rain_atmosphere(data, sample_count, parameters)
		SoundType.WAVETABLE_MORPH:
			_generate_wavetable_morph(data, sample_count, parameters)
		SoundType.PEDAL_STEEL_SWELL:
			_generate_pedal_steel_swell(data, sample_count, parameters)
		SoundType.GLITCH_CHAOS:
			_generate_glitch_chaos(data, sample_count, parameters)
		SoundType.NOIR_SAX_BREATH:
			_generate_noir_sax_breath(data, sample_count, parameters)
		SoundType.SPACE_SUB_DRONE:
			_generate_space_sub_drone(data, sample_count, parameters)
		SoundType.BASIC_SINE_WAVE:
			_generate_basic_sine_wave(data, sample_count)
		SoundType.PICKUP_MARIO:
			_generate_pickup_sound(data, sample_count)
		SoundType.TELEPORT_DRONE:
			_generate_teleport_drone(data, sample_count)
		SoundType.LIFT_BASS_PULSE:
			_generate_bass_pulse(data, sample_count)
		SoundType.GHOST_DRONE:
			_generate_ghost_drone(data, sample_count)
		SoundType.MELODIC_DRONE:
			_generate_melodic_drone(data, sample_count)
		SoundType.LASER_SHOT:
			_generate_laser_shot(data, sample_count)
		SoundType.POWER_UP_JINGLE:
			_generate_power_up_jingle(data, sample_count)
		SoundType.EXPLOSION:
			_generate_explosion(data, sample_count)
		SoundType.RETRO_JUMP:
			_generate_retro_jump(data, sample_count)
		SoundType.SHIELD_HIT:
			_generate_shield_hit(data, sample_count)
		SoundType.AMBIENT_WIND:
			_generate_ambient_wind(data, sample_count)
		SoundType.ARTIFACT_REVEAL_SHIMMER:
			_generate_artifact_reveal_shimmer(data, sample_count)
		SoundType.DARK_808_KICK:
			_generate_dark_808_kick(data, sample_count)
		SoundType.ACID_606_HIHAT:
			_generate_acid_606_hihat(data, sample_count)
		SoundType.DARK_808_SUB_BASS:
			_generate_dark_808_sub_bass(data, sample_count)
		SoundType.AMBIENT_AMIGA_DRONE:
			_generate_ambient_amiga_drone(data, sample_count)
		SoundType.MOOG_BASS_LEAD:
			_generate_moog_bass_lead(data, sample_count)
		SoundType.TB303_ACID_BASS:
			_generate_tb303_acid_bass(data, sample_count)
		SoundType.DX7_ELECTRIC_PIANO:
			_generate_dx7_electric_piano(data, sample_count)
		SoundType.C64_SID_LEAD:
			_generate_c64_sid_lead(data, sample_count)
		SoundType.AMIGA_MOD_SAMPLE:
			_generate_amiga_mod_sample(data, sample_count)
		SoundType.PPG_WAVE_PAD:
			_generate_ppg_wave_pad(data, sample_count)
		SoundType.TR909_KICK:
			_generate_tr909_kick(data, sample_count)
		SoundType.JUPITER_8_STRINGS:
			_generate_jupiter_8_strings(data, sample_count)
		SoundType.KORG_M1_PIANO:
			_generate_korg_m1_piano(data, sample_count)
		SoundType.ARP_2600_LEAD:
			_generate_arp_2600_lead(data, sample_count)
		SoundType.SYNARE_3_DISCO_TOM:
			_generate_synare_3_disco_tom(data, sample_count)
		SoundType.SYNARE_3_COSMIC_FX:
			_generate_synare_3_cosmic_fx(data, sample_count)
		SoundType.MOOG_KRAFTWERK_SEQUENCER:
			_generate_moog_kraftwerk_sequencer(data, sample_count)
		SoundType.HERBIE_HANCOCK_MOOG_FUSION:
			_generate_herbie_hancock_moog_fusion(data, sample_count)
		SoundType.APHEX_TWIN_MODULAR:
			_generate_aphex_twin_modular(data, sample_count)
		SoundType.FLYING_LOTUS_SAMPLER:
			_generate_flying_lotus_sampler(data, sample_count)
		SoundType.SCI_FI_LAB_HUM_CLEAN:
			_generate_sci_fi_lab_hum_clean(data, sample_count)
		SoundType.SCI_FI_RESONANT_DRONE:
			_generate_sci_fi_resonant_drone(data, sample_count)
		SoundType.SCI_FI_DATA_CHIRPS:
			_generate_sci_fi_data_chirps(data, sample_count)
		SoundType.SCI_FI_VENTILATION:
			_generate_sci_fi_ventilation(data, sample_count)
		SoundType.SCI_FI_ELECTROMAGNETIC:
			_generate_sci_fi_electromagnetic(data, sample_count)
		SoundType.CS80_BRASS_LEAD:
			_generate_cs80_brass_lead(data, sample_count)
		SoundType.CINEMATIC_432HZ_PAD:
			_generate_cinematic_432hz_pad(data, sample_count)
		SoundType.POP_JUNO_CHORUS_PAD:
			_generate_juno_chorus_pad(data, sample_count)
		SoundType.POP_DX7_BALLAD_KEYS:
			_generate_dx7_ballad_keys(data, sample_count)
		SoundType.POP_OBXA_BRASS:
			_generate_obxa_brass(data, sample_count)
		SoundType.POP_PROPHET_LEAD:
			_generate_prophet_lead(data, sample_count)
		SoundType.POP_FUNK_BASS:
			_generate_funk_bass(data, sample_count)
		SoundType.HEARTBEAT:
			_generate_heartbeat(data, sample_count)
		SoundType.LAB_HUM:
			_generate_lab_hum(data, sample_count)
		# Space Dystopia new sounds
		SoundType.PROCESSED_VOCAL_PAD:
			_generate_processed_vocal_pad(data, sample_count)
		SoundType.INDUSTRIAL_ANVIL:
			_generate_industrial_anvil(data, sample_count)
		SoundType.TRIP_HOP_BEAT:
			_generate_trip_hop_beat(data, sample_count)
		SoundType.ETHNIC_TABLA:
			_generate_ethnic_tabla(data, sample_count)
		SoundType.GAMELAN_BELL:
			_generate_gamelan_bell(data, sample_count)
		SoundType.ORGAN_SWELL:
			_generate_organ_swell(data, sample_count)
		SoundType.NOIR_SAX:
			_generate_noir_sax(data, sample_count)
		SoundType.CHOIR_PAD:
			_generate_choir_pad(data, sample_count)
		SoundType.REVERSED_SWELL:
			_generate_reversed_swell(data, sample_count)
		SoundType.BLADE_RUNNER_BRASS:
			_generate_blade_runner_brass(data, sample_count)
		# Essential Drum Sounds - routed to CustomSoundGenerator
		SoundType.CLAP:
			CustomSoundGenerator.generate_custom_clap(data, sample_count, parameters)
		SoundType.OPEN_HIHAT:
			CustomSoundGenerator.generate_custom_open_hihat(data, sample_count, parameters)
		SoundType.SNARE_ACOUSTIC:
			CustomSoundGenerator.generate_custom_snare_acoustic(data, sample_count, parameters)
		SoundType.RIMSHOT:
			CustomSoundGenerator.generate_custom_rimshot(data, sample_count, parameters)
		SoundType.SHAKER:
			CustomSoundGenerator.generate_custom_shaker(data, sample_count, parameters)
		SoundType.TAMBOURINE:
			CustomSoundGenerator.generate_custom_tambourine(data, sample_count, parameters)
		SoundType.RIDE_CYMBAL:
			CustomSoundGenerator.generate_custom_ride_cymbal(data, sample_count, parameters)
		SoundType.CRASH_CYMBAL:
			CustomSoundGenerator.generate_custom_crash_cymbal(data, sample_count, parameters)
		SoundType.TOM_LOW:
			CustomSoundGenerator.generate_custom_tom(data, sample_count, parameters, "low")
		SoundType.TOM_MID:
			CustomSoundGenerator.generate_custom_tom(data, sample_count, parameters, "mid")
		SoundType.TOM_HIGH:
			CustomSoundGenerator.generate_custom_tom(data, sample_count, parameters, "high")
		SoundType.CONGA:
			CustomSoundGenerator.generate_custom_conga(data, sample_count, parameters)
		SoundType.BONGO:
			CustomSoundGenerator.generate_custom_bongo(data, sample_count, parameters)
	
	return _create_audio_stream(data)

static func _generate_basic_sine_wave(data: PackedFloat32Array, sample_count: int):
	# Simple sine wave: amplitude * sin(2ÃƒÆ’Ã‚ÂÃƒÂ¢Ã¢â‚¬Å¡Ã‚Â¬ * frequency * time)
	var frequency = 440.0  # A4 note
	var amplitude = 0.3
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		data[i] = amplitude * sin(2.0 * PI * frequency * t)

static func _generate_pickup_sound(data: PackedFloat32Array, sample_count: int):
	# Mario-style pickup: rising frequency with envelope
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Rising frequency from 440Hz to 880Hz
		var freq = 440.0 + (440.0 * progress)
		
		# Sharp attack, quick decay envelope
		var envelope = exp(-progress * 8.0)
		
		# Square wave for retro feel
		var wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		
		data[i] = wave * envelope * 0.3

static func _generate_teleport_drone(data: PackedFloat32Array, sample_count: int):
	# Electrostatic drone with modulation - harsh sawtooth with noise
	var _duration = float(sample_count) / SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency with slow modulation
		var base_freq = 220.0
		var mod_freq = 0.5
		var freq = base_freq + sin(2.0 * PI * mod_freq * t) * 30.0
		
		# Sawtooth wave for harsh sound
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add deterministic noise for electrostatic feel (not random for looping)
		var noise_t = t * 1000.0  # High frequency noise
		var noise = sin(noise_t) * 0.3 + sin(noise_t * 1.7) * 0.2 + sin(noise_t * 2.3) * 0.1
		noise = noise * 0.2
		
		# Smooth envelope: fade in -> stay -> fade out -> silence
		var envelope = 0.0
		if progress < 0.05:  # Quick fade in first 5%
			envelope = progress / 0.05
		elif progress < 0.9:  # Stay steady for most of the time
			envelope = 1.0
		elif progress < 0.98:  # Quick fade out
			envelope = (0.98 - progress) / 0.08
		else:  # Silent for last 2%
			envelope = 0.0
		
		# Apply smooth curve to envelope to avoid clicks
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)  # Smoothstep
		
		data[i] = (wave + noise) * 0.2 * envelope

static func _generate_bass_pulse(data: PackedFloat32Array, sample_count: int):
	# Deep bass pulse for lifts
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Very low frequency
		var freq = 60.0
		
		# Pulse envelope - sharp attack, slow decay
		var pulse_rate = 2.0  # 2 Hz pulse
		var pulse = abs(sin(2.0 * PI * pulse_rate * t))
		var envelope = exp(-t * 2.0)
		
		# Sine wave for smooth bass
		var wave = sin(2.0 * PI * freq * t)
		
		data[i] = wave * pulse * envelope * 0.4

static func _generate_ghost_drone(data: PackedFloat32Array, sample_count: int):
	# Ghostly atmospheric drone - designed for seamless looping
	var duration = float(sample_count) / SAMPLE_RATE
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Multiple frequency layers
		var freq1 = 110.0
		var freq2 = 165.0  # Perfect fifth
		var freq3 = 220.0  # Octave
		
		# Slow amplitude modulation that completes full cycles
		var mod_freq = 2.0 / duration  # 2 complete modulation cycles per loop
		var mod = sin(2.0 * PI * mod_freq * t) * 0.3 + 0.7
		
		# Layered sine waves
		var wave = sin(2.0 * PI * freq1 * t) * 0.4
		wave += sin(2.0 * PI * freq2 * t) * 0.3
		wave += sin(2.0 * PI * freq3 * t) * 0.2
		
		data[i] = wave * mod * 0.15

static func _generate_melodic_drone(data: PackedFloat32Array, sample_count: int):
	# Beautiful melodic drone with harmony
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Harmonic series based on 220Hz
		var fundamental = 220.0
		var wave = 0.0
		
		# Add harmonics with decreasing amplitude
		wave += sin(2.0 * PI * fundamental * t) * 0.4        # Fundamental
		wave += sin(2.0 * PI * fundamental * 1.5 * t) * 0.3  # Perfect fifth
		wave += sin(2.0 * PI * fundamental * 2.0 * t) * 0.2  # Octave
		wave += sin(2.0 * PI * fundamental * 3.0 * t) * 0.1  # Perfect fifth above
		
		# Gentle tremolo
		var tremolo = sin(2.0 * PI * 4.0 * t) * 0.1 + 0.9
		
		data[i] = wave * tremolo * 0.2

static func _generate_laser_shot(data: PackedFloat32Array, sample_count: int):
	# Sci-fi laser beam - frequency sweep with sharp attack
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dramatic frequency sweep from high to low
		var start_freq = 2000.0
		var end_freq = 100.0
		var freq = start_freq + (end_freq - start_freq) * (progress * progress)  # Quadratic curve
		
		# Sharp attack, exponential decay
		var envelope = exp(-progress * 12.0) if progress < 0.1 else exp(-(progress - 0.1) * 4.0) * 0.3
		
		# Sawtooth wave for harsh laser character
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Add high-frequency harmonics for electric character
		wave += sin(2.0 * PI * freq * 3.0 * t) * 0.3 * envelope
		
		data[i] = wave * envelope * 0.4

static func _generate_power_up_jingle(data: PackedFloat32Array, sample_count: int):
	# Achievement/reward - ascending arpeggio in C major
	var duration = float(sample_count) / SAMPLE_RATE
	var note_duration = duration / 4.0  # 4 notes
	
	# C major arpeggio: C, E, G, C (262, 330, 392, 523 Hz)
	var frequencies = [262.0, 330.0, 392.0, 523.0]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var note_index = int(t / note_duration)
		note_index = clamp(note_index, 0, 3)
		
		var note_t = fmod(t, note_duration) / note_duration  # Progress within current note
		var freq = frequencies[note_index]
		
		# Bell-like envelope for each note
		var envelope = exp(-note_t * 3.0) * sin(PI * note_t)
		
		# Clean sine wave with subtle harmonics
		var wave = sin(2.0 * PI * freq * t) * 0.8
		wave += sin(2.0 * PI * freq * 2.0 * t) * 0.2  # Octave harmonic
		
		data[i] = wave * envelope * 0.3

static func _generate_explosion(data: PackedFloat32Array, sample_count: int):
	# Multi-band explosion - low rumble, mid crack, high sizzle
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Three frequency bands with different characteristics
		
		# Low rumble (20-100 Hz) - long decay
		var low_freq = 20.0 + sin(2.0 * PI * 0.5 * t) * 30.0
		var low_envelope = exp(-progress * 1.5)
		var low_wave = sin(2.0 * PI * low_freq * t) * low_envelope * 0.6
		
		# Mid crack (200-800 Hz) - sharp attack
		var mid_freq = 400.0 + sin(2.0 * PI * 3.0 * t) * 200.0
		var mid_envelope = exp(-progress * 8.0)
		var mid_wave = (2.0 * (mid_freq * t - floor(mid_freq * t)) - 1.0) * mid_envelope * 0.4
		
		# High sizzle (1-8 kHz) - noise-like, quick decay
		var high_noise = sin(t * 15000.0) * 0.3 + sin(t * 22000.0) * 0.2 + sin(t * 31000.0) * 0.1
		var high_envelope = exp(-progress * 15.0)
		var high_wave = high_noise * high_envelope * 0.3
		
		# Combine all bands
		data[i] = (low_wave + mid_wave + high_wave) * 0.5

static func _generate_retro_jump(data: PackedFloat32Array, sample_count: int):
	# Classic platformer jump - rising pitch with square wave
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Rising frequency curve (like jumping up)
		var start_freq = 150.0
		var peak_freq = 400.0
		var freq = start_freq + (peak_freq - start_freq) * sin(PI * progress * 0.7)  # Rise then level off
		
		# Sharp attack, medium decay
		var envelope = exp(-progress * 4.0) if progress < 0.05 else exp(-(progress - 0.05) * 2.0) * 0.8
		
		# Square wave with variable duty cycle
		var duty = 0.5 + sin(2.0 * PI * 2.0 * t) * 0.1  # Slight duty cycle modulation
		var phase = fmod(freq * t, 1.0)
		var wave = 1.0 if phase < duty else -1.0
		
		data[i] = wave * envelope * 0.35

static func _generate_shield_hit(data: PackedFloat32Array, sample_count: int):
	# Metallic impact - ring modulation and resonance
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Main resonant frequency
		var main_freq = 800.0
		var ring_freq = 60.0  # Ring modulation frequency
		
		# Sharp metallic attack, ringing decay
		var envelope = exp(-progress * 6.0)
		
		# Ring modulated sine wave for metallic character
		var carrier = sin(2.0 * PI * main_freq * t)
		var modulator = sin(2.0 * PI * ring_freq * t) * 0.5 + 0.5
		var ring_mod = carrier * modulator
		
		# Add harmonic resonances
		ring_mod += sin(2.0 * PI * main_freq * 1.5 * t) * 0.4 * envelope
		ring_mod += sin(2.0 * PI * main_freq * 2.0 * t) * 0.2 * envelope
		
		# Add initial impact "clank"
		var impact = exp(-progress * 50.0) * (sin(2.0 * PI * 1200.0 * t) * 0.8)
		
		data[i] = (ring_mod * envelope + impact) * 0.3

static func _generate_ambient_wind(data: PackedFloat32Array, sample_count: int):
	# Atmospheric texture - filtered noise with slow modulation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Generate pseudo-random noise using multiple sine waves
		var noise = 0.0
		noise += sin(t * 100.0) * 0.4
		noise += sin(t * 237.0) * 0.3
		noise += sin(t * 341.0) * 0.2
		noise += sin(t * 567.0) * 0.1
		
		# Low-pass filter simulation (simple averaging)
		# This creates a "whooshing" filtered noise effect
		var filtered_noise = noise * 0.7
		
		# Slow amplitude modulation for wind gusts
		var gust_mod1 = sin(2.0 * PI * 0.2 * t) * 0.3 + 0.7  # 0.2 Hz
		var gust_mod2 = sin(2.0 * PI * 0.07 * t) * 0.2 + 0.8  # 0.07 Hz
		var modulation = gust_mod1 * gust_mod2
		
		# Add subtle tonal elements (like wind through objects)
		var tonal = sin(2.0 * PI * 80.0 * t) * 0.1 + sin(2.0 * PI * 120.0 * t) * 0.05
		
		data[i] = (filtered_noise + tonal) * modulation * 0.2

static func _generate_artifact_reveal_shimmer(data: PackedFloat32Array, sample_count: int, params: Dictionary = {}):
	# Shimmering reveal cue - harmonic cluster + light noise + shimmer LFO
	var duration = float(sample_count) / SAMPLE_RATE
	var base_freq = params.get("base_freq", 880.0)
	var partial_count = int(params.get("partial_count", 5))
	var spread_cents = params.get("spread_cents", 12.0)
	var shimmer_rate = params.get("shimmer_rate", 5.0)
	var shimmer_depth = clamp(params.get("shimmer_depth", 0.4), 0.0, 1.0)
	var noise_amount = params.get("noise_amount", 0.06)
	var attack = max(params.get("attack", 0.02), 0.001)
	var decay = max(params.get("decay", 0.25), 0.001)
	var sustain = clamp(params.get("sustain", 0.4), 0.0, 1.0)
	var release = max(params.get("release", 0.6), 0.001)
	var pitch_rise = params.get("pitch_rise", 0.0)
	var amplitude = params.get("amplitude", 0.35)

	partial_count = clamp(partial_count, 1, 12)

	var ratios = [1.0, 1.5, 2.0, 2.5, 3.0, 3.5]
	var partials: Array[float] = []
	for i in range(partial_count):
		var ratio = ratios[i % ratios.size()]
		var detune_cents = (randf() * 2.0 - 1.0) * spread_cents
		var detune_ratio = pow(2.0, detune_cents / 1200.0)
		partials.append(base_freq * ratio * detune_ratio)

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count

		var pitch_ratio = pow(2.0, (pitch_rise * progress) / 12.0)
		var shimmer = sin(2.0 * PI * shimmer_rate * t + sin(2.0 * PI * shimmer_rate * 0.25 * t) * 0.5)
		shimmer = shimmer * shimmer_depth + (1.0 - shimmer_depth)

		# ADSR envelope
		var env = 1.0
		if t < attack:
			env = t / attack
		elif t < attack + decay:
			var decay_progress = (t - attack) / decay
			env = lerp(1.0, sustain, decay_progress)
		elif t < duration - release:
			env = sustain
		else:
			var release_progress = (t - (duration - release)) / release
			env = sustain * max(0.0, 1.0 - release_progress)

		var wave = 0.0
		for freq in partials:
			wave += sin(2.0 * PI * freq * pitch_ratio * t)
		wave /= float(partials.size())

		var noise = (randf() * 2.0 - 1.0) * noise_amount
		data[i] = (wave + noise) * shimmer * env * amplitude

static func _generate_dark_808_kick(data: PackedFloat32Array, sample_count: int):
	# Deep 808 kick with pitch envelope and click attack
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope - starts at start_freq, drops to end_freq
		var start_freq = 60.0
		var end_freq = 35.0
		var freq = start_freq + (end_freq - start_freq) * (1.0 - exp(-progress * 4.0))
		
		# Main 808 body - sine wave with saturation
		var body = sin(2.0 * PI * freq * t)
		
		# Apply saturation/distortion
		var saturation = 1.5
		body = tanh(body * saturation) / saturation
		
		# Click attack component
		var click_freq = 1200.0
		var click_decay = 80.0
		var click = sin(2.0 * PI * click_freq * t) * exp(-progress * click_decay)
		
		# Amplitude envelope
		var envelope = exp(-progress * 4.0)
		
		data[i] = (body * envelope + click * 0.1) * 0.7

static func _generate_acid_606_hihat(data: PackedFloat32Array, sample_count: int):
	# Filtered noise hi-hat with metallic ring characteristic of 606
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Generate high-frequency noise
		var noise = 0.0
		noise += sin(t * 8000.0 + sin(t * 15000.0)) * 0.4
		noise += sin(t * 12000.0 + sin(t * 18000.0)) * 0.3
		noise += sin(t * 16000.0 + sin(t * 22000.0)) * 0.2
		
		# Apply noise intensity
		noise *= 2.0
		
		# Filter sweep - high-pass filter simulation
		var filter_start_freq = 8000.0
		var filter_sweep = 3000.0
		var filter_freq = filter_start_freq + filter_sweep * progress
		
		# Simple high-pass filtering by reducing low frequencies
		var filtered_noise = noise * (1.0 + filter_freq / 8000.0)
		
		# Metallic ring component
		var metallic_freq = 12000.0
		var ring = sin(2.0 * PI * metallic_freq * t) * 0.2
		
		# Sharp decay envelope
		var envelope = exp(-progress * 15.0)
		
		data[i] = (filtered_noise + ring) * envelope * 0.3

static func _generate_dark_808_sub_bass(data: PackedFloat32Array, sample_count: int):
	# Deep sub bass with slow modulation and dark character
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency with slow modulation
		var base_freq = 35.0
		var mod_freq = 0.3
		var mod_depth = 5.0
		var freq = base_freq + sin(2.0 * PI * mod_freq * t) * mod_depth
		
		# Fundamental sine wave
		var fundamental = sin(2.0 * PI * freq * t)
		
		# Add harmonics for richness
		var harmonic2 = sin(2.0 * PI * freq * 2.0 * t) * 0.1
		var harmonic3 = sin(2.0 * PI * freq * 3.0 * t) * 0.05
		
		# Slow attack and very slow decay
		var envelope = 1.0
		if progress < 0.2:  # Attack phase
			envelope = progress / 0.2
		else:  # Decay phase
			envelope = exp(-(progress - 0.2) * 0.5)
		
		data[i] = (fundamental + harmonic2 + harmonic3) * envelope * 0.5

static func _generate_ambient_amiga_drone(data: PackedFloat32Array, sample_count: int):
	# Multi-layered ambient drone with slow modulation and detuning
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Three frequency layers
		var freq1 = 45.0   # Fundamental
		var freq2 = 90.0   # Octave
		var freq3 = 67.5   # Perfect fifth
		
		# Slow modulation
		var mod_freq = 0.13
		var mod_depth = 0.3
		var mod_offset = 0.7
		var modulation = sin(2.0 * PI * mod_freq * t) * mod_depth + mod_offset
		
		# Layer 1 - fundamental with detuning
		var detune1 = sin(2.0 * PI * 0.07 * t) * 0.7
		var layer1 = sin(2.0 * PI * (freq1 + detune1) * t) * 0.5
		
		# Layer 2 - octave
		var layer2 = sin(2.0 * PI * freq2 * t) * 0.3
		
		# Layer 3 - fifth with slight detuning
		var detune3 = sin(2.0 * PI * 0.11 * t) * 0.5
		var layer3 = sin(2.0 * PI * (freq3 + detune3) * t) * 0.2
		
		# Additional detuned layer for thickness
		var detune_layer = sin(2.0 * PI * (freq1 + 0.7) * t) * 0.1
		
		# Combine all layers
		var combined = (layer1 + layer2 + layer3 + detune_layer) * modulation
		
		data[i] = combined * 0.3

static func _generate_moog_bass_lead(data: PackedFloat32Array, sample_count: int):
	# Classic Moog lead/bass with ladder filter and oscillator sync
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillator setup
		var osc1_freq = 110.0
		var osc2_freq = 220.0
		var detune = 0.3
		
		# Sawtooth waves for classic Moog sound
		var osc1 = 2.0 * (osc1_freq * t - floor(osc1_freq * t)) - 1.0
		var osc2 = 2.0 * ((osc2_freq + detune) * t - floor((osc2_freq + detune) * t)) - 1.0
		
		# Mix oscillators
		var mixed = osc1 * 0.6 + osc2 * 0.4
		
		# Ladder filter simulation (simple low-pass)
		var filter_cutoff = 2000.0
		var resonance = 0.7
		var filter_env = exp(-progress * 2.0)
		var filtered = mixed * (filter_cutoff / 8000.0) * (1.0 + resonance * filter_env)
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.01:  # Attack
			envelope = progress / 0.01
		elif progress < 0.3:  # Decay
			envelope = 1.0 - (progress - 0.01) * 0.3 / 0.29
		elif progress < 0.8:  # Sustain
			envelope = 0.7
		else:  # Release
			envelope = 0.7 * (1.0 - (progress - 0.8) / 0.2)
		
		data[i] = filtered * envelope * 0.4

static func _generate_tb303_acid_bass(data: PackedFloat32Array, sample_count: int):
	# Roland TB-303 acid bass with characteristic filter sweep
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency
		var base_freq = 82.4  # Low E
		
		# Sawtooth wave for classic 303 sound
		var wave = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0
		
		# Characteristic filter sweep
		var filter_cutoff = 800.0 + sin(2.0 * PI * 0.5 * t) * 400.0
		var resonance = 0.85
		
		# Filter simulation
		var filter_factor = filter_cutoff / 4000.0
		var filtered = wave * filter_factor * (1.0 + resonance)
		
		# Add slight distortion for grit
		filtered = tanh(filtered * 1.3)
		
		# Envelope with accent
		var envelope = exp(-progress * 5.0)
		var accent = 1.0 + 0.6 * exp(-progress * 20.0)
		
		data[i] = filtered * envelope * accent * 0.3

static func _generate_dx7_electric_piano(data: PackedFloat32Array, sample_count: int):
	# Yamaha DX7 FM electric piano - the sound of the 80s
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# FM synthesis parameters
		var carrier_freq = 220.0
		var modulator_ratio = 2.0
		var fm_index = 3.0
		
		# Modulator envelope (quick decay for bell-like attack)
		var mod_env = exp(-progress * 8.0)
		
		# Carrier envelope (slower decay for sustain)
		var carrier_env = exp(-progress * 2.0) * 0.7 + 0.3
		
		# FM synthesis
		var modulator_freq = carrier_freq * modulator_ratio
		var modulator = sin(2.0 * PI * modulator_freq * t) * fm_index * mod_env
		var carrier = sin(2.0 * PI * carrier_freq * t + modulator)
		
		data[i] = carrier * carrier_env * 0.4

static func _generate_c64_sid_lead(data: PackedFloat32Array, sample_count: int):
	# Commodore 64 SID chip lead sound with PWM and ring modulation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency
		var base_freq = 440.0
		
		# Pulse width modulation
		var pwm_rate = 6.0
		var pwm_depth = 0.3
		var pulse_width = 0.25 + sin(2.0 * PI * pwm_rate * t) * pwm_depth
		
		# Generate pulse wave
		var phase = fmod(base_freq * t, 1.0)
		var pulse = 1.0 if phase < pulse_width else -1.0
		
		# Ring modulation for metallic character
		var ring_freq = base_freq * 1.5
		var ring_mod = sin(2.0 * PI * ring_freq * t) * 0.2 + 0.8
		
		# Filter simulation (simple resonant low-pass)
		var filter_cutoff = 2000.0
		var resonance = 0.6
		var filtered = pulse * (filter_cutoff / 8000.0) * (1.0 + resonance)
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.01:  # Attack
			envelope = progress / 0.01
		elif progress < 0.2:  # Decay
			envelope = 1.0 - (progress - 0.01) * 0.5 / 0.19
		elif progress < 0.7:  # Sustain
			envelope = 0.5
		else:  # Release
			envelope = 0.5 * (1.0 - (progress - 0.7) / 0.3)
		
		data[i] = filtered * ring_mod * envelope * 0.35

static func _generate_amiga_mod_sample(data: PackedFloat32Array, sample_count: int):
	# Amiga ProTracker style sample with Paula chip characteristics
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency (C4)
		var base_freq = 261.6
		
		# Generate sawtooth wave (common in Amiga samples)
		var wave = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0
		
		# Paula chip filtering (simple low-pass for warmth)
		var paula_filter = 0.7
		var filtered = wave * paula_filter
		
		# Bit crushing simulation (8-bit characteristic)
		var bit_depth = 8
		var quantization = pow(2, bit_depth - 1)
		var crushed = floor(filtered * quantization) / quantization
		
		# Simple loop with crossfade
		var loop_point = 0.5
		if progress > loop_point:
			var fade = (1.0 - progress) / (1.0 - loop_point)
			crushed *= fade
		
		data[i] = crushed * 0.8

static func _generate_ppg_wave_pad(data: PackedFloat32Array, sample_count: int):
	# PPG Wave 2.2 wavetable pad
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Wavetable position (morphing between waveforms)
		var wavetable_pos = 0.3  # Default position
		
		# Generate morphing wavetable
		var base_freq = 220.0
		var wave1 = sin(2.0 * PI * base_freq * t)  # Sine
		var wave2 = 2.0 * (base_freq * t - floor(base_freq * t)) - 1.0  # Sawtooth
		var wave = wave1 * (1.0 - wavetable_pos) + wave2 * wavetable_pos
		
		# LFO modulation
		var lfo = sin(2.0 * PI * 0.5 * t) * 0.2
		wave *= (1.0 + lfo)
		
		# ADSR envelope for pad
		var envelope = 1.0
		if progress < 0.2:  # Attack
			envelope = progress / 0.2
		elif progress > 0.8:  # Release
			envelope = (1.0 - progress) / 0.2
		
		data[i] = wave * envelope * 0.4

static func _generate_tr909_kick(data: PackedFloat32Array, sample_count: int):
	# Roland TR-909 kick drum
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch envelope (starts high, drops quickly)
		var pitch_start = 120.0
		var pitch_end = 60.0
		var pitch_envelope = exp(-progress * 20.0)
		var freq = pitch_end + (pitch_start - pitch_end) * pitch_envelope
		
		# Generate kick wave (sine with click)
		var kick = sin(2.0 * PI * freq * t)
		
		# Add click attack
		var click = sin(2.0 * PI * 2000.0 * t) * exp(-progress * 50.0) * 0.3
		
		# Amplitude envelope
		var envelope = exp(-progress * 8.0)
		
		data[i] = (kick + click) * envelope * 0.8

static func _generate_jupiter_8_strings(data: PackedFloat32Array, sample_count: int):
	# Roland Jupiter-8 string ensemble
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple oscillators for richness
		var fundamental = 220.0
		var wave = 0.0
		wave += sin(2.0 * PI * fundamental * t) * 0.3
		wave += sin(2.0 * PI * fundamental * 1.5 * t) * 0.2  # Fifth
		wave += sin(2.0 * PI * fundamental * 2.0 * t) * 0.15  # Octave
		wave += sin(2.0 * PI * fundamental * 3.0 * t) * 0.1   # Higher harmonics
		
		# Chorus effect simulation
		var chorus_rate = 1.2
		var chorus = sin(2.0 * PI * chorus_rate * t) * 0.3 + 1.0
		wave *= chorus
		
		# String envelope (slow attack)
		var envelope = 1.0
		if progress < 0.3:  # Attack
			envelope = progress / 0.3
		elif progress > 0.7:  # Release
			envelope = (1.0 - progress) / 0.3
		
		data[i] = wave * envelope * 0.3

static func _generate_korg_m1_piano(data: PackedFloat32Array, sample_count: int):
	# Korg M1 digital piano
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Digital piano harmonics
		var freq = 261.6  # C4
		var wave = 0.0
		wave += sin(2.0 * PI * freq * t) * 0.5
		wave += sin(2.0 * PI * freq * 2.0 * t) * 0.2
		wave += sin(2.0 * PI * freq * 3.0 * t) * 0.1
		wave += sin(2.0 * PI * freq * 4.0 * t) * 0.05
		
		# Piano envelope (quick attack, slow decay)
		var envelope = 1.0
		if progress < 0.01:  # Quick attack
			envelope = progress / 0.01
		else:  # Exponential decay
			envelope = exp(-(progress - 0.01) * 3.0)
			
		data[i] = wave * envelope * 0.35

static func _generate_juno_chorus_pad(data: PackedFloat32Array, sample_count: int, chord_freqs: Array = [220.0]):
	# Roland Juno-106 Lush Pad (Polyphonic)
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# PWM LFO
		var pwm_lfo = sin(2.0 * PI * 0.5 * t) * 0.4 + 0.5
		
		var mixed = 0.0
		
		for freq in chord_freqs:
			# Layer 1: Center Pulse-Saw
			var wave1 = _get_pulse_saw(freq, t, pwm_lfo)
			
			# Layer 2: Left Detune (Chorus I)
			var detune1 = sin(2.0 * PI * 0.5 * t) * 0.003
			var wave2 = _get_pulse_saw(freq * (1.0 + detune1), t, pwm_lfo)
			
			# Layer 3: Right Detune (Chorus II)
			var detune2 = cos(2.0 * PI * 0.8 * t) * 0.005
			var wave3 = _get_pulse_saw(freq * (1.0 - detune2), t, pwm_lfo) 
			
			mixed += (wave1 * 0.5) + (wave2 * 0.3) + (wave3 * 0.3)
		
		# Normalize gain based on voice count
		mixed /= max(1, chord_freqs.size())
		
		# ADSR Pad Envelope
		var envelope = 1.0
		if progress < 0.3: envelope = progress / 0.3
		elif progress > 0.6: envelope = (1.0 - progress) / 0.4
			
		data[i] = mixed * envelope * 0.3

static func _get_pulse_saw(freq: float, t: float, width: float) -> float:
	# Hybrid Sawtooth / Pulse wave
	var phase = fmod(freq * t, 1.0)
	var saw = 2.0 * phase - 1.0
	var pulse = 1.0 if phase < width else -1.0
	return saw * 0.5 + pulse * 0.5

static func _generate_dx7_ballad_keys(data: PackedFloat32Array, sample_count: int, chord_freqs: Array = [329.63]):
	# Yamaha DX7 Electric Piano (FM) - Polyphonic
	# Algorithm: Modulator -> Carrier
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var mixed = 0.0
		for freq in chord_freqs:
			# Modulator (Metal/Tine character)
			# Ratio 14.0 for bell like tone
			var mod_ratio = 14.0
			var mod_env = exp(-progress * 10.0) # Quick decay
			var mod_index = 2.0 * mod_env
			var modulator = sin(2.0 * PI * freq * mod_ratio * t) * mod_index
			
			# Carrier 1 (Body)
			# Ratio 1.0
			var car1_env = exp(-progress * 2.0)
			var car1 = sin(2.0 * PI * freq * t + modulator) * car1_env
			
			# Carrier 2 (Thump/Bass)
			var car2_env = exp(-progress * 5.0)
			var car2 = sin(2.0 * PI * freq * t) * car2_env * 0.5
			
			mixed += (car1 + car2) * 0.5
			
		mixed /= max(1, chord_freqs.size())
		data[i] = mixed * 0.5

static func _generate_obxa_brass(data: PackedFloat32Array, sample_count: int, chord_freqs: Array = [130.81]):
	# Oberheim OB-Xa "Jump" Brass - Polyphonic
	# Detuned Sawtooths + Filter Envelope
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var mixed = 0.0
		for freq in chord_freqs:
			var osc1 = _get_saw(freq, t)
			var osc2 = _get_saw(freq * 1.01, t) # Detuned
			var osc3 = _get_saw(freq * 0.995, t) # Detuned flat
			
			mixed += (osc1 + osc2 + osc3) * 0.33
			
		mixed /= max(1, chord_freqs.size())
		
		# Filter Envelope (Bright attack, sustain)
		var filter_env = 0.0
		if progress < 0.1: filter_env = progress / 0.1 + 0.5
		else: filter_env = max(0.5, 1.5 - (progress - 0.1) * 2.0)
		
		# Simulate filter by scaling amplitude of a high-pass layer? 
		# Or just cheat: Bright saw vs Dull saw mix
		# "Jump" sound is VERY bright. Let's just use the raw saw with a volume envelope.
		
		var amp_env = 1.0
		if progress < 0.05: amp_env = progress / 0.05
		elif progress > 0.8: amp_env = (1.0 - progress) / 0.2
		
		data[i] = mixed * amp_env * filter_env * 0.4

static func _get_saw(freq: float, t: float) -> float:
	return 2.0 * (freq * t - floor(freq * t)) - 1.0

static func _generate_prophet_lead(data: PackedFloat32Array, sample_count: int, freq: float = 440.0):
	# Prophet-5 Sync Lead (Monophonic)
	# Oscillator Sync effect
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var master_freq = freq
		# Slave freq sweeps up
		var slave_freq = freq * (1.0 + sin(2.0 * PI * 2.0 * t) * 0.5 + 1.0) 
		
		# Master resets Slave phase
		var _master_phase = fmod(master_freq * t, 1.0)
		var _slave_phase = fmod(slave_freq * t, 1.0)
		
		# Hard Sync simulation: 
		# Real hard sync resets slave phase when master phase resets.
		# analytically: 
		var sync_time = floor(master_freq * t) / master_freq
		var time_since_sync = t - sync_time
		var synced_slave_phase = fmod(slave_freq * time_since_sync, 1.0)
		
		var wave = 2.0 * synced_slave_phase - 1.0
		
		var env = 1.0
		if progress > 0.9: env = (1.0 - progress) / 0.1
		
		data[i] = wave * env * 0.3

static func _generate_funk_bass(data: PackedFloat32Array, sample_count: int, freq: float = 55.0):
	# Minimoog Funk Bass (Monophonic)
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var saw = _get_saw(freq, t)
		var square = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		var mix = saw * 0.7 + square * 0.3
		
		# Filter Env (Snap)
		var f_env = exp(-progress * 15.0)
		
		# Amp Env
		var a_env = exp(-progress * 5.0)
		
		data[i] = mix * a_env * (0.5 + 0.5 * f_env) * 0.6

static func _generate_arp_2600_lead(data: PackedFloat32Array, sample_count: int):
	# ARP 2600 analog lead synthesizer
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Sawtooth wave
		var freq = 440.0
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Filter sweep
		var filter_cutoff = 1500.0 + sin(2.0 * PI * 2.0 * t) * 800.0
		var filter_factor = clamp(filter_cutoff / 4000.0, 0.3, 1.0)
		wave *= filter_factor
		
		# ADSR envelope
		var envelope = 1.0
		if progress < 0.05:  # Attack
			envelope = progress / 0.05
		elif progress < 0.3:  # Decay
			envelope = 1.0 - (progress - 0.05) * 0.3 / 0.25
		elif progress < 0.7:  # Sustain
			envelope = 0.7
		else:  # Release
			envelope = 0.7 * (1.0 - (progress - 0.7) / 0.3)
		
		data[i] = wave * envelope * 0.6

static func _generate_synare_3_disco_tom(data: PackedFloat32Array, sample_count: int):
	# Star Instruments Synare 3 disco tom - the "Ring My Bell" sound
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillators with pitch envelope
		var osc1_freq = 200.0 * (1.0 + 0.7 * exp(-progress * 8.0))  # Pitch envelope drops
		var osc2_freq = 400.0 * (1.0 + 0.7 * exp(-progress * 8.0))
		
		# Generate oscillator waves (pulse waves)
		var osc1 = 1.0 if sin(2.0 * PI * osc1_freq * t) > 0.3 else -1.0
		var osc2 = 1.0 if sin(2.0 * PI * osc2_freq * t) > 0.3 else -1.0
		
		# Mix oscillators
		var osc_mix = osc1 * 0.3 + osc2 * 0.7
		
		# Add noise component
		var noise_t = t * 5000.0  # High frequency noise
		var noise = sin(noise_t) * 0.7 + sin(noise_t * 1.3) * 0.3
		noise = noise * 0.3
		
		# Filter with resonance and sweep
		var filter_cutoff = 1200.0 * exp(-progress * 2.0)  # Downward sweep
		var filter_factor = clamp(filter_cutoff / 2000.0, 0.2, 1.0)
		
		# Apply resonance (simple resonant peak)
		var resonance_boost = 1.0 + 0.6 * exp(-(abs(filter_cutoff - 800.0) / 200.0))
		filter_factor *= resonance_boost
		
		var wave = (osc_mix + noise) * filter_factor
		
		# ADSR envelope (tom-like: instant attack, long decay)
		var envelope = 1.0
		if progress < 0.001:  # Instant attack
			envelope = progress / 0.001
		else:  # Exponential decay
			envelope = exp(-progress * 2.5)
		
		# Analog drift simulation
		var drift = sin(2.0 * PI * 0.02 * t) * 0.02
		envelope *= (1.0 + drift)
		
		data[i] = wave * envelope * 0.5

static func _generate_synare_3_cosmic_fx(data: PackedFloat32Array, sample_count: int):
	# Star Instruments Synare 3 cosmic FX - UFO and space sounds
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Frequency sweep (exponential curve from low to high)
		var start_freq = 100.0
		var end_freq = 2000.0
		var freq = start_freq * pow(end_freq / start_freq, progress)
		
		# Dual oscillators with slight detuning
		var osc1 = sin(2.0 * PI * freq * t)
		var osc2 = sin(2.0 * PI * freq * 1.02 * t)  # Slight detune
		
		# LFO modulation for wobble effect
		var lfo = sin(2.0 * PI * 2.0 * t) * 0.3
		var modulated_freq = freq * (1.0 + lfo)
		
		# Mix oscillators with noise
		var wave = osc1 * 0.8 + osc2 * 0.6
		
		# Add cosmic noise
		var noise_t = t * 1000.0
		var noise = sin(noise_t) * 0.4 + sin(noise_t * 1.3) * 0.3
		wave += noise * 0.4
		
		# Filter with high resonance for cosmic effect
		var filter_cutoff = modulated_freq * 1.5
		var filter_factor = clamp(filter_cutoff / 3000.0, 0.3, 1.0)
		wave *= filter_factor * 1.85  # High resonance
		
		# Envelope (slow attack, long release)
		var envelope = 1.0
		if progress < 0.25:  # Attack
			envelope = progress / 0.25
		else:  # Release
			envelope = exp(-(progress - 0.25) * 1.5)
		
		data[i] = wave * envelope * 0.4

static func _generate_moog_kraftwerk_sequencer(data: PackedFloat32Array, sample_count: int):
	# Moog-style Kraftwerk sequencer - classic analog step sequencer
	var bpm = 120.0
	var steps = 16
	var step_duration = (60.0 / bpm) / 4.0  # 16th notes
	
	# Classic Kraftwerk sequence pattern (simplified)
	var sequence = [
		261.63, 261.63, 392.00, 261.63,  # C C G C
		329.63, 261.63, 392.00, 261.63,  # E C G C
		293.66, 293.66, 392.00, 293.66,  # D D G D
		261.63, 329.63, 392.00, 261.63   # C E G C
	]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Calculate current step
		var step_index = int(t / step_duration) % steps
		var step_progress = fmod(t / step_duration, 1.0)
		
		var freq = sequence[step_index]
		
		# Moog-style sawtooth wave
		var wave = 2.0 * (freq * t - floor(freq * t)) - 1.0
		
		# Classic Moog filter (simplified)
		var filter_cutoff = 800.0 + sin(2.0 * PI * 0.5 * t) * 300.0
		var filter_factor = clamp(filter_cutoff / 2000.0, 0.3, 1.0)
		wave *= filter_factor * 1.7  # Resonance
		
		# Step envelope
		var envelope = 1.0
		if step_progress > 0.8:  # Gate off for last 20% of step
			envelope = 0.0
		
		# ADSR envelope per step
		if step_progress < 0.01:
			envelope *= step_progress / 0.01  # Quick attack
		elif step_progress > 0.6:
			envelope *= exp(-(step_progress - 0.6) * 10.0)  # Decay
		
		data[i] = wave * envelope * 0.6

static func _generate_herbie_hancock_moog_fusion(data: PackedFloat32Array, sample_count: int):
	# Herbie Hancock jazz-fusion Moog - layered, chorded, funky
	var chord_freqs = [
		261.63, 329.63, 392.00, 493.88,  # Cmaj7
		293.66, 369.99, 440.00, 554.37,  # Dm7
		329.63, 415.30, 493.88, 622.25,  # Em7
		349.23, 440.00, 523.25, 659.26   # Fmaj7
	]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Jazz rhythm pattern
		var beat = fmod(t * 2.0, 4.0)  # 2 beats per second, 4-beat pattern
		var chord_index = int(beat) % 4
		
		# Get chord frequencies
		var root = chord_freqs[chord_index * 4]
		var third = chord_freqs[chord_index * 4 + 1]
		var fifth = chord_freqs[chord_index * 4 + 2]
		var seventh = chord_freqs[chord_index * 4 + 3]
		
		# Multiple oscillators for richness
		var wave1 = sin(2.0 * PI * root * t)  # Root
		var wave2 = sin(2.0 * PI * third * t) * 0.8  # Third
		var wave3 = sin(2.0 * PI * fifth * t) * 0.6  # Fifth
		var wave4 = sin(2.0 * PI * seventh * t) * 0.4  # Seventh
		
		var combined_wave = (wave1 + wave2 + wave3 + wave4) / 4.0
		
		# Moog filter sweep
		var filter_cutoff = 800.0 + sin(2.0 * PI * 0.3 * t) * 400.0
		var filter_factor = clamp(filter_cutoff / 1500.0, 0.4, 1.0)
		combined_wave *= filter_factor
		
		# Funk envelope - quick attack, sustained
		var envelope = 1.0
		var beat_pos = fmod(beat, 1.0)
		if beat_pos < 0.05:
			envelope = beat_pos / 0.05  # Quick attack
		elif beat_pos > 0.9:
			envelope = 1.0 - (beat_pos - 0.9) / 0.1  # Quick release
		
		data[i] = combined_wave * envelope * 0.7

static func _generate_aphex_twin_modular(data: PackedFloat32Array, sample_count: int):
	# Aphex Twin modular synthesis - complex, chaotic, mathematical
	var base_freq = 220.0  # A3
	var osc_count = 6
	var chaos_amount = 0.4
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Complex oscillator network with cross-modulation
		var total_wave = 0.0
		
		for osc in range(osc_count):
			var osc_freq = base_freq * (1.0 + float(osc) * 0.618)  # Golden ratio intervals
			
			# Chaotic modulation between oscillators
			var chaos_mod = sin(2.0 * PI * osc_freq * 0.1 * t) * chaos_amount
			var modulated_freq = osc_freq * (1.0 + chaos_mod)
			
			# Phase distortion
			var phase = 2.0 * PI * modulated_freq * t
			var distorted_phase = phase + sin(phase * 3.0) * 0.3
			
			var wave = sin(distorted_phase)
			
			# Ring modulation between adjacent oscillators
			if osc > 0:
				var ring_freq = base_freq * (1.0 + float(osc - 1) * 0.618)
				wave *= sin(2.0 * PI * ring_freq * t) * 0.5 + 0.5
			
			total_wave += wave / osc_count
		
		# Complex filter with resonance
		var filter_cutoff = 1000.0 + sin(2.0 * PI * 0.7 * t) * 800.0
		var filter_factor = clamp(filter_cutoff / 3000.0, 0.2, 1.0)
		var resonance = 0.8
		
		# Add resonant feedback
		var resonant_peak = sin(2.0 * PI * filter_cutoff * t) * resonance * 0.2
		total_wave = (total_wave + resonant_peak) * filter_factor
		
		# Granular processing
		var grain_size = 0.01  # 10ms grains
		var grain_index = int(t / grain_size)
		var grain_phase = fmod(t / grain_size, 1.0)
		
		# Randomize grain parameters
		var grain_pitch = 1.0 + (sin(grain_index * 1.618) * 0.2)
		if grain_phase < 0.1 or grain_phase > 0.9:
			total_wave *= grain_pitch * (sin(grain_phase * PI) * sin(grain_phase * PI))
		
		# Bit reduction for digital artifacts
		var bits = 12.0  # Reduce to 12-bit
		total_wave = floor(total_wave * pow(2, bits)) / pow(2, bits)
		
		# Complex envelope
		var envelope = 1.0
		var global_progress = t / (float(sample_count) / SAMPLE_RATE)
		
		if global_progress < 0.1:
			envelope = global_progress / 0.1
		elif global_progress > 0.8:
			envelope = 1.0 - (global_progress - 0.8) / 0.2
		
		# Add glitches randomly
		if randf() < 0.001:  # 0.1% chance per sample
			total_wave *= randf() * 2.0
		
		data[i] = total_wave * envelope * 0.6

static func _generate_warm_juno_pad(data: PackedFloat32Array, sample_count: int, freqs: Array):
	# SLICK VERSION: Warm, dreamy pad - Aphex Twin SAW85-92 style
	# Uses soft sine waves with gentle detuning, not harsh sawtooths
	if sample_count <= 0 or freqs.is_empty():
		return
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var sample = 0.0
		
		# Very slow, gentle chorus movement
		var chorus_lfo = sin(2.0 * PI * 0.15 * t) * 0.003
		var drift_lfo = sin(2.0 * PI * 0.07 * t) * 0.002
		
		for freq in freqs:
			# Soft sine waves with gentle detuning (NOT harsh saws)
			var f1 = freq * (1.0 + chorus_lfo)
			var f2 = freq * (1.002 + drift_lfo)
			var f3 = freq * (0.998 - chorus_lfo)
			
			# Primary: pure sine (warm, round)
			var sine1 = sin(2.0 * PI * f1 * t)
			var sine2 = sin(2.0 * PI * f2 * t)
			var sine3 = sin(2.0 * PI * f3 * t)
			
			# Add subtle 2nd harmonic for warmth
			var harm2 = sin(2.0 * PI * f1 * 2.0 * t) * 0.15
			
			sample += (sine1 + sine2 + sine3) / 3.0 + harm2
			
		sample /= max(1, freqs.size())
		
		# Very slow, gentle amplitude envelope (long attack/release for dreaminess)
		var envelope = 1.0
		if progress < 0.3: 
			envelope = progress / 0.3  # Slow 30% attack
		elif progress > 0.7: 
			envelope = (1.0 - progress) / 0.3  # Slow 30% release
		# Smooth the envelope
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)
		
		# Very subtle filter movement (almost static for smoothness)
		var cutoff_mod = sin(2.0 * PI * 0.05 * t) * 0.1 + 0.9
		
		data[i] = sample * envelope * cutoff_mod * 0.35

static func _generate_tape_drift_keys(data: PackedFloat32Array, sample_count: int, freqs: Array):
	# SLICK VERSION: Dreamy, floating keys with gentle tape character
	# Long sustain, not plucky - more like Rhodes through tape
	if sample_count <= 0 or freqs.is_empty():
		return
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Gentle tape wow (slower, subtler)
		var wow = sin(2.0 * PI * 0.2 * t) * 0.002
		var flutter = sin(2.0 * PI * 3.0 * t) * 0.0005  # Very subtle flutter
		var pitch_mod = 1.0 + wow + flutter
		
		var sample = 0.0
		for freq in freqs:
			var f = freq * pitch_mod
			
			# Soft triangle with rounded corners (almost sine-like)
			var phase = fmod(f * t, 1.0)
			var tri = abs(phase - 0.5) * 4.0 - 1.0
			# Soften the triangle into something rounder
			tri = sin(tri * PI * 0.5)  # Soft clip
			
			# Add subtle warmth
			var sine_layer = sin(2.0 * PI * f * t) * 0.3
			sample += tri * 0.7 + sine_layer
			
		sample /= max(1, freqs.size())
		
		# Long, gentle envelope (NOT plucky - sustained and dreamy)
		var envelope = 1.0
		if progress < 0.15:
			envelope = progress / 0.15  # Gentle attack
		elif progress > 0.75:
			envelope = (1.0 - progress) / 0.25  # Long release
		# Smoothstep
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)
		
		# Subtle tape saturation (warmth, not distortion)
		sample = tanh(sample * 0.8) * 1.1
		
		data[i] = sample * envelope * 0.4

static func _generate_acid_bass_sub(data: PackedFloat32Array, sample_count: int, freq: float):
	# SLICK VERSION: Warm, round sub bass - NOT aggressive Doom bass
	# Pure sine sub with gentle harmonics, no harsh distortion
	if sample_count <= 0 or freq <= 0.0:
		return
	var sub_freq = freq * 0.5  # Sub octave for deep warmth

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pure sine sub bass (clean, warm, round)
		var sub = sin(2.0 * PI * sub_freq * t)
		
		# Add gentle 2nd harmonic for presence (not harsh)
		var harm2 = sin(2.0 * PI * sub_freq * 2.0 * t) * 0.2
		
		# Very subtle 3rd for definition
		var harm3 = sin(2.0 * PI * sub_freq * 3.0 * t) * 0.08
		
		var bass = sub + harm2 + harm3
		
		# Gentle filter movement (slow, dreamy - not acid pluck)
		var filter_mod = sin(2.0 * PI * 0.1 * t) * 0.15 + 0.85
		bass *= filter_mod
		
		# Soft saturation for warmth (NOT distortion)
		bass = tanh(bass * 0.7) * 1.2
		
		# Smooth amplitude envelope
		var envelope = 1.0
		if progress < 0.1:
			envelope = progress / 0.1
		elif progress > 0.85:
			envelope = (1.0 - progress) / 0.15
		# Smoothstep
		envelope = envelope * envelope * (3.0 - 2.0 * envelope)
		
		data[i] = bass * envelope * 0.5

static func _generate_lofi_breakbeat(data: PackedFloat32Array, sample_count: int):
	# SLICK VERSION: Warm, pillowy lo-fi breakbeat
	# Softer transients, more "sampled from vinyl" feel
	if sample_count <= 0:
		return
	var beat_len = float(sample_count)
	var steps = 16
	var step_len = beat_len / steps

	if step_len < 1.0:
		step_len = 1.0

	# Simpler, more hypnotic pattern (less busy than Amen)
	var kicks = [0, 8]  # Just 1 and 3 (four on floor but half time feel)
	var snares = [4, 12]  # Clean 2 and 4
	var hats = [0, 4, 8, 12]  # Sparse hats

	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var current_step = int(float(i) / step_len)
		var step_progress = fmod(float(i), step_len) / step_len
		
		var sample = 0.0
		
		# KICK: Warm, round, not punchy (more 808 sub than acoustic)
		if current_step in kicks and step_progress < 0.4:
			var kt = step_progress * 0.6
			var kfreq = 55.0 + exp(-kt * 8.0) * 40.0  # Lower, slower sweep
			var kick = sin(2.0 * PI * kfreq * kt)
			var kick_env = exp(-kt * 6.0)  # Slower decay
			# Soft clip for warmth
			kick = tanh(kick * 0.8)
			sample += kick * kick_env * 0.6
			
		# SNARE: Muffled, lo-fi, less aggressive
		if current_step in snares and step_progress < 0.25:
			var st = step_progress * 0.4
			# Lower tone, softer
			var tone = sin(2.0 * PI * 180.0 * st) * exp(-st * 10.0)
			# Softer noise (filtered feeling)
			var noise = sin(t * 4000.0 + randf() * 0.5) * exp(-st * 12.0)
			var snare = (tone * 0.5 + noise * 0.4)
			# Lo-fi saturation
			snare = tanh(snare * 0.7)
			sample += snare * 0.5
			
		# HIHAT: Very soft, almost like tape hiss with rhythm
		if current_step in hats and step_progress < 0.08:
			var ht = step_progress * 0.15
			# Gentler noise, lower volume
			var noise = sin(t * 8000.0 + randf()) * exp(-ht * 30.0)
			sample += noise * 0.15
		
		# Add subtle continuous tape hiss/warmth
		var hiss = (randf() - 0.5) * 0.02
		sample += hiss
		
		# Soft limit the whole thing
		data[i] = tanh(sample * 0.9) * 0.8

static func _generate_tape_hiss(data: PackedFloat32Array, sample_count: int):
	for i in range(sample_count):
		# Pink noise approximation or just soft white noise
		var white = randf() * 2.0 - 1.0
		# Apply simple lowpass
		# In this static context, previous sample access is tricky without state, 
		# so we interpret noise as random volume fluctuations
		
		data[i] = white * 0.05 # Very quiet floor


static func _generate_flying_lotus_sampler(data: PackedFloat32Array, sample_count: int):
	# Flying Lotus sampler - hip-hop beats with jazz fusion and experimental elements
	var bpm = 85.0
	var beat_duration = 60.0 / bpm / 4.0  # 16th note duration
	
	# Jazz chord progression
	var chord_freqs = [
		261.63, 329.63, 392.00, 493.88,  # Cmaj7
		220.00, 277.18, 329.63, 415.30,  # Am7
		174.61, 220.00, 261.63, 329.63,  # Fmaj7
		196.00, 246.94, 293.66, 369.99   # G7
	]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# J Dilla-style swing
		var _beat_time = fmod(t / beat_duration, 1.0)
		var swing_offset = 0.0
		if int(t / beat_duration) % 2 == 1:  # Swing on off-beats
			swing_offset = 0.1
		
		# Current chord (changes every 2 seconds)
		var chord_index = int(t / 2.0) % 4
		var chord_root = chord_freqs[chord_index * 4]
		var chord_third = chord_freqs[chord_index * 4 + 1]
		var chord_fifth = chord_freqs[chord_index * 4 + 2]
		var chord_seventh = chord_freqs[chord_index * 4 + 3]
		
		# Sample chop simulation
		var chop_rate = 16.0  # 16th note chops
		var _chop_index = int((t + swing_offset) * chop_rate) % 32
		var chop_progress = fmod((t + swing_offset) * chop_rate, 1.0)
		
		# Multi-layered samples
		var bass_wave = sin(2.0 * PI * chord_root * 0.5 * t)  # Sub bass
		var chord_wave = (sin(2.0 * PI * chord_third * t) + 
						 sin(2.0 * PI * chord_fifth * t) + 
						 sin(2.0 * PI * chord_seventh * t)) / 3.0
		
		# Granular chopping
		var grain_size = 0.05  # 50ms grains
		var grain_phase = fmod(chop_progress, grain_size / beat_duration)
		var grain_envelope = sin(grain_phase * PI / (grain_size / beat_duration))
		
		var total_wave = bass_wave * 0.6 + chord_wave * 0.4
		total_wave *= grain_envelope
		
		# SP-404 style filter
		var filter_cutoff = 1200.0 + sin(2.0 * PI * 0.3 * t) * 600.0
		var filter_factor = clamp(filter_cutoff / 2400.0, 0.3, 1.0)
		total_wave *= filter_factor
		
		# Vintage saturation
		total_wave = tanh(total_wave * 1.5) * 0.7
		
		# Beat envelope
		var envelope = 1.0
		if chop_progress > 0.8:  # Gate off near end of chop
			envelope = 1.0 - (chop_progress - 0.8) / 0.2
		
		# Random stutters
		if randf() < 0.02 and chop_progress < 0.2:  # 2% chance of stutter
			total_wave *= randf() * 2.0
		
		data[i] = total_wave * envelope * 0.7

static func _create_audio_stream(data: PackedFloat32Array, loop_mode: int = AudioStreamWAV.LOOP_FORWARD) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = loop_mode
	stream.loop_begin = 0
	stream.loop_end = data.size()
	
	# Convert float data to 16-bit integers (use PackedByteArray directly)
	var byte_array = PackedByteArray()
	byte_array.resize(data.size() * 2)  # 2 bytes per 16-bit sample
	
	for i in range(data.size()):
		var sample = int(clamp(data[i], -1.0, 1.0) * 32767.0)  # Clamp and convert to 16-bit
		var byte_index = i * 2
		
		# Little-endian 16-bit encoding
		byte_array[byte_index] = sample & 0xFF          # Low byte
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF  # High byte
	
	stream.data = byte_array
	return stream

static func _create_stereo_audio_stream(data_stereo: PackedFloat32Array, loop_mode: int = AudioStreamWAV.LOOP_FORWARD) -> AudioStreamWAV:
	# Expects interleaved stereo data (L, R, L, R...)
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = true
	stream.loop_mode = loop_mode
	
	var frame_count = _idiv(data_stereo.size(), 2)
	stream.loop_begin = 0
	stream.loop_end = frame_count
	
	# Convert float data to 16-bit integers
	var byte_array = PackedByteArray()
	byte_array.resize(data_stereo.size() * 2)
	
	for i in range(data_stereo.size()):
		var sample = int(clamp(data_stereo[i], -1.0, 1.0) * 32767.0)
		var byte_index = i * 2
		byte_array[byte_index] = sample & 0xFF
		byte_array[byte_index + 1] = (sample >> 8) & 0xFF
	
	stream.data = byte_array
	return stream

# Save sounds to disk for reuse in the same directory
static func generate_and_save_all_sounds():
	print("AudioSynthesizer: Generating all sounds...")
	
	var sounds = {
		"pickup_mario": generate_sound(SoundType.PICKUP_MARIO, 0.5),
		"teleport_drone": generate_sound(SoundType.TELEPORT_DRONE, 3.0),
		"lift_bass_pulse": generate_sound(SoundType.LIFT_BASS_PULSE, 2.0),
		"ghost_drone": generate_sound(SoundType.GHOST_DRONE, 4.0),
		"melodic_drone": generate_sound(SoundType.MELODIC_DRONE, 5.0)
	}
	
	# Save in the same directory as this script (res://commons/audio/)
	var script_path = "res://commons/audio/"
	
	# Ensure the audio directory exists
	var dir = DirAccess.open("res://commons/")
	if not dir:
		print("AudioSynthesizer: ERROR - Cannot access res://commons/ directory")
		return
		
	if not dir.dir_exists("audio"):
		dir.make_dir("audio")
		print("AudioSynthesizer: Created audio directory at res://commons/audio/")
	
	for sound_name in sounds.keys():
		var file_path = script_path + sound_name + ".tres"
		var save_result = ResourceSaver.save(sounds[sound_name], file_path)
		if save_result == OK:
			print("  ÃƒÆ’Ã‚Â¢Ãƒâ€¦Ã¢â‚¬Å“ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â¦ Saved: %s" % file_path)
		else:
			print("  ÃƒÆ’Ã‚Â¢Ãƒâ€šÃ‚ÂÃƒâ€¦Ã¢â‚¬â„¢ Failed to save: %s (Error: %d)" % [file_path, save_result])
	
	print("AudioSynthesizer: All sounds generated and saved as .tres resources to res://commons/audio/!")

# Utility function to get all available sound types for UI/debugging
static func get_all_sound_types() -> Array[SoundType]:
	return [
		SoundType.BASIC_SINE_WAVE,
		SoundType.PICKUP_MARIO,
		SoundType.TELEPORT_DRONE, 
		SoundType.LIFT_BASS_PULSE,
		SoundType.GHOST_DRONE,
		SoundType.MELODIC_DRONE,
		SoundType.LASER_SHOT,
		SoundType.POWER_UP_JINGLE,
		SoundType.EXPLOSION,
		SoundType.RETRO_JUMP,
		SoundType.SHIELD_HIT,
		SoundType.AMBIENT_WIND,
		SoundType.DARK_808_KICK,
		SoundType.ACID_606_HIHAT,
		SoundType.DARK_808_SUB_BASS,
		SoundType.AMBIENT_AMIGA_DRONE,
		SoundType.MOOG_BASS_LEAD,
		SoundType.TB303_ACID_BASS,
		SoundType.DX7_ELECTRIC_PIANO,
		SoundType.C64_SID_LEAD,
		SoundType.AMIGA_MOD_SAMPLE,
		SoundType.PPG_WAVE_PAD,
		SoundType.TR909_KICK,
		SoundType.JUPITER_8_STRINGS,
		SoundType.KORG_M1_PIANO,
		SoundType.ARP_2600_LEAD,
		SoundType.SYNARE_3_DISCO_TOM,
		SoundType.SYNARE_3_COSMIC_FX,
		SoundType.MOOG_KRAFTWERK_SEQUENCER,
		SoundType.HERBIE_HANCOCK_MOOG_FUSION,
		SoundType.APHEX_TWIN_MODULAR,
		SoundType.FLYING_LOTUS_SAMPLER
	]

# Get human-readable name for a sound type
static func get_sound_type_name(type: SoundType) -> String:
	match type:
		SoundType.BASIC_SINE_WAVE:
			return "Basic Sine Wave"
		SoundType.PICKUP_MARIO:
			return "Mario Pickup"
		SoundType.TELEPORT_DRONE:
			return "Teleport Drone"
		SoundType.LIFT_BASS_PULSE:
			return "Bass Pulse"
		SoundType.GHOST_DRONE:
			return "Ghost Drone"
		SoundType.MELODIC_DRONE:
			return "Melodic Drone"
		SoundType.LASER_SHOT:
			return "Laser Shot"
		SoundType.POWER_UP_JINGLE:
			return "Power-Up Jingle"
		SoundType.EXPLOSION:
			return "Explosion"
		SoundType.RETRO_JUMP:
			return "Retro Jump"
		SoundType.SHIELD_HIT:
			return "Shield Hit"
		SoundType.AMBIENT_WIND:
			return "Ambient Wind"
		SoundType.DARK_808_KICK:
			return "Dark 808 Kick"
		SoundType.ACID_606_HIHAT:
			return "Acid 606 Hi-Hat"
		SoundType.DARK_808_SUB_BASS:
			return "Dark 808 Sub Bass"
		SoundType.AMBIENT_AMIGA_DRONE:
			return "Ambient Amiga Drone"
		SoundType.MOOG_BASS_LEAD:
			return "Moog Bass Lead"
		SoundType.TB303_ACID_BASS:
			return "TB-303 Acid Bass"
		SoundType.DX7_ELECTRIC_PIANO:
			return "DX7 Electric Piano"
		SoundType.C64_SID_LEAD:
			return "C64 SID Lead"
		SoundType.AMIGA_MOD_SAMPLE:
			return "Amiga MOD Sample"
		SoundType.PPG_WAVE_PAD:
			return "PPG Wave Pad"
		SoundType.TR909_KICK:
			return "TR-909 Kick"
		SoundType.JUPITER_8_STRINGS:
			return "Jupiter-8 Strings"
		SoundType.KORG_M1_PIANO:
			return "Korg M1 Piano"
		SoundType.ARP_2600_LEAD:
			return "ARP 2600 Lead"
		SoundType.SYNARE_3_DISCO_TOM:
			return "Synare 3 Disco Tom"
		SoundType.SYNARE_3_COSMIC_FX:
			return "Synare 3 Cosmic FX"
		SoundType.MOOG_KRAFTWERK_SEQUENCER:
			return "Moog Kraftwerk Sequencer"
		SoundType.HERBIE_HANCOCK_MOOG_FUSION:
			return "Herbie Hancock Moog Fusion"
		SoundType.APHEX_TWIN_MODULAR:
			return "Aphex Twin Modular"
		SoundType.FLYING_LOTUS_SAMPLER:
			return "Flying Lotus Sampler"
		SoundType.SCI_FI_LAB_HUM_CLEAN:
			return "Sci-Fi Lab Hum (Clean)"
		SoundType.SCI_FI_RESONANT_DRONE:
			return "Sci-Fi Resonant Drone"
		SoundType.SCI_FI_DATA_CHIRPS:
			return "Sci-Fi Data Chirps"
		SoundType.SCI_FI_VENTILATION:
			return "Sci-Fi Ventilation"
		SoundType.SCI_FI_ELECTROMAGNETIC:
			return "Sci-Fi Electromagnetic"
		SoundType.CS80_BRASS_LEAD:
			return "CS-80 Brass Lead"
		SoundType.CINEMATIC_432HZ_PAD:
			return "Cinematic 432Hz Pad"
		_:
			return "Unknown Sound"

static func _generate_sci_fi_lab_hum_clean(data: PackedFloat32Array, sample_count: int):
	# Sterile, multi-layered sine wave hum
	# Inspired by clean lab environments
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Pure sine waves at specific resonant frequencies
		var hum1 = sin(2.0 * PI * 60.0 * t) * 0.5      # Mains hum foundation
		var hum2 = sin(2.0 * PI * 120.0 * t) * 0.15    # First harmonic
		var hum3 = sin(2.0 * PI * 180.0 * t) * 0.05    # Second harmonic
		
		# High frequency "monitor whine" (very subtle)
		var whine = sin(2.0 * PI * 15000.0 * t) * 0.02
		
		# Slow amplitude modulation (breathing)
		var breath = sin(2.0 * PI * 0.1 * t) * 0.1 + 0.9
		
		data[i] = (hum1 + hum2 + hum3 + whine) * breath * 0.4

static func _generate_sci_fi_resonant_drone(data: PackedFloat32Array, sample_count: int):
	# Evolving metallic swells using FM synthesis
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# FM Synthesis
		var carrier_freq = 110.0
		var mod_freq = 220.0 * 1.5  # Non-integer ratio for metallic sound
		
		# Evolving modulation index
		var mod_index = 2.0 + sin(2.0 * PI * 0.2 * t) * 1.5
		
		var modulator = sin(2.0 * PI * mod_freq * t) * mod_index
		var carrier = sin(2.0 * PI * carrier_freq * t + modulator)
		
		# Add a second layer for depth
		var layer2_freq = 55.0
		var layer2 = sin(2.0 * PI * layer2_freq * t) * 0.3
		
		# Slow panning/movement effect (simulated with amplitude mod)
		var movement = sin(2.0 * PI * 0.15 * t) * 0.2 + 0.8
		
		data[i] = (carrier * 0.6 + layer2) * movement * 0.3

static func _generate_sci_fi_data_chirps(data: PackedFloat32Array, sample_count: int):
	# Randomized computer activity / data processing sounds
	# Uses rapid frequency modulation and bursts
	
	var burst_interval = 0.15
	var _current_burst = 0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Determine if we are in a burst
		var burst_time = fmod(t, burst_interval)
		
		var audio_signal = 0.0
		
		if burst_time < 0.05: # Active burst duration
			# High speed arpeggio/data sound
			var freq_base = 2000.0
			var freq_mod = sin(2.0 * PI * 100.0 * t) * 500.0
			
			# Square wave for digital character
			var phase = fmod((freq_base + freq_mod) * t, 1.0)
			audio_signal = 1.0 if phase < 0.5 else -1.0
			
			# Apply envelope to burst
			audio_signal *= exp(-burst_time * 20.0)
		
		# Add some background digital noise
		if randf() < 0.01:
			audio_signal += (randf() * 2.0 - 1.0) * 0.1
			
		data[i] = audio_signal * 0.25

static func _generate_sci_fi_ventilation(data: PackedFloat32Array, sample_count: int):
	# Filtered air texture
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# White noise generation
		var noise = randf() * 2.0 - 1.0
		
		# Low pass filter simulation (simple moving average approximation)
		# In a real DSP we'd use state variables, here we simulate the *result*
		# by summing low frequency sines which is cleaner for generation
		
		var air = 0.0
		# Summing non-harmonic sines to approximate filtered noise texture
		air += sin(2.0 * PI * 100.0 * t + noise) * 0.5
		air += sin(2.0 * PI * 230.0 * t + noise) * 0.3
		air += sin(2.0 * PI * 340.0 * t) * 0.2
		
		# Add "wind" modulation
		var gust = sin(2.0 * PI * 0.05 * t) * 0.2 + 0.8
		
		data[i] = air * gust * 0.15

static func _generate_sci_fi_electromagnetic(data: PackedFloat32Array, sample_count: int):
	# Subtle tech interference / electromagnetic radiation
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# 50Hz/60Hz hum characteristic
		var hum = sin(2.0 * PI * 50.0 * t)
		
		# Add sharp spikes (interference)
		var spike = 0.0
		if randf() < 0.001:
			spike = 1.0
			
		# High frequency buzz
		var buzz = sin(2.0 * PI * 3000.0 * t) * (sin(2.0 * PI * 10.0 * t) * 0.5 + 0.5)
		
		data[i] = (hum * 0.4 + spike * 0.3 + buzz * 0.1) * 0.2

static func _generate_cs80_brass_lead(data: PackedFloat32Array, sample_count: int):
	# Vangelis-style CS-80 brass lead
	# Characteristic: Sawtooth, filter sweep, aftertouch-like swelling
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Dual oscillator sawtooths with slight detuning
		var freq1 = 110.0 # A2
		var freq2 = 110.0 * 1.002 # Slight detune
		
		var saw1 = 2.0 * (freq1 * t - floor(freq1 * t)) - 1.0
		var saw2 = 2.0 * (freq2 * t - floor(freq2 * t)) - 1.0
		
		var raw_wave = (saw1 + saw2) * 0.5
		
		# Filter simulation (Low Pass opening up)
		# Simulating the famous CS-80 poly-aftertouch swell
		var swell = sin(PI * progress) # Swells in middle
		var cutoff_base = 800.0
		var cutoff_mod = 2000.0 * swell
		var cutoff = cutoff_base + cutoff_mod
		
		# Simple low-pass approximation
		var filter_factor = clamp(cutoff / 4000.0, 0.1, 1.0)
		var filtered = raw_wave * filter_factor
		
		# Add some "analog" drift
		var drift = sin(2.0 * PI * 0.5 * t) * 0.05
		
		# Envelope
		var envelope = 1.0
		if progress < 0.1: # Attack
			envelope = progress / 0.1
		elif progress > 0.8: # Release
			envelope = (1.0 - progress) / 0.2
			
		data[i] = filtered * (1.0 + drift) * envelope * 0.5

static func _generate_cinematic_432hz_pad(data: PackedFloat32Array, sample_count: int):
	# Warm pad tuned to 432Hz base (approx -32 cents from 440Hz)
	# 432Hz is approx 0.9818 of 440Hz
	var tuning_factor = 432.0 / 440.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Base frequency (A3 tuned to 432Hz reference)
		var base_freq = 220.0 * tuning_factor
		
		# Multiple detuned sawtooths for thick "analog" sound
		var wave = 0.0
		var detune_amounts = [1.0, 1.005, 0.995, 2.0, 2.01] # Unison + Octave
		
		for detune in detune_amounts:
			var f = base_freq * detune
			# Sawtooth with slow PWM-like movement
			var phase = f * t
			var saw = 2.0 * (phase - floor(phase)) - 1.0
			wave += saw
			
		wave /= detune_amounts.size()
		
		# Low pass filter (warmth)
		var filter_cutoff = 1200.0
		var filter_factor = clamp(filter_cutoff / 4000.0, 0.2, 0.8)
		wave *= filter_factor
		
		# Slow, dreamy envelope
		var envelope = 1.0
		if progress < 0.3: # Long attack
			envelope = progress / 0.3
		elif progress > 0.7: # Long release
			envelope = (1.0 - progress) / 0.3
			
		# Stereo-like widening (simulated in mono by phase shifting LFOs)
		var shimmer = sin(2.0 * PI * 3.0 * t) * 0.1 + 0.9
		
		data[i] = wave * envelope * shimmer * 0.4


# ============================================================================
# SPACE DYSTOPIA ALBUM - NEW SOUND GENERATORS
# ============================================================================

static func _generate_processed_vocal_pad(data: PackedFloat32Array, sample_count: int):
	# Arrival-style alien processed voice texture
	# Uses formant synthesis with slow morphing between vowels
	var formants_a = [800.0, 1200.0, 2500.0]  # "ah"
	var formants_o = [400.0, 800.0, 2500.0]   # "ooh"
	var bandwidths = [80.0, 90.0, 120.0]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Slow morph between vowels
		var morph = (sin(t * 0.3) + 1.0) * 0.5
		
		# Base pitch with slow drift
		var base_freq = 110.0 + sin(t * 0.1) * 10.0
		
		# Glottal pulse (sawtooth-like source)
		var phase = fmod(t * base_freq, 1.0)
		var source = (1.0 - phase) * exp(-phase * 3.0)
		
		# Apply formant filters (simplified resonant bandpass)
		var output = 0.0
		for f_idx in range(3):
			var f_a = formants_a[f_idx]
			var f_o = formants_o[f_idx]
			var freq = lerp(f_a, f_o, morph)
			var bw = bandwidths[f_idx]
			
			# Resonant bandpass approximation
			var resonance = sin(TAU * freq * t) * exp(-bw * 0.001 * t)
			output += source * resonance * (1.0 / (f_idx + 1))
		
		# Envelope
		var env = 1.0
		if progress < 0.2: env = progress / 0.2
		elif progress > 0.8: env = (1.0 - progress) / 0.2
		
		# Add ethereal reverb-like tail
		var reverb = sin(TAU * 55.0 * t) * 0.1 * (1.0 - progress)
		
		data[i] = (output * 0.3 + reverb) * env


static func _generate_industrial_anvil(data: PackedFloat32Array, sample_count: int):
	# Terminator-style metallic industrial hit
	# Multiple inharmonic partials + noise burst
	var rng = RandomNumberGenerator.new()
	rng.seed = 42
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Very fast decay
		var decay = exp(-t * 15.0)
		
		# Metallic partials (inharmonic ratios like bells)
		var metal = 0.0
		var partials = [1.0, 2.4, 3.8, 5.1, 6.9, 8.2]
		var base = 180.0
		
		for p in partials:
			var freq = base * p
			var partial_decay = exp(-t * (5.0 + p * 2.0))
			metal += sin(TAU * freq * t) * partial_decay / p
		
		# Initial noise burst (impact)
		var noise = 0.0
		if t < 0.02:
			noise = rng.randf_range(-1.0, 1.0) * (1.0 - t / 0.02) * 2.0
		
		# Low frequency thump
		var thump = sin(TAU * 60.0 * t) * exp(-t * 30.0)
		
		data[i] = (metal * 0.4 + noise * 0.3 + thump * 0.5) * decay


static func _generate_trip_hop_beat(data: PackedFloat32Array, sample_count: int):
	# Massive Attack style slow breakbeat (~90 BPM)
	var bpm = 90.0
	var beat_duration = 60.0 / bpm
	var rng = RandomNumberGenerator.new()
	rng.seed = 1234
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var beat_pos = fmod(t, beat_duration * 4.0)  # 4 beat loop
		var beat_num = int(beat_pos / beat_duration)
		var beat_t = fmod(beat_pos, beat_duration)
		
		var kick = 0.0
		var snare = 0.0
		var hat = 0.0
		
		# Kick: beats 1 and 3.5 (syncopated)
		if beat_num == 0 or (beat_num == 3 and beat_t > beat_duration * 0.5):
			var k_t = beat_t if beat_num == 0 else beat_t - beat_duration * 0.5
			if k_t < 0.15:
				var pitch = 60.0 * exp(-k_t * 30.0) + 40.0
				kick = sin(TAU * pitch * k_t) * exp(-k_t * 15.0)
		
		# Snare: beat 2 (lazy, slightly late feel)
		if beat_num == 1:
			var s_t = beat_t - 0.01  # Slight delay for swing
			if s_t > 0 and s_t < 0.2:
				var noise = rng.randf_range(-1.0, 1.0)
				var tone = sin(TAU * 200.0 * s_t)
				snare = (noise * 0.6 + tone * 0.4) * exp(-s_t * 12.0)
		
		# Hi-hat: 8th notes, varying velocity
		var eighth_t = fmod(beat_t, beat_duration * 0.5)
		if eighth_t < 0.03:
			var velocity = 0.3 + rng.randf() * 0.3
			hat = rng.randf_range(-1.0, 1.0) * exp(-eighth_t * 100.0) * velocity
		
		data[i] = kick * 0.7 + snare * 0.5 + hat * 0.25


static func _generate_ethnic_tabla(data: PackedFloat32Array, sample_count: int):
	# Tabla-style hand drum synthesis
	# Uses body resonance + membrane modes
	var rng = RandomNumberGenerator.new()
	rng.seed = 777
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Trigger pattern: repeating 7/8 feel
		var pattern_len = 0.4  # ~150 BPM
		var pat_t = fmod(t, pattern_len)
		var hit_times = [0.0, 0.1, 0.15, 0.25, 0.3]
		
		var output = 0.0
		for hit in hit_times:
			var hit_t = pat_t - hit
			if hit_t >= 0 and hit_t < 0.15:
				# Membrane modes (slightly inharmonic)
				var modes = [1.0, 1.59, 2.14, 2.65]
				var base = 200.0 + rng.randf() * 50.0
				
				for m in modes:
					var freq = base * m
					var mode_decay = exp(-hit_t * (20.0 + m * 5.0))
					output += sin(TAU * freq * hit_t) * mode_decay / m
				
				# Body resonance (low)
				output += sin(TAU * 80.0 * hit_t) * exp(-hit_t * 30.0) * 0.5
				
				# Slap noise
				if hit_t < 0.005:
					output += rng.randf_range(-0.5, 0.5)
		
		data[i] = output * 0.4


static func _generate_gamelan_bell(data: PackedFloat32Array, sample_count: int):
	# Indonesian gamelan metallic bell
	# Characteristic: slow beating between detuned partials, long sustain
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		var base = 523.25  # C5
		
		# Gamelan partials are slightly sharp (stretched octaves)
		var partials = [
			[1.0, 1.0],      # Fundamental
			[2.01, 0.7],     # Slightly sharp octave (beating)
			[3.03, 0.5],     # ~Fifth
			[4.08, 0.3],     # Sharp double octave
			[5.19, 0.2],     # Higher partial
		]
		
		var output = 0.0
		for p in partials:
			var freq = base * p[0]
			var amp = p[1]
			# Very slow decay for sustained ringing
			var decay = exp(-t * (1.0 + p[0] * 0.5))
			output += sin(TAU * freq * t) * amp * decay
		
		# Characteristic "shimmer" from beating
		var shimmer = 1.0 + sin(TAU * 1.5 * t) * 0.1
		
		# Attack transient
		var attack = 1.0
		if t < 0.005:
			attack = t / 0.005
		
		data[i] = output * shimmer * attack * 0.3


static func _generate_organ_swell(data: PackedFloat32Array, sample_count: int):
	# Interstellar-style church organ pad
	# Multiple harmonic drawbars + slow swell
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var base = 65.41  # C2 (deep pedal tone)
		
		# Organ drawbar harmonics (16', 8', 4', 2-2/3', 2', 1-3/5')
		var drawbars = [
			[0.5, 0.8],   # 16' (sub)
			[1.0, 1.0],   # 8' (fundamental)
			[2.0, 0.6],   # 4'
			[3.0, 0.4],   # 2-2/3'
			[4.0, 0.5],   # 2'
			[5.0, 0.2],   # 1-3/5'
			[6.0, 0.3],   # 1-1/3'
			[8.0, 0.4],   # 1'
		]
		
		var output = 0.0
		for d in drawbars:
			var freq = base * d[0]
			var amp = d[1]
			# Slight random phase for richness
			var phase_offset = d[0] * 0.1
			output += sin(TAU * freq * t + phase_offset) * amp
		
		# Slow dramatic swell envelope
		var swell = 0.0
		if progress < 0.4:
			swell = pow(progress / 0.4, 2.0)  # Slow exponential rise
		elif progress < 0.6:
			swell = 1.0
		else:
			swell = pow((1.0 - progress) / 0.4, 0.5)  # Slower release
		
		# Add slight tremolo (Leslie effect)
		var tremolo = 1.0 + sin(TAU * 5.5 * t) * 0.05
		
		data[i] = output * swell * tremolo * 0.15


static func _generate_noir_sax(data: PackedFloat32Array, sample_count: int):
	# Jazz noir saxophone with breath modeling
	# Waveshaping + formants + breath noise
	var rng = RandomNumberGenerator.new()
	rng.seed = 999
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Pitch with vibrato (delayed onset)
		var vibrato_depth = 0.015 * clamp((progress - 0.2) * 2.0, 0.0, 1.0)
		var vibrato = sin(TAU * 5.0 * t) * vibrato_depth
		var base_freq = 293.66 * (1.0 + vibrato)  # D4
		
		# Sawtooth-ish oscillator (reed)
		var phase = fmod(t * base_freq, 1.0)
		var reed = phase * 2.0 - 1.0
		
		# Waveshaping for sax timbre
		reed = tanh(reed * 2.0) * 0.8 + sin(TAU * base_freq * 2.0 * t) * 0.2
		
		# Breath noise
		var breath = rng.randf_range(-0.1, 0.1)
		var breath_env = 0.3 if progress < 0.1 else 0.1  # More breath at start
		
		# Formant emphasis (nasal sax character ~1500Hz)
		var formant = sin(TAU * 1500.0 * t) * 0.1
		
		# Expression envelope
		var env = 1.0
		if progress < 0.05:
			env = progress / 0.05
		elif progress > 0.85:
			env = (1.0 - progress) / 0.15
		
		# Slight growl/roughness
		var growl = sin(TAU * 30.0 * t) * 0.1 * sin(TAU * base_freq * 0.5 * t)
		
		data[i] = (reed + breath * breath_env + formant + growl) * env * 0.35


static func _generate_choir_pad(data: PackedFloat32Array, sample_count: int):
	# Ethereal choir vowel morph (ooh-aah)
	# Multi-voice with slight detuning
	var voices = 6
	var base_freq = 220.0  # A3
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Vowel morph: ooh (0) -> aah (1) -> ooh (0)
		var vowel = sin(progress * PI)  # 0->1->0
		
		# Formants for "ooh" and "aah"
		var f1 = lerp(300.0, 800.0, vowel)   # F1
		var f2 = lerp(800.0, 1200.0, vowel)  # F2
		
		var output = 0.0
		for v in range(voices):
			# Slight detune per voice
			var detune = 1.0 + (v - voices/2.0) * 0.003
			var freq = base_freq * detune
			
			# Glottal source
			var phase = fmod(t * freq, 1.0)
			var source = sin(TAU * phase) * 0.7 + sin(TAU * phase * 2) * 0.3
			
			# Apply formants
			var formant_out = source
			formant_out += sin(TAU * f1 * t) * 0.3
			formant_out += sin(TAU * f2 * t) * 0.2
			
			output += formant_out / voices
		
		# Soft envelope
		var env = sin(progress * PI)  # Gentle arc
		
		# Subtle shimmer
		var shimmer = 1.0 + sin(TAU * 0.5 * t) * 0.05
		
		data[i] = output * env * shimmer * 0.25


static func _generate_reversed_swell(data: PackedFloat32Array, sample_count: int):
	# Pre-echo reversed reverb effect
	# Sound builds up then cuts off sharply
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Reversed envelope: starts quiet, builds to peak at end
		var rev_env = pow(progress, 3.0)  # Exponential rise
		
		# Sharp cutoff at the very end
		if progress > 0.95:
			rev_env *= (1.0 - progress) / 0.05
		
		# Pad-like content (multiple detuned sines)
		var output = 0.0
		var freqs = [220.0, 220.5, 329.63, 440.0, 439.5]
		for freq in freqs:
			output += sin(TAU * freq * t) / freqs.size()
		
		# Add shimmering high frequencies that appear later
		if progress > 0.5:
			var high_mix = (progress - 0.5) * 2.0
			output += sin(TAU * 880.0 * t) * high_mix * 0.2
			output += sin(TAU * 1320.0 * t) * high_mix * 0.1
		
		data[i] = output * rev_env * 0.4


static func _generate_blade_runner_brass(data: PackedFloat32Array, sample_count: int):
	# CS-80 style massive brass swell (Vangelis)
	# Thick sawtooth stack + resonant filter sweep
	var voices = 7
	var base_freq = 146.83  # D3
	
	# Simple filter state
	var filter_y = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Filter cutoff sweep (the signature CS-80 sound)
		var cutoff = lerp(200.0, 4000.0, pow(sin(progress * PI), 0.5))
		var filter_coeff = clamp(cutoff / (SAMPLE_RATE * 0.5), 0.01, 0.99)
		
		# Pitch drift (analog instability)
		var drift = sin(t * 0.2) * 0.005
		
		# 7-voice supersaw
		var output = 0.0
		for v in range(voices):
			var detune = 1.0 + (v - voices/2.0) * 0.008 + drift
			var freq = base_freq * detune
			
			# Sawtooth
			var phase = fmod(t * freq, 1.0)
			var saw = 2.0 * phase - 1.0
			output += saw / voices
		
		# Add sub oscillator
		output += sin(TAU * base_freq * 0.5 * t) * 0.3
		
		# Simple lowpass filter
		filter_y += filter_coeff * (output - filter_y)
		var filtered = filter_y
		
		# Soft saturation
		filtered = tanh(filtered * 1.5)
		
		# Grand swell envelope
		var env = 1.0
		if progress < 0.3:
			env = pow(progress / 0.3, 2.0)  # Slow attack
		elif progress > 0.7:
			env = pow((1.0 - progress) / 0.3, 0.7)  # Slower release
		
		data[i] = filtered * env * 0.35

static func _generate_heartbeat(data: PackedFloat32Array, sample_count: int):
	# Realistic heartbeat sound with lub-dub rhythm
	# ~70 BPM = ~0.86 seconds per beat
	var bpm = 70.0
	var beat_duration = 60.0 / bpm
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var beat_phase = fmod(t, beat_duration) / beat_duration
		
		var output = 0.0
		
		# "Lub" (S1) - mitral/tricuspid valve closure, lower pitch
		# Occurs at start of beat
		if beat_phase < 0.15:
			var lub_t = beat_phase / 0.15
			var lub_env = sin(PI * lub_t) * exp(-lub_t * 3.0)
			var lub_freq = 40.0 + (1.0 - lub_t) * 20.0  # Pitch drops
			output += sin(2.0 * PI * lub_freq * t) * lub_env * 0.8
			# Add thump transient
			output += sin(2.0 * PI * 60.0 * t) * exp(-lub_t * 8.0) * 0.4
		
		# "Dub" (S2) - aortic/pulmonary valve closure, higher & shorter
		# Occurs ~0.3 into beat cycle
		elif beat_phase > 0.25 and beat_phase < 0.38:
			var dub_t = (beat_phase - 0.25) / 0.13
			var dub_env = sin(PI * dub_t) * exp(-dub_t * 4.0)
			var dub_freq = 55.0 + (1.0 - dub_t) * 15.0
			output += sin(2.0 * PI * dub_freq * t) * dub_env * 0.6
		
		# Subtle blood flow noise between beats
		var flow_noise = (randf() - 0.5) * 0.02
		output += flow_noise * (1.0 - abs(beat_phase - 0.5) * 2.0) * 0.3
		
		data[i] = output * 0.5

static func _generate_lab_hum(data: PackedFloat32Array, sample_count: int):
	# Laboratory equipment hum - electrical and mechanical ambiance
	# More industrial than the sci-fi clean version
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		# Mains hum foundation (60Hz for US, could be 50Hz for EU)
		var mains = sin(2.0 * PI * 60.0 * t) * 0.4
		
		# Harmonics from rectifiers and transformers
		var harm2 = sin(2.0 * PI * 120.0 * t) * 0.2
		var harm3 = sin(2.0 * PI * 180.0 * t) * 0.1
		var harm4 = sin(2.0 * PI * 240.0 * t) * 0.05
		
		# Fluorescent light buzz (higher frequency flutter)
		var flicker_rate = 100.0 + sin(2.0 * PI * 0.3 * t) * 5.0
		var fluorescent = sin(2.0 * PI * flicker_rate * t) * 0.08
		
		# Ventilation fan drone (low frequency)
		var fan_freq = 30.0 + sin(2.0 * PI * 0.1 * t) * 2.0  # Slight wobble
		var fan = sin(2.0 * PI * fan_freq * t) * 0.15
		
		# Random equipment clicks and digital noise (sparse)
		var equipment_noise = 0.0
		if randf() < 0.0005:  # Rare clicks
			equipment_noise = (randf() - 0.5) * 0.3
		
		# CRT/monitor whine (very high, subtle)
		var whine = sin(2.0 * PI * 15734.0 * t) * 0.015  # ~15.7kHz
		
		# Combine with subtle amplitude variation
		var breath = sin(2.0 * PI * 0.08 * t) * 0.1 + 0.9
		
		var output = (mains + harm2 + harm3 + harm4 + fluorescent + fan + whine + equipment_noise) * breath
		
		data[i] = output * 0.35

# =============================================================================
# EXPERIMENTAL / ALGORITHMIC PIONEERS
# =============================================================================

static func _generate_radiophonic_workshop(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# BBC Radiophonic Workshop style - Delia Derbyshire, Doctor Who era
	# Ring modulation, oscillator sweeps, tape-loop textures
	var carrier_hz = params.get("ring_mod_carrier_hz", 800.0)
	var mod_hz = params.get("ring_mod_modulator_hz", 120.0)
	var swoop_min = params.get("swoop_min_hz", 50.0)
	var swoop_max = params.get("swoop_max_hz", 2000.0)
	var swoop_dur = params.get("swoop_duration", 2.0)
	var warble = params.get("tape_warble", 0.02)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Tape speed warble
		var tape_drift = sin(2.0 * PI * 0.3 * t) * warble
		var playback_rate = 1.0 + tape_drift
		
		# Ring modulation - the classic Radiophonic sound
		var carrier = sin(2.0 * PI * carrier_hz * t * playback_rate)
		var modulator = sin(2.0 * PI * mod_hz * t * playback_rate)
		var ring_mod = carrier * modulator * 0.4
		
		# Oscillator swoop (Doctor Who bass line style)
		var swoop_phase = fmod(t, swoop_dur) / swoop_dur
		var swoop_freq = swoop_min + (swoop_max - swoop_min) * (1.0 - swoop_phase)
		var swoop = sin(2.0 * PI * swoop_freq * t) * 0.25 * (1.0 - swoop_phase)
		
		# Rhythmic pulse from tape loop simulation
		var loop_period = 0.75
		var loop_phase = fmod(t, loop_period) / loop_period
		var pulse = 0.0
		if loop_phase < 0.1:
			pulse = sin(PI * loop_phase / 0.1) * 0.3
		
		# Filtered noise texture
		var noise = (randf() - 0.5) * 0.1
		
		# Combine with envelope
		var env = sin(PI * progress) * 0.8 + 0.2
		data[i] = (ring_mod + swoop + pulse + noise) * env * 0.6


static func _generate_xenakis_stochastic(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Iannis Xenakis - mathematical/stochastic composition
	# Probability distributions, Markov chains, dense pitch clusters
	var mean_midi = params.get("pitch_mean_midi", 60.0)
	var std_dev = params.get("pitch_std_dev", 12.0)
	var cluster_size = int(params.get("cluster_density", 8.0))
	var spread_cents = params.get("cluster_spread_cents", 50.0)
	var event_rate = params.get("event_density", 3.0)
	var _gliss_prob = params.get("glissando_probability", 0.3)
	
	# Generate cluster frequencies using Gaussian distribution
	var cluster_freqs: Array[float] = []
	for j in range(cluster_size):
		# Box-Muller transform for Gaussian
		var u1 = max(randf(), 0.0001)
		var u2 = randf()
		var z = sqrt(-2.0 * log(u1)) * cos(2.0 * PI * u2)
		var midi_note = mean_midi + z * std_dev
		# Add microtonal spread
		var cents_offset = (randf() - 0.5) * spread_cents
		var freq = 440.0 * pow(2.0, (midi_note - 69.0 + cents_offset / 100.0) / 12.0)
		cluster_freqs.append(freq)
	
	# Markov chain for event timing
	var last_event_time = 0.0
	var event_times: Array[float] = []
	var total_duration = float(sample_count) / SAMPLE_RATE
	while last_event_time < total_duration:
		var interval = -log(max(randf(), 0.0001)) / event_rate  # Exponential distribution
		last_event_time += interval
		if last_event_time < total_duration:
			event_times.append(last_event_time)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var output = 0.0
		
		# Cluster tones with slow amplitude modulation
		for j in range(cluster_size):
			var freq = cluster_freqs[j]
			# Slow random walk on frequency (glissando)
			if randf() < 0.0001:
				cluster_freqs[j] *= 1.0 + (randf() - 0.5) * 0.02
			var amp_mod = sin(2.0 * PI * (0.1 + j * 0.05) * t) * 0.3 + 0.7
			output += sin(2.0 * PI * freq * t) * amp_mod / cluster_size
		
		# Event bursts
		for event_t in event_times:
			var dt = t - event_t
			if dt > 0 and dt < 0.3:
				var burst_env = exp(-dt * 10.0)
				var burst_freq = 200.0 + randf() * 2000.0
				output += sin(2.0 * PI * burst_freq * t) * burst_env * 0.2
		
		var env = sin(PI * float(i) / sample_count)
		data[i] = output * env * 0.4


static func _generate_spiegel_intelligent(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Laurie Spiegel - Music Mouse algorithmic harmony
	# Rule-based counterpoint, voice leading, generative harmony
	var root_midi = int(params.get("root_note_midi", 48.0))
	var scale_idx = int(params.get("scale_type", 0.0))
	var num_voices = int(params.get("harmony_voices", 4.0))
	var smoothness = params.get("voice_leading_smoothness", 0.7)
	var chord_rate = params.get("chord_change_rate", 0.5)
	var arp_prob = params.get("arpeggio_probability", 0.3)
	
	# Scale definitions (intervals from root)
	var scales = [
		[0, 2, 4, 5, 7, 9, 11],  # Major
		[0, 2, 3, 5, 7, 8, 10],  # Minor
		[0, 2, 3, 5, 7, 9, 10],  # Dorian
		[0, 2, 4, 7, 9]          # Pentatonic
	]
	var scale = scales[scale_idx % scales.size()]
	
	# Voice state
	var voice_notes: Array[int] = []
	for v in range(num_voices):
		var scale_degree = (v * 2) % scale.size()
		voice_notes.append(root_midi + scale[scale_degree] + (v / 2) * 12)
	
	var last_chord_time = 0.0
	var chord_duration = 1.0 / chord_rate
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var output = 0.0
		
		# Chord change with voice leading
		if t - last_chord_time > chord_duration:
			last_chord_time = t
			chord_duration = 0.5 + randf() * 1.5 / chord_rate
			
			# Move each voice with voice leading rules
			for v in range(num_voices):
				var current = voice_notes[v]
				var target_degree = randi() % scale.size()
				var target = root_midi + scale[target_degree] + _idiv(current - root_midi, 12) * 12
				
				# Prefer stepwise motion based on smoothness
				if randf() < smoothness:
					var step = 1 if randf() > 0.5 else -1
					var new_degree = (scale.find((current - root_midi) % 12) + step) % scale.size()
					if new_degree >= 0:
						target = root_midi + scale[new_degree] + _idiv(current - root_midi, 12) * 12
				
				voice_notes[v] = target
		
		# Generate audio for each voice
		var _phase_in_chord = (t - last_chord_time) / chord_duration
		for v in range(num_voices):
			var freq = 440.0 * pow(2.0, (voice_notes[v] - 69.0) / 12.0)
			
			# Arpeggio or sustained
			var voice_amp = 1.0
			if randf() < arp_prob * 0.01:  # Rare arp moments
				var arp_phase = fmod(t * 4.0, 1.0)
				voice_amp = 1.0 if fmod(arp_phase * num_voices, 1.0) < 0.25 else 0.3
			
			# Warm pad tone (saw + triangle mix)
			var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
			var tri = abs(fmod(t * freq * 2.0, 2.0) - 1.0) * 2.0 - 1.0
			output += (saw * 0.3 + tri * 0.7) * voice_amp / num_voices
		
		# Soft envelope
		var env = sin(PI * float(i) / sample_count)
		data[i] = output * env * 0.35


static func _generate_autechre_flutter(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Autechre - non-repetitive rhythms, glitch, micro-variations
	# "Flutter has been programmed so that no bars contain identical beats"
	var bpm = params.get("tempo_bpm", 135.0)
	var variation_prob = params.get("variation_probability", 0.3)
	var hit_prob = params.get("hit_probability", 0.4)
	var subdivision = int(params.get("subdivision_depth", 4.0))
	var glitch_amt = params.get("glitch_amount", 0.4)
	var filter_mod = params.get("filter_modulation", 0.5)
	
	var beat_duration = 60.0 / bpm
	var step_duration = beat_duration / subdivision
	
	# Pre-generate pattern ensuring no two bars are identical
	var total_steps = int(float(sample_count) / SAMPLE_RATE / step_duration) + 1
	var pattern: Array[bool] = []
	var last_bar: Array[bool] = []
	
	for step in range(total_steps):
		var bar_pos = step % (subdivision * 4)
		if bar_pos == 0 and step > 0:
			# Ensure this bar differs from last
			last_bar = pattern.slice(step - subdivision * 4, step)
		
		var hit = randf() < hit_prob
		# Force variation from last bar
		if last_bar.size() > bar_pos and randf() < variation_prob:
			hit = not last_bar[bar_pos]
		pattern.append(hit)
	
	# Filter state
	var filter_state = 0.0
	var filter_cutoff = 0.5
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var step_idx = int(t / step_duration)
		var step_phase = fmod(t, step_duration) / step_duration
		
		var output = 0.0
		
		# Drum hit
		if step_idx < pattern.size() and pattern[step_idx]:
			var hit_env = exp(-step_phase * 20.0)
			
			# Kick-like body
			var kick_freq = 60.0 + (1.0 - step_phase) * 100.0
			output += sin(2.0 * PI * kick_freq * t) * hit_env * 0.5
			
			# Noise transient
			output += (randf() - 0.5) * hit_env * hit_env * 0.4
		
		# Glitch/stutter effect
		if randf() < glitch_amt * 0.001:
			output = data[max(0, i - randi() % 1000)] if i > 1000 else output
		
		# Filter modulation
		filter_cutoff = 0.3 + sin(2.0 * PI * 0.1 * t) * filter_mod * 0.4
		filter_state = filter_state * (1.0 - filter_cutoff) + output * filter_cutoff
		output = filter_state
		
		# Subtle background texture
		output += (randf() - 0.5) * 0.02
		
		data[i] = output * 0.6


static func _generate_ikeda_dataplex(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Ryoji Ikeda - data sonification, minimal sine/noise
	# Pure tones at perception edges, beat frequencies, binary pulses
	var base_freq = params.get("base_frequency_hz", 440.0)
	var beat_freq = params.get("beat_frequency_hz", 2.0)
	var pulse_rate = params.get("pulse_rate_hz", 10.0)
	var noise_amt = params.get("noise_amount", 0.2)
	var noise_filter = params.get("noise_filter_hz", 8000.0)
	var ultrasonic = params.get("ultrasonic_presence", 0.1)
	
	var noise_state = 0.0
	var filter_coeff = exp(-2.0 * PI * noise_filter / SAMPLE_RATE)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Beat frequency pair (two close frequencies)
		var tone1 = sin(2.0 * PI * base_freq * t)
		var tone2 = sin(2.0 * PI * (base_freq + beat_freq) * t)
		var beat_tones = (tone1 + tone2) * 0.25
		
		# Binary data pulses
		var pulse_phase = fmod(t * pulse_rate, 1.0)
		var pulse = 0.0
		if pulse_phase < 0.1:
			# Simulate binary data with random on/off
			var bit = 1.0 if fmod(floor(t * pulse_rate), 2.0) < 1.0 else 0.0
			pulse = bit * sin(PI * pulse_phase / 0.1) * 0.3
		
		# High-passed white noise
		var raw_noise = (randf() - 0.5) * 2.0
		noise_state = noise_state * filter_coeff + raw_noise * (1.0 - filter_coeff)
		var filtered_noise = (raw_noise - noise_state) * noise_amt
		
		# Near-ultrasonic content
		var ultra = sin(2.0 * PI * 14000.0 * t) * ultrasonic * 0.1
		
		# Combine
		var output = beat_tones + pulse + filtered_noise + ultra
		
		# Stark envelope
		var env = 1.0 if progress > 0.02 and progress < 0.98 else sin(PI * min(progress / 0.02, (1.0 - progress) / 0.02))
		data[i] = output * env * 0.5


static func _generate_eccojam_drift(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# OPN/Chuck Person - slowed loops, heavy reverb, vaporwave nostalgia
	var speed = params.get("playback_speed", 0.5)
	var pitch_shift = params.get("pitch_shift_semitones", -12.0)
	var reverb_decay = params.get("reverb_decay", 8.0)
	var reverb_wet = params.get("reverb_wet", 0.7)
	var warble_rate = params.get("tape_warble_rate", 0.2)
	var warble_depth = params.get("tape_warble_depth", 15.0)
	
	# Generate a simple "source" loop to slow down (synth chord)
	var loop_samples = int(SAMPLE_RATE * 2.0)  # 2 second loop
	var source_loop = PackedFloat32Array()
	source_loop.resize(loop_samples)
	
	# Create a nostalgic synth chord
	var chord_freqs = [261.63, 329.63, 392.0, 523.25]  # C major with octave
	for j in range(loop_samples):
		var src_t = float(j) / SAMPLE_RATE
		var chord_sample = 0.0
		for freq in chord_freqs:
			chord_sample += sin(2.0 * PI * freq * src_t) * 0.2
		# Add subtle movement
		chord_sample *= 0.8 + sin(2.0 * PI * 0.5 * src_t) * 0.2
		source_loop[j] = chord_sample
	
	# Simple delay-based reverb
	var reverb_delay = int(SAMPLE_RATE * 0.05)
	var reverb_buffer = PackedFloat32Array()
	reverb_buffer.resize(reverb_delay)
	var reverb_idx = 0
	var reverb_feedback = 1.0 - 1.0 / reverb_decay
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Tape warble (pitch/speed fluctuation)
		var warble = sin(2.0 * PI * warble_rate * t) * warble_depth / 1200.0  # cents to ratio
		var current_speed = speed * pow(2.0, pitch_shift / 12.0 + warble)
		
		# Read from slowed loop
		var loop_pos = fmod(t * current_speed, float(loop_samples) / SAMPLE_RATE) * SAMPLE_RATE
		var idx = int(loop_pos) % loop_samples
		var dry = source_loop[idx]
		
		# Apply reverb
		var delayed = reverb_buffer[reverb_idx]
		var wet = dry + delayed * reverb_feedback
		reverb_buffer[reverb_idx] = wet
		reverb_idx = (reverb_idx + 1) % reverb_delay
		
		var output = dry * (1.0 - reverb_wet) + wet * reverb_wet
		
		# Lo-fi filter (gentle lowpass)
		output *= 0.8
		
		# Fade envelope
		var env = sin(PI * float(i) / sample_count)
		data[i] = output * env * 0.5


static func _generate_cellular_automata(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Wolfram/Conway - generative cellular automata music
	# Rule 30, Rule 110, etc. mapped to pitch and rhythm
	var rule_num = int(params.get("rule_number", 30.0))
	var grid_width = int(params.get("grid_width", 16.0))
	var evo_rate = params.get("evolution_rate_hz", 4.0)
	var root_midi = int(params.get("root_note_midi", 48.0))
	var scale_idx = int(params.get("scale_type", 1.0))
	var note_dur = params.get("note_duration", 0.15)
	
	# Scale definitions
	var scales = [
		[0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11],  # Chromatic
		[0, 2, 4, 7, 9],                          # Pentatonic
		[0, 2, 4, 5, 7, 9, 11],                   # Major
		[0, 2, 3, 5, 7, 8, 10]                    # Minor
	]
	var scale = scales[scale_idx % scales.size()]
	
	# Initialize cellular automaton (1D)
	var cells: Array[int] = []
	for j in range(grid_width):
		cells.append(0)
	cells[_idiv(grid_width, 2)] = 1  # Seed in middle
	
	var gen_duration = 1.0 / evo_rate
	var current_gen = 0
	var last_gen_time = 0.0
	
	# Active notes [(freq, start_time, duration)]
	var active_notes: Array = []
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Evolve automaton
		if t - last_gen_time > gen_duration:
			last_gen_time = t
			current_gen += 1
			
			# Apply rule
			var new_cells: Array[int] = []
			for j in range(grid_width):
				var left = cells[(j - 1 + grid_width) % grid_width]
				var center = cells[j]
				var right = cells[(j + 1) % grid_width]
				var pattern = (left << 2) | (center << 1) | right  # 0-7
				var new_state = (rule_num >> pattern) & 1
				new_cells.append(new_state)
				
				# Trigger note if cell turns on
				if new_state == 1 and cells[j] == 0:
					var scale_degree = j % scale.size()
					var octave = _idiv(j, scale.size())
					var midi = root_midi + scale[scale_degree] + octave * 12
					var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
					active_notes.append([freq, t, note_dur])
			
			cells = new_cells
		
		# Generate audio from active notes
		var output = 0.0
		var notes_to_keep: Array = []
		
		for note in active_notes:
			var freq = note[0]
			var start = note[1]
			var dur = note[2]
			var elapsed = t - start
			
			if elapsed < dur:
				var note_env = sin(PI * elapsed / dur)
				output += sin(2.0 * PI * freq * t) * note_env * 0.15
				notes_to_keep.append(note)
		
		active_notes = notes_to_keep
		
		# Background drone from cell density
		var density = 0.0
		for cell in cells:
			density += cell
		density /= grid_width
		var drone_freq = root_midi - 12  # One octave below
		drone_freq = 440.0 * pow(2.0, (drone_freq - 69.0) / 12.0)
		output += sin(2.0 * PI * drone_freq * t) * density * 0.1
		
		data[i] = output * 0.6

# =============================================================================
# POP & EDM GENRE-DEFINING SOUNDS
# =============================================================================

static func _generate_moroder_disco_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Giorgio Moroder "I Feel Love" - the synth as motor
	# Rigid 16th note sequenced bassline, minimal harmonic change
	var bpm = params.get("bpm", 120.0)
	var root_midi = int(params.get("root_note", 36.0))
	var filter_cutoff = params.get("filter_cutoff", 1200.0)
	var resonance = params.get("resonance", 0.4)
	
	var step_duration = 60.0 / bpm / 4.0  # 16th notes
	# Classic Moroder pattern: root, octave, fifth, octave repeat
	var pattern = [0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12, 0, 12, 7, 12]
	
	var filter_state = 0.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var step = int(t / step_duration) % 16
		var step_phase = fmod(t, step_duration) / step_duration
		
		var midi = root_midi + pattern[step]
		var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
		
		# Sawtooth oscillator
		var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
		
		# Tight envelope per step
		var env = exp(-step_phase * 12.0)
		
		# Resonant lowpass filter with envelope
		var cutoff_mod = filter_cutoff + env * 800.0
		var f = clamp(cutoff_mod / SAMPLE_RATE, 0.001, 0.499)
		filter_state += f * (saw * env - filter_state)
		var output = filter_state + (saw * env - filter_state) * resonance
		
		data[i] = output * 0.5


static func _generate_prophet_pad(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Prophet-5 warm polysynth pad - Michael Jackson/Thriller era
	# Warm pads as invisible backbone of pop
	var root_midi = int(params.get("root_note", 60.0))
	var detune = params.get("detune", 0.004)
	var filter_cutoff = params.get("filter_cutoff", 2000.0)
	var attack = params.get("attack", 0.3)
	var release = params.get("release", 0.5)
	
	# Major 7th chord voicing
	var chord = [0, 4, 7, 11]  # 1, 3, 5, 7
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var _progress = float(i) / sample_count
		
		var output = 0.0
		for interval in chord:
			var midi = root_midi + interval
			var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			
			# Two detuned sawtooths (classic Prophet sound)
			var saw1 = fmod(t * freq * (1.0 - detune), 1.0) * 2.0 - 1.0
			var saw2 = fmod(t * freq * (1.0 + detune), 1.0) * 2.0 - 1.0
			
			output += (saw1 + saw2) * 0.5
		
		output /= chord.size()
		
		# Warm lowpass filter with slow modulation
		var cutoff_mod = filter_cutoff + sin(t * 0.3) * 400.0
		var f = clamp(cutoff_mod / SAMPLE_RATE, 0.001, 0.499)
		output = output * f + output * (1.0 - f) * 0.3  # Simple lowpass approx
		
		# ADSR-ish envelope
		var env = 1.0
		var attack_samples = attack * SAMPLE_RATE
		var release_samples = release * SAMPLE_RATE
		if i < attack_samples:
			env = float(i) / attack_samples
		elif i > sample_count - release_samples:
			env = float(sample_count - i) / release_samples
		
		data[i] = output * env * 0.35


static func _generate_prince_sync_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Prince - aggressive oscillator sync lead with raw filter sweeps
	# Prophet-5/OB-X style - funk + synth = erotic machine
	var root_midi = int(params.get("root_note", 72.0))
	var sync_ratio = params.get("sync_ratio", 2.5)
	var filter_sweep = params.get("filter_sweep", 0.8)
	var drive = params.get("drive", 1.5)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		var freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
		
		# Oscillator sync: slave resets when master completes cycle
		var master_phase = fmod(t * freq, 1.0)
		var slave_freq = freq * sync_ratio
		var slave_phase = fmod(t * slave_freq, 1.0)
		
		# When master resets, create the characteristic sync timbre
		var sync_osc = sin(2.0 * PI * slave_phase)
		
		# Add some saw for body
		var saw = master_phase * 2.0 - 1.0
		var mix = sync_osc * 0.6 + saw * 0.4
		
		# Aggressive filter sweep
		var sweep_phase = sin(t * 3.0) * 0.5 + 0.5
		var cutoff = 800.0 + sweep_phase * filter_sweep * 4000.0
		var f = clamp(cutoff / SAMPLE_RATE, 0.001, 0.499)
		mix = mix * (0.3 + f * 0.7)  # Simple filter approx
		
		# Drive/saturation
		mix = tanh(mix * drive)
		
		# Envelope
		var env = sin(PI * progress)
		data[i] = mix * env * 0.5


static func _generate_electro_808(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Afrika Bambaataa "Planet Rock" - birth of electro and hip-hop futurism
	# TR-808 as synthetic rhythm, not imitation drums
	var bpm = params.get("bpm", 120.0)
	var cowbell_level = params.get("cowbell_level", 0.3)
	var clap_level = params.get("clap_level", 0.5)
	
	var beat_duration = 60.0 / bpm
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var beat = fmod(t / beat_duration, 4.0)
		var output = 0.0
		
		# Kick on 1 and 3
		var kick_hits = [0.0, 2.0]
		for hit in kick_hits:
			var dt = beat - hit
			if dt >= 0 and dt < 0.3:
				var kick_env = exp(-dt * 15.0)
				var kick_freq = 55.0 + kick_env * 80.0
				output += sin(2.0 * PI * kick_freq * t) * kick_env * 0.7
		
		# Clap on 2 and 4
		var clap_hits = [1.0, 3.0]
		for hit in clap_hits:
			var dt = beat - hit
			if dt >= 0 and dt < 0.15:
				var clap_env = exp(-dt * 25.0)
				output += (randf() - 0.5) * clap_env * clap_level
		
		# Cowbell on 8th notes (signature electro sound)
		var eighth_beat = fmod(beat * 2.0, 1.0)
		if eighth_beat < 0.05:
			var bell_env = exp(-eighth_beat * 100.0)
			var bell = sin(2.0 * PI * 587.0 * t) * 0.7 + sin(2.0 * PI * 845.0 * t) * 0.3
			output += bell * bell_env * cowbell_level
		
		# Hi-hat 16ths
		var sixteenth = fmod(beat * 4.0, 1.0)
		if sixteenth < 0.03:
			var hat_env = exp(-sixteenth * 200.0)
			output += (randf() - 0.5) * hat_env * 0.15
		
		data[i] = clamp(output, -1.0, 1.0) * 0.6


static func _generate_detroit_techno(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Juan Atkins - cold machine funk, Detroit techno
	# 808 as heartbeat, bass as subwoofer meditation
	var bpm = params.get("bpm", 125.0)
	var bass_note = int(params.get("bass_note", 36.0))
	var coldness = params.get("coldness", 0.7)
	
	var beat_duration = 60.0 / bpm
	var bass_freq = 440.0 * pow(2.0, (bass_note - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var beat = fmod(t / beat_duration, 4.0)
		var output = 0.0
		
		# Four-on-the-floor kick
		var kick_phase = fmod(beat, 1.0)
		if kick_phase < 0.2:
			var kick_env = exp(-kick_phase * 20.0)
			var kick_freq = 50.0 + kick_env * 60.0
			output += sin(2.0 * PI * kick_freq * t) * kick_env * 0.6
		
		# Hypnotic bass (16th note pulse)
		var sixteenth = fmod(beat * 4.0, 1.0)
		var bass_env = exp(-sixteenth * 10.0) * 0.5
		var bass = sin(2.0 * PI * bass_freq * t) * bass_env
		output += bass * 0.4
		
		# Cold hi-hat pattern
		if fmod(beat * 2.0, 1.0) < 0.04:
			var hat_env = exp(-fmod(beat * 2.0, 1.0) * 150.0)
			var hat_noise = (randf() - 0.5) * hat_env * 0.2
			output += hat_noise * coldness
		
		# Sparse clap on 2 and 4
		if (beat > 0.98 and beat < 1.05) or (beat > 2.98 and beat < 3.05):
			output += (randf() - 0.5) * 0.3
		
		data[i] = output * 0.55


static func _generate_house_organ(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Frankie Knuckles - Chicago house organ stab
	# M1 "Organ 2" preset style - house as ritual space
	var root_midi = int(params.get("root_note", 60.0))
	var stab_rate = params.get("stab_rate", 2.0)
	var brightness = params.get("brightness", 0.6)
	
	# House chord: minor 7th
	var chord = [0, 3, 7, 10]
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Stab rhythm
		var stab_phase = fmod(t * stab_rate, 1.0)
		var stab_env = 0.0
		if stab_phase < 0.15:
			stab_env = sin(PI * stab_phase / 0.15)
		
		var output = 0.0
		for interval in chord:
			var midi = root_midi + interval
			var freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			
			# Organ-like additive synthesis (fundamental + harmonics)
			output += sin(2.0 * PI * freq * t) * 0.5
			output += sin(2.0 * PI * freq * 2.0 * t) * 0.3 * brightness
			output += sin(2.0 * PI * freq * 3.0 * t) * 0.15 * brightness
			output += sin(2.0 * PI * freq * 4.0 * t) * 0.05 * brightness
		
		output /= chord.size()
		output *= stab_env
		
		data[i] = output * 0.4


static func _generate_rave_stab(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# The Prodigy - aggressive rave stab
	# Juno-106 style: saw + PWM + portamento, distorted
	var root_midi = int(params.get("root_note", 65.0))
	var aggression = params.get("aggression", 0.7)
	var stab_rate = params.get("stab_rate", 4.0)
	
	var freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		# Stab envelope
		var stab_phase = fmod(t * stab_rate, 1.0)
		var stab_env = 0.0
		if stab_phase < 0.1:
			stab_env = 1.0
		elif stab_phase < 0.2:
			stab_env = 1.0 - (stab_phase - 0.1) * 10.0
		
		# Sawtooth
		var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
		
		# PWM pulse
		var pw = 0.3 + sin(t * 3.0) * 0.2
		var pulse = 1.0 if fmod(t * freq, 1.0) < pw else -1.0
		
		var mix = saw * 0.5 + pulse * 0.5
		
		# Resonant filter sweep
		var filter_env = stab_env
		var cutoff = 500.0 + filter_env * 3000.0
		var f = clamp(cutoff / SAMPLE_RATE, 0.01, 0.49)
		mix = mix * f + mix * (1.0 - f) * 0.2
		
		# Aggressive distortion
		mix = tanh(mix * (1.0 + aggression * 2.0))
		
		data[i] = mix * stab_env * 0.5


static func _generate_supersaw_progressive(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Deadmau5 - progressive house supersaw with sidechain
	# 7+ detuned saws, pumping compression
	var root_midi = int(params.get("root_note", 60.0))
	var num_voices = int(params.get("voices", 7.0))
	var detune_spread = params.get("detune", 0.015)
	var sidechain_amount = params.get("sidechain", 0.7)
	var bpm = params.get("bpm", 128.0)
	
	# Chord: major
	var chord = [0, 4, 7]
	var kick_period = 60.0 / bpm
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		
		var output = 0.0
		for interval in chord:
			var midi = root_midi + interval
			var base_freq = 440.0 * pow(2.0, (midi - 69.0) / 12.0)
			
			# Supersaw: multiple detuned voices
			for v in range(num_voices):
				var detune = 1.0 + (float(v) / num_voices - 0.5) * detune_spread
				var freq = base_freq * detune
				var saw = fmod(t * freq, 1.0) * 2.0 - 1.0
				output += saw
		
		output /= (chord.size() * num_voices)
		
		# Sidechain compression (duck on kick)
		var kick_phase = fmod(t, kick_period) / kick_period
		var sidechain = 1.0 - exp(-kick_phase * 8.0) * sidechain_amount
		output *= sidechain
		
		# Soft limiting
		output = tanh(output * 1.2) * 0.5
		
		# Fade envelope
		var env = sin(PI * float(i) / sample_count)
		data[i] = output * env


static func _generate_wobble_bass(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Skrillex - dubstep wobble bass
	# Aggressive wavetable modulation, LFO on filter = wobble
	var root_midi = int(params.get("root_note", 36.0))
	var wobble_rate = params.get("wobble_rate", 4.0)
	var aggression = params.get("aggression", 0.8)
	
	var freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Wavetable-style morph between saw and square
		var phase = fmod(t * freq, 1.0)
		var wt_pos = sin(t * wobble_rate * 2.0 * PI) * 0.5 + 0.5
		
		var saw = phase * 2.0 - 1.0
		var square = 1.0 if phase < 0.5 else -1.0
		var osc = saw * (1.0 - wt_pos) + square * wt_pos
		
		# Add sub oscillator
		var sub = sin(2.0 * PI * freq * 0.5 * t) * 0.4
		osc += sub
		
		# Wobble filter (LFO on cutoff)
		var wobble_lfo = sin(t * wobble_rate * 2.0 * PI) * 0.5 + 0.5
		var cutoff = 150.0 + wobble_lfo * 3000.0
		var f = clamp(cutoff / SAMPLE_RATE, 0.01, 0.49)
		
		# Simple resonant filter approximation
		osc = osc * f + osc * (1.0 - f) * 0.1
		
		# Heavy distortion
		osc = tanh(osc * (1.5 + aggression))
		
		var env = sin(PI * progress)
		data[i] = osc * env * 0.5


static func _generate_synthwave_lead(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# The Weeknd "Blinding Lights" - synthwave retro-futurism
	# Detuned saw lead with chorus and gated reverb feel
	var root_midi = int(params.get("root_note", 72.0))
	var detune = params.get("detune", 0.008)
	var brightness = params.get("brightness", 0.7)
	
	var freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	# Simple "reverb" delay line
	var delay_samples = int(SAMPLE_RATE * 0.08)
	var delay_buffer = PackedFloat32Array()
	delay_buffer.resize(delay_samples)
	var delay_idx = 0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Two detuned saws (classic 80s lead)
		var saw1 = fmod(t * freq * (1.0 - detune), 1.0) * 2.0 - 1.0
		var saw2 = fmod(t * freq * (1.0 + detune), 1.0) * 2.0 - 1.0
		var osc = (saw1 + saw2) * 0.5
		
		# Bright filter
		var cutoff = 2000.0 + brightness * 3000.0
		var f = clamp(cutoff / SAMPLE_RATE, 0.01, 0.49)
		osc = osc * (0.5 + f * 0.5)
		
		# Gated reverb simulation
		var delayed = delay_buffer[delay_idx]
		var wet = osc + delayed * 0.4
		delay_buffer[delay_idx] = osc
		delay_idx = (delay_idx + 1) % delay_samples
		
		# Gate effect (80s drum gate style applied to synth)
		var gate_lfo = 1.0 if fmod(t * 8.0, 1.0) < 0.7 else 0.3
		wet *= gate_lfo
		
		var env = sin(PI * progress)
		data[i] = wet * env * 0.4


# =============================================================================
# SPACE DYSTOPIA SOUNDSCAPE POP - New Sound Generators
# =============================================================================

static func _generate_space_choir_pad(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Sacred choir vowel pad - ethereal voices morphing between "ooh" and "aah"
	var root_midi = int(params.get("root_note", 60.0))
	var vowel_morph = params.get("vowel_morph", 0.5)  # 0 = ooh, 1 = aah
	var vibrato_depth = params.get("vibrato_depth", 0.02)
	
	var root_freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	# Formant frequencies for vowels (simplified)
	# "ooh": F1=300, F2=870   "aah": F1=730, F2=1090
	var f1_ooh = 300.0; var f2_ooh = 870.0
	var f1_aah = 730.0; var f2_aah = 1090.0
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Slow vowel morph over time
		var morph = vowel_morph + sin(t * 0.2) * 0.3
		morph = clamp(morph, 0.0, 1.0)
		var f1 = f1_ooh + (f1_aah - f1_ooh) * morph
		var f2 = f2_ooh + (f2_aah - f2_ooh) * morph
		
		# Vibrato
		var vib = sin(2.0 * PI * 5.0 * t) * vibrato_depth
		var freq = root_freq * (1.0 + vib)
		
		# Generate harmonics with formant shaping
		var output = 0.0
		for h in range(1, 12):
			var harm_freq = freq * h
			var amp = 1.0 / h
			# Apply formant resonances
			var f1_gain = exp(-pow((harm_freq - f1) / 100.0, 2.0))
			var f2_gain = exp(-pow((harm_freq - f2) / 150.0, 2.0))
			amp *= (f1_gain * 0.6 + f2_gain * 0.4 + 0.1)
			output += sin(2.0 * PI * harm_freq * t) * amp
		
		# Add breathiness
		output += (randf() - 0.5) * 0.03
		
		# Envelope
		var env = 1.0
		if progress < 0.15: env = progress / 0.15
		elif progress > 0.85: env = (1.0 - progress) / 0.15
		
		data[i] = output * env * 0.25


static func _generate_cinematic_strings(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Slow attack string ensemble - Hans Zimmer style
	var root_midi = int(params.get("root_note", 48.0))
	var attack_time = params.get("attack_time", 2.0)
	var chorus_depth = params.get("chorus_depth", 0.005)
	
	var root_freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple detuned oscillators (ensemble effect)
		var output = 0.0
		var detunes = [-0.02, -0.01, 0.0, 0.008, 0.015]
		for detune in detunes:
			var freq = root_freq * (1.0 + detune * chorus_depth / 0.005)
			# Slow vibrato per voice
			freq *= 1.0 + sin(2.0 * PI * (4.0 + detune * 10.0) * t) * 0.003
			# Sawtooth for strings
			var saw = fmod(freq * t, 1.0) * 2.0 - 1.0
			output += saw
		output /= detunes.size()
		
		# Low pass filter (strings aren't too bright)
		output = tanh(output * 0.8)
		
		# Very slow attack
		var env = 1.0
		var attack_progress = t / attack_time
		if attack_progress < 1.0:
			env = attack_progress * attack_progress  # Quadratic ease-in
		if progress > 0.85:
			env *= (1.0 - progress) / 0.15
		
		data[i] = output * env * 0.35


static func _generate_industrial_clank(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Metal factory hit - FM synthesis metallic percussion
	var pitch = params.get("pitch", 150.0)
	var mod_ratio = params.get("mod_ratio", 1.414)  # ÃƒÆ’Ã‚Â¢Ãƒâ€¹Ã¢â‚¬Â Ãƒâ€¦Ã‚Â¡2 for metallic inharmonic
	var mod_index = params.get("mod_index", 8.0)
	var decay = params.get("decay", 6.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# FM synthesis for metallic timbre
		var mod_freq = pitch * mod_ratio
		var modulator = sin(2.0 * PI * mod_freq * t) * mod_index
		var carrier = sin(2.0 * PI * pitch * t + modulator)
		
		# Add higher partials for "clank"
		var clank2 = sin(2.0 * PI * pitch * 2.3 * t + modulator * 0.5) * 0.3
		
		# Sharp attack, medium decay
		var env = exp(-progress * decay)
		var attack = min(1.0, t * 100.0)  # 10ms attack
		
		var output = (carrier + clank2) * env * attack
		
		data[i] = output * 0.5


static func _generate_rain_atmosphere(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Rain and urban ambience - layered noise textures
	var density = params.get("density", 0.5)
	var rumble = params.get("rumble", 0.3)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# High frequency rain drops (filtered noise)
		var rain = 0.0
		rain += sin(t * 8000.0 + randf() * 10.0) * 0.3
		rain += sin(t * 12000.0 + randf() * 10.0) * 0.2
		rain += sin(t * 6000.0 + randf() * 10.0) * 0.15
		rain *= density
		
		# Low rumble (traffic/city)
		var traffic = sin(2.0 * PI * 40.0 * t) * 0.15
		traffic += sin(2.0 * PI * 60.0 * t + sin(t * 0.3) * 2.0) * 0.1
		traffic *= rumble
		
		# Slow modulation (wind gusts)
		var gust = sin(2.0 * PI * 0.1 * t) * 0.3 + 0.7
		
		# Envelope
		var env = 1.0
		if progress < 0.1: env = progress / 0.1
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		
		data[i] = (rain + traffic) * gust * env * 0.3


static func _generate_wavetable_morph(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Slowly evolving wavetable - sine ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ triangle ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ saw ÃƒÆ’Ã‚Â¢ÃƒÂ¢Ã¢â€šÂ¬Ã‚Â ÃƒÂ¢Ã¢â€šÂ¬Ã¢â€žÂ¢ square
	var root_midi = int(params.get("root_note", 55.0))
	var morph_rate = params.get("morph_rate", 0.1)  # Hz
	
	var freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Morph position (0-4, wrapping)
		var morph = fmod(t * morph_rate, 1.0) * 4.0
		
		# Generate all waveforms
		var phase = fmod(freq * t, 1.0)
		var sine_w = sin(2.0 * PI * phase)
		var tri = abs(4.0 * phase - 2.0) - 1.0
		var saw = 2.0 * phase - 1.0
		var square = 1.0 if phase < 0.5 else -1.0
		
		# Crossfade between waveforms
		var output = 0.0
		if morph < 1.0:
			output = sine_w * (1.0 - morph) + tri * morph
		elif morph < 2.0:
			output = tri * (2.0 - morph) + saw * (morph - 1.0)
		elif morph < 3.0:
			output = saw * (3.0 - morph) + square * (morph - 2.0)
		else:
			output = square * (4.0 - morph) + sine_w * (morph - 3.0)
		
		# Envelope
		var env = 1.0
		if progress < 0.1: env = progress / 0.1
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		
		data[i] = output * env * 0.3


static func _generate_pedal_steel_swell(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Country/ambient steel guitar - harmonics with slow swell
	var root_midi = int(params.get("root_note", 52.0))
	var swell_time = params.get("swell_time", 1.5)
	
	var root_freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Multiple strings slightly detuned
		var output = 0.0
		var string_detunes = [-0.008, 0.0, 0.006]
		for detune in string_detunes:
			var freq = root_freq * (1.0 + detune)
			# Slow vibrato (bend)
			freq *= 1.0 + sin(2.0 * PI * 0.5 * t) * 0.01
			
			# Harmonics (plucked string character)
			var string = sin(2.0 * PI * freq * t)
			string += sin(2.0 * PI * freq * 2.0 * t) * 0.5
			string += sin(2.0 * PI * freq * 3.0 * t) * 0.25
			string += sin(2.0 * PI * freq * 4.0 * t) * 0.125
			output += string
		output /= string_detunes.size()
		
		# Volume pedal swell
		var swell = 0.0
		var swell_progress = t / swell_time
		if swell_progress < 1.0:
			swell = swell_progress * swell_progress
		else:
			swell = 1.0
		if progress > 0.8:
			swell *= (1.0 - progress) / 0.2
		
		data[i] = output * swell * 0.3


static func _generate_glitch_chaos(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Digital chaos and artifacts - Autechre/Aphex territory
	var intensity = params.get("intensity", 0.7)
	var root_midi = int(params.get("root_note", 45.0))
	
	var base_freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Chaotic frequency modulation
		var chaos_mod = sin(t * 7.0) * 50.0 + sin(t * 13.0) * 30.0 + sin(t * 23.0) * 20.0
		var freq = base_freq + chaos_mod * intensity
		
		# Waveform with random switching
		var wave = 0.0
		var wave_select = fmod(t * 5.0, 1.0)
		if wave_select < 0.25:
			wave = sin(2.0 * PI * freq * t)
		elif wave_select < 0.5:
			wave = fmod(freq * t, 1.0) * 2.0 - 1.0
		elif wave_select < 0.75:
			wave = 1.0 if sin(2.0 * PI * freq * t) > 0 else -1.0
		else:
			wave = (randf() - 0.5) * 2.0
		
		# Bitcrushing effect
		var crush = 8.0 + (1.0 - intensity) * 8.0
		wave = floor(wave * crush) / crush
		
		# Random dropouts
		if randf() < intensity * 0.02:
			wave = 0.0
		
		# Envelope
		var env = 1.0
		if progress < 0.05: env = progress / 0.05
		elif progress > 0.9: env = (1.0 - progress) / 0.1
		
		data[i] = wave * env * 0.35


static func _generate_noir_sax_breath(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Breathy jazz saxophone - late night club vibes
	var root_midi = int(params.get("root_note", 65.0))
	var breathiness = params.get("breathiness", 0.4)
	var vibrato_rate = params.get("vibrato_rate", 5.0)
	
	var root_freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Delayed vibrato (comes in after note starts)
		var vib_amount = clamp((progress - 0.2) * 2.0, 0.0, 1.0)
		var vibrato = sin(2.0 * PI * vibrato_rate * t) * 0.015 * vib_amount
		var freq = root_freq * (1.0 + vibrato)
		
		# Sax harmonics (odd harmonics emphasized)
		var sax = sin(2.0 * PI * freq * t) * 0.5
		sax += sin(2.0 * PI * freq * 2.0 * t) * 0.25
		sax += sin(2.0 * PI * freq * 3.0 * t) * 0.3   # 3rd harmonic strong
		sax += sin(2.0 * PI * freq * 4.0 * t) * 0.1
		sax += sin(2.0 * PI * freq * 5.0 * t) * 0.15  # 5th harmonic
		
		# Breath noise
		var breath = (randf() - 0.5) * breathiness
		
		# Dynamic envelope (swell in middle)
		var env = sin(PI * progress)  # Natural phrase shape
		if progress < 0.05: env *= progress / 0.05
		
		data[i] = (sax + breath) * env * 0.35


static func _generate_space_sub_drone(data: PackedFloat32Array, sample_count: int, params: Dictionary):
	# Deep sub bass drone - foundation for space atmosphere
	var root_midi = int(params.get("root_note", 36.0))  # C2
	var movement = params.get("movement", 0.3)
	
	var root_freq = 440.0 * pow(2.0, (root_midi - 69.0) / 12.0)
	
	for i in range(sample_count):
		var t = float(i) / SAMPLE_RATE
		var progress = float(i) / sample_count
		
		# Very slow pitch drift
		var drift = sin(2.0 * PI * 0.05 * t) * movement * 1.5
		var freq = root_freq * (1.0 + drift)
		
		# Pure sub with slight second harmonic
		var sub = sin(2.0 * PI * freq * t)
		var harm2 = sin(2.0 * PI * freq * 2.0 * t) * 0.15
		
		# Slow amplitude modulation
		var amp_mod = sin(2.0 * PI * 0.08 * t) * 0.15 + 0.85
		
		# Very slow envelope
		var env = 1.0
		if progress < 0.15: env = progress / 0.15
		elif progress > 0.85: env = (1.0 - progress) / 0.15
		
		data[i] = (sub + harm2) * amp_mod * env * 0.5
