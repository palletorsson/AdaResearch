# SoundSuiteSequencer.gd
# Runtime sequencer that can switch between generator suites and soundbank-backed suites.

extends Node
class_name SoundSuiteSequencer

signal beat_triggered(beat_number: int)
signal pattern_changed(pattern_name: String)
signal suite_changed(suite_name: String)
signal bpm_changed(new_bpm: float)

const SAMPLE_RATE := 44100.0
const SUITE_MAPPER_PATH := "res://commons/audio/soundbanks/SuitToSoundbankMapper.gd"
const VOICE_COUNT := 24

const BASE_SUITES := {
	"trap_beats": {
		"bpm": 85.0,
		"sounds": {
			"kick": {"generator": "trap_beats", "sound_name": "kick", "default_params": {"pitch": 60.0, "decay": 1.2}},
			"snare": {"generator": "trap_beats", "sound_name": "snare", "default_params": {"decay": 0.3, "noise_amount": 0.7}},
			"hihat_closed": {"generator": "trap_beats", "sound_name": "hihat_closed", "default_params": {"decay": 0.05, "noise_tone": 8000.0}},
			"hihat_open": {"generator": "trap_beats", "sound_name": "hihat_open", "default_params": {"decay": 0.3, "noise_tone": 7000.0}},
			"clap": {"generator": "trap_beats", "sound_name": "clap", "default_params": {"decay": 0.35}},
			"rim": {"generator": "trap_beats", "sound_name": "rim", "default_params": {"pitch": 220.0}},
			"tom": {"generator": "trap_beats", "sound_name": "tom", "default_params": {"pitch": 120.0}},
			"cowbell": {"generator": "trap_beats", "sound_name": "cowbell", "default_params": {"pitch": 900.0}}
		},
		"patterns": {
			"minimal_trap": {
				"length": 16,
				"kick": [1,0,0,0, 0,0,0,1, 0,0,1,0, 0,0,0,0],
				"snare": [0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
				"hihat_closed": [1,0,1,0, 1,0,1,0, 1,0,1,0, 1,0,1,0],
				"hihat_open": [0,0,0,0, 0,0,0,1, 0,0,0,0, 0,0,0,1],
				"clap": [0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
				"rim": [0,0,0,0, 0,1,0,0, 0,0,0,0, 0,1,0,0]
			},
			"hard": {
				"length": 16,
				"kick": [1,0,0,1, 0,0,1,0, 1,0,1,0, 0,0,1,0],
				"snare": [0,0,0,0, 0,0,0,0, 1,0,0,1, 0,0,0,0],
				"hihat_closed": [1,1,1,1, 1,1,1,1, 1,1,1,1, 1,1,1,1],
				"hihat_open": [0,0,0,0, 0,0,0,1, 0,0,0,0, 0,0,0,1],
				"clap": [0,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
				"rim": [0,0,0,0, 0,1,0,0, 0,0,0,0, 0,1,0,0],
				"cowbell": [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0]
			},
			"four_floor": {
				"length": 16,
				"kick": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],
				"snare": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
				"hihat_closed": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],
				"clap": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0]
			}
		},
		"default_pattern": "minimal_trap"
	},
	"tech_noir": {
		"bpm": 60.0,
		"sounds": {
			"drone": {"generator": "tech_noir", "sound_name": "drone", "default_params": {"base_frequency": 60.0, "harmonic_count": 8}},
			"city": {"generator": "tech_noir", "sound_name": "city", "default_params": {"base_frequency": 70.0, "modulation_depth": 0.3}},
			"siren": {"generator": "tech_noir", "sound_name": "siren", "default_params": {"base_pitch": 440.0, "duration": 2.0}},
			"static": {"generator": "tech_noir", "sound_name": "static", "default_params": {"duration": 0.2}},
			"rain": {"generator": "tech_noir", "sound_name": "rain", "default_params": {"drop_density": 0.6, "filter_frequency": 2000.0}},
			"mechanical": {"generator": "tech_noir", "sound_name": "mechanical", "default_params": {"base_frequency": 80.0, "rpm": 0.4}},
			"typing": {"generator": "tech_noir", "sound_name": "typing", "default_params": {"key_count": 3, "typing_speed": 0.6}},
			"hum": {"generator": "tech_noir", "sound_name": "hum", "default_params": {"frequency": 50.0, "harmonic_count": 5}},
			"heartbeat": {"generator": "tech_noir", "sound_name": "heartbeat", "default_params": {"bpm": 58.0, "peak_frequency": 95.0}}
		},
		"patterns": {
			"ambient_sparse": {
				"length": 16,
				"drone": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
				"city": [0,0,0,0, 1,0,0,0, 0,0,0,0, 1,0,0,0],
				"rain": [0,0,0,0, 0,0,1,0, 0,0,0,0, 0,0,1,0],
				"static": [0,0,0,0, 0,0,0,0, 0,0,0,1, 0,0,0,0],
				"siren": [0,0,0,0, 0,0,0,0, 0,0,0,0, 1,0,0,0]
			},
			"atmospheric_layers": {
				"length": 16,
				"drone": [1,0,0,0, 1,0,0,0, 1,0,0,0, 1,0,0,0],
				"city": [0,0,1,0, 0,0,1,0, 0,0,1,0, 0,0,1,0],
				"rain": [0,1,0,1, 0,1,0,1, 0,1,0,1, 0,1,0,1],
				"hum": [1,0,0,0, 0,0,0,0, 1,0,0,0, 0,0,0,0],
				"mechanical": [0,0,0,0, 0,0,0,1, 0,0,0,0, 0,0,0,1]
			}
		},
		"default_pattern": "ambient_sparse"
	}
}

