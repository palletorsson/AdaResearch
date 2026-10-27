extends "res://commons/void/trials/boolean_surfaces/probe.gd"
## Original algorithms, relocated exhibits and desktop / synthetic XR input.

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/graphtheory/trial.tscn").instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func press(button: Node3D) -> void:
	var target:Vector3=button.get_node("InteractableAreaButton/CollisionShape3D").global_position
	if not xr:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED
		for frame in 25:
			game.camera.look_at(target)
			await frames(1)
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
		Input.parse_input_event(event);await frames(6)
		event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
		Input.parse_input_event(event);await frames(8)
		return
	var origin:Node3D=game.get_node("XROrigin3D")
	var pointer:Node3D=game.pointers[1]
	for frame in 20:
		var at:Vector3=game.camera.global_position+Vector3(.1,-.2,0)
		var aim:=Basis.looking_at(target-at)
		at-=aim*Vector3(0,pointer.y_offset*XRServer.world_scale,0)
		right.set_pose("aim",Transform3D(origin.global_basis.inverse()*aim,origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		await frames(1)
	print("XR_CAP ",button.name," target=",pointer.target," collider=",pointer.get_node("RayCast").get_collider())
	right.set_input("trigger_click",true);await frames(6)
	right.set_input("trigger_click",false);await frames(8)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_graph(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Independent coordinator review of Claude's three original placements, raw configurations, native geometry, BFS/DFS, bridge theorem/degrees through desktop mouse and synthetic XR, seed/adjacency, relocation, sleep/resume and retry. Source E/B actions are stubs and not counted as functioning. No physical headset test."},"\t"))
	FileAccess.open(out.path_join("measured-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(measured,"\t"))
	print("GRAPH_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func measure_floor(tag: String) -> void:
	for entry in game.building.content.data.floors[level].artifacts:
		var node:Node3D=station(entry.id);var boxes:Array=[];var csg:Array=[]
		geometry(node,boxes,csg)
		check(tag+entry.id+" real geometry",not boxes.is_empty())
		if boxes.is_empty():continue
		var bounds:AABB=boxes[0]
		for box in boxes:bounds=bounds.merge(box)
		check(tag+entry.id+" fits between slabs",bounds.position.y>=-6*level-.015 and bounds.end.y<=-6*(level-1)-.36)
		if not xr:measured.append({"id":entry.id,"min":[bounds.position.x,bounds.position.y,bounds.position.z],"max":[bounds.end.x,bounds.end.y,bounds.end.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z]})

func visit_graph(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(35)
	var tag:="XR: " if xr else "Desktop: "
	check(tag+"safe arrival and both source placements",game.checkpoint==1 and game.body.is_on_floor() and game.building.content.data.floors[1].artifacts.size()==2)
	for x in [-10,10]:check(tag+"open shaft %d"%x,ray(Vector3(x,-5,0),Vector3(x,-6.5,0)).is_empty())
	measure_floor(tag)
	var travelers:Node3D=artifact("two_travelers")
	check(tag+"fifteen original lamps with distinct complete traversals",travelers._nodes.size()==15 and travelers._bfs_order.size()==15 and travelers._dfs_order.size()==15 and travelers._bfs_order!=travelers._dfs_order)
	var mode:bool=travelers._mode_bfs
	await frames(570)
	check(tag+"original replay alternates BFS and DFS",travelers._mode_bfs!=mode and travelers._cursor>0)
	var bridge:Node3D=artifact("void_gt_bridge")
	check(tag+"historical topology and four odd degrees",bridge.nodes.size()==4 and bridge.edges.size()==7 and bridge.degree_counts.values().all(func(v):return int(v)%2==1))
	check(tag+"same analysis spatial in desktop and VR",not bridge.theorem_display.visible and not bridge.readout.text.is_empty())
	game.place_player(bridge.to_global(Vector3(0,-.6,38)));await frames(20)
	var shown:bool=bridge.show_degree_labels
	await press(bridge.buttons[1]);check(tag+"DEGREES actual input",bridge.show_degree_labels!=shown and bridge._degree_labels.all(func(n):return n.visible==bridge.show_degree_labels))
	shown=bridge.show_theorem_explanation
	await press(bridge.buttons[0]);check(tag+"THEOREM actual input",bridge.show_theorem_explanation!=shown and bridge._theorem_label.visible==bridge.show_theorem_explanation)
	await press(bridge.buttons[0]);await press(bridge.buttons[1])
	shown=bridge.show_degree_labels
	var event:=InputEventKey.new();event.keycode=KEY_D;event.pressed=true;Input.parse_input_event(event);await frames(2)
	event=InputEventKey.new();event.keycode=KEY_D;event.pressed=false;Input.parse_input_event(event);await frames(2)
	check(tag+"walking right does not toggle bridge labels",bridge.show_degree_labels==shown)
	var mount:Node3D=bridge.get_parent();var saved:Transform3D=mount.transform
	mount.position.x+=1;mount.rotation_degrees.y+=90
	game.place_player(bridge.to_global(Vector3(0,-.6,38)));await frames(20)
	await press(bridge.buttons[1]);check(tag+"edited and turned bridge retains control",bridge.show_degree_labels!=shown)
	mount.transform=saved
	if not xr:
		await photo("01-two-travelers",Vector3(-6,-3.8,10),Vector3(-3,-4.5,5))
		await photo("02-seven-bridges",Vector3(6.5,-3.3,9.5),Vector3(3,-5.4,4))
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(145);level=2
	check(tag+"shaft landing reaches layout",game.checkpoint==2 and game.body.is_on_floor())
	var clock:float=travelers._clock;await frames(15)
	check(tag+"upper replay sleeps",not travelers.can_process() and travelers._clock==clock)
	measure_floor(tag)
	var layout:Node3D=artifact("force_directed_layout")
	check(tag+"source graph and seed applied",layout.graph=="cube" and layout.layout_seed==41 and layout.nodes.size()==8 and layout.edges.size()==12)
	var links:Array=[]
	for edge in layout.edges:links.append([edge.from_id,edge.to_id])
	var pos:Vector2=layout.nodes[0].position;await frames(45)
	check(tag+"force layout moves with fixed adjacency",pos!=layout.nodes[0].position and links==layout.connections_for("cube") and is_finite(layout.total_energy))
	layout.reset_simulation();var first:Array=[]
	for n in layout.nodes:first.append(n.position)
	layout.reset_simulation();var second:Array=[]
	for n in layout.nodes:second.append(n.position)
	check(tag+"reset reproduces seed 41",first==second)
	check(tag+"private source cameras do not replace player",game.get_viewport().get_camera_3d()==game.camera)
	if not xr:
		await photo("03-connections-and-coordinates",Vector3(-6,-8.8,11),Vector3(-3,-9.6,5))
		await photo("04-layout-in-the-tower",Vector3(4,-9,13),Vector3(-3,-9.5,5))
	game.place_player(Vector3(0,-5.94,12));await frames(40)
	check(tag+"return wakes original replay",travelers.can_process() and travelers._clock!=clock)
	game.place_player(Vector3(0,-11.94,12));await frames(30);game.die("Transfer retry");await frames(145)
	check(tag+"retry returns layout floor",game.checkpoint==2 and not game.recovering and artifact("force_directed_layout").layout_seed==41)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
