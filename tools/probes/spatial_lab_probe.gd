extends "res://tools/probes/movable_pivot_probe.gd"
## Static arrangement research: actual saved trial, meshes, support, collision,
## independent copy poses and rendered photographs. No interaction acceptance.
const Recipe = preload("res://commons/modular/recipe_area.tscn")
const Grammar = preload("res://commons/modular/builder.gd")
const Inputs = preload("res://commons/modular/lab_input.gd")
const Studies = preload("res://commons/modular/spatial_studies.gd")
const STUDIES := ["lab_domino","lab_thresholds","lab_turning_passage","lab_branching","lab_seeded_field","lab_fractal_assembly","lab_sphere_fractal"]
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
	var building: Node3D=load("res://tools/probes/backrooms_floor_slice.gd" if "--backrooms-main" in OS.get_cmdline_user_args() else "res://commons/void/architecture.gd").new();host.add_child(building)
	await ticks(8)
	camera=Camera3D.new();camera.fov=52;host.add_child(camera)
	for key in building.content.exhibits:
		var exhibit: Node3D=building.content.exhibits[key]
		var item: Node3D=exhibit.get_node("Artifact")
		if item.get_script().resource_path not in ["res://commons/modular/recipe_area.gd","res://commons/modular/sphere_fractal_live.gd"]: continue
		if item.has_method("is_live_study"):await item.prepare_editor_preview()
		if item.recipe=="lab_sphere_fractal":_sphere_source_fidelity(item.bindings)
		if "--backrooms-main" in OS.get_cmdline_user_args():
			var whole: AABB=item.global_transform*item._bounds(item)
			var buffer: AABB=whole.grow(.8)
			for other_key in building.content.exhibits:
				if other_key==key:continue
				var other: Node3D=building.content.exhibits[other_key].get_node("Artifact")
				# Film monitors contain a separate rendered 3D world. Its virtual
				# actors are pixels on the monitor, not obstacles on this floor.
				var other_box: AABB=_floor_bounds(other)
				check("main floor / 0.8m separation from "+str(other_key),not buffer.intersects(other_box))
		var count := 0;var overlap := 0;var boxes: Array[AABB]=[];var members: Array=[]
		for part in item.get_children():
			if item.recipe!="lab_backrooms" and item.recipe not in STUDIES and not str(part.name).begins_with("Copy"): continue
			count+=1
			var source: Node3D=part.get_node("Source")
			var slot := "source"
			if item.recipe=="lab_fractal_assembly":
				for pair in [["_Joint","joint_source"],["_Deck","deck_source"],["_Tip","tip_source"]]:
					if str(part.name).ends_with(pair[0]):slot=pair[1]
			if item.recipe=="lab_sphere_fractal":
				var level: int=str(part.name).count("_")
				if level==int(item.bindings.depth)-1:slot="tip_source"
				elif level>0 and level%2==0:slot="inner_source"
			var token: String=str(item.bindings.get(slot,"do_not_cross_barrier"))
			check(str(key)+" / actual source "+str(part.name),source.get("source_scene")==Inputs.sources()[token].scene and (source.fit_box!=Vector3.ZERO or source.original.scene_file_path==Inputs.sources()[token].scene))
			if source.fit_box!=Vector3.ZERO:
				check(str(key)+" / structural dimensions "+str(part.name),item._bounds(part).size.distance_to(source.fit_box)<.002 and source.get_node_or_null("StructuralCollision")!=null)
			var box: AABB=item._bounds(part);box=part.transform*box
			for other in boxes:
				if box.intersects(other): overlap+=1
			boxes.append(box)
			members.append({"id":str(part.name),"source":token,"position":[part.position.x,part.position.y,part.position.z],"rotation":[part.rotation_degrees.x,part.rotation_degrees.y,part.rotation_degrees.z],"scale":[source.scale.x,source.scale.y,source.scale.z],"bounds":[box.position.x,box.position.y,box.position.z,box.size.x,box.size.y,box.size.z]})
			if source.scale.x>=.5 and token in ["crate","do_not_cross_barrier"]:
				var ray:=PhysicsRayQueryParameters3D.create(source.to_global(Vector3(-2,.34,0)),source.to_global(Vector3(2,.34,0)),1)
				check(str(key)+" / architecture has collision "+str(part.name),not source.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
		var expected: int=9 if item.recipe=="lab_growing" else int(item.bindings.get("count",10))
		if item.recipe=="lab_warehouse":expected=int(item.bindings.columns)*int(item.bindings.rows)-item.bindings.holes.size()
		if item.recipe=="lab_backrooms":expected=int(item.bindings.count)*(9+int(item.bindings.roof))+(int(item.bindings.count)-1)*(3+int(item.bindings.roof))
		if item.recipe in ["lab_thresholds","lab_turning_passage"]:expected=int(item.bindings.count)*4
		if item.recipe=="lab_branching":expected=int(pow(2,int(item.bindings.depth)+1))-1
		if item.recipe=="lab_fractal_assembly":
			var nodes := 0
			for level in int(item.bindings.depth)+1:nodes+=int(pow(int(item.bindings.branches),level))
			expected=nodes*3+int(pow(int(item.bindings.branches),int(item.bindings.depth)))
		if item.recipe=="lab_sphere_fractal":expected=(int(pow(5,int(item.bindings.depth)))-1)/4
		if item.recipe=="lab_seeded_field":
			expected=Studies.expression(Grammar.bind_arguments(load("res://commons/modular/composite.gd").terms()[item.recipe].build,item.bindings)).parts.size()
			check(str(key)+" / random field stays bounded with an anchor",count>=1 and count<=int(item.bindings.columns)*int(item.bindings.rows))
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
		if item.recipe in STUDIES:
			var envelope: AABB=item._bounds(item)
			findings[-1]["below_floor"]=envelope.position.y < -.09
			findings[-1]["above_storey"]=envelope.end.y > 6.0
			findings[-1]["static_study"]=true
			for part in item.get_children():
				var source: Node3D=part.get_node("Source")
				var ray:=PhysicsRayQueryParameters3D.create(source.to_global(Vector3(-source.fit_box.x,0,0)),source.to_global(Vector3(source.fit_box.x,0,0)),1)
				check(str(key)+" / solid fitted member "+str(part.name),not source.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
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
		if item.recipe in STUDIES:
			var envelope: AABB=item._bounds(item)
			var center: Vector3=envelope.get_center()
			var distance: float=maxf(envelope.size.length(),4.0)
			camera.fov=62
			await shot(title,Vector3(center.x+distance*.62,minf(4.8,center.y+distance*.5),center.z+distance*.85),center)
			await shot(title+"-eye-height",Vector3(center.x+distance*.42,1.65,center.z+distance*.7),Vector3(center.x,minf(center.y,1.6),center.z))
		elif item.recipe=="lab_backrooms":
			await _backrooms(item)
			var length: float = (int(item.bindings.count)*3.2+(int(item.bindings.count)-1)*float(item.bindings.corridor))*float(item.bindings.size)
			camera.fov=62
			var eye_x: float=-3.0 if "--backrooms-main" in OS.get_cmdline_user_args() else 3.9
			await shot(title+"-exterior",Vector3(eye_x,4.8,length*.64),Vector3(0,1,0))
			for part in item.get_children():
				if str(part.name).ends_with("Roof"):part.hide()
			await shot(title+"-cutaway",Vector3(eye_x,5,length*.64),Vector3(0,.5,0))
			for part in item.get_children():part.show()
			await shot(title+"-inside",Vector3(.45,1.6,length/2-.5),Vector3(-.25,1.4,-length/2))
		elif item.recipe=="lab_warehouse":
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
		for member in pose.parts:
			if member.source not in tokens:tokens.append(member.source)
	for token in tokens:
		var source: Node3D=Grammar.build({"p":"prefab","token":token,"lab_input":true},{})
		host.add_child(source);await ticks(2);snapshot(source,"source-"+token);source.free()
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"failed":failed,"poses":poses,"findings":findings,"scope":"Actual saved isolated lab; static source geometry, fit, collider presence, independent parts and native photographs. No gameplay input or physical headset test."},"  "))
	print("SPATIAL_LAB_DONE")
	building.free();host.queue_free();await ticks(3);quit(0 if failed.is_empty() and failures.is_empty() else 1)

