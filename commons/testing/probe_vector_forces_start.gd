extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("VECTOR START ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="Vectors_Act1_WhatAVectorIs"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/vector-start-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	if map_name=="Change_Choreography":
		var wishes: Array=[]
		for n in seg.find_children("*","Node",true,false):
			if n.get_meta("artifact_lookup_name","")=="if_not_exist_create":wishes.append(n)
		check(wishes.size()==4,"four idea markers instantiate")
		for n in wishes:
			check(not n.solid and not n.make.is_empty(),"non-solid named proposal: "+n.make)
		var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6
		var q=PhysicsShapeQueryParameters3D.new();q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()]
		await physics_frame
		var blocked: Array=[]
		for z in range(5,26,2):
			q.transform=Transform3D(Basis.IDENTITY,seg.to_global(Vector3(12.5,1.1,z+4)))
			if not seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty():blocked.append(z)
		check(blocked.is_empty(),"markers leave the central lane clear "+str(blocked))
		cam.global_position=seg.to_global(Vector3(3,24,0));cam.look_at(seg.to_global(Vector3(12.5,0,17)))
	else:
		var ui=seg.find_child("RoomReading",true,false);check(ui!=null,"opt-in vector wall loads")
		if ui:
			check(not ui.parts and ui.bench.reading=="bare","discovery starts with two views before components")
			var before=ui.sample_vector();press(ui,"SHIFT",cam)
			check(ui.sample_vector().is_equal_approx(before),"moving both pins preserves their world displacement")
			press(ui,"SHORT",cam);check(is_equal_approx(ui.measured.length(),0.25),"short preset measures a quarter metre")
			var direction=ui.measured.normalized();press(ui,"LONG",cam)
			check(is_equal_approx(ui.measured.length(),1.0) and ui.measured.normalized().is_equal_approx(direction),"long preset preserves direction and measures one metre")
			press(ui,"PARTS",cam);check(ui.parts and ui.readout.text.contains("v ="),"pointer reveals world components")
			var count=ui.diagram.get_child_count();ui.refresh();check(count==ui.diagram.get_child_count(),"unchanged input does not rebuild the diagram")
			press(ui,"ZERO",cam);check(ui.measured==Vector3.ZERO,"coincident pins produce zero displacement")
			press(ui,"LONG",cam);check(is_equal_approx(ui.measured.length(),1.0),"preset recovers from zero with a declared fallback direction")
			check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"console stands at reachable floor height")
			var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()];q.transform.origin=ui.to_global(Vector3(0,0.9,2.5));await physics_frame
			check(seg.get_world_3d().direct_space_state.intersect_shape(q).is_empty(),"standing approach to the wall console is clear")
			ui.end_handle.global_position=ui.start_handle.global_position+Vector3(4,0,0);ui.refresh()
			check(ui.heading.text.contains("clipped") and is_equal_approx(ui.measured.x,4.0),"wall clipping retains the actual measured component")
			press(ui,"SHORT",cam)
			check(not ui.heading.text.contains("clipped"),"returning inside the window clears the clipping label")
			var norm
			for node in seg.find_children("*","Node",true,false):
				if node.get_meta("artifact_lookup_name","")=="vector_normalize_demo":norm=node;break
			check(norm!=null,"second primary normalization scene is present")
			if norm:
				norm._update_info(Vector3.ZERO)
				check(norm.info_label.text.ends_with("0.000"),"zero normalization reports zero output length")
				norm._update_info(Vector3(2,1,0))
				check(norm.info_label.text.ends_with("1.000"),"nonzero normalization reports unit output length")
			ui.end_handle.global_position=ui.start_handle.global_position+Vector3(0.6,0.4,0.7);ui.refresh()
			cam.global_position=ui.to_global(Vector3(0.4,2.0,4.3));cam.look_at(ui.to_global(Vector3(0,1.65,-0.6)))
		else:cam.global_position=seg.to_global(Vector3(7,12,2));cam.look_at(seg.to_global(Vector3(7,0,14)))
	for i in 20:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/vector_start_"+map_name+".png")
	f=FileAccess.open("res://ada_run/vector_start_"+map_name+"_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("VECTOR START COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
