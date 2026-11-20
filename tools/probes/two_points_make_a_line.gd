extends SceneTree
## Point_Lines, floor 3: the row "point-room" (line_black_box as an open station with a door, join_gate) as it
## stands. What does the wall say before the two points are joined, at the join, and when a joined end is
## turned? Written to check one sung line against the floor: "Joined, a length. Turn it: the number wanders."
##
## The probe has no hands. The join is made the way a release makes it (the station's own
## SnapConnectionManager.create_connection), and a held end is stood where a hand would carry it: on an exact
## arc, then on an arc with a 2 cm sway, which is the probe's assumption about a hand and is reported as one.
##
##   python tools/run_floor_probe.py Point_Lines two_points_make_a_line.gd two_points.json <folder> --no-opening
##
## <out>/two_points.json, before.png, joined.png, turned.png

var game: Node
var folder := "res://ada_run/two_points"
var result := {}
var eye: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _check(what: String, ok: bool, more := {}) -> bool:
	var row := {"check": what, "ok": ok}
	row.merge(more)
	(result.checks as Array).append(row)
	return ok


func _picture(file: String) -> void:
	for i in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(folder.path_join(file))


func _stand(point: RigidBody3D, at: Vector3) -> void:
	# A point that has never been held is not frozen yet and can slip back; it is stood until it stays.
	for attempt in 6:
		point.freeze = true
		point.global_position = at
		PhysicsServer3D.body_set_state(point.get_rid(), PhysicsServer3D.BODY_STATE_TRANSFORM, Transform3D(point.global_transform.basis, at))
		point.linear_velocity = Vector3.ZERO
		point.angular_velocity = Vector3.ZERO
		for i in 4: await physics_frame
		for i in 2: await process_frame
		if point.global_position.distance_to(at) < 0.001: return
	result["a_point_would_not_stay"] = true


