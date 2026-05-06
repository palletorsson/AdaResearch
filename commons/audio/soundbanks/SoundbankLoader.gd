# SoundbankLoader.gd
# Loads and provides access to genre-specific soundbanks
#
# Each genre has its own folder with:
# - brief.json: metadata, identity, forbidden elements, sections
# - Individual sound scripts: kick.gd, snare.gd, bass.gd, pad.gd, etc.
#
# This ensures complete isolation between genres - no contamination possible.

class_name SoundbankLoader
extends RefCounted

const SOUNDBANK_PATH = "res://commons/audio/soundbanks/"

var _genre_id: String
var _brief: Dictionary
var _sounds: Dictionary = {}


static func load_genre(genre_id: String) -> SoundbankLoader:
	var loader = SoundbankLoader.new()
	loader._genre_id = genre_id
	loader._load_brief()
	loader._load_sounds()
	return loader


func _load_brief() -> void:
	var brief_path = SOUNDBANK_PATH + _genre_id + "/brief.json"
	var file = FileAccess.open(brief_path, FileAccess.READ)
	if file:
		var json = JSON.new()
		var err = json.parse(file.get_as_text())
		if err == OK:
			_brief = json.data
		else:
			push_error("SoundbankLoader: Failed to parse brief.json for " + _genre_id)
			_brief = {}
		file.close()
	else:
		push_error("SoundbankLoader: Could not open brief.json for " + _genre_id)
		_brief = {}


func _load_sounds() -> void:
	if not _brief.has("soundbank"):
		push_error("SoundbankLoader: No soundbank defined in brief for " + _genre_id)
		return
	
	for sound_name in _brief.soundbank:
		var script_path = SOUNDBANK_PATH + _genre_id + "/" + sound_name + ".gd"
		if ResourceLoader.exists(script_path):
			var script = load(script_path)
			_sounds[sound_name] = script
		else:
			push_warning("SoundbankLoader: Sound '%s' not found for %s" % [sound_name, _genre_id])


# --- Accessors ---

func get_genre_id() -> String:
	return _genre_id


func get_brief() -> Dictionary:
	return _brief


func get_brief_meta() -> Dictionary:
	return _brief.get("meta", {})


func get_identity() -> Dictionary:
	return _brief.get("identity", {})


func get_bpm() -> float:
	var meta = get_brief_meta()
	if meta.has("bpm") and meta.bpm is Dictionary:
		return meta.bpm.get("typical", 120.0)
	return 120.0


func get_forbidden() -> Array:
	return _brief.get("forbidden", [])


func get_sections() -> Dictionary:
	return _brief.get("sections", {})


func get_section_sounds(section_name: String) -> Array:
	var sections = get_sections()
	return sections.get(section_name, [])


# --- Sound Access ---

func has_sound(sound_name: String) -> bool:
	return _sounds.has(sound_name)


func get_sound_script(sound_name: String):
	if not _sounds.has(sound_name):
		push_error("SoundbankLoader: Sound '%s' not in soundbank for %s" % [sound_name, _genre_id])
		return null
	return _sounds[sound_name]


func get_available_sounds() -> Array:
	return _sounds.keys()


# --- Validation ---

func validate_sound(sound_name: String) -> bool:
	"""Check if a sound is allowed in this genre's soundbank."""
	return _sounds.has(sound_name)


func is_forbidden(element: String) -> bool:
	"""Check if an element is forbidden for this genre."""
	return element in get_forbidden()


func validate_section(section_name: String, requested_sounds: Array) -> Dictionary:
	"""Validate that all requested sounds are allowed for this section."""
	var result = {
		"valid": true,
		"errors": []
	}
	
	var allowed = get_section_sounds(section_name)
	if allowed.is_empty():
		# If section not defined, allow any sound in soundbank
		allowed = get_available_sounds()
	
	for sound in requested_sounds:
		if sound not in _sounds:
			result.valid = false
			result.errors.append("Sound '%s' not in soundbank" % sound)
		elif sound not in allowed:
			result.valid = false
			result.errors.append("Sound '%s' not allowed in section '%s'" % [sound, section_name])
	
	return result


# --- Debug ---

func print_info() -> void:
	print("=== Soundbank: %s ===" % _genre_id)
	print("Identity: %s" % get_identity().get("token", "N/A"))
	print("BPM: %s" % get_bpm())
	print("Sounds: %s" % ", ".join(get_available_sounds()))
	print("Forbidden: %s" % ", ".join(get_forbidden()))
	print("Sections: %s" % ", ".join(get_sections().keys()))
