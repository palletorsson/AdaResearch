extends "res://tools/probes/movable_pivot_probe.gd"
## Saved main floor, native placement survey and actual desktop-body traversal.
var saved := false
var survey: Array = []

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--pictures="):pictures=arg.trim_prefix("--pictures=")
		if arg=="--saved":saved=true
	DirAccess.make_dir_recursive_absolute(pictures)
	load("res://commons/void/room_source.gd").use_main_tower=true
	host=Node3D.new();root.add_child(host);current_scene=host
	var world:=WorldEnvironment.new();var env:=Environment.new();env.background_mode=Environment.BG_COLOR;env.background_color=Color("c4c0c5");env.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.ambient_light_color=Color.WHITE;env.ambient_light_energy=.7;world.environment=env;host.add_child(world)
	var sun:=DirectionalLight3D.new();sun.rotation_degrees=Vector3(-45,-25,0);sun.light_energy=1.3;host.add_child(sun)
	var building: Node3D=load("res://commons/void/architecture.gd").new();building.stream_content=true;host.add_child(building);building.content.load_floor(16);await ticks(15)
	for exhibit in building.content.exhibits.values():
		var item: Node=exhibit.get_node("Artifact")
		if item.get_script()!=null and item.get_script().resource_path=="res://commons/modular/recipe_area.gd":await item.prepare_editor_preview()
	var visible_floors: Array[int]=[16];building.show_floor_window(visible_floors);await ticks(5)
	if saved:artifact=building.content.exhibits["16/full-floor-portals"].get_node("Artifact")
	else:
		artifact=load("res://commons/modular/recipe_area.tscn").instantiate();artifact.apply_grid_config({"recipe":"transformation_variant","recipe_document":"res://commons/void/trials/transformation_adef1d2ca3/recipe.json"});artifact.position=Vector3(200,-96,0);host.add_child(artifact)
	await artifact.prepare_editor_preview();await ticks(5)
	check("all seven saved portal frames remain separate editable members",artifact.part_defaults.size()==7 and artifact.has_node("Copy07"))
	var bounds: AABB=artifact._bounds(artifact)
	if not saved:
		var shape:=BoxShape3D.new();shape.size=bounds.size-Vector3(.06,.14,.06)
		for x in [-17.0,-16.0,-15.0,-14.0,14.0,15.0,16.0,17.0]:
			for z in [-5.0,-4.0,-3.0,-2.0,-1.0,0.0,1.0,2.0,3.0,4.0,5.0]:
				var at:=Vector3(x,-96,z);var supported:=true
				for dx in [bounds.position.x,bounds.end.x]:
					for dz in [bounds.position.z,bounds.end.z]:
						var p:=at+Vector3(dx,0,dz);var hit: Dictionary=host.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p+Vector3.UP*.12,p-Vector3.UP*.5,1))
						if hit.is_empty() or not building.floors[16].is_ancestor_of(hit.collider):supported=false
				if not supported:continue
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform=Transform3D(Basis.IDENTITY,at+bounds.get_center());q.collision_mask=1;q.margin=.005
				var hits: Array=host.get_world_3d().direct_space_state.intersect_shape(q,32);var paths: Array=[]
				for hit in hits:
					var path: String=str(hit.collider.get_path());if path not in paths:paths.append(path)
				survey.append({"position":[x,z],"obstructions":paths,"count":paths.size()})
		survey.sort_custom(func(a,b):return a.count<b.count)
		FileAccess.open(pictures.path_join("survey.json"),FileAccess.WRITE).store_string(JSON.stringify(survey,"  "))
		print("PORTAL_STAGE_SURVEY ",JSON.stringify(survey.slice(0,12)))
	else:
		check("placement retains the saved full-floor dimensions",bounds.size.distance_to(Vector3(5.0944047,5.5,4.9730983))<.002)
		var walker: CharacterBody3D=load("res://commons/void/walker.gd").new();walker.scripted_input=true;host.add_child(walker);walker.desktop_pointer.process_mode=Node.PROCESS_MODE_DISABLED;walker.set_process_unhandled_input(false);Input.mouse_mode=Input.MOUSE_MODE_VISIBLE
		var first: Node3D=artifact.get_node("Copy01");var last: Node3D=artifact.get_node("Copy07")
		var start: Vector3=artifact.to_global(Vector3(.15,.08,bounds.position.z-1.3));walker.global_position=start;await ticks(20)
		check("entry spawn is grounded on the existing floor",walker.is_on_floor() and absf(walker.global_position.y+96)<.1)
		var trace: Array=[];var contacts: Array=[];var target: Vector3=artifact.to_global(Vector3(.15,0,bounds.end.z+.8));var crossed:=false
		for i in 540:
			var direction: Vector3=target-walker.global_position;walker.drive=Vector2(direction.x,direction.z).limit_length()
			if walker.is_on_floor() and i%24==0:walker.jump_queued=true
			for j in walker.get_slide_collision_count():
				var hit: KinematicCollision3D=walker.get_slide_collision(j)
				if artifact.is_ancestor_of(hit.get_collider()):
					var name: String=str(hit.get_collider().get_path());if name not in contacts:contacts.append(name)
			if i%15==0:trace.append([walker.global_position.x,walker.global_position.y+96,walker.global_position.z])
			if artifact.to_local(walker.global_position).z>bounds.end.z+.25:crossed=true;break
			await ticks(1)
		walker.drive=Vector2.ZERO
		check("production desktop body crosses the portal sequence with walk and jump",crossed)
		check("the walker contacts actual native portal collision",not contacts.is_empty())
		FileAccess.open(pictures.path_join("walk.json"),FileAccess.WRITE).store_string(JSON.stringify({"crossed":crossed,"start":[start.x,start.y+96,start.z],"end":[walker.global_position.x,walker.global_position.y+96,walker.global_position.z],"contacts":contacts,"trace":trace},"  "))
		walker.queue_free();await ticks(4)
		camera=Camera3D.new();camera.fov=60;host.add_child(camera)
		for layer in root.find_children("*","CanvasLayer",true,false):layer.hide()
		await shot("floor16-portal",Vector3(.1,1.65,bounds.position.z-2.5),Vector3(0,2,bounds.get_center().z))
	var failed: Array=checks.filter(func(c):return not c.passed)
	FileAccess.open(pictures.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"passed":failed.is_empty(),"checks":checks,"scope":"Saved Rotation floor 16 and actual static recipe members. Production desktop CharacterBody walk/jump through Jolt collision; no physical headset acceptance."},"  "))
	building.queue_free();if not saved:artifact.queue_free()
	await ticks(8);host.queue_free();await ticks(5);print("TRANSFORMATION_PORTAL_STAGE_DONE ",JSON.stringify(failed));quit(0 if failed.is_empty() else 1)
