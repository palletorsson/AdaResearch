extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("LAUNCH CHAMBER ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="VFM_05_Launch"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/launch-chamber-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","forces");em.set("start_map",map_name)
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for r in em.get("_segments"):
		if r.node.get_meta("em_map","")==map_name:seg=r.node;break
	check(seg!=null,"hall loads: "+map_name)
	if not seg:quit(1);return
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var cam=Camera3D.new();em.add_child(cam);cam.fov=65
	var ui=seg.find_child("LaunchChamber",true,false);check(ui!=null,"full-scale launch chamber instantiates")
	if not ui:quit(1);return
	print("LAUNCH PLACEMENT ",seg.to_local(ui.global_position)," BASIS ",ui.global_basis.get_scale())
	ui.set_process(false)
	check(not ui.get_parent()._rack_built,"room variant replaces tabletop rack")
	check(not ui.show_path and not ui.revealed and not ui.fired,"flight begins as a question before predicted paths and equations")
	check(is_equal_approx(ui.launch_velocity(0).length(),10.0),"initial velocity has specified speed")
	press(ui,"PAIR",cam)
	check(ui.paired and is_equal_approx(ui.flight_position(0,10).x,ui.flight_position(1,10).x),"complementary angles have equal horizontal range")
	check(ui.duration(0)<ui.duration(1),"shallow paired flight lands sooner")
	press(ui,"FIRE",cam);ui._process(1.1)
	check(ui.wall.text.contains("A LANDED / B IN FLIGHT"),"one live marker lands while its partner remains airborne")
	check(is_equal_approx(ui.balls[0].position.y,0.3) and ui.balls[1].position.y>0.3,"separate landing clocks govern the two marker positions")
	ui._process(4)
	check(ui.wall.text.contains("A LANDED / B LANDED"),"both flights finish at their own landing height")
	check(is_equal_approx(ui.flight_velocity(0,0.4).x,ui.launch_velocity(0).x),"uniform gravity leaves horizontal velocity unchanged")
	check(is_equal_approx(ui.flight_velocity(0,ui.duration(0)*0.5).y,0.0),"vertical velocity reaches zero at apex")
	press(ui,"FIRE",cam);press(ui,"SLOW",cam);ui._process(1.0)
	check(is_equal_approx(ui.elapsed,0.25) and ui.slow,"slow control changes only playback rate to one quarter")
	var slow_point=ui.balls[0].position;press(ui,"FIRE",cam);press(ui,"SLOW",cam);ui._process(0.25)
	check(ui.balls[0].position.is_equal_approx(slow_point),"same model time gives the same position at either playback rate")
	press(ui,"GRAVITY",cam)
	check(ui.gravity==15 and not ui.fired and ui.elapsed==0,"changing gravity starts a fresh comparison")
	var short_range=ui.flight_position(0,10).x;press(ui,"GRAVITY",cam)
	check(ui.flight_position(0,10).x>short_range,"stronger gravity reduces range at fixed launch velocity")
	press(ui,"SPEED",cam);check(ui.speed==6,"speed control changes launch magnitude")
	for i in 30:press(ui,"ANGLE+",cam)
	check(ui.angle_deg==75,"angle upper bound")
	for i in 30:press(ui,"ANGLE-",cam)
	check(ui.angle_deg==15,"angle lower bound")
	ui.speed=10;ui.angle_deg=45;ui.rebuild();ui.update_flight()
	check(is_equal_approx(ui.flight_position(0,10).x-ui.ORIGIN_X,10.0),"full-scale maximum range is ten actual scene metres")
	press(ui,"PATH",cam);check(ui.show_path and ui.flight_root.get_child_count()>=128,"path reveal constructs both sampled predictions")
	press(ui,"PARTS",cam);press(ui,"RULE",cam)
	check(ui.show_parts and ui.wall.text.contains("Velocity: 1 m/s drawn as 0.2 m"),"component reveal states arrow units and scaling")
	var pool=ui.arrow_pool.size();press(ui,"FIRE",cam)
	for i in 120:ui._process(1.0/120.0)
	check(ui.arrow_pool.size()<=8 and ui.arrow_pool.size()==pool,"moving vector arrows reuse their meshes")
	var fine=ui.balls[0].position;press(ui,"FIRE",cam);ui._process(1.0)
	check(ui.balls[0].position.is_equal_approx(fine),"analytic position agrees across frame partitions")
	var player_before=player.global_position;press(ui,"FIRE",cam);ui.set_process(true);await create_timer(1.7).timeout;ui.set_process(false)
	check(ui.elapsed>=ui.duration(0) and ui.balls[0].position.is_equal_approx(ui.flight_position(0,10)),"actual render frames carry marker through full flight")
	check(player.global_position.is_equal_approx(player_before),"chamber controls do not move the player")
	check(ui.balls.all(func(ball):return ball is MeshInstance3D and ball.get_child_count()==0),"flight markers have no collision bodies")
	check(ui.buttons.values().all(func(button):return button.global_position.y>0.9 and button.global_position.y<1.4),"central controls at standing reach height")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()]
	await physics_frame
	for p in [Vector3(0,0.95,0),Vector3(2.5,0.95,0),Vector3(-2.5,0.95,0),Vector3(2.5,0.95,4),Vector3(2.5,0.95,-4),Vector3(2.5,0.95,1),Vector3(2.5,0.95,2),Vector3(2.5,0.95,3),Vector3(2.5,0.95,-1),Vector3(2.5,0.95,-2),Vector3(2.5,0.95,-3)]:
		q.transform.origin=ui.to_global(p);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear centre and approach "+str(p))
	var legacy=load("res://commons/artifacts/launch_arc/launch_arc.tscn").instantiate();legacy.position.y=-100;root.add_child(legacy)
	check(legacy._rack_built and legacy.find_child("LaunchChamber",true,false)==null,"ordinary tabletop launch remains available");legacy.queue_free()
	ui.angle_deg=30;ui.speed=10;ui.gravity=10;ui.rebuild();press(ui,"FIRE",cam);ui._process(0.7)
	cam.global_position=ui.to_global(Vector3(0,1.7,0));cam.look_at(ui.to_global(Vector3(-1.0,1.8,-3)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/launch_chamber_inside.png")
	cam.global_position=ui.to_global(Vector3(7.5,5.6,-4.3));cam.look_at(ui.to_global(Vector3(0,2,0)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/launch_chamber_overview.png")
	f=FileAccess.open("res://ada_run/launch_chamber_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("LAUNCH CHAMBER COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
