extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-sculpted-what-the-centres-keep/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	return hits.is_empty()
func same_vertices(a:ArrayMesh,b:ArrayMesh)->bool:
	var av:PackedVector3Array=a.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	var bv:PackedVector3Array=b.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	if av.size()!=bv.size():return false
	for i in av.size():
		if not av[i].is_equal_approx(bv[i]):return false
	return true
func collider_count(model:Node)->int:
	var count:=0
	for n in model.get_children():
		if str(n.name).begins_with("MoundCollider"):count+=1
	return count
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	var desk=find_scene("/timing_machines/pg_workshop.gd")
	check("Sculpted desk bound",desk!=null and desk.ready_for_input and desk.chapter=="sculpted")
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(16.5,0,3.5)
	observations.mound_origin=xyz(desk.model.global_position);observations.dome_origin=xyz(desk.other.global_position)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	observations.desk_approach_clear=clear_body(approach);observations.desk_approach_supported=not floor_at(approach).is_empty()
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	var Frozen:Array=[];observations.buttons=[]
	for id in ["DROP","SAMPLE","VOXEL","ORIGINAL","CUT","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.35).timeout;var effect:=false
		match id:
			"DROP":effect=desk.model.cubes.size()==12 and not desk.sampled and collider_count(desk.model)==0 and desk.model.cubes.all(func(c):return not c.freeze)
			"SAMPLE":
				effect=desk.sampled and is_instance_valid(desk.model.generated_mesh) and collider_count(desk.model)==1 and desk.model.cubes.all(func(c):return c.freeze and c.collision_layer==0 and not c.visible)
				for c in desk.model.cubes:Frozen.append(c.global_transform)
				await snapshot("sample-fine",desk.model.to_global(Vector3(-6,6,-9)),desk.model.to_global(Vector3(0,3.5,0)),62)
			"VOXEL":effect=desk.model.voxel_size==1.0 and desk.sampled and collider_count(desk.model)==1
			"ORIGINAL":effect=desk.model.cubes[0].visible and not desk.model.generated_mesh.visible and collider_count(desk.model)==1 and desk.model.cubes.all(func(c):return c.freeze and c.collision_layer==0)
			"CUT":effect=desk.other.facture=="blank"
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
	await driver.teardown();driver.queue_free();await tick()
	var stable:=true
	for i in Frozen.size():stable=stable and desk.model.cubes[i].global_transform.is_equal_approx(Frozen[i])
	check("Resolution and view changes retain frozen body transforms",stable)
	await snapshot("originals",desk.model.to_global(Vector3(-6,6,-9)),desk.model.to_global(Vector3(0,3.5,0)),62)
	desk.act("ORIGINAL");await tick()
	await snapshot("sample-coarse",desk.model.to_global(Vector3(-6,6,-9)),desk.model.to_global(Vector3(0,3.5,0)),62)
	var model=load(DIR+"printed/sample.gd").new();var assembler=load(DIR+"printed/faces.gd")
	var agreement:=true;observations.production_samples=[]
	for spacing in [1.0,.5]:
		if desk.model.voxel_size!=spacing:desk.act("VOXEL");await create_timer(.4).timeout
		model.cell_size=spacing;model.capture(desk.model,desk.model.cubes)
		var mesh:ArrayMesh=assembler.build(model.faces(),model.origin,spacing)
		agreement=agreement and same_vertices(mesh,desk.model.generated_mesh.mesh)
		observations.production_samples.append({"spacing":spacing,"cells":model.cells.size(),"faces":model.faces().size(),"bounds":str(mesh.get_aabb()),"centres":model.centres.map(func(p):return xyz(p))})
	check("Printed pipeline reproduces actual frozen pile vertices at two spacings",agreement)
	check("Rebuilt mound has one generated collider",collider_count(desk.model)==1)
	desk.act("CUT");await create_timer(.5).timeout
	check("Dome cores are an alternate state of same artifact",desk.other.facture=="core")
	await snapshot("dome-cores",desk.other.to_global(Vector3(-15,18,25)),desk.other.to_global(Vector3(0,10,0)),62)
	desk.act("CUT");await create_timer(.5).timeout
	check("Dome section is available",desk.other.facture=="section")
	await snapshot("dome-section",desk.other.to_global(Vector3(-15,18,25)),desk.other.to_global(Vector3(0,10,0)),62)
	desk.act("CUT");await create_timer(.4).timeout;check("Dome returns to cast",desk.other.facture=="cast")
	var route_ok:=true;var supported:=true;var samples:=0;var blocked:Array=[]
	var route:=[Vector3(10,0,3.5),Vector3(3,0,3.5),Vector3(3,0,23),Vector3(20,0,23),Vector3(20,0,40.5),Vector3(16.5,0,40.5),Vector3(16.5,0,42.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:Vector3=map_at(p+Vector3.UP*.01)
			var clear:=clear_body(at);route_ok=clear and route_ok;supported=not floor_at(at).is_empty() and supported;samples+=1
			if not clear:blocked.append(xyz(p))
	observations.route={"clear":route_ok,"supported":supported,"samples":samples,"blocked":blocked,"scope":"Measured candidate bypass; not a gameplay or portal traversal."}
	var study=load(DIR+"printed/sculpture.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,21)));root.add_child(study);await tick();await tick()
	var learner_approach:Vector3=map_at(Vector3(8.5,.01,19))
	check("Learner bay has supported clear hand approach",clear_body(learner_approach) and not floor_at(learner_approach).is_empty() and study.point.global_position.distance_to(learner_approach+Vector3.UP*1.1)<.9)
	observations.learner_baseline={"cells":study.model.cells.size(),"faces":study.model.faces().size(),"centres":study.model.centres.map(func(p):return xyz(p))}
	await snapshot("student-originals",study.to_global(Vector3(-2,2.6,3.2)),study.to_global(Vector3(0,1.6,0)),56)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();hand.global_position+=Vector3(.2,.1,0);await tick()
	check("Moving held point does not sample",study.point.is_picked_up() and not study.show_sample)
	study.point.action();await tick();check("Held action reveals sampled surface",study.show_sample and study.skin.visible and not study.bodies[0].visible)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();check("Release parks inherited point",study.point.position.is_equal_approx(Vector3(0,1.1,1.5)))
	origin.queue_free();await tick()
	await snapshot("student-sample",study.to_global(Vector3(-2,2.6,3.2)),study.to_global(Vector3(0,1.6,0)),56)
	var record:Array=study.model.centres.duplicate();var occupied:Dictionary=study.model.cells.duplicate()
	study.act("MOVE");study.act("VIEW");check("Source moves without replacing retained sample",study.model.centres==record and study.model.cells==occupied)
	study.act("SAMPLE");check("Resampling records moved source",study.model.centres[2].is_equal_approx(Vector3(2,1,0)) and study.model.cells!=occupied)
	study.act("RESET");study.act("SAMPLE");await tick()
	await snapshot("above",desk.to_global(Vector3(0,47,-15)),desk.to_global(Vector3(0,0,-18)),70)
	desk.act("CUT");desk.act("CUT");desk.act("CUT");await create_timer(.5).timeout
	await snapshot("above-section",desk.to_global(Vector3(0,47,-15)),desk.to_global(Vector3(0,0,-18)),70)
	desk.act("CUT");await create_timer(.5).timeout
	study.queue_free();await tick()
	var edited=load(DIR+"variation/sculpture.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,21)));root.add_child(edited);await tick();edited.act("SAMPLE");await tick()
	check("Complete edited host retains centres and marks smaller subset",edited.model.centres==record and edited.model.cells.size()<occupied.size() and edited.model.cells.keys().all(func(c):return occupied.has(c)))
	observations.learner_edited={"cells":edited.model.cells.size(),"faces":edited.model.faces().size()}
	await snapshot("student-edited",edited.to_global(Vector3(-2,2.6,3.2)),edited.to_global(Vector3(0,1.6,0)),56)
	edited.queue_free();await tick()
	desk.act("DROP");await tick();await tick()
	check("New drop removes old generated collider and returns moving bodies",collider_count(desk.model)==0 and not desk.sampled and desk.model.cubes.all(func(c):return not c.freeze and c.collision_layer!=0))
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Onward record valid",not observations.exit.is_empty() and not observations.exit.get("invalid",false))
	observations.scope="Actual pointer controls, actual frozen-pile vertex agreement at two spacings, collider lifetime, dome states, complete learner and extent edit, supplied XRTools poses. Candidate bypass measured separately; dome dominates room. No headset, player walk atop mound, or full portal traversal."
