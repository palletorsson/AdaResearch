extends "res://tools/probes/void_polyhedra_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	if "--capture" in OS.get_cmdline_user_args():
		await arrive_cube(false)
		game._set_enabled(false)
		var route: Node3D=walkway()
		await photograph("cube-walkway.png",route.global_position+Vector3(-6.5,3.2,2.4),route.global_position+Vector3(.2,1,0),80)
		await photograph("cube-walkway-side.png",route.global_position+Vector3(.1,2.8,4.4),route.global_position+Vector3(0,.9,0),91)
		if game.trial_id.is_empty():
			await photograph("cube-context.png",Vector3(5,-38.2,7.5),Vector3(-8,-40.8,0),83)
		check("native capture saved",FileAccess.file_exists(out.path_join("cube-walkway.png")))
		await cleanup(false)
	else:
		await exercise_cube(false)
		await exercise_cube(true)
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"failed":failed,"scope":"Real Godot physics, desktop movement and synthetic XR. Not physical headset testing."},"\t"))
	quit(0 if failed.is_empty() else 1)

func arrive_cube(use_xr: bool) -> void:
	await start(use_xr)
	var index := 7 if game.trial_id.is_empty() else 1
	game.checkpoint=index
	game.place_player(Vector3(-5.6,-6*index+.06,4))
	await frames(60)
	var deadline := Time.get_ticks_msec()+20000
	while not game.building.content.pending.is_empty() and Time.get_ticks_msec()<deadline:
		await frames(1)
	await frames(10)

func walkway() -> Node3D:
	var key := "7/carried-walkway" if game.trial_id.is_empty() else "1/carried-walkway"
	return game.building.content.exhibits[key].get_node("Artifact")

func exercise_cube(use_xr: bool) -> void:
	await arrive_cube(use_xr)
	var tag := ("Desktop: " if not use_xr else "XR: ")+("Cube: " if game.trial_id.is_empty() else "Transformation: ")
	var route: Node3D=walkway()
	check(tag+"same saved construction recipe",route.get_meta("construction_recipe")=="res://commons/void/cube_walkway.json" and route.get_meta("construction_definition")=="cube_wedge_walkway_v1")
	var cubes := 0
	var wedges := 0
	for member in route.recipe.members:
		var node: Node3D=route.get_node(member.id)
		check(tag+member.id+" is an editor part",route.part_defaults.has(member.id))
		if member.kind=="cube":
			cubes+=1
			check(tag+member.id+" is a true one-metre cube",node.scene_file_path.ends_with("/platform_block.tscn") and node.get_node("Platform").mesh.size==Vector3.ONE)
			var shape: CollisionShape3D=node.find_children("*","CollisionShape3D",true,false)[0]
			check(tag+member.id+" collision matches the visible metre",shape.shape.size==Vector3.ONE and node.has_node("MetreJoints"))
		else:
			wedges+=1
			check(tag+member.id+" keeps the original wp",node.get_node("OriginalWP").scene_file_path=="res://commons/scenes/mapobjects/walkableprism.tscn")
	check(tag+"thirty cubes and six wedges",cubes==30 and wedges==6)
	# Independent ray samples across three lanes: rising surfaces and flat joins.
	for z in [-1,0,1]:
		for sample in [[-4.8,.1],[-4,.5],[-3.1,.95],[-2.8,1],[-1.1,1],[-.8,1.1],[0,1.5],[.8,1.9],[1.2,2],[2.5,2],[3.8,2]]:
			var local := Vector3(float(sample[0]),float(sample[1]),z)
			var query := PhysicsRayQueryParameters3D.create(route.to_global(local+Vector3.UP*.05),route.to_global(local-Vector3.UP*.05),1)
			var hit := game.get_world_3d().direct_space_state.intersect_ray(query)
			check(tag+"support surface "+str(local),not hit.is_empty() and route.is_ancestor_of(hit.collider) and absf(route.to_local(hit.position).y-local.y)<.015)
	var health_before: float=game.health.get_health()
	var deaths_before: int=game.deaths
	for point in route.recipe.walk_route:
		var target := route.to_global(Vector3(point[0],point[1],point[2]))
		var reached: bool=await move_to(target)
		check(tag+"walk to "+str(point),reached)
		if not reached: print("BLOCKED ",game.body.global_position," target ",target)
	var backwards: Array=route.recipe.walk_route.duplicate()
	backwards.reverse()
	for point in backwards:
		check(tag+"return to "+str(point),await move_to(route.to_global(Vector3(point[0],point[1],point[2]))))
	check(tag+"route needs no jump or health loss",is_equal_approx(game.health.get_health(),health_before) and game.deaths==deaths_before)
	# Apply the same per-part edit data that the lab editor saves; check PHYSICS, not only visuals.
	var duplicate: Node3D=load("res://commons/void/cube_walkway.tscn").instantiate()
	game.add_child(duplicate)
	duplicate.position=Vector3(0,-6*(7 if game.trial_id.is_empty() else 1),0)
	duplicate.apply_grid_config({"only_parts":["LandingCube1_1_1"],"parts":{"LandingCube1_1_1":{"position":[6,0,6],"rotation":[0,90,0]}}})
	await frames(3)
	check(tag+"editor copy isolates one named cube",duplicate.get_child_count()==1 and duplicate.get_node("LandingCube1_1_1").position==Vector3(6,0,6))
	var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(duplicate.to_global(Vector3(6,1.5,6)),duplicate.to_global(Vector3(6,.5,6)),1))
	check(tag+"copied cube collision follows its saved pose",not hit.is_empty() and duplicate.is_ancestor_of(hit.collider))
	duplicate.queue_free()
	await cleanup(use_xr)
