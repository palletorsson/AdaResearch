extends SceneTree
## The sticky-note board (sticky_map) photographed from the web page's own "Board" camera (0, middle of
## the board, 4.9 m out, 50 degrees vertical, 16:9), then the live watch tested: a changed copy of the map
## is written to user://sticky_maps/ (where the board reads first), the board must redraw within ~2 s,
## and the copy is removed again. Writes ada_run/sticky_map/{board.png, changed.png, report.json}.
func _init() -> void:
	var out_dir := ProjectSettings.globalize_path("res://ada_run/sticky_map");DirAccess.make_dir_recursive_absolute(out_dir)
	var env := WorldEnvironment.new();var e := Environment.new();e.background_mode = Environment.BG_COLOR;e.background_color = Color("2a2c33")
	e.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;e.ambient_light_color = Color("e2ddd4");e.ambient_light_energy = .8;env.environment = e;root.add_child(env)
	var sun := DirectionalLight3D.new();sun.rotation_degrees = Vector3(-38, 16, 0);sun.light_energy = .9;root.add_child(sun)
	var floor_m := MeshInstance3D.new();var fb := BoxMesh.new();fb.size = Vector3(12, .1, 8);floor_m.mesh = fb;floor_m.position = Vector3(0, -.05, 2)
	var fmat := StandardMaterial3D.new();fmat.albedo_color = Color("8f8a84");floor_m.material_override = fmat;root.add_child(floor_m)
	var map_id: String = OS.get_cmdline_user_args()[0] if OS.get_cmdline_user_args().size() > 0 else "ai_assemblage"   # -- <map>
	var board: Node3D = load("res://commons/artifacts/sticky_map/sticky_map.tscn").instantiate();board.set("map_id", map_id);root.add_child(board)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/sticky_maps/%s.json" % map_id))
	var cy := float(data.board.bottom) + float(data.board.height) / 2.0
	var R := float(data.board.get("radius", 0.0)) if str(data.board.get("shape", "flat")) == "arc" else 0.0
	var cam := Camera3D.new();cam.transform = Transform3D(Basis(), Vector3(0, cy, 4.9)).looking_at(Vector3(0, cy, 0));cam.fov = 50;root.add_child(cam);cam.current = true
	if R > 0.0:   # the page's Board camera for an arc: further back and a little above
		cam.transform = Transform3D(Basis(), Vector3(0, cy + .5, maxf(4.9, 2.7 * R))).looking_at(Vector3(0, cy - .15, .35 * R))
	for i in 20:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("board.png"))
	if R > 0.0:   # and from inside, standing at the axis with the page's wide eye
		cam.transform = Transform3D(Basis(), Vector3(0, 1.6, R)).looking_at(Vector3(0, 1.6, 0));cam.fov = 75
		for i in 6:
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out_dir.path_join("inside.png"))
		cam.transform = Transform3D(Basis(), Vector3(0, cy + .5, maxf(4.9, 2.7 * R))).looking_at(Vector3(0, cy - .15, .35 * R));cam.fov = 50
	var report := {"map": map_id, "radius": R, "notes": board.find_children("Note_*", "", false, false).size(), "needles": board.find_children("Needle_*", "", false, false).size(), "links": (data.links as Array).size()}
	# the watch: a changed copy where the board reads first
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("user://sticky_maps"))
	var changed: Dictionary = data.duplicate(true)
	for n in changed.notes:
		if n.id == "minus":n.title = "8 · The minus operation (moved)";n.x = -1.9;n.y = 0.75
	var f := FileAccess.open("user://sticky_maps/%s.json" % map_id, FileAccess.WRITE);f.store_string(JSON.stringify(changed));f.close()
	var t0 := Time.get_ticks_msec();var redrawn := false
	var want: float = (board.call("bend", Vector3(-1.9, .75, .012)) as Vector3).x   # where the moved note stands: -1.9 itself on a flat board
	while Time.get_ticks_msec() - t0 < 4000:
		await process_frame
		var note: Node3D = board.get_node_or_null("Note_minus")
		if note != null and not note.is_queued_for_deletion() and absf(note.position.x - want) < .001:redrawn = true;break
	report["redrawn_after_ms"] = Time.get_ticks_msec() - t0 if redrawn else -1
	for i in 10:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out_dir.path_join("changed.png"))
	DirAccess.remove_absolute(ProjectSettings.globalize_path("user://sticky_maps/%s.json" % map_id))   # never leave a copy that would shadow the file
	report["copy_removed"] = not FileAccess.file_exists("user://sticky_maps/%s.json" % map_id)
	var out := FileAccess.open(out_dir.path_join("report.json"), FileAccess.WRITE);out.store_string(JSON.stringify(report, "  "));out.close()
	quit(0)
