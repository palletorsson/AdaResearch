extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("FIELD RECEIVERS ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="Vectors_Act3_FieldsAndMotion"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/field-receivers-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var ui=seg.find_child("FieldReceivers",true,false)
	check(ui!=null,"full-scale field receivers load")
	if not ui:quit(1);return
	ui.set_physics_process(false)
	check(ui.global_basis.get_scale().is_equal_approx(Vector3.ONE),"scene uses actual metres")
	check(ui.positions[0]==ui.positions[1] and ui.velocities[1]==Vector3.ZERO,"same planar starting address")
	check(ui.field_at(Vector3.ZERO)==Vector3.ZERO,"sink zero at centre")
	check(ui.field_at(Vector3(2,0,0)).is_equal_approx(Vector3(-0.7,0,0)),"sink points inward")
	press(ui,"RUN",cam);check(ui.running,"pointer starts experiment")
	for i in 240:ui.advance(1.0/60.0)
	check(ui.positions[0].x<0 and ui.positions[0].x> -0.6,"velocity receiver approaches without crossing")
	check(ui.positions[1].x>1 and ui.velocities[1].x>0,"acceleration receiver overshoots with retained velocity")
	check(absf(ui.elapsed-4)<0.0001,"four model seconds")
	var snapshot=ui.positions.duplicate();press(ui,"RUN",cam);ui._physics_process(0.2)
	check(not ui.running and ui.positions==snapshot,"pause freezes both receivers")
	var old_velocity=ui.velocities[1];press(ui,"REVERSE",cam)
	check(ui.positions==snapshot and ui.velocities[1]==old_velocity and ui.sign_value==-1,"reverse preserves state")
	press(ui,"RESET",cam)
	check(ui.positions[0]==ui.START and ui.velocities[1]==Vector3.ZERO and ui.elapsed==0 and not ui.running,"reset clears state and pauses")
	check(ui.sign_value==-1,"reset keeps field settings")
	press(ui,"REVERSE",cam);press(ui,"FIELD",cam)
	check(ui.field_index==1 and absf(ui.field_at(Vector3(2,0,1)).dot(Vector3(2,0,1)))<0.00001,"swirl is perpendicular to radius")
	press(ui,"FIELD",cam)
	check(ui.field_index==2 and ui.field_at(Vector3.ONE)==ui.field_at(-Vector3.ONE),"uniform field ignores address")
	press(ui,"RESET",cam)
	for i in 60:ui.advance(1.0/60)
	check(absf(ui.positions[0].x-(ui.START.x+0.8))<0.001,"uniform velocity gives constant speed")
	check(absf(ui.velocities[1].x-0.8)<0.001 and absf(ui.positions[1].x-(ui.START.x+0.4))<0.005,"uniform acceleration accumulates speed and displacement")
	var sixty=ui.positions.duplicate();press(ui,"RESET",cam)
	for i in 30:ui.advance(1.0/30)
	check(ui.positions[0].distance_to(sixty[0])<0.00001 and ui.positions[1].distance_to(sixty[1])<0.00001,"30 and 60 Hz yield same fixed-step paths")
	press(ui,"GAIN",cam);check(ui.gain==1.5,"gain rises")
	press(ui,"GAIN",cam);check(ui.gain==0.5,"gain wraps")
	press(ui,"GAIN",cam);check(ui.gain==1,"gain returns")
	press(ui,"ARROWS",cam);press(ui,"TRAILS",cam);press(ui,"RULE",cam)
	check(ui.shafts.visible and ui.tips.visible and ui.sample_origins.size()==63,"63 field samples in two MultiMeshes")
	check(ui.trail_views[0].visible and ui.trail_meshes[0].get_surface_count()==2,"floor and wall read the same history")
	check(ui.wall.text.contains("1 m/s²") and ui.wall.text.contains("no units"),"distinct adapter units displayed")
	var rebuilds=ui.field_rebuilds;var nodes=ui.get_child_count()
	for i in 60:ui.advance(1.0/60)
	check(ui.field_rebuilds==rebuilds and ui.get_child_count()==nodes,"field and moving geometry reuse nodes")
	press(ui,"RESET",cam);ui.positions[1]=Vector3(4.99,0,0);ui.velocities[1]=Vector3(2,0,0);ui.advance(ui.STEP)
	check(ui.stopped[1] and ui.velocities[1].x>2,"exit keeps outgoing velocity without contact")
	var exited=ui.positions[1];ui.advance(0.1);check(ui.positions[1]==exited,"exited receiver stays frozen")
	press(ui,"RESET",cam);ui.field_index=0;ui.gain=1;ui.sign_value=1;ui.refresh_field()
	for i in 1500:ui.advance(1.0/60)
	check(ui.histories[0].size()==240 and ui.histories[1].size()==240,"bounded 240-sample histories")
	press(ui,"RESET",cam);ui.advance(2)
	check(absf(ui.elapsed-0.25)<0.00001,"stall catch-up capped to 0.25 seconds")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()];q.collision_mask=1
	await physics_frame
	for p in [Vector3(0,0.95,0),Vector3(2.5,0.95,0),Vector3(2.5,0.95,3),Vector3(2.5,0.95,-3)]:
		q.transform.origin=ui.to_global(p);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear operator route "+str(p))
	check(ui.buttons.values().all(func(button):return button.global_position.y>0.9 and button.global_position.y<1.4),"standing control heights")
	check(ui.markers.all(func(marker):return marker.find_children("*","CollisionObject3D",true,false).is_empty()),"markers do not collide with visitor")
	var legacy=load("res://algorithms/vectors/10_vector_field_flow/VectorFieldFlow.tscn").instantiate();legacy.position.y=-100;root.add_child(legacy)
	check(legacy.particle!=null and legacy.find_child("FieldReceivers",true,false)==null,"legacy compact scene still builds");legacy.queue_free()
	press(ui,"RESET",cam)
	for i in 240:ui.advance(1.0/60)
	ui.update_views()
	check(ui.wall_markers[0].position==ui.wall_position(ui.positions[0],0) and ui.wall_markers[1].position==ui.wall_position(ui.positions[1],1),"live wall markers share the receivers planar positions")
	check(ui.markers[0].position.y>1.3 and ui.markers[1].position.y>1.3,"both markers remain above the control tables")
	cam.global_position=ui.to_global(Vector3(0,1.7,0));cam.look_at(ui.to_global(Vector3(-0.3,1.9,-4)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/field_receivers_inside.png")
	cam.global_position=ui.to_global(Vector3(6,6,-3));cam.look_at(ui.to_global(Vector3(0,1,0)))
	for i in 15:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/field_receivers_overview.png")
	f=FileAccess.open("res://ada_run/field_receivers_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("FIELD RECEIVERS COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
