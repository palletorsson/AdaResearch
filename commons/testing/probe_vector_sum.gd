extends SceneTree
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("VECTOR SUM ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="VFM_02_Operations"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/vector-sum-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var ui=seg.find_child("RoomSum",true,false)
	check(ui!=null,"room addition adapter instantiated")
	if not ui:quit(1);return
	ui.set_physics_process(false)
	check(ui.result.is_equal_approx(Vector2(1,1)),"two floor contributions share one resultant")
	check(not ui.revealed,"arithmetic initially withheld")
	var before=ui.result;press(ui,"SWAP",cam)
	check(ui.result.is_equal_approx(before) and ui.a==Vector2(0,1),"swap changes first leg while preserving endpoint")
	press(ui,"GO",cam);ui._physics_process(10)
	check(not ui.running and ui.carriage.position.is_equal_approx(ui.floor_point(ui.result)),"detour reaches resultant exactly")
	check(is_equal_approx(ui.travelled,2.0),"detour retains two metres of travel")
	press(ui,"PATH",cam);press(ui,"GO",cam);ui._physics_process(10)
	check(is_equal_approx(ui.travelled,sqrt(2.0)),"direct journey is shorter at the same endpoint")
	press(ui,"CANCEL",cam)
	check(ui.result==Vector2.ZERO,"opposing nonzero inputs sum to zero")
	press(ui,"GO",cam);ui._physics_process(10)
	check(is_zero_approx(ui.travelled),"direct zero displacement does not move")
	press(ui,"PATH",cam);press(ui,"GO",cam);ui._physics_process(0.5)
	check(is_equal_approx(ui.travelled,0.4) and ui.carriage.position.distance_to(ui.floor_point(Vector2.ZERO))>0.3,"zero-result detour nevertheless moves at specified speed")
	ui._physics_process(10)
	check(is_equal_approx(ui.travelled,2.0) and ui.carriage.position.is_equal_approx(ui.floor_point(Vector2.ZERO)),"cancelled detour returns with nonzero distance")
	press(ui,"RULE",cam)
	check(ui.numbers.text.contains("A+B = (0.0, 0.0)") and ui.revealed,"pointer reveals the actual cancelled arithmetic")
	press(ui,"A/B",cam);var old_a=ui.a;press(ui,"X+",cam)
	check(ui.a==old_a and ui.b.x==0.5,"component editing changes selected B only")
	for i in 8:press(ui,"X+",cam)
	check(ui.b.x==1.0,"bounded input stops at declared one-metre limit")
	check(ui.wall_point(ui.result).is_equal_approx(Vector3(-1.65+ui.result.x*0.48,1.95+ui.result.y*0.48,-2.99)),"wall maps the floor frame without dropping a component")
	var count=ui.diagram.get_child_count();ui._physics_process(0.016)
	check(count==ui.diagram.get_child_count(),"motion leaves diagram geometry stable")
	# Integrator must consume the full step when a frame crosses a waypoint.
	ui.a=Vector2(1,0);ui.b=Vector2(0,1);ui.refresh();press(ui,"GO",cam)
	for i in 60:ui._physics_process(1.0/60.0)
	var fine=ui.carriage.position;var distance_fine=ui.travelled
	press(ui,"GO",cam);ui._physics_process(1.0)
	check(ui.carriage.position.is_equal_approx(fine) and is_equal_approx(ui.travelled,distance_fine),"travel agrees across frame partitioning")
	# Also run the real physics clock and verify AnimatableBody updates are retained.
	press(ui,"GO",cam);ui.set_physics_process(true);await create_timer(3.0).timeout;ui.set_physics_process(false)
	check(not ui.running and ui.carriage.position.is_equal_approx(ui.floor_point(ui.result)),"actual physics frames carry the cube to its destination")
	check(ui.buttons.values().all(func(button):return button.global_position.y>0.9 and button.global_position.y<1.4),"all controls stand at reachable height")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collide_with_areas=false;q.exclude=[player.get_rid()]
	await physics_frame
	for point in [Vector3(0,0.95,4.9),Vector3(-4,0.95,0),Vector3(4,0.95,0),Vector3(-4,0.95,-4),Vector3(4,0.95,-4)]:
		q.transform.origin=ui.to_global(point)
		check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"clear approach / onward route "+str(point))
	q.transform.origin=ui.to_global(Vector3(2.72,0.95,0))
	check(not seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"stage glass separates the carriage from the walkway")
	var legacy=load("res://commons/artifacts/adder_board/adder_board.tscn").instantiate();legacy.position=Vector3(0,-100,0);root.add_child(legacy)
	check(legacy._vector_a!=null and legacy.find_child("RoomSum",true,false)==null,"ordinary addition board retains its legacy controls")
	legacy.queue_free()
	ui.a=Vector2(1,0);ui.b=Vector2(0,1);ui.refresh();press(ui,"GO",cam);ui._physics_process(1.7)
	cam.global_position=ui.to_global(Vector3(4.5,3.7,5.25));cam.look_at(ui.to_global(Vector3(0,1.0,0)))
	for i in 20:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/vector_sum_room.png")
	cam.global_position=ui.to_global(Vector3(0,2.0,5.1));cam.look_at(ui.to_global(Vector3(0,1.6,-1)))
	for i in 12:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/vector_sum_console.png")
	f=FileAccess.open("res://ada_run/vector_sum_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("VECTOR SUM COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
