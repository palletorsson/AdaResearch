extends "res://tools/probes/void_trial_probe.gd"

func start(use_xr: bool) -> void:
	xr = use_xr
	if xr:
		head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
		left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-.3,1.2,-.4))
		right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO); right.set_input("primary",Vector2.ZERO)
	var scene: PackedScene = load("res://commons/void/void.tscn")
	var staged: Node3D = scene.instantiate()
	check("main tower satisfies staging scene type", is_instance_of(staged, load("res://addons/godot-xr-tools/staging/scene_base.gd")))
	game = staged
	game.force_xr = xr
	root.add_child(game); current_scene = game
	if not xr: game.body.scripted_input=true
	await frames(45)
	game.scene_loaded(); game.scene_visible()
	await frames(30)

func dock(platform: Node3D, far_bank: bool) -> bool:
	for i in range(1500):
		await frames(1)
		if not is_instance_valid(platform):return false
		var progress: float=platform.ride_progress()
		if far_bank and progress>.999 and not platform.is_moving and platform.return_timer>3.0:return true
		if not far_bank and progress<.001 and platform.waiting_to_start and platform.start_timer>2.5:return true
	return false


func turn_dock(turn: Node3D) -> bool:
	for i in range(1600):
		await frames(1)
		if is_zero_approx(turn.current_angle) and not turn.is_rotating and turn.pause_timer>4.5:return true
	return false


func growth_dock(growth: Node3D) -> bool:
	for i in range(1400):
		await frames(1)
		if is_equal_approx(growth.current_scale,growth.max_scale) and growth.pause_timer>4.5:return true
	return false



func walk_to(at: Vector3, tag: String) -> bool:
	var okay := await move_to(at,false,480)
	check(tag+"walk "+str(at),okay)
	return okay

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg=="--capture": take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated save directory",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for mode in ([false] if take_photos else [false,true]):
		await start(mode)
		var tag := "XR: " if mode else "Desktop: "
		var content: Node3D=game.building.content
		var museum_score: int=root.get_node("GameManager").player_score
		check(tag+"16-floor main tower with no trial session",game.trial_id.is_empty() and game.trial_session==null and content.data.floors.size()==16)
		check(tag+"direct start on Pre",game.checkpoint==13)
		check(tag+"pink artifact extensions removed",content.roots[13].find_children("Lead_*","",true,false).is_empty())
		check(tag+"original 16 Pre artifacts",content.data.floors[13].artifacts.size()==16)
		# Actual drop from the final Primitives floor onto Pre's cushion.
		game.checkpoint=12
		game.place_player(Vector3(-8.3,-71.94,1.9));await frames(160)
		check(tag+"Melencolia A shaft lands on Pre",game.checkpoint==13 and game.health.get_health()==100 and game.deaths==0)
		game.place_player(game.spawn_for(13));await frames(25)
		check(tag+"Pre wedge climbs to carried cube route",await move_to(Vector3(-6,-77,0)))
		check(tag+"walk into still cube",await move_to(Vector3(-5,-77,-2)))
		var score: Node=content.roots[13].get_node("LessonScore")
		check(tag+"collection is local to Pre",score.score==1 and root.get_node("GameManager").player_score==museum_score)
		check(tag+"return to box route",await move_to(Vector3(-5,-77,0)))
		game.health.set_health(60)
		check(tag+"step on health box",await move_to(Vector3(-3,-77,0)))
		await frames(45)
		var box: Node3D=content.exhibits["13/first-health"].get_node("Artifact")
		check(tag+"main tower reward heals its actual body",box.opened and is_equal_approx(game.health.get_health(),85))
		var old_root: Node3D=content.roots[13]
		game.die("Restart Pre");await wait_for_recovery(game.deaths-1)
		check(tag+"Pre restarts with closed boxes and local score reset",not is_instance_valid(old_root) and content.roots[13].get_node("LessonScore").score==0 and not content.exhibits["13/first-health"].get_node("Artifact").opened)
		old_root=content.roots[13]
		if take_photos:
			await pictures()
		else:
			await introduction(mode)
			check(tag+"Introduction retries preserve previous Pre instance",content.roots[13]==old_root)
			await translation(tag)
			check(tag+"tower pickups did not change museum save score",root.get_node("GameManager").player_score==museum_score)
		game.soundscape.set_process(false)
		for node in game.find_children("*","",true,false):
			if node is AudioStreamPlayer or node is AudioStreamPlayer3D: node.stop()
		game.queue_free();await frames(20)
		if mode:
			for item in [head,left,right]: XRServer.remove_tracker(item)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"physical_headset":"not tested"},"\t"))
	quit(0 if failed.is_empty() else 1)

