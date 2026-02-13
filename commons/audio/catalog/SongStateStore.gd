extends RefCounted
class_name SongStateStore

signal state_changed(snapshot: Dictionary)
signal command_applied(command: Dictionary, snapshot: Dictionary)
signal command_rejected(command: Dictionary, reason: String)

const DEFAULT_KEY: String = "C"
const DEFAULT_SCALE: String = "major"
const DEFAULT_ROLE: String = "generic"

var _song_state: Dictionary = {}
var _layer_to_track_id: Dictionary = {}


func _init() -> void:
	_song_state = _make_default_song_state()


func initialize(song_id: String, bpm: float, key: String = DEFAULT_KEY, scale: String = DEFAULT_SCALE) -> void:
	_song_state = _make_default_song_state()
	_song_state["song_id"] = song_id
	_song_state["bpm"] = maxf(1.0, bpm)
	_song_state["key"] = key
	_song_state["scale"] = scale
	_layer_to_track_id.clear()
	state_changed.emit(snapshot())


func snapshot() -> Dictionary:
	return _song_state.duplicate(true)


func get_song_id() -> String:
	return str(_song_state.get("song_id", ""))


func ensure_track(layer_name: String, instrument_id: String = "", role: String = DEFAULT_ROLE) -> String:
	var normalized_layer: String = _normalize_layer_key(layer_name)
	var existing_track_id: String = str(_layer_to_track_id.get(normalized_layer, ""))
	if not existing_track_id.is_empty():
		return existing_track_id

	var track_id: String = _make_track_id(layer_name)
	register_track(track_id, layer_name, instrument_id, role)
	return track_id


func register_track(track_id: String, layer_name: String, instrument_id: String, role: String = DEFAULT_ROLE) -> void:
	var normalized_track_id: String = _normalize_track_id(track_id)
	if normalized_track_id.is_empty():
		return

	var tracks: Dictionary = _get_tracks()
	var track_state: Dictionary = {}
	if tracks.has(normalized_track_id):
		var existing_variant: Variant = tracks.get(normalized_track_id, {})
		if existing_variant is Dictionary:
			track_state = (existing_variant as Dictionary).duplicate(true)
	if track_state.is_empty():
		track_state = _make_default_track_state(normalized_track_id, layer_name, instrument_id, role)
	else:
		if not layer_name.is_empty():
			track_state["layer_name"] = layer_name
		if not instrument_id.is_empty():
			track_state["instrument_id"] = instrument_id
		if not role.is_empty():
			track_state["role"] = role

	tracks[normalized_track_id] = track_state
	_song_state["tracks"] = tracks
	if not layer_name.is_empty():
		_layer_to_track_id[_normalize_layer_key(layer_name)] = normalized_track_id
	state_changed.emit(snapshot())


func get_track_for_layer(layer_name: String) -> Dictionary:
	var layer_key: String = _normalize_layer_key(layer_name)
	var track_id: String = str(_layer_to_track_id.get(layer_key, ""))
	if track_id.is_empty():
		return {}
	var tracks: Dictionary = _get_tracks()
	var track_variant: Variant = tracks.get(track_id, {})
	if track_variant is Dictionary:
		return (track_variant as Dictionary).duplicate(true)
	return {}


func apply_command(command: Dictionary) -> bool:
	var command_type: String = str(command.get("type", ""))
	if command_type.is_empty():
		command_rejected.emit(command.duplicate(true), "missing command type")
		return false

	var applied: bool = false
	match command_type:
		"SetTrackParam":
			applied = _apply_set_track_param(command)
		"SetPatternData":
			applied = _apply_set_pattern_data(command)
		"AddTrackWord":
			applied = _apply_add_track_word(command)
		"RemoveTrackWord":
			applied = _apply_remove_track_word(command)
		"SetPreviewContext":
			applied = _apply_set_preview_context(command)
		"SetTrackMix":
			applied = _apply_set_track_mix(command)
		"SetTransport":
			applied = _apply_set_transport(command)
		"SetSongMeta":
			applied = _apply_set_song_meta(command)
		_:
			command_rejected.emit(command.duplicate(true), "unknown command type: %s" % command_type)
			return false

	if not applied:
		command_rejected.emit(command.duplicate(true), "handler rejected command: %s" % command_type)
		return false

	var snapshot_dict: Dictionary = snapshot()
	command_applied.emit(command.duplicate(true), snapshot_dict)
	state_changed.emit(snapshot_dict)
	return true


func _apply_set_track_param(command: Dictionary) -> bool:
	var track_id: String = _resolve_or_register_track(command)
	if track_id.is_empty():
		return false

	var param_key: String = str(command.get("param", ""))
	if param_key.is_empty():
		return false
	var value: Variant = command.get("value", 0.0)

	var track_state: Dictionary = _get_track(track_id)
	var params: Dictionary = _coerce_dict(track_state.get("params", {}))
	params[param_key] = value
	track_state["params"] = params
	_set_track(track_id, track_state)
	return true


