# LayerRenderer.gd
# Shared layer/stem rendering utilities for SongDevTools and StemEditor.
# Uses SoundbankLoader + SoundbankGenerator pattern conventions.

class_name LayerRenderer
extends RefCounted

const SAMPLE_RATE: float = 44100.0
const HIT_DURATION_SECONDS: float = 0.5
const MIN_PREVIEW_SECONDS: float = 2.0
const DEFAULT_VELOCITY: Dictionary = {"base": 0.8, "accent": 1.0, "ghost": 0.4}
const DEFAULT_PATTERN: Array = [1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0]
const SOUNDBANK_ROOT: String = "res://commons/audio/soundbanks/"
const SONG_TO_BANK: Dictionary = {
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
	"midnight_metroplex": "detroit_techno",
	"i_feel_love": "moroder_disco",
	"computer_love": "kraftwerk",
	"dark_wave_cathedral": "dark_wave",
	"aphex_twin_digital_amber": "aphex_twin",
	"pop_madonna": "madonna_80s",
	"kpop_prog_remix": "kpop_prog",
	"blade_runner": "vangelis_cs80",
}


static func render_mix_stream(song_id: String, tracks: Array, bpm: float, num_bars: int) -> AudioStreamWAV:
	var safe_bpm: float = maxf(1.0, bpm)
	var bars: int = maxi(1, num_bars)
	var bar_duration: float = 240.0 / safe_bpm
	var total_duration: float = float(bars) * bar_duration
	var total_samples: int = maxi(1, int(total_duration * SAMPLE_RATE))
	var final_mix = PackedFloat32Array()
	final_mix.resize(total_samples)
	final_mix.fill(0.0)

	var bank_id: String = resolve_bank_id(song_id)
	var bank: SoundbankLoader = load_song_bank(song_id)

	var any_solo: bool = false
	for track_variant in tracks:
		if not (track_variant is Dictionary):
			continue
		var track_check: Dictionary = track_variant
		if bool(track_check.get("solo", false)):
			any_solo = true
			break

	for track_variant in tracks:
		if not (track_variant is Dictionary):
			continue
		var track: Dictionary = track_variant
		var muted: bool = bool(track.get("muted", false))
		var solo: bool = bool(track.get("solo", false))
		if muted:
			continue
		if any_solo and not solo:
			continue

		var track_audio: PackedFloat32Array = render_track_buffer(track, bank, bank_id, total_samples, bar_duration, bars)
		if track_audio.is_empty():
			continue

		for i in range(total_samples):
			final_mix[i] = clampf(final_mix[i] + track_audio[i], -1.0, 1.0)

	return create_audio_stream(final_mix)