func _done() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("two_points.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()
	quit()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	result = {"floor": int(game.checkpoint), "checks": [], "passed": false}
	for i in 900: await physics_frame
	eye = root.get_camera_3d()
	var mount := game.building.content.exhibits.get("%d/point-room" % int(game.checkpoint)) as Node3D
	var room := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if not _check("the row point-room stands on the floor", room != null):
		_done(); return
	var a := room.get("point_a") as RigidBody3D
	var b := room.get("point_b") as RigidBody3D
	var manager := room.get("connection_manager") as Node
	var readout := room.get("readout") as Label3D
	var gate := room.get("exit_gate") as Node3D
	result["station"] = {"open_station": room.get("open_station"), "join_gate": room.get("join_gate"),
		"words_on_the_wall": room.get_children().filter(func(n): return n is Label3D and n != readout).map(func(n): return (n as Label3D).text)}
	result["visitor_to_station_m"] = snappedf(game.body.global_position.distance_to(room.global_position), 0.01)
	game.body.set_physics_process(false)
	game.body.set_process(false)
	# the frame of this song is the designed view of the station
	var opera: Node = game.get_meta("inner_opera", null) as Node
	var frame: Node3D
	for node in get_nodes_in_group("song_fields"):
		if str(node.get("song_id")) == "chapter_03_line_black_box" and node.has_node("OperaFrame"): frame = node.get_node("OperaFrame") as Node3D
	var view_from := frame.to_global(Vector3(0, 0, 1.2)) if frame != null else room.to_global(Vector3(0.3, 1.5, 2.6))
	var view_at := frame.to_global(Vector3(0, 0, -4.0)) if frame != null else room.to_global(Vector3(-0.3, 1.3, 0))
	# 1. before the join: aside first, so that no line is cued by the look
	eye.global_position = room.to_global(Vector3(1.0, 1.6, 3.4))
	eye.look_at(room.to_global(Vector3(-0.2, 1.4, -0.6)), Vector3.UP)
	var apart: float = a.global_position.distance_to(b.global_position)
	result["before"] = {"readout": readout.text, "points_apart_m": snappedf(apart, 0.01), "joined": manager.call("are_points_connected", a, b),
		"door": "open" if gate != null and (gate.get("opened") or gate.get("opening")) else "shut"}
	_check("before the join the wall asks for the act and shows no number", not readout.text.contains(" m") and result.before.door == "shut", result.before)
	await _picture("before.png")
	# 2. the join: one point is brought to the other and released
	var heard_before: int = (opera.get("heard") as Array).size() if opera != null else 0
	await _stand(b, a.global_position + (b.global_position - a.global_position).normalized() * 0.10)
	var just_stood: float = a.global_position.distance_to(b.global_position)
	manager.call("create_connection", a, b)
	await physics_frame
	var a_frame_later: float = a.global_position.distance_to(b.global_position)
	for i in 30: await physics_frame
	for i in 4: await process_frame
	result["at_the_join"] = {"readout": readout.text, "points_apart_m": snappedf(a.global_position.distance_to(b.global_position), 0.001),
		"b_frozen": b.freeze, "b_sleeping": b.sleeping, "joined": manager.call("are_points_connected", a, b),
		"stood_at_m": snappedf(just_stood, 0.001), "one_frame_later_m": snappedf(a_frame_later, 0.001),
		"door": "opening" if gate != null and gate.get("opening") else ("open" if gate != null and gate.get("opened") else "shut")}
	_check("at the join a length stands on the wall and the door gives", readout.text.ends_with(" m") and result.at_the_join.door != "shut", result.at_the_join)
	# what the floor's progression made of it, and what the opera then sings through the frame
	var progression: Variant = opera.get("lines_progression") if opera != null else null
	result["progression_events"] = (progression.events as Array).filter(func(e): return e.object == "chapter_03_line_black_box") if progression != null else []
	eye.global_position = view_from
	eye.look_at(view_at, Vector3.UP)
	var sang := {}
	var waited := 0
	while opera != null and waited < 1800 and sang.is_empty():
		await physics_frame
		waited += 1
		var heard: Array = opera.get("heard")
		for i in range(heard_before, heard.size()):
			if str(heard[i].get("encounter", "")) == "chapter_03_line_black_box": sang = heard[i]
	result["sung_at_the_join"] = sang
	result["next_line"] = str(opera.call("_next_line", "chapter_03_line_black_box")) if opera != null else ""
	_check("the join is the cue: the opera sings this frame's line after it", bool(sang.get("sung", false)), {"take": sang.get("object", ""), "text": sang.get("text", ""), "after_s": snappedf(waited / 60.0, 0.1)})
	await _picture("joined.png")
	# 3. a joined end, carried
	var centre := a.global_position
	var out := (b.global_position - a.global_position)
	out.y = 0.0
	out = out.normalized()
	var readings := []
	await _stand(b, centre + out * 0.80)
	readings.append({"what": "drawn apart to 0.80 m", "readout": readout.text, "points_apart_m": snappedf(a.global_position.distance_to(b.global_position), 0.001)})
	await _stand(b, centre + out.rotated(Vector3.UP, deg_to_rad(30)) * 0.80)
	readings.append({"what": "turned 30 degrees on an exact arc", "readout": readout.text, "points_apart_m": snappedf(a.global_position.distance_to(b.global_position), 0.001)})
	_check("the number follows the points: an exact turn keeps it", readings[0].readout == readings[1].readout and readings[0].readout == "0.80 m", {"readings": readings})
	await _stand(b, centre + out.rotated(Vector3.UP, deg_to_rad(30)) * 0.83)
	readings.append({"what": "3 cm further out", "readout": readout.text})
	_check("nothing holds the length: 3 cm of hand is 3 cm on the wall", readout.text == "0.83 m", {"readout": readout.text})
	var swayed := []
	for step in 13:
		var angle := deg_to_rad(30.0 + 5.0 * step)
		await _stand(b, centre + out.rotated(Vector3.UP, angle) * (0.80 + 0.02 * sin(step * 1.7)))
		swayed.append(readout.text)
	var different := {}
	for text in swayed: different[text] = true
	result["a_turn_with_a_2_cm_sway"] = {"assumption": "a hand turning an end through 60 degrees strays 2 cm from the arc; the probe's figure, not a measured hand",
		"readouts": swayed, "different_numbers": different.size()}
	_check("turned by a hand that sways 2 cm, the wall shows more than one number", different.size() > 1, {"different_numbers": different.size()})
	result["readings"] = readings
	await _picture("turned.png")
	_done()
