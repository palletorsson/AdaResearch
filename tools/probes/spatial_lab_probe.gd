extends "res://tools/probes/movable_pivot_probe.gd"
## Static arrangement research: actual saved trial, meshes, support, collision,
## independent copy poses and rendered photographs. No interaction acceptance.
const Recipe = preload("res://commons/modular/recipe_area.tscn")
const Grammar = preload("res://commons/modular/builder.gd")
const Inputs = preload("res://commons/modular/lab_input.gd")
var poses: Array = []
var findings: Array = []

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="): pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(out);DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();root.add_child(host);current_scene=host
	var environment := WorldEnvironment.new();var env := Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a9a5b0")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ded3df");env.ambient_light_energy=.45
	environment.environment=env;host.add_child(environment)
	var sun := DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=1.1;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building)
	await ticks(8)
	camera=Camera3D.new();camera.fov=52;host.add_child(camera)
	for key in building.content.exhibits:
		var exhibit: Node3D=building.content.exhibits[key]
		var item: Node3D=exhibit.get_node("Artifact")
		if item.get_script().resource_path!="res://commons/modular/recipe_area.gd": continue
		var count := 0;var overlap := 0;var boxes: Array[AABB]=[];var members: Array=[]
		for part in item.get_children():
			if not str(part.name).begins_with("Copy"): continue
			count+=1
			var source: Node3D=part.get_node("Source")
			var token: String=str(item.bindings.get("source","do_not_cross_barrier"))
			check(str(key)+" / actual source "+str(part.name),source.get("source_scene")==Inputs.sources()[token].scene and source.original.scene_file_path==Inputs.sources()[token].scene)
			var box: AABB=item._bounds(part);box=part.transform*box
			for other in boxes:
				if box.intersects(other): overlap+=1
			boxes.append(box)
			members.append({"id":str(part.name),"position":[part.position.x,part.position.y,part.position.z],"rotation":[part.rotation_degrees.x,part.rotation_degrees.y,part.rotation_degrees.z],"scale":[source.scale.x,source.scale.y,source.scale.z],"bounds":[box.position.x,box.position.y,box.position.z,box.size.x,box.size.y,box.size.z]})
			if source.scale.x>=.5 and token in ["crate","do_not_cross_barrier"]:
				var ray:=PhysicsRayQueryParameters3D.create(source.to_global(Vector3(-2,.34,0)),source.to_global(Vector3(2,.34,0)),1)
				check(str(key)+" / architecture has collision "+str(part.name),not source.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
		var expected: int=9 if item.recipe=="lab_growing" else int(item.bindings.get("count",10))
		if item.recipe=="lab_warehouse":expected=int(item.bindings.columns)*int(item.bindings.rows)-item.bindings.holes.size()
		check(str(key)+" / stable independently editable copies",count==expected)
		var table: Node3D=item.get_node_or_null("Table");var table_box := AABB()
		if table!=null:table_box=item._bounds(table)
		var overhang := 0
		if table!=null and item.recipe!="lab_growing":
			for box in boxes:
				if box.position.x<table_box.position.x-.005 or box.end.x>table_box.end.x+.005 or box.position.z<table_box.position.z-.005 or box.end.z>table_box.end.z+.005: overhang+=1
		var fit := true
		for part in item.get_children():
			var box: AABB=(building.global_transform.affine_inverse()*part.global_transform)*item._bounds(part)
			fit=fit and box.position.x>=-21 and box.end.x<=21 and box.position.z>=-9 and box.end.z<=9
			for sx in [-10,10]: fit=fit and not (box.position.x<sx+2.5 and box.end.x>sx-2.5 and box.position.z<3 and box.end.z>-3)
		check(str(key)+" / bounds measured for every copy",boxes.size()==count)
		poses.append({"key":key,"recipe":item.recipe,"bindings":item.bindings,"build_ms":item.build_ms,"parts":members})
		findings.append({"key":key,"aabb_overlap_pairs":overlap,"table_overhang_copies":overhang,"slab_and_shafts_clear":fit,"note":"AABB overlaps and slab/shaft overflow are findings to inspect, not silent repacking."})
		# Move one member and independently copy it through the production adapter.
		if not members.is_empty():
			var first_key: String=str(members[0].id)
			var first: Node3D=item.get_node(first_key);var before: Vector3=first.position
			item.apply_grid_config({"parts":{first_key:{"position":[before.x+.2,before.y,before.z],"rotation":[0,17,0]}}})
			check(str(key)+" / editor member move and rotation",first.position.distance_to(before+Vector3(.2,0,0))<.0001 and absf(first.rotation_degrees.y-17)<.001)
			item.apply_grid_config({"parts":{first_key:{"position":[before.x,before.y,before.z],"rotation":members[0].rotation}}})
			var copy: Node3D=Recipe.instantiate();copy.apply_grid_config({"recipe":item.recipe,"bindings":item.bindings,"only_parts":[first_key],"parts":{first_key:{"position":[0,0,0],"rotation":[0,30,0]}}});copy.position=Vector3(0,-30,0);host.add_child(copy)
			check(str(key)+" / isolated copy keeps source geometry",copy.get_child_count()==1 and copy.get_node(first_key).position==Vector3.ZERO and copy.get_node(first_key+"/Source").get_script()==first.get_node("Source").get_script())
			copy.free()
		artifact=item
		var title: String=str(key).replace("/","-")
		if item.recipe=="lab_warehouse":
			if _reference_warehouse(item.bindings):await _warehouse_physics(item)
			camera.fov=65
			await shot(title,Vector3(2.4,4.8,10.5),Vector3(0,.4,0))
			camera.fov=52
			await shot(title+"-gaps",Vector3(-4.2,2.8,4.9),Vector3(-1,.3,.3))
		elif item.recipe=="lab_growing": await shot(title,Vector3(-3.5,2.7,-5.8),Vector3(0,.8,-1))
		else: await shot(title,Vector3(2.3,2.9,3.3),Vector3(0,.75,.05))
	# Export the unscaled original source at its original insertion point for the
	# Three.js recipe builder. No footprint-fit or placeholder is substituted.
	var tokens: Array=[]
	for pose in poses:
		var token: String=str(pose.bindings.get("source","do_not_cross_barrier"))
		if token not in tokens:tokens.append(token)
	for token in tokens:
		var source: Node3D=Grammar.build({"p":"prefab","token":token,"lab_input":true},{})
		host.add_child(source);await ticks(2);snapshot(source,"source-"+token);source.free()
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"failed":failed,"poses":poses,"findings":findings,"scope":"Actual saved isolated lab; static source geometry, fit, collider presence, independent parts and native photographs. No gameplay input or physical headset test."},"  "))
	print("SPATIAL_LAB_DONE")
	building.free();host.queue_free();await ticks(3);quit(0 if failed.is_empty() and failures.is_empty() else 1)