func _apply_set_pattern_data(command: Dictionary) -> bool:
	var track_id: String = _resolve_or_register_track(command)
	if track_id.is_empty():
		return false

	var pattern_variant: Variant = command.get("pattern_data", {})
	if not (pattern_variant is Dictionary):
		return false
	var pattern_data: Dictionary = (pattern_variant as Dictionary).duplicate(true)

	var track_state: Dictionary = _get_track(track_id)
	track_state["pattern_data"] = pattern_data

	if pattern_data.has("pattern"):
		var pattern_steps_variant: Variant = pattern_data.get("pattern", [])
		if pattern_steps_variant is Array:
			track_state["pattern"] = (pattern_steps_variant as Array).duplicate()
	if pattern_data.has("notes"):
		var notes_variant: Variant = pattern_data.get("notes", [])
		if notes_variant is Array:
			track_state["notes"] = (notes_variant as Array).duplicate()
	if pattern_data.has("chords"):
		var chords_variant: Variant = pattern_data.get("chords", [])
		if chords_variant is Array:
			track_state["chords"] = (chords_variant as Array).duplicate()
	if pattern_data.has("key"):
		_song_state["key"] = str(pattern_data.get("key", _song_state.get("key", DEFAULT_KEY)))
	if pattern_data.has("scale"):
		_song_state["scale"] = str(pattern_data.get("scale", _song_state.get("scale", DEFAULT_SCALE)))

	_set_track(track_id, track_state)
	return true


func _apply_add_track_word(command: Dictionary) -> bool:
	var track_id: String = _resolve_or_register_track(command)
	if track_id.is_empty():
		return false
	var word: String = str(command.get("word", "")).strip_edges()
	if word.is_empty():
		return false

	var track_state: Dictionary = _get_track(track_id)
	var words: Array = _coerce_array(track_state.get("words", []))
	if not words.has(word):
		words.append(word)
	track_state["words"] = words
	_set_track(track_id, track_state)
	return true


func _apply_remove_track_word(command: Dictionary) -> bool:
	var track_id: String = _resolve_or_register_track(command)
	if track_id.is_empty():
		return false
	var word: String = str(command.get("word", "")).strip_edges()
	if word.is_empty():
		return false

	var track_state: Dictionary = _get_track(track_id)
	var words: Array = _coerce_array(track_state.get("words", []))
	words.erase(word)
	track_state["words"] = words
	_set_track(track_id, track_state)
	return true


func _apply_set_preview_context(command: Dictionary) -> bool:
	var track_id: String = _resolve_or_register_track(command)
	if track_id.is_empty():
		return false

	var context_variant: Variant = command.get("context", {})
	if not (context_variant is Dictionary):
		return false
	var context: Dictionary = (context_variant as Dictionary).duplicate(true)

	var track_state: Dictionary = _get_track(track_id)
	track_state["last_preview_context"] = context
	_set_track(track_id, track_state)
	return true


func _apply_set_track_mix(command: Dictionary) -> bool:
	var track_id: String = _resolve_or_register_track(command)
	if track_id.is_empty():
		return false

	var track_state: Dictionary = _get_track(track_id)
	var mix: Dictionary = _coerce_dict(track_state.get("mix", _default_mix_state()))

	if command.has("mute"):
		mix["mute"] = bool(command.get("mute", false))
	if command.has("solo"):
		mix["solo"] = bool(command.get("solo", false))
	if command.has("gain_db"):
		mix["gain_db"] = float(command.get("gain_db", 0.0))
	if command.has("pan"):
		mix["pan"] = clampf(float(command.get("pan", 0.0)), -1.0, 1.0)

	track_state["mix"] = mix
	_set_track(track_id, track_state)
	return true


func _apply_set_transport(command: Dictionary) -> bool:
	var transport: Dictionary = _coerce_dict(_song_state.get("transport", _default_transport_state()))
	if command.has("playing"):
		transport["playing"] = bool(command.get("playing", false))
	if command.has("position_sec"):
		transport["position_sec"] = maxf(0.0, float(command.get("position_sec", 0.0)))
	if command.has("loop_start"):
		transport["loop_start"] = maxf(0.0, float(command.get("loop_start", 0.0)))
	if command.has("loop_end"):
		transport["loop_end"] = maxf(0.0, float(command.get("loop_end", 0.0)))
	if command.has("bpm"):
		_song_state["bpm"] = maxf(1.0, float(command.get("bpm", _song_state.get("bpm", 120.0))))
	_song_state["transport"] = transport
	return true


