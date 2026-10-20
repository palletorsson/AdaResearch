extends "res://tools/probes/void_triangle_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args(): await capture_room()
	else:
		await exercise_floor(false)
		await exercise_floor(true)
	OS.delay_msec(150)
	await frames(10)
	var filename := "capture-checks.json" if "--capture" in OS.get_cmdline_user_args() else "checks.json"
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Actual source artifacts, native movement and synthetic XR controllers. Not a physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive(use_xr: bool, descend := true) -> void:
	await start(use_xr)
	game.checkpoint=5 if descend else 6
	game.place_player(Vector3(13.3,-29.94,-1.65) if descend else Vector3(13.7,-35.94,4.3))
	await frames(60)
	var content: Node3D=game.building.content
	var deadline := Time.get_ticks_msec()+15000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		OS.delay_msec(5)
		await frames(1)
	if descend:
		check(("XR" if use_xr else "Desktop")+": reach intermediate timber",await move_to(Vector3(11,-33,-1.65)))
		check("intermediate timber keeps Triangle checkpoint",game.checkpoint==5)
		check("jump onto Polyhedra landing",await move_to(Vector3(11,-36,1.85),true))
		await frames(20)
		check("landing saves floor 06 checkpoint",game.checkpoint==6 and game.deaths==0)

func cleanup(use_xr: bool) -> void:
	game.queue_free();await frames(15)
	root.get_node("TraceData").clear_traces()
	if use_xr:
		for tracker in [head,left,right]: XRServer.remove_tracker(tracker)

