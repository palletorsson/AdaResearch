extends "res://tools/probes/movable_pivot_probe.gd"
## The preserved studies in the actual streamed Rotation floor, without changing its route.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(pictures);DirAccess.make_dir_recursive_absolute(out)
	host=Node3D.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("b6b3ba");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.2;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();building.stream_content=true;host.add_child(building);building.content.load_floor(16);await ticks(25)
	var ids: Array=["archive-s-cutaway","archive-s-boolean","archive-portal-fall","archive-portal-square"]
	var models: Dictionary={};var exclude: Array[RID]=[]
	for id in ids:
		var model: Node3D=building.content.exhibits["16/"+id].get_node("Artifact");await model.prepare_editor_preview();models[id]=model
		for body in model.find_children("*","CollisionObject3D",true,false):exclude.append(body.get_rid())
	await ticks(5)
	var data: Dictionary={};var supports:=true;var clear:=true;var shapes: Array=[];var collisions: Array=[]
	for id in ids:
		var model: Node3D=models[id]
		check(str(id)+" retains independently editable members",model.part_defaults.size()>5)
		var board: AABB=model.get_node("StudyStand").global_transform*model._bounds(model.get_node("StudyStand"));shapes.append(board)
		check(str(id)+" board stays outside the shaft opening",board.end.z< -2.5 or board.position.z>2.5)
		for x in [-.8,.8]:
			for z in [-.35,.35]:
				var point: Vector3=model.to_global(Vector3(x,0,z));var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.12,point-Vector3.UP*.3,1);query.exclude=exclude
				var hit: Dictionary=host.get_world_3d().direct_space_state.intersect_ray(query)
				if hit.is_empty() or not building.floors[16].is_ancestor_of(hit.collider):supports=false
		var volume:=BoxShape3D.new();volume.size=Vector3(2.44,2.25,1.215)
		var query:=PhysicsShapeQueryParameters3D.new();query.shape=volume;query.transform.origin=model.to_global(Vector3(0,1.2,0));query.exclude=exclude;query.collision_mask=1
		var hits: Array=host.get_world_3d().direct_space_state.intersect_shape(query,8)
		if not hits.is_empty():
			clear=false
			for hit in hits:collisions.append(str(id)+" / "+str(hit.collider.get_path()))
		var record: Dictionary={"artifact":"spatial_recipe","config":{},"parts":{}}
		for item in building.content.data.floors[16].artifacts:
			if item.id==id:record.config=item.config.duplicate(true)
		for child in model.get_children():
			if child is Node3D and model.part_defaults.has(str(child.name)):
				var part: Dictionary=snapshot(child,"16-"+id+"-"+str(child.name));part["default"]=model.part_defaults[str(child.name)];part["scale"]=[1,1,1];record.parts[str(child.name)]=part
		data[id]=record
	check("all sixteen model supports land on the actual Rotation slab",supports)
	check("model display volumes are clear of existing solid fixtures",clear)
	var disjoint:=true
	for i in shapes.size():
		for j in range(i+1,shapes.size()):
			if shapes[i].intersects(shapes[j]):disjoint=false
	check("the four study boards remain separate",disjoint)
	artifact=models[ids[0]];camera=Camera3D.new();camera.fov=58;host.add_child(camera)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	await shot("03-floor-16-studies",Vector3(7,3.5,3),Vector3(1.8,1.1,0))
	artifact=models["archive-portal-fall"]
	await shot("04-models-beside-tunnel",Vector3(4.2,3.5,-4.5),Vector3(-1.65,1.1,0))
	artifact=models[ids[0]]
	await shot("05-floor-16-archive",Vector3(12,5.2,9),Vector3(4.8,1.1,4.2))
	FileAccess.open(out.path_join("archive-models.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifacts":data,"failures":failures},"  "))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("archive-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"collisions":collisions,"export_errors":failures,"scope":"Preserved model placement on actual Rotation floor16: member construction, slab support, shaft separation, display volume clearance and real exports. Existing floor mechanics and physical headset were not retested."},"  "))
	print("PORTAL_ARCHIVE_DONE ",JSON.stringify(failed));building.free();host.free();quit(0 if failed.is_empty() and failures.is_empty() else 1)
