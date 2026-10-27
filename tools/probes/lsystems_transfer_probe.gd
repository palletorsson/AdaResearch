extends "res://commons/void/trials/fractals/probe.gd"
## Coordinator acceptance of the original L-System instruments in their new mounts.
var measured_bounds:Dictionary={}

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/lsystems/trial.tscn").instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	var photos_only := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
		if arg=="--photos-only":photos_only=true
	DirAccess.make_dir_recursive_absolute(out)
	if photos_only:
		await capture_collection()
		quit(0)
		return
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_lsystems(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Representative original grammar and interpreter controls through desktop mouse and synthetic tracked XR; all original placements loaded, geometry measured, shaft descent, sleeping and retry. Other secondary instruments are not exhaustively interaction-tested. No physical headset test."},"\t"))
	FileAccess.open(out.path_join("bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(measured_bounds,"\t"))
	print("LSYSTEM_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func capture_collection() -> void:
	level=1;await start(false)
	var lesson:Node3D=station("f1_lsystem_editor_9_7").get_node("GrammarLesson")
	game.place_player(lesson.to_global(Vector3(0,.06,3.1)));await frames(10)
	await press(lesson.buttons["NEXT"]);await press(lesson.buttons["HOLD"])
	await press(lesson.buttons["TURN"])
	await floor_photo("01-grammar",Vector3(0,2.5,13),Vector3(0,2,5.7))
	await floor_photo("02-grammar-collection",Vector3(-4,2.4,-1),Vector3(0,1,-7))
	var fy:float=game.building.spec.levels[2]
	game.place_player(Vector3(0,fy+.06,12));await frames(60);level=2
	var growth:Node3D=station("f2_parametric_lsystem_9_7").get_node("GrowthLesson")
	game.place_player(growth.to_global(Vector3(0,.06,3.1)));await frames(10)
	await press(growth.buttons["TREE"])
	await floor_photo("03-growth",Vector3(0,3.6,14.5),Vector3(0,3.6,6.6))
	await floor_photo("04-growth-collection",Vector3(-6,2.4,-1),Vector3(1,2,-4.5))
	game.queue_free();await frames(8)

func measure_floor() -> void:
	var fy:float=game.building.spec.levels[level]
	for item in game.building.content.data.floors[level].artifacts:
		var source:Node3D=station(item.id)
		var bounds:=AABB();var first:=true
		for node in source.find_children("*","GeometryInstance3D",true,false):
			if not node.is_visible_in_tree() or node.get_viewport()!=game.get_viewport():continue
			var local:=AABB()
			if node is MeshInstance3D and node.mesh:local=node.mesh.get_aabb()
			elif node is MultiMeshInstance3D and node.multimesh:local=node.multimesh.get_aabb()
			else:continue
			local=node.global_transform*local
			bounds=local if first else bounds.merge(local);first=false
		check(("XR: " if xr else "Desktop: ")+item.id+" has visible original geometry",not first)
		measured_bounds[item.id]={"min":[bounds.position.x,bounds.position.y-fy,bounds.position.z],"max":[bounds.end.x,bounds.end.y-fy,bounds.end.z]}

func floor_photo(filename:String,at:Vector3,target:Vector3) -> void:
	if not take_photos:return
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport():layer.hide()
	game.status.hide();game.notice_time=-1
	var before:Vector3=game.body.global_position;var offset:=Vector3(0,game.building.spec.levels[level],0)
	game.place_player(offset+Vector3(-18,.06,13));await frames(4)
	var origin:Node3D=game.get_node("XROrigin3D");origin.hide()
	root.msaa_3d=Viewport.MSAA_4X;await photograph(filename,offset+at,offset+target)
	origin.show();game.place_player(before);await frames(4)

func visit_lsystems(use_xr:bool) -> void:
	level=1;await start(use_xr)
	var tag := "XR: " if xr else "Desktop: "
	var y:float=game.building.spec.levels[1]
	check(tag+"safe four-floor trial start",game.checkpoint==1 and game.body.is_on_floor() and game.building.spec.levels.size()==4)
	check(tag+"eight original Grammar Lab placements",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("1/")).size()==8)
	for x in [-10,10]:check(tag+"shaft %d remains open"%x,ray(Vector3(x,y+1,0),Vector3(x,y-.5,0)).is_empty())
	var editor:Node3D=station("f1_lsystem_editor_9_7")
	check(tag+"original GrammarLesson installed",editor.has_node("GrammarLesson"))
	if not editor.has_node("GrammarLesson"):game.queue_free();await frames(8);return
	var lesson:Node3D=editor.get_node("GrammarLesson")
	game.place_player(lesson.to_global(Vector3(0,.06,3.1)));await frames(15)
	var generation:int=editor.generations
	await press(lesson.buttons["NEXT"])
	check(tag+"NEXT rewrites the original grammar",editor.generations==generation+1)
	await press(lesson.buttons["HOLD"])
	var sentence:String=editor.get_string();var lines:Array=lesson.reference.lines.duplicate()
	var angle:float=editor.angle_degrees
	await press(lesson.buttons["TURN"])
	check(tag+"TURN changes drawing while sentence and witness persist",editor.angle_degrees!=angle and editor.get_string()==sentence and lesson.reference.lines==lines and editor.fitted_lines!=lines)
	await press(lesson.buttons["RULE"])
	check(tag+"RULE exposes original rewriting rules",lesson.show_rule)
	await press(lesson.buttons["RESET"])
	check(tag+"RESET restores opening grammar",editor.preset==0 and editor.generations==0)
	check(tag+"original hand companion remains",lesson.has_node("GrammarHand"))
	measure_floor()
	if not xr:
		var local:Vector3=editor.global_position-Vector3(0,y,0)
		await floor_photo("01-grammar",local+Vector3(6,2.6,8),local+Vector3(0,1.7,.2))
		await floor_photo("02-grammar-collection",Vector3(0,3.4,15),Vector3(0,1.3,3))
	game.place_player(Vector3(-8.3,y+.06,-1.9));await frames(130);level=2
	check(tag+"shaft landing reaches Growth",game.checkpoint==2 and game.body.is_on_floor())
	check(tag+"Grammar Lab sleeps after descent",not editor.can_process())
	check(tag+"five original Growth placements",game.building.content.exhibits.keys().filter(func(k):return str(k).begins_with("2/")).size()==5)
	var tree:Node3D=station("f2_parametric_lsystem_9_7")
	check(tag+"original GrowthLesson installed",tree.has_node("GrowthLesson"))
	if not tree.has_node("GrowthLesson"):game.queue_free();await frames(8);return
	var growth:Node3D=tree.get_node("GrowthLesson")
	game.place_player(growth.to_global(Vector3(0,.06,3.1)));await frames(15)
	var cursor:int=growth.cursor
	await press(growth.buttons["STEP"])
	check(tag+"STEP advances one original interpreter frame",growth.cursor==cursor+1)
	await press(growth.buttons["HOLD"])
	var witness:Dictionary=growth.reference.duplicate(true)
	var original_sentence:String=tree._current_string
	await press(growth.buttons["RATIO"])
	check(tag+"RATIO changes interpretation, preserving sentence and held state",is_equal_approx(tree.length_decay,1.0) and tree._current_string==original_sentence and growth.reference==witness)
	await press(growth.buttons["TREE"])
	check(tag+"TREE builds second original generation",tree.iterations==2 and tree.tree_segments.size()>1)
	await press(growth.buttons["RULE"])
	check(tag+"RULE exposes saved-state stack",growth.show_rule)
	check(tag+"original GrowthHand remains",growth.has_node("GrowthHand"))
	var fy:float=game.building.spec.levels[2]
	check(tag+"eight-metre ruler fits beneath slab",fy+float(tree.get_parent().position.y)+8.5*tree.scale.y<game.building.spec.levels[1]-game.building.spec.slab_thickness)
	measure_floor()
	if not xr:
		var local:Vector3=tree.global_position-Vector3(0,fy,0)
		await floor_photo("03-growth",local+Vector3(6,3,8),local+Vector3(0,3,.2))
		await floor_photo("04-growth-collection",Vector3(0,3.8,15),Vector3(0,2,3))
	await press(growth.buttons["RESET"])
	check(tag+"RESET restores source branch ratio and trace",tree.iterations==1 and is_equal_approx(tree.length_decay,.72) and growth.cursor==1)
	check(tag+"visitor owns the camera",game.get_viewport().get_camera_3d()==game.camera)
	game.place_player(Vector3(0,fy+.06,12));await frames(5);game.die("Transfer retry");await frames(110)
	check(tag+"retry rebuilds Growth",game.checkpoint==2 and not game.recovering and station("f2_parametric_lsystem_9_7").has_node("GrowthLesson"))
	game.queue_free();await frames(8)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
