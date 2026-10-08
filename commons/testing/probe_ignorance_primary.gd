extends SceneTree
var checks := 0
var failures: Array[String] = []
var pointer: Node3D
func _initialize() -> void: call_deferred("run")
func check(ok: bool,label: String) -> void:
	checks += 1
	if not ok: failures.append(label)
	print(("PASS " if ok else "FAIL ")+label)
func press(button: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer,area,area.global_position)
	XRToolsPointerEvent.released(pointer,area,area.global_position)
func run() -> void:
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	pointer = Node3D.new()
	world.add_child(pointer)
	var counter = load("res://commons/artifacts/budget_of_smoothness/budget_of_smoothness.tscn").instantiate()
	counter.set_meta("config_discovery","1")
	world.add_child(counter)
	var panel: Node3D = counter.get_node("ExperimentPanel")
	check(not counter.costs_visible and not counter.edges_visible,"initial encounter withholds counts and edges")
	check(counter._tags.all(func(tag): return not tag.body.contains("triangles")),"price tags invite a judgment before counting")
	var meshes: Array = counter._spheres.map(func(sphere): return sphere.mesh)
	press(panel.get_node("CostButton"))
	check(counter.costs_visible,"pointer button reveals counts")
	var invoice: Array = []
	for i in 4:
		var mesh: Mesh = meshes[i]
		var arrays: Array = mesh.surface_get_arrays(0)
		var count: int = arrays[Mesh.ARRAY_INDEX].size()/3
		check(count==counter._counts[i].submitted,"price equals actual index triangle count")
		check(counter._tags[i].body.contains("%d mesh triangles"%count),"tag displays measured count")
		check(counter._tags[i].body.contains("%d with area"%counter._counts[i].surface_triangles),"tag distinguishes measurable surface triangles")
		check(counter._counts[i].submitted-counter._counts[i].surface_triangles==2*mesh.radial_segments,"two pole fans account for collapsed triangle entries")
		invoice.append({"segments":mesh.radial_segments,"rings":mesh.rings,"submitted":count,"surface_triangles":counter._counts[i].surface_triangles})
	print("INVOICE ",JSON.stringify(invoice))
	press(panel.get_node("EdgeButton"))
	check(counter._wires.all(func(wire): return wire.visible),"pointer button shows four edge overlays")
	check(counter._spheres.map(func(sphere): return sphere.mesh)==meshes,"revealing edges retains original sphere meshes")
	var before: float = counter._spheres[0].rotation.y
	counter.call("_process",0.25)
	check(counter._spheres[0].rotation.y > before,"overlays follow the rotating sphere parents")
	press(panel.get_node("CostButton"))
	check(not counter.costs_visible and counter.edges_visible,"counts and edges can be examined independently")
	press(panel.get_node("CostButton"))
	# Test the real paired artifact settings, including the formerly indexed shader path.
	for token in ["sphere_low","sphere_mid","sphere_high"]:
		var pair: Array = []
		for shown in [true,false]:
			var sphere = load("res://commons/primitives/godotmeshes/"+token+".tscn").instantiate()
			sphere.set_meta("config_inspection","1")
			sphere.set_meta("config_inspection_edges","1" if shown else "0")
			world.add_child(sphere)
			pair.append(sphere)
			check(sphere.get_node("MeshInspectionEdges").visible==shown,"pair edge visibility matches configuration")
		check(pair[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==pair[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX],"paired spheres have identical vertex positions")
		check(pair[0].mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX]==pair[1].mesh.surface_get_arrays(0)[Mesh.ARRAY_INDEX],"paired spheres have identical triangle indices")
		for sphere in pair: sphere.queue_free()
	await process_frame
	var museum: Node = load("res://commons/scenes/endless_museum.tscn").instantiate()
	museum.set("_studio",true)
	museum.set("_headless",true)
	var row: Dictionary = museum.call("_derive_map_row","Primitives_Ignorance")
	var placed := Node3D.new()
	world.add_child(placed)
	var matches := 0
	for entry: Dictionary in row.artifacts:
		if entry.token != "budget_of_smoothness": continue
		var cell: Array = entry.tile_cell
		check(cell[0]==5 and cell[1]==9,"wide counter occupies the clear central bay")
		check(museum.call("_stamp",placed,"res://commons/artifacts/budget_of_smoothness/budget_of_smoothness.tscn",entry.token,{"x":cell[0],"y":cell[1],"top":0.0},0,1,{},false,0.0,float(entry.rotation),entry.get("config",{})),"configured counter stamps through museum")
		matches += 1
	check(matches==1 and placed.get_children().any(func(n): return n.has_node("ExperimentPanel")),"single room counter has discoverable controls")
	placed.queue_free()
	museum.free()
	await process_frame
	if "--shot" in OS.get_cmdline_user_args():
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.position = Vector3(0,2.10,3.0)
		camera.look_at(Vector3(0,0.9,0))
		camera.current = true
		var env := WorldEnvironment.new()
		env.environment = Environment.new()
		env.environment.background_mode = Environment.BG_COLOR
		env.environment.background_color = Color(0.10,0.12,0.15)
		env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
		env.environment.ambient_light_color = Color.WHITE
		env.environment.ambient_light_energy = 0.9
		world.add_child(env)
		var light := DirectionalLight3D.new()
		light.rotation_degrees = Vector3(-40,-30,0)
		world.add_child(light)
		await create_timer(0.4).timeout
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/ignorance_primary/preview.png")
	FileAccess.open("res://ada_run/ignorance_primary/checks.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"invoice":invoice,"scope":"Pointer events, actual mesh arrays and configured museum counter stamping; full-room/headset legibility and routes unverified."},"  "))
	print("RESULT ",checks," ",failures)
	quit(0 if failures.is_empty() else 1)
