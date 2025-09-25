extends Node

const TEXT_DATA_PATH := "res://commons/text/map_texts.json"
const GLOBAL_MAP_KEY := "_global"

var text_data: Dictionary = {}
var event_counters: Dictionary = {}
var event_id_exhausted: Dictionary = {}
var exhausted_events: Dictionary = {}
var last_loaded_path: String = TEXT_DATA_PATH

signal text_data_reloaded(success: bool)
signal text_triggered(event_id: String, message_data: Dictionary)
signal text_missing(event_id: String, map_name: String)

func _ready() -> void:
	load_text_data(TEXT_DATA_PATH)
	if typeof(GameManager) != TYPE_NIL and GameManager.has_signal("current_map_changed"):
		GameManager.current_map_changed.connect(_on_current_map_changed)

func load_text_data(path: String = TEXT_DATA_PATH) -> bool:
	last_loaded_path = path
	var success := false
	var parsed: Dictionary = {}
	if FileAccess.file_exists(path):
		var file := FileAccess.open(path, FileAccess.READ)
		if file:
			var json_text := file.get_as_text()
			file.close()
			var json := JSON.new()
			var parse_status := json.parse(json_text)
			if parse_status == OK and typeof(json.data) == TYPE_DICTIONARY:
				parsed = json.data
				success = true
			else:
				push_warning("TextManager: Failed to parse text data JSON %s" % path)
		else:
			push_warning("TextManager: Unable to open text data file %s" % path)
	else:
		push_warning("TextManager: Text data file not found at %s" % path)
	text_data = parsed
	event_counters.clear()
	exhausted_events.clear()
	event_id_exhausted.clear()
	text_data_reloaded.emit(success)
	return success

func reload_text_data() -> bool:
	return load_text_data(last_loaded_path)

func _event_key_from_map(map_name: String) -> String:
	return map_name if not map_name.is_empty() else GLOBAL_MAP_KEY


func trigger_event(event_id: String, context: Dictionary = {}) -> bool:
	if event_id.is_empty():
		return false
	var map_name := _get_current_map_name()
	var lookup := _get_entries_for_event(map_name, event_id)
	var entries: Array = lookup.get("entries", [])
	var event_key: String = lookup.get("event_key", _event_key_from_map(map_name))
	if _is_event_id_exhausted(event_id) or _is_event_exhausted(event_key, event_id):
		return false
	if entries.is_empty():
		if not _is_event_exhausted(event_key, event_id):
			_mark_event_exhausted(event_key, event_id)
		if event_key == GLOBAL_MAP_KEY and not _is_event_id_exhausted(event_id):
			_mark_event_id_exhausted(event_id)
			push_warning("TextManager: No entries for event '%s' on map '%s'" % [event_id, map_name])
			text_missing.emit(event_id, map_name)
		return false
	var index := _get_next_index(event_key, event_id, entries.size())
	if index < 0:
		if not _is_event_exhausted(event_key, event_id):
			_mark_event_exhausted(event_key, event_id)
		if event_key == GLOBAL_MAP_KEY and not _is_event_id_exhausted(event_id):
			_mark_event_id_exhausted(event_id)
			push_warning("TextManager: All entries exhausted for event '%s' on map '%s'" % [event_id, map_name])
			text_missing.emit(event_id, map_name)
		return false
	var raw_entry = entries[index]
	var entry: Dictionary = {}
	if typeof(raw_entry) == TYPE_DICTIONARY:
		entry = raw_entry
	else:
		entry = {
			"text": str(raw_entry)
		}
	var template: String = entry.get("text", "")
	if template.is_empty():
		text_missing.emit(event_id, map_name)
		return false
	var hydrated := _apply_context(template, context)
	var message_type: String = entry.get("type", "info")
	var source: String = entry.get("source", event_id)
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("add_console_message"):
		GameManager.add_console_message(hydrated, message_type, source)
	var context_payload = context.duplicate(true) if typeof(context) == TYPE_DICTIONARY else context
	var payload := {
		"text": hydrated,
		"type": message_type,
		"source": source,
		"map": map_name,
		"event_id": event_id,
		"context": context_payload
	}
	text_triggered.emit(event_id, payload)
	if index >= entries.size() - 1:
		if not _is_event_exhausted(event_key, event_id):
			_mark_event_exhausted(event_key, event_id)
		if event_key == GLOBAL_MAP_KEY and not _is_event_id_exhausted(event_id):
			_mark_event_id_exhausted(event_id)
	return true

