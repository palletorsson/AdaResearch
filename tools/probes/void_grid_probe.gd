extends "res://tools/probes/void_game_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	await replay_contract()
	await frames(120)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed, "scope": "Actual Trace floor and Grid, retained drawing, editor placement/copy and synthetic XR grip/release. Not a physical headset test."}, "\t"))
	quit(0 if failed.is_empty() else 1)

func replay_contract() -> void:
	await start(true)
	game.checkpoint = 4
	game.place_player(game.spawn_for(4))
	await frames(30)
	var content: Node3D = game.building.content
	var deadline := Time.get_ticks_msec() + 10000
	while not content.pending.is_empty() and Time.get_ticks_msec() < deadline:
		OS.delay_msec(5)
		await process_frame
	check("Grid remains part of Trace rather than becoming a separate floor", content.data.floors[4].map == "Point_Trace" and content.data.floors[5].map != "Point_Line_Grid")
	var record: Node3D = content.exhibits["4/record"].get_node("Artifact")
	check("Grid is an editable part of Trace", record.has_node("GridReplay") and record.part_defaults.has("GridReplay"))
	var grid: Node3D = record.get_node("GridReplay/SavedTraceGrid")
	check("original Grid occupies shaft A one metre below Trace", grid.get_script().resource_path.ends_with("primitives/line/grid_lines.gd") and grid.global_position.is_equal_approx(Vector3(-10,-25,0)))
	check("Grid is live on the same floor as the drawing point", grid.is_visible_in_tree() and grid.can_process() and game.floor_stream.records[4].mode == "live")
	check("no invented drawing appears before release", grid._trace_data_list.is_empty())
	var archive: Node = root.get_node("TraceData")
	var drawing: Node3D = record.get_node("ShadowPoint")
	var point: RigidBody3D = drawing.point
	game.place_player(point.global_position + Vector3(0,-1.0,1.0))
	await frames(20)
	hand_at(right,point.global_position)
	await frames(15)
	right.set_input("grip",1.0)
	await frames(20)
	check("XR grip picks up the existing small black drawing point", game.pickups[1].picked_up_object == point)
	var begin := point.global_position
	for i in range(14):
		hand_at(right, begin + Vector3(i * .13, sin(i*.45)*.32, cos(i*.3)*.24))
		await frames(3)
	right.set_input("grip",0.0)
	await frames(90)
	check("XR release retains a world-space drawing", archive.saved_traces.size() == 1 and archive.saved_traces[0].size() > 8)
	if archive.saved_traces.is_empty(): return
	var original: Array = archive.saved_traces[0].duplicate()
	check("Grid immediately receives the same source positions", grid._trace_data_list.size() == 1 and grid._trace_data_list[0].raw_points == original)
	check("pink source and green snapped version are both present", is_instance_valid(grid._trace_data_list[0].visual) and is_instance_valid(grid._trace_data_list[0].shadow))
	check("readout controls stand at reachable height on the west rim", grid._data_panel.global_position.is_equal_approx(Vector3(-13.1,-22.8,1.8)))
	check("readout support meets the Trace slab", is_equal_approx(grid.get_node("ArchiveFoot").global_position.y,-23.98))
	grid.point_selection.select_point(4)
	await frames(10)
	check("selection preserves the source identity", grid.point_selection.point_index == 4 and grid.point_selection.record().raw_points == original)
	grid.get_node("ArchivePanel/NextPage").pressed.emit()
	await frames(5)
	check("paging and display changes leave archived points untouched", archive.saved_traces[0] == original)
	check("lattice leaves the shaft open for falling", ray(Vector3(-10,-24.2,0),Vector3(-10,-31,0)).is_empty())
	check("existing timber descent remains in shaft B", content.exhibits.has("4/descent") and not ray(Vector3(11,-20.9,-1.65),Vector3(11,-21.2,-1.65)).is_empty())
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("from-trace.png", Vector3(-6.6,-22.35,3.4), Vector3(-10,-24.6,0))
		await photograph("grid-rim.png", Vector3(-14.8,-22.35,5.8), Vector3(-11.5,-23.7,0))
		await photograph("trace-floor.png", Vector3(3,-22.35,6.5), Vector3(-8,-23.5,0))
	# Exercise the same per-part edits and copy path used by the lab editor.
	var old_position: Vector3 = record.get_node("GridReplay").position
	record.apply_grid_config({"parts":{"GridReplay":{"position":[-4.2,0,0.6],"rotation":[0,0,0]}}})
	check("editor part placement reaches the native grid", grid.global_position.is_equal_approx(Vector3(-9.5,-25,0)))
	record.get_node("GridReplay").position = old_position
	var copy: Node3D = load("res://commons/void/trace_record.tscn").instantiate()
	copy.position = Vector3(0,-24,0)
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["GridReplay"],"parts":{"GridReplay":{"position":[-6.7,0,1.8],"rotation":[0,90,0]}}})
	await frames(90)
	check("copy contains only Grid and keeps its saved trace", copy.get_child_count() == 1 and copy.get_node("GridReplay/SavedTraceGrid")._trace_data_list[0].raw_points == original)
	check("copied Grid retains editable facing", is_equal_approx(copy.get_node("GridReplay").rotation_degrees.y,90))
	copy.queue_free()
	await frames(5)
	var identity := grid.get_instance_id()
	game.place_player(game.spawn_for(0))
	await frames(15)
	check("Grid sleeps with Trace when leaving the floor", not grid.can_process())
	game.place_player(game.spawn_for(4))
	await frames(30)
	check("return restores the same Grid and drawing", grid.get_instance_id() == identity and grid.can_process() and archive.saved_traces[0] == original)
	game.die("Grid retry")
	await wait_for_recovery(0)
	check("retry returns to Trace without deleting the drawing", game.checkpoint == 4 and not game.recovering and archive.saved_traces[0] == original)
	game.queue_free()
	await frames(10)
	archive.clear_traces()
	for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	game.status.hide()
	game.notice_time = -1
	for layer in game.find_children("*", "CanvasLayer", true, false): layer.hide()
	var cam := Camera3D.new()
	root.add_child(cam)
	cam.environment = game.atmosphere.environment
	cam.position = at
	cam.look_at(target)
	cam.make_current()
	root.msaa_3d = Viewport.MSAA_4X
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
	cam.queue_free()
	await frames(2)
	game.camera.make_current()