func _apply_set_song_meta(command: Dictionary) -> bool:
	if command.has("song_id"):
		_song_state["song_id"] = str(command.get("song_id", _song_state.get("song_id", "")))
	if command.has("bpm"):
		_song_state["bpm"] = maxf(1.0, float(command.get("bpm", _song_state.get("bpm", 120.0))))
	if command.has("key"):
		_song_state["key"] = str(command.get("key", _song_state.get("key", DEFAULT_KEY)))
	if command.has("scale"):
		_song_state["scale"] = str(command.get("scale", _song_state.get("scale", DEFAULT_SCALE)))
	return true


func _resolve_or_register_track(command: Dictionary) -> String:
	var track_id: String = _normalize_track_id(str(command.get("track_id", "")))
	var layer_name: String = str(command.get("layer_name", ""))
	var instrument_id: String = str(command.get("instrument_id", ""))
	var role: String = str(command.get("role", DEFAULT_ROLE))

	if track_id.is_empty() and not layer_name.is_empty():
		var layer_key: String = _normalize_layer_key(layer_name)
		track_id = str(_layer_to_track_id.get(layer_key, ""))
		if track_id.is_empty():
			track_id = _make_track_id(layer_name)

	if track_id.is_empty():
		return ""

	var tracks: Dictionary = _get_tracks()
	if not tracks.has(track_id):
		register_track(track_id, layer_name, instrument_id, role)
	else:
		if not layer_name.is_empty():
			_layer_to_track_id[_normalize_layer_key(layer_name)] = track_id
	return track_id


func _get_tracks() -> Dictionary:
	var tracks_variant: Variant = _song_state.get("tracks", {})
	if tracks_variant is Dictionary:
		return tracks_variant as Dictionary
	return {}


func _get_track(track_id: String) -> Dictionary:
	var tracks: Dictionary = _get_tracks()
	var track_variant: Variant = tracks.get(track_id, {})
	if track_variant is Dictionary:
		return (track_variant as Dictionary).duplicate(true)
	return _make_default_track_state(track_id, "", "", DEFAULT_ROLE)


func _set_track(track_id: String, track_state: Dictionary) -> void:
	var tracks: Dictionary = _get_tracks()
	tracks[track_id] = track_state.duplicate(true)
	_song_state["tracks"] = tracks
	var layer_name: String = str(track_state.get("layer_name", ""))
	if not layer_name.is_empty():
		_layer_to_track_id[_normalize_layer_key(layer_name)] = track_id


func _make_default_song_state() -> Dictionary:
	return {
		"song_id": "",
		"bpm": 120.0,
		"key": DEFAULT_KEY,
		"scale": DEFAULT_SCALE,
		"transport": _default_transport_state(),
		"tracks": {},
	}


func _make_default_track_state(track_id: String, layer_name: String, instrument_id: String, role: String) -> Dictionary:
	return {
		"track_id": track_id,
		"layer_name": layer_name,
		"instrument_id": instrument_id if not instrument_id.is_empty() else _normalize_track_id(layer_name),
		"role": role if not role.is_empty() else DEFAULT_ROLE,
		"pattern": [],
		"notes": [],
		"chords": [],
		"pattern_data": {},
		"params": {},
		"words": [],
		"mix": _default_mix_state(),
		"last_preview_context": {},
	}


func _default_transport_state() -> Dictionary:
	return {
		"playing": false,
		"position_sec": 0.0,
		"loop_start": 0.0,
		"loop_end": 0.0,
	}


func _default_mix_state() -> Dictionary:
	return {
		"mute": false,
		"solo": false,
		"gain_db": 0.0,
		"pan": 0.0,
	}


func _make_track_id(layer_name: String) -> String:
	var normalized: String = _normalize_track_id(layer_name)
	return "track_%s" % normalized if not normalized.is_empty() else "track_unknown"


func _normalize_track_id(value: String) -> String:
	var normalized: String = value.strip_edges().to_lower()
	normalized = normalized.replace(" ", "_")
	normalized = normalized.replace("-", "_")
	var sanitized: String = ""
	for idx in range(normalized.length()):
		var ch: String = normalized.substr(idx, 1)
		var keep: bool = (ch >= "a" and ch <= "z") or (ch >= "0" and ch <= "9") or ch == "_"
		if keep:
			sanitized += ch
	while sanitized.contains("__"):
		sanitized = sanitized.replace("__", "_")
	return sanitized.strip_edges()


func _normalize_layer_key(layer_name: String) -> String:
	return _normalize_track_id(layer_name)


func _coerce_dict(value: Variant) -> Dictionary:
	if value is Dictionary:
		return (value as Dictionary).duplicate(true)
	return {}


func _coerce_array(value: Variant) -> Array:
	if value is Array:
		return (value as Array).duplicate()
	return []