var current_suite: String = ""
var current_pattern: Dictionary = {}
var is_playing: bool = false
var bpm: float = 120.0
var swing_amount: float = 0.0
var variation: float = 0.0
var pattern_length: int = 16

var _suite_definitions: Dictionary = {}
var _track_state: Dictionary = {}
var _stream_cache: Dictionary = {}
var _soundbank_cache: Dictionary = {}
var _voice_pool: Array[AudioStreamPlayer] = []
var _voice_cursor: int = 0

var _step_index: int = 0
var _beat_counter: int = 0
var _step_timer: float = 0.0
var _base_step_interval: float = 0.125
var _current_step_interval: float = 0.125


func _ready():
	randomize()
	_suite_definitions = BASE_SUITES.duplicate(true)
	_register_mapper_suite("detroit_techno", "detroit_techno", "detroit_techno")
	_init_voice_pool()
	_update_timing()


func initialize(config: Dictionary):
	if config.has("bpm"):
		set_bpm(float(config.get("bpm", bpm)))
	if config.has("swing"):
		set_swing(float(config.get("swing", swing_amount)))
	if config.has("variation"):
		set_variation(float(config.get("variation", variation)))

	var requested_suite := str(config.get("suite", "trap_beats"))
	if not change_suite(requested_suite):
		change_suite("trap_beats")

	var requested_pattern = config.get("pattern", "")
	if requested_pattern != "":
		load_pattern(requested_pattern)

	var sound_params: Dictionary = config.get("sound_params", {})
	for sound_name in sound_params.keys():
		var params: Dictionary = sound_params.get(sound_name, {})
		set_sound_params(str(sound_name), params)


func change_suite(suite_name: String) -> bool:
	if not _suite_definitions.has(suite_name):
		push_warning("SoundSuiteSequencer: Suite not found: " + suite_name)
		return false

	current_suite = suite_name
	_stream_cache.clear()
	_build_track_state()

	var suite_def: Dictionary = _suite_definitions[current_suite]
	if suite_def.has("bpm"):
		set_bpm(float(suite_def.get("bpm", bpm)))

	var default_pattern := str(suite_def.get("default_pattern", ""))
	if default_pattern.is_empty():
		var patterns: Dictionary = suite_def.get("patterns", {})
		if not patterns.is_empty():
			default_pattern = str(patterns.keys()[0])

	if not default_pattern.is_empty():
		load_pattern(default_pattern)
	else:
		current_pattern = {"length": 16}
		pattern_length = 16

	suite_changed.emit(current_suite)
	return true


func load_pattern(pattern) -> bool:
	if current_suite.is_empty():
		push_warning("SoundSuiteSequencer: No current suite. Call change_suite() first.")
		return false

	if pattern is String:
		var pattern_name := str(pattern)
		var suite_patterns: Dictionary = _suite_definitions[current_suite].get("patterns", {})
		if not suite_patterns.has(pattern_name):
			push_warning("SoundSuiteSequencer: Pattern not found in suite '%s': %s" % [current_suite, pattern_name])
			return false
		current_pattern = _normalize_pattern(suite_patterns.get(pattern_name, {}))
		pattern_length = int(current_pattern.get("length", 16))
		pattern_changed.emit(pattern_name)
		return true

	if pattern is Dictionary:
		current_pattern = _normalize_pattern(pattern)
		pattern_length = int(current_pattern.get("length", 16))
		pattern_changed.emit("custom")
		return true

	push_warning("SoundSuiteSequencer: Invalid pattern type. Expected String or Dictionary.")
	return false


