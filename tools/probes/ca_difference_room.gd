extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(.7).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	var old=museum.get("_cam")
	if old is Node3D:old.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	for child in museum.get_children():
		if child is Node3D and child.has_meta("em_map") and child!=hall:child.hide()
	var work:=find_scene("/difference_study.gd")
	check("Installed paired study found",work!=null)
	if work==null:return
	work.target=0;work.model.scattered=false;work.model.disturbance=0;work.model.integer_storage=false;work.model.reset();work.select_spatial_slice(5);work.paint()
	observations["work_local"]=xyz(hall.to_local(work.global_position))
	var inventory:Array=[]
	for item in hall.find_children("*","Node3D",true,false):
		if item.has_meta("artifact_lookup_name"):inventory.append({"key":item.get_meta("artifact_lookup_name"),"local":xyz(hall.to_local(item.global_position))})
	observations["inventory"]=inventory
	camera.projection=Camera3D.PROJECTION_ORTHOGONAL;camera.size=42;camera.global_position=hall.to_global(Vector3(9.5,50,18));camera.look_at(hall.to_global(Vector3(9.5,0,18)),Vector3.FORWARD);camera.current=true
	await create_timer(.4).timeout;await RenderingServer.frame_post_draw;root.get_texture().get_image().save_png(ProjectSettings.globalize_path(folder+"overhead.png"))
	await snapshot("raised-oblique",hall.to_global(Vector3(38,40,48)),hall.to_global(Vector3(9.5,0,18)),62)
	camera.projection=Camera3D.PROJECTION_PERSPECTIVE
	await snapshot("entry",hall.to_global(Vector3(9.5,1.7,5.5)),hall.to_global(Vector3(9.5,1.7,13)),87)
	await snapshot("paired-volumes",work.to_global(Vector3(-.3,2.4,-3.5)),work.to_global(Vector3(0,1.75,3.5)),88)
	await snapshot("rear-gallery",hall.to_global(Vector3(9.5,1.7,21)),hall.to_global(Vector3(9.5,1.5,29)),90)
	if not folder.contains("/before/"):await interaction_checks(work)
	observations["scope"]="Native museum above and inside; player/neighbour halls hidden for capture. No physical headset."

