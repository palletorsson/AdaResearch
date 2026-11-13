extends SceneTree
## THE RECORD PILES on their floor (PG_Branching_Growth; the pass, 2026-11-13)
## The hall's desk steps a nearest-target growth rule; the floor work lays every stored record down as a disc and
## stacks the records that share a position. Read in the running tower, with the hall's own desk and the tower's walker:
##   the work reads the lesson's model on its floor (it has no rule of its own);
##   before a step: one record, one place, eight posts, none reached;
##   after eight STEPs at the desk: what the bench predicted (tools/probes/record_piles_bench.py) - 192 records on 14
##   places, the tallest pile 40, one post of eight reached - and what the desk's own readout says;
##   a body stepping on the plate sees one disc a place, and stepping on it again every record;
##   a pile is solid: a body walking straight at the tallest does not pass through its place;
##   a body walks on to the farthest post, which nothing has reached;
##   with the desk's VARIATION the same number of records lies on (nearly) as many places; RESET leaves one.
##
##   godot --path <stage> --script res://tools/probes/record_piles_floor.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## piles.json: checks with what was read. begin.png, arrival.png, piles.png, above.png, places.png, variation.png.
const ID := "record-piles"
const BENCH := {"records": 192, "places": 14, "tallest": 40, "reached": 1}
var game: Node3D


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 600, speed: float = 0.5, mind: Vector3 = Vector3.INF) -> float:
	var nearest := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if mind != Vector3.INF: nearest = minf(nearest, Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(mind.x, mind.z)))
		if d < 0.15: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return nearest


