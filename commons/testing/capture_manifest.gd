## Manifest-based skip engine for the capture pipeline.
## Hashes INPUT files (.gd + .tscn source) to determine if re-capture is needed.
## If source hasn't changed since last capture AND output PNGs exist → skip.
##
## Usage (from capture_all.gd or any GDScript):
##   var manifest := CaptureManifest.load_manifest("user://capture_manifest.json")
##   var hash := CaptureManifest.compute_file_hash(["res://path/to.gd", "res://path/to.tscn"])
##   if CaptureManifest.should_capture(manifest, "my_artifact", hash, ["front.png", "left.png"]):
##       # ... do capture ...
##       CaptureManifest.update_entry(manifest, "my_artifact", hash, sources, angles, "ok")
##   CaptureManifest.save_manifest("user://capture_manifest.json", manifest)

class_name CaptureManifest

const MANIFEST_VERSION := 2


## Load manifest from disk, or return a fresh empty one.
static func load_manifest(path: String) -> Dictionary:
	var absolute_path: String = ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
	if not FileAccess.file_exists(absolute_path) and not FileAccess.file_exists(path):
		return _empty_manifest()

	var file: FileAccess = FileAccess.open(path, FileAccess.READ)
	if file == null:
		file = FileAccess.open(absolute_path, FileAccess.READ)
	if file == null:
		return _empty_manifest()

	var json_text: String = file.get_as_text()
	file.close()

	var json := JSON.new()
	if json.parse(json_text) != OK:
		push_warning("CaptureManifest: Failed to parse manifest, starting fresh")
		return _empty_manifest()

	var data: Dictionary = json.data if json.data is Dictionary else {}
	if data.get("version", 0) != MANIFEST_VERSION:
		push_warning("CaptureManifest: Version mismatch (got %s, want %d), starting fresh" % [
			str(data.get("version", "?")), MANIFEST_VERSION
		])
		return _empty_manifest()

	# Ensure entries dict exists
	if not data.has("entries") or not data["entries"] is Dictionary:
		data["entries"] = {}

	return data


## Save manifest to disk as formatted JSON.
static func save_manifest(path: String, manifest: Dictionary) -> void:
	manifest["timestamp"] = Time.get_datetime_string_from_system(true)
	manifest["version"] = MANIFEST_VERSION

	var absolute_path: String = ProjectSettings.globalize_path(path) if path.begins_with("user://") or path.begins_with("res://") else path
	var dir_path: String = absolute_path.get_base_dir()
	if not DirAccess.dir_exists_absolute(dir_path):
		DirAccess.make_dir_recursive_absolute(dir_path)

	var file: FileAccess = FileAccess.open(absolute_path, FileAccess.WRITE)
	if file == null:
		push_error("CaptureManifest: Cannot write manifest to %s" % absolute_path)
		return

	file.store_string(JSON.stringify(manifest, "\t"))
	file.close()


## Compute SHA-256 hash of the concatenated contents of the given file paths.
## Paths should be res:// paths — they'll be read via FileAccess.
## Returns "sha256:<hex>" or "error" on failure.
static func compute_file_hash(paths: Array) -> String:
	var ctx := HashingContext.new()
	if ctx.start(HashingContext.HASH_SHA256) != OK:
		push_error("CaptureManifest: Failed to start HashingContext")
		return "error"

	var any_read := false
	for raw_path in paths:
		var p: String = str(raw_path).strip_edges()
		if p.is_empty():
			continue
		var file: FileAccess = FileAccess.open(p, FileAccess.READ)
		if file == null:
			# Try globalized path
			var gp: String = ProjectSettings.globalize_path(p)
			file = FileAccess.open(gp, FileAccess.READ)
		if file == null:
			push_warning("CaptureManifest: Cannot read file for hashing: %s" % p)
			continue
		var data: PackedByteArray = file.get_buffer(file.get_length())
		file.close()
		if data.size() > 0:
			ctx.update(data)
			any_read = true

	if not any_read:
		return "error"

	var digest: PackedByteArray = ctx.finish()
	return "sha256:" + digest.hex_encode()


