extends SceneTree
## The building stations in template mode (commons/artifacts/face_assembly/template_build.gd) on the floor the
## game starts on: the row named by --row. Stands the visitor's camera in front of the box and of each frame
## and acts the way a pointer does: a ray on the pointer mask finds the body, and the pointer events a push
## button gets (entered, moved, pressed) are sent to it with that ray. The probe has no hands and no mouse; the
## events are the ones commons/scenes/DesktopInteractionPointer.gd and the XR pointer send.
##
## Checks: no buttons, no loose faces and no table; the box hangs in the air; every frame has its own plinth
## half a metre high; a frame takes nothing until a face is taken from the box; taking it makes the face the
## hand's selected item, on the belt, with its miniature where the hand shows the current item (the wrist clock
## in VR); one press adds one face; a filled frame drops its solid on its own plinth and empties; with another
## thing in the hand the frame refuses again; a held diamond draws the world in wireframe and letting go dresses
## it again; the association frame makes cube associations from terms.json, two in a row different; and a
## station without the config key is the old free-form table.
##
##   python tools/run_floor_probe.py <Map> template_build.gd template_build.json <folder> --no-opening --opera-quiet --row=<row id> [--xr]

const POINTER_MASK := (1 << 18) | (1 << 20) | (1 << 22)
const Items := preload("res://commons/player/inventory_items.gd")

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


