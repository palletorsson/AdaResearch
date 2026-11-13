extends SceneTree
## MAKING ROOM on its floor (GT_Matching; the pass, 2026-11-13)
## The hall's workshop at the size of a body: the body is the maker who waits. Read in the running tower with its
## own walker, against the bench (tools/probes/making_room_bench.py):
##   built from the tower's prefabs (counter walls, salvaged chairs, pyramid-and-ball makers); the hall model's
##   greedy has A at the drill, B at the saw, C at the plane, the lathe unused, and its alternating path from the
##   visitor runs drill, A, saw, B, plane, C, lathe;
##   the drill is taken: maker A holds a body off its bench;
##   the body stands still on ASK: the question goes down the row and the moves come back - C to the lathe, B to the
##   plane, A to the saw;
##   the body steps up to the drill: four are working;
##   without the lathe the question goes down the row and nobody moves: three of four, whatever is rearranged.
##
##   godot --path <stage> --script res://tools/probes/making_room_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## workshop.json: checks with what was read. arrival.png, first.png, asking.png, four.png, short.png.
const ID := "making-room"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 900, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 14: await physics_frame


func _stand_at(figures: Array, xs: Array) -> bool:
	for i in xs.size():
		if absf(float(figures[i][0]) - float(xs[i])) > 0.03 or absf(float(figures[i][1]) + 2.7) > 0.03: return false
	return true


func _until_settled(ticks_max: int = 1500) -> void:
	for i in ticks_max:
		if not bool(work.state().busy) and i > 80: break
		await physics_frame
	for i in 30: await physics_frame


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("ask_point"):
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var up := Vector3(0, 0.3, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		var over := at + Vector3(0.6, 4.6, 8.2)
		var middle := at + Vector3(0.0, 0.2, -1.2)
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "built from the tower's prefabs; the hall model's greedy has A at the drill, B at the saw, C at the plane, and its alternating path from the visitor runs drill, A, saw, B, plane, C, lathe",
			"ok": Array(s.pairs) == ["A-drill", "B-saw", "C-plane"] and int(s.working) == 3 and Array(s.path) == [3, 4, 0, 5, 1, 6, 2, 7]
				and int(kinds.get("counter_wall", 0)) == 4 and int(kinds.get("salvage_chair", 0)) == 4 and int(kinds.get("traffic_pyramid_5", 0)) == 3 and int(kinds.get("trace_point_ball", 0)) == 3,
			"pairs": s.pairs, "working": int(s.working), "path": s.path, "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.6, -1.0), folder.path_join("arrival.png"))
		await _shot(cam, over, middle, folder.path_join("first.png"))
		# the drill is taken
		game.place_player(work.your_chair() + up)
		for i in 40: await physics_frame
		await _go(work.drill_mat(), 500, 0.5)
		var held: Vector3 = work.to_local(body.global_position)
		checks.append({"check": "the drill is taken: maker A holds a body off its bench", "ok": held.z > -2.3 and not bool(work.state().at_drill), "stopped_at_z": snappedf(held.z, .01), "the_bench_place_is_at_z": -2.7})
		# ask
		await _go(work.ask_point())
		for i in 150: await physics_frame
		var during: Dictionary = work.state()
		await _shot(cam, body.global_position + Vector3(2.6, 1.5, 2.6), work.to_global(Vector3(-1.0, 0.9, -2.7)), folder.path_join("asking.png"))
		await _until_settled()
		var a: Dictionary = work.state()
		checks.append({"check": "the body stands still on ASK: the question goes down the row and the moves come back - C to the lathe, B to the plane, A to the saw", "ok": bool(during.busy) and int(a.asks) == 1
			and Array(a.asked) == ["A", "B", "C"] and Array(a.pairs) == ["A-saw", "B-plane", "C-lathe", "YOU-drill"] and _stand_at(a.figures, [-1.5, 1.5, 4.5]) and not bool(a.refused),
			"asked": a.asked, "pairs": a.pairs, "figures": a.figures, "asks": int(a.asks)})
		# the drill
		await _go(work.drill_mat())
		var four: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("four.png"))
		checks.append({"check": "the body steps up to the drill: four are working, and no new tool arrived", "ok": bool(four.at_drill) and int(four.working) == 4 and int(four.tools) == 4, "working": int(four.working), "tools": int(four.tools)})
		# without the lathe
		await _go(work.your_chair())
		work.apply_grid_config({"arrangement": "short"})
		for i in 20: await physics_frame
		var before: Dictionary = work.state()
		await _go(work.ask_point())
		await _until_settled()
		var after: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("short.png"))
		checks.append({"check": "without the lathe the question goes down the row and nobody moves: three of four, whatever is rearranged", "ok": int(before.tools) == 3 and Array(before.path).is_empty()
			and Array(after.asked) == ["A", "B", "C"] and bool(after.refused) and Array(after.pairs) == ["A-drill", "B-saw", "C-plane"] and int(after.working) == 3 and int(after.asks) == 2,
			"asked": after.asked, "pairs": after.pairs, "working": int(after.working), "refused": bool(after.refused)})
		work.apply_grid_config({"arrangement": "first"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("workshop.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[making_room_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
