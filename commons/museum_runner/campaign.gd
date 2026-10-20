extends RefCounted
## Runner checkpoints only. Museum/tutorial progression is a separate save.
const IDS := ["point_line", "face_body", "transformation", "array_colour"]
const MAPS := [preload("maps/point_line.tscn"), preload("maps/face_body.tscn"),
	preload("maps/transformation.tscn"), preload("maps/array_colour.tscn")]
var next_level := 0
var banked_score := 0
var best := 0

func restore(path: String) -> void:
	next_level = 0
	banked_score = 0
	best = 0
	var config := ConfigFile.new()
	if config.load(path) != OK: return
	# Existing best-only saves migrate without inventing completed levels.
	var old_best: Variant = config.get_value("runner", "best", 0)
	if (old_best is int or old_best is float) and is_finite(float(old_best)):
		best = clampi(int(old_best), 0, 100000000)
	if config.get_value("journey", "version", 0) != 1: return
	var map_id: Variant = config.get_value("journey", "next_map", "")
	var saved_score: Variant = config.get_value("journey", "score", 0)
	if not map_id is String or not saved_score is int or saved_score < 0 or saved_score > 100000000: return
	var index := IDS.size() if map_id == "complete" else IDS.find(map_id)
	if index < 0: return
	next_level = index
	banked_score = saved_score

## Write a temporary file, then replace the checkpoint. Memory advances only on success.
func store(path: String, next: int, earned: int, record: int) -> Error:
	if next < 0 or next > IDS.size() or earned < 0: return ERR_INVALID_PARAMETER
	var config := ConfigFile.new()
	config.set_value("runner", "best", maxi(best, record))
	config.set_value("journey", "version", 1)
	config.set_value("journey", "next_map", "complete" if next == IDS.size() else IDS[next])
	config.set_value("journey", "score", earned)
	var absolute := ProjectSettings.globalize_path(path)
	var error := DirAccess.make_dir_recursive_absolute(absolute.get_base_dir())
	if error != OK: return error
	error = config.save(path + ".tmp")
	if error != OK: return error
	error = DirAccess.rename_absolute(absolute + ".tmp", absolute)
	if error != OK: return error
	next_level = next
	banked_score = earned
	best = maxi(best, record)
	return OK