static func render_track_buffer(track: Dictionary, bank: SoundbankLoader, song_id: String, total_samples: int, bar_duration: float, num_bars: int) -> PackedFloat32Array:
	var buffer = PackedFloat32Array()
	buffer.resize(total_samples)
	buffer.fill(0.0)

	if bank == null:
		return buffer

	var track_name: String = str(track.get("name", ""))
	if track_name.is_empty():
		return buffer

	var available_sounds: Array = bank.get_available_sounds()
	var sound_name: String = _resolve_sound_name(track_name, available_sounds)
	if sound_name.is_empty():
		return buffer

	var script: Variant = null
	if bank.has_sound(sound_name):
		script = bank.get_sound_script(sound_name)
	if script == null:
		return buffer

	var pattern_variant: Variant = track.get("pattern", DEFAULT_PATTERN)
	var pattern: Array = _coerce_pattern(pattern_variant, _default_pattern_for_layer(track_name))
	if pattern.is_empty():
		return buffer

	var steps_per_bar: int = 16
	var bar_samples: int = maxi(1, int(bar_duration * SAMPLE_RATE))
	var step_samples: int = maxi(1, int((bar_duration / float(steps_per_bar)) * SAMPLE_RATE))
	var velocity_cfg_raw: Variant = SoundbankGenerator.VELOCITY.get(song_id, DEFAULT_VELOCITY)
	var velocity_cfg: Dictionary = velocity_cfg_raw if velocity_cfg_raw is Dictionary else DEFAULT_VELOCITY
	var base_volume: float = float(velocity_cfg.get("base", DEFAULT_VELOCITY["base"]))
	var accent_volume: float = float(velocity_cfg.get("accent", DEFAULT_VELOCITY["accent"]))
	var ghost_volume: float = float(velocity_cfg.get("ghost", DEFAULT_VELOCITY["ghost"]))
	var track_gain_linear: float = 1.0
	if track.has("gain_linear"):
		track_gain_linear = maxf(0.0, float(track.get("gain_linear", 1.0)))
	elif track.has("volume_db"):
		track_gain_linear = maxf(0.0, db_to_linear(float(track.get("volume_db", 0.0))))

	var hit_buffer: PackedFloat32Array = _build_hit_buffer(script)
	if hit_buffer.is_empty():
		return buffer

	# Build one bar once, then copy it across bars (pattern repeats per bar).
	var bar_buffer: PackedFloat32Array = PackedFloat32Array()
	bar_buffer.resize(bar_samples)
	bar_buffer.fill(0.0)

	for step in range(steps_per_bar):
		var pattern_step: int = step % pattern.size()
		var vel_raw: Variant = pattern[pattern_step]
		var vel: float = float(vel_raw)
		if vel <= 0.0:
			continue

		var volume: float = base_volume
		if vel >= 2.0:
			volume = accent_volume
		elif vel < 1.0:
			volume = ghost_volume
		volume *= track_gain_linear

		var step_start: int = step * step_samples
		_mix_hit_into_buffer(bar_buffer, hit_buffer, step_start, volume)

	var safe_num_bars: int = maxi(1, num_bars)
	for bar in range(safe_num_bars):
		var bar_start: int = bar * bar_samples
		if bar_start >= total_samples:
			break
		var copy_count: int = mini(bar_samples, total_samples - bar_start)
		for sample_index in range(copy_count):
			buffer[bar_start + sample_index] += bar_buffer[sample_index]

	return buffer


static func render_song_layer_preview(song_id: String, layer_name: String, params: Dictionary = {}, bpm: float = 120.0, num_bars: int = 1) -> AudioStreamWAV:
	var bars: int = maxi(1, num_bars)
	var safe_bpm: float = maxf(1.0, bpm)
	var bar_duration: float = 240.0 / safe_bpm
	var total_duration: float = maxf(MIN_PREVIEW_SECONDS, float(bars) * bar_duration)
	var total_samples: int = maxi(1, int(total_duration * SAMPLE_RATE))

	var bank_id: String = _resolve_bank_id(song_id)
	if bank_id.is_empty():
		return _render_procedural_preview(layer_name, params, total_samples)

	var bank: SoundbankLoader = SoundbankLoader.load_genre(bank_id)
	if bank == null:
		return _render_procedural_preview(layer_name, params, total_samples)

	var available_sounds: Array = bank.get_available_sounds()
	var preferred_instrument_id: String = str(params.get("instrument_id", ""))
	var sound_name: String = _resolve_sound_name_with_preferred(layer_name, available_sounds, preferred_instrument_id)
	if sound_name.is_empty():
		return _render_procedural_preview(layer_name, params, total_samples)

	var script: Variant = null
	if bank.has_sound(sound_name):
		script = bank.get_sound_script(sound_name)

	var is_step_preview: bool = bool(params.get("step_preview", false))
	if is_step_preview and script != null:
		var overrides: Dictionary = _build_preview_overrides(layer_name, params)
		var step_buffer: PackedFloat32Array = _render_step_preview_buffer(script, total_samples, overrides)
		if not _is_silent(step_buffer):
			return create_audio_stream(step_buffer)

	var pattern: Array = _coerce_pattern(params.get("pattern", _default_pattern_for_layer(layer_name)), _default_pattern_for_layer(layer_name))
	var track = {
		"name": sound_name,
		"pattern": pattern,
		"muted": false,
		"solo": true,
	}

	var track_buffer: PackedFloat32Array = render_track_buffer(track, bank, bank_id, total_samples, bar_duration, bars)
	if _is_silent(track_buffer):
		return _render_procedural_preview(layer_name, params, total_samples)

	return create_audio_stream(track_buffer)