func exercise_floor(use_xr: bool) -> void:
	await arrive(use_xr)
	var tag := "XR: " if use_xr else "Desktop: "
	var content: Node3D=game.building.content
	check(tag+"Polyhedra occupies the next floor",content.data.floors[6].map=="Primitives_Polythedra")
	for item in content.data.floors[6].artifacts:
		check(tag+"loaded work area "+item.id,content.exhibits.has("6/"+str(item.id)))
	for stop in content.data.floors[6].route:
		var raised := str(stop.label) in ["04 / Climb the same profile","View the column and model","Around the model","Across the platform","Align with the descent wedge"]
		var target := Vector3(float(stop.position[0]),-35.1 if raised else -36,float(stop.position[1]))
		var reached: bool=await move_to(target)
		check(tag+str(stop.label),reached)
		if not reached:
			print("BLOCKED at ",game.body.global_position," wanted ",target)
			break
	check(tag+"route stays on this floor without damage",game.checkpoint==6 and game.deaths==0 and is_equal_approx(game.health.get_health(),100))
	for item in content.data.floors[6].props:
		var prop: Node3D=content.props["6/"+str(item.id)]
		check(tag+"editor pose: "+item.id,prop.position.is_equal_approx(Vector3(item.position[0],0,item.position[1])) and is_equal_approx(prop.rotation_degrees.y,float(item.facing)))
	var closure: Node3D=content.exhibits["6/closure"].get_node("Artifact")
	for title in ["AlignTetrahedron","AlignWedge"]:
		var instrument: Node3D=closure.get_node(title)
		check(tag+title+" uses the original alignment script",instrument.get_script().resource_path.ends_with("primitive_encounters/align_solid.gd") and not instrument.complete)
		if use_xr:
			game.place_player(instrument.global_position+Vector3(0,.06,1.5));await frames(15)
			hand_at(right,instrument.handle.global_position);await frames(15)
			right.set_input("grip",1.0);await frames(20)
			check(tag+"grip picks the loose vertex of "+title,game.pickups[1].picked_up_object==instrument.handle)
			hand_at(right,instrument.to_global(instrument.target_position));await frames(20)
			right.set_input("grip",0.0);await frames(75)
		else:
			instrument.handle.on_desktop_grab(null)
			instrument.handle.global_position=instrument.to_global(instrument.target_position)
			instrument.handle.on_desktop_drop(null);await frames(75)
		check(tag+title+" release creates its physical solid",instrument.complete and is_instance_valid(instrument.solid_body) and not instrument.solid_body.freeze)
		if not is_instance_valid(instrument.solid_body): continue
		var body: RigidBody3D=instrument.solid_body
		check(tag+title+" falls onto the slab",body.position.y<.8 and body.global_position.y> -36.1)
		if use_xr:
			hand_at(right,body.global_position+Vector3(0,.08,0));await frames(15)
			right.set_input("grip",1.0);await frames(20)
			check(tag+"completed "+title+" can be held",game.pickups[1].picked_up_object==body)
			hand_at(right,body.global_position+Vector3(0,1,.1));await frames(15)
			right.set_input("grip",0.0);await frames(50)
	var boundary: Node3D=content.exhibits["6/boundaries"].get_node("Artifact")
	var opened: Node3D=boundary.get_node("OpenTrihedron")
	var closed: Node3D=boundary.get_node("ClosedTetrahedron")
	check(tag+"open surface and closed body retain their face counts",opened._trihedron_geometry().faces.size()==3 and closed._tetrahedron_geometry().faces.size()==4)
	var monitor: Node3D=boundary.get_node("UnfoldingMonitor")
	monitor.discover_source();monitor.observe(.25)
	check(tag+"monitor observes its own real tetrahedron",monitor.source==closed and monitor.stage.record.points.size()==4 and monitor.stage.record.faces.size()==4)
	var before: Dictionary=closed._tetrahedron_geometry()
	monitor.activate("step");monitor.activate("route");monitor.activate("replay")
	check(tag+"monitor leaves original geometry unchanged",before==closed._tetrahedron_geometry())
	var pyramid: Node3D=boundary.get_node("EditablePyramid")
	var mesh: Mesh=pyramid.mesh_instance.mesh
	pyramid.handle_nodes.apex.position.x+=.2;await frames(5)
	check(tag+"existing apex rebuilds its faces",pyramid.mesh_instance.mesh!=mesh and pyramid.handle_nodes.size()==5)
	var support: Node3D=content.exhibits["6/support"].get_node("Artifact")
	var model: Node3D=support.get_node("WedgeMouseModel")
	check(tag+"same wedge becomes six-piece column and movable maze",support.get_node("WedgeColumn").pieces.size()==6 and model.pieces.size()==23)
	var mouse_before: Vector3=model.mouse.position
	model.joystick.set_angles_degrees(Vector2(0,-30));await frames(25)
	model.joystick.set_angles_degrees(Vector2.ZERO)
	check(tag+"existing joystick moves the wedge mouse",model.mouse.position.distance_to(mouse_before)>.025)
	if use_xr:
		var wall_piece: RigidBody3D=model.pieces[0]
		game.place_player(Vector3(-18.2,-35.04,0));await frames(20)
		hand_at(right,wall_piece.global_position);await frames(15)
		right.set_input("grip",1.0);await frames(20)
		check(tag+"maze wall remains grabbable on the platform",game.pickups[1].picked_up_object==wall_piece)
		hand_at(right,wall_piece.global_position+Vector3(0,.3,0));await frames(15)
		right.set_input("grip",0.0);await frames(10)
	# Editor copies instantiate the original factory, then isolate a named part.
	var copy: Node3D=load("res://commons/void/polyhedra_support.tscn").instantiate()
	game.add_child(copy)
	copy.apply_grid_config({"only_parts":["WedgeColumn"],"parts":{"WedgeColumn":{"position":[0,0,0],"rotation":[0,90,0]}}})
	check(tag+"independent editor copy retains the original six prisms",copy.get_child_count()==1 and copy.get_node("WedgeColumn").pieces.size()==6 and copy.get_node("WedgeColumn").pieces[0]!=support.get_node("WedgeColumn").pieces[0])
	copy.queue_free();await frames(10)
	var solid: Node3D=closure.get_node("AlignTetrahedron").solid_body
	if is_instance_valid(solid):
		var identity := solid.get_instance_id()
		game.place_player(game.spawn_for(5));await frames(20)
		game.place_player(game.spawn_for(6));await frames(20)
		check(tag+"return keeps the completed body",solid.get_instance_id()==identity and closure.get_node("AlignTetrahedron").complete)
		game.die("Polyhedra retry");await wait_for_recovery(0)
		check(tag+"retry keeps Polyhedra and completed work",game.checkpoint==6 and not game.recovering and closure.get_node("AlignTetrahedron").complete)
	await cleanup(use_xr)

func capture_room() -> void:
	await arrive(false,false)
	game._set_enabled(false)
	var boundary: Node3D=game.building.content.exhibits["6/boundaries"].get_node("Artifact")
	var monitor: Node3D=boundary.get_node("UnfoldingMonitor")
	monitor.discover_source();monitor.observe(.25)
	monitor.stage.running=false;monitor.stage.playhead=14;monitor.stage.refresh()
	monitor.refresh_once()
	for item in [
		["polyhedra-arrival.png",Vector3(13.5,-34.35,5.2),Vector3(16,-34.8,-.5),78],
		["polyhedra-boundaries.png",Vector3(-.8,-34.35,-.1),Vector3(-.5,-34.5,-5),83],
		["polyhedra-wedges.png",Vector3(5.6,-34.35,1.3),Vector3(-2,-35.1,5.5),80],
		["polyhedra-support.png",Vector3(-15.5,-34.35,5.8),Vector3(-18,-34.65,-.2),85],
		["polyhedra-model.png",Vector3(-18.25,-33.45,1.6),Vector3(-17.1,-34.1,-.3),80],
		["polyhedra-corner.png",Vector3(19.1,-34.35,-4.5),Vector3(17.7,-35,-6.7),78]
	]:
		await photograph(item[0],item[1],item[2],item[3])
		check("Native screenshot: "+item[0],FileAccess.file_exists(out.path_join(item[0])))
	await cleanup(false)
