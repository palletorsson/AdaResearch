extends "res://tools/probes/transformation_encounters.gd"
var source_origin: Vector3
func map_at(p: Vector3) -> Vector3:return source_origin+hall.global_basis*p
func clear_body(at:Vector3) -> bool:
	var capsule:=CapsuleShape3D.new();capsule.radius=.28;capsule.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=capsule;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1.0).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var wardrobe=museum.get("_wardrobe")
	if wardrobe!=null and is_instance_valid(wardrobe.get("costume")):wardrobe.get("costume").hide()
	var source=find_scene("/the_believing_turtle/the_believing_turtle.gd")
	check("Existing three-reader interpreter present",source!=null)
	if source==null:return
	var desk=source.get_node("InterpreterLesson");var hand=desk.get_node("InterpreterHand")
	source_origin=source.global_position-hall.global_basis*Vector3(9.5,0,7.5)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	observations.works=works
	var authored:=["the_believing_turtle","ContextFreeGrammars","space_filling_curve_gallery","Hilbert3D","lindenmayer_tube_tree","film_grammar_forward","tube_painting"]
	check("Seven authored works retained once",authored.all(func(t):return works.count(t)==1))
	check("Original lectern and studies remain behind the primary",source.has_node("OriginalStudy") and source.get_node("OriginalStudy").get_child_count()>0)
	var approach:Vector3=source.to_global(Vector3(0,.005,3.2))
	check("Controls have supported clear approach",not floor_at(approach).is_empty() and clear_body(approach))
	check("Carried point within reach of control position",hand.point.global_position.distance_to(approach+Vector3.UP*1.2)<.85)
	await snapshot("arrival",source.to_global(Vector3(0,1.75,6.5)),source.to_global(Vector3(0,2.5,0)),90)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	for id in ["STEP","READ F","ANGLE","TREE","RESET","RULE"]:
		var r:Dictionary=await driver.press(desk.buttons[id],approach)
		check("Nearby pointer reaches "+id,str(r.get("hover","")) not in ["","none","null","nothing"])
	await driver.teardown();driver.queue_free();await tick()
	desk.act("RESET")
	var original_text:String=desk.sentence;var reference:Dictionary=desk.readings[0].duplicate(true)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position=hand.to_global(Vector3(.35,1.18,2.55));await tick();await tick();await tick()
	check("Held point selects90; reference sentence generation and cursor retained",hand.point.is_picked_up() and desk.turn_angle==90 and desk.readings[0]==reference and desk.sentence==original_text and desk.generation==1 and desk.cursor==1)
	hand.point.action();await tick()
	check("Held trigger reflects blue first step without changing heading",desk.sideways and desk.cursor==1 and desk.readings[2].frames[1].pos.is_equal_approx(Vector3.RIGHT*.32) and is_equal_approx(desk.readings[2].frames[1].heading,PI/2))
	origin.hide()
	await snapshot("hand",source.to_global(Vector3(1.7,2.1,3.7)),source.to_global(Vector3(0,1.14,2.2)),70)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks at selected angle without advancing",not hand.point.held() and hand.point.position.is_equal_approx(Vector3(.35,1.18,2.55)) and desk.cursor==1)
	desk.act("ANGLE") # 90 ->25
	desk.act("ANGLE") # 25 ->45; matches baseline comparison.
	for i in 5:desk.act("STEP")
	check("Symbol6 reveals three branches with shared count and different direction rules",desk.cursor==6 and desk.readings.all(func(r):return r.frames[6].count==3) and not desk.readings[0].frames[6].pos.is_equal_approx(desk.readings[1].frames[6].pos) and not desk.readings[0].frames[6].pos.is_equal_approx(desk.readings[2].frames[6].pos))
	await snapshot("fork",source.to_global(Vector3(0,2.6,6.2)),source.to_global(Vector3(0,2.4,0)),94)
	var rods_match:=true;var rod_count:=0
	for generation in [1,2]:
		desk.generation=generation;desk.cursor=10000;desk.rebuild()
		for i in 3:
			var mesh:MultiMesh=desk.views[i].get_child(0).multimesh
			for j in desk.readings[i].segments.size():
				var pose:=mesh.get_instance_transform(j)
				rods_match=rods_match and (pose*Vector3(0,-.5,0)).is_equal_approx(desk.readings[i].segments[j][0]) and (pose*Vector3(0,.5,0)).is_equal_approx(desk.readings[i].segments[j][1])
				rod_count+=1
	check("All216 displayed cylinders join recorded endpoints at both generations",rods_match and rod_count==216)
	check("Second generation retains common metre units and64 segments each",desk.sentence.length()==172 and desk.readings.all(func(r):return r.segments.size()==64) and desk.views.all(func(v):return v.scale==Vector3.ONE))
	var reflected:=true
	for i in desk.readings[0].frames.size():
		var a:Dictionary=desk.readings[0].frames[i];var b:Dictionary=desk.readings[2].frames[i]
		reflected=reflected and b.pos.is_equal_approx(Vector3(a.pos.y,a.pos.x,0)) and is_equal_approx(a.heading,b.heading)
	check("Installed blue reader reflects entire second-generation path",reflected)
	await snapshot("three",source.to_global(Vector3(0,3.1,6.2)),source.to_global(Vector3(0,3.2,0)),96)
	await snapshot("above",map_at(Vector3(11.5,47,17)),map_at(Vector3(11.5,0,26)),72)
	await snapshot("opening-above",map_at(Vector3(9.5,24,3)),map_at(Vector3(9.5,0,10)),70)
	await snapshot("applications",map_at(Vector3(11.5,2,30)),map_at(Vector3(11.5,3,39.5)),80)
	desk.act("STEP");check("STEP wraps last symbol to START",desk.cursor==0 and desk.views.all(func(v):return not v.get_child(0) is MultiMeshInstance3D))
	desk.act("RESET");check("RESET restores initial reading",desk.cursor==1 and desk.generation==1 and desk.turn_angle==25 and not desk.sideways)
	origin.queue_free();await tick()
	var route_ok:=true;var samples:=0
	for route in [[Vector3(9.5,0,2),Vector3(2.1,0,4),Vector3(2.1,0,10),Vector3(9.5,0,12),Vector3(9.5,0,17.5),Vector3(13.8,0,17.5),Vector3(13.8,0,23),Vector3(10.6,0,25),Vector3(10.6,0,28.5),Vector3(9.5,0,29),Vector3(2.2,0,30),Vector3(2.2,0,47),Vector3(11.5,0,48.5)], [Vector3(9.5,0,2),Vector3(16.7,0,4),Vector3(16.7,0,10),Vector3(9.5,0,12)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var p:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(p) and not floor_at(p).is_empty() and route_ok;samples+=1
	check("Bypasses, curve room and tube-bay onward route have supported capsule path",route_ok)
	observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Nonempty entry and onward portal validate",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	var study=load("res://doc/book/iterations/2026-10-09-curves-one-sentence-three-readers/printed/readers.gd").new()
	study.global_transform=source.global_transform;root.add_child(study)
	study.choose(1);study.exchange();study.set_tree(2);source.hide()
	await snapshot("student",study.to_global(Vector3(0,3.1,6.2)),study.to_global(Vector3(0,3.2,0)),96)
	check("Exact printed program reconstructs three readings inside museum",study.cursor==172 and study.sideways and study.angle==45 and study.drawing.get_child_count()==201)
	study.queue_free();source.show()
	observations.scope="Actual Curves hall; supplied desktop rays, real XRTools with supplied poses, supported capsule samples and native images. No physical headset, independent student or complete portal traversal."
