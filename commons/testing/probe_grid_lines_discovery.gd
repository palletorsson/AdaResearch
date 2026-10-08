extends SceneTree
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ") + label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://ada_run/grid_lines_discovery")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var store_node := root.get_node("TraceData")
	store_node.clear_traces()
	var museum: Node = load("res://commons/scenes/endless_museum.tscn").instantiate()
	museum.set("_studio",true)
	museum.set("_headless",true)
	var row: Dictionary = museum.call("_derive_map_row","Point_Line_Grid")
	for entry: Dictionary in row.artifacts:
		if entry.token != "grid_lines": continue
		check(museum.call("_stamp",world,"res://commons/primitives/line/grid_lines.tscn","grid_lines",
			{"x":0,"y":0,"top":-1.0},0,1,{},false,0.0,float(entry.rotation),entry.config),"museum stamps cased grid from current map token at basin depth")
	var grid: Node3D
	for child in world.get_children():
		if child.get_meta("artifact_lookup_name","") == "grid_lines": grid = child
	check(grid != null,"grid instance exists")
	if grid == null: quit(1); return
	grid.set_process(false)
	var label: Label = grid.get("_data_table_label")
	check(label.text.contains("No released trace yet"),"empty session explains how a trace arrives")
	check(grid.get_node_or_null("ArchivePanel/Casing") != null,"readout has casing")
	check(is_equal_approx(grid.get_node("ArchivePanel").global_position.y,1.2),"basin readout sits at 1.2m above deck")
	check(grid.get("rotation_speed") == 0,"this hall keeps the replay still")
	var line = grid.get_node("LineX1/lineContainer")
	check(line.start_pos.is_equal_approx(Vector3(-2.5,0,-2.5)) and line.end_pos.is_equal_approx(Vector3(2.5,0,-2.5)),"ruling has actual five-metre extent")
	check(grid.get_node("LineX3/lineContainer").line_color.g > 0.5,"half-metre-offset line is not labelled a red zero axis")
	var dot: Node3D = load("res://commons/primitives/point/draw_dot.tscn").instantiate()
	world.add_child(dot)
	dot.set_process(false)
	dot.set("record_only_when_grabbed",false)
	for i in range(12):
		dot.get_node("GrabPoint").global_position = Vector3(10+i*0.1,1.5+sin(i*0.5)*0.15,20+i*0.04)
		dot.call("_process",0.02)
	var source: Array = dot.get("_trail_points").duplicate()
	dot.get_node("GrabPoint").dropped.emit(dot.get_node("GrabPoint"))
	check(store_node.get_all_traces().size() == 1,"real dot drop publishes one snapshot")
	check(grid.get("_trace_data_list").size() == 1,"grid receives dot drop via session signal")
	check(label.text.contains("Latest: 12 points") and label.text.contains("SOURCE WORLD POSITIONS"),"table distinguishes source coordinates and latest point count")
	check(label.text.contains("x4.545") and label.text.contains("0.1667 m"),"readout declares actual rescaling and display snap pitch")
	check(label.text.contains("1 of 2"),"long source has declared pages")
	var replay: MeshInstance3D = grid.get_node("SavedTrace")
	var vertices: PackedVector3Array = replay.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var frame: Dictionary = grid.call("_display_frame",source)
	check(vertices.size() == 12 and vertices[0].is_equal_approx((source[0]-frame.center)*frame.scale),"display geometry recentres and scales the source")
	var lo := vertices[0]
	var hi := vertices[0]
	for v in vertices: lo = lo.min(v); hi = hi.max(v)
	check(is_equal_approx((hi-lo).x,5.0),"enlarged source fits the five-metre display")
	var shadow: MeshInstance3D = grid.get_node("ShadowTrace")
	var green: PackedVector3Array = shadow.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(green[0].is_equal_approx(vertices[0].snapped(Vector3.ONE/6.0)),"green replay rounds displayed positions in all three axes")
	dot.call("clear_trail")
	check(store_node.get_all_traces()[0].size() == 12 and grid.get("_trace_data_list")[0].raw_points.size() == 12,"clearing live dot preserves released snapshot")
	grid.call("_process",20.0)
	check(label.text.contains("1 of 2"),"museum archive holds its page until requested")
	# Dispatch actual pointer events to the physical button's Area3D.
	var pointer := Node3D.new()
	world.add_child(pointer)
	var buttons: Array = grid.get("_page_buttons")
	for action in [2,0,1]:
		var area: Area3D = buttons[action].get_node("InteractableAreaButton")
		area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,area,area.global_position,area.global_position))
		area.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.RELEASED,pointer,area,area.global_position,area.global_position))
		if action == 2: check(label.text.contains("2 of 2"),"physical NEXT reveals final source rows")
		if action == 0: check(label.text.contains("1 of 2"),"physical PREVIOUS restores first page")
	check(grid.get("_archive_auto") and buttons[1].is_selected(),"AUTO latches visibly through physical input")
	grid.call("_process",2.1)
	check(label.text.contains("2 of 2") and label.text.contains("12:"),"archive page exposes final source rows")
	var stationary: Basis = replay.basis
	grid.call("_process",0.2)
	check(replay.basis.is_equal_approx(stationary),"zero rotation leaves replay orientation fixed")
	grid.call("step_archive_page",1)
	check(label.text.contains("1 of 2") and not grid.get("_archive_auto") and not buttons[1].is_selected(), "manual next wraps and unlatches auto")
	grid.call("step_archive_page",-1)
	check(label.text.contains("2 of 2"), "previous wraps safely from first to last page")
	grid.call("_process",30.0)
	check(label.text.contains("2 of 2"), "manual page stays held after auto was interrupted")
	store_node.add_trace([Vector3.ZERO,Vector3(0.2,0.1,0)])
	check(label.text.contains("Latest: 2 points") and label.text.contains("1 of 1"),"new release resets page to latest source")
	check(grid.get("_trace_data_list")[0].raw_points[0] == source[0],"replay transformations do not alter original coordinates")
	await process_frame
	await process_frame
	var surface: MeshInstance3D = grid.get_node("ArchivePanel/PanelSurface")
	var viewport: SubViewport = grid.get_node("ArchivePanel/DataViewport")
	check(label.get_minimum_size().x <= viewport.size.x-64 and label.get_minimum_size().y <= viewport.size.y-140,"text fits the fixed flat viewport")
	var panel: Node3D = grid.get_node("ArchivePanel")
	var casing: MeshInstance3D = panel.get_node("Casing/Shell")
	var casing_in_grid: AABB = (panel.transform * casing.get_parent().transform * casing.transform) * casing.get_aabb()
	check(casing_in_grid.position.x > 2.5,"entire display casing sits outside the grid's right edge")
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.global_position = grid.global_position + Vector3(3.8,4.4,7.5)
		camera.look_at(grid.global_position + Vector3(1.2,0.9,0.5))
		camera.current = true
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.12,0.14,0.17)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color.WHITE
		env.environment.ambient_light_energy = 0.8
		world.add_child(env)
		await create_timer(1.2).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/grid_lines_discovery/preview.png")
	var report := {"checks":checks,"failures":failures,"scope":"Museum stamp at declared basin depth, actual dot drop signal and session store, replay mesh vertices, panel fit. Supplied motion; full museum access and headset reading unverified."}
	FileAccess.open("res://ada_run/grid_lines_discovery/checks.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	museum.free()
	print(JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
