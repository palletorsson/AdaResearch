extends SceneTree
# One-shot headless check for the jspace artifact family: parse the scripts,
# instantiate the scenes, confirm the layout json loads, then write a result
# file (for the watchdog) and quit.

const OUT := "user://jspace_parse_check.json"

func _initialize() -> void:
	var result := {"ok": true, "errors": []}
	for path in [
		"res://commons/artifacts/jspace/jspace_zoom_chamber.tscn",
		"res://commons/artifacts/jspace/jspace_feature_field.tscn",
		"res://commons/artifacts/jspace/jspace_count_plates.tscn",
		"res://commons/artifacts/jspace/jspace_ring.tscn",
		"res://commons/artifacts/museum/museum_hall_shell.tscn",
		"res://commons/artifacts/curator/mode_crown.tscn",
		"res://commons/artifacts/curator/mode_dialogue.tscn",
		"res://commons/artifacts/curator/mode_witness_wall.tscn",
		"res://commons/artifacts/exhibits/exhibit_podium.tscn",
		"res://commons/artifacts/exhibits/exhibit_vitrine.tscn",
	]:
		var scene = load(path)
		if scene == null:
			result["ok"] = false
			result["errors"].append("load failed: %s" % path)
			continue
		var inst = scene.instantiate()
		if inst == null:
			result["ok"] = false
			result["errors"].append("instantiate failed: %s" % path)
			continue
		if inst.get_script() == null:
			result["ok"] = false
			result["errors"].append("SCRIPT FAILED TO COMPILE: %s" % path)
		root.add_child(inst)   # runs _ready — builds visuals headless
		result["children_%s" % path.get_file()] = inst.get_child_count()
		print("OK  %s  (%d children after _ready)" % [path, inst.get_child_count()])
	var f := FileAccess.open("res://commons/artifacts/jspace/jspace_layout.json", FileAccess.READ)
	if f == null or not (JSON.parse_string(f.get_as_text()) is Dictionary):
		result["ok"] = false
		result["errors"].append("layout json unreadable")
	else:
		print("OK  jspace_layout.json")
	var out := FileAccess.open(OUT, FileAccess.WRITE)
	out.store_string(JSON.stringify(result))
	out.close()
	print("RESULT: %s" % JSON.stringify(result))
	quit(0 if result["ok"] else 1)
