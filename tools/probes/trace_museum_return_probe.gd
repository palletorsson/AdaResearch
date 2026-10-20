extends "res://tools/probes/void_trace_light_probe.gd"
## Real tower, original museum recorders, actual desktop and XRTools grabs.
var tag := ""
var aim := Vector3.ZERO

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	for mode in ([true] if "--capture" in OS.get_cmdline_user_args() else [false,true]):
		await encounters(mode)
	OS.delay_msec(200)
	await frames(30)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Native Godot desktop and synthetic XR grip/release. Rendered captures use Mobile. No physical headset test; no claim about long-session performance."},"\t"))
	quit(0 if failed.is_empty() else 1)

func grab(body: Node3D) -> void:
	if xr:
		aim=body.global_position
		hand_at(right,aim);await frames(12);right.set_input("grip",1.0)
	else: game.body.desktop_pointer._grab_held(body)
	await frames(15)
	check(tag+"pickup "+body.name,body.is_picked_up())

func carry(body: Node3D, where: Vector3) -> void:
	if xr:
		aim+=where-body.global_position
		hand_at(right,aim)
	else:
		game.camera.global_position=where+Vector3(0,0,1.5)
		game.camera.global_basis=Basis.IDENTITY
		game.body.desktop_pointer._hold_distance=1.5
	await frames(4)

func release() -> void:
	if xr: right.set_input("grip",0.0)
	else: game.body.desktop_pointer._drop_held()
	await frames(15)

func picture(file: String, at: Vector3, towards: Vector3) -> void:
	if "--capture" in OS.get_cmdline_user_args(): await photograph(file,at,towards)

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	if DisplayServer.get_name()=="headless": return
	# Hide the player's HUD, not the monitor's private teaching UI.
	for layer in game.find_children("*","CanvasLayer",true,false):
		if layer.get_viewport()==game.get_viewport(): layer.hide()
	game.status.hide();game.notice_time=-1
	var walk:Node3D=game.building.content.exhibits["4/museum-point_line_grid-1-9"].get_node("Artifact")
	walk.clear_trail() # Test teleports are not the visitor's walking gesture.
	var origin:Node3D=game.get_node("XROrigin3D")
	origin.hide()
	var cam:=Camera3D.new();root.add_child(cam)
	cam.environment=game.atmosphere.environment
	cam.position=at;cam.look_at(target);cam.make_current()
	root.msaa_3d=Viewport.MSAA_4X
	await frames(20);await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(filename))
	cam.queue_free();await frames(2)
	game.camera.make_current();origin.show()

