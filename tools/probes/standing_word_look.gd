extends SceneTree
## THE STANDING WORDS of a floor (the pass, 2026-11-15)
## Every row of the floor that is a standing_word: does it stand on the slab at its height, within the width it was
## given, and does it hold a body off? A picture from its front and one from behind (where it reads the wrong way
## round).
##
##   godot --path <stage> --script res://tools/probes/standing_word_look.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## words.json: one check a word. <word>_front.png, <word>_back.png.
var game: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


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
	var rows := []
	for row in record.artifacts:
		if str(row.artifact) == "standing_word": rows.append(str(row.id))
	for i in 1500:
		if rows.all(func(id): return game.building.content.exhibits.has("%d/%s" % [floor, id])): break
		await physics_frame
	for i in 200: await physics_frame
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	var cam := Camera3D.new()
	cam.fov = 75
	eye.add_child(cam)
	cam.current = true
	var body: CharacterBody3D = game.body
	for id in rows:
		var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, id])
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work == null or not work.has_method("said"):
			checks.append({"check": "%s stands" % id, "ok": false})
			continue
		var s: Dictionary = work.state()
		var front: Vector3 = work.global_transform.basis.z.normalized()
		var away: float = maxf(3.2, float(s.size[0]) * 0.75)
		for side in [["front", 1.0], ["back", -1.0]]:
			cam.global_position = work.global_position + front * away * float(side[1]) + Vector3(0, 1.5, 0)
			cam.look_at(work.global_position + Vector3(0, float(s.size[1]) * 0.5, 0), Vector3.UP)
			for i in 6: await process_frame
			eye.get_texture().get_image().save_png(folder.path_join("%s_%s.png" % [str(s.said).to_lower(), str(side[0])]))
		# a body walking at it from the front is held off
		game.place_player(work.global_position + front * 2.0 + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		var target: Vector3 = work.global_position - front * 1.5
		for i in 240:
			body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
			body.drive = Vector2(0, -0.5)
			await physics_frame
		body.drive = Vector2.ZERO
		var kept: float = (body.global_position - work.global_position).dot(front)
		checks.append({"check": "%s stands on the slab at its height, within its width, and holds a body off" % str(s.said), "ok": float(s.size[1]) > 0.5 and float(s.size[0]) <= float(s.fit_width) + 0.01
			and absf(work.global_position.y - mount.global_position.y) < 0.05 and kept > 0.2, "size_m": s.size, "body_stopped_m_in_front": snappedf(kept, .01), "build_ms": int(s.build_ms)})
	result["passed"] = not checks.is_empty() and checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("words.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[standing_word_look] ", "PASSED" if result.passed else "FAILED")
	quit()
