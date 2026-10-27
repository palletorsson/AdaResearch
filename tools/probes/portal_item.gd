extends "res://tools/probes/movable_pivot_probe.gd"
## Generic saved-item model check. Deliberate gaps are findings, not gameplay acceptance.
func run() -> void:
	var count:=24
	var full:=false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
		if arg.begins_with("--count="):count=int(arg.trim_prefix("--count="))
		if arg=="--full-size":full=true
	DirAccess.make_dir_recursive_absolute(pictures)
	host=Node3D.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("b9b4bc");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.8;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-35,0);sun.light_energy=1.2;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();host.add_child(building);await ticks(8)
	artifact=building.content.exhibits["1/portal-item"].get_node("Artifact");await artifact.prepare_editor_preview();await ticks(4)
	check("local saved recipe produces all editable item members",artifact.part_defaults.size()==count+(2 if full else 5))
	var square:=true;var ready:=true;var sources: Array=[]
	for i in count:
		var source: Node3D=artifact.get_node("Portal%02d/Source"%(i+1));sources.append(source)
		var size: Vector3=source.get_meta("outer_size");square=square and absf(size.x-size.y)<.00001;ready=ready and source.ready_mesh
	check("every portal has equal outer width and height",square)
	check("every actual Boolean piece bakes successfully",ready)
	check("source element carries its pink orientation marker",artifact.has_node(("Portal01" if full else "OneElement")+"/Source/OrientationCorner"))
	var caps:=0
	for i in count-1:
		if not host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(sources[i].global_position,sources[i+1].global_position,1)).is_empty():caps+=1
	var findings: Dictionary={"centreline_caps":caps,"upright_start":sources[0].global_basis.y.normalized().dot(Vector3.UP),"inverted_end":sources[-1].global_basis.y.normalized().dot(Vector3.UP)}
	camera=Camera3D.new();camera.fov=45;camera.near=.01;host.add_child(camera)
	for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
	if full:
		var envelope:=AABB();var first:=true
		for source in sources:
			var bounds: AABB=artifact.global_transform.affine_inverse()*source.global_transform*artifact._bounds(source)
			envelope=bounds if first else envelope.merge(bounds);first=false
		check("actual native portal geometry stays inside the existing 5 by 6 shaft",envelope.position.x> -2.5 and envelope.end.x<2.5 and envelope.position.z> -3 and envelope.end.z<3)
		findings["portal_envelope"]=[envelope.position.x,envelope.position.y,envelope.position.z,envelope.size.x,envelope.size.y,envelope.size.z]
		for id in ["EntryBridge","ExitBridge"]:
			var bridge: Node3D=artifact.get_node(id);var query:=PhysicsRayQueryParameters3D.create(bridge.global_position+Vector3.UP,bridge.global_position-Vector3.UP,1)
			var hit: Dictionary=host.get_world_3d().direct_space_state.intersect_ray(query)
			check(id+" has real supporting collision",not hit.is_empty() and bridge.is_ancestor_of(hit.collider))
		# Hide only slab visuals for the tall cutaway picture; all collisions stay.
		for floor in building.floors:floor.hide()
		await shot("01-square-item",Vector3(10,2,13),Vector3(0,-5,0))
		await shot("02-square-unit",Vector3(-4,2,5),Vector3(0,1,0))
	else:
		await shot("01-square-item",Vector3(2.4,2.7,3.3),Vector3(-.05,1.3,0))
		await shot("02-square-unit",Vector3(-.1,1.2,1.1),Vector3(-.75,.84,.35))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"findings":findings,"metrics":{"parts":artifact.part_defaults},"scope":"Saved square source item, actual Boolean model, centreline findings and exported editable pieces. No full-size body-clearance, physics gameplay or headset acceptance."},"  "))
	print("PORTAL_ITEM_DONE ",JSON.stringify(failed));building.free();host.free();quit(0 if failed.is_empty() else 1)
