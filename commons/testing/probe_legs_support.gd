extends SceneTree
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("LEGS SUPPORT ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="VFM_09_Legs"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/legs-support-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var ui=seg.find_child("SupportPolygonLab",true,false)
	check(ui!=null,"support experiment loads")
	if ui==null:quit(1);return
	check(ui.body is RigidBody3D and ui.body.mass==10,"actual ten-kilogram rigid load")
	check(ui.body.freeze and not ui.released,"initial body held for prediction")
	check(ui.global_basis.get_scale().is_equal_approx(Vector3.ONE),"experiment retains metre scale")
	check(ui.body.gravity_scale==1 and ui.body.collision_mask==ui.PRIVATE_LAYER,"gravity enabled and collision domain isolated")
	check(ui.supports.all(func(s):return s.physics_material_override.friction==ui.body.physics_material_override.friction),"support and load share explicit friction material")
	check(ui.com_marker.position==ui.body.center_of_mass,"X-ray marker locates actual mass centre")
	check(ui.body.linear_damp==0 and ui.body.angular_damp==0,"no added linear or angular damping")
	check(ui.active_indices().size()==4 and ui.margin()>1.4,"four finite pads enclose central load")
	var start=ui.body.position
	for i in 20:await physics_frame
	check(ui.body.position.is_equal_approx(start),"held state does not fall")
	press(ui,"RELEASE",cam)
	for i in 120:await physics_frame
	print("SUPPORT four tilt=",ui.tilt_degrees()," y=",ui.body.position.y)
	check(not ui.body.freeze and ui.released,"release enables engine integration")
	check(ui.tilt_degrees()<2 and ui.body.position.y>1.60,"four supports hold the released load level")
	press(ui,"FEET",cam);await physics_frame
	check(ui.mode==1 and ui.active_indices()==[1,2,3] and ui.body.freeze,"remove first support and reset held")
	check(ui.supports[0].collision_layer==0 and not ui.foot_meshes[0].visible,"removed support has neither collision nor visible post")
	check(ui.margin()>0 and ui.margin()<0.12,"finite pad width gives centred three-support case a small margin")
	press(ui,"SHIFT",cam);await physics_frame
	check(ui.body.center_of_mass==Vector3(-0.65,0,0.65) and ui.margin()>0.7,"shift away from missing corner moves physical mass centre inside")
	press(ui,"RELEASE",cam)
	for i in 120:await physics_frame
	print("SUPPORT inside tilt=",ui.tilt_degrees()," y=",ui.body.position.y)
	check(ui.tilt_degrees()<2 and ui.body.position.y>1.60,"three supports hold load shifted toward supported corner")
	press(ui,"SHIFT",cam);await physics_frame
	check(ui.margin()< -0.7 and ui.body.freeze,"shift toward missing corner predicts outside initial support")
	press(ui,"RELEASE",cam)
	for i in 120:await physics_frame
	print("SUPPORT outside tilt=",ui.tilt_degrees()," y=",ui.body.position.y)
	check(ui.tilt_degrees()>10,"load outside support tips under actual gravity")
	press(ui,"RESET",cam)
	for i in 3:await physics_frame
	check(ui.mode==1 and ui.shift_index==2 and ui.body.freeze,"reset retains selected supports and mass offset")
	check(ui.body.linear_velocity.length()<0.001 and ui.body.angular_velocity.length()<0.001,"reset clears motion")
	check(ui.tilt_degrees()<0.01 and ui.body.position.is_equal_approx(ui.START),"reset restores level pose")
	press(ui,"FEET",cam);press(ui,"SHIFT",cam);await physics_frame
	check(ui.mode==2 and ui.active_indices().size()==2 and ui.margin()< -1.2,"adjacent pair leaves centred load outside")
	press(ui,"RELEASE",cam)
	for i in 120:await physics_frame
	check(ui.tilt_degrees()>15,"adjacent pair permits actual tipping")
	press(ui,"FEET",cam);await physics_frame
	check(ui.mode==3 and ui.margin()>0 and ui.margin()<0.12,"diagonal pair of finite pads gives narrow positive margin")
	press(ui,"PARTS",cam);press(ui,"RULE",cam)
	check(ui.hull_mesh.visible and ui.wall_mesh.visible and ui.projection.visible,"parts reveal floor and wall from same state")
	check(ui.board.text.contains("initial footprint") and ui.board.text.contains("not a contact sensor"),"rule limits static forecast explicitly")
	var count=ui.get_child_count();for i in 30:ui.update_visuals()
	check(count==ui.get_child_count(),"live footprint reuses geometry")
	check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"standing controls within reach band")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()];q.collide_with_areas=false
	for at in [Vector3(0,1,-5),Vector3(0,1,-3),Vector3(3,1,0),Vector3(-3,1,0),Vector3(0,1,3)]:
		q.transform.origin=ui.to_global(at);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"body-sized approach "+str(at))
	# The comparison walker still uses its original kinematic stepping code.
	var walkers=[]
	for node in seg.find_children("Body","MeshInstance3D",true,false):
		if node.get_script()!=null and node.get_script().resource_path.ends_with("four_leg_critter.gd"):walkers.append(node)
	check(walkers.size()==1,"original four-leg walker remains in hall")
	if walkers.size()==1:check(walkers[0]._feet.size()==4 and walkers[0].driven_by_player==false,"comparison keeps four procedural foot targets and autonomous movement")
	ui.mode=1;ui.shift_index=1;ui.reset_experiment();await physics_frame;press(ui,"RELEASE",cam)
	for i in 90:await physics_frame
	cam.global_position=ui.to_global(Vector3(5.2,4.6,-6.4));cam.look_at(ui.to_global(Vector3(0,1.9,0)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/legs_support.png")
	ui.shift_index=2;ui.reset_experiment();await physics_frame;press(ui,"RELEASE",cam)
	for i in 60:await physics_frame
	cam.global_position=ui.to_global(Vector3(5.2,4.6,-6.4));cam.look_at(ui.to_global(Vector3(0,1.9,0)))
	for i in 3:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/legs_tipping.png")
	if walkers.size()==1:
		var walker=walkers[0]
		cam.global_position=walker.global_position+Vector3(4,1.7,-5.5);cam.look_at(walker.global_position)
		for i in 5:await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/legs_walker.png")
	f=FileAccess.open("res://ada_run/legs_support_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("LEGS SUPPORT COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
