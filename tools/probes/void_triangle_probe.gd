extends "res://tools/probes/void_game_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	await triangle_contract()
	await desktop_descent()
	await frames(120)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual Godot artifacts; synthetic XR controllers and native desktop movement. Not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func triangle_contract() -> void:
	await start(true)
	game.checkpoint = 4
	game.place_player(game.spawn_for(4))
	await frames(60)
	var content: Node3D = game.building.content
	var deadline := Time.get_ticks_msec()+15000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		OS.delay_msec(5)
		await frames(1)
	check("floor 05 is the existing Triangle hall", content.data.floors[5].map == "Point_Triangle_Context")
	check("all four areas finish loading", content.exhibits.has("5/assembly") and content.pending.is_empty())
	if not content.exhibits.has("5/drawing"): return
	var area: Node3D = content.exhibits["5/drawing"].get_node("Artifact")
	var drawing: Node3D = area.get_node("Drawing")
	var twin: Node3D = area.get_node("LiveTwin")
	check("preloading does not consume the first visit", not area.drawing_entered and game.floor_stream.records[5].mode=="preview")
	var archive: Node = root.get_node("TraceData")
	var point: RigidBody3D = content.exhibits["4/record"].get_node("Artifact/ShadowPoint").point
	game.place_player(point.global_position+Vector3(0,-1,1))
	await frames(20)
	hand_at(right,point.global_position); await frames(15)
	right.set_input("grip",1.0); await frames(20)
	check("actual Trace point can be picked up",game.pickups[1].picked_up_object==point)
	var begin := point.global_position
	for i in range(22):
		hand_at(right,begin+Vector3(i*.10,sin(i*.3)*.25,sin(i*.21)*.45))
		await frames(3)
	right.set_input("grip",0.0); await frames(20)
	check("release records the drawing after Triangle has preloaded",archive.saved_traces.size()==1 and archive.saved_traces[0].size()>8)
	if archive.saved_traces.is_empty(): return
	var source: Array = archive.saved_traces[0].duplicate()
	var grid: Node3D = content.exhibits["4/record"].get_node("Artifact/GridReplay/SavedTraceGrid")
	check("Grid still receives the original on Trace",grid._trace_data_list[0].raw_points==source)
	game.place_player(Vector3(13.3,-23.94,-1.65)); await frames(20)
	check("XR descends to first timber landing",await move_to(Vector3(11,-27,-1.65)))
	check("intermediate landing keeps Trace checkpoint",game.checkpoint==4 and game.deaths==0)
	check("XR jumps to Triangle landing",await move_to(Vector3(11,-30,1.85),true))
	await frames(30)
	check("Triangle landing saves checkpoint 05",game.checkpoint==5 and game.deaths==0)
	check("XR steps onto solid Triangle slab",await move_to(Vector3(13.7,-30,4.3)))
	check("first live visit imports the late trace without closing it",area.drawing_entered and drawing.placed_points.size()>=3 and drawing.placed_points.size()<=6 and drawing.completed_triangles.is_empty())
	check("Triangle reads a copy; original world positions survive",archive.saved_traces[0]==source)
	check("large twin and monitor bind to this drawing",twin.source==drawing and area.get_node("FaceMonitor").source==drawing)
	check("carried outline closes through the existing control",drawing.close_current_face())
	await frames(20)
	check("closed drawing produces a face fan in the twin",twin.triangle_count==drawing.placed_points.size()-2 and twin.faces.mesh!=null)
	drawing.get_node("MuseumWorkbench").buttons.fill.pressed.emit()
	await frames(10)
	check("fill can hide while corners and edges remain",not twin.faces.visible and twin.edge_pairs.size()>0 and not drawing.placed_points.is_empty())
	drawing.get_node("MuseumWorkbench").buttons.fill.pressed.emit()
	check("restore supplies the same editable three-corner reference",twin.restore_reference())
	await frames(15)
	var handle: RigidBody3D = drawing.point_indicators[2]
	game.place_player(drawing.global_position+Vector3(0,-1.3,1.2)); await frames(15)
	hand_at(right,handle.global_position); await frames(15)
	right.set_input("grip",1.0); await frames(20)
	check("existing triangle corner is XR grabbable",game.pickups[1].picked_up_object==handle)
	var old_corner: Vector3 = drawing.placed_points[2]
	hand_at(right,handle.global_position+Vector3(.15,.15,0)); await frames(20)
	right.set_input("grip",0.0); await frames(15)
	check("editing a corner updates both scales",drawing.placed_points[2].distance_to(old_corner)>.1 and twin.large_points[2].is_equal_approx(twin.CENTRE+drawing.to_local(drawing.placed_points[2])*twin.ENLARGEMENT))
	var puzzle: Node3D = content.exhibits["5/arrival"].get_node("Artifact/ThreeEdges")
	check("closure reuses the original three-line puzzle",puzzle.snap_lines.size()==3 and puzzle.stock=="ringed")
	for i in range(3):
		var line: Node3D = puzzle.snap_lines[i]
		for j in range(2):
			var endpoint: Node3D = line.endpoint_a if j==0 else line.endpoint_b
			endpoint.global_position = puzzle.to_global(puzzle.target_positions[(i+j)%3])
			line._on_endpoint_dropped(endpoint,endpoint)
		line._update_line_geometry()
	puzzle._validate_puzzle(); await frames(5)
	check("three joined edges close without inventing a face",puzzle.is_completed and puzzle.discovery_face==null)
	puzzle.get_node("ExperimentPanel").buttons.fill.pressed.emit(); await frames(5)
	check("face appears only through the separate fill action",puzzle.discovery_face!=null and puzzle.discovery_face.visible)
	var surfaces: Node3D = content.exhibits["5/surfaces"].get_node("Artifact")
	var quad: Node3D = surfaces.get_node("SharedDiagonal")
	check("quad retains two faces sharing one diagonal",quad.triangle_a_indices==[0,1,2] and quad.triangle_b_indices==[0,2,3] and quad.triangle_mesh_a_front.mesh!=null)
	check("folded strip and four-edge boundary are original artifacts",surfaces.get_node("FoldedStrip").num_triangles==24 and surfaces.get_node("FourEdges").snap_lines.size()==4)
	var assembly: Node3D = content.exhibits["5/assembly"].get_node("Artifact")
	var table: Node3D = assembly.get_node("TriangleTable")
	check("assembly retains twelve pickable triangular pieces",table.pieces.size()==12 and table.pieces[0].has_method("is_picked_up"))
	var piece: RigidBody3D = table.pieces[0]
	game.place_player(piece.global_position+Vector3(0,-.84,1.2)); await frames(15)
	hand_at(right,piece.global_position); await frames(15)
	right.set_input("grip",1.0); await frames(20)
	check("XR grip takes a real assembly face",game.pickups[1].picked_up_object==piece)
	hand_at(right,piece.global_position+Vector3(0,.5,.1)); await frames(15)
	right.set_input("grip",0.0); await frames(15)
	check("released assembly face stays where placed",piece.freeze and piece.global_position.y> -29)
	if "--capture" in OS.get_cmdline_user_args():
		await photograph("closure.png",Vector3(18.6,-28.35,4.3),Vector3(16,-28.6,-.3))
		await photograph("drawing.png",Vector3(4.8,-28.35,3.0),Vector3(0,-28.7,-1.0))
		await photograph("surfaces.png",Vector3(-13.6,-28.35,4.9),Vector3(-16,-28.5,-1.0))
		await photograph("assembly.png",Vector3(3.0,-28.35,7.5),Vector3(0,-29.1,5.3))
	var original_pose: Transform3D = table.transform
	assembly.apply_grid_config({"parts":{"TriangleTable":{"position":[1,0,0],"rotation":[0,90,0]}}})
	check("editor placement moves and turns the real table",table.position.is_equal_approx(Vector3(1,0,0)) and is_equal_approx(table.rotation_degrees.y,90))
	table.transform=original_pose
	var duplicate: Node3D = load("res://commons/void/triangle_assembly.tscn").instantiate()
	duplicate.position=Vector3(5,-30,5.3)
	game.add_child(duplicate)
	duplicate.apply_grid_config({"only_parts":["TriangleTable"],"parts":{"TriangleTable":{"position":[0,0,0],"rotation":[0,90,0]}}})
	await frames(5)
	check("editor copy owns twelve independent pickable faces",duplicate.get_child_count()==1 and duplicate.get_node("TriangleTable").pieces.size()==12 and duplicate.get_node("TriangleTable").pieces[0]!=table.pieces[0])
	duplicate.queue_free(); await frames(5)
	var saved_points: Array = drawing.placed_points.duplicate()
	var identity := drawing.get_instance_id()
	game.place_player(game.spawn_for(4)); await frames(20)
	game.place_player(game.spawn_for(5)); await frames(20)
	check("return preserves edited geometry instead of reimporting",drawing.get_instance_id()==identity and drawing.placed_points==saved_points)
	game.die("Triangle retry"); await wait_for_recovery(0)
	check("retry restores Triangle and keeps drawing/archive",game.checkpoint==5 and not game.recovering and drawing.placed_points==saved_points and archive.saved_traces[0]==source)
	game.queue_free(); await frames(15)
	archive.clear_traces()
	for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func desktop_descent() -> void:
	await start(false)
	game.checkpoint=4
	game.place_player(Vector3(13.3,-23.94,-1.65)); await frames(20)
	check("desktop reaches the intermediate landing",await move_to(Vector3(11,-27,-1.65)))
	check("desktop jumps down to Triangle",await move_to(Vector3(11,-30,1.85),true))
	check("desktop saves Triangle checkpoint",game.checkpoint==5 and game.deaths==0)
	var area: Node3D = game.building.content.exhibits["5/drawing"].get_node("Artifact")
	await frames(30)
	check("visitor without a trace gets an editable triangle",area.get_node("Drawing").placed_points.size()==3 and area.get_node("LiveTwin").triangle_count==1)
	var route_ok := true
	for stop in game.building.content.data.floors[5].route:
		if not await move_to(Vector3(stop.position[0],-30,stop.position[1])):
			route_ok = false
			print("[void] blocked Triangle route: ",stop.label)
			break
	check("entire authored route reaches all four areas on the slab",route_ok and game.checkpoint==5 and game.deaths==0)
	game.queue_free(); await frames(15)

func photograph(filename: String, at: Vector3, target: Vector3, field_of_view := 75.0) -> void:
	game.status.hide()
	game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	var cam := Camera3D.new()
	cam.fov=field_of_view
	root.add_child(cam)
	cam.environment=game.atmosphere.environment
	cam.position=at; cam.look_at(target); cam.make_current()
	root.msaa_3d=Viewport.MSAA_4X
	await frames(20)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
	cam.queue_free(); await frames(2)
	game.camera.make_current()
