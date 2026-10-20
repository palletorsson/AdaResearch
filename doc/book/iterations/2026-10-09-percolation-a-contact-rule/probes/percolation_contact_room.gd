extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-percolation-a-contact-rule/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hit_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func occupied(s)->Dictionary:
	var result:Dictionary={}
	for x in 18:
		for y in 18:
			for z in 18:
				if s.grid[x][y][z]!=0:result[Vector3i(x,y,z)]=true
	return result
func reached(s)->Dictionary:
	var result:Dictionary={}
	for x in 18:
		for y in 18:
			for z in 18:
				if s.grid[x][y][z] in [2,3,4]:result[Vector3i(x,y,z)]=true
	return result
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	observations.capture_exposure=.45
	var desk=find_scene("/timing_machines/pg_workshop.gd")
	check("Percolation desk bound",desk!=null and desk.ready_for_input and desk.chapter=="percolation")
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(13.5,0,3.5)
	desk.act("RESET");await tick()
	check("Face opening has one source and a colliding white neighbour",occupied(desk.model).size()==2 and reached(desk.model).size()==1 and desk.model.cube_nodes[10][1][9].has_node("CollisionBody") and not desk.model.cube_nodes[9][1][9].has_node("CollisionBody"))
	await snapshot("face-before",desk.model.to_global(Vector3(2,-2,3)),desk.model.to_global(Vector3(.25,-4,0)),55)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk approach supported clear",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["STEP","CONTACT","LATTICE","DENSITY","RULE","RESET"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await tick();var effect:=false
		match id:
			"STEP":effect=desk.model.grid[10][1][9]==2 and not desk.model.cube_nodes[10][1][9].has_node("CollisionBody")
			"CONTACT":effect=desk.variant==1 and desk.model.grid[10][2][10]==1 and reached(desk.model).size()==1
			"LATTICE":effect=desk.sampled and reached(desk.model).size()==324 and desk.sample_index==0
			"DENSITY":effect=desk.sample_index==1 and reached(desk.model).size()==324 and desk.step_count==0
			"RULE":effect=desk.rule_card.visible
			"RESET":effect=desk.variant==0 and occupied(desk.model).size()==2 and desk.step_count==0
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
	await driver.teardown();driver.queue_free();await tick()
	desk.act("STEP");await tick()
	await snapshot("face-after",desk.model.to_global(Vector3(2,-2,3)),desk.model.to_global(Vector3(.25,-4,0)),55)
	desk.act("CONTACT");desk.act("STEP");await tick()
	check("Corner still blocks signal and retains collision",reached(desk.model).size()==1 and desk.model.cube_nodes[10][2][10].has_node("CollisionBody"))
	await snapshot("corner",desk.model.to_global(Vector3(2,-2,3)),desk.model.to_global(Vector3(.25,-3.75,.25)),55)
	desk.act("RESET");desk.act("LATTICE");var sparse:Dictionary=occupied(desk.model)
	desk.act("DENSITY");var medium:Dictionary=occupied(desk.model)
	check("Same seed adds occupied sites at higher cutoff",sparse.keys().all(func(c):return medium.has(c)) and medium.size()>sparse.size())
	var projection=load(DIR+"printed/reach.gd").new();projection.occupied=medium.duplicate();projection.sources=reached(desk.model);projection.restart()
	check("Desk supplies whole z17 source face",projection.sources.size()==324 and projection.sources.keys().all(func(c):return c.z==17))
	await snapshot("lattice-start",desk.model.to_global(Vector3(9,7,11)),desk.model.global_position,70)
	var agreement:=true
	for i in 64:
		desk.act("STEP");projection.step()
		if i%8==7:agreement=agreement and projection.reached==reached(desk.model)
		await process_frame
	check("Actual sixty-four-step lattice matches Boolean reached projection",agreement)
	var state:Dictionary=reached(desk.model);desk.act("STEP")
	check("Desk sixty-four-step cap holds state",desk.step_count==64 and reached(desk.model)==state)
	check("Opposite z face reached in this seeded medium field",projection.far_count()>0)
	observations.lattice={"occupied":medium.size(),"reached_without_sources":state.size()-324,"far":projection.far_count(),"steps":64}
	await snapshot("lattice-reached",desk.model.to_global(Vector3(9,7,11)),desk.model.global_position,70)
	desk.act("DENSITY");var dense:Dictionary=occupied(desk.model)
	check("Dense comparison retains every medium occupied site",medium.keys().all(func(c):return dense.has(c)) and dense.size()>medium.size())
	var route_ok:=true;var samples:=0
	var route:=[Vector3(16,0,3.5),Vector3(24,0,3.5),Vector3(24,0,40.5),Vector3(13.5,0,40.5),Vector3(13.5,0,42.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
			route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Side bypass remains supported clear beside dense lattice",route_ok);observations.route_samples=samples
	var study=load(DIR+"printed/lattice.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,18)));root.add_child(study);await tick();await tick()
	var learner_approach:Vector3=map_at(Vector3(8.5,.01,16))
	check("Learner bay has supported clear hand approach",clear_body(learner_approach) and not floor_at(learner_approach).is_empty() and study.point.global_position.distance_to(learner_approach+Vector3.UP*1.1)<.9)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();controller.global_position+=Vector3(.2,.1,0);await tick();await tick()
	check("Held movement leaves wave unchanged",study.point.is_picked_up() and study.model.generation==0)
	study.point.action();await tick();check("Held trigger advances face transmission once",study.model.generation==1 and study.model.reached.size()==2)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Point returns beside learner field",study.point.position.is_equal_approx(Vector3(0,1.1,1.5)))
	origin.queue_free();await tick()
	desk.act("RESET");await tick()
	study.act("CONTACT");study.act("STEP")
	await snapshot("student-corner",study.to_global(Vector3(1.8,1.3,-2.4)),study.to_global(Vector3(0,1,0)),52)
	check("Printed corner remains white",study.model.reached.size()==1)
	study.act("DENSITY");study.act("TEN");study.act("TEN")
	check("Printed medium field matches headless count",study.model.reached.size()==97 and study.model.far_count()==4)
	await snapshot("student-field",study.to_global(Vector3(3,3,2.8)),study.to_global(Vector3(0,1.5,0)),62)
	desk.act("DENSITY");desk.act("DENSITY");await tick()
	await snapshot("above",desk.to_global(Vector3(0,46,-14)),desk.to_global(Vector3(0,0,-18)),70)
	desk.act("RESET");await tick()
	study.queue_free();await tick()
	var edited=load(DIR+"variation/lattice.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,18)));root.add_child(edited);await tick();edited.act("CONTACT");edited.act("STEP")
	check("Complete edited rule transmits selected corner in museum",edited.model.reached.size()==2)
	await snapshot("student-edited",edited.to_global(Vector3(1.8,1.3,-2.4)),edited.to_global(Vector3(0,1,0)),52)
	edited.queue_free();await tick()
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Onward record valid",not observations.exit.is_empty() and not observations.exit.get("invalid",false))
	observations.scope="Actual pointer controls, collision transition, 64-generation production projection, complete temporary learner/edit, supplied XRTools poses, side bypass only. Camera exposure .45; lighting unchanged. Entry marker blocked by desk. No physical headset, independent student or full portal traversal."
