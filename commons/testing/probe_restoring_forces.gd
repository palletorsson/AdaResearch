extends SceneTree
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("RESTORING ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="Vectors_Act4b_Oscillation"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/restoring-forces-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var ui=seg.find_child("RestoringForces",true,false);check(ui!=null,"spring variant loads")
	if not ui:quit(1);return
	ui.set_physics_process(false)
	check(ui.global_basis.get_scale().is_equal_approx(Vector3.ONE),"model and room use metre scale")
	check(ui.handle.freeze and ui.handle.collision_mask==0 and ui.handle.is_in_group("no_gravity_gun"),"handle has no competing solver or gravity-gun unfreeze")
	check(not ui.running and not ui.parts and not ui.rule,"start ready with explanations hidden")
	press(ui,"RELEASE",cam);var initial=ui.energy()
	for i in 60:ui.advance(1.0/60)
	check(absf(ui.displacement-1.25*cos(2.0))<0.02,"free spring matches analytical displacement at one second")
	check(absf(ui.velocity+2.5*sin(2.0))<0.02,"free spring matches analytical velocity")
	check(absf(ui.energy()/initial-1)<0.015,"undamped energy error stays within discretisation tolerance")
	check(ui.crossings==1,"inertia carries free body across equilibrium")
	press(ui,"RESET",cam);press(ui,"RELEASE",cam)
	for i in 240:ui.advance(1.0/60)
	var partition=Vector2(ui.displacement,ui.velocity)
	press(ui,"RESET",cam);press(ui,"RELEASE",cam)
	for i in 120:ui.advance(1.0/30)
	check(partition.distance_to(Vector2(ui.displacement,ui.velocity))<0.00001,"30/60 Hz frame partitions agree")
	press(ui,"RESET",cam);press(ui,"RELEASE",cam);ui.advance(1.0)
	check(absf(ui.elapsed-0.25)<0.0001,"long stall catch-up is explicitly bounded")
	press(ui,"RESET",cam);press(ui,"DAMP",cam);press(ui,"RELEASE",cam)
	initial=ui.energy()
	for i in 360:ui.advance(1.0/60)
	check(ui.crossings>0 and ui.energy()<initial*0.01,"light damping crosses and loses energy")
	press(ui,"RESET",cam);press(ui,"DAMP",cam);press(ui,"RELEASE",cam)
	for i in 120:ui.advance(1.0/60)
	var critical_x=ui.displacement
	check(ui.crossings==0 and critical_x>0 and critical_x<0.13,"critical return from rest approaches without crossing")
	press(ui,"RESET",cam);press(ui,"DAMP",cam);press(ui,"RELEASE",cam)
	for i in 120:ui.advance(1.0/60)
	check(ui.crossings==0 and ui.displacement>critical_x*3,"heavy damping returns more slowly than critical")
	press(ui,"DAMP",cam);check(ui.damping_index==0,"damping cycle returns to free")
	var state=Vector2(ui.displacement,ui.velocity);press(ui,"MASS",cam)
	check(ui.mass_value==4 and state==Vector2(ui.displacement,ui.velocity),"mass edit retains position and velocity")
	press(ui,"SPRING",cam);check(ui.stiffness==16 and state==Vector2(ui.displacement,ui.velocity),"spring edit retains position and velocity")
	ui.damping_index=2;check(absf(ui.damping_coefficient()-2*sqrt(ui.stiffness*ui.mass_value))<0.00001,"critical damping recalculates with mass and stiffness")
	ui.reset_pose();ui.mass_value=2;ui.stiffness=8;ui.damping_index=0;press(ui,"RELEASE",cam)
	for i in 60:ui.advance(1.0/60)
	var light_x=ui.displacement;ui.reset_pose();ui.mass_value=4;press(ui,"RELEASE",cam)
	for i in 60:ui.advance(1.0/60)
	check(light_x<0 and ui.displacement>0,"heavier body takes longer to first crossing")
	ui.mass_value=2;ui.reset_pose();press(ui,"PULL",cam)
	check(ui.displacement==-1.25 and not ui.running and ui.velocity==0,"PULL offers a held opposite-side release")
	var held=ui.displacement;ui.advance(1);check(ui.displacement==held,"held state does not integrate")
	# Exercise XRTools pickup/drop with a supplied non-headset grabber.
	var grabber=SuppliedGrabber.new();em.add_child(grabber);grabber.global_transform=ui.handle.global_transform
	ui.handle.pick_up(grabber);check(ui.grabbed and not ui.running,"actual pickup signal holds model")
	grabber.global_position=ui.to_global(Vector3(1,2.1,0.7))
	for i in 5:await physics_frame
	check(absf(ui.displacement-1)<0.03,"supplied hand controls displacement")
	check(absf(ui.handle.position.y-ui.HEIGHT)<0.001 and absf(ui.handle.position.z)<0.001,"grab is constrained to horizontal axis")
	grabber.global_position=ui.to_global(Vector3(5,3,2))
	for i in 5:await physics_frame
	check(absf(ui.displacement-ui.PULL_LIMIT)<0.001,"hand pull is bounded")
	ui.handle.let_go(grabber,Vector3(20,20,20),Vector3.ONE)
	check(not ui.grabbed and ui.running and ui.velocity==0 and ui.handle.freeze,"release starts numerical model from rest, excluding hand throw")
	ui.advance(0.1);check(ui.velocity<0,"release actually produces restoring acceleration")
	grabber.queue_free()
	ui.reset_pose(0);ui.velocity=2;ui.damping_index=1
	var forces=ui.forces();check(forces.x==0 and forces.y<0,"at equilibrium damping can remain while spring force is zero")
	ui.reset_pose(1);ui.velocity=-1;forces=ui.forces()
	check(forces.x<0 and forces.y>0 and absf(forces.z-forces.x-forces.y)<0.00001,"on return damping and restoring force oppose one another")
	press(ui,"PARTS",cam);press(ui,"RULE",cam);ui.update_visuals();ui.update_text()
	check(ui.arrows.size()==6 and ui.arrows[0].position.x<ui.displacement and ui.arrows[2].position.x>ui.displacement,"body arrows show signed force directions")
	check(ui.arrows[0].get_child(0).scale.y==ui.arrows[1].get_child(0).scale.y,"wall and body arrows share magnitude and scale")
	check(ui.board.text.contains("120 steps") and ui.force_labels[0].text.contains("N"),"revealed rule and force units are explicit")
	var count=ui.get_child_count();for i in 20:ui.update_visuals()
	check(count==ui.get_child_count(),"coil and arrow geometry reused")
	ui.reset_pose(2.24);ui.velocity=10;ui.running=true;ui.advance(0.05)
	check(ui.frame_exit and not ui.running and ui.velocity!=0,"observation exit holds outgoing state")
	ui.reset_pose();var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()];q.collide_with_areas=false
	await physics_frame
	for at in [Vector3(0,1,-4),Vector3(0,1,-3.2),Vector3(0,1,-1.5),Vector3(2.5,1,0),Vector3(-2.5,1,0),Vector3(0,1,2)]:
		q.transform.origin=ui.to_global(at);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear approach "+str(at))
	check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"controls within standing reach")
	for node in seg.find_children("*","Node3D",true,false):
		if node.get_meta("artifact_lookup_name","") in ["pendulum_hall","calder_mobile","calder_object_mobile"]:
			check(node.find_children("*","Label3D",true,false).all(func(l):return not l.no_depth_test),"supporting labels respect wall occlusion: "+str(node.name))
	var sculpture: Node3D
	for node in seg.find_children("*","Node3D",true,false):
		if node.get_meta("artifact_lookup_name","")=="surreal_kinetic_sculpture":sculpture=node;break
	check(sculpture!=null and absf(sculpture.global_basis.get_scale().x-0.12)<0.001,"supporting sculpture is compact")
	if sculpture:
		check(sculpture.find_children("*","Light3D",true,false).all(func(n):return not n.visible),"supporting sculpture does not relight whole room")
		check(sculpture.find_children("*","Control",true,false).all(func(n):return not n.visible),"standalone screen overlays disabled in museum")
	var legacy=load("res://commons/artifacts/spring_tower/spring_tower.tscn").instantiate();em.add_child(legacy)
	check(legacy.find_child("RestoringForces",true,false)==null and legacy._mass!=null,"legacy tower remains available outside opt-in hall");legacy.queue_free()
	ui.damping_index=1;ui.reset_pose();ui.release_body();ui.advance(0.25);ui.advance(0.25);ui.update_visuals();ui.update_text()
	cam.global_position=ui.to_global(Vector3(4.2,4.2,-5.5));cam.look_at(ui.to_global(Vector3(0,1.8,0)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/restoring_overview.png")
	cam.global_position=ui.to_global(Vector3(0,1.75,-2.1));cam.look_at(ui.to_global(Vector3(0,2.2,1)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/restoring_inside.png")
	f=FileAccess.open("res://ada_run/restoring_forces_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("RESTORING COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
