extends "res://tools/probes/void_game_probe.gd"
const Stream := preload("res://commons/void/floor_stream.gd")
var summaries: Array[Dictionary]=[]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	await start(false)
	var stream: Node=game.floor_stream
	var content: Node3D=game.building.content
	check("roof starts with only current and next content instantiated",content.roots.size()==2 and content.roots.has(0) and content.roots.has(1) and not content.roots.has(2))
	check("actual tower contains nine structural levels",game.building.floors.size()==9 and content.data.floors.size()==9 and game.building.spec.levels.back()==-48)
	check("window shows four above and four below",Stream.floor_window(6,14)==[2,3,4,5,6,7,8,9,10] and Stream.floor_window(0,14)==[0,1,2,3,4])
	check("roof uses full content with frozen preview below",stream.records[0].mode=="live" and stream.records[1].mode=="preview" and not content.roots[1].can_process())
	check("roof shows through floor four and hides the deepest structure",game.building.floors[4].visible and not game.building.floors[8].visible and not game.building.floor_details[8].visible)
	check("fog is enabled across four storeys without a volumetric pass",game.camera.environment.fog_enabled and game.camera.environment.fog_depth_begin==6 and game.camera.environment.fog_depth_end==30 and game.camera.environment.fog_density==1 and not game.camera.environment.volumetric_fog_enabled)
	summaries.append(stream.summary())
	game.place_player(game.spawn_for(3));await frames(90)
	# Threaded I/O uses wall time; a headless fixed-fps run can simulate seconds
	# before the OS finishes reading a resource. Wait for completion with a cap.
	var deadline := Time.get_ticks_msec()+10000
	while not content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		OS.delay_msec(5)
		await process_frame
	check("destination is complete and below is prewarmed",stream.focus==3 and content.pending.is_empty() and content.exhibits.has("4/descent"))
	if not content.pending.is_empty(): quit(2);return
	var descent: Node3D=content.exhibits["4/descent"].get_node("Artifact")
	var record: Node3D=content.exhibits["4/record"].get_node("Artifact")
	if descent.get_child_count()==0:
		quit(2);return
	var landing: Node3D=descent.get_node_or_null("Landing0Plank0")
	check("shaft landing remains visible before descending",landing!=null and landing.is_visible_in_tree() and not descent.can_process())
	check("remote pedestal study is hidden in next-floor preview",not record.get_node("ShadowPoint").is_visible_in_tree())
	var hit := ray(Vector3(11,-20,-1.65),Vector3(11,-21.2,-1.65))
	check("preview landing already has working collision",not hit.is_empty() and is_equal_approx(hit.position.y,-21))
	var monitor: Node3D=record.get_node("SamplingMonitor")
	var screens := monitor.find_children("*","SubViewport",true,false)
	var screens_asleep := not screens.is_empty()
	for screen in screens: screens_asleep=screens_asleep and screen.render_target_update_mode==SubViewport.UPDATE_DISABLED
	check("preview screens stop rendering",screens_asleep)
	var point: RigidBody3D=record.get_node("ShadowPoint").point
	check("hidden next-floor pickables leave the physics space",not PhysicsServer3D.body_get_space(point.get_rid()).is_valid())
	var pose := point.global_transform
	await frames(20)
	check("preview bodies remain frozen",point.freeze and point.global_transform.is_equal_approx(pose))
	check("old floor scripts and physics are removed from active simulation",stream.records[0].mode=="sleep" and not content.roots[0].visible and not content.roots[0].can_process())
	summaries.append(stream.summary())
	if "--capture" in OS.get_cmdline_user_args(): await pictures()
	game.place_player(game.spawn_for(4));await frames(25)
	var visible_count := 0
	for floor in game.building.floors:
		if floor.visible: visible_count+=1
	check("Trace has all nine structural levels around it",visible_count==9 and stream.focus==4)
	check("new floors have no invented lessons or artifacts",content.data.floors.slice(5).all(func(f): return f.map=="" and f.artifacts.is_empty() and f.walls.is_empty()))
	check("unfinished floors add no unintended balconies",game.building.landing_pads.size()==3)
	var lower_slab := ray(Vector3(0,-47,5),Vector3(0,-49,5))
	var lower_shaft := ray(Vector3(-10,-25,0),Vector3(-10,-49,0))
	check("new floors have solid slabs and continuous open shaft A",not lower_slab.is_empty() and is_equal_approx(lower_slab.position.y,-48) and lower_shaft.is_empty())
	check("entering Trace restores complete study and monitor processing",record.get_node("ShadowPoint").is_visible_in_tree() and record.can_process() and monitor.can_process())
	check("waking restores pickable physics",PhysicsServer3D.body_get_space(point.get_rid()).is_valid())
	var drawing: Node3D=record.get_node("ShadowPoint")
	var archive: Node=root.get_node("TraceData");archive.clear_traces()
	point.on_desktop_grab(null);await frames(3)
	point.position+=Vector3(0.3,0.2,0);await frames(3)
	point.on_desktop_drop(null);await frames(3)
	var original: Array=archive.saved_traces[0].duplicate()
	var point_id := point.get_instance_id()
	var ink_count: int=drawing.ink.get_child_count()
	game.place_player(game.spawn_for(0));await frames(20)
	check("sleep preserves trace archive and in-room ink",archive.saved_traces[0]==original and drawing.ink.get_child_count()==ink_count and stream.records[4].mode=="sleep")
	game.place_player(game.spawn_for(4));await frames(20)
	check("return wakes the same objects without rebuilding",point.get_instance_id()==point_id and drawing.ink.get_child_count()==ink_count and archive.saved_traces[0]==original)
	# Mutated catalyst grid cells also remain in their resident record.
	game.place_player(game.spawn_for(1));await frames(15)
	var cell: Dictionary={}
	for candidate in content.cells.values():
		if candidate.floor==1: cell=candidate;break
	check("fixture has a real catalyst cell",not cell.is_empty())
	if not cell.is_empty():
		content.react_at_world(cell.node.global_position,"catalyst.primitives")
		var changed: float=cell.height
		game.place_player(game.spawn_for(0));await frames(10)
		game.place_player(game.spawn_for(1));await frames(10)
		check("changed catalyst panel survives sleeping and waking",is_equal_approx(cell.height,changed) and changed>0.03)
	game.checkpoint=3;game.die("Stream checkpoint");await frames(90)
	check("retry restores the checkpoint floor before play resumes",stream.focus==3 and game.checkpoint==3 and game.body.is_on_floor() and not game.recovering)
	game.place_player(game.spawn_for(8));await frames(30)
	check("bottom structural floor can load and save a checkpoint",stream.focus==8 and game.checkpoint==8 and game.body.is_on_floor() and content.roots.has(8) and not content.roots.has(9))
	summaries.append(stream.summary())
	game.queue_free();await frames(4)
	await carried_point()
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"snapshots":summaries,"scope":"Native loading, visibility, paused simulation, collision, retained trace and synthetic XR carrying; not a headset performance benchmark."},"\t"))
	quit(0 if failed.is_empty() else 1)

