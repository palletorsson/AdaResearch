extends SceneTree
## FRESH GROUND on its floor (ML_Evolution; the pass, 2026-11-14)
## The tutorial's eight-by-eight field at the size of a body, the visitor one of the bodies. Read in the running
## tower with its own walker, against the bench (tools/probes/fresh_ground_bench.py):
##   sixty-four timber panels, twelve bodies waiting, the clock stopped until someone steps on;
##   the body steps on: the clock runs, the panels under the body pay the body, bodies are born;
##   finite ground: the floor is eaten, everyone stops, the visitor's energy too, and the field stays bare;
##   the plate for ground that returns begins again with the next seed; a body standing still is paid again by
##   the panel it stands on, and the field carries a full population;
##   barren: nothing is laid; twelve bodies and a visitor last ten seconds.
##
##   godot --path <stage> --script res://tools/probes/fresh_ground_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## field.json: checks with what was read. arrival.png, waiting.png, eaten.png, bare.png, returns.png.
const ID := "fresh-ground"
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


func _until(what: Callable, ticks_max: int) -> void:
	for i in ticks_max:
		if what.call(): break
		await physics_frame


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
	if work != null and work.has_method("cell_point"):
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
		var over := at + Vector3(4.6, 4.9, 7.6)
		var middle := at + Vector3(0.0, 0.0, -0.6)
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "sixty-four timber panels, twelve bodies waiting, the clock stopped until someone steps on", "ok": str(s.ground) == "finite" and not bool(s.running) and int(s.alive) == 12 and int(s.fresh) == 64
			and float(s.clock) == 0.0 and int(kinds.get("timber_panel_1x1", 0)) == 64 and int(kinds.get("trace_point_ball", 0)) == 32 and int(kinds.get("traffic_pyramid_5", 0)) == 4,
			"alive": int(s.alive), "fresh": int(s.fresh), "clock": float(s.clock), "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.2, 0), folder.path_join("arrival.png"))
		await _shot(cam, over, middle, folder.path_join("waiting.png"))
		# onto the field
		game.place_player(work.point_at(Vector3(-0.5, 0.3, 4.7)))
		for i in 40: await physics_frame
		var still_waiting: bool = not bool(work.state().running)
		await _go(work.cell_point(3, 2), 900, 0.5)
		var w: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("eaten.png"))
		checks.append({"check": "the body steps on: the clock runs, the panels under the body pay the body, bodies are born", "ok": still_waiting and bool(w.running) and int(w.me.meals) >= 2 and int(w.born) > 13 and int(w.fresh) < 64,
			"clock": float(w.clock), "you_took": int(w.me.meals), "born": int(w.born), "fresh": int(w.fresh), "alive": int(w.alive)})
		# finite ground runs out
		await _until(func(): return bool(work.state().over), 4200)
		var e: Dictionary = work.state()
		for i in 180: await physics_frame
		var later: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("bare.png"))
		checks.append({"check": "finite ground: the floor is eaten, everyone stops, the visitor's energy too, and the field stays bare", "ok": bool(e.over) and int(e.fresh) == 0 and int(e.alive) == 0 and not bool(e.me.alive)
			and float(e.bare_at) > 2.0 and float(e.bare_at) < 30.0 and float(e.ended_at) < 70.0 and int(later.fresh) == 0 and not bool(later.running) and float(later.clock) == float(e.clock),
			"bare_at_s": float(e.bare_at), "ended_at_s": float(e.ended_at), "born": int(e.born), "stopped": int(e.died), "you": e.me})
		# begin again: ground that returns
		await _go(work.point_at(Vector3(2.6, 0, 3.4)))
		await _go(work.plate_point("returns"))
		for i in 80: await physics_frame
		var again: Dictionary = work.state()
		await _go(work.cell_point(6, 6))
		for i in 1800: await physics_frame
		var r: Dictionary = work.state()
		await _shot(cam, over, middle, folder.path_join("returns.png"))
		checks.append({"check": "the plate for ground that returns begins again with the next seed; a body standing still is paid again by the panel it stands on, and the field carries a full population",
			"ok": str(again.ground) == "returns" and not bool(again.running) and int(again.fresh) == 64 and int(again.alive) == 12 and int(again.seed) == int(s.seed) + 1
				and bool(r.running) and int(r.me.meals) >= 2 and int(r.alive) >= 20 and int(r.fresh) > 0 and float(r.clock) > 28.0,
			"seed": int(again.seed), "after_30_s": {"alive": int(r.alive), "fresh": int(r.fresh), "you": r.me}})
		# barren
		await _go(work.point_at(Vector3(4.8, 0, 3.4)))
		work.apply_grid_config({"ground": "barren"})
		for i in 20: await physics_frame
		var b0: Dictionary = work.state()
		await _go(work.cell_point(6, 6))
		await _until(func(): return bool(work.state().over), 1500)
		var b: Dictionary = work.state()
		checks.append({"check": "barren: nothing is laid; twelve bodies and a visitor last ten seconds", "ok": int(b0.fresh) == 0 and int(b0.alive) == 12 and bool(b.over) and float(b.ended_at) > 9.0 and float(b.ended_at) < 12.0
			and int(b.me.meals) == 0, "ended_at_s": float(b.ended_at), "you": b.me})
		work.apply_grid_config({"ground": "finite"})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("field.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[fresh_ground_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
