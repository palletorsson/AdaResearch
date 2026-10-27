extends "res://tools/probes/logic_sequence.gd"
## Current main-tower route; normal movement, real colliders and native carriers.
var route_photos := false
var metres_start := 0.0

func start(use_xr: bool) -> void:
	xr=use_xr;Source.use_main_tower=true
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
	load("res://commons/void/game.gd").requested_floor=14
	game=load("res://commons/void/void.tscn").instantiate();game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":route_photos=true
	DirAccess.make_dir_recursive_absolute(out);root.size=Vector2i(1440,900)
	var modes: Array=[true] if "--xr-only" in OS.get_cmdline_user_args() else ([false] if "--desktop-only" in OS.get_cmdline_user_args() or "--photos-only" in OS.get_cmdline_user_args() else [false,true])
	for mode in modes:
		await start(mode)
		await visit_logic_floor(14)
		var tag := "Synthetic XR / " if xr else "Desktop / "
		if "--translation-only" in OS.get_cmdline_user_args():
			await visit_logic_floor(15);game.health.reset();metres_start=game.health.metres_travelled
			await translation(tag)
		elif not "--photos-only" in OS.get_cmdline_user_args():
			await pyramid_shortcuts(tag)
			game.place_player(game.spawn_for(14));await frames(25)
			game.health.reset();metres_start=game.health.metres_travelled
			var okay := await introduction(tag)
			if okay:await translation(tag)
		if route_photos and not xr:
			await visit_logic_floor(14)
			await image("introduction-ramp",Vector3(-17.7,-79.7,6.8),Vector3(-10,-82,0))
			await image("introduction-crossings",Vector3(-15,-79.4,1.7),Vector3(-10,-83,1.9))
			await visit_logic_floor(15)
			await image("translation-ramp",Vector3(-20.2,-87,8.5),Vector3(-12,-87.5,6))
			await image("translation-bridge",Vector3(17.3,-85.5,8.3),Vector3(10,-88,0))
		game.queue_free();await frames(20)
		if mode:
			for t in [head,left,right]:XRServer.remove_tracker(t)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,
		"modes":modes,"photos_only":"--photos-only" in OS.get_cmdline_user_args(),
		"scope":"Final pyramid-rim layout. Main floors 14/15: direct ground jumping attempts, continuous native ramp/bridge traversal, deliberate bridge-to-inner-rim jumps and ordinary corner-pad descent; desktop and synthetic XR. Not physical-headset acceptance or proof against every possible airborne shortcut."}
	var filename := "photo-checks.json" if "--photos-only" in OS.get_cmdline_user_args() else ("route-xr-checks.json" if "--xr-only" in OS.get_cmdline_user_args() else "route-checks.json")
	FileAccess.open(out.path_join(filename),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)

func walk(x: float,h: float,z: float,tag: String) -> bool:
	var target := Vector3(x,float(game.building.spec.levels[level])+h,z)
	var ok := await move_to(target,false,540)
	check(tag+"walk "+str(target),ok)
	if not ok:
		for i in game.body.get_slide_collision_count():
			var c: KinematicCollision3D=game.body.get_slide_collision(i)
			print("ROUTE_CONTACT ",c.get_collider().get_path()," / ",c.get_position())
	return ok

func pyramid_shortcuts(tag: String) -> void:
	for index in [14,15]:
		await visit_logic_floor(index)
		var y: float=game.building.spec.levels[index]
		var cx: float=-10 if index==14 else 10
		# Cardinal approaches include the lower saddle BETWEEN adjacent peaks.
		for c in [[-5.2,-.75,-2.73,-.75],[5.2,.75,2.73,.75],[0,-5.9,0,-3.25],[0,5.9,0,3.25]]:
			game.place_player(Vector3(cx+c[0],y+.06,c[1]));await frames(15)
			var start_at: Vector3=game.body.global_position
			await move_to(Vector3(cx+c[2],y,c[3]),true,100)
			var at: Vector3=game.body.global_position
			var outside := absf(at.x-cx)>3.2 or absf(at.z)>3.7
			check(tag+str(index)+" pyramid saddle blocks ground jump "+str(c),outside and not game.recovering)
			print("PYRAMID_JUMP ",start_at," -> ",at)
		check(tag+str(index)+" every pyramid remains an independent source prefab",game.building.content.data.floors[index].artifacts.filter(func(a):return str(a.id).begins_with("shaft-rim-pyramid-")).size()==22)
		check(tag+str(index)+" passive pyramids have no electrical leads",not game.building.content.roots[index].has_node("Lead_shaft-rim-pyramid-00"))
	await visit_logic_floor(14)

