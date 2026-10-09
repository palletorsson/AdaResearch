extends SceneTree
var failures: Array[String] = []
var OUT := ""
var checks := 0
var observations: Dictionary = {}
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):OUT=arg.trim_prefix("--out=")
	run.call_deferred()
func check(ok: bool, note: String) -> void:
	checks+=1
	if not ok:failures.append(note)
	print("TIMING ","PASS " if ok else "FAIL ",note)
func capture(cam: Camera3D, at: Vector3, target: Vector3, name: String) -> void:
	if DisplayServer.get_name()=="headless":return
	cam.global_position=at;cam.look_at(target)
	for i in 12:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+"timing_"+name+".png")
func press(machine: Node3D, id: String, cam: Camera3D) -> void:
	var button=machine.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,button,button.global_position)
	XRToolsPointerEvent.released(cam,button,button.global_position)
func run() -> void:
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl=OUT+"timing-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused")
	em.set("start_chapter","forces");em.set("start_map","Change_Choreography");root.add_child(em);current_scene=em
	await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg: Node3D
	for rec in em.get("_segments"):
		if rec.node.get_meta("em_map","")=="Change_Choreography":seg=rec.node;break
	check(seg!=null,"new hall loads after oscillation")
	if not seg:quit(1);return
	var rods: Node3D;var belt: Node3D
	for n in seg.find_children("*","Node",true,false):
		if n.get_meta("artifact_lookup_name","")=="phase_rod_array":rods=n
		if n.get_meta("artifact_lookup_name","")=="conveyor_backlog":belt=n
	check(rods!=null and belt!=null,"both primary scenes spawn")
	if rods==null or belt==null:quit(1);return
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	var cam=Camera3D.new();em.add_child(cam);cam.fov=65
	rods.set_process(false)
	check(rods.rods.size()==20,"twenty individually indexed rods")
	check(is_equal_approx(rods.angle_at(0,1),rods.angle_at(19,1)),"all rods begin with equal period and phase")
	press(rods,"ONE +",cam)
	check(is_equal_approx(rods.angle_at(9,1)-rods.angle_at(8,1),PI/4),"pointer offsets only rod ten by 45 degrees")
	press(rods,"WAVE",cam)
	check(is_equal_approx(rods.angle_at(1,1)-rods.angle_at(0,1),TAU/5),"adjacent columns differ by one fifth of a turn")
	check(is_equal_approx(rods.angle_at(1,7)-rods.angle_at(1,1),TAU),"phase wave retains the six-second period")
	rods.elapsed=0;rods._update_rods()
	await capture(cam,rods.to_global(Vector3(3.5,3.4,6)),rods.to_global(Vector3(0,1.2,0)),"rods_wave")
	press(rods,"DRIFT",cam)
	check(is_equal_approx(rods.angle_at(10,150)-rods.angle_at(0,150),TAU),"four-percent frequency difference realigns after 150 seconds")
	check(not is_equal_approx(rods.angle_at(10,37.5),rods.angle_at(0,37.5)),"drift separates phases between alignments")
	rods.elapsed=37.5;rods._update_rods()
	press(rods,"RULE",cam);check(rods.rule.visible,"rule is revealed by pointer")
	await capture(cam,rods.to_global(Vector3(3.5,3.4,6)),rods.to_global(Vector3(0,1.3,0)),"rods_drift")
	press(rods,"RESET",cam);check(rods.elapsed==37.5 and rods.mode=="TOGETHER","reset aligns rods without rewinding their clock")
	rods.set_process(true)
	for m in [rods,belt]:
		check(m.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"console buttons lie in standing reach band")
	await physics_frame
	var shape=CapsuleShape3D.new();shape.radius=0.22;shape.height=1.6
	var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collide_with_areas=false;q.exclude=[player.get_rid()]
	var blocked: Array[int]=[]
	for z in range(5,27,2):
		q.transform=Transform3D(Basis.IDENTITY,seg.to_global(Vector3(12.5,1.1,z+4)))
		if not seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():blocked.append(z)
	check(blocked.is_empty(),"central passage is clear: "+str(blocked))
	press(belt,"RESET",cam)
	await create_timer(14).timeout
	observations["matched"]={"admitted":belt.admitted,"collected":belt.collected,"here":belt.boxes.size()}
	check(belt.collected>0,"rigid parcels ride the belt and reach the receiver")
	check(belt.admitted-belt.collected==belt.boxes.size(),"admission minus collection equals actual rigid bodies")
	var before: int=belt.boxes.size()
	press(belt,"BACK UP",cam)
	await create_timer(30).timeout
	var backed: int=belt.boxes.size()
	var admitted_backed: int=belt.admitted
	observations["backlog"]={"admitted":belt.admitted,"collected":belt.collected,"here":backed}
	check(backed>before+4,"slow receiver makes a physical backlog")
	var highest := 0.0
	for b in belt.boxes:highest=maxf(highest,belt.to_local(b.global_position).y)
	observations["highest_backlog_center"]=highest
	var in_tray := 0
	for b in belt.boxes:
		if belt.to_local(b.global_position).x>=3.0:in_tray+=1
	observations["parcels_in_tray"]=in_tray
	check(in_tray>=3,"parcels enter the receiving tray before collection")
	await capture(cam,belt.to_global(Vector3(7,4,7)),belt.to_global(Vector3(0.8,0.7,0)),"backlog")
	press(belt,"RULE",cam);check(belt.rule.visible,"queue accounting can be revealed")
	press(belt,"RECOVER",cam)
	await create_timer(24).timeout
	observations["recovered"]={"admitted":belt.admitted,"collected":belt.collected,"here":belt.boxes.size()}
	check(belt.boxes.size()<backed/2.0,"faster collection drains most of the backlog")
	check(belt.admitted>admitted_backed+4,"recovery releases the inlet and admits new parcels")
	check(belt.admitted-belt.collected==belt.boxes.size(),"accounting survives recovery without lost parcels")
	observations["remaining_positions"]=[]
	for b in belt.boxes:observations["remaining_positions"].append(str(belt.to_local(b.global_position)))
	await capture(cam,belt.to_global(Vector3(7,4,7)),belt.to_global(Vector3(0.8,0.7,0)),"recovered")
	await capture(cam,belt.to_global(Vector3(0,1.9,4.2)),belt.to_global(Vector3(0,1.2,2.3)),"console")
	var time_before: float=belt.elapsed
	press(belt,"RESET",cam);await physics_frame
	check(belt.boxes.is_empty() and belt.admitted==0 and belt.collected==0,"reset clears the local parcel experiment")
	check(belt.elapsed>=time_before,"reset does not rewind elapsed museum time")
	await capture(cam,seg.to_global(Vector3(3,24,0)),seg.to_global(Vector3(12.5,0,17)),"hall")
	f=FileAccess.open(OUT+"timing_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations,"headset_tested":false},"  "));f.close()
	print("TIMING COMPLETE ",checks," checks / ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)
