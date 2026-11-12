extends SceneTree
## THE COLONIZATION FLOOR (floor PG_Space_Colonization; the pass, 2026-11-12)
## Points ask the nearest site within 1.6 m; a site that is asked grows 15 cm toward the sum of those who ask; a
## point is taken when a site stands within 30 cm. Read in the running tower, with its own walker:
##   THE BENCH    the rule alone, on field 3, gives exactly what the bench predicted before the work was built
##                (tools/probes/colonization_bench.py --json 3): a tree of 228 sites that takes all sixty points in
##                59 steps when every site may answer, and a thread that spends all 900 sites on six points when
##                only a tip may;
##   THE FLOOR    the field on the floor grows to the same tree by itself;
##   THE POINTS ARE YOURS   the walker crosses the field: its walk leaves points, pieces grow in answer to them,
##                and when it has left none of its points is still asking;
##   a plate changes who answers; what a physics tick costs.
##
##   godot --path <stage> --script res://tools/probes/colonization_floor_grow.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## colonization.json: checks with what was read. arrival.png, tree.png, yours.png, thread.png.
const ID := "colonization-floor"
const SCRIPT := "res://algorithms/proceduralgeneration/growth_systems/colonization_floor/colonization_floor.gd"
## who answers -> [steps, sites, points taken, points left]
const BENCH := {"all": [59, 228, 60, 0], "tips": [900, 900, 6, 54]}
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 900, speed: float = 0.5) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.15: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return best


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

	# 1 the rule alone, against the bench
	var Rule = load(SCRIPT).Field
	var read := {}
	var rule_ok := true
	for who: String in BENCH:
		var f = Rule.new(3, who)
		f.run()
		read[who] = [int(f.steps), int(f.sx.size()), int(f.taken()), int(f.asking())]
		if str(read[who]) != str(BENCH[who]): rule_ok = false
	checks.append({"check": "the rule alone on field 3: a tree of 228 sites takes all sixty points in 59 steps; a thread spends 900 sites on six", "ok": rule_ok, "read": read, "bench": BENCH})

	for i in 1500:
		if game.building.content.exhibits.has(str(floor) + "/" + ID): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get(str(floor) + "/" + ID)
	var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	checks.append({"check": "the floor holds the colonization floor", "ok": work != null and work.has_method("yours")})
	if work != null and work.has_method("yours"):
		for i in 200: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var centre: Vector3 = work.global_position
		game.place_player(Vector3(9.0, level + 0.3, 8.5))
		for i in 30: await physics_frame

		# 2 the floor grows the same tree by itself
		work.apply_grid_config({"begin_again_seconds": 600.0})
		work.set_field(3)
		work.frame_ms()
		var grown := false
		for i in 900:
			await physics_frame
			var st: Dictionary = work.state()
			if int(st.sites) == 228 and int(st.asking) == 0: grown = true; break
		for i in 60: await physics_frame
		var tree: Dictionary = work.state()
		var growing: Dictionary = work.frame_ms()
		checks.append({"check": "on the floor the field grows by itself to the bench's tree: 228 sites, sixty points taken, none asking", "ok": grown and int(tree.sites) == 228 and int(tree.taken) == 60 and int(tree.asking) == 0, "state": tree})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), centre + Vector3(0, 0.0, -0.4), folder.path_join("arrival.png"))
		await _shot(cam, centre + Vector3(0, 5.0, 4.6), centre + Vector3(0, 0, -0.2), folder.path_join("tree.png"))

		# 3 the walker crosses the field; the branches come to its walk
		var from: Vector3 = work.field_point(-5.0, 1.4)
		var to: Vector3 = work.field_point(4.6, -1.2)
		game.place_player(from + Vector3(-1.4, 0.3, 0))
		for i in 40: await physics_frame
		await _go(body, from)
		await _go(body, to)
		var mid: Dictionary = work.state()
		for i in 240: await physics_frame
		var after: Dictionary = work.state()
		var mine: Dictionary = work.yours()
		checks.append({"check": "the walker crosses the field: its walk leaves points, pieces grow in answer to them, and none of its points is still asking", "ok": int(after.left_by_bodies) >= 15 and int(mine.pieces) >= 20 and int(mine.still_asking) == 0 and int(after.sites) > 228,
			"points_left_by_the_walk": int(after.left_by_bodies), "pieces_grown_for_them": int(mine.pieces), "still_asking": int(mine.still_asking), "sites": int(after.sites)})
		await _shot(cam, centre + Vector3(0, 5.0, 4.6), centre + Vector3(0, 0, -0.2), folder.path_join("yours.png"))

		# 4 only a tip answers: the thread
		game.place_player(Vector3(9.0, level + 0.3, 8.5))      # off the field: a body on it leaves a point
		for i in 30: await physics_frame
		work.apply_grid_config({"steps_per_second": 2000.0})
		work.set_answers("tips")
		var spent := false
		for i in 1200:
			await physics_frame
			if int(work.state().sites) >= 900: spent = true; break
		for i in 30: await physics_frame
		var thread: Dictionary = work.state()
		checks.append({"check": "only a tip answers: the thread spends all 900 sites and takes six points", "ok": spent and int(thread.sites) == 900 and int(thread.taken) == 6 and int(thread.asking) == 54, "state": thread})
		await _shot(cam, centre + Vector3(0, 5.0, 4.6), centre + Vector3(0, 0, -0.2), folder.path_join("thread.png"))

		# 5 a plate; cost
		work.apply_grid_config({"steps_per_second": 12.0})
		var plate: Vector3 = work.plate_centre(1)
		game.place_player(plate + Vector3(1.0, 0.3, 0.0))
		for i in 80: await physics_frame
		await _go(body, plate, 300, 0.34)
		checks.append({"check": "a body steps on WHO ANSWERS and every site answers again", "ok": str(work.answers) == "all", "answers": str(work.answers)})
		checks.append({"check": "a physics tick costs under 0.3 ms on average while the tree grows; the worst is reported", "ok": float(growing.mean) < 0.3, "mean_ms": snappedf(float(growing.mean), .001), "worst_ms": snappedf(float(growing.worst), .01)})
		work.apply_grid_config({"begin_again_seconds": 30.0})
		work.set_field(3)
		game.place_player(Vector3(9.0, level + 0.3, 8.5))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("colonization.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[colonization_floor_grow] ", "PASSED" if result.passed else "FAILED")
	quit()
