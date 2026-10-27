extends "res://tools/probes/movable_pivot_probe.gd"
## Actual main tower, shared recipe and collisions. No synthetic traversal claim.
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
	host=Node3D.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("bbb6bc");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-50,-35,0);sun.light_energy=1.3;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();building.stream_content=true;host.add_child(building)
	for i in [16,17,18]:building.content.load_floor(i)
	await ticks(25);artifact=building.content.exhibits["16/twisting-tunnel"].get_node("Artifact");await artifact.prepare_editor_preview();await ticks(5)
	check("saved main Rotation floor loads the full-size square recipe",artifact.has_node("Portal01") and artifact.has_node("EntryBridge") and artifact.global_position.is_equal_approx(Vector3(10,-96,0)))
	var envelope:=AABB();var first:=true;var exclude: Array[RID]=[]
	for body in artifact.find_children("*","CollisionObject3D",true,false):exclude.append(body.get_rid())
	for member in artifact.get_children():
		if str(member.name).begins_with("Portal"):
			var bounds: AABB=artifact.global_transform.affine_inverse()*member.global_transform*artifact._bounds(member)
			envelope=bounds if first else envelope.merge(bounds);first=false
	check("full-size native bend stays inside the unchanged 5 by 6 shaft",envelope.position.x> -2.5 and envelope.end.x<2.5 and envelope.position.z> -3 and envelope.end.z<3)
	var pads_clear:=true
	for pad in building.landing_pads:
		if pad.global_position.x>7.5 and pad.global_position.x<12.5 and pad.global_position.y< -95 and pad.global_position.y> -103:pads_clear=false
	check("old catch boards no longer obstruct this descending passage",pads_clear)
	var portals: Array=artifact.get_children().filter(func(n):return str(n.name).begins_with("Portal"))
	var obstructions: Array=[]
	for i in portals.size()-1:
		var query:=PhysicsRayQueryParameters3D.create(portals[i].global_position,portals[i+1].global_position,1);query.exclude=exclude
		var hit: Dictionary=host.get_world_3d().direct_space_state.intersect_ray(query)
		if not hit.is_empty():obstructions.append(str(hit.collider.get_path()))
	check("no existing platform or other exhibit caps the route centreline",obstructions.is_empty())
	var landing_results: Array=[]
	for id in ["EntryBridge","ExitBridge"]:
		var bridge: Node3D=artifact.get_node(id)
		# The outer end of each tongue must overlap the existing slab, not float.
		var end_a: Vector3=bridge.to_global(Vector3(0,.09,-.5));var end_b: Vector3=bridge.to_global(Vector3(0,.09,.5))
		var outer: Vector3=end_a if absf(end_a.x-10)>absf(end_b.x-10) or absf(end_a.z)>absf(end_b.z) else end_b
		var surface:=false
		# Read the actual box half-depth rather than assuming a standard plank.
		var mesh: MeshInstance3D=bridge.find_children("*","MeshInstance3D",true,false)[0]
		var length: float=mesh.mesh.get_aabb().size.z
		for sign in [-1,1]:
			var point: Vector3=bridge.to_global(Vector3(0,.09,sign*(length/2-.15)))
			var query:=PhysicsRayQueryParameters3D.create(point+Vector3.UP*.2,point-Vector3.UP*.5,1);query.exclude=exclude
			var hit: Dictionary=host.get_world_3d().direct_space_state.intersect_ray(query)
			if not hit.is_empty() and (building.floors[16].is_ancestor_of(hit.collider) or building.floors[18].is_ancestor_of(hit.collider) or building.floors[17].is_ancestor_of(hit.collider)):surface=true
		check(id+" overlaps a real tower slab",surface);landing_results.append({"id":id,"slab_supported":surface})
	var record: Dictionary={"artifact":"spatial_recipe","config":artifact.cfg.duplicate(true) if artifact.get("cfg")!=null else {},"parts":{}}
	for item in building.content.data.floors[16].artifacts:
		if item.id=="twisting-tunnel":record.config=item.config.duplicate(true)
	for child in artifact.get_children():
		if child is Node3D and artifact.part_defaults.has(str(child.name)):
			var part: Dictionary=snapshot(child,"16-twisting-tunnel-"+str(child.name));part["default"]=artifact.part_defaults[str(child.name)];part["scale"]=[1,1,1];record.parts[str(child.name)]=part
	FileAccess.open(pictures.path_join("floor16-model.json"),FileAccess.WRITE).store_string(JSON.stringify({"artifact":record,"failures":failures},"  "))
	camera=Camera3D.new();camera.fov=60;host.add_child(camera)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	await shot("03-floor16-entry",Vector3(-1.5,1.7,5),Vector3(-.4,1.0,1.5))
	for i in [16,17,18]:building.floors[i].hide()
	await shot("04-floor16-descent",Vector3(10,3,13),Vector3(0,-5,0))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("floor16-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty() and failures.is_empty(),"checks":checks,"obstructions":obstructions,"landings":landing_results,"scope":"Actual main floors 16–18, native geometry and collision, unchanged shaft envelope, entry/exit slab overlap and exported independent members. Descent photo hides slab visuals. Whole-body passage and headset comfort remain unverified."},"  "))
	print("PORTAL_FLOOR16_DONE ",JSON.stringify(failed));building.free();host.free();quit(0 if failed.is_empty() and failures.is_empty() else 1)
