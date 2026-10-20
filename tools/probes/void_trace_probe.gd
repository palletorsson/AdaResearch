extends "res://tools/probes/void_game_probe.gd"
const Grid = preload("res://commons/primitives/line/grid_lines.gd")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--editor" in OS.get_cmdline_user_args():
		await start(false)
		var content: Node3D=game.building.content
		var monitor: Node3D=content.exhibits["4/record"].get_node("Artifact/SamplingMonitor")
		check("saved editor draft places original monitor",monitor.global_position.is_equal_approx(Vector3(2.5,-24,-2.6)))
		var beam: Node3D=content.exhibits["4/steel-copy"].get_node("Artifact")
		check("saved copy instantiates only the black steel beam",beam.get_child_count()==1 and beam.get_child(0).skin=="beam" and beam.get_child(0).global_position.is_equal_approx(Vector3(16.5,-23.85,6)))
		var record: Node3D=content.exhibits["4/record"].get_node("Artifact")
		check("saved editor point position reaches VR",record.get_node("ShadowPoint/BlackPoint").global_position.is_equal_approx(Vector3(-14.5,-22.95,3)))
		check("saved outline rotation reaches VR",is_equal_approx(record.get_node("OutlineBox1").rotation_degrees.y,45))
		var point_copy: Node3D=content.exhibits["4/shadow-copy"].get_node("Artifact")
		check("saved copied point is independently pickable",point_copy.get_child_count()==1 and point_copy.get_node("ShadowPoint").point!=record.get_node("ShadowPoint").point)
		var frame_copy: Node3D=content.exhibits["4/outline-copy"].get_node("Artifact")
		check("saved copied outline keeps all twelve edges",frame_copy.get_child_count()==1 and frame_copy.get_node("OutlineBox0").get_child_count()==12)
		game.queue_free();await frames(3)
		FileAccess.open(out.path_join("editor-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks}))
		quit(0 if failed.is_empty() else 1);return
	if "--capture" in OS.get_cmdline_user_args():
		await pictures();quit();return
	await trace_contract()
	await shadow_contract()
	await descent_contract(false)
	await descent_contract(true)
	FileAccess.open(out.path_join("trace-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed},"\t"))
	print("TRACE_RESULT ",checks.size()-failed.size(),"/",checks.size())
	quit(0 if failed.is_empty() else 1)

func trace_contract() -> void:
	await start(true)
	game.checkpoint=4;game.place_player(game.spawn_for(4));await frames(25)
	var content: Node3D = game.building.content
	check("fifth floor is Point Trace",content.data.floors.size()>=5 and content.data.floors[4].map=="Point_Trace")
	check("three earlier balconies retained, none on Trace",game.building.landing_pads.size()==3)
	var record: Node3D = content.exhibits["4/record"].get_node("Artifact")
	var bead: Node3D = record.get_node("Bead10mm")
	check("original DrawDot implements the bead",bead.get_script().resource_path=="res://commons/primitives/point/draw_dot.gd")
	check("three resolutions remain distinct",bead.resolution_mm==10 and record.get_node("Bead40mm").resolution_mm==40 and record.get_node("Bead80mm").resolution_mm==80)
	check("readout sits on the physical plinth",bead._data_mount_ready and is_equal_approx(bead._data_mount_surface.y,-23.1))
	var monitor: Node3D = record.get_node("SamplingMonitor")
	check("original glass and monitor scenes",content.exhibits["4/surface"].get_node("Artifact/GlassWall").get_script().resource_path.ends_with("glass_paint_wall.gd") and monitor.get_script().resource_path.ends_with("trace_sampling_monitor.gd"))
	var point: RigidBody3D = bead.get_node("GrabPoint")
	var archive: Node = root.get_node("TraceData")
	archive.clear_traces()
	hand_at(right,point.global_position);await frames(15)
	right.set_input("grip",1.0);await frames(25)
	check("XR grip picks up the actual drawing bead",game.pickups[1].picked_up_object==point)
	var begin: Vector3 = point.global_position
	for i in range(30):
		hand_at(right,begin+Vector3(i*0.025,sin(i*0.15)*0.25,0.3))
		await frames(2)
	check("moving the held point produces real samples",bead._trail_points.size()>10)
	check("monitor follows the same held point on this floor",monitor.sources.size()==3 and monitor.active_source==bead)
	right.set_input("grip",0.0);await frames(15)
	check("release archives a trace",archive.saved_traces.size()==1)
	if not archive.saved_traces.is_empty():
		var original: Array = archive.saved_traces[0].duplicate()
		check("archive copies world coordinates",original==bead._trail_points and original[0].y< -20)
		var grid := Grid.new();grid.position=Vector3(0,-24,0);game.add_child(grid);await frames(10)
		check("real Grid reads the retained drawing",grid._trace_data_list.size()==1 and grid._trace_data_list[0].raw_points==original and not grid._rotating_instances.is_empty())
		await frames(30)
		check("Grid rotation and recentering leave original intact",archive.saved_traces[0]==original)
		grid.queue_free();await frames(2)
		game.die("Trace archive regression");await frames(90)
		check("retry keeps trace and floor checkpoint",archive.saved_traces[0]==original and game.checkpoint==4 and game.deaths==1 and not game.recovering)
	var ramp: Node3D = content.exhibits["4/release"].get_node("Artifact/BallRamp")
	var old: RigidBody3D = ramp.ball
	hand_at(right,old.global_position);await frames(15);right.set_input("grip",1.0);await frames(25)
	hand_at(right,ramp.to_global(Vector3(0,1.3,0.9)));await frames(20);right.set_input("grip",0.0);await frames(80)
	check("released ramp ball stays while a new ball waits",ramp.traces.size()==2 and is_instance_valid(old) and is_instance_valid(ramp.ball) and ramp.ball!=old)
	check("ramp records the actual fall",ramp.traces[0].segment_count>1)
	# Exercise the same placement adapter used for editor saves and part copies.
	var old_pose: Vector3 = record.get_node("SamplingMonitor").position
	record.apply_grid_config({"parts":{"SamplingMonitor":{"position":[4.5,0,-3.8],"rotation":[0,15,0]}}})
	check("editor override moves original live monitor",record.get_node("SamplingMonitor").position.x==4.5 and is_equal_approx(record.get_node("SamplingMonitor").rotation_degrees.y,15))
	var copy: Node3D = load("res://commons/void/trace_record.tscn").instantiate();game.add_child(copy)
	copy.apply_grid_config({"only_parts":["SamplingMonitor"]})
	check("copy isolates a fresh working artifact",copy.get_child_count()==1 and copy.get_node("SamplingMonitor").has_node("LiveScreen"))
	copy.reset_after_fall();copy.queue_free()
	game.queue_free();await frames(3)
	for item in [head,left,right]: XRServer.remove_tracker(item)

func shadow_contract() -> void:
	await start(true)
	game.checkpoint=4;game.place_player(Vector3(-15,-23.94,4.2));await frames(25)
	var record: Node3D=game.building.content.exhibits["4/record"].get_node("Artifact")
	var drawing: Node3D=record.get_node("ShadowPoint")
	var ball: RigidBody3D=drawing.point
	check("Shadow Game's actual point class is reused",ball.get_script().resource_path=="res://commons/shadow_game/point.gd")
	check("smaller sphere and collider both have 7cm radius",is_equal_approx(ball.get_child(0).mesh.radius,0.07) and is_equal_approx(ball.get_child(1).shape.radius,0.07) and ball.scale==Vector3.ONE)
	check("original glossy black finish retained",ball.get_child(0).material_override.albedo_color==Color("10131d") and is_equal_approx(ball.get_child(0).material_override.roughness,0.16))
	var frames_ok := true
	for i in range(3):
		var frame: Node3D=record.get_node("OutlineBox%d"%i)
		var plinth: Node3D=record.get_node("OutlinePlinth%d"%i)
		frames_ok=frames_ok and frame.get_script().resource_path.ends_with("shadow_game/socket_frame.gd") and frame.get_child_count()==12 and is_equal_approx(frame.position.y-0.24-0.012,plinth.position.y+0.49)
	check("three open twelve-edge cubes rest on solid pedestals",frames_ok)
	var archive: Node=root.get_node("TraceData");archive.clear_traces()
	hand_at(right,ball.global_position);await frames(15);right.set_input("grip",1.0);await frames(25)
	check("XR grip picks up the smaller Shadow ball",game.pickups[1].picked_up_object==ball)
	var first: Vector3=ball.global_position
	for i in range(20):
		hand_at(right,first+Vector3(-i*0.065,0.25+sin(i*0.2)*0.2,-0.3))
		await frames(2)
	var samples: int=drawing.stroke.size();await frames(20)
	check("held movement makes a trace and stationary hand adds none",samples>5 and drawing.stroke.size()==samples)
	right.set_input("grip",0.0);await frames(12)
	check("release archives the ball's original world positions",archive.saved_traces.size()==1 and archive.saved_traces[0]==drawing.stroke and drawing.stroke[0].y< -20)
	var original: Array=archive.saved_traces[0].duplicate()
	var grid := Grid.new();game.add_child(grid);await frames(10)
	check("Grid consumes the Shadow ball trace unchanged",grid._trace_data_list.size()==1 and grid._trace_data_list[0].raw_points==original)
	grid.queue_free();await frames(2)
	var kept: int=drawing.ink.get_child_count()
	# A second pickup starts another stroke, never a bridge to the previous one.
	hand_at(right,ball.global_position);await frames(10);right.set_input("grip",1.0);await frames(20)
	check("picking up again does not connect separate strokes",drawing.ink.get_child_count()==kept and drawing.stroke.size()==1)
	hand_at(right,ball.global_position+Vector3(0,0.3,0));await frames(15)
	right.set_input("grip",0.0);await frames(12)
	check("second released stroke preserves the first record",archive.saved_traces.size()==2 and archive.saved_traces[0]==original)
	kept=drawing.ink.get_child_count()
	ball.position=Vector3(0,-3,0);record.reset_after_fall();await frames(3)
	check("lost ball returns to its stand without erasing ink",ball.position.is_zero_approx() and drawing.ink.get_child_count()==kept and archive.saved_traces[0]==original)
	var copy: Node3D=load("res://commons/void/trace_record.tscn").instantiate();game.add_child(copy)
	copy.apply_grid_config({"only_parts":["ShadowPoint"],"parts":{"ShadowPoint":{"position":[2,1,0]}}})
	check("editor copy isolates a fresh functioning Shadow point",copy.get_child_count()==1 and copy.get_node("ShadowPoint").point!=ball and copy.get_node("ShadowPoint").position==Vector3(2,1,0))
	copy.reset_after_fall();copy.queue_free()
	game.queue_free();await frames(3)
	for item in [head,left,right]: XRServer.remove_tracker(item)
	# Shadow Game's desktop hooks are retained. Void's walker currently has no
	# desktop hand, so this checks the adapter, not a playable desktop pickup UI.
	await start(false)
	game.checkpoint=4;game.place_player(Vector3(-15,-23.94,4.2));await frames(25)
	drawing=game.building.content.exhibits["4/record"].get_node("Artifact/ShadowPoint")
	archive.clear_traces()
	drawing.point.on_desktop_grab(null);await frames(15)
	check("Shadow desktop pickup hook remains available",drawing.point.is_held())
	drawing.point.position+=Vector3(0,0.35,0);await frames(20)
	drawing.point.on_desktop_drop(null);await frames(10)
	check("Shadow desktop release hook keeps a trace for Grid",not drawing.point.is_held() and archive.saved_traces.size()==1)
	game.queue_free();await frames(3)

func descent_contract(use_xr: bool) -> void:
	await start(use_xr)
	var tag := "XR" if use_xr else "Desktop"
	game.checkpoint=3;game.place_player(Vector3(13.3,-17.94,-1.65));await frames(25)
	var count: int = game.deaths
	check(tag+": drop from Lines onto first timber landing",await move_to(Vector3(11,-21,-1.65)))
	check(tag+": intermediate landing keeps Lines checkpoint",game.checkpoint==3 and game.deaths==count)
	check(tag+": jump to offset lower timber landing",await move_to(Vector3(11,-24,1.85),true))
	await frames(15)
	check(tag+": lower landing saves Trace checkpoint",game.checkpoint==4 and game.deaths==count)
	check(tag+": walk off timber onto Trace floor",await move_to(Vector3(11,-24,4)))
	var route_clear := true
	for waypoint in game.building.content.data.floors[4].route:
		if not await move_to(Vector3(waypoint.position[0],-24,waypoint.position[1])):
			route_clear=false;break
	check(tag+": walk the full glass-beads-monitor-ramp route",route_clear)
	var hit := ray(Vector3(11,-20,-1.65),Vector3(11,-21.2,-1.65))
	check(tag+": visible 6cm plank equals collision",not hit.is_empty() and hit.collider.skin=="plank" and is_equal_approx(hit.collider.get_node("PickupBody").shape.size.y,0.06) and is_equal_approx(hit.position.y,-21))
	game.place_player(Vector3(10,-23.94,0));await wait_for_recovery(count)
	check(tag+": missing the open shaft returns to Trace",game.deaths==count+1 and game.checkpoint==4 and not game.recovering and game.body.is_on_floor())
	game.queue_free();await frames(3)
	if use_xr:
		for item in [head,left,right]: XRServer.remove_tracker(item)

func pictures() -> void:
	await start(false)
	game._set_enabled(false)
	game.status.hide();game.notice_time=-1
	for layer in game.find_children("*","CanvasLayer",true,false): layer.hide()
	root.msaa_3d=Viewport.MSAA_4X
	var cam := Camera3D.new();root.add_child(cam);cam.environment=game.atmosphere.environment;cam.make_current();cam.fov=75
	for shot in [
		["trace-shadow",Vector3(-12.7,-22.2,6),Vector3(-16.5,-22.85,0.8)],
		["trace-room",Vector3(3.8,-22.35,6),Vector3(-1,-23,-1)],
		["trace-beads",Vector3(1,-22,5.4),Vector3(-1,-22.85,0)],
		["trace-ramp",Vector3(14,-21.7,4),Vector3(16.5,-23,-.2)],
		["trace-shaft",Vector3(8,-19.0,-2.2),Vector3(11.5,-22.5,0.6)]
	]:
		cam.position=shot[1];cam.look_at(shot[2]);await frames(25);await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join(shot[0]+".png"))
	game.queue_free();cam.queue_free();await frames(3)
