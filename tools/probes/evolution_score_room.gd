extends "res://tools/probes/transformation_encounters.gd"
const DIR:="res://doc/book/iterations/2026-10-09-evolution-what-the-score-reads/"
var map_origin:Vector3
func map_at(p:Vector3) -> Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func same_opening(study,desk) -> bool:
	for record in study.candidates:
		var found:=false
		for g in desk.model.population:
			if g.id==record.id:
				found=g.genes.size()==record.genes.size() and g.genes[0].parameters.scale==record.genes[0].scale and g.genes[0].parameters.position==record.genes[0].position
		if not found:return false
	return true
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var desk=find_scene("/genetic_programming/selection_lesson.gd")
	check("Existing six-candidate lesson loaded",desk!=null)
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(9.5,0,5.5)
	desk.act("RESET");desk.act("HOLD")
	check("Opening unit box leads with100",desk.model.best_genome.id==1 and is_equal_approx(desk.model.best_genome.fitness,100))
	await snapshot("opening",desk.to_global(Vector3(4,3,2)),desk.to_global(Vector3(0,1.2,-6)),80)
	var opening:Array=[]
	for g in desk.model.population:opening.append(desk.signature(g))
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Actual console approach clear and supported",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	var retained:Array=desk.signature(desk.held_genome);var elite_signatures:Array=[]
	observations.buttons=[]
	for id in ["TARGET","RING","HOLD","RULE","STEP","RESET"]:
		if id=="STEP":elite_signatures=[desk.signature(desk.model.population[0]),desk.signature(desk.model.population[1])]
		var result:Dictionary=await driver.press(desk.buttons[id],approach);var effect:=false
		match id:
			"TARGET":effect=desk.model.current_generation==0 and desk.model.best_genome.id==2 and is_equal_approx(desk.model.best_genome.fitness,100/1.375)
			"RING":effect=desk.model.best_genome.genes.size()==2 and is_equal_approx(desk.model.best_genome.fitness,100/1.375)
			"HOLD":effect=desk.held_genome.genes.size()==2;retained=desk.signature(desk.held_genome)
			"RULE":effect=desk.rule_card.visible
			"STEP":effect=desk.model.current_generation==1 and desk.model.population.size()==6
			"RESET":effect=desk.model.current_generation==0 and desk.model.best_genome.id==1 and desk.signature(desk.held_genome)==retained
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
		if id=="TARGET":
			check("Target reorders same installed descriptions",desk.model.population.all(func(g):return desk.signature(g) in opening))
			await snapshot("target",desk.to_global(Vector3(0,2.5,1)),desk.to_global(Vector3(0,1.3,-5)),83)
		if id=="RING":await snapshot("ring",desk.to_global(Vector3(4,3,2)),desk.to_global(Vector3(0,1.2,-6)),80)
		if id=="STEP":
			var signatures:Array=desk.model.population.map(func(g):return desk.signature(g))
			check("One installed generation preserves two unchanged elites",elite_signatures.all(func(s):return s in signatures))
			check("Held genome survives offspring",desk.signature(desk.held_genome)==retained)
	await driver.teardown();driver.queue_free();await tick()
	desk.model.current_generation=50;desk.act("STEP")
	check("Generation limit blocks next step",desk.model.current_generation==50 and desk.notice.contains("limit"))
	desk.act("RESET");desk.act("HOLD")
	check("Generated specimens are collision-free",desk.model.population.all(func(g):return g.phenotype.find_children("*","CollisionObject3D",true,false).is_empty()))
	var ramp=hall.find_child("ObservationRampSupport",true,false)
	check("Retained observation ramp exists",ramp!=null)
	var supported:=true
	for i in 13:
		var x:float=1.15+float(i)*.25;var y:float=minf((x-1)/3*2,2)
		var hit:Dictionary=floor_at(map_at(Vector3(x,y+.05,25.8)))
		supported=supported and not hit.is_empty()
	check("Thirteen ramp samples reach the two-metre deck",supported)
	var route_ok:=true;var route_samples:=0
	var route:=[Vector3(9.5,0,1.5),Vector3(17,0,3.5),Vector3(17,0,36.5),Vector3(9.5,0,36.5),Vector3(9.5,0,37.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
			route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;route_samples+=1
	check("Supported eastern bypass reaches rear exit approach",route_ok);observations.route_samples=route_samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Entry and onward records valid",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.exit.get("invalid",false))
	var bay:Vector3=map_at(Vector3(9.5,.01,16.8));var learner_approach:Vector3=map_at(Vector3(9.5,.01,15))
	check("Learner bay and approach clear and supported",clear_body(bay) and clear_body(learner_approach) and not floor_at(bay).is_empty() and not floor_at(learner_approach).is_empty())
	var study=load(DIR+"printed/selection.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(9.5,0,16.8)));root.add_child(study);await tick();await tick()
	check("Printed candidate genes match installed opening",same_opening(study,desk))
	check("Study point reachable from approach",study.point.global_position.distance_to(learner_approach+Vector3.UP*1.2)<.9)
	await snapshot("student",study.to_global(Vector3(0,2.3,1.8)),study.to_global(Vector3(-.3,.9,-.6)),86)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();controller.global_position+=Vector3(.2,.1,0);await tick();await tick()
	check("Hand movement leaves score criterion alone",study.point.is_picked_up() and study.target_index==0 and same_opening(study,desk))
	study.point.action();await tick();check("Held trigger changes target while genes remain",study.target_index==1 and same_opening(study,desk))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Released point parks at learner host",study.point.position.is_equal_approx(Vector3(0,1.15,1.1)))
	origin.queue_free();await tick();study.act("RING")
	await snapshot("student-ring",study.to_global(Vector3(0,2.3,1.8)),study.to_global(Vector3(-.3,.9,-.6)),86)
	await snapshot("above",desk.to_global(Vector3(0,38,-7)),desk.to_global(Vector3(0,0,-13)),70)
	study.queue_free();await tick()
	var edited=load(DIR+"variation/selection.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(9.5,0,16.8)));root.add_child(edited);await tick();await tick()
	check("Complete corrected-coefficient program selects ID5 in museum",edited.bodies[5].position==Vector3(-1.15,.6,0) and same_opening(edited,desk))
	await snapshot("student-corrected",edited.to_global(Vector3(0,2.3,1.8)),edited.to_global(Vector3(-.3,.9,-.6)),86)
	edited.queue_free();await tick()
	await snapshot("deck",desk.to_global(Vector3(-5,6,-19)),desk.to_global(Vector3(0,1,-25)),65)
	observations.scope="Installed score/selection desk, actual pointer effects, single-generation elites, supplied XRTools learner input, complete edited learner program, sampled right bypass and ramp. Production unchanged. No headset, full portal traversal, arbitrary secondary screen functionality or independent-student acceptance."
