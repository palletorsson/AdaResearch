extends "res://tools/probes/introduction_sequence_probe.gd"
## Production bodies traverse the saved floor. No teleport between crossings.

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	if take_photos:
		await photos()
	else:
		for mode in [false,true]: await visit(mode)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Production desktop and synthetic XR; no physical headset test."},"\t"))
	quit(0 if failed.is_empty() else 1)

func finish(mode: bool) -> void:
	game.soundscape.set_process(false)
	for node in game.find_children("*","",true,false):
		if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.stop()
	OS.delay_msec(100)
	game.queue_free()
	await frames(20)
	if mode:
		for item in [head,left,right]:XRServer.remove_tracker(item)

func walk_to(at: Vector3,tag: String) -> bool:
	var okay := await move_to(at,false,480)
	check(tag+"walk "+str(at),okay)
	return okay

func visit(mode: bool) -> void:
	await start(mode)
	var tag := "XR: " if mode else "Desktop: "
	game.checkpoint=1
	game.place_player(Vector3(11.7,-5.94,-1.9))
	await frames(140)
	check(tag+"original B drop reaches Introduction",game.checkpoint==2 and game.health.get_health()==100 and game.deaths==0)
	if mode:
		head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(5)
	var room: Dictionary=game.building.content.data.floors[2]
	var grid: Node3D=game.building.content.roots[2].get_node("Construction")
	var encounter: Node3D=game.building.content.exhibits["2/sequence"].get_node("Artifact")
	var platform: Node3D=grid.get_node("SuspendedPlatform").platform
	var growth: Node3D=encounter.get_node("GrowingCube")
	var turn: Node3D=encounter.get_node("TurningPlank")
	var bank: Node3D=encounter.get_node("AdjustableLanding")
	check(tag+"shared saved construction is loaded",grid.items==room.construction)
	check(tag+"old divider walls and lamps removed",room.walls.is_empty() and room.props.is_empty())
	check(tag+"eight clamps connect to fixed pillar pairs",room.construction.filter(func(c):return c.kind=="collar").size()==8)
	for kind in ["Cube","Wedge","Truss","Deck","Collar"]:
		check(tag+kind+" retains batched mesh and collision",grid.get_node(kind+"Collision").get_child_count()>0 and grid.find_children(kind+"*","MultiMeshInstance3D",true,false).size()>0)
	check(tag+"original scale and rotation scripts retained",growth.get_script().get_base_script().resource_path.ends_with("scale_cube.gd") and turn.get_script().get_base_script().resource_path.ends_with("rotation_cube.gd"))
	check(tag+"original adjustable landing retained",bank.get_script().get_base_script().resource_path.ends_with("adjustable_landing.gd"))
	check(tag+"bank controls stand on the near deck",bank.control_rig.global_position.is_equal_approx(Vector3(-7,Y+3,1)))
	var support_hit := ray(Vector3(-7,Y+3.1,1.35),Vector3(-7,Y+2.8,1.35))
	check(tag+"player has solid deck beside bank controls",not support_hit.is_empty() and absf(support_hit.position.y-(Y+3))<.02)
	check(tag+"pipe runs are absent from the lesson floor",game.building.floor_details[2].find_children("*Riser*","",true,false).is_empty())
	check(tag+"all instruments, hazards and signs are editable",encounter.part_defaults.size()==7)
	for at in [Vector3(14,Y,-1.9),Vector3(18.4,Y,-1.9),Vector3(18.4,Y,-8.3),Vector3(16.5,Y,-8.3),Vector3(16.5,Y+1,-6),Vector3(16.5,Y+2,-4),Vector3(16.5,Y+3,0),Vector3(13.3,Y+3,0)]:
		if not await walk_to(at,tag):await finish(mode);return
	check(tag+"three-metre deck stays in Introduction streaming scope",game.floor_stream.focus==2)
	check(tag+"suspended platform returns to start",await dock(platform,false))
	if not await walk_to(Vector3(11.55,Y+3,0),tag):await finish(mode);return
	check(tag+"walking attaches rider",platform.carried_player==game.body)
	var b0:Vector3=game.body.global_position
	var e0:Vector3=game.camera.global_position
	var p0:Vector3=platform.global_position
	var basis0:Basis=platform.global_basis
	check(tag+"moving platform reaches far bank",await dock(platform,true))
	var movement:Vector3=platform.global_position-p0
	check(tag+"translation carries body and view once",(game.body.global_position-b0-movement).length()<.09 and (game.camera.global_position-e0-movement).length()<.09)
	check(tag+"translation keeps size and facing",platform.global_basis.is_equal_approx(basis0))
	for at in [Vector3(6.5,Y+3,0),Vector3(2.8,Y+3,0)]:
		if not await walk_to(at,tag):await finish(mode);return
	check(tag+"leaving platform releases passenger",not is_instance_valid(platform.carried_player))
	check(tag+"growth reaches crossing height",await growth_dock(growth))
	check(tag+"growth preserves centre and updates collision",growth.global_position.is_equal_approx(Vector3(0,Y+1.5,0)) and growth.box_shape.size.is_equal_approx(Vector3.ONE*3))
	if not await walk_to(Vector3(-2.8,Y+3,0),tag):await finish(mode);return
	if not await walk_to(Vector3(-7,Y+3,0),tag):await finish(mode);return
	# Exercise the original slider callback and reset, then restore the route.
	bank.slider.set_normalized_value(1.0);bank._on_slider(1.0)
	await frames(270)
	check(tag+"bank slider opens a metre gap",is_equal_approx(bank.displacement,1) and bank.readout.text.contains("GAP 1.00"))
	check(tag+"moving bank changes its support position",absf(bank.landing.global_position.x+14)<.01)
	bank.reset_landing();await frames(270)
	check(tag+"reset closes the gap",is_zero_approx(bank.displacement) and bank.readout.text.contains("EDGES MEET"))
	check(tag+"turning plank aligns",await turn_dock(turn))
	check(tag+"rotation keeps centre and dimensions",turn.global_position.is_equal_approx(Vector3(-10,Y+2.9,0)) and turn.body_size().is_equal_approx(Vector3(3,.2,1)))
	if not await walk_to(Vector3(-13,Y+3,0),tag):await finish(mode);return
	for at in [Vector3(-16.5,Y+3,0),Vector3(-16.5,Y+2,4),Vector3(-16.5,Y+1,6),Vector3(-16.5,Y,8.3)]:
		if not await walk_to(at,tag):await finish(mode);return
	check(tag+"complete continuous three-crossing walk keeps health",game.health.get_health()==100 and game.deaths==0)
	# Walk to the existing A south-west descent pad without passing another gap.
	for at in [Vector3(-13.3,Y,4.2),Vector3(-13.3,Y,1.9)]:
		if not await walk_to(at,tag):await finish(mode);return
	await move_to(Vector3(-11.7,Y,1.9),false,100);await frames(140)
	check(tag+"A corner still lands safely in Translation",game.checkpoint==3 and game.health.get_health()==100 and game.deaths==0)
	game.place_player(game.spawn_for(2));await frames(25)
	check(tag+"no extra basin or kill zones",not room.has("basin") and encounter.find_children("*Pit*","Node3D",true,false).is_empty())
	for sample in [Vector3(0,Y+.06,0),Vector3(10,Y+.06,5),Vector3(-10,Y+.06,-5)]:
		game.place_player(sample);await frames(30)
		check(tag+"ordinary floor is safe "+str(sample),game.body.is_on_floor() and absf(game.body.global_position.y-Y)<.1 and game.health.get_health()==100)
	for x in [10.0,-10.0]:
		game.place_player(game.spawn_for(2));await frames(25)
		var before:int=game.deaths
		# Offset from the moving bodies, inside each existing open shaft.
		game.place_player(Vector3(x,Y+3.06,-2.3))
		for i in range(240):
			await frames(1)
			if game.deaths>before:break
		check(tag+"shaft fall from raised route remains dangerous "+str(x),game.deaths==before+1)
		await wait_for_recovery(before)
		check(tag+"shaft fall restarts Introduction",game.checkpoint==2 and game.health.get_health()==100)
	check(tag+"reload retains seven instrument and caption parts",game.building.content.exhibits["2/sequence"].get_node("Artifact").get_child_count()==7)
	await finish(mode)

