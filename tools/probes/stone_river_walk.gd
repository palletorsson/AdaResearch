extends SceneTree
## THE ROUTE AFTER A STONE DISAPPEARS on its floor (GT_Pathfinding; the pass, 2026-11-13)
## A river of stepping stones a body crosses while the river takes stones on its way. Read in the running tower with
## its own walker, against the bench (tools/probes/stone_river_bench.py, seed 40):
##   34 stones, and a crossing of seven; built from the tower's prefabs, the lab's and three kinds from the wider
##   catalogue (museum tape barrier, pink triangle sign, work light);
##   water holds a body off where no stone stands;
##   the body walks the way the balls show and stands on the north bank;
##   the river takes a stone on the way back: there is still a way (the bench: seven or nine), and the body walks it home;
##   with three stones down a fourth sinking lets the oldest rise;
##   impatient: with a body standing on a stone, the river takes one by itself within nine seconds.
##
##   godot --path <stage> --script res://tools/probes/stone_river_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## river.json: checks with what was read. arrival.png, above.png, midstream.png, sunk.png.
const ID := "stone-river"
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


func _go(target: Vector3, ticks_max: int = 500, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 14: await physics_frame


## Walk the way the work shows, asking again after every stone (the way may change under the body).
func _follow(steps_max: int = 40) -> void:
	for i in steps_max:
		var points: Array = work.route_points()
		if points.is_empty(): return
		await _go(points[0])
		if int(work.state().node) < 2 and points.size() == 1: return


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
	if work != null and work.has_method("route_points"):
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
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
		work.apply_grid_config({"impatience": "still"})
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "34 stones and a crossing of seven; built from the tower's prefabs, three kinds of them from the wider catalogue", "ok": int(s.stones) == 34 and int(s.stones_on_the_way) == 7
			and kinds.has("museum_tape_barrier") and kinds.has("pink_triangle_sign") and kinds.has("work_light") and int(kinds.get("timber_panel_1x1", 0)) == 34, "stones": int(s.stones), "the_way": int(s.stones_on_the_way), "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.3, 0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(-7.0, 5.0, 8.5), at + Vector3(0.5, 0, -1.0), folder.path_join("above.png"))
		# water holds
		game.place_player(work.to_global(Vector3(-4.5, 0.3, 4.0)))
		for i in 40: await physics_frame
		await _go(work.to_global(Vector3(-4.5, 0, 0.0)), 240, 0.5)
		var held: Vector3 = work.to_local(body.global_position)
		checks.append({"check": "water holds a body off where no stone stands", "ok": held.z > 3.0 and int(work.state().node) == 0, "stopped_at_z": snappedf(held.z, .01), "the_river_begins_at_z": 3.0})
		# across
		var first: Array = work.route_points()
		await _go(work.to_global(Vector3(work.to_local(first[0]).x, 0, 3.8)))
		for i in 4:
			var points: Array = work.route_points()
			await _go(points[0])
		await _shot(cam, body.global_position + Vector3(0, 1.6, 0), at + Vector3(0.0, 0.2, -3.5), folder.path_join("midstream.png"))
		await _follow()
		var north: Dictionary = work.state()
		checks.append({"check": "the body walks the way the balls show and stands on the north bank", "ok": int(north.node) == 1 and int(north.crossings) == 1 and not bool(north.going_north), "node": int(north.node), "crossings": int(north.crossings)})
		# a stone on the way back goes
		var before: int = int(north.stones_on_the_way)
		var took: int = work.sink()
		var after: Dictionary = work.state()
		await _shot(cam, at + Vector3(-7.0, 5.0, 8.5), at + Vector3(0.5, 0, -1.0), folder.path_join("sunk.png"))
		await _follow()
		var home: Dictionary = work.state()
		checks.append({"check": "the river takes a stone on the way back: there is still a way, and the body walks it home", "ok": took >= 0 and (after.down as Array).size() == 1 and int(after.stones_on_the_way) >= before
			and int(home.node) == 0 and int(home.crossings) == 2, "way_before": before, "way_after": int(after.stones_on_the_way), "down": after.down, "home": [int(home.node), int(home.crossings)]})
		# the pool
		for i in 3: work.sink()
		var pool: Dictionary = work.state()
		checks.append({"check": "with three stones down a fourth sinking lets the oldest rise", "ok": (pool.down as Array).size() == 3 and int(pool.sinkings) == 4, "down": pool.down, "sinkings": int(pool.sinkings)})
		# impatient
		work.rise_all()
		work.apply_grid_config({"impatience": "impatient"})
		var again: Array = work.route_points()
		await _go(work.to_global(Vector3(work.to_local(again[0]).x, 0, 3.8)))
		await _go(again[0])
		var was: int = int(work.state().sinkings)
		for i in 560: await physics_frame
		var now: Dictionary = work.state()
		checks.append({"check": "impatient: with a body standing on a stone the river takes one by itself within nine seconds", "ok": int(now.sinkings) > was and int(now.node) >= 2, "sinkings_by_itself": int(now.sinkings) - was, "still_on_a_stone": int(now.node) >= 2})
		work.rise_all()
		work.apply_grid_config({"impatience": "patient"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("river.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[stone_river_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
