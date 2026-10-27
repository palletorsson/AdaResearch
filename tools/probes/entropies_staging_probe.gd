extends "res://tools/probes/random_definition_hardware_probe.gd"

func start(use_xr: bool) -> void:
	xr=use_xr;level=72
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/void.tscn").instantiate();game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(65);game.scene_loaded();game.scene_visible();await frames(35)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	if not out.ends_with("before"):
		for mode in ([false] if "--desktop-only" in OS.get_cmdline_user_args() else [false,true]):await verify(mode)
		FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native desktop and synthetic XR; no physical headset test."},"\t"))
		print("ENTROPIES_STAGING_RESULT ",checks.size()," checks; failures ",failed)
		quit(0 if failed.is_empty() else 1);return
	await start(false)
	var report: Dictionary={}
	for item in game.building.content.data.floors[72].artifacts:
		var source:=station(item.id)
		var b:=AABB()
		var first:=true
		for mesh in source.find_children("*","MeshInstance3D",true,false):
			if mesh.mesh==null:continue
			var local: AABB=source.global_transform.affine_inverse()*mesh.global_transform*mesh.mesh.get_aabb()
			b=local if first else b.merge(local);first=false
		report[item.id]={"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]}
	FileAccess.open(out.path_join("measurements.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"\t"))
	print("ENTROPIES_MEASURE ",report)
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	game.place_player(Vector3(-18,-431.94,8.3))
	game.get_node("CareBody").process_mode=Node.PROCESS_MODE_DISABLED
	game.get_node("CareBody").hide()
	await photograph("overview",Vector3(0,-426,17),Vector3(0,-431,-3))
	print("ENTROPIES_STAGING_RESULT measured")
	quit()

func verify(mode: bool) -> void:
	await start(mode)
	var tag: String="XR: " if xr else "Desktop: "
	check(tag+"floor 72 retains the original nine placements",game.checkpoint==72 and game.building.content.data.floors[72].artifacts.size()==9)
	game.building.content.load_floor(73);await frames(5)
	var lower: Node3D=game.building.content.exhibits["73/f1_signal_room_12_48"].get_node("Artifact")
	check(tag+"Signal Room roof stays below this floor",Hardware._world_bounds(lower).end.y<=-432.36)
	var signal_study: Node3D=lower.specimen
	signal_study.set_pattern(2,435);var before: PackedByteArray=signal_study.values.duplicate();signal_study.step_rows()
	check(tag+"lower Signal Room retains values and row-shift behaviour",signal_study.values==before and signal_study.row_offset==1 and before.count(1)==2048)
	check(tag+"two partitions and four prefab props editable",game.building.content.data.floors[72].walls.size()==2 and game.building.content.data.floors[72].props.size()==4)
	for item in game.building.content.data.floors[72].artifacts:
		var source:=station(item.id)
		check(tag+item.id+" original source survives",source.get_script().resource_path.contains("ordinary_entropies") or item.id=="research")
		for contact in source.find_children("SlabContact*","Marker3D",true,false):
			var at: Vector3=contact.global_position
			check(tag+item.id+" mount touches the actual upper slab",not ray(at-Vector3.UP*.12,at+Vector3.UP*.12).is_empty())
	var reference: Node3D=station("reference").get_node("ReferenceChair")
	check(tag+"reference chair stands on this floor",absf(reference.global_position.y+432)<.05)
	check(tag+"four Shannon comparisons and three Boltzmann comparisons kept",station("shannon").versions.size()==4 and station("boltzmann").versions.size()==3)
	var cups:=station("cups")
	var heat0: Dictionary=Entropy.thermal(0);var heat60: Dictionary=Entropy.thermal(60)
	check(tag+"five cup snapshots preserve the original heat model",cups.versions.size()==5 and absf(heat0.energy-heat60.energy)<.01 and heat60.total>heat0.total)
	check(tag+"five frost panes retain declared information",station("frost").versions.size()==5 and station("frost").versions[2].setting==station("frost").versions[3].setting)
	for sx in [-10,10]:
		check(tag+"shaft stays open at "+str(sx),ray(Vector3(sx,-431.8,0),Vector3(sx,-432.6,0)).is_empty())
	# Real movement through the route. Stop at the front of each comparison,
	# rather than testing only abstract graph connectivity.
	game.place_player(Vector3(-6,-431.94,4.5));await frames(12)
	var route: Array[Vector2]=[Vector2(-11.2,4.2),Vector2(-11.2,7.8),Vector2(-13,7.8),Vector2(-13,4.5),Vector2(-13,.8),Vector2(-13,-1),Vector2(-13,-7.8),Vector2(-7.9,-7.8),Vector2(-7.9,-4.3),Vector2(0,-4.3),Vector2(0,-1.7),Vector2(0,1.4),Vector2(-3.4,3.7),Vector2(0,3.8),Vector2(6.2,3.8),Vector2(13.1,4.2),Vector2(16.7,6.5)]
	if not xr:
		for i in route.size():
			var reached:=await walk(Vector3(route[i].x,-431.99,route[i].y))
			check(tag+"walk tutorial waypoint "+str(i),reached)
			if not reached:break
		check(tag+"low divider is physically solid",not ray(Vector3(-17,-431.6,.6),Vector3(-17,-431.6,-.4)).is_empty())
	var doors:=station("doors")
	game.place_player(doors.to_global(Vector3(2.25,.06,1.15)));await frames(12)
	doors.reset_study();await frames(5)
	await press(doors.buttons["STEP"])
	check(tag+"STEP advances both original rules",doors.step_index==1)
	await press(doors.buttons["GAP +"])
	check(tag+"GAP changes initial separation",doors.gap_index==3 and doors.step_index==0)
	await press(doors.buttons["RESET"])
	check(tag+"RESET remains live",doors.step_index==0)
	var guesses:=station("guesses")
	for i in guesses.versions.size():
		var table: Node3D=guesses.versions[i]
		game.place_player(table.to_global(Vector3(0,.06,2.9)));await frames(12)
		await press(table.buttons["PINK"]);await press(table.buttons["DRAW"])
		check(tag+"pyramid "+str(i)+" original guess and draw",table.model.guess==0 and table.model.draws==1 and table.model.selected>=0)
		if table.buttons.has("CHANGE ONE"):
			var count: int=table.model.counts()[0]
			await press(table.buttons["CHANGE ONE"])
			check(tag+"pyramid "+str(i)+" changes a category",table.model.counts()[0]==count+1)
		await press(table.buttons["RESET"])
		check(tag+"pyramid "+str(i)+" resets same 16 chairs",table.model.draws==0 and table.chairs.size()==16)
	check(tag+"same best guess still differs in Shannon entropy",guesses.versions[0].model.readings().min==guesses.versions[1].model.readings().min and guesses.versions[1].model.readings().shannon==1.5)
	var table: Node3D=guesses.versions[0]
	var chair: Node3D=reference if xr else table.chairs[6]
	var at: Vector3=chair.global_position+Vector3(0,.06,1.2);at.y=-431.94
	game.place_player(at);await frames(12)
	await grab(chair,Vector3(0,.47,0));check(tag+"full-size chair remains grabbable",chair.held())
	await drop();await frames(12)
	check(tag+"moving a chair leaves colour probabilities intact",table.model.counts()==[8,8,0])
	if not xr:
		for layer in game.find_children("*","CanvasLayer",true,false):
			if layer.get_viewport()==game.get_viewport():layer.hide()
		game.status.hide();game.notice_time=-1
		game.place_player(Vector3(0,-431.94,8.3))
		game.get_node("CareBody").process_mode=Node.PROCESS_MODE_DISABLED
		for mesh in game.get_node("CareBody").find_children("*","GeometryInstance3D",true,false):mesh.hide()
		root.msaa_3d=Viewport.MSAA_4X
		await photograph("01-chair-comparisons",Vector3(-12.8,-430.35,6),Vector3(-17,-431.2,1))
		await photograph("02-recipes-and-doors",Vector3(-6.7,-430.35,-3.2),Vector3(0,-430.8,-5.5))
		await photograph("03-door-interface",doors.to_global(Vector3(3.7,1.65,2.8)),doors.to_global(Vector3(2.1,1.42,0)))
		await photograph("04-cups-and-frost",Vector3(-.5,-430.35,1.3),Vector3(-2,-431,4.3))
		await photograph("05-guess-consoles",Vector3(16.7,-430.35,7.7),Vector3(16.7,-430.7,.5))
	# XRTools restores collision pairs half a second after release. Let that
	# callback finish before tearing down the test's physics world.
	await create_timer(.65).timeout
	game.queue_free();await frames(10)
	if xr:
		for tracker_node in [head,left,right]:XRServer.remove_tracker(tracker_node)
