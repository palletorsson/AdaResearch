extends SceneTree
## ISO_ImplicitModeling, floor 156: the row "contact" (commons/artifacts/contact_study) - two bodies that come
## together as the visitor comes near, made four ways. Walks the visitor's camera towards each station and reads
## what the station does: far away the two stand apart, near they are as close as they come; the frame follows the
## distance; SKIN goes from two bodies to one body to one body with an opening, as its baked frames say; THROUGH
## slides one mesh into the other. Counts the triangles drawn and takes pictures: the row from the arrival side,
## each station near, and SKIN at three distances.
##
##   python tools/run_floor_probe.py ISO_ImplicitModeling contact_study.gd contact_study.json <folder> --no-opening --opera-quiet [--row=contact] [--xr]

var game: Node
var folder := "res://ada_run/contact_study"
var result := {}
var eye: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var entry := {"check": what, "ok": ok}
	entry.merge(more)
	(result.checks as Array).append(entry)
	return ok


func _stand(from: Vector3, at: Vector3, seconds: float) -> void:
	eye.global_position = from
	eye.look_at(at, Vector3.UP)
	for i in int(seconds * 60.0): await physics_frame


func _picture(file: String) -> void:
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("contact_study.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	var row := "contact"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--row="): row = arg.trim_prefix("--row=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	# --xr: the game's VR branch on synthetic trackers, before a headset build
	if OS.get_cmdline_user_args().has("--xr"): game.force_xr = true
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	result = {"floor": index, "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	var mount := game.building.content.exhibits.get("%d/%s" % [index, row]) as Node3D
	var study := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if not _check("the row stands on the floor", study != null):
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var stations: Array = study.get("stations")
	_check("four stations, each with its frames", stations.size() == 4 and stations.all(func(s): return s.kind == "through" or ((s.meshes as Array).size() >= 8 and not (s.meshes as Array).has(null))),
		{"stations": stations.map(func(s): return [s.kind, (s.meshes as Array).size()])})
	var front := study.global_basis.z   # the side the plaques face
	var far: float = study.get("far")
	var near: float = study.get("near")
	# from the arrival, before anyone is near
	await _stand(arrival, study.global_position + Vector3.UP * 1.0, 0.5)
	await _picture("1_from_the_arrival.png")
	await _stand(study.global_position + front * 3.6 - study.global_basis.x * 7.2 + Vector3.UP * 1.65, study.global_position - study.global_basis.x * 0.5 + Vector3.UP * 1.0, 3.5)
	await _picture("2_the_row_apart.png")
	var report := []
	for station: Dictionary in stations:
		var at: Vector3 = (station.root as Node3D).global_position
		var entry := {"kind": station.kind}
		# far: the approach has not begun
		await _stand(at + front * (far + 1.2) + Vector3.UP * 1.65, at + Vector3.UP * 1.0, 3.5)
		entry["t_far"] = snappedf(float(station.t), 0.01)
		entry["frame_far"] = int(station.frame)
		# near: as close as they come; the bodies follow at their own speed
		await _stand(at + front * (near - 0.1) + Vector3.UP * 1.65, at + Vector3.UP * 1.0, 3.5)
		entry["t_near"] = snappedf(float(station.t), 0.01)
		entry["frame_near"] = int(station.frame)
		entry["plaque"] = (station.plaque as Label3D).text if station.has("plaque") else ""
		if station.has("slides"): entry["slid_m"] = snappedf((station.slides as Node3D).position.x, 0.01)
		await _stand(at + front * 2.3 + study.global_basis.x * 0.5 + Vector3.UP * 1.55, at + Vector3.UP * 1.05, 0.1)
		await _picture("3_%s_near.png" % station.kind)
		report.append(entry)
	result["stations"] = report
	_check("far away every pair stands apart; near, each is as close as it comes", report.all(func(r): return float(r.t_far) <= 0.02 and float(r.t_near) >= 0.98), {"t": report.map(func(r): return [r.kind, r.t_far, r.t_near])})
	_check("the frames follow: first frame far, last frame near", report.all(func(r): return r.kind == "through" or (int(r.frame_far) == 0 and int(r.frame_near) >= 7)), {"frames": report.map(func(r): return [r.kind, r.frame_far, r.frame_near])})
	var through: Dictionary = report.filter(func(r): return r.kind == "through")[0]
	_check("THROUGH slides one mesh into the other", float(through.slid_m) < -0.05, {"slid_m": through.slid_m})
	# SKIN: what the join is at each step of the approach
	var skin: Dictionary = stations.filter(func(s): return s.kind == "skin")[0]
	var rows: Array = skin.rows
	var story := rows.map(func(r): return [float(r.gap), int(r.get("pieces", 0)), int(r.get("handles", 0))])
	result["skin_story_gap_pieces_openings"] = story
	var first: Array = story.front()
	var joined_before_touch := story.any(func(s): return s[0] > 0.0 and s[1] == 1)
	var ring := story.any(func(s): return s[1] == 1 and s[2] >= 1)
	_check("SKIN: two bodies, then one body before they touch, then one body with an opening", first[1] == 2 and joined_before_touch and ring, {"story": story})
	var at_skin: Vector3 = (skin.root as Node3D).global_position
	for step in [[far + 1.0, "4_skin_far.png"], [(far + near) * 0.5 + 0.35, "5_skin_coming.png"], [(far + near) * 0.5 - 0.6, "6_skin_joined.png"], [near - 0.1, "7_skin_near.png"]]:
		await _stand(at_skin + front * float(step[0]) + Vector3.UP * 1.65, at_skin + Vector3.UP * 1.0, 3.5)
		var said := (skin.plaque as Label3D).text
		await _stand(at_skin + front * 2.1 + study.global_basis.x * 0.45 + Vector3.UP * 1.5, at_skin + Vector3.UP * 1.08, 0.05)
		await _picture(str(step[1]))
		(result.checks as Array).append({"check": "picture " + str(step[1]), "ok": true, "plaque": said})
	# what is drawn: every station at once
	var triangles := 0
	for station: Dictionary in stations:
		for node in (station.root as Node3D).find_children("*", "MeshInstance3D", true, false):
			var mesh := (node as MeshInstance3D).mesh
			if mesh == null or node.name == "Wire": continue
			for surface in mesh.get_surface_count():
				var arrays := mesh.surface_get_arrays(surface)
				triangles += (arrays[Mesh.ARRAY_INDEX] as PackedInt32Array).size() / 3 if arrays[Mesh.ARRAY_INDEX] != null else 0
	_check("the whole row draws a modest number of triangles", triangles > 2000 and triangles < 30000, {"triangles": triangles})
	await _stand(study.global_position + front * 5.2 - study.global_basis.x * 6.5 + Vector3.UP * 1.65, study.global_position + Vector3.UP * 1.0, 0.1)
	await _picture("8_the_row_from_its_end.png")
	_done()