func has_event(event_id: String, map_name: String = "") -> bool:
	var lookup := _get_entries_for_event(map_name, event_id)
	var entries: Array = lookup.get("entries", [])
	var event_key: String = lookup.get("event_key", _event_key_from_map(map_name))
	if _is_event_id_exhausted(event_id) or _is_event_exhausted(event_key, event_id):
		return false
	return entries.size() > 0

func get_events_for_map(map_name: String = "") -> Array:
	var names: Array[String] = []
	var payload := _get_map_payload(map_name)
	for key in payload.keys():
		names.append(str(key))
	names.sort()
	return names

func _get_current_map_name() -> String:
	if typeof(GameManager) != TYPE_NIL and GameManager.has_method("get_current_map"):
		var map_name = GameManager.get_current_map()
		return str(map_name)
	return ""

func _get_entries_for_event(map_name: String, event_id: String) -> Dictionary:
	var result := {
		"entries": [],
		"event_key": _event_key_from_map(map_name)
	}
	if not map_name.is_empty() and text_data.has(map_name):
		var candidate = text_data[map_name]
		if typeof(candidate) == TYPE_DICTIONARY:
			var map_payload: Dictionary = candidate
			if map_payload.has(event_id):
				var entries_variant = map_payload[event_id]
				if typeof(entries_variant) == TYPE_ARRAY:
					result["entries"] = entries_variant
					result["event_key"] = map_name
					return result
	if text_data.has(GLOBAL_MAP_KEY):
		var fallback_candidate = text_data[GLOBAL_MAP_KEY]
		if typeof(fallback_candidate) == TYPE_DICTIONARY:
			var global_payload: Dictionary = fallback_candidate
			result["event_key"] = GLOBAL_MAP_KEY
			if global_payload.has(event_id):
				var fallback_entries = global_payload[event_id]
				if typeof(fallback_entries) == TYPE_ARRAY:
					result["entries"] = fallback_entries
	return result

func _get_map_payload(map_name: String) -> Dictionary:
	if not map_name.is_empty() and text_data.has(map_name):
		var map_payload_variant = text_data[map_name]
		if typeof(map_payload_variant) == TYPE_DICTIONARY:
			return map_payload_variant
	var fallback_payload: Dictionary = {}
	if text_data.has(GLOBAL_MAP_KEY):
		var candidate = text_data[GLOBAL_MAP_KEY]
		if typeof(candidate) == TYPE_DICTIONARY:
			fallback_payload = candidate
	return fallback_payload

func _get_next_index(event_key: String, event_id: String, total: int) -> int:
	if total <= 0:
		return -1
	var key := event_key if not event_key.is_empty() else GLOBAL_MAP_KEY
	if not event_counters.has(key):
		event_counters[key] = {}
	var map_events: Dictionary = event_counters[key]
	var next_index: int = map_events.get(event_id, 0)
	if next_index >= total:
		return -1
	map_events[event_id] = next_index + 1
	event_counters[key] = map_events
	return next_index

func _apply_context(template: String, context: Dictionary) -> String:
	var result := template
	for key in context.keys():
		var placeholder := "{" + str(key) + "}"
		result = result.replace(placeholder, str(context[key]))
	return result

func _is_event_exhausted(event_key: String, event_id: String) -> bool:
	var key := event_key if not event_key.is_empty() else GLOBAL_MAP_KEY
	if not exhausted_events.has(key):
		return false
	var map_events: Dictionary = exhausted_events[key]
	return map_events.get(event_id, false)

func _mark_event_exhausted(event_key: String, event_id: String) -> void:
	var key := event_key if not event_key.is_empty() else GLOBAL_MAP_KEY
	if not exhausted_events.has(key):
		exhausted_events[key] = {}
	var map_events: Dictionary = exhausted_events[key]
	map_events[event_id] = true
	exhausted_events[key] = map_events

func _is_event_id_exhausted(event_id: String) -> bool:
	return event_id_exhausted.get(event_id, false)

func _mark_event_id_exhausted(event_id: String) -> void:
	event_id_exhausted[event_id] = true

func _on_current_map_changed(map_name: String) -> void:
	var key := _event_key_from_map(map_name)
	if event_counters.has(key):
		event_counters.erase(key)
	if exhausted_events.has(key):
		exhausted_events.erase(key)
