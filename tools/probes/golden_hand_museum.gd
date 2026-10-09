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
	var source=find_scene("/fibonacci_sequences/FibonacciSequences.gd")
	var rectangle=find_scene("/golden_rectangle/golden_rectangle.gd")
	check("Both primary sources are installed",source!=null and rectangle!=null)
	if source==null or rectangle==null:return
	var desk=source.get_node("GoldenLesson");var hand=desk.hand_sum
	var rect_desk=rectangle.get_node("GoldenLesson")
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var n=rec.get("node")
		if is_instance_valid(n) and hall.is_ancestor_of(n):works.append(str(rec.get("token","")))
	observations.works=works
	var authored: Array=["fibonacci_sequences","golden_rectangle","the_recursion_cabinet","diffusion_limited_aggregation","dark_sphere","fibonacci_terrain","romanesco"]
	check("Seven authored specimens remain",authored.all(func(token):return works.count(token)==1))
	check("Six original controls per desk plus three nearby controls",desk.buttons.size()==6 and rect_desk.buttons.size()==6 and hand.nearby.size()==3)
	observations.source=xyz(hall.to_local(source.global_position));observations.hand=xyz(hall.to_local(hand.global_position));observations.rectangle=xyz(hall.to_local(rectangle.global_position))
	var approach:Vector3=hand.to_global(Vector3(0,0.005,1.12))
	check("Hand approach has floor and standing clearance",not floor_at(approach).is_empty() and clear_body(approach))
	check("Both points are reachable from one standing place",hand.points.all(func(p):return p.global_position.distance_to(approach+Vector3.UP*1.25)<0.85))
	hand.hide()
	await snapshot("before",source.to_global(Vector3(0,2.0,-8)),source.to_global(Vector3(0,1.1,-2.5)),72)
	hand.show()
	await snapshot("arrival",source.to_global(Vector3(0,2.0,-8)),source.to_global(Vector3(0,1.1,-2.5)),72)
	await snapshot("two-seeds",hand.to_global(Vector3(0,1.75,1.75)),hand.to_global(Vector3(0,1.3,0)),76)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(0.2).timeout
	for id in ["NEXT","BACK","RESET"]:
		var result:Dictionary=await driver.press(hand.nearby[id],approach)
		check("Nearby "+id+" reachable through desktop ray",str(result.get("hover","")) not in ["","none","null","nothing"])
	check("Nearby reset returns two seeds",hand.values==[1,1] and desk.term_count==2)
	var origin:=XROrigin3D.new();root.add_child(origin)
	var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.points[0].global_position;hand.points[0].pick_up(pickup);await create_timer(0.2).timeout
	controller.global_position=hand.points[1].global_position-hand.global_basis.x*0.17;await create_timer(0.3).timeout
	check("Museum pickup and contact reveal third term",desk.term_count==3 and hand.values==[1,1,2])
	origin.hide()
	await snapshot("one-sum",hand.to_global(Vector3(0,1.75,1.75)),hand.to_global(Vector3(0,1.3,0)),76)
	check("Held contact stays a single request",desk.term_count==3)
	hand.points[0].let_go(pickup,Vector3.ZERO,Vector3.ZERO);await create_timer(0.2).timeout
	check("Release returns point and exposes1+2",hand.names[0].text=="1" and hand.names[1].text=="2" and not hand.latched)
	for i in 7:desk.act("NEXT")
	await snapshot("two-views",hand.to_global(Vector3(0,1.75,1.75)),hand.to_global(Vector3(0,1.3,0)),76)
	check("Hand and large desk agree at ten terms",desk.term_count==10 and hand.values==source.fibonacci_numbers.slice(0,10))
	await snapshot("large-log",source.to_global(Vector3(0,2.4,-7)),source.to_global(Vector3(0,1.6,0)),70)
	var record:Array=hand.values.duplicate();desk.act("HEIGHT")
	await snapshot("large-linear",source.to_global(Vector3(0,2.4,-7)),source.to_global(Vector3(0,1.6,0)),70)
	check("HEIGHT keeps hand record and changes large height",hand.values==record and is_equal_approx(desk.height_values[-1],2.75))
	desk.act("SUM")
	await snapshot("unit-sum",source.to_global(Vector3(5.0,2.5,-3.8)),source.to_global(Vector3(5.8,1.7,0)),57)
	check("SUM reveals fixed-unit witness",desk.sum_view.visible)
	var ids:Array=source.get_node("NaturalPatterns").get_children().map(func(n):return n.get_instance_id())
	for id in ["HEIGHT","BACK","NEXT","RULE"]:desk.act(id)
	check("Primary edits preserve held secondary examples",ids==source.get_node("NaturalPatterns").get_children().map(func(n):return n.get_instance_id()))
	await snapshot("added-rules",source.to_global(Vector3(1.5,3.1,2.5)),source.to_global(Vector3(0,1.5,6)),80)
	var rect_approach:Vector3=rect_desk.to_global(Vector3(0,0.005,2.85))
	check("Rectangle desk approach supported and clear",not floor_at(rect_approach).is_empty() and clear_body(rect_approach))
	for i in 5:await driver.press(rect_desk.buttons.NEXT,rect_approach)
	for id in ["MEASURE","ARC"]:await driver.press(rect_desk.buttons[id],rect_approach)
	check("Rectangle controls work through actual pointer",rect_desk.cut==5 and rect_desk.show_measure and rect_desk.show_arc)
	await snapshot("rectangle",rectangle.to_global(Vector3(0,2.8,-6)),rectangle.to_global(Vector3(0,2.4,0)),58)
	var retained:Array=rectangle.rectangles.duplicate(true)
	await driver.press(rect_desk.buttons.ARC,rect_approach)
	check("Removing arc retains partition",not rect_desk.show_arc and rectangle.rectangles==retained)
	await snapshot("rectangle-no-arc",rectangle.to_global(Vector3(0,2.8,-6)),rectangle.to_global(Vector3(0,2.4,0)),58)
	await snapshot("overview",source.to_global(Vector3(-6,9,-4)),source.to_global(Vector3(0,1,10)),80)
	driver.teardown();await process_frame
	var study=load("res://ada_run/golden_student/sum_points.gd").new();study.transform=hand.global_transform;root.add_child(study);hand.hide()
	for i in 8:study.advance()
	await snapshot("student",study.to_global(Vector3(0,1.75,1.75)),study.to_global(Vector3(0,1.3,0)),76)
	check("Exact printed code runs inside the museum",study.values==[1,1,2,3,5,8,13,21,34,55] and study.drawing.get_child_count()==42)
	study.queue_free();hand.show();origin.queue_free()
	if stream!=null:
		var exit_data:Dictionary=stream.get("_exit");var entry_data:Dictionary=stream.get("_entry")
		observations.exit=exit_data;observations.entry=entry_data
		check("Both authored portals validate",not exit_data.get("invalid",false) and not entry_data.get("invalid",false))
	observations.scope="Actual Endless Museum with seven retained specimens. Original desk/rectangle controls through supplied desktop ray; XRTools pickup with supplied pose. Before image hides only the new table. Student image temporarily substitutes exact printed scripts. No physical headset or Quest performance claim."
