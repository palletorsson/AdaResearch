extends SceneTree
## The Prefab Test floor forgets what is placed on it (Palle, 2026-11-23: "when we add an object the objects stay ...
## for now the world should not remember these"). commons/data/inventory/forget.json lists the map; the inventory hand
## (commons/player/inventory_hand.gd, _forgotten) leaves a thing standing there out of placed.json and does not stand
## a row kept there before. A thing on the floor above (Primitives_Prefab_Library, not listed) is kept as always.
##
##   python tools/run_floor_probe.py Primitives_Prefab_Test prefab_test_forgets.gd forgets.json <folder> --no-opening --opera-quiet

var game: Node
var folder := "res://ada_run/prefab_test_forgets"
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var entry := {"check": what, "ok": ok}
	entry.merge(more)
	(result.checks as Array).append(entry)
	return ok


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("forgets.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	# this probe's placed things go in its own folder, fresh each run
	var HandLib = load("res://commons/player/inventory_hand.gd")
	HandLib.keep_default = folder.path_join("placed.json")
	if FileAccess.file_exists(HandLib.keep_default): DirAccess.remove_absolute(HandLib.keep_default)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	game.set_process_unhandled_key_input(false); game.set_process_unhandled_input(false)
	var index := int(game.checkpoint)
	result = {"floor": index, "checks": [], "passed": false}
	for i in 600: await physics_frame
	var hand: Node = get_first_node_in_group("inventory_hands")
	var floors: Array = game.building.content.data.floors
	if not _check("the hand keeps placed things here, in this probe's own file", hand != null and str(hand.get("keep_path")) == HandLib.keep_default and str(floors[index].map) == "Primitives_Prefab_Test", {"keep_path": str(hand.get("keep_path")) if hand != null else "", "map": str(floors[index].map)}):
		_done(); return
	var above := index - 1
	var levels: Array = game.building.spec.levels
	var eye: Vector3 = root.get_camera_3d().global_position
	var here := Transform3D(Basis.IDENTITY, Vector3(eye.x, float(levels[index]) + 0.6, eye.z - 2.0))
	var there := Transform3D(Basis.IDENTITY, Vector3(eye.x, float(levels[above]) + 0.6, eye.z - 2.0))
	var on_this: Node3D = hand.spawn_at(here, "woodenbox")
	var on_above: Node3D = hand.spawn_at(there, "woodenbox")
	for i in 3: await process_frame
	result["floors"] = {"this": [index, str(floors[index].map)], "above": [above, str(floors[above].map)]}
	var rows: Array = hand.kept_rows()
	var heights := rows.map(func(r): return snappedf(float(r.at[1]), 0.01))
	_check("a box placed on the Prefab Test floor is left out of what is kept; one on the floor above is kept",
		on_this != null and on_above != null and rows.size() == 1 and absf(float(rows[0].at[1]) - float(there.origin.y)) < 1.0,
		{"rows": rows.size(), "row_heights": heights, "this_floor_y": snappedf(float(levels[index]), 0.01), "above_floor_y": snappedf(float(levels[above]), 0.01)})
	_check("the box on the Prefab Test floor still stands for the visit", is_instance_valid(on_this) and on_this.is_inside_tree() and (hand.placed as Array).has(on_this))
	hand.save_kept(true)
	var kept: Variant = JSON.parse_string(FileAccess.get_file_as_string(HandLib.keep_default))
	_check("placed.json holds the one from the floor above only", kept is Dictionary and (kept.placed as Array).size() == 1, {"file": ProjectSettings.globalize_path(HandLib.keep_default)})
	# a row kept on this floor before it was forgetful is not stood again by the next game
	var old_row: Dictionary = (kept.placed as Array)[0].duplicate(true)
	old_row.at = [here.origin.x, here.origin.y, here.origin.z]
	var file := FileAccess.open(HandLib.keep_default, FileAccess.WRITE)
	file.store_string(JSON.stringify({"version": 1, "placed": [(kept.placed as Array)[0], old_row]}, "  "))
	file.close()
	var before: int = (hand.placed as Array).size()
	var stood: int = hand.restore_kept()
	_check("restoring a file with a row on each floor stands only the one from the floor above", stood == 1 and (hand.placed as Array).size() == before + 1, {"stood": stood})
	_done()