func introduction(tag: String) -> bool:
	level=14
	var grid: Node3D=game.building.content.roots[14].get_node("Construction")
	var assembly: Node3D=game.building.content.exhibits["14/sequence"].get_node("Artifact")
	var platform: Node3D=grid.get_node("SuspendedPlatform").platform
	var turn: Node3D=assembly.get_node("TurningPlank")
	var growth: Node3D=assembly.get_node("GrowingCube")
	for p in [[18.5,0,-8.3],[16,0,-8.3],[16,1,-6],[16,2,-4],[16,3,0],[14.5,3,0]]:
		if not await walk(p[0],p[1],p[2],tag):return false
	check(tag+"suspended ferry docks",await dock(platform,false))
	if not await walk(12.45,3,0,tag):return false
	check(tag+"ferry attaches real passenger",platform.carried_player==game.body)
	check(tag+"ferry reaches opposite bank",await dock(platform,true))
	for p in [[6.5,3,0],[3.1,3,0]]:
		if not await walk(p[0],p[1],p[2],tag):return false
	var aligned := false
	for i in 1800:
		await frames(1)
		if is_zero_approx(turn.current_angle) and not turn.is_rotating and turn.pause_timer>4.5:
			aligned=true;break
	check(tag+"turning bridge aligns",aligned)
	if not await walk(-4.2,3,0,tag):return false
	if not await walk(-6.8,3,0,tag):return false
	aligned=false
	for i in 1800:
		await frames(1)
		if growth.current_scale>4.999 and growth.pause_timer>4.5:
			aligned=true;break
	check(tag+"growing cube meets deck",aligned)
	if not await walk(-13.4,3,0,tag):return false
	if not await walk(-14.8,3,0,tag):return false
	check(tag+"three transformations reached with only normal travel drain",normal_charge(0) and game.deaths==0)
	check(tag+"bridge jump lands on inner rim",await move_to(Vector3(-12.73,-84,1.9),true,220))
	check(tag+"bridge jump keeps the ordinary five-point landing cost",normal_charge(1) and game.deaths==0)
	await move_to(Vector3(-11.7,-84,1.9),false,100);await frames(140)
	check(tag+"normal A drop lands on Translation",game.checkpoint==15 and normal_charge(1) and game.deaths==0)
	return game.checkpoint==15 and not game.recovering

func translation(tag: String) -> void:
	level=15
	# Continue from the actual arrival, not a new spawn.
	for p in [[-13.3,0,4.4],[-20.2,0,4.4],[-20.2,0,6],[-18,1,6],[-16,2,6],[-13,3,6],[-10,3,6],[-10,3,5.2]]:
		if not await walk(p[0],p[1],p[2],tag):return
	for p in [[-10,3,6],[0,3,6],[10,3,6],[11.7,3,6]]:
		if not await walk(p[0],p[1],p[2],tag):return
	check(tag+"Translation bridge jump lands inside pyramid rim",await move_to(Vector3(11.7,-90,3.25),true,220))
	for p in [[12.73,0,3.25],[12.73,0,-1.9]]:
		if not await walk(p[0],p[1],p[2],tag):return
	var jumps := 1 if "--translation-only" in OS.get_cmdline_user_args() else 2
	check(tag+"raised linking bridge and inner rim keep normal jump/travel costs",normal_charge(jumps) and game.deaths==0)
	await move_to(Vector3(11.7,-90,-1.9),false,100);await frames(140)
	check(tag+"normal B drop reaches Rotation",game.checkpoint==16 and normal_charge(jumps) and game.deaths==0)

func normal_charge(jumps: int=0) -> bool:
	var expected: float=100-(game.health.metres_travelled-metres_start)*game.health.CHARGE_PER_METRE-5*jumps
	print("ROUTE_CHARGE ",game.health.get_health()," expected ",expected)
	return absf(game.health.get_health()-expected)<.15

func dock(platform: Node3D,far_bank: bool) -> bool:
	for i in 1800:
		await frames(1)
		var p: float=platform.ride_progress()
		if far_bank and p>.999 and not platform.is_moving and platform.return_timer>2.5:return true
		if not far_bank and p<.001 and platform.waiting_to_start and platform.start_timer>2.5:return true
	return false

func image(filename: String,at: Vector3,target: Vector3) -> void:
	var shown: Array[int]=[level]
	game.building.show_floor_window(shown)
	for layer in game.find_children("*","CanvasLayer",true,false):layer.hide()
	game.status.hide();game.notice_time=-1
	game.get_node("XROrigin3D").hide()
	var cam := Camera3D.new();cam.fov=65;game.add_child(cam)
	cam.global_position=at;cam.look_at(target);cam.make_current()
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename+".png"))
	cam.queue_free();game.camera.make_current()