func set_sound_params(sound_name: String, params: Dictionary):
	if not _track_state.has(sound_name):
		return
	var state: Dictionary = _track_state[sound_name]
	var merged: Dictionary = state.get("params", {}).duplicate(true)
	for key in params.keys():
		merged[key] = params[key]
	state["params"] = merged
	_track_state[sound_name] = state
	_invalidate_stream_cache(sound_name)


func get_sound_params(sound_name: String) -> Dictionary:
	if not _track_state.has(sound_name):
		return {}
	return _track_state[sound_name].get("params", {}).duplicate(true)


func start():
	if current_suite.is_empty():
		if not change_suite("trap_beats"):
			return
	is_playing = true
	_step_index = 0
	_beat_counter = 0
	_step_timer = 0.0
	_current_step_interval = _compute_step_interval(_step_index)


func stop():
	is_playing = false
	_step_timer = 0.0


func set_bpm(new_bpm: float):
	bpm = clampf(new_bpm, 40.0, 200.0)
	_update_timing()
	bpm_changed.emit(bpm)


func set_swing(amount: float):
	swing_amount = clampf(amount, 0.0, 1.0)
	_current_step_interval = _compute_step_interval(_step_index)


func set_variation(amount: float):
	variation = clampf(amount, 0.0, 1.0)


func mute_track(track_name: String, muted: bool):
	if not _track_state.has(track_name):
		return
	var state: Dictionary = _track_state[track_name]
	state["muted"] = muted
	_track_state[track_name] = state


func set_track_volume(track_name: String, volume_db: float):
	if not _track_state.has(track_name):
		return
	var state: Dictionary = _track_state[track_name]
	state["volume_db"] = clampf(volume_db, -60.0, 12.0)
	_track_state[track_name] = state


func get_available_suites() -> Array:
	var names: Array = _suite_definitions.keys()
	names.sort()
	return names


func get_suite_sounds() -> Array:
	if not current_suite.is_empty() and _suite_definitions.has(current_suite):
		return _suite_definitions[current_suite].get("sounds", {}).keys()
	return []


func _process(delta: float):
	if not is_playing:
		return

	_step_timer += delta
	while _step_timer >= _current_step_interval:
		_step_timer -= _current_step_interval
		_trigger_step(_step_index)

		_step_index = (_step_index + 1) % maxi(pattern_length, 1)
		if _step_index % 4 == 0:
			_beat_counter += 1
			beat_triggered.emit(_beat_counter)

		_current_step_interval = _compute_step_interval(_step_index)


func _trigger_step(step_index: int):
	if current_pattern.is_empty():
		return

	for track_name_variant in current_pattern.keys():
		var track_name := str(track_name_variant)
		if track_name == "length":
			continue
		if not _track_state.has(track_name):
			continue

		var row = current_pattern.get(track_name, [])
		if not (row is Array):
			continue

		var hit_value := _step_value(row, step_index)
		if hit_value <= 0.0:
			continue

		var state: Dictionary = _track_state[track_name]
		if bool(state.get("muted", false)):
			continue

		var velocity := hit_value
		if variation > 0.0:
			var drop_chance := 0.15 * variation
			if velocity < 1.0 and randf() < drop_chance:
				continue
			velocity *= 1.0 + randf_range(-0.2, 0.2) * variation
			velocity = clampf(velocity, 0.05, 2.0)

		var stream: AudioStreamWAV = _get_track_stream(track_name)
		if stream == null:
			continue

		var track_volume_db := float(state.get("volume_db", 0.0))
		var velocity_gain := linear_to_db(clampf(velocity, 0.001, 2.0))
		_play_stream(stream, track_volume_db + velocity_gain)


func _step_value(values: Array, step_index: int) -> float:
	if values.is_empty():
		return 0.0
	var idx := step_index % values.size()
	return float(values[idx])


