extends SceneTree
class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false
var checks := 0
var failures: Array[String] = []
func _initialize() -> void:run.call_deferred()
func check(ok: bool, text: String) -> void:
	checks+=1
	if not ok:failures.append(text)
	print("ARENA ","PASS " if ok else "FAIL ",text)
func press(ui: Node3D,id: String,cam: Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var map_name="VFM_08_Arena"
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--map="):map_name=a.trim_prefix("--map=")
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate()
	var ctl="res://ada_run/arena-relations-"+map_name+"-control.json";var f=FileAccess.open(ctl,FileAccess.WRITE);f.store_string(JSON.stringify({"first_chapter":"forces","dollhouse":0,"grid_pack":1}));f.close()
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
	var ui=seg.find_child("ArenaRelationLab",true,false)
	check(ui!=null,"controlled encounter loads")
	if ui==null:quit(1);return
	check(not ui.running and not ui.crab.is_processing(),"encounter waits paused")
	check(ui.global_basis.get_scale().is_equal_approx(Vector3.ONE),"station retains metre scale")
	check(not ui.crab.can_bite and not ui.crab.path_on,"scoped creature omits bite and global path grid")
	check(ui.crab._feet.size()==4,"original four-leg gait rig built")
	check(ui.crab.choose().get("node")==ui.beacon,"opening visible beacon selected")
	var start=ui.crab.position;for i in 10:await process_frame
	check(ui.crab.position.is_equal_approx(start),"paused body does not move")
	press(ui,"RUN",cam);check(ui.running and ui.crab.is_processing(),"RUN enables actual controller")
	ui.crab.set_process(false)
	for i in 60:ui.crab._process(1.0/60)
	check(ui.crab.position.distance_to(start)>0.3,"controller moves its mesh toward nominated target")
	press(ui,"RESET",cam);await physics_frame
	press(ui,"SCREEN",cam);await physics_frame
	check(ui.screen.collision_layer==1 and ui.screen_mesh.visible,"screen is visible collision geometry")
	check(ui.crab.choose().is_empty(),"screen occludes central beacon")
	ui.crab._target=ui.beacon;ui.crab._nearest_food();check(ui.crab._target==null,"no stale target remains after sight is blocked")
	press(ui,"BEACON",cam);await physics_frame
	check(ui.beacon_index==1 and ui.crab.choose().get("node")==ui.beacon,"side beacon becomes visible around screen")
	press(ui,"SCREEN",cam);await physics_frame
	check(ui.screen.collision_layer==0 and not ui.screen_mesh.visible,"screen opens without invisible collision")
	press(ui,"FOOD",cam);await process_frame;await physics_frame
	check(is_instance_valid(ui.food) and ui.food.is_bait(),"native mushroom settles as edible candidate")
	check(not ui.food.is_in_group("spider_bait") and not ui.food.can_be_picked_up,"food is scoped and cannot be taken by other crabs or walking pickup")
	check(ui.crab.choose().get("node")==ui.food,"nearer visible mushroom replaces beacon")
	for i in 600:
		ui.crab._process(1.0/60)
		if ui.crab._degree==1:break
	check(ui.crab._degree==1,"unassisted steering reaches offered food and completes a meal")
	press(ui,"RESET",cam);await physics_frame;press(ui,"FOOD",cam);await process_frame;await physics_frame
	var original_food=ui.food;press(ui,"FOOD",cam);check(ui.food==original_food,"food button never stacks unbounded candidates")
	ui.beacon.global_position=ui.crab.global_position+Vector3(0.6,0.2,0)
	check(ui.crab.choose().get("node")==ui.beacon,"nearer beacon beats mushroom; food has no category priority")
	ui.beacon.position=Vector3(0,0.1,3.8)
	ui.crab.position=Vector3(-2,ui.crab._ride,-1)
	ui.crab._process(1.0/60)
	check(ui.crab._meal_t>1.9,"arriving within feeding range begins two-second meal")
	var before_degree=ui.crab._degree
	for i in 60:ui.crab._process(1.0/60)
	check(ui.crab._degree==before_degree and ui.crab._meal_t>0.8,"one second is not a completed meal")
	for i in 63:ui.crab._process(1.0/60)
	check(ui.crab._degree==1 and not ui.crab._rooted,"first completed meal increments state without rooting")
	for i in 25:await process_frame
	for meal in 4:
		press(ui,"FOOD",cam);await process_frame;await physics_frame
		ui.crab.position=Vector3(-2,ui.crab._ride,-1)
		for i in 123:ui.crab._process(1.0/60)
		for i in 25:await process_frame
	check(ui.crab._degree==5 and ui.crab._rooted,"fifth completed meal reaches stopping threshold")
	check(ui.crab.chase_speed==0 and ui.crab.patrol_speed==0 and not ui.crab.can_bite,"threshold disables movement and bite")
	start=ui.crab.position;for i in 30:ui.crab._process(1.0/60)
	check(ui.crab.position.is_equal_approx(start),"stopped animal retains its place")
	press(ui,"RESET",cam);await physics_frame
	check(ui.crab._degree==0 and not ui.crab._rooted and ui.crab.chase_speed==0.8 and not ui.running,"reset creates an unfed animal and waits")
	check(ui.beacon_index==1,"reset retains beacon setting")
	ui.beacon.position=Vector3(0,0,10);check(ui.crab.choose().is_empty(),"candidate beyond six-metre range is excluded")
	ui.beacon.position=ui.BEACONS[ui.beacon_index]
	press(ui,"VISITOR",cam);check(ui.recipient()==player,"VISITOR nominates actual museum player")
	press(ui,"VISITOR",cam);check(ui.recipient()==ui.beacon,"VISITOR can return to beacon")
	press(ui,"PARTS",cam);press(ui,"RULE",cam)
	check(ui.board.text.contains("No sight memory") and ui.board.text.contains("five completed meals"),"rule declares scope and threshold")
	var count=ui.get_child_count();for i in 20:ui.update_visuals()
	check(ui.get_child_count()==count,"readouts and sight line reuse geometry")
	check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"controls at standing reach")
	ui.running=true;ui.crab.position.x=5.1;ui._process(0.1)
	check(ui.boundary and not ui.running and not ui.crab.is_processing(),"golden frame freezes outgoing observation")
	press(ui,"RESET",cam);check(not ui.boundary,"reset clears observation exit")
	# Preserve and verify the existing analytic collision model.
	var carts=null
	for node in seg.find_children("*","Node3D",true,false):
		if node.get_script()!=null and node.get_script().resource_path.ends_with("collision_carts.gd"):carts=node;break
	check(carts!=null,"existing collision-carts primary retained")
	if carts!=null:
		for ratio in [0.0,0.27272727,1.0]:
			carts._param_set(ratio);carts._build_demo();var a=lerpf(0.4,2.6,ratio);var va=(a-1)/(a+1);var vb=2*a/(a+1)
			check(absf(a*va+vb-a)<0.00001 and absf(a*va*va+vb*vb-a)<0.00001,"declared 1D elastic outcomes conserve totals at ratio "+str(ratio))
		carts._param_set(0.6);carts._build_demo()
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()];q.collide_with_areas=false
	await physics_frame
	for at in [Vector3(0,1,-5),Vector3(0,1,-3.5),Vector3(3,1,0),Vector3(-3,1,0)]:
		q.transform.origin=ui.to_global(at);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"body-sized approach "+str(at))
	ui.beacon_index=0;ui.beacon.position=ui.BEACONS[0];ui.screen_on=true;ui.update_visuals();await physics_frame;ui.update_visuals();ui.update_text()
	cam.global_position=ui.to_global(Vector3(5,4,-6));cam.look_at(ui.to_global(Vector3(0,1,0)))
	for i in 10:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/arena_screen.png")
	ui.screen_on=false;ui.update_visuals();await physics_frame;press(ui,"FOOD",cam);await process_frame;await physics_frame
	ui.crab.position=Vector3(-2,ui.crab._ride,-1);ui.crab._process(1.0/60)
	for i in 60:ui.crab._process(1.0/60)
	ui.update_visuals();ui.update_text();cam.global_position=ui.to_global(Vector3(1.5,2,-4));cam.look_at(ui.crab.global_position+Vector3(0,0.2,0))
	for i in 5:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/arena_feeding.png")
	if carts!=null:
		cam.global_position=carts.global_position+Vector3(3,2.0,4);cam.look_at(carts.global_position+Vector3(0,1.0,0))
		for i in 5:await process_frame;cam.make_current()
		await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/arena_carts.png")
	f=FileAccess.open("res://ada_run/arena_relations_probe.json",FileAccess.WRITE);f.store_string(JSON.stringify({"checks":checks,"failures":failures,"headset_tested":false},"  "));f.close()
	print("ARENA COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
