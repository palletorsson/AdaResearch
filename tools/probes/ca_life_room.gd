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
	var work:=find_scene("/game_of_life_petri.gd")
	check("Installed Life dish found",work!=null)
	if work==null:return
	var study:Node3D=work.get_node("AddressStudy");study.choose_glider()
	observations["work_local"]=xyz(hall.to_local(work.global_position))
	var inventory:Array=[]
	for item in hall.find_children("*","Node3D",true,false):
		if item.has_meta("artifact_lookup_name"):inventory.append({"key":item.get_meta("artifact_lookup_name"),"local":xyz(hall.to_local(item.global_position)),"path":str(item.get_path())})
	observations["inventory"]=inventory
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=37
	camera.global_position=hall.to_global(Vector3(7.5,45,17.5));camera.look_at(hall.to_global(Vector3(7.5,0,17.5)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	camera.size=37
	await snapshot("raised-oblique",hall.to_global(Vector3(28,40,40)),hall.to_global(Vector3(7.5,0,17)),60)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(6.5,1.65,4.2)),study.to_global(Vector3(0,.65,2.5)),78)
	await snapshot("floor-zero",study.to_global(Vector3(-4.6,1.65,3.4)),study.to_global(Vector3(0,.15,6.3)),78)
	for i in 8:study.step_once()
	await snapshot("address-lit",study.to_global(Vector3(3,1.65,3.3)),study.to_global(Vector3(3.5,.9,7)),87)
	await snapshot("rear-gallery",hall.to_global(Vector3(6.5,1.65,22.3)),hall.to_global(Vector3(6.5,1.2,28.5)),88)
	check("GLIDER reaches A at generation eight",work._generation==8 and study.receivers[0].light.light_energy>0)
	if not folder.contains("/before/"):
		await interaction_checks(work,study)
		check_routes()
		var learner=load("res://doc/book/iterations/2026-10-08-ca-a-pattern-visits/printed/life.gd").new()
		hall.add_child(learner);learner.position=Vector3(3.3,0,8);learner.rotation.y=PI/2
		for i in 8:learner.step()
		await tick()
		await snapshot("printed-study",hall.to_global(Vector3(6.3,2.15,8.4)),hall.to_global(Vector3(3.3,1.12,8)),66)
		learner.queue_free()
	observations["scope"]="Native museum; actual hall overhead, raised and visitor-height. Neighbouring halls/player hidden for captures. No physical headset test."