func translation(tag: String) -> void:
	game.place_player(game.spawn_for(15));await frames(30)
	var content: Node3D=game.building.content
	var previous: Node3D=content.roots[14]
	var carrier: Node3D=content.roots[15].get_node("Construction/SuspendedPlatform")
	var platform: Node3D=carrier.platform
	check(tag+"Translation at actual tower depth",game.checkpoint==15 and is_equal_approx(carrier.ceiling_y,-84.36))
	game.place_player(Vector3(-19.9,-89.94,2.3));await frames(15)
	for at in [Vector3(-20.3,-90,2.3),Vector3(-20.3,-90,6),Vector3(-18,-89,6),Vector3(-16,-88,6),Vector3(-13,-87,6),Vector3(-10,-87,6),Vector3(-10,-87,5.4)]:
		if not await walk_to(at,tag):return
	check(tag+"Translation near dock",await dock(platform,false))
	if not await walk_to(Vector3(-10,-87,4),tag):return
	check(tag+"Translation actual passenger attaches",platform.carried_player==game.body)
	var b0:Vector3=game.body.global_position
	var e0:Vector3=game.camera.global_position
	var p0:Vector3=platform.global_position
	check(tag+"Translation reaches other bank",await dock(platform,true))
	var delta:Vector3=platform.global_position-p0
	check(tag+"Translation body and camera carried once",(game.body.global_position-b0-delta).length()<.09 and (game.camera.global_position-e0-delta).length()<.09)
	for at in [Vector3(-10,-87,-5.5),Vector3(-10,-87,-6),Vector3(-13,-87,-6),Vector3(-16,-88,-6),Vector3(-18,-89,-6),Vector3(-20.3,-90,-6)]:
		if not await walk_to(at,tag):return
	var before:int=game.deaths
	game.place_player(Vector3(-8,-86.94,0));await frames(120)
	check(tag+"last-floor shaft remains lethal",game.deaths==before+1)
	await wait_for_recovery(before)
	check(tag+"last-floor restart and health restored",game.checkpoint==15 and game.health.get_health()==100)
	check(tag+"Translation death preserves Introduction",content.roots[14]==previous)

func pictures() -> void:
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	game.status.hide();game.notice_time=-1
	await photograph("pre",Vector3(-11,-73.5,8),Vector3(3,-77,0))
	game.place_player(game.spawn_for(14));await frames(35)
	var encounter:Node3D=game.building.content.exhibits["14/sequence"].get_node("Artifact")
	var growth:Node3D=encounter.get_node("GrowingCube")
	growth.set_physics_process(false);growth.current_scale=growth.max_scale;growth.apply_scale()
	var turn:Node3D=encounter.get_node("TurningPlank")
	turn.set_physics_process(false);turn.current_angle=0;turn.mesh_instance.rotation_degrees.y=0;turn.static_body.transform=turn.mesh_instance.transform
	await photograph("introduction",Vector3(19.6,-78.9,7.9),Vector3(-4,-81.7,0))
	game.place_player(game.spawn_for(15));await frames(35)
	await photograph("translation",Vector3(-5.8,-85.4,0),Vector3(-12,-88,0))