func carried_point() -> void:
	await start(true)
	game.place_player(Vector3(-15,-23.94,4.2));await frames(25)
	var stream: Node=game.floor_stream
	var drawing: Node3D=game.building.content.exhibits["4/record"].get_node("Artifact/ShadowPoint")
	var point: RigidBody3D=drawing.point
	# Follow the user's saved placement, keeping the synthetic hand within reach.
	game.place_player(Vector3(point.global_position.x,-23.94,point.global_position.z+1.0));await frames(15)
	hand_at(right,point.global_position);await frames(12)
	right.set_input("grip",1.0);await frames(20)
	check("streamed point can be picked up",game.pickups[1].picked_up_object==point)
	game.place_player(game.spawn_for(0));await frames(25)
	check("carrying across floors pins original object and lesson",game.pickups[1].picked_up_object==point and point.is_picked_up() and stream.records[4].mode=="live" and drawing.can_process())
	right.set_input("grip",0.0);await frames(20)
	check("released traveller remains visible near the player",stream.records[4].mode=="live" and point.is_visible_in_tree())
	game.place_player(game.spawn_for(2));await frames(25)
	check("distant released traveller can sleep without deletion",stream.records[4].mode=="sleep" and is_instance_valid(point))
	game.queue_free();await frames(4)
	for item in [head,left,right]: XRServer.remove_tracker(item)

func pictures() -> void:
	game.notice_time=-1;game.status.hide()
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	game.atmosphere.set_process(false);game.atmosphere.set_sky_time(180)
	root.msaa_3d=Viewport.MSAA_4X
	var cam:=Camera3D.new();root.add_child(cam);cam.environment=game.atmosphere.environment;cam.make_current();cam.fov=78
	cam.position=Vector3(13.3,-16.35,-1.65);cam.look_at(Vector3(9.5,-23.2,1.8))
	await frames(30);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("shaft-preview.png"))
	game.place_player(game.spawn_for(4));await frames(25)
	cam.position=Vector3(-7.8,-22.35,0);cam.look_at(Vector3(-10,-44,0))
	await frames(30);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("four-below.png"))
	cam.environment.fog_enabled=false
	await frames(3);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("four-below-clear.png"))
	cam.environment.fog_enabled=true
	cam.look_at(Vector3(-10,-2,0))
	await frames(30);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("four-above.png"))
	cam.position=Vector3(-12.7,-22.2,6);cam.look_at(Vector3(-16.5,-22.85,0.8))
	await frames(30);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("trace-awake.png"))
	game.place_player(game.spawn_for(0));await frames(25)
	cam.position=Vector3(-7.0,1.65,-1.2);cam.look_at(Vector3(-10,-17,1.2))
	await frames(30);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("fog-depth.png"))
	game.place_player(game.spawn_for(3));await frames(15)
	cam.queue_free();await frames(2);game.camera.make_current()
