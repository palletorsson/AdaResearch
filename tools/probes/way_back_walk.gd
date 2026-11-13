extends SceneTree
## A WAY BACK on its floor (GT_Connectivity; the pass, 2026-11-13)
## Three places a metre apart in height, built from the spatial lab's prefabs: a wedge is walked both ways, a drop one
## way. Read in the running tower with its own walker, against the bench (tools/probes/way_back_bench.py):
##   split  two groups, FLOOR + ONE and TWO + THREE, and the work is built from the lab's prefabs;
##          the body goes up the ramp to ONE and down again (there and back);
##          it drops from ONE to TWO and cannot return; it walks the wedge to THREE and back (there and back);
##          the court of THREE holds it in;
##   total  standing still on the plate in TWO builds the return: up the wedge to ONE, down the ramp to the floor;
##   none   from TWO a drop into THREE and no way back, three groups; standing on the plate in THREE builds the way up.
##
##   godot --path <stage> --script res://tools/probes/way_back_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## way.json: checks with what was read. arrival.png, above.png, two.png, total.png.
const ID := "way-back"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


## Walk toward a point given in the work's own frame (x east, z south); y is ignored.
func _go(x: float, z: float, ticks_max: int = 600, speed: float = 0.34) -> void:
	var target: Vector3 = work.to_global(Vector3(x, 0, z))
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.12: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 24: await physics_frame


func _at() -> Array:
	var here: Vector3 = work.to_local(body.global_position)
	return [snappedf(here.x, .01), snappedf(here.y, .01), snappedf(here.z, .01), str(work.state().place)]


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
	if work != null and work.has_method("groups"):
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
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
		var s: Dictionary = work.state()
		var prefabs := 0
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"):
				prefabs += 1
				kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "split: two groups, FLOOR + ONE and TWO + THREE, and the work is built from the lab's prefabs", "ok": str(s.mutuality) == "split" and s.groups == [["FLOOR", "ONE"], ["TWO", "THREE"]] and prefabs >= 45 and kinds.size() >= 5,
			"groups": s.groups, "prefabs_in_the_tree": prefabs, "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 1.0, 0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(-6.5, 5.0, 9.5), at + Vector3(0.5, 0.6, -0.5), folder.path_join("above.png"))
		# FLOOR and ONE: there and back
		game.place_player(work.to_global(Vector3(-3.0, 0.3, 6.4)))
		for i in 40: await physics_frame
		await _go(-3.0, 1.9)
		await _go(-3.0, 0.0)
		var on_one := _at()
		await _go(-3.0, 1.9)
		await _go(-3.0, 6.4)
		var on_floor := _at()
		checks.append({"check": "the body goes up the ramp to ONE and down again: there and back", "ok": absf(float(on_one[1]) - 2.0) < 0.15 and str(on_one[3]) == "ONE" and absf(float(on_floor[1])) < 0.15 and str(on_floor[3]) == "FLOOR",
			"on_one": on_one, "back_on_the_floor": on_floor})
		# ONE -> TWO, and no return
		await _go(-3.0, 1.9)
		await _go(-3.0, 0.0)
		await _go(0.0, 0.0)
		var on_two := _at()
		await _shot(cam, body.global_position + Vector3(0.6, 1.6, 0.8), work.to_global(Vector3(-3.0, 2.2, 0.0)), folder.path_join("two.png"))
		await _go(-3.0, 0.0, 300, 0.5)
		var tried := _at()
		checks.append({"check": "it drops from ONE to TWO, and walking back at ONE it stays in TWO: no way back", "ok": absf(float(on_two[1]) - 1.0) < 0.15 and str(on_two[3]) == "TWO" and float(tried[0]) > -1.5 and absf(float(tried[1]) - 1.0) < 0.15 and str(tried[3]) == "TWO",
			"on_two": on_two, "after_trying": tried})
		# TWO and THREE: there and back by the wedge
		await _go(1.2, -1.0)
		await _go(3.8, -1.0)
		await _go(3.0, 0.5)
		var on_three := _at()
		await _go(6.5, -0.1, 300, 0.5)
		var held := _at()
		await _go(3.9, -0.1)
		await _go(3.8, -1.0)
		await _go(1.0, -1.0)
		var up_again := _at()
		checks.append({"check": "it walks the wedge down to THREE and up again: there and back; the court of THREE holds it in", "ok": absf(float(on_three[1])) < 0.15 and str(on_three[3]) == "THREE" and float(held[0]) < 4.5 and absf(float(held[1])) < 0.15
			and absf(float(up_again[1]) - 1.0) < 0.15 and str(up_again[3]) == "TWO", "on_three": on_three, "walking_out_of_the_court": held, "up_again": up_again})
		# the plate in TWO builds the return
		await _go(0.95, 0.95)
		for i in 90: await physics_frame
		var t: Dictionary = work.state()
		await _go(0.8, 1.0)
		await _go(-2.6, 1.0)
		var returned := _at()
		await _shot(cam, at + Vector3(-6.5, 5.0, 9.5), at + Vector3(0.5, 0.6, -0.5), folder.path_join("total.png"))
		await _go(-3.0, 1.2)
		await _go(-3.0, 6.4)
		var out := _at()
		checks.append({"check": "total: standing still on the plate in TWO builds the return - one group; the body walks up to ONE and down the ramp to the floor", "ok": str(t.mutuality) == "total" and bool(t.return_stands) and (t.groups as Array).size() == 1
			and absf(float(returned[1]) - 2.0) < 0.15 and str(returned[3]) == "ONE" and absf(float(out[1])) < 0.15 and str(out[3]) == "FLOOR", "groups": t.groups, "on_one_again": returned, "out": out})
		# none
		work.apply_grid_config({"mutuality": "none"})
		game.place_player(work.to_global(Vector3(0.0, 1.3, 0.5)))
		for i in 60: await physics_frame
		var n0: Dictionary = work.state()
		await _go(3.0, 0.5)
		var dropped := _at()
		await _go(0.0, 0.5, 300, 0.5)
		var stuck := _at()
		await _go(3.5, 0.6)
		for i in 90: await physics_frame
		var n1: Dictionary = work.state()
		await _go(3.8, -1.0)
		await _go(1.0, -1.0)
		var climbed := _at()
		checks.append({"check": "none: three groups; a drop from TWO into THREE and no way back; standing still on the plate in THREE builds the way up, and the body walks it", "ok": n0.groups == [["FLOOR", "ONE"], ["TWO"], ["THREE"]] and not bool(n0.way_up_stands)
			and absf(float(dropped[1])) < 0.15 and str(dropped[3]) == "THREE" and float(stuck[0]) > 1.5 and str(stuck[3]) == "THREE" and str(n1.mutuality) == "split" and bool(n1.way_up_stands)
			and absf(float(climbed[1]) - 1.0) < 0.15 and str(climbed[3]) == "TWO", "groups": n0.groups, "dropped": dropped, "after_trying": stuck, "after_the_plate": [str(n1.mutuality), bool(n1.way_up_stands)], "climbed": climbed})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("way.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[way_back_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
