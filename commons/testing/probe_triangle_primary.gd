extends SceneTree
var checks := 0
var failures: Array[String] = []
var pointer: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
func run() -> void:
	DirAccess.make_dir_recursive_absolute("res://ada_run/triangle_primary")
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	pointer = Node3D.new()
	world.add_child(pointer)
	var puzzle = load("res://commons/primitives/line/puzzles/triangle_line_puzzle.tscn").instantiate()
	puzzle.set_meta("config_discovery","1")
	puzzle.position = Vector3(4,1.5,6)
	world.add_child(puzzle)
	for i in 5: await process_frame
	var panel: Node3D = puzzle.get_node("ExperimentPanel")
	press(panel.get_node("FillButton"))
	check(puzzle.discovery_face == null,"open boundary refuses fill button")
	var targets: Array = puzzle.target_positions
	for i in 3:
		var line = puzzle.snap_lines[i]
		line.endpoint_a.global_position = puzzle.to_global(targets[i])
		line.endpoint_b.global_position = puzzle.to_global(targets[(i+1)%3])
		line._update_line_geometry()
		line.endpoints_changed.emit(line.endpoint_a.global_position,line.endpoint_b.global_position)
		if i < 2: check(not puzzle.is_completed,"incomplete edge assembly stays open")
	check(puzzle.is_completed,"actual endpoint signals close triangle")
	check(puzzle.discovery_face == null,"closure alone adds no fill")
	press(panel.get_node("FillButton"))
	check(puzzle.discovery_face != null and puzzle.discovery_face.visible,"pointer press reveals face only after closure")
	var verts: PackedVector3Array = puzzle.discovery_face.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	check(verts.size()==3 and verts[1].is_equal_approx(targets[1]),"revealed face uses puzzle target geometry")
	press(panel.get_node("FillButton"))
	check(not puzzle.discovery_face.visible and puzzle.is_completed,"hide fill preserves closed boundary")
	press(panel.get_node("FillButton"))
	var tool = load("res://commons/primitives/point/draw_triangle_faces.tscn").instantiate()
	tool.set_meta("config_discovery","1")
	tool.position = Vector3(7,1.4,6)
	tool.rotation_degrees.y = 90
	world.add_child(tool)
	tool.set_process(false)
	var tpanel: Node3D = tool.get_node("ExperimentPanel")
	var tip: Node3D = tool.get("_draw_sphere")
	var points: Array[Vector3] = [Vector3(7,1.4,5.5),Vector3(7.6,1.4,5.5),Vector3(7.2,1.9,5.5)]
	tool.get_node("GrabPoint").picked_up.emit(tool.get_node("GrabPoint"))
	for pos in points:
		tip.global_position = pos
		tool.call("_process",1.01)
	tip.global_position = points[0]
	tool.call("_process",1.01)
	check(tool.completed_triangles.size()==1,"held point placements close one triangle")
	for i in 3:
		check(tool.point_indicators[i].global_position.is_equal_approx(points[i]),"editable corner agrees with world-space source in rotated translated artifact")
	tPanel_refresh(tpanel)
	check(tpanel.text_label.text.contains("Triangles: 1"),"one loop reports one fan triangle")
	check(tool.point_indicators[0].get_node("CornerNumber").get_meta("text") == "START 1","active first corner is marked")
	tool.get_node("GrabPoint").dropped.emit(tool.get_node("GrabPoint"))
	var n: int = tool.placed_points.size()
	tip.global_position += Vector3(1,1,0)
	tool.call("_process",2.0)
	check(not tool._is_grabbed and tool.placed_points.size()==n,"released moving handle cannot lay timed points")
	press(tpanel.get_node("FillButton"))
	check(not tool.completed_triangles[0].mesh.visible,"face visibility button hides completed fill")
	check(tool.line_mesh.get_surface_count()==1 and tool.line_mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size()==6,"closed triangle boundary survives hidden fill")
	press(tpanel.get_node("FillButton"))
	tool.point_indicators[1].global_position = Vector3(7.73,1.41,5.48)
	tool.point_indicators[1].dropped.emit(tool.point_indicators[1])
	check(tool.placed_points[1].is_equal_approx(Vector3(7.7,1.4,5.5)),"editing a corner snaps in world metres")
	check(tool.point_indicators[1].global_position.is_equal_approx(tool.placed_points[1]),"edited marker remains on stored vertex")
	press(tpanel.get_node("NewOutlineButton"))
	check(tool.current_path.is_empty() and tool.completed_triangles.size()==1,"new outline preserves completed face")
	tPanel_refresh(tpanel)
	check(tpanel.text_label.text.contains("Drawing first: --"),"new outline clears first-corner readout")
	await process_frame
	await process_frame
	for p in [panel,tpanel]:
		var label: Label = p.text_label
		var viewport: SubViewport = p.surface.viewport
		check(label.get_minimum_size().x <= viewport.size.x-64 and label.get_minimum_size().y <= viewport.size.y-140,"flat status fits the fixed case")
		check(p.find_children("*","Label3D",true,false).is_empty(),"console lettering uses 2D surfaces")
		check(p.top_level,"console cannot lift the specimen during seating")
	check(tpanel.get_node("NewOutlineButton").get_parent()==tpanel,"all three actions share the same tilted frame")
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.global_position = Vector3(5.2,2.8,9.2)
		camera.look_at(Vector3(5.5,1.35,6))
		camera.current = true
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.10,0.12,0.15)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color.WHITE
		env.environment.ambient_light_energy = 0.8
		world.add_child(env)
		await create_timer(0.8).timeout
		await RenderingServer.frame_post_draw
		for pair in [[puzzle,panel,"puzzle"],[tool,tpanel,"drawing"]]:
			var body: Node3D = pair[0]
			var instrument: Node3D = pair[1]
			var aim: Vector3 = (body.global_position + instrument.global_position)*0.5
			camera.global_position = aim + instrument.global_basis.z*2.2 + Vector3.UP*0.22 + instrument.global_basis.x*0.15
			camera.look_at(aim)
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/triangle_primary/"+pair[2]+".png")
	FileAccess.open("res://ada_run/triangle_primary/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"scope":"Actual endpoint and pointer events, supplied held positions, rotated translated scenes; headset usability unverified."},"  "))
	print("RESULT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)
func tPanel_refresh(panel: Node) -> void:
	panel.update_readout()