func _press(target: Node3D, at: Vector3) -> void:
	XRToolsPointerEvent.pressed(eye, target, at)
	XRToolsPointerEvent.released(eye, target, at)


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
	# the probe's own belt: what it collects is not written into the visitor's saved one
	Items.collected_path = folder.path_join("collected.json")
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	# --xr: the game's VR branch on synthetic trackers, to catch a script error only the headset's path would meet
	if OS.get_cmdline_user_args().has("--xr"): game.force_xr = true
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	result = {"floor": int(game.checkpoint), "row": row, "xr": bool(game.get("vr")), "frames": [], "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var mount := game.building.content.exhibits.get("%d/%s" % [int(game.checkpoint), row]) as Node3D
	var table := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if not _check("the row stands on the floor", table != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var build := table.get("template") as Node3D
	if not _check("the station is in template mode", str(table.get("build")) == "template" and is_instance_valid(build)):
		_done(); return
	var buttons := table.find_children("*", "", true, false).filter(func(n): return n.has_signal("pressed") and n.has_signal("released"))
	_check("no buttons, no loose faces, no table", buttons.is_empty() and (table.get("pieces") as Array).is_empty() and not table.has_node("Controls") and build.find_children("TableTop", "", true, false).is_empty(),
		{"buttons": buttons.size(), "loose_faces": (table.get("pieces") as Array).size()})
	var frames: Array = build.get("frames")
	var item := str(build.call("item_id"))
	var hand: Node = get_first_node_in_group("inventory_hands")
	result["hand"] = {"found": hand != null, "item": item}
	# the box: in the air, nothing of the station under it
	var box_at: Vector3 = table.to_global(build.get("box_at"))
	var under := PhysicsRayQueryParameters3D.create(box_at + Vector3.DOWN * 0.17, box_at + Vector3.DOWN * 1.15, 1)
	var below := eye.get_world_3d().direct_space_state.intersect_ray(under)
	var below_node := below.get("collider") as Node
	_check("the box hangs in the air", box_at.y - table.global_position.y > 1.0 and (below_node == null or not table.is_ancestor_of(below_node)),
		{"height_m": snappedf(box_at.y - table.global_position.y, 0.01), "under_it": str(below_node.name) if below_node != null else "nothing"})
	var plinths_ok := true
	var tops := []
	for frame: Dictionary in frames:
		var plinth := frame.plinth as Node3D
		var block := plinth.get_node_or_null("Block") as MeshInstance3D
		var top: float = (block.position.y + (block.mesh as BoxMesh).size.y * 0.5) if block != null else -1.0
		tops.append(snappedf(top, 0.01))
		var centre: Vector3 = frame.centre
		if block == null or absf(top - 0.5) > 0.005 or absf(plinth.position.x - centre.x) > 0.001 or absf(plinth.position.z - centre.z) > 0.001: plinths_ok = false
	_check("every frame has its own plinth, half a metre high, under it", plinths_ok and frames.size() >= 2, {"frames": frames.size(), "plinth_tops_m": tops})
	await _look(table.to_global(Vector3(0.1, 1.7, 2.7)), table.to_global(Vector3(-0.1, 0.95, 0.3)))
	await _picture("1_station.png")
	# before a face is taken a frame takes nothing
	var first: Dictionary = frames[0]
	await _look(table.to_global(Vector3(table.to_local((first.root as Node3D).global_position).x + 0.25, 1.62, 1.55)), (first.root as Node3D).global_position)
	var hit := _ray()
	var reach := hit.get("collider") as Node3D
	if reach != null and reach.has_method("pointer_event"): _press(reach, hit.position)
	await _wait(0.2)
	_check("without a face in the hand a frame takes nothing and says so", not bool(build.call("in_hand")) and (first.filled as Array).count(null) == (first.filled as Array).size() and (first.label as Label3D).text.contains("TAKE A FACE"),
		{"label": (first.label as Label3D).text})
	# take the face: a press on the box
	await _look(box_at + table.global_basis * Vector3(0.1, 0.35, 1.3), box_at)
	hit = _ray()
	var stock := hit.get("collider") as Node3D
	if _check("the pointer's ray meets the box", stock != null and stock.has_method("pointer_event") and stock.get("build") == build, {"collider": str(stock.name) if stock != null else "nothing"}):
		_press(stock, hit.position)
	await _wait(0.6)
	var mini: Node3D = hand.call("mini_node") as Node3D if hand != null else null
	_check("the face is the hand's selected item, on the belt, and shown where the hand shows it", bool(build.call("in_hand")) and (hand == null or (str(hand.get("current")) == item and item in (hand.call("belt") as Array) and mini != null)),
		{"current": str(hand.get("current")) if hand != null else "no hand", "miniature": str(mini.name) if mini != null else "none",
		"shown_on": str(mini.get_parent().name) if mini != null else "", "on_the_wrist_clock": mini != null and mini.get_parent().has_meta("inventory_wrist")})
	await _picture("2_face_taken.png")
	for index in frames.size():
		var frame: Dictionary = frames[index]
		var centre: Vector3 = (frame.root as Node3D).global_position
		var plinth_top: Vector3 = (frame.plinth as Node3D).global_position + Vector3.UP * 0.5
		var entry := {"title": frame.title, "reward": frame.reward, "walls": (frame.walls as Array).size()}
		(result.frames as Array).append(entry)
		for turn in (2 if frame.reward == "association" else 1):
			await _look(table.to_global(Vector3(table.to_local(centre).x + 0.25, 1.62, 1.55)), centre)
			hit = _ray()
			reach = hit.get("collider") as Node3D
			if not _check("the pointer's ray meets frame %d (%s)" % [index, frame.title], reach != null and reach.has_method("pointer_event") and reach.get("build") == build,
				{"collider": str(reach.name) if reach != null else "nothing"}): break
			XRToolsPointerEvent.entered(eye, reach, hit.position)
			XRToolsPointerEvent.moved(eye, reach, hit.position, hit.position)
			var ghost := build.get("ghost") as Node3D
			if turn == 0: _check("looking at frame %d shows where the next face goes" % index, ghost.visible)
			var presses := 0
			var filled: Array = frame.filled
			var went_in := true
			while filled.has(null) and presses < 30:
				var before := filled.count(null)
				_press(reach, hit.position)
				presses += 1
				if filled.count(null) != before - 1: went_in = false
				await _wait(0.25)
				if frame.reward in ["diamond", "cube"] and turn == 0 and presses == int(entry.walls) / 2:
					XRToolsPointerEvent.moved(eye, reach, hit.position, hit.position)
					await _picture("3_half_filled.png")
			_check("frame %d: one press, one face, %d presses fill it" % [index, int(entry.walls)], went_in and presses == int(entry.walls), {"presses": presses})
			_check("a filled frame takes no more", not bool(build.call("add_face", index, 0)))
			XRToolsPointerEvent.exited(eye, reach, hit.position)
			await _wait(2.8)
			var rewards: Array = build.get("rewards")
			var reward := rewards.back() as Node3D if not rewards.is_empty() else null
			var lies := reward.global_position - plinth_top if is_instance_valid(reward) else Vector3.ONE * 9.0
			_check("frame %d drops its solid on its own plinth and empties" % index,
				is_instance_valid(reward) and lies.y > -0.06 and lies.y < 0.4 and absf(lies.x) < 0.25 and absf(lies.z) < 0.25 and filled.count(null) == filled.size(),
				{"reward": str(reward.name) if is_instance_valid(reward) else "none", "from_the_plinth_top_m": _v(lies), "label": (frame.label as Label3D).text})
			if not is_instance_valid(reward): break
			entry["reward_%d" % turn] = str(reward.name)
			if frame.reward == "diamond":
				var was: int = root.debug_draw
				await _look(table.to_global(Vector3(0.1, 1.7, 2.7)), table.to_global(Vector3(-0.1, 0.95, 0.3)))
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
				_check("it is a model no larger than the hand", maxf(size.x, maxf(size.y, size.z)) <= 0.245, {"size_m": _v(size)})
				if turn == 1: _check("two in a row are different things", entry.reward_0 != entry.reward_1, {"first": entry.reward_0, "second": entry.reward_1})
	await _look(table.to_global(Vector3(0.1, 1.7, 2.7)), table.to_global(Vector3(-0.1, 0.95, 0.3)))
	await _picture("4_solids_on_their_plinths.png")
	# another thing in the hand: the frame refuses again; the face back in the hand: it takes
	if hand != null and str(hand.get("current")) == item:
		hand.call("set_current", "")
		await _wait(0.2)
		var refuses := not bool(build.call("in_hand"))
		hand.call("set_current", item)
		await _wait(0.2)
		_check("with the hand empty the frame refuses; with the face chosen again it takes", refuses and bool(build.call("in_hand")))
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