## Determine whether a target needs to be re-captured.
## Returns true if:
##   - Target not in manifest
##   - Hash differs from stored hash
##   - Any expected output file doesn't exist
static func should_capture(manifest: Dictionary, key: String, current_hash: String, expected_files: Array) -> bool:
	if current_hash == "error":
		# Can't compute hash → always capture
		return true

	var entries: Dictionary = manifest.get("entries", {})
	if not entries.has(key):
		return true

	var entry: Dictionary = entries[key]
	var stored_hash: String = str(entry.get("input_hash", ""))
	if stored_hash != current_hash:
		return true

	# Check that all expected output files actually exist on disk
	for file_path in expected_files:
		var fp: String = str(file_path)
		var absolute: String = ProjectSettings.globalize_path(fp) if fp.begins_with("user://") or fp.begins_with("res://") else fp
		if not FileAccess.file_exists(absolute) and not FileAccess.file_exists(fp):
			return true

	return false


## Update (or create) a manifest entry after successful capture.
static func update_entry(manifest: Dictionary, key: String, hash_value: String,
		source_files: Array, angles: Array, status: String) -> void:
	if not manifest.has("entries"):
		manifest["entries"] = {}
	manifest["entries"][key] = {
		"input_hash": hash_value,
		"source_files": source_files,
		"captured_at": Time.get_datetime_string_from_system(true),
		"angles": angles,
		"status": status,
	}


## Remove a manifest entry (e.g., if target was deleted).
static func remove_entry(manifest: Dictionary, key: String) -> void:
	if manifest.has("entries") and manifest["entries"] is Dictionary:
		manifest["entries"].erase(key)


## Return a summary of manifest state: total entries, how many ok/failed.
static func get_summary(manifest: Dictionary) -> Dictionary:
	var entries: Dictionary = manifest.get("entries", {})
	var total: int = entries.size()
	var ok_count: int = 0
	var fail_count: int = 0
	for key in entries:
		var status: String = str(entries[key].get("status", ""))
		if status == "ok":
			ok_count += 1
		elif status == "failed":
			fail_count += 1
	return {
		"total": total,
		"ok": ok_count,
		"failed": fail_count,
		"other": total - ok_count - fail_count,
	}


## Resolve source files for an artifact given its registry entry.
## Returns array of res:// paths for the .tscn and .gd files.
static func resolve_artifact_sources(scene_path: String) -> Array:
	var sources: Array = []
	if scene_path.is_empty():
		return sources

	# The .tscn scene file itself
	sources.append(scene_path)

	# Convention: .gd script lives next to .tscn with the same name
	var gd_path: String = scene_path.get_basename() + ".gd"
	if FileAccess.file_exists(gd_path):
		sources.append(gd_path)
	else:
		# Try finding the .gd in the same directory with any name
		var dir_path: String = scene_path.get_base_dir()
		var dir := DirAccess.open(dir_path)
		if dir:
			dir.list_dir_begin()
			var fname: String = dir.get_next()
			while fname != "":
				if fname.ends_with(".gd") and not fname.begins_with("."):
					sources.append(dir_path.path_join(fname))
				fname = dir.get_next()
			dir.list_dir_end()

	return sources


## Resolve source files for a map given its name.
## Returns array containing the map_data.json path.
static func resolve_map_sources(map_name: String) -> Array:
	var map_data_path: String = "res://commons/maps/%s/map_data.json" % map_name
	if FileAccess.file_exists(map_data_path):
		return [map_data_path]
	return []


# ── Private ──────────────────────────────────────────────────────────────────

static func _empty_manifest() -> Dictionary:
	return {
		"version": MANIFEST_VERSION,
		"timestamp": Time.get_datetime_string_from_system(true),
		"entries": {},
	}