func interaction_checks(work:Node3D,study:Node3D) -> void:
	var hand_point=study.get_node_or_null("LifeHand")
	check("Walk-floor installation supplies carried PointBody STEP",hand_point!=null and hand_point.point!=null)
	var transforms:Array=[]
	for i in 576:transforms.append(study.floor_view.multimesh.get_instance_transform(i))
	var state:Array=work._grid.duplicate(true);var events:int=study.receivers[0].rises
	study.toggle_link()
	check("Installed LINK off changes output only",not study.linked and study.receivers[0].light.light_energy==0 and work._grid==state and work._generation==8)
	study.toggle_link()
	check("Reconnect relights A without counting a new occupancy",study.receivers[0].light.light_energy>0 and study.receivers[0].rises==events and work._grid==state)
	study.toggle_trace();await tick()
	var traces:=true
	for y in 24:
		for x in 24:
			var now:bool=work._grid[y][x];var was:bool=work._next_grid[y][x]
			if now==was:continue
			var want:Color=study.BIRTH_COLOUR if now else study.DEATH_COLOUR
			traces=traces and close_colour(study.floor_view.multimesh.get_instance_color(y*24+x),want) and close_colour(work._multimesh.get_instance_color(y*24+x),want)
	check("TRACE marks births and withdrawals in both receivers",traces)
	study.toggle_trace();await tick();var restored:=true
	for y in 24:
		for x in 24:
			var on:bool=work._grid[y][x]
			restored=restored and close_colour(study.floor_view.multimesh.get_instance_color(y*24+x),Color("90ebca") if on else Color("273e49")) and close_colour(work._multimesh.get_instance_color(y*24+x),work.alive_color if on else work.dead_color)
	check("TRACE off restores both views without editing state",restored and state==work._grid and work._generation==8)
	study.choose_blinker();var initial:Array=work._grid.duplicate(true);var centre:=true
	for i in 2:study.step_once();centre=centre and study.receivers[0].light.light_energy>0
	check("Installed blinker repeats after two steps; centre stays occupied",centre and work._grid==initial)
	study.choose_meeting()
	for i in 6:study.step_once()
	var empty:=true
	for row in work._grid:empty=empty and row.count(true)==0
	check("Installed meeting is empty at generation six",empty and work._generation==6)
	study.choose_glider();var fixed:=true;var support:=true
	var walker:=CharacterBody3D.new();hall.add_child(walker);walker.add_to_group("em_walker")
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	shape.shape=capsule;shape.position.y=.88;walker.add_child(shape)
	var at:Vector3=study.floor_position(Vector2i(10,10));at.y=0
	walker.global_position=study.to_global(at)
	for gen in [0,8,12]:
		while work._generation<gen:study.step_once()
		var before:Array=work._grid.duplicate(true)
		for i in 6:
			await physics_frame;walker.velocity=Vector3.DOWN*.5;walker.move_and_slide()
		fixed=fixed and work._grid==before and work._generation==gen
		support=support and absf(study.to_local(walker.global_position).y)<.06
	check("A supplied body remains supported at A before, during and after occupancy",support)
	check("Standing at A never writes cell state",fixed)
	walker.queue_free();await tick()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand_point.point.global_position;hand_point.point.pick_up(pickup);await tick();await tick()
	state=work._grid.duplicate(true);controller.global_position=study.to_global(Vector3(0,1.2,6.5));await tick();await tick()
	check("Actual XRTools carries installed STEP beside floor without editing cells",hand_point.point.held() and work._grid==state and work._generation==12)
	hand_point.point.action();await tick()
	check("Held installed trigger advances one generation",work._generation==13)
	await snapshot("carried-step",study.to_global(Vector3(0,1.65,4.7)),study.to_global(Vector3(2,.9,7)),88)
	hand_point.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release returns installed point to console shelf",not hand_point.point.held() and hand_point.point.position.is_equal_approx(Vector3(1.35,1.08,-2.3)))
	origin.queue_free();await tick()
	study.toggle_run();study._process(.5);study.running=false
	check("Installed RUN uses existing half-second update",work._generation==14)
	for i in 50:study.step_once()
	check("Installed observation holds at 48",work._generation==48 and not study.running)
	fixed=true
	for i in 576:fixed=fixed and transforms[i]==study.floor_view.multimesh.get_instance_transform(i)
	check("All installed floor transforms remain fixed",fixed)
	study.toggle_link();study.replay()
	check("Replay clears time but preserves link choice",work._generation==0 and not study.linked)
	study.toggle_link()
	observations["single_step_ms"]=study.last_step_usec/1000.0

func close_colour(a:Color,b:Color) -> bool:return absf(a.r-b.r)<.004 and absf(a.g-b.g)<.004 and absf(a.b-b.b)<.004

func check_routes() -> void:
	var routes:Dictionary={
		"entry_to_desk":[Vector2(6.5,3.5),Vector2(6.5,5.5)],
		"desk_to_floor":[Vector2(6.5,5.5),Vector2(4.2,5.5),Vector2(4.2,10.5),Vector2(5.9,14.7)],
		"floor_to_rear":[Vector2(5.9,14.7),Vector2(5.9,22.2)],
		"rear_to_hex_controls":[Vector2(5.9,22.2),Vector2(12.5,22.2),Vector2(12.5,24.8),Vector2(9.5,24.8)],
		"rear_to_exit":[Vector2(5.9,22.2),Vector2(5.5,22.2),Vector2(5.5,29.5),Vector2(6.5,29.5),Vector2(6.5,30.5)]}
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
	print("CA LIFE ROOM ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
