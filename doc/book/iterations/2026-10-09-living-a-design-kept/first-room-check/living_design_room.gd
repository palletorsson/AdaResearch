extends "res://tools/probes/transformation_encounters.gd"
var map_origin:Vector3
func map_at(p:Vector3) -> Vector3:return map_origin+hall.global_basis*p
func geometry(node:Node, include_transform:bool=false) -> String:
	var value:=""
	if include_transform and node is Node3D:value+=str(node.transform)
	if node is MeshInstance3D and node.mesh:
		for surface in node.mesh.get_surface_count():value+=str(node.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX])
	for child in node.get_children():value+=geometry(child,true)
	return value
func clear_body(at:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/genetic_tree_sculptor/genetic_tree_sculptor.gd");check("Existing sculptor present",source!=null)
	if source==null:return
	var desk=source.get_node("LivingLesson");var hand=desk.get_node("LivingHand")
	map_origin=source.global_position-hall.global_basis*Vector3(9.5,0,8.5)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	observations.works=works
	check("All six authored works retained",["genetic_tree_sculptor","lsystem_tree","branching_coral","living_paper_fern","living_paper_tree","living_paper_dragon"].all(func(t):return works.count(t)==1))
	check("All eight original genes retained",source.GENE_SLIDERS.size()==8 and is_instance_valid(source._control_panel))
	var approach:Vector3=source.to_global(Vector3(.35,.01,3.25))
	check("Supported clear approach within hand reach",clear_body(approach) and not floor_at(approach).is_empty() and hand.point.global_position.distance_to(approach+Vector3.UP*1.2)<.95)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	desk.act("RESET");observations.buttons=[]
	for id in ["MORE","LESS","GENE","HOLD","PLANT","RESET"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach)
		var effect:=false
		match id:
			"MORE":effect=is_equal_approx(source._dna.segments,4.2)
			"LESS":effect=is_equal_approx(source._dna.segments,4)
			"GENE":effect=desk.gene_index==1
			"HOLD":effect=is_instance_valid(desk.held) and desk.held_dna!=source._dna
			"PLANT":effect=is_instance_valid(desk.planted) and desk.planted_dna!=source._dna
			"RESET":effect=desk.gene_index==0 and is_equal_approx(source._dna.segments,4)
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
		check("Actual desktop button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
	await driver.teardown();driver.queue_free();await tick()
	desk.act("RESET");desk.act("HOLD")
	var baseline:=geometry(source._tree_root);var kept:=geometry(desk.held)
	check("HOLD retains the exact initial geometry",baseline==kept)
	await snapshot("opening",source.to_global(Vector3(6,5,5)),source.to_global(Vector3(0,1.6,-3)),68)
	for i in 4:desk.act("MORE")
	source.flush_preview()
	check("Depth4.8 changes record but not compiled tree",is_equal_approx(source._dna.segments,4.8) and desk.readings().generations==2 and geometry(source._tree_root)==baseline)
	await snapshot("below",source.to_global(Vector3(0,1.75,3.1)),source.to_global(Vector3(0,1.3,-2)),82)
	desk.act("MORE");source.flush_preview()
	check("Depth5.0 crosses threshold and changes geometry",is_equal_approx(source._dna.segments,5) and desk.readings().generations==3 and geometry(source._tree_root)!=baseline)
	check("Held record and geometry survive later edits",is_equal_approx(desk.held_dna.segments,4) and geometry(desk.held)==kept)
	await snapshot("threshold",source.to_global(Vector3(6,5,5)),source.to_global(Vector3(0,1.6,-3)),68)
	desk.act("PLANT");var planted:=geometry(desk.planted);var exported:CritterDNA=Engine.get_meta("sculptor_tree_dna")
	check("PLANT exports an independent record",desk.planted_dna!=exported and exported!=source._dna and is_equal_approx(exported.segments,5))
	desk.act("RESET")
	check("RESET preserves both kept specimens",geometry(desk.held)==kept and geometry(desk.planted)==planted and is_equal_approx(desk.planted_dna.segments,5))
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick();await tick()
	check("Picking up does not edit the design",hand.point.is_picked_up() and is_equal_approx(source._dna.segments,4))
	controller.global_position=hand.to_global(Vector3(-.1,1.18,2.55));await tick();await tick()
	check("Hand position selects depth5",is_equal_approx(source._dna.segments,5))
	hand.point.action();await tick()
	check("Held trigger flushes and keeps the current design",not source._rebuild_queued and is_equal_approx(desk.held_dna.segments,5) and geometry(desk.held)==geometry(source._tree_root))
	origin.hide()
	await snapshot("hand",source.to_global(Vector3(1.8,2.3,4)),source.to_global(Vector3(0,1.1,2.1)),55)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks without changing design",hand.point.position.is_equal_approx(Vector3(-.1,1.18,2.55)) and is_equal_approx(source._dna.segments,5))
	desk.act("RESET");desk.act("HOLD");for i in 5:desk.act("MORE")
	desk.act("PLANT")
	await snapshot("planted",source.to_global(Vector3(5,4,-4)),source.to_global(Vector3(0,1.2,-8)),65)
	source.set_gene_normalized("segments",1);source.set_gene_normalized("symmetry",1);source.flush_preview()
	check("Maximum genes request4964 commands against200 budget",desk.readings().commands==4964 and desk.readings().budget==200)
	desk.act("RESET");for i in 5:desk.act("MORE")
	source.flush_preview()
	await snapshot("above",source.to_global(Vector3(0,31,-3)),source.to_global(Vector3(0,0,-10)),70)
	await snapshot("collection",source.to_global(Vector3(4,4,-10)),source.to_global(Vector3(0,1,-17)),75)
	origin.queue_free();await tick()
	var route_ok:=true;var samples:=0
	for route in [[Vector3(9.5,0,2),Vector3(2.1,0,4),Vector3(2.1,0,33),Vector3(9.5,0,33),Vector3(9.5,0,34)], [Vector3(9.5,0,2),Vector3(16.9,0,4),Vector3(16.9,0,33),Vector3(9.5,0,33)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Supported outer routes reach onward opening",route_ok);observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Entry and onward portal records valid",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	var study=load("res://doc/book/iterations/2026-10-09-living-a-design-kept/printed/living.gd").new();study.transform=source.global_transform;root.add_child(study)
	source.hide();study.keep("held");study.set_normalized(.375);study.keep("planted")
	check("Exact printed study matches current compiled sentence in museum",study.preview.sentence==desk.readings().sentence and study.held.depth==4 and study.planted.depth==5)
	await snapshot("student",study.to_global(Vector3(6,5,5)),study.to_global(Vector3(0,1.6,-3)),68)
	study.queue_free();source.show();desk.act("RESET")
	observations.scope="Actual Living hall. Six supplied desktop pointer effects, XRTools supplied poses, geometry threshold and independent snapshots, supported routes, portal records. No physical headset, independent learner or full portal traversal claim."
