extends "res://tools/probes/noise_trial_probe.gd"
## Coordinator checks of the transferred original instruments, not final curation.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/fractals/trial.tscn").instantiate()
	game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func artifact(key: String) -> Node3D:
	for item in game.building.content.data.floors[level].artifacts:
		if item.artifact == key:return station(item.id)
	return null

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_fractals(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Desktop mouse and synthetic XR pointer on representative original recursion/tree controls. Native Mobile renderer, shaft descent, residency and restart. Other instruments retain their original implementation but are not exhaustively interaction-tested. No physical headset test."},"\t"))
	print("FRACTAL_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func visit_fractals(use_xr: bool) -> void:
	level=1;await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	check(tag+"four-floor scaffold and safe start",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.levels.size()==4)
	check(tag+"all ten source placements load",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("1/")).size()==10)
	for x in [-10,10]:check(tag+"shaft %d remains open"%x,ray(Vector3(x,-5,0),Vector3(x,-6.5,0)).is_empty())
	var one:Node3D=artifact("fractal_recursion_2")
	var lesson:Node3D=one.get_node("RecursionLesson")
	game.place_player(lesson.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(lesson.buttons["MORE"])
	check(tag+"MORE advances original recursion",one.depth==2)
	await press(lesson.buttons["LAYOUT"])
	check(tag+"LAYOUT changes nested calls to abreast",one.recession=="abreast")
	await press(lesson.buttons["BEGIN"])
	check(tag+"BEGIN restores source law",one.depth==1 and one.recession=="nested")
	var circles:Node3D=artifact("example_8_3_recursion_circles_vr")
	var circle_lesson:Node3D=circles.get_node("RecursionLesson")
	game.place_player(circle_lesson.to_global(Vector3(0,.06,3.1)));await frames(15)
	await press(circle_lesson.buttons["PACKING"])
	check(tag+"PACKING changes four-call relation",circles.packing=="contact")
	await press(circle_lesson.buttons["BEGIN"])
	var chair:Node3D=artifact("recursive_chair")
	var chair_lesson:Node3D=chair.get_node("RecursionLesson")
	chair_lesson.act("NEXT");await frames(8)
	check(tag+"original chair stage API works",chair.step==1)
	chair_lesson.act("BEGIN")
	if not xr:
		await photo("01-recursion",Vector3(-7,-3.5,-14.5),Vector3(-6,-4.4,-8.5))
		await photo("02-collection",Vector3(0,-3.4,15.2),Vector3(-1,-4.2,5))
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(110);level=2
	check(tag+"shaft descent reaches second source map",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"previous floor sleeps",not one.can_process())
	check(tag+"all twelve second-floor placements load",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("2/")).size()==12)
	var tree:Node3D=artifact("recursive_tree_2")
	var tree_lesson:Node3D=tree.get_node("TreeLesson")
	game.place_player(tree_lesson.to_global(Vector3(0,.06,3.2)));await frames(15)
	var before:int=tree.current_depth
	await press(tree_lesson.buttons["GROW"])
	check(tag+"GROW advances original generation",tree.current_depth>before)
	await press(tree_lesson.buttons["ANGLE"])
	check(tag+"ANGLE changes the branch rule",tree.branch_angle_min==65)
	await press(tree_lesson.buttons["RESET"])
	check(tag+"RESET restores branch angle",tree.branch_angle_min==35)
	check(tag+"original hand fork and canopy remain",tree_lesson.hand_fork!=null and tree_lesson._canopy!=null)
	var turtle:Node3D=artifact("fractal_lsystem_tree")
	check(tag+"L-system controllers above the floor",turtle.angle_controller.global_position.y>-11.2 and turtle.length_controller.global_position.y>-11.2)
	turtle._on_angle_changed(30);await frames(6)
	check(tag+"original L-system parameter API",turtle.turn_angle==30)
	var fractal:Node3D=artifact("void_fractal_scene")
	var source:Node3D=fractal._fractal
	var mmi:MultiMeshInstance3D=source.multi_mesh_instances[0]
	check(tag+"world-space mesh is not transformed twice",(mmi.global_transform*mmi.multimesh.get_instance_transform(0)).origin.distance_to(source.global_position)<.001)
	var mount:Node3D=fractal.get_parent();mount.position.x+=1;mount.rotation_degrees.y+=90;await frames(5)
	check(tag+"world-space mesh follows edited mount",(mmi.global_transform*mmi.multimesh.get_instance_transform(0)).origin.distance_to(source.global_position)<.001)
	mount.position.x-=1;mount.rotation_degrees.y-=90;await frames(5)
	if not xr:
		await photo("03-branching",Vector3(-8.5,-9.7,-14.2),Vector3(-8,-10.4,-8))
		await photo("04-trees-collection",Vector3(0,-9,15.3),Vector3(-3,-10,5))
	game.place_player(Vector3(0,-11.94,12));await frames(10)
	game.die("Transfer retry");await frames(110)
	check(tag+"retry rebuilds second collection",game.checkpoint==2 and not game.recovering and artifact("void_fractal_scene")!=null)
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
