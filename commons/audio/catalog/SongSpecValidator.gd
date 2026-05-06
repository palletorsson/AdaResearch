# SongSpecValidator.gd
# Runtime validator for song-to-soundbank parity.
# Checks: song references valid soundbank, soundbank has all instruments,
# instruments have generation scripts.

class_name SongSpecValidator
extends RefCounted

const SOUNDBANK_PATH := "res://commons/audio/soundbanks/"
const SONGS_PATH := "res://commons/audio/parameters/songs/"

# Maps song_id (with _sb suffix) to soundbank folder
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

# Maps non-_sb songs to their soundbank (where applicable)
const SONG_TO_BANK := {
	"midnight_metroplex": "detroit_techno",
	"dark_wave_cathedral": "dark_wave",
	"detroit_techno": "detroit_techno",
	"synthwave": "synthwave",
	"burial": "burial",
	"boards_of_canada": "boards_of_canada",
	"kraftwerk": "kraftwerk",
	"rave": "rave",
	"moroder_disco": "moroder_disco",
	"gypsy_woman_house": "gypsy_woman_house",
	"dub_house": "dub_house",
	"nineties_rnb": "nineties_rnb",
	"lofi_house": "emd_house",
	"k_bass": "k_bass",
	"ada_theme": "ada_theme",
	"chromatic_story": "chromatic_story",
}


class ValidationResult:
	var song_id: String
	var valid: bool = true
	var soundbank_id: String = ""
	var errors: Array = []
	var warnings: Array = []
	var instruments_declared: Array = []
	var instruments_found: Array = []
	var instruments_missing: Array = []

	func add_error(msg: String) -> void:
		errors.append(msg)
		valid = false

	func add_warning(msg: String) -> void:
		warnings.append(msg)

	func to_dict() -> Dictionary:
		return {
			"song_id": song_id,
			"valid": valid,
			"soundbank_id": soundbank_id,
			"errors": errors,
			"warnings": warnings,
			"instruments_declared": instruments_declared,
			"instruments_found": instruments_found,
			"instruments_missing": instruments_missing,
		}

	func summary() -> String:
		var status := "PASS" if valid else "FAIL"
		var parts: Array = ["%s: %s" % [song_id, status]]
		if not soundbank_id.is_empty():
			parts.append("  soundbank: %s" % soundbank_id)
		if not instruments_missing.is_empty():
			parts.append("  missing: %s" % ", ".join(instruments_missing))
		for err in errors:
			parts.append("  ERROR: %s" % err)
		for warn in warnings:
			parts.append("  WARN: %s" % warn)
		return "\n".join(parts)


static func validate_song(song_id: String) -> ValidationResult:
	var result := ValidationResult.new()
	result.song_id = song_id

	# Resolve soundbank
	var bank_id := _resolve_soundbank(song_id)
	if bank_id.is_empty():
		result.add_warning("No soundbank mapping (may use direct AudioSynthesizer)")
		return result

	result.soundbank_id = bank_id

	# Check brief.json exists
	var brief_path := SOUNDBANK_PATH + bank_id + "/brief.json"
	if not FileAccess.file_exists(brief_path):
		result.add_error("Soundbank brief.json not found: %s" % brief_path)
		return result

	# Load brief
	var brief := _load_json(brief_path)
	if brief.is_empty():
		result.add_error("Failed to parse brief.json")
		return result

	# Get declared instruments
	var instruments: Array = brief.get("soundbank", [])
	if instruments.is_empty():
		result.add_error("No 'soundbank' array in brief.json")
		return result

	result.instruments_declared = instruments.duplicate()

	# Check each instrument has a .gd script
	for instrument in instruments:
		var script_path := SOUNDBANK_PATH + bank_id + "/" + str(instrument) + ".gd"
		if FileAccess.file_exists(script_path):
			result.instruments_found.append(instrument)
		else:
			result.instruments_missing.append(instrument)

	if not result.instruments_missing.is_empty():
		result.add_error("Missing instrument scripts: %s" % ", ".join(result.instruments_missing))

	return result


