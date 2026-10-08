extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("VECTOR GAP ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="Vectors_Act2_VectorArithmetic"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/vector-gap-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var gap=seg.find_child("RoomGap",true,false);var proj=seg.find_child("RoomProjection",true,false)
	check(gap!=null and proj!=null,"both room adapters load")
	if not gap or not proj:quit(1);return
	check(not gap.get_parent()._rack_built and not proj.get_parent()._rack_built,"room variants replace any preconfigured tabletop rack")
	check(proj.source==gap,"projection binds this hall's actual subtraction source")
	check(gap.gap==Vector2(1.5,0.5) and proj.gap==gap.gap,"initial shared gap")
	var before=gap.gap;press(gap,"SHIFT",cam)
	check(gap.gap.is_equal_approx(before) and proj.gap.is_equal_approx(before),"common shift preserves gap in both receivers")
	press(gap,"SWAP",cam)
	check(gap.gap.is_equal_approx(-before) and proj.gap.is_equal_approx(-before),"subtraction reverses on exchange")
	press(gap,"SAME",cam)
	check(gap.gap==Vector2.ZERO and proj.kept==Vector2.ZERO and proj.remainder==Vector2.ZERO,"coincident addresses produce finite zero decomposition")
	press(gap,"RESET",cam);var kept=proj.kept;var old=gap.a;press(proj,"SLIDE",cam)
	check(not gap.a.is_equal_approx(old) and proj.kept.is_equal_approx(kept),"perpendicular slide changes upstream A but preserves projection")
	check((proj.kept+proj.remainder).is_equal_approx(gap.gap),"kept plus remainder recovers upstream gap")
	check(absf(proj.remainder.dot(proj.axis))<0.0001,"remainder is perpendicular to rail")
	var prior_gap=gap.gap;press(proj,"TURN",cam)
	check(gap.gap.is_equal_approx(prior_gap) and not proj.kept.is_equal_approx(kept),"turning receiver changes decomposition without editing input")
	kept=proj.kept;var signed_length=proj.gap.dot(proj.axis);press(proj,"FLIP",cam)
	check(proj.kept.is_equal_approx(kept) and is_equal_approx(proj.gap.dot(proj.axis),-signed_length),"axis reversal preserves projected vector and reverses signed coordinate")
	press(proj,"RULE",cam);press(gap,"RULE",cam)
	check(proj.numbers.text.contains("kept + rest = gap") and gap.numbers.text.contains("gap = a - b"),"both reveals name their implemented rule")
	# Axis remains normalized under repeated interactive turns, including negative dot.
	for i in 24:press(proj,"TURN",cam)
	check(is_equal_approx(proj.axis.length(),1.0) and absf(proj.remainder.dot(proj.axis))<0.0001,"repeated turns preserve unit rail and perpendicular remainder")
	press(gap,"RESET",cam);press(gap,"A/B",cam);old=gap.a;press(gap,"X-",cam)
	check(gap.a==old and gap.b.x==-1.0 and proj.gap==gap.gap,"selected B edits propagate immediately")
	for i in 8:press(gap,"F+",cam)
	check(gap.b.y==1.5 and gap.notice.contains("limit"),"bounded components refuse rather than silently exceed limits")
	gap.a=Vector2(1.5,0);gap.b=Vector2(0,0);gap.shift_sign=1;gap.refresh();before=gap.gap;press(gap,"SHIFT",cam)
	check(gap.gap==before and gap.notice.contains("refused"),"common shift refuses as a whole when an address hits a limit")
	gap.a=Vector2(0,1.5);gap.b=Vector2.ZERO;gap.refresh();proj.axis=Vector2.RIGHT;proj.slide_sign=1;proj.refresh();press(proj,"SLIDE",cam)
	check(gap.a==Vector2(0,1.5) and proj.notice.contains("limit"),"receiver slide reports an upstream limit without changing the model")
	var counts=[gap.drawing.get_child_count(),proj.drawing.get_child_count()];await process_frame
	check(counts==[gap.drawing.get_child_count(),proj.drawing.get_child_count()],"idle frame does not rebuild either drawing")
	check(gap.point(Vector2(1,0),false).x==0.5,"display scale is explicitly half a metre per coordinate metre")
	# Deliberately add an unrelated source in another room, and a new receiver.
	var other=Node3D.new();other.set_meta("em_map","UnrelatedTestRoom");root.add_child(other)
	var foreign=load("res://commons/artifacts/vector_op_console/gap_projection_room.gd").new();foreign.position.y=-100;other.add_child(foreign)
	var receiver=load("res://commons/artifacts/vector_op_console/gap_projection_room.gd").new();receiver.projection_mode=true;receiver.position.y=-100;other.add_child(receiver)
	check(receiver.source==foreign and proj.source==gap,"source binding remains isolated by museum hall")
	other.queue_free()
	for ui in [gap,proj]:
		check(ui.buttons.values().all(func(button):return button.global_position.y>0.9 and button.global_position.y<1.4),"controls stand at floor reach height "+ui.name)
		var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()]
		await physics_frame
		for point in [Vector3(0,0.95,3.9),Vector3(3.7,0.95,0)]:
			q.transform.origin=ui.to_global(point)
			check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear standing/side approach "+ui.name+str(point))
	for path in ["res://commons/artifacts/vector_op_console/vector_sub.tscn","res://commons/artifacts/projection_shadow/projection_shadow.tscn"]:
		var legacy=load(path).instantiate();legacy.position.y=-100;root.add_child(legacy)
		check(legacy.find_child("RoomGap",true,false)==null and legacy.find_child("RoomProjection",true,false)==null and legacy.get_child_count()>0,"ordinary console remains built: "+path)
		legacy.queue_free()
	press(gap,"RESET",cam);proj.axis=Vector2.RIGHT;proj.refresh();press(proj,"SLIDE",cam)
	for ui in [gap,proj]:
		cam.global_position=ui.to_global(Vector3(3.6,2.8,4.4));cam.look_at(ui.to_global(Vector3(0,1.3,-0.5)))
		for i in 15:await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/vector_gap_"+ui.name+".png")
	f=FileAccess.open("res://ada_run/vector_gap_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("VECTOR GAP COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