func _get_track_stream(track_name: String) -> AudioStreamWAV:
	var track_cfg: Dictionary = _get_track_config(track_name)
	if track_cfg.is_empty():
		return null

	var params: Dictionary = _track_state.get(track_name, {}).get("params", {})
	var cache_key := _build_cache_key(track_name, params)
	if _stream_cache.has(cache_key):
		return _stream_cache[cache_key]

	var generator := str(track_cfg.get("generator", ""))
	var sound_name := str(track_cfg.get("sound_name", track_name))
	var stream: AudioStreamWAV = null

	match generator:
		"trap_beats":
			stream = TrapBeatsGenerator.generate_sound(sound_name, params)
		"tech_noir":
			stream = TechnoNoirGenerator.generate_sound(sound_name, params)
		"soundbank_script":
			stream = _generate_soundbank_script_stream(track_cfg, params)
		_:
			push_warning("SoundSuiteSequencer: Unknown generator for '%s': %s" % [track_name, generator])
			stream = null

	if stream != null:
		_stream_cache[cache_key] = stream
	return stream


func _generate_soundbank_script_stream(track_cfg: Dictionary, params: Dictionary) -> AudioStreamWAV:
	var soundbank_id := str(track_cfg.get("soundbank_id", ""))
	var sound_name := str(track_cfg.get("sound_name", ""))
	if soundbank_id.is_empty() or sound_name.is_empty():
		return null

	var bank = _soundbank_cache.get(soundbank_id, null)
	if bank == null:
		bank = SoundbankLoader.load_genre(soundbank_id)
		_soundbank_cache[soundbank_id] = bank
	if bank == null or not bank.has_sound(sound_name):
		return null

	var script = bank.get_sound_script(sound_name)
	if script == null:
		return null

	var duration := clampf(float(params.get("duration", _default_duration(sound_name))), 0.06, 6.0)
	var gain := clampf(float(params.get("gain", 1.0)), 0.0, 2.0)
	var freq := _resolve_frequency(params)
	var chord_freqs: Array = params.get("chord_freqs", [freq, freq * 1.25, freq * 1.5])
	var sample_count := int(SAMPLE_RATE * duration)

	var data := PackedFloat32Array()
	data.resize(sample_count)

	for i in range(sample_count):
		var t := float(i) / SAMPLE_RATE
		var sample := _sample_soundbank(script, sound_name, t, freq, chord_freqs, duration, params)
		data[i] = clampf(sample * gain, -1.0, 1.0)

	return CustomSoundGenerator.create_audio_stream(data)


func _sample_soundbank(script, sound_name: String, t: float, freq: float, chord_freqs: Array, duration: float, params: Dictionary) -> float:
	var trigger_time := float(params.get("trigger_time", 0.0))

	if _is_percussion(sound_name):
		if sound_name == "hihat":
			if script.has_method("generate_closed"):
				return script.generate_closed(t, trigger_time)
			if script.has_method("generate"):
				return script.generate(t, trigger_time, false)
			return 0.0
		if script.has_method("generate"):
			return script.generate(t, trigger_time)
		return 0.0

	if _is_bass(sound_name):
		if script.has_method("generate"):
			return script.generate(t, freq, duration, trigger_time)
		if script.has_method("generate_sample"):
			return script.generate_sample(t, freq)
		return 0.0

	if _is_harmony(sound_name):
		if script.has_method("generate"):
			return script.generate(t, chord_freqs, duration, trigger_time)
		if script.has_method("generate_sample"):
			return script.generate_sample(t, chord_freqs)
		return 0.0

	if _is_stab(sound_name):
		if script.has_method("generate"):
			return script.generate(t, chord_freqs, trigger_time)
		return 0.0

	if _is_melodic(sound_name):
		if script.has_method("generate"):
			return script.generate(t, freq, trigger_time)
		if script.has_method("generate_sample"):
			return script.generate_sample(t, freq)
		return 0.0

	if script.has_method("generate"):
		return script.generate(t, trigger_time)
	return 0.0


func _resolve_frequency(params: Dictionary) -> float:
	if params.has("frequency_hz"):
		return maxf(float(params.get("frequency_hz", 110.0)), 20.0)
	if params.has("root_freq_hz"):
		return maxf(float(params.get("root_freq_hz", 110.0)), 20.0)
	if params.has("midi_note"):
		var midi := float(params.get("midi_note", 45.0))
		return 440.0 * pow(2.0, (midi - 69.0) / 12.0)
	return 110.0


func _default_duration(sound_name: String) -> float:
	if _is_percussion(sound_name):
		return 0.28
	if _is_bass(sound_name):
		return 0.45
	if _is_harmony(sound_name):
		return 0.8
	if _is_stab(sound_name):
		return 0.35
	if _is_melodic(sound_name):
		return 0.3
	return 0.3


func _is_percussion(sound_name: String) -> bool:
	return sound_name in ["kick", "snare", "clap", "hihat", "rimshot", "shaker", "fingersnap", "tambourine", "perc", "rim", "tom", "cowbell", "break"]