func introduction(mode: bool) -> void:
	var deaths_before_walk: int = game.deaths
	var tag := "XR: " if mode else "Desktop: "
	game.checkpoint=13
	game.place_player(Vector3(11.7,-77.94,-1.9))
	await frames(140)
	check(tag+"original B drop reaches Introduction",game.checkpoint==14 and game.health.get_health()==100 and game.deaths==deaths_before_walk)
	if mode:
		head.set_pose("default",Transform3D(Basis.IDENTITY,Vector3(.22,1.65,.14)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(5)
	var room: Dictionary=game.building.content.data.floors[14]
	var grid: Node3D=game.building.content.roots[14].get_node("Construction")
	var encounter: Node3D=game.building.content.exhibits["14/sequence"].get_node("Artifact")
	var platform: Node3D=grid.get_node("SuspendedPlatform").platform
	var growth: Node3D=encounter.get_node("GrowingCube")
	var turn: Node3D=encounter.get_node("TurningPlank")
	var pier: StaticBody3D=turn.get_node("CentralSupport")
	var pier_pose := pier.global_transform
	var pier_hit := ray(Vector3(-2,-84.0+1.4,0),Vector3(1,-84.0+1.4,0))
	check(tag+"central column has solid support down to the floor",not pier_hit.is_empty() and pier_hit.collider==pier and is_equal_approx(pier.global_position.y,-84.0))
	check(tag+"shared saved construction is loaded",grid.items==room.construction)
	check(tag+"old divider walls and lamps removed",room.walls.is_empty() and room.props.is_empty())
	check(tag+"eight clamps connect to fixed pillar pairs",room.construction.filter(func(c):return c.kind=="collar").size()==8)
	for kind in ["Cube","Wedge","Truss","Deck","Collar"]:
		check(tag+kind+" retains batched mesh and collision",grid.get_node(kind+"Collision").get_child_count()>0 and grid.find_children(kind+"*","MultiMeshInstance3D",true,false).size()>0)
	check(tag+"original scale and rotation scripts retained",growth.get_script().get_base_script().resource_path.ends_with("scale_cube.gd") and turn.get_script().get_base_script().resource_path.ends_with("rotation_cube.gd"))
	check(tag+"extra rotation landing and controls removed",not encounter.has_node("AdjustableLanding"))
	check(tag+"order is translation rotation scale",platform.global_position.x>turn.global_position.x and turn.global_position.x>growth.global_position.x)
	check(tag+"main decks are two metres wide",room.construction.filter(func(c):return c.kind=="deck" and absf(c.position[0])<15).all(func(c):return absf(c.position[2])==.5))
	check(tag+"pipe runs are absent from the lesson floor",game.building.floor_details[14].find_children("*Riser*","",true,false).is_empty())
	check(tag+"all instruments, hazards and signs are editable",encounter.part_defaults.size()==6)
	for at in [Vector3(14,-84.0,-1.9),Vector3(18.4,-84.0,-1.9),Vector3(18.4,-84.0,-8.3),Vector3(16.0,-84.0,-8.3),Vector3(16.0,-84.0+1,-6),Vector3(16.0,-84.0+2,-4),Vector3(16.0,-84.0+3,0),Vector3(14.3,-84.0+3,0)]:
		if not await walk_to(at,tag):return
	check(tag+"three-metre deck stays in Introduction streaming scope",game.floor_stream.focus==14)
	check(tag+"suspended platform returns to start",await dock(platform,false))
	if not await walk_to(Vector3(12.55,-84.0+3,0),tag):return
	check(tag+"walking attaches rider",platform.carried_player==game.body)
	var b0:Vector3=game.body.global_position
	var e0:Vector3=game.camera.global_position
	var p0:Vector3=platform.global_position
	var basis0:Basis=platform.global_basis
	check(tag+"seven metre gap docks flush at both banks",platform.initial_position.is_equal_approx(Vector3(12.5,-84.0+2.5,0)) and platform.target_position.is_equal_approx(Vector3(7.5,-84.0+2.5,0)))
	check(tag+"moving platform reaches far bank",await dock(platform,true))
	var movement:Vector3=platform.global_position-p0
	check(tag+"translation carries body and view once",(game.body.global_position-b0-movement).length()<.09 and (game.camera.global_position-e0-movement).length()<.09)
	check(tag+"translation keeps size and facing",platform.global_basis.is_equal_approx(basis0))
	for at in [Vector3(6,-84.0+3,0),Vector3(3.3,-84.0+3,0)]:
		if not await walk_to(at,tag):return
	check(tag+"leaving platform releases passenger",not is_instance_valid(platform.carried_player))
	check(tag+"rotation reaches alignment in the middle",await turn_dock(turn))
	check(tag+"rotation keeps centre and dimensions",turn.global_position.is_equal_approx(Vector3(-.5,-84.0+2.9,0)) and turn.body_size().is_equal_approx(Vector3(6,.2,1)))
	if not await walk_to(Vector3(-4.3,-84.0+3,0),tag):return
	check(tag+"central support stays fixed while the plank turns",pier.global_transform.is_equal_approx(pier_pose))
	if not await walk_to(Vector3(-6.8,-84.0+3,0),tag):return
	check(tag+"scale reaches crossing height over A",await growth_dock(growth))
	check(tag+"scale keeps centre and matching collision",growth.global_position.is_equal_approx(Vector3(-10,-84.0+.5,0)) and growth.box_shape.size.is_equal_approx(Vector3.ONE*5))
	if not await walk_to(Vector3(-13.3,-84.0+3,0),tag):return
	for at in [Vector3(-16,-84.0+3,0),Vector3(-16,-84.0+2,4),Vector3(-16,-84.0+1,6),Vector3(-16,-84.0,8.3)]:
		if not await walk_to(at,tag):return
	check(tag+"complete continuous three-crossing walk keeps health",game.health.get_health()==100 and game.deaths==deaths_before_walk)
	# Walk to the existing A south-west descent pad without passing another gap.
	for at in [Vector3(-13.3,-84.0,4.2),Vector3(-13.3,-84.0,1.9)]:
		if not await walk_to(at,tag):return
	await move_to(Vector3(-11.7,-84.0,1.9),false,100);await frames(140)
	check(tag+"A corner still lands safely in Translation",game.checkpoint==15 and game.health.get_health()==100 and game.deaths==deaths_before_walk)
	game.place_player(game.spawn_for(14));await frames(25)
	check(tag+"no extra basin or kill zones",not room.has("basin") and encounter.find_children("*Pit*","Node3D",true,false).is_empty())
	for sample in [Vector3(0,-84.0+.06,2),Vector3(10,-84.0+.06,5),Vector3(-10,-84.0+.06,-5)]:
		game.place_player(sample);await frames(30)
		check(tag+"ordinary floor is safe "+str(sample),game.body.is_on_floor() and absf(game.body.global_position.y--84.0)<.1 and game.health.get_health()==100)
	for x in [10.0,-10.0]:
		game.place_player(game.spawn_for(14));await frames(25)
		var before:int=game.deaths
		# Offset from the moving bodies, inside each existing open shaft.
		game.place_player(Vector3(x,-84.0+3.06,-2.8))
		for i in range(240):
			await frames(1)
			if game.deaths>before:break
		check(tag+"shaft fall from raised route remains dangerous "+str(x),game.deaths==before+1)
		await wait_for_recovery(before)
		check(tag+"shaft fall restarts Introduction",game.checkpoint==14 and game.health.get_health()==100)
	check(tag+"reload retains six instrument and caption parts",game.building.content.exhibits["14/sequence"].get_node("Artifact").get_child_count()==6)