static func create_audio_stream(buffer: PackedFloat32Array) -> AudioStreamWAV:
	var stream = AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = int(SAMPLE_RATE)
	stream.stereo = false

	var data = PackedByteArray()
	data.resize(buffer.size() * 2)

	for i in range(buffer.size()):
		var sample_16: int = int(clampf(buffer[i], -1.0, 1.0) * 32767.0)
		data[i * 2] = sample_16 & 0xFF
		data[i * 2 + 1] = (sample_16 >> 8) & 0xFF

	stream.data = data
	return stream


static func _add_sound_to_buffer(buffer: PackedFloat32Array, script: Variant, start: int, volume: float) -> void:
	var duration_samples: int = int(HIT_DURATION_SECONDS * SAMPLE_RATE)
	for i in range(duration_samples):
		var idx: int = start + i
		if idx < 0 or idx >= buffer.size():
			break

		var t: float = float(i) / SAMPLE_RATE
		var sample: float = _sample_script(script, t)
		buffer[idx] += sample * volume


static func _build_preview_overrides(layer_name: String, params: Dictionary) -> Dictionary:
	var overrides: Dictionary = {}
	var layer_lower: String = layer_name.to_lower()

	var hit_duration: float = 0.28
	if layer_lower.contains("pad") or layer_lower.contains("key") or layer_lower.contains("chord") or layer_lower.contains("vocoder"):
		hit_duration = 0.72
	elif layer_lower.contains("arp") or layer_lower.contains("sequence"):
		hit_duration = 0.22
	overrides["hit_duration"] = hit_duration
	overrides["note_duration"] = hit_duration

	if params.has("preview_freq_hz"):
		overrides["preview_freq_hz"] = maxf(20.0, float(params.get("preview_freq_hz", 220.0)))
	elif params.has("preview_note"):
		var raw_note: int = int(params.get("preview_note", 60))
		var midi_note: int = raw_note if raw_note >= 24 else 60 + raw_note
		overrides["preview_freq_hz"] = _midi_to_frequency(midi_note)

	if params.has("chord_freqs"):
		var chord_variant: Variant = params.get("chord_freqs", [])
		if chord_variant is Array:
			overrides["chord_freqs"] = _coerce_float_array(chord_variant)
	elif params.has("chord_degree"):
		var chord_degree: String = str(params.get("chord_degree", "I"))
		var key_name: String = str(params.get("key", "C"))
		var scale_name: String = str(params.get("scale", "major"))
		var chord_freqs: Array = _chord_degree_to_freqs(chord_degree, key_name, scale_name)
		if not chord_freqs.is_empty():
			overrides["chord_freqs"] = chord_freqs

	return overrides


static func _render_step_preview_buffer(script: Variant, sample_count: int, overrides: Dictionary) -> PackedFloat32Array:
	var buffer = PackedFloat32Array()
	buffer.resize(sample_count)
	buffer.fill(0.0)

	if script == null:
		return buffer

	var hit_buffer: PackedFloat32Array = _build_hit_buffer(script, overrides)
	_mix_hit_into_buffer(buffer, hit_buffer, 0, 1.0)
	return buffer


static func _build_hit_buffer(script: Variant, overrides: Dictionary = {}) -> PackedFloat32Array:
	var hit = PackedFloat32Array()
	var hit_duration: float = HIT_DURATION_SECONDS
	if overrides.has("hit_duration"):
		hit_duration = maxf(0.05, float(overrides.get("hit_duration", HIT_DURATION_SECONDS)))
	var duration_samples: int = int(hit_duration * SAMPLE_RATE)
	hit.resize(duration_samples)
	if script == null:
		hit.fill(0.0)
		return hit

	var generator_desc: Dictionary = _resolve_generator_descriptor(script, overrides)
	if generator_desc.is_empty():
		hit.fill(0.0)
		return hit

	var method_name: String = str(generator_desc.get("name", ""))
	var tail_args_variant: Variant = generator_desc.get("tail_args", [])
	var tail_args: Array = tail_args_variant if tail_args_variant is Array else []
	var call_args: Array = [0.0]
	call_args.append_array(tail_args)

	for i in range(duration_samples):
		call_args[0] = float(i) / SAMPLE_RATE
		hit[i] = float(script.callv(method_name, call_args))
	return hit


