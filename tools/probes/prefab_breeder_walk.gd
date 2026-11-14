extends SceneTree
## THE BREEDING YARD on its floor (ML_Evolution; the pass, 2026-11-14)
## Six forms grown from genomes whose genes are the tower's prefabs; three judges. Read in the running tower with
## its own walker:
##   six forms stand, every part of them a lab prefab, nobody has chosen;
##   the body stands still on a pad: that form stays as it was, the other five are its children - each differs from
##   it, and they differ among themselves;
##   on the sentence's plate the written taste chooses every two and a half seconds, and its best score does not fall;
##   on the other plate nobody chooses: a generation is kept by lot;
##   KEEP writes the last chosen form as a recipe of prefabs and puts it on the shelf; read back, it stands there again.
##
##   godot --path <stage> --script res://tools/probes/prefab_breeder_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## yard.json: checks with what was read. founders.png, children.png, sentence.png, kept.png.
const ID := "breeding-yard"
const PROBE_FOLDER := "user://bred_prefabs_probe"
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


func _kinds() -> Dictionary:
	var kinds := {}
	for stand in work.find_children("Stand*", "Node3D", true, false):
		for n in stand.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene") and not n.is_queued_for_deletion(): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
	return kinds


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
	if work != null and work.has_method("plate_point"):
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
		# an empty folder of its own, so that a test keeps nothing on the tower's shelf
		var dir := DirAccess.open(PROBE_FOLDER)
		if dir != null:
			for old in dir.get_files(): dir.remove(old)
		work.apply_grid_config({"keep_folder": PROBE_FOLDER})
		game.place_player(work.point_at(Vector3(-5.0, 0.3, 4.4)))
		for i in 60: await physics_frame
		var view: Vector3 = work.point_at(Vector3(0.0, 2.6, 7.4))
		var middle: Vector3 = work.point_at(Vector3(0.0, 0.9, -0.4))
		var s: Dictionary = work.state()
		var kinds := _kinds()
		var known := ["crate", "construction_cube", "timber_plank_2m", "timber_panel_1x1", "traffic_pyramid_5", "pentagonal_bipyramid_7", "trace_point_ball", "tetrahedron_blocker", "wp", "barrier"]
		var all_known := true
		var total := 0
		for k in kinds:
			total += int(kinds[k])
			if not known.has(k): all_known = false
		var parts_said := 0
		for m in s.measures: parts_said += int(m.parts)
		checks.append({"check": "six forms stand, every part of them a lab prefab, nobody has chosen", "ok": (s.genomes as Array).size() == 6 and int(s.generation) == 0 and int(s.last) == -1 and all_known and total == parts_said and total >= 12
			and int(s.kept) == 0, "parts": total, "kinds": kinds, "measures": s.measures, "build_ms": int(s.build_ms)})
		await _shot(cam, view, middle, folder.path_join("founders.png"))
		# the visitor chooses the third
		await _go(work.plate_point("pad", 2))
		for i in 90: await physics_frame
		var c: Dictionary = work.state()
		var differ := 0
		var distinct := {}
		for i in 6:
			if i != 2 and str(c.genomes[i]) != str(c.genomes[2]): differ += 1
			distinct[str(c.genomes[i])] = true
		await _shot(cam, view, middle, folder.path_join("children.png"))
		checks.append({"check": "the body stands still on a pad: that form stays as it was, the other five are its children - each differs from it, and they differ among themselves", "ok": int(c.generation) == 1 and int(c.last) == 2
			and str(c.last_judge) == "visitor" and str(c.genomes[2]) == str(s.genomes[2]) and differ == 5 and distinct.size() >= 4 and int(c.pending) == 0, "children_that_differ": differ, "distinct_forms": distinct.size()})
		# the sentence
		await _go(work.plate_point("pad", 2) + (work.plate_point("sentence") - work.plate_point("pad", 2)) * 0.5)
		await _go(work.plate_point("sentence"))
		var best_before: float = float(c.measures[int(c.best)].score)
		for i in 600: await physics_frame
		var t: Dictionary = work.state()
		await _shot(cam, view, middle, folder.path_join("sentence.png"))
		checks.append({"check": "on the sentence's plate the written taste chooses every two and a half seconds, and its best score does not fall", "ok": int(t.chosen_by.sentence) >= 3 and float(t.measures[int(t.best)].score) >= best_before
			and str(t.last_judge) == "sentence", "generations_by_the_sentence": int(t.chosen_by.sentence), "best_score_before": best_before, "best_score_after": float(t.measures[int(t.best)].score), "the_best": t.measures[int(t.best)]})
		# nobody
		await _go(work.plate_point("nobody"))
		for i in 330: await physics_frame
		var n: Dictionary = work.state()
		checks.append({"check": "on the other plate nobody chooses: a generation is kept by lot", "ok": int(n.chosen_by.nobody) >= 2 and str(n.last_judge) == "nobody", "generations_by_lot": int(n.chosen_by.nobody), "generation": int(n.generation)})
		# keep
		await _go(work.plate_point("keep"))
		for i in 90: await physics_frame
		var k: Dictionary = work.state()
		var written: Variant = JSON.parse_string(FileAccess.get_file_as_string(str(k.saved))) if str(k.saved) != "" else null
		var good: bool = written is Dictionary and (written.parts as Array).size() >= 2 and known.has(str(written.parts[0].prefab)) and (written.parts[0].fit as Array).size() == 3
		work.reload_shelf()
		for i in 20: await physics_frame
		var again: Dictionary = work.state()
		await _shot(cam, work.point_at(Vector3(3.5, 2.4, 5.4)), work.point_at(Vector3(-1.0, 0.6, -1.6)), folder.path_join("kept.png"))
		checks.append({"check": "KEEP writes the last chosen form as a recipe of prefabs and puts it on the shelf; read back, it stands there again", "ok": int(k.kept) == 1 and good and int(again.kept) == 1 and str(k.folder) == PROBE_FOLDER,
			"file": str(k.saved).get_file(), "parts_in_the_recipe": (written.parts as Array).size() if written is Dictionary else 0, "bred": written.bred if written is Dictionary else {}})
		work.apply_grid_config({"keep_folder": ""})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(ch): return ch.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("yard.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[prefab_breeder_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
