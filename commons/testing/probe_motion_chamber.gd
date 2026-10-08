extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("MOTION CHAMBER ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="VFM_03_Motion"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/motion-chamber-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var ui=seg.find_child("MotionChamber",true,false);check(ui!=null,"rigid-body motion chamber loads")
	if not ui:quit(1);return
	check(ui.body is RigidBody3D and ui.body.mass==1,"one-kilogram rigid body is the receiver")
	check(ui.body.gravity_scale==0 and ui.body.linear_damp==0 and ui.body.linear_damp_mode==RigidBody3D.DAMP_MODE_REPLACE,"coast explicitly excludes gravity and inherited damping")
	check(not ui.body.can_sleep and ui.body.axis_lock_linear_y,"body stays awake in a declared horizontal model")
	press(ui,"RESET",cam);await physics_frame;await physics_frame
	press(ui,"PUSH X",cam);await create_timer(1.15).timeout
	var speed_one=ui.velocity().length();check(absf(speed_one-2.0)<0.09,"two newtons for one second produce about two m/s at one kg: "+str(speed_one))
	check(ui.pulse_left==0 and ui.local_force.is_zero_approx(),"finite push ends automatically")
	var before=ui.body.position;press(ui,"COAST",cam);await create_timer(0.7).timeout
	check(absf(ui.velocity().length()-speed_one)<0.03 and ui.body.position.distance_to(before)>1.2,"velocity and movement persist after command ends")
	press(ui,"BRAKE",cam);await create_timer(1.2).timeout
	check(ui.velocity().length()<0.05,"opposing force brakes without a velocity reset")
	press(ui,"MASS",cam);await physics_frame;await physics_frame
	check(ui.body.mass==2 and ui.velocity().length()<0.03,"mass comparison resets velocity and doubles mass")
	press(ui,"PUSH X",cam);await create_timer(1.15).timeout
	check(absf(ui.velocity().length()-speed_one*0.5)<0.06,"same pulse produces half the velocity change at double mass")
	press(ui,"RESET",cam);await physics_frame;await physics_frame
	press(ui,"PUSH X",cam);await create_timer(0.35).timeout;press(ui,"COAST",cam);await create_timer(0.2).timeout
	check(ui.velocity().x>0.2 and ui.velocity().x<0.7,"COAST can cut a pulse short without erasing acquired velocity")
	press(ui,"PUSH F",cam);await create_timer(1.15).timeout
	check(ui.velocity().x>0.2 and ui.velocity().z< -0.9,"new perpendicular force retains old velocity component")
	press(ui,"RESET",cam);await physics_frame;await physics_frame
	ui.body.linear_velocity=ui.global_basis*Vector3(2,0,0);press(ui,"DRAG",cam);press(ui,"COAST",cam);await create_timer(1).timeout
	check(ui.drag_on and ui.velocity().length()<1.2 and ui.velocity().length()>0.2,"COAST leaves enabled engine damping active")
	press(ui,"DRAG",cam);press(ui,"RESET",cam);await physics_frame;await physics_frame
	ui.body.position=Vector3(4.5,1,-2);ui.body.linear_velocity=ui.global_basis*Vector3(2,0,0);await create_timer(0.7).timeout
	check(ui.velocity().x< -1.8 and absf(ui.velocity().length()-2.0)<0.12,"elastic frame reflects velocity instead of silently wrapping")
	check(absf(ui.body.position.y-1)<0.001,"height lock holds during contact")
	press(ui,"PARTS",cam);press(ui,"TRAIL",cam);press(ui,"RULE",cam)
	check(ui.parts and ui.trail_view.visible and ui.wall.text.contains("measured a"),"pointer reveals measured state, command and trail")
	var count=ui.get_child_count();await create_timer(0.2).timeout;check(ui.get_child_count()==count and ui.arrows.size()==3,"moving arrows keep their node allocation stable")
	# History is bounded even when a saved run already contains the maximum samples.
	ui.trail_points.clear()
	for i in ui.TRAIL_LIMIT:ui.trail_points.append(ui.body.position)
	await create_timer(0.2).timeout;check(ui.trail_points.size()==120,"trail remains bounded to 120 samples")
	press(ui,"RESET",cam);check(ui.trail_points.is_empty() and ui.run_time==0,"RESET clears local history and run clock")
	check(ui.body.collision_mask==ui.BODY_LAYER,"body uses the model's declared collision layer")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()];q.collision_mask=1
	await physics_frame
	for p in [Vector3(0,0.95,0),Vector3(2.5,0.95,0),Vector3(2.5,0.95,2),Vector3(2.5,0.95,-2),Vector3(2.5,0.95,4),Vector3(2.5,0.95,-4)]:
		q.transform.origin=ui.to_global(p);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear operator/side approach "+str(p))
	check(ui.buttons.values().all(func(button):return button.global_position.y>0.9 and button.global_position.y<1.4),"central controls at standing height")
	var ramp
	for n in seg.find_children("*","Node",true,false):
		if n.get_meta("artifact_lookup_name","")=="friction_ramp":ramp=n;break
	check(ramp!=null and ramp.find_child("RoomStand",true,false)!=null,"second primary has a physical stand")
	if ramp:
		ramp.set_physics_process(false);ramp.ramp_angle_deg=30;ramp.friction_mu=1;ramp._reset_block();ramp._update_physics_state()
		check(not ramp._is_sliding,"ramp holds when friction bound exceeds downslope pull")
		ramp.friction_mu=0;ramp._reset_block();ramp._update_physics_state();ramp._physics_process(0.1)
		check(ramp._is_sliding and ramp._block_velocity>0,"ramp model accumulates velocity when its threshold is crossed")
		ramp.friction_mu=1
		check(ramp._block_velocity==0,"ramp's simplified static transition explicitly zeros velocity")
		check(ramp._control_panel.global_position.y>0.9 and ramp._control_panel.global_position.y<1.3,"ramp controls are raised to standing reach: root="+str(ramp.global_position)+" panel="+str(ramp._control_panel.global_position)+" scale="+str(ramp.global_basis.get_scale()))
		ramp.friction_mu=0.5;ramp._reset_block();ramp._update_physics_state()
	# Ordinary compact scene still builds outside the opt-in hall.
	var legacy=load("res://algorithms/vectors/08_vector_motion/VectorMotion.tscn").instantiate();legacy.position.y=-100;root.add_child(legacy)
	check(legacy.ball!=null and legacy.find_child("MotionChamber",true,false)==null,"legacy VectorMotion remains available");legacy.queue_free()
	ui.body.mass=1;press(ui,"RESET",cam);await physics_frame;await physics_frame;press(ui,"PUSH X",cam);await create_timer(0.65).timeout
	ui.set_physics_process(false);ui.body.freeze=true
	if ramp:
		cam.global_position=ramp.to_global(Vector3(1.1,0.9,1.6));cam.look_at(ramp.to_global(Vector3(0,0.1,0)))
		for i in 15:await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/motion_friction_stand.png")
	cam.global_position=ui.to_global(Vector3(0,1.7,0));cam.look_at(ui.to_global(Vector3(-1,1.5,-3)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/motion_chamber_inside.png")
	cam.global_position=ui.to_global(Vector3(7,6,-4));cam.look_at(ui.to_global(Vector3(0,1,0)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/motion_chamber_overview.png")
	f=FileAccess.open("res://ada_run/motion_chamber_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("MOTION CHAMBER COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