static func _mix_hit_into_buffer(buffer: PackedFloat32Array, hit_buffer: PackedFloat32Array, start: int, volume: float) -> void:
	if buffer.is_empty() or hit_buffer.is_empty():
		return
	if start >= buffer.size():
		return

	var offset: int = 0
	if start < 0:
		offset = -start

	var dst_start: int = maxi(0, start)
	var max_count: int = mini(buffer.size() - dst_start, hit_buffer.size() - offset)
	if max_count <= 0:
		return

	for i in range(max_count):
		buffer[dst_start + i] += hit_buffer[offset + i] * volume


static func _resolve_generator_descriptor(script: Variant, overrides: Dictionary = {}) -> Dictionary:
	if script == null:
		return {}

	var candidates: Array[String] = ["generate", "generate_closed", "generate_sample"]
	for method_name_variant in candidates:
		var method_name: String = str(method_name_variant)
		if not script.has_method(method_name):
			continue

		var method_args: Array = _get_method_args(script, method_name)
		var tail_args: Array = []
		if method_args.is_empty():
			# Fallback when metadata is unavailable.
			if method_name == "generate_sample":
				tail_args.append([220.0, 277.18, 329.63])
			else:
				tail_args.append(110.0)
				tail_args.append(0.0)
		else:
			for i in range(1, method_args.size()):
				var arg_info_variant: Variant = method_args[i]
				var arg_info: Dictionary = arg_info_variant if arg_info_variant is Dictionary else {}
				tail_args.append(_default_arg_value(arg_info, overrides))

		return {
			"name": method_name,
			"tail_args": tail_args,
		}

	return {}


static func _sample_script(script: Variant, t: float) -> float:
	if script == null:
		return 0.0

	if script.has_method("generate"):
		var value: Variant = _call_method_with_defaults(script, "generate", t)
		return float(value)
	if script.has_method("generate_closed"):
		var value_closed: Variant = _call_method_with_defaults(script, "generate_closed", t)
		return float(value_closed)
	if script.has_method("generate_sample"):
		var value_sample: Variant = _call_method_with_defaults(script, "generate_sample", t)
		return float(value_sample)

	return 0.0


static func _call_method_with_defaults(target: Object, method_name: String, t: float) -> Variant:
	if target == null:
		return 0.0

	var method_args: Array = _get_method_args(target, method_name)
	if method_args.is_empty():
		# Fallback when method metadata is unavailable.
		if method_name == "generate_sample":
			return target.call(method_name, t, [220.0, 277.18, 329.63])
		return target.call(method_name, t, 110.0, 0.0)

	var call_args: Array = [t]
	for i in range(1, method_args.size()):
		var arg_info_variant: Variant = method_args[i]
		var arg_info: Dictionary = arg_info_variant if arg_info_variant is Dictionary else {}
		call_args.append(_default_arg_value(arg_info))

	return target.callv(method_name, call_args)


static func _get_method_args(target: Object, method_name: String) -> Array:
	if target == null:
		return []

	var methods: Array = []
	if target is Script and target.has_method("get_script_method_list"):
		methods = target.get_script_method_list()
	if methods.is_empty():
		methods = target.get_method_list()

	for method_variant in methods:
		if not (method_variant is Dictionary):
			continue
		var method_info: Dictionary = method_variant
		if str(method_info.get("name", "")) != method_name:
			continue
		var args_variant: Variant = method_info.get("args", method_info.get("arguments", []))
		return args_variant if args_variant is Array else []

	return []


