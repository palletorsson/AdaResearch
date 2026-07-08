extends SceneTree
# One-shot: load Museum_Spine_Court through the real catalog path and write
# the list of spawned interactable nodes to a json — did the shell spawn?

const MAP_CATALOG_SCENE := "res://commons/maps/catalog/MapCatalogDesktop3D.tscn"
const OUT := "user://museum_spawn_probe.json"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var err: int = change_scene_to_file(MAP_CATALOG_SCENE)
	if err != OK:
		_finish({"ok": false, "error": "catalog scene load failed"})
		return
	await process_frame
	await process_frame
	var catalog: Node = current_scene
	var ok: bool = bool(catalog.call("load_map_fresh", "Museum_Wings"))
	if not ok:
		_finish({"ok": false, "error": "load_map_fresh false"})
		return
	# give generation time
	for _i in 90:
		await process_frame
	# find every node whose name hints at our cast
	var names: Array = []
	_collect(root, names)
	var hits: Array = []
	for n in names:
		var low := String(n).to_lower()
		for want in ["museum", "incompleteness", "galton", "pompeii", "menger",
				"koch", "cantor", "pendulum", "spring", "petri", "gravity",
				"cradle", "shell"]:
			if low.contains(want):
				hits.append(n)
				break
	# inspect the shell itself
	var segs := root.find_child("WallSegments", true, false)
	var shell := root.find_child("MuseumHallShell", true, false)
	var shell_info := {}
	if shell:
		shell_info = {
			"children": shell.get_child_count(),
			"visible": shell.visible,
			"pos": str(shell.global_position),
			"scale": str(shell.scale),
			"script": str(shell.get_script()),
			"first_children": [],
		}
		for i in mini(4, shell.get_child_count()):
			shell_info["first_children"].append(shell.get_child(i).name)
	_finish({"ok": true, "total_nodes": names.size(), "cast_hits": hits,
			"shell": shell_info,
			"wall_segments": segs.get_child_count() if segs else -1})

func _collect(n: Node, out: Array) -> void:
	out.append(n.name)
	for c in n.get_children():
		_collect(c, out)

func _finish(result: Dictionary) -> void:
	var f := FileAccess.open(OUT, FileAccess.WRITE)
	f.store_string(JSON.stringify(result, " "))
	f.close()
	print("RESULT ", JSON.stringify(result))
	quit(0)
