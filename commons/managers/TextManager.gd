extends Node
class_name TextManager

const TEXT_DATA_PATH := "res://commons/text/map_texts.json"
const GLOBAL_MAP_KEY := "_global"

var text_data: Dictionary = {}
var event_counters: Dictionary = {}
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
	text_data_reloaded.emit(success)
	return success

func reload_text_data() -> bool:
	return load_text_data(last_loaded_path)

func trigger_event(event_id: String, context: Dictionary = {}) -> bool:
	if event_id.is_empty():
		return false
	var map_name := _get_current_map_name()
	var entries := _get_entries_for_event(map_name, event_id)
	if entries.is_empty():
		push_warning("TextManager: No entries for event '%s' on map '%s'" % [event_id, map_name])
		text_missing.emit(event_id, map_name)
		return false
	var index := _get_next_index(map_name, event_id, entries.size())
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
	return true

func has_event(event_id: String, map_name: String = "") -> bool:
	return not _get_entries_for_event(map_name, event_id).is_empty()

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

func _get_entries_for_event(map_name: String, event_id: String) -> Array:
	var payload := _get_map_payload(map_name)
	if payload.has(event_id):
		var entries = payload[event_id]
		if typeof(entries) == TYPE_ARRAY:
			return entries
	return _get_fallback_entries(event_id)

func _get_map_payload(map_name: String) -> Dictionary:
	if not map_name.is_empty() and text_data.has(map_name):
		var map_payload = text_data[map_name]
		if typeof(map_payload) == TYPE_DICTIONARY:
			return map_payload
	var fallback_payload = text_data.get(GLOBAL_MAP_KEY, {})
	if typeof(fallback_payload) == TYPE_DICTIONARY:
		return fallback_payload
	return {}

func _get_fallback_entries(event_id: String) -> Array:
	var global_payload := text_data.get(GLOBAL_MAP_KEY, {})
	if typeof(global_payload) == TYPE_DICTIONARY and global_payload.has(event_id):
		var entries = global_payload[event_id]
		if typeof(entries) == TYPE_ARRAY:
			return entries
	return []

func _get_next_index(map_name: String, event_id: String, total: int) -> int:
	if total <= 0:
		return 0
	var key := map_name if not map_name.is_empty() else GLOBAL_MAP_KEY
	if not event_counters.has(key):
		event_counters[key] = {}
	var map_events: Dictionary = event_counters[key]
	var next_index: int = map_events.get(event_id, 0)
	map_events[event_id] = (next_index + 1) % total
	event_counters[key] = map_events
	return next_index

func _apply_context(template: String, context: Dictionary) -> String:
	var result := template
	for key in context.keys():
		var placeholder := "{" + str(key) + "}"
		result = result.replace(placeholder, str(context[key]))
	return result

func _on_current_map_changed(map_name: String) -> void:
	var key := map_name if not map_name.is_empty() else GLOBAL_MAP_KEY
	if event_counters.has(key):
		event_counters.erase(key)
