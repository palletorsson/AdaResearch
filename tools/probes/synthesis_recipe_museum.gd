extends "res://tools/probes/transformation_encounters.gd"
func clear_body(at: Vector3) -> bool:
	var capsule:=CapsuleShape3D.new();capsule.radius=0.28;capsule.height=1.6
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform.origin=at+Vector3.UP*0.84;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var walker=museum.get("_player")
	if walker is Node3D:
		walker.hide();walker.set_process(false);walker.set_physics_process(false);walker.global_position=Vector3(0,-100,0)
	var old_cam=museum.get("_cam")
	if old_cam is Node3D:old_cam.hide()
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	var gallery=find_scene("/fractal_procedure_gallery/fractal_procedure_gallery.gd")
	var started:=Time.get_ticks_msec()
	while gallery!=null and not gallery.staged and Time.get_ticks_msec()-started<18000:await process_frame
	check("Gallery staged with recipe table",gallery!=null and gallery.staged and gallery.recipe_table!=null)
	if gallery==null or gallery.recipe_table==null:return
	var table=gallery.recipe_table
	var cantor=find_scene("/cantorset/cantor_set.gd")
	var tree=find_scene("/recursive_tree/recursive_tree.gd")
	check("Original interval and tree remain",cantor!=null and tree!=null)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	observations.works=works
	var authored:Array=["fractal_procedure_gallery","cantor_set","recursive_tree","fractal_recursion_1","koch_curve","sierpinski_triangle","fractal_clouds","dark_sphere","strange_attractors","romanesco","fibonacci_sequences"]
	check("Ten authored artifacts plus gallery retained once each",authored.all(func(token):return works.count(token)==1))
	var approach:Vector3=table.to_global(Vector3(0,0.005,1.07))
	check("Table approach has floor and standing clearance",not floor_at(approach).is_empty() and clear_body(approach))
	check("Point reachable from one standing position",table.point.global_position.distance_to(approach+Vector3.UP*1.25)<0.8)
	for side in [-1,1]:
		var pass_at:Vector3=table.to_global(Vector3(side*1.8,0.005,0))
		check("Table side bypass has floor and clearance "+str(side),not floor_at(pass_at).is_empty() and clear_body(pass_at))
	table.hide()
	await snapshot("before",hall.to_global(Vector3(9.5,2.0,3.2)),hall.to_global(Vector3(9.5,1.4,10.5)),77)
	table.show()
	await snapshot("arrival",hall.to_global(Vector3(9.5,2.0,3.2)),hall.to_global(Vector3(9.5,1.4,10.5)),77)
	await snapshot("thirds",table.to_global(Vector3(0,1.75,2.1)),table.to_global(Vector3(0,1.20,0)),75)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(0.2).timeout
	for id in ["NEXT","KEEP","RESTORE","RESET"]:
		var result:Dictionary=await driver.press(table.buttons[id],approach)
		check("Nearby "+id+" receives desktop ray",str(result.get("hover","")) not in ["","none","null","nothing"])
	check("Pointer NEXT and KEEP retained four cuts; RESET restores live three",table.recipe.steps==3 and table.kept_recipe.steps==4)
	table.keep_current()
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=table.point.global_position;table.point.pick_up(pickup);await create_timer(0.2).timeout
	controller.global_position=table.to_global(Vector3(-0.35,1.15,0.55));await create_timer(0.2).timeout
	check("Museum hand selects quarters while kept thirds remain",is_equal_approx(table.recipe.fraction,0.25) and is_equal_approx(table.kept_recipe.fraction,1.0/3.0))
	origin.hide()
	await snapshot("quarters",table.to_global(Vector3(0,1.75,2.1)),table.to_global(Vector3(0,1.20,0)),75)
	table.point.action();await create_timer(0.1).timeout
	controller.global_position=table.to_global(Vector3(0.35,1.15,0.55));await create_timer(0.2).timeout
	check("Trigger keeps quarters while live becomes two fifths",is_equal_approx(table.total(table.kept),0.75) and is_equal_approx(table.total(table.live),3.072))
	await snapshot("comparison",table.to_global(Vector3(0,1.75,2.1)),table.to_global(Vector3(0,1.20,0)),75)
	table.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await create_timer(0.2).timeout
	await driver.press(table.buttons.RESTORE,approach)
	check("Pointer RESTORE recovers kept quarter recipe",table.live==table.kept and not is_same(table.recipe,table.kept_recipe))
	await snapshot("restored",table.to_global(Vector3(0,1.75,2.1)),table.to_global(Vector3(0,1.20,0)),75)
	var original_tree:Array=tree.get_children().map(func(n):return n.get_instance_id()) if tree!=null else []
	var original_cuts:int=cantor.current_iteration if cantor!=null else -1
	table.act("NEXT");table.act("NEXT");table.act("NEXT")
	check("Live reaches cap while kept stays at three",table.recipe.steps==5 and table.kept_recipe.steps==3)
	check("Table changes leave original desks untouched",cantor.current_iteration==original_cuts and tree.get_children().map(func(n):return n.get_instance_id())==original_tree)
	await snapshot("five-cuts",table.to_global(Vector3(0,1.75,2.1)),table.to_global(Vector3(0,1.20,0)),75)
	await snapshot("cantor",hall.to_global(Vector3(5.5,2.4,6.6)),hall.to_global(Vector3(5.5,2.2,12.0)),68)
	await snapshot("tree",hall.to_global(Vector3(13.5,2.4,6.4)),hall.to_global(Vector3(13.5,2.4,12.8)),68)
	await snapshot("overview",hall.to_global(Vector3(3.5,7.7,4.4)),hall.to_global(Vector3(9.5,1.5,18)),85)
	driver.teardown();await process_frame
	var study=load("res://ada_run/synthesis_student/recipe.gd").new();study.transform=table.global_transform;root.add_child(study);table.hide()
	study.choose(0);study.keep_current();study.choose(2)
	await snapshot("student",study.to_global(Vector3(0,1.75,2.1)),study.to_global(Vector3(0,1.20,0)),75)
	check("Exact printed program runs inside museum",is_equal_approx(study.total(study.kept),0.75) and is_equal_approx(study.total(study.live),3.072) and study.drawing.get_child_count()==16)
	study.queue_free();table.show();origin.queue_free()
	if stream!=null:
		var exit_data:Dictionary=stream.get("_exit");var entry_data:Dictionary=stream.get("_entry")
		observations.exit=exit_data;observations.entry=entry_data
		check("Both authored portals validate",not exit_data.get("invalid",false) and not entry_data.get("invalid",false))
		if not exit_data.get("invalid",false):
			var door:Vector3=exit_data.door;var inward:Vector3=exit_data.inward
			await snapshot("exit",door+inward*3.5+Vector3.UP*1.65,door+Vector3.UP*1.5,66)
			walker.global_position=door+inward*2.0;walker.velocity=Vector3.ZERO
			walker.rotation=Vector3(0,PI,0);museum.set("_yaw",PI);museum.set("_pitch",0.0);museum.set("_vy",0.0)
			old_cam.rotation=Vector3.ZERO
			stream.set("_have_previous_eye",false);stream.set("_armed",true);stream.set_process(true)
			await create_timer(0.2).timeout
			museum.set_process(true)
			key(KEY_W,true)
			for i in 100:
				await physics_frame
				if bool(stream.get("busy")):break
				museum.call("_physics_process",museum.get_physics_process_delta_time())
			key(KEY_W,false)
			check("Walking through rear doorway requests next hall",bool(stream.get("busy")))
			var crossing:=Time.get_ticks_msec()
			while bool(stream.get("busy")) and Time.get_ticks_msec()-crossing<45000:await process_frame
			var next:Dictionary=stream.get("_current")
			observations.portal_end={"map":next.get("map",""),"phase":stream.get("phase"),"failure":stream.get("failure")}
			check("Portal completes arrival in Grammar Lab",not bool(stream.get("busy")) and str(next.get("map",""))=="LSystems_Grammar_Lab")
	observations.scope="Actual Endless Museum; original ten works and gallery retained. Before hides only new comparison table. Desktop button rays, supplied XRTools hand poses and walker passage into next hall. Exact printed script temporarily substituted for screenshot. No physical headset or Quest performance claim."

func key(code: int, down: bool) -> void:
	var event:=InputEventKey.new();event.keycode=code;event.physical_keycode=code;event.pressed=down
	Input.parse_input_event(event);Input.flush_buffered_events()
