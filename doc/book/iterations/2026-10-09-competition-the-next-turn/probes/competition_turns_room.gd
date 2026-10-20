extends "res://tools/probes/transformation_encounters.gd"
var map_origin:Vector3
func map_at(p:Vector3) -> Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty():observations["hits_"+str(at)]=hits.map(func(h):return str(h.collider.get_path()))
	return hits.is_empty()
func sum_cells(cells:Array) -> float:
	var value:=0.0
	for row in cells:
		for x in row:value+=x
	return value
func equal(a:Array,b:Array) -> bool:
	for z in a.size():
		for x in a[z].size():
			if not is_equal_approx(a[z][x],b[z][x]):return false
	return true
func landing_checks() -> void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/Ecosystem/ForestCompetition.gd");check("Existing forest present",source!=null)
	if source==null:return
	var desk=source.get_node("CompetitionLesson");var hand=desk.get_node("CompetitionHand")
	map_origin=source.global_position-hall.global_basis*Vector3(9.5,0,8.5)
	var works:Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node):works.append(str(rec.get("token","")))
	check("All three authored works retained once",["ForestCompetition","branching_coral","dark_sphere"].all(func(t):return works.count(t)==1))
	check("Original five strategies and four controls retained",source._trees.size()==5 and is_instance_valid(source._diffusion_ctrl) and is_instance_valid(source._supply_ctrl) and is_instance_valid(source._speed_ctrl) and is_instance_valid(source._trees_ctrl))
	var approach:Vector3=source.to_global(Vector3(.35,.01,2.65))
	check("Clear supported approach reaches carried point",clear_body(approach) and not floor_at(approach).is_empty() and hand.point.global_position.distance_to(approach+Vector3.UP*1.2)<.95)
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	desk.act("RESET");observations.buttons=[]
	for id in ["STEP","ORDER","SEASON","SOIL","RESET","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach)
		var effect:=false
		match id:
			"STEP":effect=desk.events.size()==1 and is_equal_approx(desk.last_takes[0],2.25)
			"ORDER":effect=desk.first==1 and desk.events.is_empty()
			"SEASON":effect=desk.winter and desk.events.is_empty()
			"SOIL":effect=desk.soil_seconds==1
			"RESET":effect=not desk.winter and desk.first==0 and desk.soil_seconds==0
			"RULE":effect=desk.readout.text.contains("uptake > 0.05")
		observations.buttons.append({"id":id,"pointer":result,"effect":effect})
		check("Actual desktop button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
	await driver.teardown();driver.queue_free();await tick()
	desk.act("RESET")
	await snapshot("opening",source.to_global(Vector3(7,6,6)),source.to_global(Vector3(0,1,-3)),66)
	var origin:=XROrigin3D.new();root.add_child(origin);var controller:=XRController3D.new();origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(pickup)
	controller.global_position=hand.point.global_position;hand.point.pick_up(pickup);await tick();await tick()
	controller.global_position+=Vector3(.2,.15,0);await tick();await tick()
	check("Held point moves without giving a tree a turn",hand.point.is_picked_up() and desk.events.is_empty())
	hand.point.action();await tick()
	check("Held trigger gives A one native kernel attempt",desk.events.size()==1 and is_equal_approx(desk.last_takes[0],2.25) and desk.model._trees[0].generation==1)
	origin.hide()
	await snapshot("hand",source.to_global(Vector3(2.0,2.0,3.8)),source.to_global(Vector3(.4,1.05,1.7)),64)
	hand.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release parks point without changing turn",hand.point.position.is_equal_approx(Vector3(.88,1.14,2)) and desk.events.size()==1)
	desk.act("STEP")
	check("Pair retains expected2.25 and1.98 allocations",is_equal_approx(desk.last_takes[0],2.25) and is_equal_approx(desk.last_takes[1],1.98))
	observations.first_pair=desk.last_takes.duplicate();var soil:Array=desk.model._nutrient_grid.duplicate(true)
	await snapshot("two-turns",source.to_global(Vector3(0,1.75,3.1)),source.to_global(Vector3(0,.8,-3)),78)
	await snapshot("soil",source.to_global(Vector3(2.9,5,-.3)),source.to_global(Vector3(0,.05,-3)),50)
	desk.act("ORDER");desk.act("STEP");desk.act("STEP")
	check("Reversed native pair swaps allocation and ends at same field",is_equal_approx(desk.last_takes[1],2.25) and is_equal_approx(desk.last_takes[0],1.98) and equal(soil,desk.model._nutrient_grid))
	desk.act("SEASON");desk.act("STEP");desk.act("STEP")
	check("Winter consumes without rewrite or diameter growth",desk.model._trees.all(func(t):return t.generation==0 and is_equal_approx(t.dbh,.02)) and is_equal_approx(sum_cells(desk.model._nutrient_grid),235.77))
	await snapshot("winter",source.to_global(Vector3(7,6,6)),source.to_global(Vector3(0,1,-3)),66)
	var turn:int=desk.model._current_grow_idx;var before:float=sum_cells(desk.model._nutrient_grid);desk.act("SOIL")
	check("SOIL changes field without tree turn or season change",desk.model._current_grow_idx==turn and desk.winter and desk.soil_seconds==1 and not is_equal_approx(sum_cells(desk.model._nutrient_grid),before))
	desk.act("RESET")
	for i in 6:desk.act("STEP")
	check("Six spring turns reach three generations each",desk.model._trees.all(func(t):return t.generation==3))
	soil=desk.model._nutrient_grid.duplicate(true);desk.act("STEP");desk.act("STEP")
	check("Native cap refuses consumption after six turns",equal(soil,desk.model._nutrient_grid) and desk.last_takes==[0.0,0.0])
	await snapshot("grown",source.to_global(Vector3(7,6,6)),source.to_global(Vector3(0,1,-3)),66)
	await snapshot("above",source.to_global(Vector3(0,29,-3)),source.to_global(Vector3(0,0,-9)),70)
	await snapshot("forest",source.to_global(Vector3(4,3,-10)),source.to_global(Vector3(0,.7,-15)),70)
	origin.queue_free();await tick()
	var route_ok:=true;var samples:=0
	for route in [[Vector3(9.5,0,2),Vector3(2.1,0,4),Vector3(2.1,0,31),Vector3(9.5,0,31),Vector3(9.5,0,32)], [Vector3(9.5,0,2),Vector3(16.9,0,4),Vector3(16.9,0,31),Vector3(9.5,0,31)]]:
		for j in range(route.size()-1):
			var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var at:Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok;samples+=1
	check("Supported outer routes connect entry and onward opening",route_ok);observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
		check("Entry and onward portal records valid",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	var study=load("res://doc/book/iterations/2026-10-09-competition-the-next-turn/printed/competition.gd").new();study.transform=source.global_transform;root.add_child(study)
	source.hide();desk.act("RESET");study.attempt();study.attempt();desk.act("STEP");desk.act("STEP")
	check("Exact printed first pair agrees with installed field inside museum",equal(study.soil.cells,desk.model._nutrient_grid) and is_equal_approx(study.trees[1].last,desk.last_takes[1]))
	await snapshot("student",study.to_global(Vector3(7,6,6)),study.to_global(Vector3(0,1,-3)),66)
	study.queue_free();source.show();desk.act("RESET")
	observations.scope="Actual Competition hall; six supplied desktop pointer events, XRTools supplied poses, native first-pair/winter/cap/soil tests and supported outer-route samples. Not physical headset, independent student or full portal traversal."
