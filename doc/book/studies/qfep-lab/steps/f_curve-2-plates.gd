extends Node3D

const Look := preload("res://supplied/look.gd")
const Segment := preload("res://supplied/segment.gd")

const STEP := 0.4    # metres from one chapter's plate to the next
const BASE := 0.05   # metres: the height of a plate whose F is 0

@export var log_file := "res://sketchbook.json"
@export var rise := 0.03   # metres of height for one point of F

var entries: Array = []   # the log: one dictionary for each chapter, with "f" added
var ranked: Array = []    # the same entries, the most wrong first

func _ready() -> void:
	entries = read_log(log_file)
	for i in entries.size():
		add_plate(i)
		if i > 0:
			var line: MeshInstance3D = Segment.new()
			add_child(line)
			line.show_between(top_of(i - 1), top_of(i))
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

## The middle of the top of plate i: where the line passes and a body stands.
func top_of(i: int) -> Vector3:
	return Vector3((i - (entries.size() - 1) / 2.0) * STEP, BASE + rise * entries[i]["f"], 0.0)

func add_plate(i: int) -> void:
	var top := top_of(i)
	var box := BoxMesh.new()
	box.size = Vector3(STEP, top.y, 0.8)
	var plate := MeshInstance3D.new()
	plate.mesh = box
	plate.material_override = Look.paint(Look.BODY)
	plate.position = Vector3(top.x, top.y / 2.0, 0.0)
	add_child(plate)
	plate.create_convex_collision()   # a body of its own: the walker stands on it
	var label := Look.label("%s  %.2f" % [entries[i]["chapter"], entries[i]["f"]])
	label.font_size = 28
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT
	label.rotation = Vector3(-PI / 2.0, -PI / 3.0, 0.0)   # flat on the floor, slanted like the names under a chart
	label.position = Vector3(top.x - 0.1, 0.01, 0.5)
	add_child(label)
