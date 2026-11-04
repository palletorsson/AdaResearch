extends "res://tools/probes/void_game_probe.gd"
## Survey (2026-11-04): the Primitives_Columns hall's editor parts (lines_area part_defaults) with their positions -
## the names an only_parts config must keep. Writes <out>/parts.json.
const FLOOR := 9

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible()
	game.body.scripted_input = true
	await frames(150)
	var mount: Node3D = game.building.content.exhibits.get("%d/hall" % FLOOR)
	var hall: Node = mount.get_node("Artifact") if mount else null
	var parts: Dictionary = hall.get("part_defaults") if hall else {}
	FileAccess.open(out.path_join("parts.json"), FileAccess.WRITE).store_string(JSON.stringify(parts, "  "))
	print("[columns_parts] %d parts" % parts.size())
	quit(0)
