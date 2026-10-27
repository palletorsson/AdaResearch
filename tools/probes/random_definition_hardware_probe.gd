extends "res://tools/probes/randomness_trial_probe.gd"
const Hardware = preload("res://commons/void/randomness_interface_hardware.gd")

func start(use_xr: bool) -> void:
	xr=use_xr;level=71
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/void.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(65);game.scene_loaded();game.scene_visible();await frames(35)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated user saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for mode in ([false] if "--diagnose" in OS.get_cmdline_user_args() else [false,true]):
		await encounter(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Mobile renderer; actual desktop mouse input and synthetic XR controllers. Physical headset not tested."},"\t"))
	print("RANDOM_HARDWARE_RESULT ",checks.size()," checks; failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func approach(source: Node3D, offset := Vector3(0,0,1.5)) -> void:
	var at:=source.to_global(offset);at.y=-425.94
	game.place_player(at)
	if not xr:game.camera.position=Vector3(0,1.65,0)
	await frames(20)

func shot(file: String, source: Node3D, at: Vector3, target: Vector3) -> void:
	if xr:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var player_at: Vector3=game.body.global_position
	game.place_player(Vector3(-18,-425.94,8.3))
	var care: Node3D=game.get_node("CareBody")
	care.process_mode=Node.PROCESS_MODE_DISABLED
	for mesh in care.find_children("*","GeometryInstance3D",true,false): mesh.hide()
	game.body.hide();game.get_node("CareBody").hide();game.get_node("XROrigin3D").hide()
	root.msaa_3d=Viewport.MSAA_4X
	await photograph(file,source.to_global(at),source.to_global(target))
	game.body.show();game.get_node("CareBody").show();game.get_node("XROrigin3D").show()
	care.process_mode=Node.PROCESS_MODE_INHERIT
	game.place_player(player_at);await frames(5)

func encounter(mode: bool) -> void:
	await start(mode)
	var tag: String="XR: " if xr else "Desktop: "
	check(tag+"real tower starts on floor 71",game.checkpoint==71 and game.building.content.data.floors[71].map=="Random_Definition")
	var room: Dictionary=game.building.content.data.floors[71]
	var placements: Array=room.artifacts.duplicate()
	placements.append_array(room.get("copies",[]))
	for item in placements:
		var source:=station(item.id)
		var hardware: Node3D=source.get_node_or_null("ArchitecturalHardware")
		check(tag+str(item.id)+" retains original controls and mounted case",hardware!=null and not source.find_children("*","CollisionObject3D",true,false).is_empty())
		if hardware==null:continue
		check(tag+str(item.id)+" connected to shared supply",hardware.has_node("HardwareSupply"))
		var pillar: bool=item.artifact=="slot_machine"
		var anchor: Node3D=hardware.get_node_or_null("PillarContact" if pillar else "SlabContact")
		check(tag+str(item.id)+" structural anchor exists",anchor!=null)
		if anchor:
			var at: Vector3=anchor.global_position
			var direction: Vector3=Vector3(0,0,signf(at.z)) if pillar else Vector3.UP
			var hit:=ray(at-direction*.13,at+direction*.13)
			check(tag+str(item.id)+" anchor meets actual building collision",not hit.is_empty())
		if pillar:check(tag+str(item.id)+" pedestal removed",source.get_node_or_null("Assembly/Pedestal")==null)
	var crank:=station("crank")
	await approach(crank,Vector3(0,0,1))
	await press(crank.find_child("Btn_0",true,false));await frames(180)
	check(tag+"CRANK completes one original PRNG step",crank._step_count==1)
	await press(crank.find_child("Btn_1",true,false))
	check(tag+"RESET restores crank state",crank._step_count==0)
	await shot("01-crank",crank,Vector3(1.9,1,2.6),Vector3(0,.8,0))
	var slot:=station("slots-1")
	await approach(slot)
	await press(slot.find_child("Btn_0",true,false));await frames(240)
	check(tag+"pillar slot PULL completes a spin",slot._total_spins==1)
	await press(slot.find_child("Btn_2",true,false))
	check(tag+"pillar slot RESET retains original behaviour",slot._total_spins==0)
	await shot("02-pillar-slot",slot,Vector3(1.5,1.9,2.5),Vector3(0,1.3,0))
	var seed:=station("seed")
	await approach(seed,Vector3(.84,0,1.6))
	await press(seed.get_node("Panel").find_child("Btn_2",true,false))
	check(tag+"seed witness discard changes only replay",seed.extra_on() and seed.column_colors(0)!=seed.column_colors(1))
	await press(seed.get_node("Panel").find_child("Btn_2",true,false))
	check(tag+"restoring procedure reproduces original colours",not seed.extra_on() and seed.column_colors(0)==seed.column_colors(1))
	var sampler: Node3D=seed._movement_sampler
	check(tag+"movement sampler has its own suspension",sampler.has_node("ArchitecturalHardware/SlabContact"))
	await approach(sampler)
	await grab(sampler.point)
	check(tag+"real grip starts movement recording",sampler.collecting)
	for i in 65:
		if xr:hand_at(right,sampler.to_global(Vector3(.23*sin(i*.1),1.13,.35)))
		else:game.camera.rotate_y(.002)
		await frames(1)
	await drop();await frames(10)
	check(tag+"release keeps movement as a shared seed",not sampler.collecting and seed._source_receipt.provider=="movement" and sampler.sample.samples.size()>=30)
	Hall.reset(seed)
	await shot("03-seed-and-movement",seed,Vector3(-3.5,2.2,5.7),Vector3(-.8,2.35,.25))
	var lava:=station("lava")
	await approach(lava)
	await press(lava._board.find_child("Btn_0",true,false))
	var heat: int=lava.heat
	await press(lava._board.find_child("Btn_2",true,false))
	check(tag+"lava HEAT changes the original capture experiment",lava.heat!=heat and not lava.baseline.is_empty())
	await press(lava._board.find_child("Btn_3",true,false))
	check(tag+"lava KEEP retains measured record",not lava.kept.is_empty())
	await press(lava._board.find_child("Btn_4",true,false))
	check(tag+"lava REPLAY reuses kept record",lava.current==lava.kept)
	await shot("04-lava",lava,Vector3(-2.5,2.3,5.4),Vector3(0,2,0))
	var geiger:=station("geiger")
	await approach(geiger)
	var rate: int=geiger.current.rate_per_second
	await press(geiger._board.find_child("Btn_3",true,false))
	check(tag+"Geiger RATE changes timing with seed held",geiger.current.rate_per_second!=rate and geiger.current.seed==geiger.baseline.seed)
	await press(geiger._board.find_child("Btn_7",true,false))
	await press(geiger._board.find_child("Btn_8",true,false))
	check(tag+"Geiger KEEP / REPLAY retains exact detections",not geiger.kept.is_empty() and geiger.current.events_us==geiger.kept.events_us)
	await shot("05-geiger",geiger,Vector3(2.3,2.1,4.3),Vector3(0,2,0))
	var ride:=station("ride")
	ride.enabled_motion=false;ride.restart(435)
	var sample: Vector3=ride.route_position(7)
	ride.restart(435)
	check(tag+"expanded route replays deterministically",ride.shaft_route and ride.route_position(7).is_equal_approx(sample) and ride.chosen_distance>5.0)
	var on_rim:=true
	for i in 216:
		var p: Vector3=ride.route_position(i*.1)
		if absf(p.x)<2.9 and absf(p.z)<3.4:on_rim=false
	check(tag+"route stays outside shaft across full out-and-back cycle",on_rim)
	check(tag+"shaft centre remains open",ray(Vector3(10,-425,0),Vector3(10,-426.5,0)).is_empty())
	await approach(ride,Vector3(0,0,5.0))
	await grab(ride.point)
	check(tag+"actual grip boards shaft-rim ride",ride.point.held())
	var before: Vector3=game.body.global_position
	ride.clock=2;ride.enabled_motion=true
	await frames(150)
	check(tag+"ride carries body on solid rim",game.body.global_position.distance_to(before)>.2 and game.body.is_on_floor() and not game.recovering)
	await drop();await frames(5)
	check(tag+"release ends carry",not ride.point.held() and not is_instance_valid(ride.rider))
	ride.enabled_motion=false
	await shot("06-shaft-ride",ride,Vector3(-5,2.7,6.5),Vector3(0,1.1,0))
	game.queue_free();await frames(6)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
