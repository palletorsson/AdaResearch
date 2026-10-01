extends Node3D
## The guest of the QFEP laboratory: a prediction log as a body.
## It reads sketchbook.json from its own folder and stands one plate for each
## chapter of the log, side by side. A plate's height is that chapter's F:
## how far the prediction was from the observation. The plate of the largest F
## is 0.3 m high and SECOND; all the others are BODY. Every plate has a
## collider, so a walker steps onto it and a marble rests on it.
## It names nothing outside its folder, writes its colours out, fits a box of
## 1.6 m, stands on the ground at its own origin and declares no class_name.
## To make it yours: put your own log in the sketchbook.json beside this file.

const BODY := Color("c6ff3d")     # the kit's colours, written out
const SECOND := Color("22d9ff")
const INK := Color("ffffff")
const SHADE := Color("0d0620")
const WIDTH := 1.5      # metres: the whole curve, however many chapters it has
const DEPTH := 0.6
const BASE := 0.03      # metres: the height of a plate whose F is 0
const HIGHEST := 0.3    # metres: the plate of the largest F; the walker steps up 0.35

@export var log_file := ""   # empty: the sketchbook.json in this folder

var entries: Array = []      # the log, each entry with its "f"
var most_wrong := {}         # the entry with the largest F; empty when there is no log

func _ready() -> void:
	var path := log_file
	if path == "":
		path = (get_script() as Script).resource_path.get_base_dir() + "/sketchbook.json"
	entries = read_log(path)
	for entry: Dictionary in entries:
		if most_wrong.is_empty() or entry["f"] > most_wrong["f"]:
			most_wrong = entry
	if entries.is_empty():
		print("QFEP lab: no log to read at ", path, ": nothing stands here")
		return
	for i in entries.size():
		add_plate(i)
	var label := Label3D.new()
	label.text = "%s  F %.2f" % [most_wrong["chapter"], most_wrong["f"]]
	label.pixel_size = 0.004
	label.font_size = 40
	label.modulate = INK
	label.outline_modulate = SHADE
	label.outline_size = 12
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = Vector3(0.0, HIGHEST + 0.3, 0.0)
	add_child(label)
	print("QFEP lab: %d chapters; most wrong: %s, F = %.2f" % [entries.size(), most_wrong["chapter"], most_wrong["f"]])

func read_log(path: String) -> Array:
	if not FileAccess.file_exists(path):
		return []
	var data = JSON.parse_string(FileAccess.get_file_as_string(path))
	if not data is Dictionary or not data.get("entries") is Array:
		return []
	var out: Array = []
	for entry in data["entries"]:
		if entry is Dictionary and entry.has("chapter") and entry.has("predicted") and entry.has("observed"):
			entry["f"] = absf(float(entry["predicted"]) - float(entry["observed"]))
			out.append(entry)
	return out

func height_of(entry: Dictionary) -> float:
	if most_wrong["f"] <= 0.0:
		return BASE
	return BASE + (HIGHEST - BASE) * entry["f"] / most_wrong["f"]

func add_plate(i: int) -> void:
	var pitch := WIDTH / entries.size()
	var height := height_of(entries[i])
	var box := BoxMesh.new()
	box.size = Vector3(pitch, height, DEPTH)
	var plate := MeshInstance3D.new()
	plate.mesh = box
	var paint := StandardMaterial3D.new()
	paint.albedo_color = SECOND if entries[i] == most_wrong else BODY
	paint.roughness = 0.8
	plate.material_override = paint
	plate.position = Vector3((i - (entries.size() - 1) / 2.0) * pitch, height / 2.0, 0.0)
	add_child(plate)
	var shape := BoxShape3D.new()
	shape.size = box.size
	var collider := CollisionShape3D.new()
	collider.shape = shape
	var body := StaticBody3D.new()
	body.add_child(collider)
	plate.add_child(body)