func interaction_checks(work:Node3D) -> void:
	work.set_process(false)
	var model=work.model;var reader=work.slice_walker;var hand=work.get_node_or_null("SliceHand")
	check("Walking study carries the same held point",hand!=null and hand.point!=null and reader!=null)
	if hand==null:return
	model.scattered=false;model.disturbance=0;model.coupling=.25;model.changed=true;model.integer_storage=true;model.reset();work.paint()
	var before_a:PackedFloat64Array=model.a.duplicate();var before_b:PackedFloat64Array=model.b.duplicate()
	var walker:=CharacterBody3D.new();walker.add_to_group("em_walker");hall.add_child(walker)
	var shape:=CollisionShape3D.new();var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7;shape.shape=capsule;shape.position.y=.88;walker.add_child(shape)
	walker.global_position=work.to_global(Vector3(0,.02,1.6));await tick();await tick();await tick()
	check("Real body overlap selects section5",reader.last_body==walker.get_instance_id() and work.slice_z==5)
	var visible:Color=work.textures[2].get_image().get_pixel(5,5)
	walker.global_position=work.to_global(Vector3(0,.02,1.87));await tick();await tick();await tick()
	check("Walking to section6 hides image but not stored difference",work.slice_z==6 and not work.textures[2].get_image().get_pixel(5,5).is_equal_approx(visible) and model.report().different==1 and model.tick==0 and model.a==before_a and model.b==before_b)
	check("Selected frame and floor edge mark follow sameZ",absf(reader.frames[0].position.z-1.87)<.001 and reader.frames[1].position.z==reader.frames[0].position.z and reader.floor_mark.position.z==reader.frames[0].position.z)
	walker.global_position=work.to_global(Vector3(0,.02,2.015));await tick();await tick();check("Body deadband holds selection near midpoint",work.slice_z==6)
	walker.global_position=work.to_global(Vector3(0,.02,1.87));await tick()
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=hand.to_global(Vector3(-3.35,1.24,-2.25+5*.11));await tick();await tick();await tick()
	check("Held point chooses section5 despite body remaining at6",hand.point.held() and work.slice_z==5 and model.tick==0 and model.b==before_b)
	await snapshot("point-reader",work.to_global(Vector3(-6.7,2.7,-4.1)),work.to_global(Vector3(-3.5,1.35,-1.2)),75)
	work.operate(1);var expected:int=model.tick+10;controller.global_position=hand.to_global(Vector3(-3.35,1.24,-2.25+4*.11));await tick();await tick()
	check("Hand changes slice without cancelling scheduled plus10",work.slice_z==4 and work.target==expected and model.tick==0)
	hand.point.action();await tick();check("Trigger steps once and cancels scheduled run like STEP",model.tick==1 and work.target==0)
	check("Installed integer first step removes uniform intervention",model.a==model.b and model.report().different==0)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();await tick()
	check("Release returns section selection to still-present body",not hand.point.held() and work.slice_z==6 and hand.point.position.is_equal_approx(Vector3(-3.35,1.24,-2.25+6*.11)))
	walker.global_position=work.to_global(Vector3(0,.02,-2.8));await tick();await tick();await tick()
	check("Leaving reader releases visitor and retains last section",reader.visitors.is_empty() and work.slice_z==6)
	origin.queue_free();walker.queue_free();await tick()
	press(work,9);work.select_spatial_slice(5);work.operate(0)
	check("Installed STORE resets fractional beginning; next27 peak.75",not model.integer_storage and model.tick==1 and model.report().different==27 and absf(model.report().max_difference-.75)<1e-12)
	check("Difference floor and third panel share material and gain",work.floor_view.material_override==work.materials[2] and work.walls[2].material_override==work.materials[2] and absf(work.view_gain-4.0/3)<1e-12)
	await snapshot("fractional-first-step",work.to_global(Vector3(0,4.8,-1.0)),work.to_global(Vector3(0,2.2,6.5)),85)
	work.advance(19);observations["generation20"]=work.readback()
	check("Fractional difference spreads while peak fades at20",model.tick==20 and model.report().different>27 and model.report().max_difference<.75 and work.view_gain>4.0/3)
	await snapshot("difference-at20",work.to_global(Vector3(0,4.8,-1.0)),work.to_global(Vector3(0,2.2,6.5)),85)
	var fixed_a:PackedFloat64Array=model.a.duplicate();var fixed_b:PackedFloat64Array=model.b.duplicate();var gen:int=model.tick
	press(work,11);work.select_spatial_slice(3)
	check("Coating and section preserve complete paired state",not work.floor_view.visible and model.tick==gen and model.a==fixed_a and model.b==fixed_b)
	press(work,11);press(work,4)
	check("PULL zero resets and preserves its new setting",model.coupling==0 and model.tick==0)
	work.advance(20);check("Zero pull and drive keep one whole difference",model.report().different==1 and model.report().max_difference==1)
	press(work,3);press(work,7);press(work,8);work.advance(20)
	check("ONE CELL off with DRIVE and scattered seed keeps matched arrays",not model.changed and model.scattered and model.disturbance==1 and model.a==model.b)
	press(work,2);check("REPLAY preserves parameters and restores matched beginning",model.tick==0 and model.coupling==0 and not model.changed and model.scattered and model.a==model.b)
	press(work,1);work._process(.01);var held:int=model.tick;work._process(.12)
	check("Plus10 budget advances at most one per eligible frame",held==0 and model.tick==1 and work.target==10)
	for i in 12:work._process(.12)
	check("Scheduled run stops exactly at its requested generation",model.tick==10 and work.target==0)
	model.tick=99;work.advance(10);fixed_a=model.a.duplicate();work.advance(1)
	check("Installed100-update limit prevents extra state change",model.tick==100 and model.a==fixed_a)
	var physical:=true
	for z in [0,5,10]:
		var foot:Vector3=work.to_global(Vector3(0,0,.25+.27*z));var hit=floor_at(foot);physical=physical and not hit.is_empty() and absf(hit.position.y-foot.y)<.03
	check("Difference floor remains supported at all witness depths",physical)
	check_routes()
	var learner=load("res://doc/book/iterations/2026-10-08-ca-what-a-difference-keeps/printed/difference.gd").new();hall.add_child(learner);learner.position=Vector3(3.5,0,19);learner.rotation.y=PI/2
	learner.model.integer_storage=false;learner.model.reset();learner.step();await tick()
	await snapshot("printed-study",learner.to_global(Vector3(.4,2.7,3.8)),learner.to_global(Vector3(0,1.65,0)),65)
	learner.queue_free()

func press(work:Node3D,i:int) -> void:
	var button=work.console.find_child("Btn_%d"%i,true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)

func check_routes() -> void:
	var routes:Dictionary={
		"entry_to_console":[Vector2(9.5,4.5),Vector2(9.5,6.5),Vector2(4.5,6.5)],
		"console_to_body_reader":[Vector2(4.5,6.5),Vector2(9.5,6.5),Vector2(9.5,13.5)],
		"reader_to_rear":[Vector2(9.5,13.5),Vector2(16.2,13.5),Vector2(16.2,18),Vector2(9.5,20)],
		"rear_to_exit":[Vector2(9.5,20),Vector2(9.5,33.2)]}
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
	print("CA DIFFERENCE ROOM ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