static func _default_arg_value(arg_info: Dictionary, overrides: Dictionary = {}) -> Variant:
	var arg_name: String = str(arg_info.get("name", "")).to_lower()
	var arg_type: int = int(arg_info.get("type", TYPE_NIL))

	# Name-driven defaults first (more reliable than missing type metadata).
	if arg_name.contains("chord") or arg_name.contains("freqs"):
		if overrides.has("chord_freqs"):
			var chord_variant: Variant = overrides.get("chord_freqs", [])
			if chord_variant is Array:
				return (chord_variant as Array).duplicate()
		return [220.0, 277.18, 329.63]
	if arg_name.contains("params") or arg_name.contains("config"):
		return {}
	if arg_name == "open":
		return false
	if arg_name.contains("freq"):
		if overrides.has("preview_freq_hz"):
			return float(overrides.get("preview_freq_hz", 110.0))
		return 110.0
	if arg_name.contains("duration"):
		if overrides.has("note_duration"):
			return float(overrides.get("note_duration", 0.5))
		return 0.5
	if arg_name.contains("velocity"):
		return 1.0
	if arg_name.contains("trigger") or arg_name.contains("time"):
		if overrides.has("trigger_time"):
			return float(overrides.get("trigger_time", 0.0))
		return 0.0

	# Type-driven defaults.
	if arg_type == TYPE_ARRAY:
		return [220.0, 277.18, 329.63]
	if arg_type == TYPE_DICTIONARY:
		return {}
	if arg_type == TYPE_BOOL:
		return false
	if arg_type == TYPE_INT:
		return 0
	if arg_type == TYPE_FLOAT:
		return 0.0
	if arg_type == TYPE_STRING:
		return ""

	return 0.0


static func _coerce_float_array(values_variant: Variant) -> Array:
	var values: Array = []
	if values_variant is Array:
		var source: Array = values_variant as Array
		for value_variant in source:
			values.append(float(value_variant))
	return values


static func _midi_to_frequency(midi_note: int) -> float:
	return 440.0 * pow(2.0, (float(midi_note) - 69.0) / 12.0)