func _sphere_source_fidelity(config: Dictionary) -> void:
	# Compare against the actual museum script, not a second copy of our formula.
	# Its random coefficients are injected to isolate geometry from RNG differences.
	var rule = load("res://commons/modular/sphere_fractal.gd")
	var settings: Dictionary=config.duplicate(true)
	settings.ratio=.5;settings.spacing=1.5
	var coefficients: Array=rule.coefficients(settings)
	var original = load("res://algorithms/fractals/meshfractal/fractal.gd").new()
	original.depth=int(settings.depth)
	original.branch_mesh=SphereMesh.new();original.leaf_mesh=BoxMesh.new()
	original.position=Vector3(0,float(settings.size),0);original.scale=Vector3.ONE*float(settings.size)
	host.add_child(original);original.set_process(false)
	for phase_value in [0.0,7.0]:
		settings.phase=phase_value
		for level in coefficients.size():
			for i in coefficients[level].size():
				original.parts[level][i].spin_angle=0.0
				original.parts[level][i].spin_velocity=deg_to_rad(coefficients[level][i].speed)
				original.parts[level][i].max_sag_angle=deg_to_rad(coefficients[level][i].sag)
		original.update_fractal(phase_value)
		var expression: Dictionary=rule.expression(settings)
		var index := 0;var positions_match := true;var rotations_match := true
		for level in original.parts:
			for member in level:
				var pose: Dictionary=expression.parts[index];index+=1
				var position := Vector3(pose.at[0],pose.at[1],pose.at[2])
				var rotation := Basis.from_euler(Vector3(pose.rot[0],pose.rot[1],pose.rot[2])*PI/180)
				positions_match=positions_match and position.distance_to(member.world_position)<.00003
				rotations_match=rotations_match and rotation.is_equal_approx(Basis(member.world_rotation))
		check("sphere source / all positions match original at %ss"%phase_value,positions_match)
		check("sphere source / inherited spin and sag match original at %ss"%phase_value,rotations_match)
	original.free()

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