func _press(desk: Node, id: String, times: int = 1) -> void:
	for i in times:
		desk.act(id)
		for j in 14: await process_frame      # the floor work looks at the model every 0.15 s


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
	var desk_id := ""
	for a in record.artifacts:
		if str(a.artifact) == "pg_workshop_console": desk_id = str(a.id)
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]) and game.building.content.exhibits.has("%d/%s" % [floor, desk_id]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	var desk_mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, desk_id])
	var piles: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
	var desk: Node = desk_mount.get_node_or_null("Artifact") if desk_mount != null else null
	var have: bool = piles != null and desk != null and piles.has_method("state") and desk.has_method("act")
	if have:
		for i in 1200:
			if bool(desk.ready_for_input) and str(piles.state().reads) == "floor": break
			await physics_frame
		for i in 40: await physics_frame
	checks.append({"check": "the floor holds the record piles and the hall's desk, and the piles read the lesson's model on this floor", "ok": have and bool(desk.ready_for_input) and str(piles.state().reads) == "floor",
		"reads": str(piles.state().reads) if have else ""})
	if have and bool(desk.ready_for_input) and str(piles.state().reads) == "floor":
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):
			if layer.get_viewport() == root: layer.hide()
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var at: Vector3 = piles.global_position
		var lesson: Object = piles.get("_model")
		await _press(desk, "RESET")
		var s0: Dictionary = piles.state()
		checks.append({"check": "before a step: one record on one place, eight posts, none reached", "ok": int(s0.records) == 1 and int(s0.places) == 1 and int(s0.targets) == 8 and int(s0.reached) == 0, "state": s0})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(-1.0, 0.7, -4.0), folder.path_join("begin.png"))
		await _press(desk, "STEP", 8)
		var s8: Dictionary = piles.state()
		var said: String = str(desk.readout.text)
		checks.append({"check": "after eight steps at the desk: 192 records on 14 places, the tallest pile 40, one post of eight reached - the bench, and the desk's own readout", "ok": int(s8.records) == int(BENCH.records) and int(s8.places) == int(BENCH.places)
			and int(s8.tallest) == int(BENCH.tallest) and int(s8.reached) == int(BENCH.reached) and said.contains("192/192 records") and said.contains("14 distinct positions") and int(s8.discs) == 192,
			"state": s8, "the_desk_says": said.replace("\n", " | ")})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(-1.0, 0.7, -4.0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(0.9, 1.5, 1.2), at + Vector3(-3.0, 0.7, -2.5), folder.path_join("piles.png"))
		await _shot(cam, at + Vector3(-1.0, 9.5, 1.5), at + Vector3(-1.0, 0.0, -5.0), folder.path_join("above.png"))
		# the plate
		var plate: Vector3 = at + Vector3(5.6, 0, 1.3)
		game.place_player(plate + Vector3(0, 0.3, 2.2))
		for i in 40: await physics_frame
		await _go(body, plate, 400, 0.34)
		for i in 14: await process_frame
		var on_once: Dictionary = piles.state()
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(-1.0, 0.7, -4.0), folder.path_join("places.png"))
		await _go(body, plate + Vector3(0, 0, 2.2), 400, 0.34)
		await _go(body, plate, 400, 0.34)
		for i in 14: await process_frame
		var on_twice: Dictionary = piles.state()
		checks.append({"check": "a body stepping on the plate sees one disc a place, and stepping on it again every record", "ok": str(on_once.shows) == "places" and int(on_once.discs) == 14 and str(on_twice.shows) == "records" and int(on_twice.discs) == 192,
			"first": [str(on_once.shows), int(on_once.discs)], "second": [str(on_twice.shows), int(on_twice.discs)]})
		# a pile is solid
		var tall_at := Vector3.ZERO
		var tall_n := 0
		var seen := {}
		for b in lesson.branches:
			seen[b.position] = int(seen.get(b.position, 0)) + 1
			if int(seen[b.position]) > tall_n:
				tall_n = int(seen[b.position])
				tall_at = piles.to_global(piles.on_floor(b.position))
		game.place_player(tall_at + Vector3(0, 0.3, 1.6))
		for i in 40: await physics_frame
		var nearest: float = await _go(body, tall_at + Vector3(0, 0, -2.0), 500, 0.34, tall_at)
		checks.append({"check": "a pile is solid: a body walking straight at the tallest does not pass through its place", "ok": nearest >= 0.24 and int(piles.state().solid_piles) >= 8, "nearest_m_to_the_pile": snappedf(nearest, .01),
			"tallest": tall_n, "solid_piles": int(piles.state().solid_piles)})
		# on to the farthest post
		var far: Vector3 = piles.to_global(piles.on_floor(lesson.attractors[lesson.attractors.size() - 1].position))
		game.place_player(Vector3(0.6, level + 0.3, 7.6))
		for i in 40: await physics_frame
		await _go(body, at + Vector3(2.0, 0, 0.6), 500)
		await _go(body, Vector3(far.x + 2.0, level, far.z + 1.0), 900)
		await _go(body, far + Vector3(0.5, 0, 0), 500, 0.34)
		var from_post: float = Vector2(body.global_position.x - far.x, body.global_position.z - far.z).length()
		checks.append({"check": "a body walks on to the farthest post: nothing has reached it", "ok": from_post < 0.8 and not bool(lesson.attractors[lesson.attractors.size() - 1].is_reached) and absf(body.global_position.y - level) < 0.2,
			"m_from_the_post": snappedf(from_post, .01), "post_from_the_root_m": snappedf(Vector2(far.x - at.x, far.z - at.z).length(), .01)})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		# variation, then reset
		await _press(desk, "VARIATION")
		await _press(desk, "STEP", 8)
		var sv: Dictionary = piles.state()
		await _shot(cam, at + Vector3(0.9, 1.5, 1.2), at + Vector3(-3.0, 0.4, -2.5), folder.path_join("variation.png"))
		await _press(desk, "RESET")
		var sr: Dictionary = piles.state()
		checks.append({"check": "with the desk's VARIATION the records lie on nearly as many places, no pile over three; RESET leaves one record", "ok": int(sv.records) >= 150 and int(sv.places) >= int(sv.records) * 9 / 10 and int(sv.tallest) <= 3 and int(sr.records) == 1,
			"variation": sv, "reset": sr})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("piles.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[record_piles_floor] ", "PASSED" if result.passed else "FAILED")
	quit()