static func _normalize_chord_degree(chord_degree: String) -> String:
	var token: String = chord_degree.to_lower().strip_edges()
	token = token.replace(" ", "")
	token = token.replace("dim", "")
	token = token.replace("_", "")
	token = token.replace("-", "")
	var cleaned: String = ""
	for i in range(token.length()):
		var ch: String = token.substr(i, 1)
		if (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9"):
			cleaned += ch
	token = cleaned

	var roman_candidates: Array[String] = ["vii", "vi", "iv", "iii", "ii", "v", "i"]
	for candidate_variant in roman_candidates:
		var candidate: String = str(candidate_variant)
		if token.begins_with(candidate):
			return candidate
	return "i"


static func _key_to_pitch_class(key_name: String) -> int:
	var normalized_key: String = key_name.to_lower().strip_edges()
	var key_map: Dictionary = {
		"c": 0,
		"c#": 1, "db": 1,
		"d": 2,
		"d#": 3, "eb": 3,
		"e": 4,
		"f": 5,
		"f#": 6, "gb": 6,
		"g": 7,
		"g#": 8, "ab": 8,
		"a": 9,
		"a#": 10, "bb": 10,
		"b": 11, "cb": 11,
	}
	return int(key_map.get(normalized_key, 0))


static func _chord_degree_to_freqs(chord_degree: String, key_name: String = "C", scale_name: String = "major") -> Array:
	var degree: String = _normalize_chord_degree(chord_degree)
	var degree_map: Dictionary = {
		"i": 0,
		"ii": 1,
		"iii": 2,
		"iv": 3,
		"v": 4,
		"vi": 5,
		"vii": 6,
	}
	var degree_index: int = int(degree_map.get(degree, 0))

	var scale_intervals: Array = [0, 2, 4, 5, 7, 9, 11]
	var lower_scale: String = scale_name.to_lower()
	if lower_scale == "minor" or lower_scale == "aeolian" or lower_scale == "phrygian" or lower_scale == "dorian":
		scale_intervals = [0, 2, 3, 5, 7, 8, 10]

	var tonic_pitch_class: int = _key_to_pitch_class(key_name)
	var tonic_midi: int = 60 + tonic_pitch_class

	var root_interval: int = int(scale_intervals[degree_index % 7])
	var third_index: int = (degree_index + 2) % 7
	var fifth_index: int = (degree_index + 4) % 7
	var third_interval: int = int(scale_intervals[third_index])
	var fifth_interval: int = int(scale_intervals[fifth_index])
	if third_index <= degree_index:
		third_interval += 12
	if fifth_index <= degree_index:
		fifth_interval += 12

	var root_midi: int = tonic_midi + root_interval
	var third_midi: int = tonic_midi + third_interval
	var fifth_midi: int = tonic_midi + fifth_interval
	return [
		_midi_to_frequency(root_midi),
		_midi_to_frequency(third_midi),
		_midi_to_frequency(fifth_midi),
	]


static func _resolve_bank_id(song_id: String) -> String:
	var mapped_variant: Variant = SONG_TO_BANK.get(song_id, song_id)
	var mapped: String = str(mapped_variant)
	var brief_path: String = "%s%s/brief.json" % [SOUNDBANK_ROOT, mapped]
	if ResourceLoader.exists(brief_path):
		return mapped
	return ""


static func resolve_bank_id(song_id: String) -> String:
	var bank_id: String = _resolve_bank_id(song_id)
	return bank_id if not bank_id.is_empty() else song_id


static func load_song_bank(song_id: String) -> SoundbankLoader:
	return SoundbankLoader.load_genre(resolve_bank_id(song_id))


static func _normalize_token(name: String) -> String:
	return name.to_lower().strip_edges().replace(" ", "_").replace("-", "_")


static func _find_sound_index(normalized_sounds: Array[String], target: String) -> int:
	var normalized_target: String = _normalize_token(target)
	if normalized_target.is_empty():
		return -1

	for i in range(normalized_sounds.size()):
		if normalized_sounds[i] == normalized_target:
			return i

	# Avoid one/two-character partial matches (e.g. "i" matching "kick").
	if normalized_target.length() < 3:
		return -1

	for i in range(normalized_sounds.size()):
		var normalized_sound: String = normalized_sounds[i]
		if normalized_sound.contains(normalized_target) or normalized_target.contains(normalized_sound):
			return i

	return -1


static func _resolve_sound_name(layer_name: String, available_sounds: Array) -> String:
	if available_sounds.is_empty():
		return ""

	var normalized_layer: String = _normalize_token(layer_name)
	var normalized_sounds: Array[String] = []
	for sound_variant in available_sounds:
		normalized_sounds.append(_normalize_token(str(sound_variant)))

	# Chord-degree labels can come from pattern row previews.
	# Route them to harmony-like sounds rather than falling back to kick.
	var roman_degree_tokens: Array[String] = ["i", "ii", "iii", "iv", "v", "vi", "vii", "viio", "vii_dim"]
	if roman_degree_tokens.has(normalized_layer):
		for harmony_target in ["pad", "vocoder", "keys", "piano", "organ", "strings", "sequence"]:
			var harmony_idx: int = _find_sound_index(normalized_sounds, harmony_target)
			if harmony_idx >= 0:
				return str(available_sounds[harmony_idx])

	# 1) Exact normalized match.
	for i in range(normalized_sounds.size()):
		if normalized_sounds[i] == normalized_layer:
			return str(available_sounds[i])

	# 1.5) Keyword-to-sound targets for descriptive layer names.
	var keyword_targets: Dictionary = {
		"minimoog_bass": ["bass", "sub"],
		"bassline": ["bass", "sub"],
		"sequencer_line": ["sequence", "sequencer", "arp"],
		"sequencer": ["sequence", "sequencer", "arp"],
		"sequence": ["sequence", "sequencer", "arp"],
		"arpeggio": ["sequence", "arp", "lead"],
		"arp": ["sequence", "arp", "lead"],
		"lead_melody": ["lead", "sequence", "vocoder", "arp"],
		"melody": ["lead", "sequence", "vocoder", "arp"],
		"vocoder_pad": ["vocoder", "pad"],
		"vocoder": ["vocoder", "pad"],
		"electric_percussion": ["electronic_perc", "perc", "hihat"],
		"percussion": ["electronic_perc", "perc", "hihat"],
	}
	for keyword_variant in keyword_targets.keys():
		var keyword: String = str(keyword_variant)
		if not normalized_layer.contains(keyword):
			continue
		var targets_variant: Variant = keyword_targets.get(keyword_variant, [])
		if not (targets_variant is Array):
			continue
		var targets: Array = targets_variant as Array
		for target_variant in targets:
			var match_index: int = _find_sound_index(normalized_sounds, str(target_variant))
			if match_index >= 0:
				return str(available_sounds[match_index])

	# 2) Alias families.
	var aliases: Dictionary = {
		"drums": ["kick", "snare", "hihat_closed", "hihat_open", "clap"],
		"bass": ["bass", "sub", "reese", "juno_bass", "filter_bass", "trance_bass"],
		"pad": ["pad", "strings", "string_pad", "ambient_pad", "supersaw_pad"],
		"lead": ["lead", "keys", "arp", "duck_lead", "supersaw_lead"],
		"keys": ["keys", "piano", "chords", "pad", "organ", "rhodes", "vocoder", "lead"],
		"perc": ["electronic_perc", "perc", "rim", "tom", "hihat", "hihat_closed"],
		"percussion": ["electronic_perc", "perc", "rim", "tom", "hihat", "hihat_closed"],
		"arp": ["sequence", "arp", "lead"],
		"sequence": ["sequence", "arp", "lead"],
		"sequencer": ["sequence", "arp", "lead"],
		"vocoder": ["vocoder", "pad"],
	}
	for alias_key_variant in aliases.keys():
		var alias_key: String = str(alias_key_variant)
		if normalized_layer == alias_key or normalized_layer.contains(alias_key):
			var candidates_variant: Variant = aliases[alias_key_variant]
			if candidates_variant is Array:
				var candidates: Array = candidates_variant as Array
				for candidate_variant in candidates:
					var match_index: int = _find_sound_index(normalized_sounds, str(candidate_variant))
					if match_index >= 0:
						return str(available_sounds[match_index])

	# 3) Partial containment.
	for i in range(normalized_sounds.size()):
		var normalized_sound: String = normalized_sounds[i]
		if normalized_layer.length() >= 3 and (normalized_layer.contains(normalized_sound) or normalized_sound.contains(normalized_layer)):
			return str(available_sounds[i])

	# 4) First available as last resort.
	return str(available_sounds[0])


static func _resolve_sound_name_with_preferred(layer_name: String, available_sounds: Array, preferred_sound: String) -> String:
	if available_sounds.is_empty():
		return ""

	var preferred_normalized: String = _normalize_token(preferred_sound)
	if not preferred_normalized.is_empty():
		var normalized_sounds: Array[String] = []
		for sound_variant in available_sounds:
			normalized_sounds.append(_normalize_token(str(sound_variant)))

		var preferred_index: int = _find_sound_index(normalized_sounds, preferred_normalized)
		if preferred_index >= 0:
			return str(available_sounds[preferred_index])

		var role_targets: Dictionary = {
			"drum": ["kick", "snare", "hihat", "clap", "perc"],
			"bass": ["bass", "sub", "reese"],
			"lead": ["lead", "keys", "vocoder", "arp"],
			"pad": ["pad", "strings", "keys", "organ", "vocoder"],
			"arp": ["sequence", "arp", "lead"],
			"fx": ["noise", "fx", "perc"],
		}
		if role_targets.has(preferred_normalized):
			var targets_variant: Variant = role_targets.get(preferred_normalized, [])
			if targets_variant is Array:
				var targets: Array = targets_variant as Array
				for target_variant in targets:
					var role_match_index: int = _find_sound_index(normalized_sounds, str(target_variant))
					if role_match_index >= 0:
						return str(available_sounds[role_match_index])

	return _resolve_sound_name(layer_name, available_sounds)


static func _coerce_pattern(pattern_variant: Variant, fallback: Array) -> Array:
	var source: Array = []
	if pattern_variant is Array:
		source = (pattern_variant as Array).duplicate()
	if source.is_empty():
		source = fallback.duplicate()

	var result: Array = []
	result.resize(source.size())
	for i in range(source.size()):
		result[i] = float(source[i])

	return result


static func _default_pattern_for_layer(layer_name: String) -> Array:
	var layer: String = _normalize_token(layer_name)
	if layer.contains("hat"):
		return [1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0, 1, 0]
	if layer.contains("snare") or layer.contains("clap"):
		return [0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0]
	if layer.contains("drum") or layer.contains("kick"):
		return DEFAULT_PATTERN.duplicate()
	if layer.contains("pad") or layer.contains("string"):
		return [1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0]
	return DEFAULT_PATTERN.duplicate()


static func _resolve_param(value: Variant) -> float:
	if value is Dictionary:
		var dict_value: Dictionary = value
		if dict_value.has("value"):
			return float(dict_value["value"])
		if dict_value.has("range"):
			var range_variant: Variant = dict_value["range"]
			if range_variant is Array:
				var range_array: Array = range_variant
				if range_array.size() >= 2:
					var low: float = float(range_array[0])
					var high: float = float(range_array[1])
					var tendency: String = str(dict_value.get("tendency", "middle"))
					match tendency:
						"low":
							return low + (high - low) * 0.25
						"high":
							return low + (high - low) * 0.75
						_:
							return (low + high) * 0.5
		return 0.0
	return float(value) if value != null else 0.0


static func _render_procedural_preview(layer_name: String, params: Dictionary, sample_count: int) -> AudioStreamWAV:
	var data = PackedFloat32Array()
	data.resize(sample_count)

	var duration: float = float(sample_count) / SAMPLE_RATE
	var base_freq: float = 261.63
	var attack: float = _resolve_param(params.get("env.attack", params.get("attack", 0.01)))
	var decay: float = _resolve_param(params.get("env.decay", params.get("decay", 0.2)))
	var sustain: float = _resolve_param(params.get("env.sustain", params.get("sustain", 0.7)))
	var voices: int = int(_resolve_param(params.get("osc.voices", params.get("voices", 1))))
	var detune: float = _resolve_param(params.get("osc.detune", params.get("detune", 0.0)))

	var layer_lower: String = layer_name.to_lower()
	if layer_lower in ["bass", "reese bass", "juno bass", "filter bass", "trance bass"]:
		base_freq = 65.41
	elif layer_lower in ["pad", "ambient pad", "juno pad", "supersaw pad", "string pad"]:
		base_freq = 130.81
	elif layer_lower in ["lead", "supersaw lead", "duck lead", "vangelis keys"]:
		base_freq = 523.25

	var safe_attack: float = maxf(0.001, attack)
	var safe_decay: float = maxf(0.001, decay)
	var release_duration: float = 0.3
	var safe_voices: int = maxi(1, voices)

	for i in range(sample_count):
		var t: float = float(i) / SAMPLE_RATE
		var env: float = sustain
		if t < safe_attack:
			env = t / safe_attack
		elif t < safe_attack + safe_decay:
			env = 1.0 - (1.0 - sustain) * ((t - safe_attack) / safe_decay)
		elif t > duration - release_duration:
			env = sustain * (duration - t) / release_duration

		var osc: float = 0.0
		for voice_index in range(safe_voices):
			var voice_detune: float = 0.0
			if safe_voices > 1:
				voice_detune = (float(voice_index) / float(safe_voices - 1) - 0.5) * detune * 0.01
			var freq: float = base_freq * (1.0 + voice_detune)
			if layer_lower.contains("pad") or layer_lower.contains("ambient"):
				osc += sin(2.0 * PI * freq * t)
			else:
				osc += fmod(t * freq, 1.0) * 2.0 - 1.0

		osc /= float(safe_voices)
		data[i] = clampf(osc * env * 0.5, -1.0, 1.0)

	return create_audio_stream(data)


static func _is_silent(buffer: PackedFloat32Array) -> bool:
	for sample in buffer:
		if absf(sample) > 0.00001:
			return false
	return true