func _backrooms(item: Node3D) -> void:
	var s: float=float(item.bindings.size)
	var opening: float=float(item.bindings.opening)
	var count: int=int(item.bindings.count)
	var pitch: float=3.2+float(item.bindings.corridor)
	var off: float=minf(.55,(3.6-opening)/2-.2)
	await ticks(3)
	var walls_ok := true;var doors_ok := true
	for i in count:
		var z: float=(i-(count-1)/2.0)*pitch
		var door: float=off if i%2==0 else -off
		var from: Vector3=item.to_global(Vector3(door,1.2,z+1.35)*s)
		var to: Vector3=item.to_global(Vector3(door,1.2,z+1.85)*s)
		doors_ok=doors_ok and item.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty()
		from=item.to_global(Vector3(0,1.2,z)*s);to=item.to_global(Vector3(2,1.2,z)*s)
		walls_ok=walls_ok and not item.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from,to,1)).is_empty()
	check("backrooms / openings contain no invisible wall",doors_ok)
	check("backrooms / repeated walls have actual collision",walls_ok)
	# One full-scale reference passage through every offset doorway, using the
	# production walker. Narrow experimental variants keep clearance as a finding.
	if s<.99 or opening<1.2:return
	var player: Node3D=load("res://commons/void/walker.gd").new();player.scripted_input=true;host.add_child(player)
	var length: float=(count*3.2+(count-1)*float(item.bindings.corridor))*s
	var door: float=off if (count-1)%2==0 else -off
	player.global_position=item.to_global(Vector3(door*s,.05,length/2+.5));await ticks(10)
	var route_ok := true
	for i in range(count-1,-1,-1):
		var z: float=(i-(count-1)/2.0)*pitch
		var exit_x: float=off if i%2==0 else -off
		var entry_x: float=off if (i-1)%2==0 else -off
		for waypoint in [Vector3(exit_x,0,z+.8),Vector3(entry_x,0,z-.8),Vector3(entry_x,0,z-1.9)]:
			var target: Vector3=item.to_global(waypoint*s)
			for step in 160:
				var delta: Vector3=target-player.global_position
				if Vector2(delta.x,delta.z).length()<.09:break
				player.drive=Vector2(delta.x,delta.z).normalized()*.7;await ticks(1)
			player.drive=Vector2.ZERO
			route_ok=route_ok and Vector2(target.x-player.global_position.x,target.z-player.global_position.z).length()<.15
	check("backrooms / walker traverses every room and connecting corridor",route_ok)
	player.free();await ticks(2)

func _floor_bounds(node: Node3D) -> AABB:
	var result := AABB();var first := true
	for mesh in node.find_children("*","MeshInstance3D",true,false):
		var ancestor: Node=mesh.get_parent();var embedded := false
		while ancestor!=null and ancestor!=node:
			if ancestor is SubViewport:embedded=true;break
			ancestor=ancestor.get_parent()
		if embedded or mesh.mesh==null or not mesh.is_visible_in_tree():continue
		var box: AABB=mesh.global_transform*mesh.get_aabb()
		result=box if first else result.merge(box);first=false
	return result
