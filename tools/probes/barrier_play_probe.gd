extends "res://tools/probes/movable_pivot_final.gd"
## Three authored placements from the real saved floor. Native photographs,
## original prefab geometry/collision, clearances and a real walking route.
var studies: Dictionary = {}

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	DirAccess.make_dir_recursive_absolute(out);DirAccess.make_dir_recursive_absolute(pictures)
	host=ReviewWorld.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new()
	env.background_mode=Environment.BG_COLOR;env.background_color=Color("a9a5b0")
	env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color("ded3df");env.ambient_light_energy=.4
	env.tonemap_mode=Environment.TONE_MAPPER_FILMIC;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-55,-25,0);sun.light_energy=.9;sun.shadow_enabled=true;host.add_child(sun)
	var building: Node3D=load("res://tools/probes/pivot_floor_slice.gd").new();host.add_child(building)
	for id in ["barrier-packed","sun-feather","barrier-scale-line"]:
		studies[id]=building.content.exhibits["15/"+id].get_node("Artifact")
	await ticks(8)
	var packed: Node3D=studies["barrier-packed"];var fan: Node3D=studies["sun-feather"];var line: Node3D=studies["barrier-scale-line"]
	check("three staged studies load through the production registry",packed.layout_mode=="packed" and fan.layout_mode=="circumference" and line.specimens.size()==9)
	check("packed table holds ten same-size blue barriers without control furniture",packed.specimens.size()==10 and not is_instance_valid(packed.controls) and packed.source_family=="barrier")
	var parallel:=true
	for i in 10:
		var part: Node3D=packed.specimens[i]
		parallel=parallel and absf(part.position.z-(i-4.5)*.16)<.0001 and part.basis.is_equal_approx(Basis.IDENTITY) and part.get_node("ScaledPrefab").scale.distance_to(Vector3.ONE*.3)<.0001
	check("ten packed barriers are parallel and closely spaced at 16 cm",parallel)
	var radial:=true
	for i in 10:
		var part: Node3D=fan.specimens[i];var horizontal:=Vector2(part.position.x,part.position.z)
		radial=radial and absf(horizontal.length()-.65)<.0001 and part.basis.is_equal_approx(Basis(Vector3.UP,deg_to_rad(i*36))) and part.get_node("ScaledPrefab").scale.distance_to(Vector3.ONE*.3)<.0001
	check("fan follows one circumference in ten equal 36-degree turns",radial and fan.source_family=="barrier")
	var grew:=true;var support:=true
	for i in line.specimens.size():
		var part: Node3D=line.specimens[i];var barrier: Node3D=part.get_node("BlueDoNotCross")
		grew=grew and barrier.get_script().resource_path.ends_with("/do_not_cross_barrier.gd") and is_equal_approx(barrier.scale.x,line.SCALES[i]) and is_equal_approx(part.position.y,line.BASES[i])
		var query:=PhysicsRayQueryParameters3D.create(part.global_position+Vector3.UP*.04,part.global_position-Vector3.UP*.15,1)
		query.exclude=[barrier.get_node("Barrier/BarrierBody").get_rid()]
		var hit: Dictionary=barrier.get_world_3d().direct_space_state.intersect_ray(query)
		support=support and not hit.is_empty() and absf(hit.position.y-part.global_position.y)<.03
	check("original blue barriers grow from 0.14x to 2.5x as supports descend",grew)
	check("every barrier rests on its table, lower block or actual floor",support)
	check("last three barriers are oversized; largest spans 5.5 metres",line.SCALES[6]>1 and line.SCALES[7]>1 and line.SCALES[8]==2.5 and absf(line._mesh_bounds(line.specimens[8],line).size.x-5.5)<.01)
	# Full projected bounds must stay on solid slab, not just the insertion point.
	var fit:=true;var measured: Array=[]
	for id in studies:
		var node: Node3D=studies[id];var b: AABB=node._mesh_bounds(node,building)
		measured.append({"id":id,"bounds":[b.position.x,b.position.y,b.position.z,b.size.x,b.size.y,b.size.z]})
		fit=fit and b.position.x>=-21 and b.end.x<=21 and b.position.z>=-9 and b.end.z<=9 and b.end.y < -84
		for x in [-10,10]:
			var overlap: bool=b.position.x<x+2.5 and b.end.x>x-2.5 and b.position.z<3 and b.end.z>-3
			fit=fit and not overlap
	check("all full study bounds fit the storey and leave both shafts clear",fit)
	# Physical collision belongs to the original oversized source too.
	var largest: Node3D=line.specimens[8].get_node("BlueDoNotCross")
	var ray:=PhysicsRayQueryParameters3D.create(largest.to_global(Vector3(-1.6,.6,0)),largest.to_global(Vector3(1.6,.6,0)),1)
	var collision: Dictionary=largest.get_world_3d().direct_space_state.intersect_ray(ray)
	check("oversized barrier retains its original matching physical blocker",not collision.is_empty() and collision.collider==largest.get_node("Barrier/BarrierBody"))
	# Walk along the existing slab between the west shaft and the largest signs.
	var visitor: Node3D=load("res://commons/void/walker.gd").new();host.add_child(visitor);visitor.scripted_input=true
	visitor.global_position=Vector3(-13.35,-89.94,-4.4);await ticks(12);visitor.drive=Vector2(0,1)
	var grounded:=true
	for i in 220:
		await ticks(1);grounded=grounded and visitor.is_on_floor()
		if visitor.global_position.z>=4.4:break
	visitor.drive=Vector2.ZERO
	check("B can walk around the growing line on the real slab",grounded and visitor.global_position.z>=4.4 and visitor.global_position.y>-90.1)
	# The circular experiment retains the two existing transformation controls.
	visitor.global_position=fan.to_global(Vector3(-.42,.06,2.2));await ticks(8)
	var before: float=fan.turn_per_copy;var seen:=await drag_grip(visitor,fan.turn_slider._handle,Vector3.DOWN*.05)
	check("circular fan remains adjustable through the real desktop hand",seen and fan.turn_per_copy<before-5)
	fan.set_parameters(36,1,"barrier")
	visitor.global_position=fan.to_global(Vector3(0,.06,2.2));await ticks(8)
	before=fan.scale_ratio;seen=await drag_grip(visitor,fan.scale_slider._handle,Vector3.DOWN*.05)
	check("fan scale slider retains the tabletop recipe",seen and fan.scale_ratio<before-.03)
	fan.set_parameters(36,1,"barrier");visitor.queue_free();await ticks(4)
	# An independently copied large barrier must remain editable without the rest.
	var copy: Node3D=load("res://commons/artifacts/barrier_scale_line/barrier_scale_line.tscn").instantiate();copy.position=Vector3(17,-108,0);copy.rotation.y=PI/2;host.add_child(copy)
	copy.apply_grid_config({"only_parts":["GrowingBarrier09"],"parts":{"GrowingBarrier09":{"position":[0,0,0],"rotation":[0,30,0]}}});await ticks(3)
	check("independent large-barrier copy retains its source and editor pose",copy.part_defaults.size()==1 and copy.get_node("GrowingBarrier09").position==Vector3.ZERO and absf(copy.get_node("GrowingBarrier09").rotation_degrees.y-30)<.01 and copy.get_node("GrowingBarrier09/BlueDoNotCross").scale.x==2.5)
	copy.queue_free();await ticks(4)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	camera=Camera3D.new();camera.fov=52;host.add_child(camera)
	artifact=packed;await shot("01-packed-ten",Vector3(2.3,2.9,3.3),Vector3(0,.75,.05))
	artifact=fan;await shot("02-circular-feather",Vector3(2.3,2.9,3.3),Vector3(0,.75,.05))
	artifact=line;await shot("03-table-to-architecture",Vector3(-4.5,4.7,7),Vector3(0,1.0,-.2))
	await shot("04-grow-down-to-floor",Vector3(-3.5,2.7,-5.8),Vector3(0,.8,-1.0))
	await shot("05-oversized-eye-height",Vector3(-3.5,1.65,3.8),Vector3(0,1.65,2.2))
	await shot("06-west-side",Vector3(4.2,5.0,7.5),Vector3(0,1,-.5))
	# Fresh native editor models for each of the three saved placements.
	var result: Dictionary={"artifacts":{},"failures":failures}
	for id in studies:
		var node: Node3D=studies[id];await node.prepare_editor_preview();await ticks(2)
		var record: Dictionary={}
		for item in building.content.data.floors[15].artifacts:
			if item.id==id:record=item;break
		var data: Dictionary={"artifact":record.artifact,"config":record.config.duplicate(true),"parts":{}}
		for child in node.get_children():
			if child is Node3D and node.part_defaults.has(str(child.name)):
				var part: Dictionary=snapshot(child,"15-"+id+"-"+str(child.name));part["default"]=node.part_defaults[str(child.name)];part["scale"]=[1,1,1];data.parts[str(child.name)]=part
		result.artifacts[id]=data
	FileAccess.open(out.path_join("assembly.json"),FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"failed":failed,"measured":measured,"export_errors":failures,"scope":"Three actual saved floor 15 placements, original prefab meshes and matching large collision, real slab walking and desktop mouse input. Native floor-slice photographs, not full tower/headset acceptance."},"  "))
	host.queue_free();await ticks(8);quit(0 if failed.is_empty() and failures.is_empty() else 1)
