extends Node3D

@export var log_file := "res://sketchbook.json"

var entries: Array = []   # the log: one dictionary for each chapter, with "f" added
var ranked: Array = []    # the same entries, the most wrong first

func _ready() -> void:
	entries = read_log(log_file)
	ranked = entries.duplicate()
	ranked.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return a["f"] > b["f"])
	if not ranked.is_empty():
		print("%d chapters; most wrong: %s, F = %.2f" % [entries.size(), ranked[0]["chapter"], ranked[0]["f"]])

## The entries of the log, each with its F: how far the prediction was from the observation.
func read_log(path: String) -> Array:
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("entries") is Array:
		print("no log to read at ", path)
		return []
	var out: Array = []
	for entry: Dictionary in data["entries"]:
		entry["f"] = absf(entry["predicted"] - entry["observed"])
		out.append(entry)
	return out
