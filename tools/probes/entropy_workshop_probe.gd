extends "res://tools/probes/random_definition_hardware_probe.gd"
func start(use_xr: bool) -> void:
	xr=use_xr;level=73
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

func artifact(kind: String) -> Node3D:
	for item in game.building.content.data.floors[level].artifacts:
		if item.artifact==kind:return station(item.id)
	return null

func stand(source: Node3D, local: Vector3) -> void:
	var at:=source.to_global(local);at.y=-437.94
	game.place_player(at);await frames(16)

func point_press(button: Node3D) -> void:
	# Signal Room's original StaticBody pointer receiver uses the same click path.
	if not xr:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(button.global_position)
		await frames(15)
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
		Input.parse_input_event(event);await frames(5)
		event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
		Input.parse_input_event(event);await frames(8)
	else:
		var at:Vector3=button.global_position+button.global_basis.z*.65
		var origin:Node3D=game.get_node("XROrigin3D")
		right.set_pose("aim",Transform3D(Basis.looking_at(button.global_position-at),origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(15);right.set_input("trigger_click",true);await frames(5)
		right.set_input("trigger_click",false);await frames(8)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated test saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for mode in ([false] if "--desktop-only" in OS.get_cmdline_user_args() else [false,true]):await workshop(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real desktop mouse/pickup and synthetic XR input in native Mobile renderer; physical headset not tested."},"\t"))
	print("ENTROPY_WORKSHOP_RESULT ",checks.size()," checks; failures ",failed)
	quit(0 if failed.is_empty() else 1)

func workshop(mode: bool) -> void:
	await start(mode)
	var tag: String="XR: " if xr else "Desktop: "
	check(tag+"Random Entropy starts on floor 73",game.checkpoint==73 and game.building.content.data.floors[73].map=="Random_Entropy")
	check(tag+"all ten existing artifacts retained",game.building.content.data.floors[73].artifacts.size()==10)
	for item in game.building.content.data.floors[73].artifacts:
		var source:=station(item.id)
		if item.artifact=="entropy_axiom":continue
		check(tag+item.artifact+" installed with grid connection",source.has_meta("entropy_workshop_installed") and not source.find_children("HardwareSupply","Node3D",true,false).is_empty())
		for contact in source.find_children("SlabContact*","Marker3D",true,false):
			check(tag+item.artifact+" anchor meets slab at "+str(contact.global_position),not ray(contact.global_position-Vector3.UP*.16,contact.global_position+Vector3.UP*.16).is_empty())
	for x in [-10,10]:check(tag+"shaft "+str(x)+" remains open",ray(Vector3(x,-437.6,0),Vector3(x,-438.5,0)).is_empty())
	var ledger:=artifact("shannon_entropy_meter")
	await stand(ledger,Vector3(0,0,2.30))
	var sequence:Array=ledger.get_sequence();var h:float=ledger.get_entropy()
	await press(ledger._panel.find_child("Btn_0",true,false));await frames(45)
	check(tag+"SORT changes neighbours without changing counts or H",ledger.sorted_view and ledger.get_sequence()==sequence and is_equal_approx(h,ledger.get_entropy()))
	await press(ledger._panel.find_child("Btn_1",true,false))
	check(tag+"CONTRAST changes colour shares and H",ledger.contrast and ledger.get_entropy()<h)
	await press(ledger._panel.find_child("Btn_2",true,false));await frames(12)
	check(tag+"DISCLOSE rebuild preserves the mounted controls",ledger._panel.has_node("WorkshopCarrier") and ledger.has_node("Staging/GaugeCarrier"))
	var states:=artifact("entropy_jar_states")
	await stand(states,Vector3(-1.9,0,1.35))
	await press(states.buttons["PAUSE"]);var elapsed:float=states.elapsed;await frames(15)
	check(tag+"PAUSE holds four eighty-bead specimens",states.paused and is_equal_approx(states.elapsed,elapsed) and states.jars.size()==4)
	await press(states.buttons["RESTART"])
	check(tag+"RESTART restores the comparison interval",not states.paused and states.elapsed<1)
	var jar:=artifact("entropy_jar")
	await stand(jar,Vector3(0,0,.65));await grab(jar._jar_body)
	check(tag+"jar remains pickable",jar._is_held)
	await drop();await frames(12)
	check(tag+"jar retains forty beads of each colour",jar._particles_a.size()==40 and jar._particles_b.size()==40)
	await stand(jar,Vector3(.55,0,.85));await press(jar.get_node("RackPanel").find_child("Btn_0",true,false))
	var c:=artifact("entropy_compartments")
	await stand(c,Vector3(0,0,1.45));await press(c.buttons["A LEFT -"])
	check(tag+"A LEFT changes macrostate through original callback",c.cursor==1 and c.history.size()==2)
	await press(c.buttons["KEEP"]);var saved:Dictionary=c.capture()
	await press(c.buttons["ONE SWAP"]);await press(c.buttons["REPLAY"]);await frames(70)
	check(tag+"KEEP and REPLAY retain site history",c.history.size()==saved.states.size())
	await press(c.buttons["RESET"])
	check(tag+"RESET restores compartment baseline",c.cursor==0 and c.history.size()==1)
	var sorting:=artifact("entropy_sorting_table")
	await stand(sorting,Vector3(.18,0,1.55));await press(sorting.button)
	for i in 500:
		if sorting.delivered==4:break
		await frames(1)
	check(tag+"DROP FOUR delivers one retained batch",sorting.delivered==4 and not sorting.delivering)
	await press(sorting.button)
	check(tag+"ADD DIVIDER changes the description",sorting.model.stage==1)
	var disorder:=artifact("prefab_disorder")
	await stand(disorder,Vector3(0,0,2.4));await press(disorder.buttons["HYBRIDS"])
	check(tag+"HYBRIDS keeps source controls alive",is_equal_approx(disorder.disorder,1.0))
	await press(disorder.buttons["ORIGINAL"])
	check(tag+"ORIGINAL reverses the assembly",is_zero_approx(disorder.disorder))
	var ruin:=artifact("entropy_ruin")
	var marker:Node3D=ruin.get_node("ExhibitStage/ReachConsole/StandingPosition")
	game.place_player(marker.global_position+Vector3.UP*.06);await frames(20)
	check(tag+"ruin operator stands on solid west bank",game.body.is_on_floor() and not game.recovering and game.body.global_position.x < -13)
	await press(ruin.controls["ONE STONE"]);await frames(80)
	check(tag+"ONE STONE releases one of 116 original stones",ruin.history.size()==1 and ruin.pieces.size()==116 and ruin.extracting<0)
	await press(ruin.controls["RESTORE"]);await frames(6)
	check(tag+"RESTORE rebuilds stone supports",ruin.history.is_empty() and not ruin.running)
	var decay:=artifact("hardware_entropy_decay")
	await stand(decay,Vector3(-2.9,0,1.2));var panel:Node3D=decay.get_node("ENTROPY_DECAY")
	var was_paused:bool=decay._paused
	var presses:Array[int]=[0]
	panel.find_child("Btn_1",true,false).pressed.connect(func():presses[0]+=1)
	await press(panel.find_child("Btn_1",true,false))
	check(tag+"weathering PAUSE triggers exactly once",presses[0]==1 and decay._paused!=was_paused)
	var signal_room:=artifact("signal_room")
	await stand(signal_room,Vector3(0,0,12.5));await point_press(signal_room.controls[2])
	check(tag+"CELLS changes Signal Room arrangement",signal_room.specimen.mode==2)
	var values:PackedByteArray=signal_room.specimen.values.duplicate()
	await point_press(signal_room.controls[0])
	check(tag+"ORDERED retains the same symbol population",signal_room.specimen.mode==0 and signal_room.specimen.values.size()==values.size())
	check(tag+"Signal Room retains curated position and storey fit",signal_room.get_parent().position.is_equal_approx(Vector3(1,0,25)) and signal_room.specimen.room_height==5.4)
	for contact in signal_room.find_children("LintelContact*","Marker3D",true,false):
		check(tag+"Signal Room carrier meets its own ceiling",not ray(contact.global_position-Vector3.UP*.25,contact.global_position+Vector3.UP*.12).is_empty())
	var axiom:=artifact("entropy_axiom")
	check(tag+"displacement enclosure preserves its original 1280 points",axiom.square_room and axiom.multimesh_instance.multimesh.instance_count==1280)
	if not xr:
		game.place_player(Vector3(-13,-437.94,4.1));await frames(12)
		for point in [Vector2(-15,3.8),Vector2(-16.2,2),Vector2(-15,-.5),Vector2(-14.4,-2.4)]:
			check(tag+"walk west work area "+str(point),await walk(Vector3(point.x,-437.99,point.y)))
		game.place_player(Vector3(6,-437.94,6));await frames(12)
		for point in [Vector2(12.8,6),Vector2(13.5,3.7),Vector2(13.5,-.8),Vector2(14.4,-2.8)]:
			check(tag+"walk east work area "+str(point),await walk(Vector3(point.x,-437.99,point.y)))
		game.place_player(Vector3(.8,-437.94,8.2));await frames(12)
		for point in [Vector2(.8,12.6),Vector2(3.7,12.6),Vector2(3.7,15)]:
			check(tag+"walk Signal Room threshold "+str(point),await walk(Vector3(point.x,-437.99,point.y)))
		game.place_player(Vector3(-19,-437.94,8));await frames(12)
		for layer in game.find_children("*","CanvasLayer",true,false):
			if layer.get_viewport()==game.get_viewport():layer.hide()
		game.status.hide();game.notice_time=-1
		game.get_node("CareBody").process_mode=Node.PROCESS_MODE_DISABLED
		for mesh in game.get_node("CareBody").find_children("*","GeometryInstance3D",true,false):mesh.hide()
		game.body.hide();game.get_node("XROrigin3D").hide();root.msaa_3d=Viewport.MSAA_4X
		await photograph("01-ledger-and-jars",Vector3(-16.3,-436.35,7.7),Vector3(-15,-436.8,5.5))
		await photograph("02-four-starts",Vector3(-11,-436.35,8.5),Vector3(-9,-436.5,6))
		await photograph("03-workshop-bays",Vector3(13,-436.35,3.7),Vector3(16,-436.5,-5))
		await photograph("04-ruin-controls",Vector3(-16,-436.35,.2),Vector3(-13,-436.6,-5))
		await photograph("05-signal-room",Vector3(1,-436.35,8),Vector3(1,-436.4,18))
	await create_timer(.65).timeout
	game.queue_free();await frames(12)
	if xr:
		for t in [head,left,right]:XRServer.remove_tracker(t)