func encounters(use_xr: bool) -> void:
	await arrive(use_xr)
	tag="XR: " if xr else "Desktop: "
	game.atmosphere.animate_sky=false;game.atmosphere.set_sky_time(180)
	var content:Node3D=game.building.content
	var record:Node3D=content.exhibits["4/record"].get_node("Artifact")
	var archive:Node=root.get_node("TraceData")
	var grid:Node3D=record.get_node("GridReplay/SavedTraceGrid")
	check(tag+"no invented trace on arrival",archive.saved_traces.is_empty() and grid._trace_data_list.is_empty())
	await glass_trial(content.exhibits["4/surface"].get_node("Artifact/GlassWall"))
	check(tag+"glass image stays local",archive.saved_traces.is_empty())
	var monitor:Node3D=record.get_node("SamplingMonitor")
	for title in ["Bead10mm","Bead40mm","Bead80mm"]:
		var bead:Node3D=record.get_node(NodePath(title))
		var point:Node3D=bead.get_node("GrabPoint")
		check(tag+title+" original recorder and reachable readout",bead.get_script().resource_path.ends_with("point/draw_dot.gd") and bead._data_mount_ready and absf(bead._data_panel.global_position.y+23.1)<.8)
		game.place_player(Vector3(-5.3,-23.94,point.global_position.z));await frames(12)
		await grab(point)
		var beginning:Vector3=point.global_position
		for i in range(40):
			var t:=float(i)/39.0*TAU
			await carry(point,beginning+Vector3(.45+sin(t)*.28,.38+cos(t)*.3,sin(t*2)*.21))
		check(tag+title+" monitor records this same gesture",monitor.active_source==bead and monitor.stage.record.positions.size()>40 and monitor.sources.size()==3)
		await frames(12)
		var count:int=bead._trail_points.size();await frames(30)
		check(tag+title+" holding still adds no retained position",bead._trail_points.size()==count)
		var snapped:=true
		var previous:=Vector3.INF
		for p:Vector3 in bead._trail_points:
			snapped=snapped and p.is_equal_approx(p.snapped(Vector3.ONE*bead.resolution_mm/1000.0)) and p!=previous
			previous=p
		check(tag+title+" retained positions obey its grid without adjacent repeats",snapped and count>8)
		await release()
		var light:Node3D=bead.get_node("TraceIllumination")
		check(tag+title+" release preserves drawing, lights and exact Grid source",archive.saved_traces[-1]==bead._trail_points and grid._trace_data_list[-1].raw_points==bead._trail_points and light.tubes.multimesh.visible_instance_count==count-1 and light.lamps[0].visible)
	check(tag+"sampling monitor compares one source at three resolutions",monitor.stage.record.samples(INF,1,0).size()>monitor.stage.record.samples(INF,1,2).size())
	monitor.force_active=true;monitor.stage.mode=1;monitor.activate("replay");await frames(90)
	await picture("three-grains.png",Vector3(-3.5,-22.1,4.0),Vector3(-6.35,-22.8,.35))
	await picture("same-gesture.png",Vector3(7.8,-22.3,-4.5),Vector3(7.5,-22.3,-7.5))
	var original:Array=archive.saved_traces[0].duplicate()
	grid.point_selection.select_point(4);grid.get_node("ArchivePanel/NextPage").pressed.emit();await frames(8)
	check(tag+"Grid selection and paging preserve original coordinates",archive.saved_traces[0]==original and grid._trace_data_list[0].raw_points==original)
	check(tag+"Grid leaves Trace opening clear; controls stand on west rim",grid.global_position.is_equal_approx(Vector3(-10,-25,0)) and grid._data_panel.global_position.is_equal_approx(Vector3(-13.1,-22.8,1.8)) and ray(Vector3(-10,-24.2,0),Vector3(-10,-27,0)).is_empty())
	# Below this floor, an existing Triangle MuseumPlinth intersects the shaft
	# at y=-28.95. Keep that curator placement and report it, not a false pass
	# claiming the entire multi-storey opening is unobstructed.
	await picture("grid-and-source.png",Vector3(-15.1,-22.1,4.5),Vector3(-10.8,-23.6,.6))
	await ball_trial(content.exhibits["4/release"].get_node("Artifact/BallRamp"))
	check(tag+"rolling-ball paths do not enter the bead archive",archive.saved_traces.size()==3)
	var shadow:Node3D=record.get_node("ShadowPoint")
	game.place_player(Vector3(17,-23.94,3));await frames(12)
	await grab(shadow.point)
	var beginning:Vector3=shadow.point.global_position
	for i in range(28):
		var t:=float(i)/27*TAU
		await carry(shadow.point,beginning+Vector3(sin(t)*.65,.5+cos(t)*.4,.3+sin(t*2)*.3))
	await release()
	check(tag+"small black point keeps its own lit stroke and supplies Grid",archive.saved_traces.size()==4 and archive.saved_traces[-1]==shadow.stroke and shadow.get_node("TraceIllumination").lamps[0].visible)
	await picture("black-point.png",Vector3(16,-22.1,5.6),Vector3(18.5,-22.4,3.3))
	var segments:int=shadow.ink.get_child_count()
	await grab(shadow.point);await frames(10);await release()
	check(tag+"regrabbing without moving draws no connecting stroke",segments==shadow.ink.get_child_count())
	# Same part isolation, transform and fresh instance used by the editor.
	var copy:Node3D=load("res://commons/void/trace_record.tscn").instantiate()
	copy.position=Vector3(0,-24,0);game.add_child(copy)
	copy.apply_grid_config({"only_parts":["GridReplay"],"parts":{"GridReplay":{"position":[0,0,0],"rotation":[0,90,0]}}})
	await frames(10)
	check(tag+"editor Grid copy rotates independently and reads the same archive",copy.get_child_count()==1 and is_equal_approx(copy.get_node("GridReplay").rotation_degrees.y,90) and copy.get_node("GridReplay/SavedTraceGrid")._trace_data_list[0].raw_points==original)
	copy.queue_free();await frames(5)
	var walk:Node3D=content.exhibits["4/museum-point_line_grid-1-9"].get_node("Artifact")
	game.place_player(Vector3(-14.2,-23.94,4.3));await frames(15);walk.clear_trail()
	var walked:bool=await move_to(Vector3(-14.2,-24,1.8))
	var correct_y:bool=not walk._trail_points.is_empty()
	for p:Vector3 in walk._trail_points: correct_y=correct_y and absf(walk.to_global(p).y+24)<.15
	check(tag+"walking Grid keeps one-metre snapping and the unrounded ghost",walked and is_equal_approx(walk.seam_grid,1) and walk.show_discarded and walk._truth_points.size()>walk._trail_points.size())
	check(tag+"walking trace lies on this tower floor",correct_y)
	game.place_player(game.spawn_for(0));await frames(20)
	check(tag+"sleeping floor clears walking line and disables trace lights",walk._trail_points.is_empty() and active_lights()==0)
	game.place_player(game.spawn_for(4));await frames(25)
	check(tag+"return retains drawings and their original world coordinates",archive.saved_traces[0]==original and grid._trace_data_list[0].raw_points==original and active_lights()>0)
	game.die("Trace return");await wait_for_recovery(0)
	check(tag+"retry preserves the session archive",not game.recovering and game.checkpoint==4 and archive.saved_traces[0]==original)
	await finish_room(use_xr)

