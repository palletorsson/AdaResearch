extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	var old=museum.get("_cam")
	if old is Node3D:old.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/exchange_study.gd")
	check("Installed exchange study found",work!=null)
	if work==null:return
	work.reset()
	var inventory:Array=[]
	for item in hall.find_children("*","Node3D",true,false):
		if item.has_meta("artifact_lookup_name"):inventory.append({"key":item.get_meta("artifact_lookup_name"),"local":xyz(hall.to_local(item.global_position))})
	observations["inventory"]=inventory;observations["work_local"]=xyz(hall.to_local(work.global_position))
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=37
	camera.global_position=hall.to_global(Vector3(8.5,45,17));camera.look_at(hall.to_global(Vector3(8.5,0,17)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	await snapshot("raised-oblique",hall.to_global(Vector3(31,40,42)),hall.to_global(Vector3(8.5,0,17)),60)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(8.5,1.65,4.5)),work.to_global(Vector3(0,1.3,3.5)),84)
	work.step_once()
	check("One update gives W V .02 with exchange and zero without",is_equal_approx(work.left.v[492],.02) and work.right.v[492]==0)
	work.advance(99)
	await snapshot("exchange",work.to_global(Vector3(0,1.65,-1)),work.to_global(Vector3(0,1.6,4.3)),89)
	await snapshot("rear-gallery",hall.to_global(Vector3(8.5,1.65,21.6)),hall.to_global(Vector3(8.5,1.3,27.5)),85)
	if not folder.contains("/before/"):
		await interaction_checks(work)
		check_routes()
		var learner=load("res://doc/book/iterations/2026-10-08-ca-what-a-neighbour-offers/printed/exchange.gd").new()
		hall.add_child(learner);learner.position=Vector3(8.5,0,24);learner.rotation.y=PI
		learner.advance(400);await tick()
		await snapshot("printed-study",hall.to_global(Vector3(9.9,2.5,20.6)),hall.to_global(Vector3(8.5,1.5,23.5)),66)
		learner.queue_free()
	observations["scope"]="Native museum overhead/raised/eye-level. Player and neighbour halls hidden for capture. No headset."