func _warehouse_physics(item: Node3D) -> void:
	var health: Node=load("res://commons/void/health.gd").new();host.add_child(health)
	var player: Node3D=load("res://commons/void/walker.gd").new();player.scripted_input=true;host.add_child(player);player.add_to_group("em_walker")
	var spacing: float=float(item.bindings.spacing);var deck: float=float(item.bindings.deck)
	player.global_position=item.to_global(Vector3(-2*spacing,deck+.03,3*spacing));await ticks(12)
	check("warehouse / standing on a crate stays safe above live bed",player.is_on_floor() and health.get_health()==100)
	var route_ok := true
	for z in [2*spacing,0.0,-spacing,-3*spacing]:
		var target: Vector3=item.to_global(Vector3(-2*spacing,deck,z))
		var delta: Vector3=target-player.global_position
		var duration: float=2.0*4.6/9.8
		player.drive=Vector2(delta.x,delta.z)/(duration*3.0);player.jump_queued=true
		var airborne := false
		for tick in 100:
			await ticks(1)
			if not player.is_on_floor():airborne=true
			if airborne and player.is_on_floor():break
		player.drive=Vector2.ZERO;await ticks(5)
		var landed: bool=player.is_on_floor() and Vector2(player.global_position.x-target.x,player.global_position.z-target.z).length()<.54 and health.get_health()>0
		print("WAREHOUSE_LANDING ",{"target":target,"feet":player.global_position,"charge":health.get_health(),"landed":landed})
		route_ok=route_ok and landed
	check("warehouse / real walker crosses the missing-cell route with jumps",route_ok)
	# An actual missing grid cell exposes the same electrical contact volume.
	var hole: Vector3=item.to_global(Vector3(-2*spacing,0,spacing))
	var query:=PhysicsRayQueryParameters3D.create(hole+Vector3.UP*1.5,hole-Vector3.UP*.1,1)
	query.exclude=[player.get_rid()]
	var opening: Dictionary=player.get_world_3d().direct_space_state.intersect_ray(query)
	check("warehouse / missing cell has no hidden box collider",not opening.is_empty() and absf(opening.position.y-hole.y)<.03)
	player.velocity=Vector3.ZERO;player.global_position=item.to_global(Vector3(-2*spacing,.03,spacing));await ticks(12)
	check("warehouse / exposed gap conducts and depletes charge",health.get_health()==0)
	player.free();health.free();await ticks(2)

func _reference_warehouse(config: Dictionary) -> bool:
	if str(config.get("source",""))!="crate" or int(config.get("columns",0))!=5 or int(config.get("rows",0))!=7:return false
	for pair in [["spacing",1.2],["size",1.5],["deck",1.02]]:
		if not is_equal_approx(float(config.get(pair[0],0)),float(pair[1])):return false
	var keys: Array=[]
	for cell in config.get("holes",[]):keys.append("%d,%d"%[int(cell[0]),int(cell[1])])
	keys.sort()
	return keys==["0,1","0,4","2,3","2,5","3,1","4,2","4,4"]
