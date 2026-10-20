extends "res://tools/probes/transformation_encounters.gd"
var map_origin: Vector3
func map_at(p: Vector3) -> Vector3: return map_origin+hall.global_basis*p
func clear_body(at: Vector3) -> bool:
	var shape:=CapsuleShape3D.new(); shape.radius=.28; shape.height=1.7
	var query:=PhysicsShapeQueryParameters3D.new(); query.shape=shape
	query.transform.origin=at+Vector3.UP*.88; query.collision_mask=1|4
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not hits.is_empty(): observations["hits_"+str(at)]=hits.map(func(h): return str(h.collider.get_path()))
	return hits.is_empty()
func collision_for(body: MeshInstance3D) -> ConcavePolygonShape3D:
	for child in body.find_children("*", "CollisionShape3D", true, false):
		if child.shape is ConcavePolygonShape3D: return child.shape
	return null
func same_vertices(a: PackedVector3Array, b: PackedVector3Array) -> bool:
	if a.size()!=b.size(): return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]): return false
	return true
func landing_checks() -> void:
	museum.call("flush_stamps"); await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null: stream.set_process(false); stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D: player.hide(); player.set_process(false); player.set_physics_process(false); player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var source=find_scene("/form_grammar_family/form_grammar_family.gd")
	var canopy=find_scene("/form_grammar_canopy/form_grammar_canopy.gd")
	check("Both authored collections loaded",source!=null and canopy!=null)
	if source==null or canopy==null: return
	map_origin=source.global_position-hall.global_basis*Vector3(10.5,0,11.5)
	var works: Array=[]
	for rec in museum.get("_edit_records"):
		var node=rec.get("node")
		if is_instance_valid(node) and hall.is_ancestor_of(node): works.append(str(rec.get("token","")))
	observations.works=works
	check("Each authored collection appears once alongside museum fixtures",works.count("form_grammar_family")==1 and works.count("form_grammar_canopy")==1)
	check("Six family and three canopy specimens",source.records.size()==6 and canopy.records.size()==3)
	var counts: Array=[]; var rests:=true; var exact_collisions:=true
	for record in source.records:
		counts.append(record.faces)
		var mesh: MeshInstance3D=source.meshes[record.id]
		rests=rests and is_equal_approx(mesh.position.y+float(record.bounds_position[1]),.56)
		var shape=collision_for(mesh)
		exact_collisions=exact_collisions and shape!=null
		if shape!=null: exact_collisions=exact_collisions and same_vertices(shape.get_faces(),mesh.mesh.get_faces())
	check("Six installed counts agree with tutorial",counts==[12,24,36,84,84,444])
	check("All family bodies retain common display height",rests)
	check("All six body colliders use the displayed triangles",exact_collisions)
	var small: MeshInstance3D=canopy.specimens.petals; var large: MeshInstance3D=canopy.specimens.canopy
	check("Canopy reuses the same mesh at exactly four times scale",same_vertices(small.mesh.get_faces(),large.mesh.get_faces()) and large.get_parent().scale.is_equal_approx(Vector3.ONE*4) and small.get_parent().scale.is_equal_approx(Vector3.ONE))
	check("The same support places surface origins at0.9and3.6m",is_equal_approx(canopy.to_local(small.global_position).y,.9) and is_equal_approx(canopy.to_local(large.global_position).y,3.6))
	var open_collision:=true
	for mesh in canopy.specimens.values():
		var shape=collision_for(mesh)
		open_collision=open_collision and shape!=null
		if shape!=null: open_collision=open_collision and shape.backface_collision and same_vertices(shape.get_faces(),mesh.mesh.get_faces())
	check("Open surfaces keep exact two-sided triangle collision",open_collision)
	await snapshot("family",source.to_global(Vector3(8,7,10)),source.to_global(Vector3(0,1,0)),70)
	await snapshot("first-three",source.to_global(Vector3(0,2.7,8)),source.to_global(Vector3(0,1,3.2)),80)
	await snapshot("above",source.to_global(Vector3(0,38,-4)),source.to_global(Vector3(0,0,-9)),73)
	await snapshot("beneath",canopy.to_global(Vector3(1,1.7,-.3)),canopy.to_global(Vector3(0,4,-4)),80)
	var route_ok:=true; var samples:=0
	for route in [[Vector3(10.5,0,2.5),Vector3(2.1,0,4),Vector3(2.1,0,40),Vector3(10.5,0,40),Vector3(10.5,0,41.5)], [Vector3(10.5,0,2.5),Vector3(18.9,0,4),Vector3(18.9,0,40),Vector3(10.5,0,40)]]:
		for j in range(route.size()-1):
			var a: Vector3=route[j]; var b: Vector3=route[j+1]; var steps:=ceili(a.distance_to(b)/.25)
			for k in steps+1:
				var at: Vector3=map_at(a.lerp(b,float(k)/steps)+Vector3.UP*.01)
				route_ok=clear_body(at) and not floor_at(at).is_empty() and route_ok; samples+=1
	check("Supported side routes reach onward opening",route_ok); observations.route_samples=samples
	if stream!=null:
		observations.entry=stream.get("_entry"); observations.exit=stream.get("_exit")
		check("Entry and onward records valid",not observations.entry.is_empty() and not observations.exit.is_empty() and not observations.entry.get("invalid",false) and not observations.exit.get("invalid",false))
	var at:=map_at(Vector3(10.5,.01,21.5)); var approach:=map_at(Vector3(10.5,.01,18.4))
	check("Learner bay and approach have floor and body clearance",clear_body(at) and clear_body(approach) and not floor_at(at).is_empty() and not floor_at(approach).is_empty())
	var study=load("res://doc/book/iterations/2026-10-09-shape-grammar-a-face-continues/printed/family.gd").new()
	study.transform=Transform3D(source.global_basis,map_at(Vector3(10.5,0,21.5))); root.add_child(study)
	await tick(); await tick()
	check("Temporary exact printed study fits reachable bay",study.point.global_position.distance_to(approach+Vector3.UP*1.2)<1.0 and study.global_basis.is_equal_approx(source.global_basis))
	var scenes: Array=[source.meshes.seed,source.meshes.inset,source.meshes.lift,source.meshes.repeat,source.meshes.wider,source.meshes.all]
	var matches:=true
	for i in 6:
		study.show_recipe(i)
		matches=matches and same_vertices(study.body.mesh.get_faces(),scenes[i].mesh.get_faces())
	check("Exact printed program reconstructs all installed family surfaces",matches)
	study.show_recipe(0)
	await snapshot("student-seed",study.to_global(Vector3(2.8,4.4,4.6)),study.to_global(Vector3(0,1.3,.5)),58)
	var origin:=XROrigin3D.new(); root.add_child(origin); var controller:=XRController3D.new(); origin.add_child(controller)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate(); controller.add_child(pickup)
	controller.global_position=study.point.global_position; study.point.pick_up(pickup); await tick(); await tick()
	check("Pickup alone retains seed",study.point.is_picked_up() and study.index==0)
	controller.global_position+=Vector3(.4,.2,0); await tick(); await tick()
	check("Moving point does not silently change recipe",study.index==0)
	study.point.action(); await tick()
	check("Held action advances once to inset",study.index==1 and study.record.faces.size()==24)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO); await tick(); await tick()
	check("Release parks point in museum host",study.point.position.is_equal_approx(Vector3(0,1.15,2.2)) and study.index==1)
	origin.queue_free(); await tick()
	await snapshot("student-inset",study.to_global(Vector3(2.8,4.4,4.6)),study.to_global(Vector3(0,1.3,.5)),58)
	study.show_recipe(2)
	await snapshot("student-extrude",study.to_global(Vector3(2.8,4.4,4.6)),study.to_global(Vector3(0,1.3,.5)),58)
	study.show_recipe(3)
	await snapshot("student-repeat",study.to_global(Vector3(2.8,4.4,4.6)),study.to_global(Vector3(0,1.3,.5)),58)
	await snapshot("student-above",source.to_global(Vector3(0,38,-4)),source.to_global(Vector3(0,0,-9)),73)
	study.queue_free(); await tick()
	var variant=load("res://doc/book/iterations/2026-10-09-shape-grammar-a-face-continues/variation/family.gd").new()
	variant.transform=Transform3D(source.global_basis,map_at(Vector3(10.5,0,21.5))); root.add_child(variant); variant.show_recipe(3)
	check("Complete student edit makes one tip and48 faces inside museum",variant.record.tags.count("growing")==1 and variant.record.faces.size()==48)
	await snapshot("student-one-face",variant.to_global(Vector3(2.8,4.4,4.6)),variant.to_global(Vector3(0,1.3,.5)),58)
	variant.queue_free(); await tick()
	observations.scope="Actual restored Shape Grammars hall. Existing six/three specimens, exact triangle collisions, supported side routes, portal records. Exact printed program and complete student edit run temporarily in clear centre bay; supplied XRTools poses. No headset, independent learner or full portal traversal claim. Production artifacts unchanged."