static func validate_all_songs() -> Array:
	var results: Array = []
	var song_ids := _list_song_ids()

	for song_id in song_ids:
		results.append(validate_song(song_id))

	return results


static func validate_all_soundbanks() -> Array:
	var results: Array = []
	var bank_ids := _list_soundbank_ids()

	for bank_id in bank_ids:
		results.append(_validate_soundbank(bank_id))

	return results


static func _validate_soundbank(bank_id: String) -> ValidationResult:
	var result := ValidationResult.new()
	result.song_id = "(soundbank) " + bank_id
	result.soundbank_id = bank_id

	var brief_path := SOUNDBANK_PATH + bank_id + "/brief.json"
	if not FileAccess.file_exists(brief_path):
		result.add_error("brief.json not found")
		return result

	var brief := _load_json(brief_path)
	if brief.is_empty():
		result.add_error("Failed to parse brief.json")
		return result

	var instruments: Array = brief.get("soundbank", [])
	if instruments.is_empty():
		result.add_error("No 'soundbank' array in brief.json")
		return result

	result.instruments_declared = instruments.duplicate()

	for instrument in instruments:
		var script_path := SOUNDBANK_PATH + bank_id + "/" + str(instrument) + ".gd"
		if FileAccess.file_exists(script_path):
			result.instruments_found.append(instrument)
		else:
			result.instruments_missing.append(instrument)

	if not result.instruments_missing.is_empty():
		result.add_error("Missing scripts: %s" % ", ".join(result.instruments_missing))

	return result


static func generate_report() -> String:
	var lines: Array = ["=== Song Spec Validation Report ===", ""]

	# Songs
	lines.append("--- Songs ---")
	var song_results := validate_all_songs()
	var pass_count := 0
	var fail_count := 0

	for r in song_results:
		var result: ValidationResult = r
		lines.append(result.summary())
		if result.valid:
			pass_count += 1
		else:
			fail_count += 1

	lines.append("")
	lines.append("Songs: %d PASS, %d FAIL" % [pass_count, fail_count])

	# Soundbanks
	lines.append("")
	lines.append("--- Soundbanks ---")
	var bank_results := validate_all_soundbanks()
	var bank_pass := 0
	var bank_fail := 0

	for r in bank_results:
		var result: ValidationResult = r
		lines.append(result.summary())
		if result.valid:
			bank_pass += 1
		else:
			bank_fail += 1

	lines.append("")
	lines.append("Soundbanks: %d PASS, %d FAIL" % [bank_pass, bank_fail])

	return "\n".join(lines)


static func _resolve_soundbank(song_id: String) -> String:
	# Check _sb suffix mapping
	if song_id.ends_with("_sb"):
		return str(SOUNDBANK_MAP.get(song_id, ""))

	# Check direct song mapping
	if SONG_TO_BANK.has(song_id):
		return str(SONG_TO_BANK.get(song_id, ""))

	# Check if song_id matches a soundbank folder directly
	var bank_path := SOUNDBANK_PATH + song_id + "/brief.json"
	if FileAccess.file_exists(bank_path):
		return song_id

	return ""


static func _list_song_ids() -> Array:
	var ids: Array = []
	var dir := DirAccess.open(SONGS_PATH)
	if dir == null:
		return ids

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if not dir.current_is_dir() and entry.ends_with(".json"):
			ids.append(entry.get_basename())
		entry = dir.get_next()
	dir.list_dir_end()

	ids.sort()
	return ids


static func _list_soundbank_ids() -> Array:
	var ids: Array = []
	var dir := DirAccess.open(SOUNDBANK_PATH)
	if dir == null:
		return ids

	dir.list_dir_begin()
	var entry := dir.get_next()
	while not entry.is_empty():
		if dir.current_is_dir() and not entry.begins_with("."):
			var brief_path := SOUNDBANK_PATH + entry + "/brief.json"
			if FileAccess.file_exists(brief_path):
				ids.append(entry)
		entry = dir.get_next()
	dir.list_dir_end()

	ids.sort()
	return ids


static func _load_json(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		return {}
	var text := file.get_as_text()
	file.close()
	var parsed = JSON.parse_string(text)
	if parsed is Dictionary:
		return parsed
	return {}
