extends "res://tools/probes/transformation_encounters.gd"
const DIR := "res://doc/book/iterations/2026-10-09-mirrored-a-copy-kept/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.transform.origin=at+Vector3.UP*.88;query.collision_mask=1|4
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()
func quad(field:Array)->Array:
	var model=load(DIR+"printed/reflection.gd").new();model.hold(field);model.reflect();return model.result
func lives(field:Array)->int:
	var count:=0
	for row in field:count+=row.count(1)
	return count
func next_life(field:Array)->Array:
	var n:=field.size();var out:Array=field.duplicate(true)
	for y in range(1,n-1):
		for x in range(1,n-1):
			var count:=0
			for dy in range(-1,2):
				for dx in range(-1,2):
					if dx!=0 or dy!=0:count+=field[y+dy][x+dx]
			out[y][x]=int(count==3 or (field[y][x]==1 and count==2))
	return out
func graph_count(generator:Node)->Dictionary:
	var components:=0;var seen:Dictionary={};var edges:Dictionary={};var adj:Dictionary={}
	for node in generator.network_nodes:adj[node.id]=[]
	for edge in generator.connections:
		var pair:Vector2i=Vector2i(mini(edge.start_id,edge.end_id),maxi(edge.start_id,edge.end_id))
		if edges.has(pair):continue
		edges[pair]=true;adj[edge.start_id].append(edge.end_id);adj[edge.end_id].append(edge.start_id)
	for id in adj:
		if seen.has(id):continue
		components+=1;var pending:Array=[id];seen[id]=true
		while not pending.is_empty():
			var current=pending.pop_back()
			for neighbour in adj[current]:
				if not seen.has(neighbour):seen[neighbour]=true;pending.append(neighbour)
	return {"nodes":adj.size(),"edges":edges.size(),"components":components,"cycles":edges.size()-adj.size()+components}
