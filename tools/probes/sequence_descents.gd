extends "res://tools/probes/void_game_probe.gd"
## Actual tower, actual walker / XR body and streaming, isolated user saves.
func run() -> void:
	var kind := "jump_terraces"
	var wanted_map := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
		if arg.begins_with("--kind="): kind=arg.trim_prefix("--kind=")
		if arg.begins_with("--map="): wanted_map=arg.trim_prefix("--map=")
	xr="--synthetic-xr" in OS.get_cmdline_user_args()
	var rooms: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/void/rooms.json"))
	var index := -1; var selected: Dictionary={}
	for i in rooms.floors.size():
		for item in rooms.floors[i].artifacts:
			if index<0 and item.artifact=="sequence_descent" and item.config.kind==kind and (wanted_map.is_empty() or rooms.floors[i].map==wanted_map):
				index=i;selected=item
	check("requested route is installed",index>=0)
	if index<0: quit(1);return
	preload("res://commons/void/room_source.gd").use_main_tower=true
	load("res://commons/void/game.gd").requested_floor=index
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
	game=load("res://commons/void/void.tscn").instantiate();game.force_xr=xr
	root.add_child(game);current_scene=game
	if not xr: game.body.scripted_input=true
	game.scene_loaded();game.scene_visible();await frames(60)
	var route: Node3D=game.building.content.exhibits[str(index)+"/"+str(selected.id)].get_node("Artifact")
	check("route lands on the actual adjacent level",absf(route.to_global(route.exit).y-float(game.building.spec.levels[index+1]))<.001)
	check("route is streaming-pinned through its destination",selected.config.connects_next_floor)
	var rendering := DisplayServer.get_name()!="headless"
	if rendering:
		var camera:=Camera3D.new();game.add_child(camera)
		camera.global_position=route.to_global(Vector3(14,7,16))
		camera.look_at(route.to_global(Vector3(-1,-2,0)));camera.make_current()
		await frames(5);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("overview.png"))
		camera.queue_free();game.camera.make_current()
	var supported:=true
	for point in [Vector3(-7.5,0,-5.5),Vector3(-7.5,-route.vertical_drop,5.5)] if kind!="boolean_drop" else [route.exit]:
		var hit:=ray(route.to_global(point+Vector3.UP*.4),route.to_global(point-Vector3.UP*.4))
		if hit.is_empty():supported=false
	check("entrance and lower landing have real support",supported)
	if kind=="boolean_drop":
		check("opening has no invisible floor",ray(route.to_global(route.entrance+Vector3.UP*.1),route.to_global(route.entrance-Vector3.UP*4.5)).is_empty())
		game.place_player(route.to_global(route.entrance+Vector3.UP*.08))
	else:
		game.place_player(route.to_global(Vector3(-7.7,.06,-5.5)))
		await frames(5)
		var approach := await move_to(route.to_global(Vector3(-1.6,0,-6.05)),false,360)
		approach = await move_to(route.to_global(Vector3(0,0,-6.05)),false,180) and approach
		approach = await move_to(route.to_global(route.entrance),false,180) and approach
		check("walk from tower across the approach bridge and around the mouth",approach)
		if not approach: game.place_player(route.to_global(route.entrance+Vector3.UP*.06))
	await frames(5)
	var reached:=false;var peak:=0.0;var airborne:=0;var blockers:Array=[]
	var before:int=game.deaths
	if kind=="maximal_stairs":
		var walked:=0
		for p in route.stair_path:
			if not await move_to(route.to_global(p),false,100): break
			walked+=1
		check("every spiral tread is traversable in order",walked==route.stair_path.size())
		await move_to(route.to_global(route.exit),false,240)
		reached=game.body.global_position.distance_to(route.to_global(route.exit))<.7
	else:
		for frame in 1500:
			var p:Vector3=route.to_local(game.body.global_position)
			if kind=="boolean_drop": axes(Vector2.ZERO)
			elif kind.begins_with("wave_") and route._point_inside(game.body.global_position): axes(Vector2.ZERO)
			else:
				var direction:Vector3=route.global_basis*Vector3(0,0,1)
				axes(Vector2(direction.x,direction.z))
			await frames(1)
			peak=maxf(peak,game.body.velocity.length())
			if not game.body.is_on_floor():airborne+=1
			if frame%120==0:
				print("[route] ",kind," ",p)
				for c in game.body.get_slide_collision_count():
					var path:=str(game.body.get_slide_collision(c).get_collider().get_path())
					if path not in blockers:blockers.append(path)
			if p.y < -route.vertical_drop+.18 and (kind=="boolean_drop" or p.z>4.7):reached=true;break
	axes(Vector2.ZERO);await frames(45)
	check("physical traversal reaches the next floor",reached)
	check("arrival is supported",game.body.is_on_floor())
	check("next floor is active",game.floor_stream.focus==index+1)
	check("connecting route remains live after crossing floor boundary",index in game.floor_stream.pinned and route.can_process())
	check("no death or reset during traversal",game.deaths==before and route.to_local(game.body.global_position).y< -route.vertical_drop+.2)
	if kind=="jump_terraces":check("terraces produce real airborne movement",airborne>10)
	if kind.begins_with("wave_"):
		check("slide speed is bounded",peak<3.5)
		game.place_player(Vector3(0,float(game.building.spec.levels[index+1])+.05,2));await frames(5)
		check("relocation releases slide ownership",route.riders.is_empty())
	var data:Dictionary={"passed":failed.is_empty(),"kind":kind,"xr":xr,"checks":checks,"failed":failed,"peak":peak,"airborne":airborne,"blockers":blockers,"position":str(game.body.global_position)}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(data,"  "))
	game.queue_free();await frames(4)
	if xr:
		for t in [head,left,right]:XRServer.remove_tracker(t)
	quit(0 if failed.is_empty() else 1)
