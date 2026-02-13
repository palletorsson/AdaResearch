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

	for bar in range(maxi(1, num_bars)):
		var bar_start: int = int(float(bar) * bar_duration * SAMPLE_RATE)
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

			var step_start: int = bar_start + step * step_samples
			_add_sound_to_buffer(buffer, script, step_start, volume)

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
	var sound_name: String = _resolve_sound_name(layer_name, available_sounds)
	if sound_name.is_empty():
		return _render_procedural_preview(layer_name, params, total_samples)

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
		buffer[idx] = clampf(buffer[idx] + sample * volume, -1.0, 1.0)


static func _sample_script(script: Variant, t: float) -> float:
	if script == null:
		return 0.0

	if script.has_method("generate"):
		var value: Variant = script.call("generate", t, 0.0)
		return float(value)
	if script.has_method("generate_closed"):
		var value_closed: Variant = script.call("generate_closed", t, 0.0)
		return float(value_closed)
	if script.has_method("generate_sample"):
		var value_sample: Variant = script.call("generate_sample", t, [])
		return float(value_sample)

	return 0.0


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


static func _resolve_sound_name(layer_name: String, available_sounds: Array) -> String:
	if available_sounds.is_empty():
		return ""

	var normalized_layer: String = _normalize_token(layer_name)
	var normalized_sounds: Array[String] = []
	for sound_variant in available_sounds:
		normalized_sounds.append(_normalize_token(str(sound_variant)))

	# 1) Exact normalized match.
	for i in range(normalized_sounds.size()):
		if normalized_sounds[i] == normalized_layer:
			return str(available_sounds[i])

	# 2) Alias families.
	var aliases: Dictionary = {
		"drums": ["kick", "snare", "hihat_closed", "hihat_open", "clap"],
		"bass": ["bass", "sub", "reese", "juno_bass", "filter_bass", "trance_bass"],
		"pad": ["pad", "strings", "string_pad", "ambient_pad", "supersaw_pad"],
		"lead": ["lead", "keys", "arp", "duck_lead", "supersaw_lead"],
		"keys": ["keys", "piano", "chords", "lead"],
		"perc": ["perc", "rim", "tom", "hihat_closed"],
	}
	for alias_key_variant in aliases.keys():
		var alias_key: String = str(alias_key_variant)
		if normalized_layer == alias_key or normalized_layer.contains(alias_key):
			var candidates_variant: Variant = aliases[alias_key_variant]
			if candidates_variant is Array:
				var candidates: Array = candidates_variant
				for candidate_variant in candidates:
					var candidate: String = _normalize_token(str(candidate_variant))
					for i in range(normalized_sounds.size()):
						if normalized_sounds[i] == candidate:
							return str(available_sounds[i])

	# 3) Partial containment.
	for i in range(normalized_sounds.size()):
		var normalized_sound: String = normalized_sounds[i]
		if normalized_layer.contains(normalized_sound) or normalized_sound.contains(normalized_layer):
			return str(available_sounds[i])

	# 4) First available as last resort.
	return str(available_sounds[0])


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