func shell_has_no_collision(desk:Node)->bool:
	for body in desk.other.environment_container.find_children("*","CollisionObject3D",true,false):
		if body.collision_layer!=0 or body.collision_mask!=0:return false
	return true
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	var desk=find_scene("/timing_machines/pg_workshop.gd")
	check("Mirrored desk bound",desk!=null and desk.ready_for_input and desk.chapter=="mirrored")
	if desk==null:return
	map_origin=desk.global_position-hall.global_basis*Vector3(16.5,0,3.5)
	var start:Array=desk.model.grid.duplicate(true);var seeds:Array=desk.other.maze_generator.growth_points.duplicate(true)
	check("Opening field held with automatic evolution stopped",desk.model.grid_size==31 and desk.held_field==start and not desk.model.auto_evolve and desk.variant==3)
	await snapshot("field-opening",desk.model.to_global(Vector3(0,6,5)),desk.model.global_position,62)
	await snapshot("network-tree",desk.other.to_global(Vector3(-10,9,12)),desk.other.to_global(Vector3(0,2,0)),62)
	observations.graphs=[{"topology":desk.other.topology,"metrics":graph_count(desk.other.maze_generator)}]
	check("Opening tree has six nodes five edges one component",observations.graphs[0].metrics=={"nodes":6,"edges":5,"components":1,"cycles":0})
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	observations.desk_approach={"clear":clear_body(approach),"supported":not floor_at(approach).is_empty()}
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["STEP","HOLD","STENCIL","NETWORK","SURFACE","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.4).timeout;var effect:=false
		match id:
			"STEP":effect=desk.model.grid==next_life(start) and desk.held_field==start and desk.model.generation==1
			"HOLD":
				effect=desk.held_field==desk.model.grid and desk.held_field!=start
				await snapshot("field-held",desk.model.to_global(Vector3(0,6,5)),desk.model.global_position,62)
			"STENCIL":effect=desk.variant==0 and desk.model.grid==quad(desk.held_field)
			"NETWORK":effect=desk.other.topology=="rhizome" and desk.other.maze_generator.growth_points==seeds
			"SURFACE":effect=desk.show_surface and desk.other.environment_container.visible and not desk.graph_view.visible and shell_has_no_collision(desk)
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer button "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
	await driver.teardown();driver.queue_free();await tick()
	var held:Array=desk.held_field.duplicate(true);observations.field={"size":31,"opening_live":lives(start),"held_live":lives(held),"quad_live":lives(desk.model.grid)}
	check("Printed quadrant model matches the actual held museum input",desk.model.grid==quad(held))
	await snapshot("field-quad",desk.model.to_global(Vector3(0,6,5)),desk.model.global_position,62)
	var reflected:Array=desk.model.grid.duplicate(true);desk.act("STEP");await tick()
	check("STEP evolves displayed field then applies quadrant",desk.model.grid==quad(next_life(reflected)) and desk.held_field==held)
	for i in 3:desk.act("STENCIL");await tick()
	check("Stencil none restores held field after live steps",desk.variant==3 and desk.model.grid==held and desk.held_field==held)
	desk.act("STENCIL");await tick();check("Returning to quad reuses unchanged held input",desk.model.grid==quad(held))
	await snapshot("network-surface",desk.other.to_global(Vector3(-10,9,12)),desk.other.to_global(Vector3(0,2,0)),62)
	desk.act("SURFACE");await tick()
	check("Hiding surface does not leave invisible collision",not desk.show_surface and desk.graph_view.visible and shell_has_no_collision(desk))
	await snapshot("network-rhizome",desk.other.to_global(Vector3(-10,9,12)),desk.other.to_global(Vector3(0,2,0)),62)
	var rhizome:Dictionary=graph_count(desk.other.maze_generator);observations.graphs.append({"topology":"rhizome","metrics":rhizome})
	check("Rhizome reports unique edges with additional routes",rhizome==desk.graph_metrics() and rhizome.components==1 and rhizome.cycles>0)
	desk.act("NETWORK");await create_timer(.5).timeout
	var severed:Dictionary=graph_count(desk.other.maze_generator);observations.graphs.append({"topology":"severed","metrics":severed})
	check("Severed policy retains seeds and separates components",desk.other.maze_generator.growth_points==seeds and severed==desk.graph_metrics() and severed.components>1 and shell_has_no_collision(desk))
	await snapshot("network-severed",desk.other.to_global(Vector3(-10,9,12)),desk.other.to_global(Vector3(0,2,0)),62)
	var study=load(DIR+"printed/panels.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,6.5)));root.add_child(study);await tick();await tick()
	var stand:Vector3=map_at(Vector3(8.5,.01,4.5))
	check("Learner bay has clear supported approach",clear_body(stand) and not floor_at(stand).is_empty())
	await snapshot("student-input",study.to_global(Vector3(-.1,1.85,2.7)),study.to_global(Vector3(0,1.65,0)),56)
	var before:Array=study.model.held.duplicate(true)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position;study.point.pick_up(pickup);await tick();await tick();hand.global_position+=Vector3(.2,.1,0);await tick()
	check("Held movement alone does not copy",study.point.is_picked_up() and study.model.result==before)
	study.point.action();await tick();check("Held action copies from retained input",study.model.result==quad(before) and study.model.held==before)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();check("Release parks inherited point",study.point.position.is_equal_approx(Vector3(0,1.1,1.2)))
	origin.queue_free();await tick()
	await snapshot("student-reflection",study.to_global(Vector3(-.1,1.85,2.7)),study.to_global(Vector3(0,1.65,0)),56)
	study.act("MARK");check("Mark leaves held array intact",study.model.held==before and study.model.result[2][4]==0)
	study.act("HOLD");study.act("REFLECT");check("Explicit hold carries marked axis forward",study.model.held[2][4]==0 and study.model.result[2][4]==0)
	study.act("RESET");study.act("REFLECT");await tick()
	await snapshot("above",desk.to_global(Vector3(0,50,-17)),desk.to_global(Vector3(0,0,-20)),70)
	study.queue_free();await tick()
	var edited=load(DIR+"variation/panels.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(8.5,0,6.5)));root.add_child(edited);await tick();edited.act("REFLECT");await tick()
	check("Complete axis edit retains input and fills predicted row",edited.model.held==before and edited.model.result[2]==[0,1,1,1,0] and lives(edited.model.result)==13)
	await snapshot("student-axes",edited.to_global(Vector3(-.1,1.85,2.7)),edited.to_global(Vector3(0,1.65,0)),56)
	edited.queue_free();await tick()
	var route_ok:=true;var supported:=true;var samples:=0;var blocked:Array=[]
	var route:=[Vector3(20,0,3.5),Vector3(28,0,3.5),Vector3(28,0,44.5),Vector3(16.5,0,44.5),Vector3(16.5,0,46.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:Vector3=map_at(p+Vector3.UP*.01)
			var clear:=clear_body(at);route_ok=clear and route_ok;supported=not floor_at(at).is_empty() and supported;samples+=1
			if not clear:blocked.append(xyz(p))
	observations.route={"clear":route_ok,"supported":supported,"samples":samples,"blocked":blocked,"scope":"Side bypass sampled from beside desk, not complete player or portal traversal."}
	if stream!=null:observations.entry=stream.get("_entry");observations.exit=stream.get("_exit")
	observations.scope="Real museum pointer actions, held-field/source agreement, actual graph metrics and disabled shell collisions, complete learner and axis edit, supplied XRTools poses, eleven native captures. No physical headset or independent ghost student. Authored entrance obstruction recorded separately."