func interaction_checks(work:Node3D) -> void:
	var hand=work.get_node_or_null("ExchangeHand");check("Installed point is available beside desk",hand!=null and hand.point!=null)
	work.reset();work.set_process(false)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=work.to_global(Vector3(2.45+(4.5-16)*.05,1.04,.5+(5.5-16)*.05));await tick();await tick()
	check("Actual XRTools pickup maps held point to requested cell",hand.point.held() and hand.target_site()==Vector2i(4,5))
	check("Movement alone leaves the field unseeded",work.injections==0 and work.left.v[164]==0)
	hand.point.action();await tick()
	check("Held trigger plants nine matched sites without advancing",work.injections==1 and work.left.v.count(.25)==45 and work.left.v==work.right.v and work.left.ticks==0)
	await snapshot("point-seed",work.to_global(Vector3(4.5,1.75,-1.5)),work.to_global(Vector3(2.45,1.03,.5)),66)
	controller.global_position=work.to_global(Vector3(-2.45+(8.5-16)*.05,1.04,.5+(6.5-16)*.05));await tick();await tick();hand.point.action();await tick()
	check("B table targets corresponding sites in both fields",hand.target_site()==Vector2i(8,6) and work.left.v[200]==.25 and work.right.v[200]==.25 and work.injections==2)
	controller.global_position+=Vector3.UP;await tick();await tick();hand.point.action()
	check("A trigger too high over the table has no effect",work.injections==2)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();hand.plant()
	check("Released point parks and no longer injects",not hand.point.held() and hand.point.position.is_equal_approx(Vector3(-5.85,1.08,-1.7)) and work.injections==2)
	origin.queue_free();await tick()
	work.reset();work.inject_at(Vector2i.ZERO)
	check("Installed selected seed wraps its patch across corner",work.left.v[1023]==.25 and work.left.v.count(.25)==45 and work.right.v==work.left.v)
	work.reset();work.advance(100)
	var old_u:PackedFloat32Array=work.left.u;var old_v:PackedFloat32Array=work.left.v;var old_ticks:int=work.left.ticks
	work.change_view();work.toggle_coating()
	check("VIEW and COAT leave every value and clock untouched",work.left.u==old_u and work.left.v==old_v and work.left.ticks==old_ticks and not work.walls[0].visible and not work.walls[1].visible)
	var sharing:=true
	for side in 2:sharing=sharing and work.get_node("TableField_%d"%side).material_override.albedo_texture==work.walls[side].material_override.albedo_texture
	check("Both curved walls share the corresponding table texture",sharing)
	var floor= floor_at(work.to_global(Vector3(0,0,2.15)))
	check("Coating visibility leaves floor support intact",not floor.is_empty() and absf(work.to_local(floor.position).y)<.03)
	work.change_view();work.toggle_coating();work.toggle_exchange();work.advance(100)
	check("Adding exchange to B replays equal full fields",work.right.exchange and work.left.u==work.right.u and work.left.v==work.right.v)
	work.toggle_exchange();work.hundred()
	for i in 25:work._process(.1)
	check("Plus100 uses bounded batches and stops exactly",work.left.ticks==100 and work.right.ticks==100 and not work.running and work.target==0)
	work.toggle_run();work._process(.1);work.running=false
	check("RUN adds four numerical ticks per work opportunity",work.left.ticks==104)
	var crossing=work.get_node("WalkSeed")
	var prop:=RigidBody3D.new();hall.add_child(prop);prop.freeze=true
	crossing._entered(prop);check("Floor crossing ignores loose props",work.injections==0);prop.queue_free()
	var walker:=CharacterBody3D.new();hall.add_child(walker);walker.add_to_group("em_walker")
	var boundary:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	boundary.shape=capsule;boundary.position.y=.88;walker.add_child(boundary)
	walker.global_position=work.to_global(Vector3(0,0,-.6));await tick();await tick()
	work.reset();work.advance(100);walker.global_position=work.to_global(Vector3(0,0,2.15));await tick();await tick();await tick()
	check("Physical body arrival plants fixed matched patch",work.injections==1 and work.left.v[484]==.25 and work.right.v[484]==.25)
	await create_timer(.15).timeout;check("Remaining on the crossing does not replenish",work.injections==1)
	work.advance(100)
	await snapshot("seed-crossing",work.to_global(Vector3(-.2,1.65,.1)),work.to_global(Vector3(0,1.45,4.35)),100)
	work.reset();await tick();check("Replay while occupied does not silently reinject",work.injections==0)
	walker.global_position=work.to_global(Vector3(0,0,-.6));await tick();await tick();walker.global_position=work.to_global(Vector3(0,0,2.15));await tick();await tick();await tick()
	check("Leaving and returning makes a new event",work.injections==1)
	walker.queue_free();await tick();await tick()
	work.left.ticks=2399;work.right.ticks=2399;work.advance(4);old_v=work.left.v;work.advance(4)
	check("Installed study stops both fields at 2400",work.left.ticks==2400 and work.right.ticks==2400 and work.left.v==old_v)
	work.reset();work.advance(400)
	observations["batch_ms"]=work.last_batch_usec/1000.0

func check_routes() -> void:
	var routes:Dictionary={
		"entry_to_point":[Vector2(8.5,4.5),Vector2(8.5,6.4),Vector2(2.65,6.4),Vector2(2.65,7.0)],
		"point_to_fields":[Vector2(2.65,7.0),Vector2(8.5,7.0),Vector2(8.5,11.65)],
		"fields_to_clockmaker":[Vector2(8.5,11.65),Vector2(8.5,15.5)],
		"clockmaker_to_exit":[Vector2(8.5,15.5),Vector2(5.4,15.5),Vector2(5.4,20),Vector2(8.5,20),Vector2(8.5,29.0)]}
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7;var results:Dictionary={}
	for label in routes:
		var points:Array=routes[label];var blocked:Array=[];var unsupported:Array=[];var samples:=0
		for i in range(1,points.size()):
			var a:Vector2=points[i-1];var b:Vector2=points[i];var count:=ceili(a.distance_to(b)/.15)
			for j in range(count+1):
				var p:=a.lerp(b,float(j)/count);var foot:=hall.to_global(Vector3(p.x,0,p.y))
				var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform=Transform3D(Basis.IDENTITY,foot+Vector3.UP*.88)
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query,8)
				if not hits.is_empty():blocked.append({"at":[p.x,p.y],"node":str(hits[0].collider.get_path())})
				var ground:=floor_at(foot)
				if ground.is_empty() or absf(ground.position.y-foot.y)>.03:unsupported.append([p.x,p.y])
				samples+=1
		results[label]={"samples":samples,"blocked":blocked,"unsupported":unsupported}
		check(label+": capsule clearance",blocked.is_empty());check(label+": continuous level floor",unsupported.is_empty())
	observations["routes"]=results
	var stream=museum.get("_portal_stream")
	check("Entry frame has supported approach",not stream.get("_entry").is_empty() and not stream.get("_entry").get("invalid",false))
	check("Exit frame has supported approach",not stream.get("_exit").is_empty() and not stream.get("_exit").get("invalid",false))
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	print("CA EXCHANGE ROOM ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
