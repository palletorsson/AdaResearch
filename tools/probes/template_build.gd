extends SceneTree
## The building tables in template mode (commons/artifacts/face_assembly/template_build.gd) on the floor the game
## starts on: the row named by --row. Stands the visitor's camera in front of each frame and adds faces the way
## a pointer does: a ray on the pointer mask finds the frame's body, and the pointer events a push button gets
## (entered, moved, pressed) are sent to it with that ray. The probe has no hands and no mouse; the events are
## the ones commons/scenes/DesktopInteractionPointer.gd and the XR pointer send.
##
## Checks: no buttons and no loose faces; every frame is reached by the pointer's ray; one press adds one face;
## a filled frame drops its reward on the table and empties; a held diamond draws the world in wireframe and
## letting go dresses it again; the association frame makes cube associations from terms.json, two in a row
## different; and a table without the config key is the old free-form table.
##
##   python tools/run_floor_probe.py <Map> template_build.gd template_build.json <folder> --no-opening --opera-quiet --row=<row id> [--xr]

const POINTER_MASK := (1 << 18) | (1 << 20) | (1 << 22)

var game: Node
var folder := "res://ada_run/template_build"
var row := ""
var result := {}
var eye: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var entry := {"check": what, "ok": ok}
	entry.merge(more)
	(result.checks as Array).append(entry)
	return ok


func _v(p: Vector3) -> Array:
	return [snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)]


func _look(from: Vector3, at: Vector3) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)
	for i in 3: await physics_frame


func _picture(file: String) -> void:
	for i in 10: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


## What the pointer's ray meets, straight ahead of the camera.
func _ray() -> Dictionary:
	var query := PhysicsRayQueryParameters3D.create(eye.global_position, eye.global_position - eye.global_basis.z * 10.0, POINTER_MASK)
	query.collide_with_areas = true
	return eye.get_world_3d().direct_space_state.intersect_ray(query)


