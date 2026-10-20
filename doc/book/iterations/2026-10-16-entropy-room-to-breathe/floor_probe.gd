extends "res://tools/probes/transformation_encounters.gd"

func clear_person(p: Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=0.3;shape.height=1.8
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1
	query.transform=Transform3D(Basis(),p+Vector3.UP*0.95)
	return hall.get_world_3d().direct_space_state.intersect_shape(query).is_empty()

func landing_checks() -> void:
	root.size=Vector2i(1600,1000)
	museum.call("flush_stamps");await create_timer(0.5).timeout
	var reference=find_scene("/ordinary_entropies/chair_reference.gd")
	check("full-size entrance chair is installed",reference!=null)
	if reference==null:return
	var chair=reference.get_node("ReferenceChair")
	var near_chair: Array=[]
	for body in hall.find_children("*","CollisionShape3D",true,false):
		if body.shape is BoxShape3D:
			var box: AABB=body.global_transform*AABB(-body.shape.size/2,body.shape.size)
			if box.has_point(chair.to_global(Vector3(0,0.8,-0.19))):
				near_chair.append({"node":str(body.get_path()),"size":xyz(body.shape.size),"position":xyz(body.global_position),"parent":str(body.get_parent().get_meta_list())})
	observations["overlapping_chair_back"]=near_chair
	check("chair back is clear of foreign collision geometry",near_chair.size()==1 and str(near_chair[0].node).contains("/ReferenceChair/"))
	check("chair rests at local floor level",is_zero_approx(chair.position.y))
	check("reference retains its full scale",reference.scale.is_equal_approx(Vector3.ONE) and chair.scale.is_equal_approx(Vector3.ONE))
	var shelf_count:=0
	for child in reference.get_children():
		if child is MeshInstance3D and child.mesh is BoxMesh and is_equal_approx(child.mesh.size.y,0.08):shelf_count+=1
	check("raised shelf is absent",shelf_count==0)
	for offset in [Vector3(0,0,1.3),Vector3(-0.9,0,0.5),Vector3(0.9,0,0.5)]:
		var p: Vector3=reference.to_global(offset)
		var hit:=floor_at(p)
		check("reference approach clear "+str(offset),clear_person(p))
		check("reference shares the approach floor "+str(offset),not hit.is_empty() and absf(hit.position.y-chair.global_position.y)<0.025)
	await snapshot("chair-on-floor",reference.to_global(Vector3(0,1.55,1.6)),reference.to_global(Vector3(0,1.1,0.15)),85)
	var comparisons:=0
	for host in hall.find_children("*","Node3D",true,false):
		if host.get_script()==null or not str(host.get_script().resource_path).ends_with("/ordinary_entropies/comparison.gd"):continue
		if not host.kind in [0,1,2,5]:continue
		comparisons+=1
		check("full-size comparison scene retains scale "+str(host.kind),host.scale.is_equal_approx(Vector3.ONE))
		for i in host.versions.size():
			var version=host.versions[i]
			var hit:=floor_at(version.to_global(Vector3(0,0,1.45)))
			check("comparison %d version %d at floor" % [host.kind,i],not hit.is_empty() and absf(hit.position.y-version.global_position.y)<0.025)
		if host.kind==0:await snapshot("chairs-at-floor-level",host.to_global(Vector3(0,1.7,4.3)),host.to_global(Vector3(0,0.45,0)),95)
	check("all four full-size chair groups found",comparisons==4)
	var guess=find_scene("/ordinary_entropies/one_guess.gd")
	check("miniature guessing tables remain installed",guess!=null and guess.versions.size()==4)
	if guess!=null:
		for i in 4:
			var table=guess.versions[i]
			var approach: Vector3=table.to_global(Vector3(0,0,2.0))
			check("miniature table has clear floor approach "+str(i),clear_person(approach) and not floor_at(approach).is_empty())
			check("miniature chairs stay at reachable table height "+str(i),table.chairs.size()==16 and is_equal_approx(table.chairs[0].position.y,0.75))
	observations["reference_chair_foot_position"]=xyz(chair.global_position)
	observations["scope"]="Actual hall floor and collision checks. Miniature tabletop study retained. Physical headset comfort and reading remain untested."
