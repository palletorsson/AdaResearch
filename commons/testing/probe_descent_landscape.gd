extends SceneTree
var checks:=0
var failures:Array[String]=[]
func _initialize() -> void:run.call_deferred()
func check(ok:bool,message:String) -> void:
	checks+=1
	if not ok:failures.append(message)
	print("DESCENT ","PASS " if ok else "FAIL ",message)
func press(ui:Node3D,id:String,cam:Camera3D) -> void:
	var area=ui.buttons[id].get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(cam,area,area.global_position);XRToolsPointerEvent.released(cam,area,area.global_position)
func run() -> void:
	var em=load("res://commons/scenes/endless_museum.tscn").instantiate();var ctl="res://ada_run/descent-landscape-control.json"
	var file=FileAccess.open(ctl,FileAccess.WRITE);file.store_string(JSON.stringify({"first_chapter":"formfinding","dollhouse":0,"grid_pack":1}));file.close()
	em.set("EM_CONTROL",ctl);em.set("_overrides_path",ctl+".unused");em.set("_hand_path",ctl+".unused");em.set("start_chapter","formfinding");em.set("start_map","FormFinding_Descent")
	root.add_child(em);current_scene=em;await create_timer(2).timeout
	em.set_process(false);em.set_physics_process(false);em.call("flush_stamps")
	var seg:Node3D
	for r in em.get("_segments"):
		if r.node.get_meta("em_map","")=="FormFinding_Descent":seg=r.node;break
	check(seg!=null,"actual museum hall loads")
	if seg==null:quit(1);return
	var ui=seg.find_child("DescentLandscapeLab",true,false)
	check(ui!=null,"interactive landscape loads")
	if ui==null:quit(1);return
	ui.set_process(false)
	var player=em.get("_player");player.set_physics_process(false);em.get("_feel").set_process(false)
	em.get("_wardrobe").appearance_save_path="";em.get("_wardrobe").costume.visible=false
	var cam=Camera3D.new();em.add_child(cam);cam.fov=67
	check(ui.global_basis.get_scale().is_equal_approx(Vector3.ONE),"landscape retains six-metre domain")
	check(ui.plot(Vector2(3,3)).y<1.5,"rim stays below standing eye height")
	check(ui.steps==0 and not ui.running,"waits for visitor input")
	var initial=ui.point;ui._process(1.0);check(ui.point==initial,"paused presentation never advances")
	for p in [Vector2(-2,1),Vector2(0,0),Vector2(2.5,-1.5)]:
		check(ui.gradient(p).distance_to(p*0.5)<0.0001,"sampled bowl gradient agrees with independent analytic slope "+str(p))
	press(ui,"STEP",cam)
	check(ui.steps==1 and ui.point.distance_to(initial*0.65)<0.0001,"pointer STEP applies p minus 0.7 gradient")
	check(ui.last_delta<0 and ui.samples.size()==2,"accepted step records lower cost and path")
	press(ui,"RESET",cam);check(ui.steps==0 and ui.point==initial and ui.samples.size()==1,"reset restores selected start and clears path")
	press(ui,"RUN",cam);ui._process(0.1);check(ui.steps==0,"run waits for presentation interval")
	ui._process(0.13);check(ui.steps==1,"run advances one discrete step after interval")
	press(ui,"RUN",cam);check(not ui.running,"run toggles pause")
	press(ui,"PARTS",cam);press(ui,"RULE",cam)
	check(ui.slope.visible and ui.board.text.contains("No momentum") and ui.board.text.contains("0.03"),"reveals sampled slope, code and omitted momentum")
	press(ui,"RESET",cam)
	for i in 160:ui.step_once()
	check(ui.status=="SMALL SLOPE" and ui.gradient(ui.point).length()<0.01,"bowl stops at declared small-slope tolerance")
	var tight=ui.cost(ui.point);var tight_steps=ui.steps
	press(ui,"STOP",cam);press(ui,"STOP",cam)
	check(ui.tolerance_index==2 and ui.steps==0,"tolerance edit starts a fresh comparison")
	for i in 160:ui.step_once()
	check(ui.steps<tight_steps and ui.cost(ui.point)>tight,"looser tolerance accepts an earlier, higher-cost endpoint")
	ui.tolerance_index=0;ui.rate_index=3;ui.reset();ui.step_once()
	check(ui.status=="LEFT FRAME" and ui.point==ui.STARTS[0],"oversized step reports frame exit without hidden coordinate clamp")
	ui.rate_index=1;ui.reset();ui.steps=160;ui.step_once()
	check(ui.status=="STEP LIMIT" and not ui.running,"budget stop is distinct from convergence")
	ui.steps=0;ui.reset();press(ui,"SURFACE",cam)
	check(ui.surface==1 and ui.steps==0,"surface control rebuilds objective and resets")
	var endpoints=[];var costs=[]
	for index in [0,1]:
		ui.start_index=index;ui.reset()
		for i in 160:ui.step_once()
		check(ui.status=="SMALL SLOPE","two-valley run reaches small slope from start "+str(index))
		endpoints.append(ui.point);costs.append(ui.cost(ui.point))
	check(endpoints[0].x<0 and endpoints[1].x>0,"different starts end in different valleys under the same rule")
	check(costs[1]-costs[0]>0.5,"both small slopes can have unequal final cost")
	print("DESCENT ENDPOINTS ",endpoints," costs ",costs)
	press(ui,"START",cam);check(ui.start_index==2 and ui.steps==0,"START chooses next declared beginning")
	press(ui,"RATE",cam);check(ui.rate_index==2 and ui.steps==0,"RATE edit starts a fresh trajectory")
	check(ui.buttons.values().all(func(b):return b.global_position.y>0.9 and b.global_position.y<1.4),"all nine pointer buttons at standing reach")
	var count=ui.get_child_count();for i in 30:ui.refresh()
	check(ui.get_child_count()==count,"readouts and paths reuse nodes")
	var legacy=[]
	for n in seg.find_children("*","Node3D",true,false):
		if n.get_script()==null:continue
		var path=n.get_script().resource_path
		if path.ends_with("GradientDescentDemo.gd"):
			legacy.append("gradient_descent")
			check(absf(n.global_basis.get_scale().x-0.14)<0.001,"original twenty-metre noise landscape is a compact comparison")
		for suffix in ["descent_marble_toy.gd","gradient_descent_well.gd","settling_tremble.gd","science_screen.gd"]:
			if path.ends_with(suffix):legacy.append(suffix)
	check(legacy.size()==5,"all five pre-existing exhibit identities still load")
	var q=PhysicsShapeQueryParameters3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.22;capsule.height=1.6;q.shape=capsule;q.collision_mask=1;q.exclude=[player.get_rid()];q.collide_with_areas=false
	await physics_frame
	for at in [Vector3(0,1,-5.3),Vector3(-4,1,0),Vector3(5.4,1,0),Vector3(0,1,5.1)]:
		q.transform.origin=ui.to_global(at);check(seg.get_world_3d().direct_space_state.intersect_shape(q,1).is_empty(),"body-sized viewing approach "+str(at))
	for rec in em.get("_vis_records"):
		var n=rec.get("node")
		if n is Node3D and is_instance_valid(n) and seg.is_ancestor_of(n):n.visible=true
	ui.surface=0;ui.rate_index=1;ui.start_index=0;ui.build_surface();ui.reset();ui.parts=true;ui.rule=false
	for i in 5:ui.step_once()
	cam.global_position=ui.to_global(Vector3(-4,4.3,-6));cam.look_at(ui.to_global(Vector3(0,1.2,0)))
	for i in 10:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/descent_bowl.png")
	ui.surface=1;ui.build_surface();ui.start_index=1;ui.rule=true;ui.reset()
	for i in 160:ui.step_once()
	cam.global_position=ui.to_global(Vector3(0,4.5,-5.6));cam.look_at(ui.to_global(Vector3(0,1.5,0)))
	for i in 10:await process_frame;cam.make_current()
	await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png("res://ada_run/descent_valleys.png")
	file=FileAccess.open("res://ada_run/descent_landscape_probe.json",FileAccess.WRITE);file.store_string(JSON.stringify({"checks":checks,"failures":failures,"valley_costs":costs,"headset_tested":false},"  "));file.close()
	print("DESCENT COMPLETE ",checks," / ",failures.size());quit(0 if failures.is_empty() else 1)
