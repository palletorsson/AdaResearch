extends SceneTree
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
var OUT := ""
var replay_before := false
var snapshot: GDScript
var measurement: Dictionary = {}
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): OUT=arg.trim_prefix("--out=")
	replay_before="--replay-before" in OS.get_cmdline_user_args()
	if replay_before:
		snapshot=load("res://commons/artifacts/orbital_mechanics_demo/gravity_relations.gd")
		snapshot.source_code=FileAccess.get_file_as_string("res://doc/book/iterations/2026-09-19-forces-review/relations/before-source/commons/artifacts/orbital_mechanics_demo/gravity_relations.gd")
		assert(snapshot.reload()==OK)
	run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("GRAVITY ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="VFM_07_Gravity"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=OUT+"gravity-relations-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var orbit=seg.find_child("GravityOrbit",true,false);var mutual=seg.find_child("GravityRelations",true,false)
	check(orbit!=null and mutual!=null,"both primary variants load")
	if orbit==null or mutual==null:quit(1);return
	for ui in [orbit,mutual]:ui.set_physics_process(false)
	check(orbit.global_basis.get_scale().is_equal_approx(Vector3.ONE) and mutual.global_basis.get_scale().is_equal_approx(Vector3.ONE),"both exhibits retain metre scale")
	check(not orbit.running and not mutual.running,"both experiments wait for visitor")
	check(orbit.board.text.contains("source is held fixed")==replay_before,"initial board explanation matches tested version")
	check(orbit.bank_labels[1].text.contains("Fixed source")==replay_before,"initial console explanation matches tested version")
	await capture(cam,orbit,"orbit-initial")
	press(orbit,"PARTS",cam)
	check(orbit.board.text.contains("source is held fixed")==replay_before and orbit.bank_labels[1].text.contains("Fixed source")==replay_before,"PARTS exposes arrows without an additional explanation")
	var positions=orbit.states[0].p.duplicate();var velocities=orbit.states[0].v.duplicate()
	press(orbit,"RULE",cam)
	check(orbit.board.text.contains("reaction omitted") and orbit.bank_labels[1].text.contains("Fixed source"),"RULE exposes omitted reaction and names fixed source")
	check(orbit.states[0].p==positions and orbit.states[0].v==velocities and is_zero_approx(orbit.elapsed),"explanation toggles leave physical state unchanged")
	await capture(cam,orbit,"orbit-rule")
	press(orbit,"RULE",cam);press(orbit,"PARTS",cam)
	check(orbit.bank_labels[1].text.contains("Fixed source")==replay_before,"RULE toggles explanation back to observation prompt")
	var e=orbit.energy(orbit.states[0]);press(orbit,"RUN",cam)
	for i in 600:orbit.advance(1.0/60)
	check(not orbit.frame_exit and absf(orbit.states[0].p[1].length()-3)<0.001,"softened circular orbit holds its radius for ten seconds")
	check(absf(orbit.energy(orbit.states[0])/e-1)<0.0001,"circular orbit energy remains within numerical tolerance")
	check(orbit.states[0].p[0]==Vector3.ZERO and orbit.states[0].v[0]==Vector3.ZERO,"first source is explicitly fixed")
	press(orbit,"RUN",cam);var before=orbit.states[0].p[1];orbit.advance(1);check(orbit.states[0].p[1]==before,"pause retains state")
	press(orbit,"RESET",cam);press(orbit,"RUN",cam)
	for i in 120:orbit.advance(1.0/60)
	press(orbit,"REVERSE",cam)
	for i in 120:orbit.advance(1.0/60)
	check(orbit.states[0].p[1].distance_to(Vector3(3,0,0))<0.0001,"velocity reversal retraces isolated orbit within solver tolerance")
	press(orbit,"SPEED",cam);check(orbit.speed_index==2 and not orbit.running and orbit.histories[0][1].size()==1,"speed edit resets beginning and history")
	press(orbit,"SPEED",cam);press(orbit,"RUN",cam)
	for i in 600:orbit.advance(1.0/60)
	check(orbit.frame_exit and not orbit.running and orbit.states[0].v[1].length()>0,"fast launch reaches observation boundary with outgoing velocity held")
	press(orbit,"RESET",cam);check(not orbit.frame_exit and orbit.speed_index==3,"reset clears exit while retaining speed choice")
	# Equal-and-opposite forces in the mutually responding apparatus.
	check(mutual.states[0].p.size()==2,"mutual encounter begins with a pair")
	var acc=mutual.accelerations(mutual.states[0]);check((acc[0]*mutual.masses[0]+acc[1]*mutual.masses[1]).length()<0.000001,"pair forces are equal and opposite")
	var com=mutual.centre_of_mass(mutual.states[0]);e=mutual.energy(mutual.states[0]);press(mutual,"RUN",cam)
	for i in 600:mutual.advance(1.0/60)
	check(absf(mutual.states[0].p[0].distance_to(mutual.states[0].p[1])-4)<0.001,"mutual circular pair retains separation")
	check(mutual.states[0].p[0].distance_to(Vector3(-2,0,0))>1 and mutual.states[0].p[1].distance_to(Vector3(2,0,0))>1,"both attracting bodies move")
	check(mutual.momentum(mutual.states[0]).length()<0.000001 and mutual.centre_of_mass(mutual.states[0]).distance_to(com)<0.000001,"pair momentum and centre of mass remain constant")
	press(mutual,"BODIES",cam);check(mutual.body_count==3 and not mutual.running,"third body changes initial setup and pauses")
	var third_acc=mutual.accelerations(mutual.states[0]);check(absf(third_acc[0].z)>0.1,"third body adds a new acceleration component to the old pair")
	var force_sum=Vector3.ZERO
	for i in 3:force_sum+=third_acc[i]*mutual.masses[i]
	check(force_sum.length()<0.000001,"three-body pair contributions still sum to zero")
	press(mutual,"NUDGE",cam);check(mutual.nudge()==0.03 and mutual.states[0].p[0]==mutual.states[1].p[0] and mutual.states[0].p[1]==mutual.states[1].p[1] and absf(mutual.states[1].p[2].x-mutual.states[0].p[2].x-0.03)<0.00001,"only last body's initial X changes in comparison copy")
	check(mutual.states[0].v==mutual.states[1].v,"paired copies have identical initial velocities")
	var c0=mutual.centre_of_mass(mutual.states[0]);var c1=mutual.centre_of_mass(mutual.states[1]);e=mutual.energy(mutual.states[0]);press(mutual,"RUN",cam)
	for i in 240:mutual.advance(1.0/60)
	measurement={"model_seconds":mutual.elapsed,"nudge_m":mutual.nudge(),"rms_separation_m":mutual.separation(),"initial_rms_m":mutual.nudge()/sqrt(3.0),"energy_ratio":mutual.energy(mutual.states[0])/e,"momentum_residual_kg_m_s":mutual.momentum(mutual.states[0]).length(),"G":mutual.G,"softening_m":mutual.EPS,"step_s":mutual.STEP,"masses_kg":mutual.masses}
	check(absf(mutual.elapsed-4.0)<0.00001 and absf(mutual.separation()-0.0758)<0.0001,"specified 3 cm nudge reproduces approximately 7.6 cm RMS at four seconds")
	print("GRAVITY measured t=",mutual.elapsed," separation=",mutual.separation()," energy ratio=",mutual.energy(mutual.states[0])/e," momentum residual=",mutual.momentum(mutual.states[0]).length())
	check(mutual.elapsed>3.9 and mutual.separation()>0.005,"paired trajectories remain measurable at common four-second time")
	check(mutual.centre_of_mass(mutual.states[0]).distance_to(c0)<0.00001 and mutual.centre_of_mass(mutual.states[1]).distance_to(c1)<0.00001,"each three-body centre remains at its own initial value")
	check(mutual.momentum(mutual.states[0]).length()<0.001,"three-body momentum residual below 0.001 kg m/s")
	check(absf(mutual.energy(mutual.states[0])/e-1)<0.02,"three-body energy error stays below two percent over tested interval")
	var final_positions=mutual.states[0].p.duplicate();var final_velocities=mutual.states[0].v.duplicate()
	press(mutual,"RESET",cam);press(mutual,"RUN",cam)
	for i in 120:mutual.advance(1.0/30)
	var difference=0.0
	for i in 3:difference+=mutual.states[0].p[i].distance_to(final_positions[i])+mutual.states[0].v[i].distance_to(final_velocities[i])
	check(difference<0.00001,"30/60 Hz partition agreement and deterministic reset")
	press(mutual,"RESET",cam);press(mutual,"RUN",cam);mutual.advance(1.0);check(absf(mutual.elapsed-0.25)<0.00001,"stall catch-up caps at quarter second")
	var close={"p":[Vector3.ZERO,Vector3.ZERO],"v":[Vector3.ZERO,Vector3.ZERO]};acc=mutual.accelerations(close)
	check(acc[0].is_finite() and acc[1].is_finite() and acc[0]==Vector3.ZERO,"softened coincidence is finite and produces no arbitrary direction")
	mutual.body_count=2;mutual.nudge_index=0;mutual.reset_experiment();press(mutual,"RUN",cam)
	for i in 900:mutual.advance(1.0/60)
	check(mutual.histories[0][0].size()==240,"history bounded to 240 samples per body")
	check(mutual.separation()==0,"identical beginnings remain identical")
	for ui in [orbit,mutual]:
		press(ui,"PARTS",cam);press(ui,"RULE",cam);ui.update_visuals();ui.update_text()
		check(ui.board.text.contains("epsilon = 0.25") and ui.board.text.contains("observation ends"),"rule states close-range modification and frame boundary")
		ui.place_arrow(ui.arrows[0][1],Vector3.ZERO,Vector3(100,0,0))
		check(is_equal_approx(ui.arrows[0][1].get_child(0).scale.y,2.0),"acceleration drawing caps at two metres")
		var count=ui.get_child_count();for i in 20:ui.update_visuals()
		check(ui.get_child_count()==count,"moving markers and arrows reuse geometry")
		press(ui,"PATH",cam);check(not ui.trail_meshes[0][1].visible,"path toggle hides visible history")
		press(ui,"PATH",cam)
		check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"controls at standing reach")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()];q.collide_with_areas=false
	await physics_frame
	for ui in [orbit,mutual]:
		for at in [Vector3(0,1,-5),Vector3(0,1,-4.5),Vector3(0,1,0),Vector3(4,1,0),Vector3(0,1,4)]:
			q.transform.origin=ui.to_global(at);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"body-sized route "+str(ui.name)+str(at))
	orbit.speed_index=0;orbit.reset_experiment();orbit.running=true
	for i in 300:orbit.advance(1.0/60)
	orbit.update_visuals();orbit.update_text()
	mutual.body_count=3;mutual.nudge_index=1;mutual.reset_experiment();mutual.running=true
	for i in 240:mutual.advance(1.0/60)
	mutual.update_visuals();mutual.update_text()
	for ui in [orbit,mutual]:
		cam.global_position=ui.to_global(Vector3(4.5,5,-5.5));cam.look_at(ui.to_global(Vector3(0,1.3,0)))
		for i in 15:await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(OUT+"gravity_"+("mutual" if ui.mutual else "orbit")+".png")
	f=FileAccess.open(OUT+"gravity_relations_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false,"measurement":measurement,"replay_before":replay_before},"  "));f.close()
	print("GRAVITY COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)

func capture(cam:Camera3D,ui:Node3D,suffix:String) -> void:
	cam.global_position=ui.to_global(Vector3(4.5,5,-5.5));cam.look_at(ui.to_global(Vector3(0,1.3,0)))
	for i in 20:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+suffix+".png")
	var f:=FileAccess.open(OUT+suffix+"-camera.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"position":str(cam.global_position),"target":str(ui.to_global(Vector3(0,1.3,0))),"fov":cam.fov,"viewport":str(root.size)},"  "));f.close()
	cam.global_position=ui.to_global(Vector3(0,2.7,-.2));cam.look_at(ui.to_global(Vector3(0,2.7,5.4)))
	for i in 20:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+suffix+"-board.png")