func _wait(seconds: float) -> void:
	for i in int(seconds * 60.0): await physics_frame


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("template_build.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--row="): row = arg.trim_prefix("--row=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	# --xr: the game's VR branch on synthetic trackers, to catch a script error only the headset's path would meet
	if OS.get_cmdline_user_args().has("--xr"): game.force_xr = true
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	result = {"floor": int(game.checkpoint), "row": row, "frames": [], "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var mount := game.building.content.exhibits.get("%d/%s" % [int(game.checkpoint), row]) as Node3D
	var table := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if not _check("the row stands on the floor", table != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var build := table.get("template") as Node3D
	if not _check("the table is in template mode", str(table.get("build")) == "template" and is_instance_valid(build)):
		_done(); return
	var buttons := table.find_children("*", "", true, false).filter(func(n): return n.has_signal("pressed") and n.has_signal("released"))
	_check("no button interface and no loose faces", buttons.is_empty() and (table.get("pieces") as Array).is_empty() and not table.has_node("Controls"),
		{"buttons": buttons.size(), "loose_faces": (table.get("pieces") as Array).size()})
	var frames: Array = build.get("frames")
	var top: float = table.to_global(Vector3(0, float(build.TOP), 0)).y
	await _look(table.to_global(Vector3(0.2, 1.75, 2.2)), table.to_global(Vector3(0, 1.15, 0.3)))
	await _picture("1_empty_frames.png")
	for index in frames.size():
		var frame: Dictionary = frames[index]
		var centre: Vector3 = (frame.root as Node3D).global_position
		var entry := {"title": frame.title, "reward": frame.reward, "walls": (frame.walls as Array).size()}
		(result.frames as Array).append(entry)
		for turn in (2 if frame.reward == "association" else 1):
			# stand in front, a little above, as a visitor at the table's long side
			await _look(table.to_global(Vector3(to_table(table, centre).x + 0.25, 1.62, 1.55)), centre)
			var hit := _ray()
			var reach := hit.get("collider") as Node3D
			if not _check("the pointer's ray meets frame %d (%s)" % [index, frame.title], reach != null and reach.has_method("pointer_event") and reach.get("build") == build,
				{"collider": str(reach.name) if reach != null else "nothing"}): break
			XRToolsPointerEvent.entered(eye, reach, hit.position)
			XRToolsPointerEvent.moved(eye, reach, hit.position, hit.position)
			var ghost := build.get("ghost") as Node3D
			if turn == 0: _check("looking at frame %d shows where the next face goes" % index, ghost.visible, {"ghost_at": _v(ghost.global_position)})
			var presses := 0
			var filled: Array = frame.filled
			var went_in := true
			while filled.has(null) and presses < 20:
				var before := filled.count(null)
				XRToolsPointerEvent.pressed(eye, reach, hit.position)
				XRToolsPointerEvent.released(eye, reach, hit.position)
				presses += 1
				if filled.count(null) != before - 1: went_in = false
				await _wait(0.3)
				if index == 0 and turn == 0 and presses == int(entry.walls) / 2:
					XRToolsPointerEvent.moved(eye, reach, hit.position, hit.position)
					await _picture("2_half_filled.png")
			_check("frame %d: one press, one face, %d presses fill it" % [index, int(entry.walls)], went_in and presses == int(entry.walls), {"presses": presses})
			if index == 0 and turn == 0: await _picture("3_filled.png")
			_check("a filled frame takes no more", not bool(build.call("add_face", index, 0)))
			XRToolsPointerEvent.exited(eye, reach, hit.position)
			await _wait(2.6)
			var rewards: Array = build.get("rewards")
			var reward := rewards.back() as Node3D if not rewards.is_empty() else null
			var lies: float = reward.global_position.y - top if is_instance_valid(reward) else -9.0
			_check("frame %d drops its reward on the table and empties" % index, is_instance_valid(reward) and lies > -0.02 and lies < 0.35 and filled.count(null) == filled.size(),
				{"reward": str(reward.name) if is_instance_valid(reward) else "none", "origin_above_the_table_m": snappedf(lies, 0.01), "label": (frame.label as Label3D).text})
			if not is_instance_valid(reward): break
			entry["reward_%d" % turn] = str(reward.name)
			if frame.reward == "diamond":
				await _look(table.to_global(Vector3(0.2, 1.75, 2.2)), table.to_global(Vector3(0, 1.15, 0.3)))
				await _picture("4_diamond_on_the_table.png")
				var was: int = root.debug_draw
				reward.call("on_desktop_grab", eye)
				await _wait(0.2)
				_check("held, the diamond draws the world in wireframe", root.debug_draw == Viewport.DEBUG_DRAW_WIREFRAME, {"debug_draw": root.debug_draw})
				await _picture("5_diamond_held_wireframe.png")
				reward.call("on_desktop_drop", eye)
				await _wait(0.2)
				_check("let go, the world is dressed again", root.debug_draw == was, {"debug_draw": root.debug_draw, "was": was})
			elif frame.reward == "association":
				var names: Array = build.call("cube_terms")
				var term := str(reward.name).trim_prefix("Association_")
				_check("the association is a cube association from terms.json", term in names, {"term": term, "of": names})
				var hull := reward.get_children().filter(func(n): return n is CollisionShape3D).back() as CollisionShape3D
				var size: Vector3 = (hull.shape as BoxShape3D).size
				_check("it is a table model, no larger than the hand", maxf(size.x, maxf(size.y, size.z)) <= 0.245, {"size_m": _v(size)})
				if turn == 1:
					_check("two in a row are different things", entry.reward_0 != entry.reward_1, {"first": entry.reward_0, "second": entry.reward_1})
					await _look(table.to_global(Vector3(0.2, 1.75, 2.2)), table.to_global(Vector3(0, 1.15, 0.3)))
					await _picture("4_associations_on_the_table.png")
			else:
				await _look(table.to_global(Vector3(0.2, 1.75, 2.2)), table.to_global(Vector3(0, 1.15, 0.3)))
				await _picture("4_cube_on_the_table.png")
	# the gate: the same scene with no config key is the free-form table with its buttons
	var old := (load(str(table.scene_file_path)) as PackedScene).instantiate() as Node3D if str(table.scene_file_path) != "" else null
	if old != null:
		root.add_child(old)
		old.global_position = table.global_position + Vector3(0, 40, 0)
		await _wait(0.2)
		_check("without the key it is the old table: buttons and loose faces, no frames", str(old.get("build")) == "free" and old.has_node("Controls") and (old.get("pieces") as Array).size() == 12 and old.get("template") == null,
			{"pieces": (old.get("pieces") as Array).size(), "controls": old.has_node("Controls")})
		old.queue_free()
	_done()


func to_table(table: Node3D, at: Vector3) -> Vector3:
	return table.to_local(at)