func photos() -> void:
	await start(true)
	game.place_player(game.spawn_for(2));await frames(40)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	game.get_node("XROrigin3D").hide();game.status.hide();game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	var encounter:Node3D=game.building.content.exhibits["2/sequence"].get_node("Artifact")
	var carrier:Node3D=game.building.content.roots[2].get_node("Construction/SuspendedPlatform")
	carrier.platform.set_physics_process(false)
	carrier.platform.global_position=carrier.to_global(Vector3(-1.5,-.5,0))
	carrier._update_suspension()
	var growth:Node3D=encounter.get_node("GrowingCube")
	growth.set_physics_process(false);growth.current_scale=3;growth.apply_scale()
	var turn:Node3D=encounter.get_node("TurningPlank")
	turn.set_physics_process(false);turn.current_angle=0;turn.mesh_instance.rotation_degrees.y=0
	turn.static_body.transform=turn.mesh_instance.transform
	await photo("whole-route",Vector3(19.6,Y+5.1,7.9),Vector3(-4,Y+2.3,0))
	await photo("move",Vector3(14.6,Y+4.65,.7),Vector3(7,Y+3.2,0))
	await photo("grow",Vector3(5,Y+4.65,1.5),Vector3(-1,Y+2.6,0))
	await photo("turn-and-bank",Vector3(-6,Y+4.65,1.8),Vector3(-12,Y+3.1,0))
	await photo("pillar-frame",Vector3(7,Y+1.7,5),Vector3(5,Y+2.6,7))
	await finish(true)
