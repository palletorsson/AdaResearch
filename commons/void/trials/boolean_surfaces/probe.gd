extends "res://commons/void/trials/isosurfaces/probe.gd"
## Codex's independent native acceptance of Claude's placement-only handoff.
var measured: Array = []

func start(use_xr: bool) -> void:
	xr=use_xr
	if xr:
		head=tracker("head",XRServer.TRACKER_HEAD,"default",Vector3(0,1.65,0))
		left=tracker("left_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(-.3,1.2,-.4))
		right=tracker("right_hand",XRServer.TRACKER_CONTROLLER,"aim",Vector3(.3,1.2,-.4))
		left.set_input("primary",Vector2.ZERO);right.set_input("primary",Vector2.ZERO)
		right.set_input("trigger_click",false);right.set_input("grip",0.0)
	game=load("res://commons/void/trials/boolean_surfaces/trial.tscn").instantiate()
	game.force_xr=xr;root.add_child(game);current_scene=game
	if not xr:game.body.scripted_input=true
	await frames(45);game.scene_loaded();game.scene_visible();await frames(30)
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out=arg.trim_prefix("--out=")
		if arg=="--capture":take_photos=true
	DirAccess.make_dir_recursive_absolute(out)
	if "--photos-only" in OS.get_cmdline_user_args():
		level=2;await start(false)
		game.place_player(Vector3(0,-11.94,12));await frames(40)
		await photo("04-removal-registers",Vector3(0,-9.7,-15.5),Vector3(0,-11,-12))
		game.queue_free();await frames(10);quit(0);return
	check("isolated saves",OS.get_user_data_dir().contains("Ada Void Trial Test"))
	if not checks.back().passed:quit(1);return
	for use_xr in [false,true]:await visit_boolean(use_xr)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Coordinator independent check of all 29 original placements and each configured variant on desktop and synthetic tracked XR. Native CSG, measured bounds, rotation, volume readout, monitor controls, descent, sleep, resume and retry. No physical headset test."},"\t"))
	FileAccess.open(out.path_join("measured-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(measured,"\t"))
	print("BOOLEAN_TRANSFER_RESULT ",checks.size()," failures: ",failed)
	quit(0 if failed.is_empty() else 1)

func geometry(node: Node, boxes: Array, csg: Array) -> void:
	if node is SubViewport:return
	if node is CSGShape3D:
		csg.append(node)
		if node.is_root_shape() and node.is_visible_in_tree():boxes.append(node.global_transform*node.get_aabb())
	elif node is MeshInstance3D and node.mesh!=null and node.is_visible_in_tree() and node.layers!=0:
		boxes.append(node.global_transform*node.get_aabb())
	elif node is MultiMeshInstance3D and node.multimesh!=null and node.is_visible_in_tree():
		boxes.append(node.global_transform*node.get_aabb())
	for child in node.get_children():geometry(child,boxes,csg)

func inspect_floor(tag: String) -> void:
	for entry in game.building.content.data.floors[level].artifacts:
		var node:Node3D=station(entry.id)
		check(tag+entry.id+" original scene script",node.get_script()!=null)
		for key in entry.config:
			if key in ["plinth","pin"]:continue
			check(tag+entry.id+" actual variant "+key,str(node.get(key)).to_lower()==str(entry.config[key]).to_lower())
		var boxes:Array=[];var csg:Array=[];geometry(node,boxes,csg)
		check(tag+entry.id+" native geometry built",not boxes.is_empty())
		check(tag+entry.id+" CSG remains non-colliding",csg.all(func(s):return not s.use_collision))
		if boxes.is_empty():continue
		var bounds:AABB=boxes[0]
		for box in boxes:bounds=bounds.merge(box)
		check(tag+entry.id+" geometry stays between slabs",bounds.position.y>=-6*level-.015 and bounds.end.y<=-6*(level-1)-.36+.015)
		if not xr:
			measured.append({"id":entry.id,"artifact":entry.artifact,"floor":level,"min":[bounds.position.x,bounds.position.y,bounds.position.z],"max":[bounds.end.x,bounds.end.y,bounds.end.z],"size":[bounds.size.x,bounds.size.y,bounds.size.z],"colliders":node.find_children("*","PhysicsBody3D",true,false).size(),"native_csg":csg.size()})
		if node.get("_root_csg")!=null:
			check(tag+entry.id+" boolean result has triangles",node._root_csg.get_meshes().size()==2)

func film_button(film: Node3D, key: String) -> void:
	var target:Vector3=film.buttons[key].global_position
	if xr:
		var origin:Node3D=game.get_node("XROrigin3D")
		var at:Vector3=target+film.global_basis.z*.6
		for frame in 18:
			right.set_pose("aim",Transform3D(origin.global_basis.inverse()*Basis.looking_at(target-at),origin.to_local(at)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
			await frames(1)
		right.set_input("trigger_click",true);await frames(6)
		right.set_input("trigger_click",false);await frames(8)
	else:
		Input.mouse_mode=Input.MOUSE_MODE_CAPTURED;game.camera.look_at(target);await frames(18)
		var event:=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=true
		Input.parse_input_event(event);await frames(6)
		event=InputEventMouseButton.new();event.button_index=MOUSE_BUTTON_LEFT;event.pressed=false
		Input.parse_input_event(event);await frames(8)

func look_at_film(film: Node3D) -> void:
	if xr:
		var origin:Node3D=game.get_node("XROrigin3D")
		var eye:Vector3=game.camera.global_position
		head.set_pose("default",Transform3D(origin.global_basis.inverse()*Basis.looking_at(film.screen.global_position-eye),origin.to_local(eye)),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	else:game.camera.look_at(film.screen.global_position)
	await frames(30)

func visit_boolean(use_xr: bool) -> void:
	level=1;await start(use_xr);await frames(35)
	var tag:="XR: " if xr else "Desktop: "
	check(tag+"safe arrival and four verbs",game.checkpoint==1 and game.body.is_on_floor() and game.building.content.data.floors[1].artifacts.size()==4)
	inspect_floor(tag)
	for x in [-10,10]:check(tag+"open shaft %d"%x,ray(Vector3(x,-5,0),Vector3(x,-6.5,0)).is_empty())
	var union:Node3D=artifact("csg_union_demo");var before:float=union._t
	await frames(10);check(tag+"original union rotates",union._t>before)
	var intersection:Node3D=artifact("csg_intersection_demo")
	check(tag+"original numeral plate survived",intersection.forfeit=="numeral" and intersection.get_node("ForfeitReadout").text.contains("|A ∩ B|"))
	var volumes:Dictionary=intersection._volumes()
	check(tag+"intersection volume bounded by both operands",volumes.both>0 and volumes.both<=minf(volumes.a,volumes.b))
	if not xr:
		await photo("01-boolean-verbs",Vector3(5,-2,12),Vector3(0,-5,1))
		await photo("02-argument-of-solids",Vector3(5,-3,-5),Vector3(2,-4.8,-10))
	game.place_player(Vector3(-8.3,-5.94,-1.9));await frames(145);level=2
	check(tag+"landing reaches gallery",game.checkpoint==2 and game.body.is_on_floor())
	before=union._t;await frames(12)
	check(tag+"upper moving solids sleep",not union.can_process() and union._t==before)
	var sleeping_union:float=union._t
	check(tag+"all 25 gallery copies loaded",game.building.content.data.floors[2].artifacts.size()==25)
	inspect_floor(tag)
	var offsets:Array=[];var cuts:Array=[]
	for entry in game.building.content.data.floors[2].artifacts:
		var node:Node3D=station(entry.id)
		if entry.artifact=="csg_union_demo":offsets.append(node._fusion_offset())
		if entry.artifact=="removal_room":cuts.append(node._keep_p.size())
	check(tag+"four union configurations produce different offsets",offsets.size()==4 and offsets[0]!=offsets[1] and offsets[1]!=offsets[2] and offsets[2]!=offsets[3])
	check(tag+"four removal rules built retained and removed cells",cuts.size()==4 and cuts.min()>0 and cuts.max()>cuts.min())
	var film:Node3D=artifact("film_boolean_overlap")
	check(tag+"film preserves original private CSG stage",film.viewport.own_world_3d and film.stage.validation().passed)
	game.place_player(film.to_global(Vector3(0,.06,2.2)));await frames(10);await look_at_film(film)
	check(tag+"looking at film activates playback",film.gaze_active and film.stage.playhead>0)
	await film_button(film,"pause");before=film.stage.playhead;await frames(12)
	check(tag+"film PAUSE through real pointer",not film.stage.running and film.stage.playhead==before)
	await film_button(film,"step");check(tag+"film STEP advances phase",not film.stage.running and film.stage.playhead!=before)
	before=film.stage._view_offset;await film_button(film,"route")
	check(tag+"film TURN VIEW changes private camera",film.stage._view_offset!=before)
	await film_button(film,"replay");check(tag+"film REPLAY restarts original illustration",film.stage.running and film.stage.playhead<1)
	var mount:Node3D=film.get_parent();var saved:Transform3D=mount.transform
	mount.position.x-=1;mount.rotation_degrees.y+=90;await frames(5)
	game.place_player(film.to_global(Vector3(0,.06,2.2)));await frames(10)
	await film_button(film,"step");check(tag+"moved and turned monitor retains input",not film.stage.running)
	mount.transform=saved
	check(tag+"private camera never replaces visitor",game.get_viewport().get_camera_3d()==game.camera)
	if not xr:
		await photo("03-boolean-gallery",Vector3(0,-7,12),Vector3(0,-11,-4))
		await photo("04-removal-registers",Vector3(0,-9.7,-15.5),Vector3(0,-11,-12))
	game.place_player(Vector3(0,-5.94,12));await frames(40)
	check(tag+"return resumes existing union",game.checkpoint==1 and union.can_process() and union._t>sleeping_union)
	game.place_player(Vector3(0,-11.94,12));await frames(30)
	game.die("Transfer retry");await frames(145)
	check(tag+"retry returns gallery",game.checkpoint==2 and not game.recovering)
	game.queue_free();await frames(10)
	if xr:
		for item in [head,left,right]:XRServer.remove_tracker(item)