func _is_bass(sound_name: String) -> bool:
	return sound_name in ["bass", "sub", "hoover"]


func _is_harmony(sound_name: String) -> bool:
	return sound_name in ["pad", "strings", "choir", "organ", "piano", "rhodes"]


func _is_stab(sound_name: String) -> bool:
	return sound_name in ["stab", "chord_stab", "echo_stab"]


func _is_melodic(sound_name: String) -> bool:
	return sound_name in ["arp", "sequence", "sequencer", "lead", "vocoder", "vocal", "jupiter_arp", "singing_voice"]


func _build_track_state():
	_track_state.clear()
	var suite_def: Dictionary = _suite_definitions.get(current_suite, {})
	var sounds: Dictionary = suite_def.get("sounds", {})
	for track_name_variant in sounds.keys():
		var track_name := str(track_name_variant)
		var cfg: Dictionary = sounds.get(track_name, {})
		_track_state[track_name] = {
			"params": cfg.get("default_params", {}).duplicate(true),
			"muted": false,
			"volume_db": 0.0
		}


func _get_track_config(track_name: String) -> Dictionary:
	if current_suite.is_empty() or not _suite_definitions.has(current_suite):
		return {}
	var sounds: Dictionary = _suite_definitions[current_suite].get("sounds", {})
	return sounds.get(track_name, {})


func _normalize_pattern(pattern: Dictionary) -> Dictionary:
	var normalized := {}
	var inferred_length := int(pattern.get("length", _infer_pattern_length(pattern)))
	var length := maxi(inferred_length, 1)
	normalized["length"] = length

	for key_variant in pattern.keys():
		var key := str(key_variant)
		if key == "length":
			continue
		var row = pattern.get(key, [])
		if not (row is Array):
			continue
		var resized: Array = []
		resized.resize(length)
		for i in range(length):
			resized[i] = float(row[i]) if i < row.size() else 0.0
		normalized[key] = resized

	return normalized


func _infer_pattern_length(pattern: Dictionary) -> int:
	var max_len := 16
	for key_variant in pattern.keys():
		var key := str(key_variant)
		if key == "length":
			continue
		var row = pattern.get(key, [])
		if row is Array:
			max_len = maxi(max_len, row.size())
	return max_len


func _build_cache_key(track_name: String, params: Dictionary) -> String:
	return "%s|%s|%s" % [current_suite, track_name, JSON.stringify(params)]


func _invalidate_stream_cache(track_name: String):
	var prefix := "%s|%s|" % [current_suite, track_name]
	var to_remove: Array = []
	for cache_key_variant in _stream_cache.keys():
		var cache_key := str(cache_key_variant)
		if cache_key.begins_with(prefix):
			to_remove.append(cache_key)
	for cache_key in to_remove:
		_stream_cache.erase(cache_key)


func _compute_step_interval(step_index: int) -> float:
	var swing_depth := clampf(swing_amount, 0.0, 1.0) * 0.35
	if step_index % 2 == 1:
		return _base_step_interval * (1.0 + swing_depth)
	return _base_step_interval * (1.0 - swing_depth)


func _update_timing():
	var steps_per_second := (bpm / 60.0) * 4.0
	_base_step_interval = 1.0 / maxf(steps_per_second, 0.001)
	_current_step_interval = _compute_step_interval(_step_index)


func _init_voice_pool():
	for i in range(VOICE_COUNT):
		var player := AudioStreamPlayer.new()
		player.name = "SuiteVoice_%02d" % i
		player.bus = "Master"
		add_child(player)
		_voice_pool.append(player)


func _play_stream(stream: AudioStreamWAV, volume_db: float):
	if _voice_pool.is_empty():
		return
	var index := _voice_cursor % _voice_pool.size()
	_voice_cursor += 1
	var player: AudioStreamPlayer = _voice_pool[index]
	player.stop()
	player.stream = stream
	player.volume_db = clampf(volume_db, -60.0, 12.0)
	player.play()


func _register_mapper_suite(genre_id: String, suite_id: String, soundbank_id: String):
	if not ResourceLoader.exists(SUITE_MAPPER_PATH):
		return
	var mapper = load(SUITE_MAPPER_PATH)
	if mapper == null:
		return

	var runtime_suite: Dictionary = mapper.build_runtime_suite(genre_id, suite_id, soundbank_id)
	if runtime_suite.is_empty():
		return
	_suite_definitions[suite_id] = runtime_suite