func glass_trial(glass: Node3D) -> void:
	var drawing:Node3D=glass.get_node("DrawingTools")
	check(tag+"original transparent glass, four pens and eraser",glass.glass_surface and drawing.transparent_ink and drawing.pens.size()==5)
	game.place_player(Vector3(-.25,-23.94,-6));await frames(12)
	var pen:Node3D=drawing.pens[1]
	await grab(pen)
	var before:int=drawing.stroke_events
	await pen_tip(pen,drawing,Vector3(-.6,.7,.3))
	check(tag+"pen leaves air blank",drawing.stroke_events==before)
	for x in [-.6,-.5,-.4,-.3]: await pen_tip(pen,drawing,Vector3(x,.7,.044))
	check(tag+"contact on glass records ink",drawing.stroke_events>before)
	await pen_tip(pen,drawing,Vector3(0,.7,.3))
	check(tag+"lifting breaks the stroke",pen._previous.x<0)
	for x in [.3,.4,.5,.6]: await pen_tip(pen,drawing,Vector3(x,.7,.044))
	await release()
	check(tag+"glass ink exists on both sides of a transparent gap",ink_alpha(drawing,-.45)>.9 and ink_alpha(drawing,.45)>.9 and ink_alpha(drawing,0)<.01)
	await picture("glass-contact.png",Vector3(.7,-22.3,-4.8),Vector3(-.25,-22.7,-7.5))
	var eraser:Node3D=drawing.pens[4]
	await grab(eraser);before=drawing.stroke_events
	await pen_tip(eraser,drawing,Vector3(-.45,.7,.044))
	check(tag+"eraser delivers a local clear operation",drawing.stroke_events>before and eraser.eraser)
	await release()
	check(tag+"erasing restores transparency without clearing remote ink",ink_alpha(drawing,-.45)<.01 and ink_alpha(drawing,.45)>.9)

func ink_alpha(drawing:Node3D,x:float) -> float:
	var uv:Vector2=drawing.sample_uv(drawing.to_global(Vector3(x,.7,.044)),0)
	var image:Image=drawing.canvas._image
	return image.get_pixel(roundi(uv.x*image.get_width()),roundi(uv.y*image.get_height())).a

func pen_tip(pen:Node3D,drawing:Node3D,local_point:Vector3) -> void:
	for repeat in range(2):
		await carry(pen,pen.global_position+drawing.to_global(local_point)-pen.get_node("WritingTip").global_position)

func ball_trial(ramp:Node3D) -> void:
	game.place_player(ramp.global_position+Vector3(1.4,.06,0));await frames(15)
	var ball:Node3D=ramp.ball
	await grab(ball);await carry(ball,ramp.to_global(Vector3(0,1.5,.8)))
	# Let the pickup driver's throw history settle: this encounter is release,
	# not an accidental throw caused by the test moving the hand quickly.
	await frames(60);await release();await frames(480)
	var landed:Vector3=ramp.to_local(ball.global_position)
	check(tag+"released ball rolls into the tray and retains measured segments",landed.z>3.7 and landed.z<5.4 and landed.y>.1 and landed.y<.4 and ramp.traces[0].segment_count>30)
	check(tag+"stand supplies a new ball without removing the old one",ramp.traces.size()==2 and ramp.ball!=ball and is_instance_valid(ramp.ball) and ramp.ball.freeze)
	await picture("gravity-draws.png",ramp.global_position+Vector3(3.4,2.3,5.5),ramp.global_position+Vector3(0,.55,2.2))
