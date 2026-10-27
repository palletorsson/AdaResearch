extends "res://tools/probes/sine_yoke.gd"
## Reuse capture utilities; this is a staging and real no-jump ramp check.
func walk(visitor: CharacterBody3D, targets: Array, label: String) -> void:
	var clear := true
	for target in targets:
		var reached := false
		var distance: float = Vector2(target.x-visitor.position.x,target.z-visitor.position.z).length()
		var budget := int(ceil(distance/1.5*60))+150
		for i in budget:
			var diff: Vector3 = target-visitor.global_position;diff.y = 0
			if diff.length()<.10:reached = true;break
			visitor.drive = Vector2(diff.x,diff.z).normalized()*.5
			await tick()
		visitor.drive = Vector2.ZERO
		if not reached:clear = false;break
	check(label,clear)
	observations[label] = {"position":[visitor.position.x,visitor.position.y-level_y,visitor.position.z],"on_floor":visitor.is_on_floor()}
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	Source.use_main_tower = true
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var building: Node3D = load("res://commons/void/architecture.gd").new()
	building.stream_content = true;scene.add_child(building)
	var draft: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(out.path_join("draft-rooms.json")))
	building.content.data.floors[59] = draft.floors[59];building.content.load_floor(59)
	var shown: Array[int] = [59];building.show_floor_window(shown);level_y = building.spec.levels[59]
	root.size = Vector2i(1440,900)
	var env := WorldEnvironment.new();env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR;env.environment.background_color = Color("30383f")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_energy = .4
	env.environment.tonemap_mode = Environment.TONE_MAPPER_FILMIC;scene.add_child(env)
	var light := DirectionalLight3D.new();light.rotation_degrees = Vector3(-45,-25,0)
	light.light_energy = .8;light.shadow_enabled = true;scene.add_child(light)
	camera = Camera3D.new();camera.fov = 68;scene.add_child(camera)
	var score: Node = load("res://commons/void/lesson_score.gd").new();scene.add_child(score)
	var pickups: Array = []
	for id in ["pickup-still","pickup-turn","pickup-transform","size-1","size-2","size-3","size-4","size-5"]:
		var pickup: Node3D = building.content.exhibits["59/"+id].get_node("Artifact")
		pickup.score_provider = score;pickups.append(pickup)
	await tick(30)
	check("all22 artifacts retained including hand wheel",draft.floors[59].artifacts.size()==22 and building.content.exhibits.has("59/hand-sine-yoke"))
	check("no workbench props remain",draft.floors[59].props.all(func(p):return p.kind!="workbench"))
	check("27 original cube and wp modules built",draft.floors[59].construction.size()==27 and building.content.roots[59].has_node("Construction"))
	check("all eight pickups remain until approached",score.score==0 and pickups.all(func(n):return is_instance_valid(n) and not n.has_been_collected))
	var clock: Node3D = building.content.exhibits["59/clock"].get_node("Artifact")
	var driven: Node3D = building.content.exhibits["59/driven"].get_node("Artifact")
	var clock_low := INF;var driven_low := INF
	for i in 240:
		var clock_box: AABB = clock._cube_mesh.global_transform*clock._cube_mesh.get_aabb()
		clock_low = minf(clock_low,clock_box.position.y-level_y)
		var mesh: MeshInstance3D = driven._cube_instance.get_node("CubeBaseStaticBody3D/CubeBaseMesh")
		var driven_box: AABB = mesh.global_transform*mesh.get_aabb()
		driven_low = minf(driven_low,driven_box.position.y-level_y)
		await tick()
	check("clock clears one metre blocks throughout sampled cycle",clock_low>1.04)
	check("pendulum driven cube clears one metre blocks",driven_low>1.01)
	observations.clearance = {"clock_minimum":clock_low,"driven_minimum":driven_low,"support_top":1.0}
	await photo("01-temporary-block-supports",at(2.0,2.7,7.0),at(-1.4,1.0,3.3))
	await photo("02-pickup-ramp-west",at(-16.4,3.1,8.5),at(-16.0,1.0,4.8))
	camera.fov = 75
	await photo("03-size-pickup-ramp-east",at(16.5,3.5,8.6),at(16.5,1.0,5.0))
	var visitor: CharacterBody3D = load("res://commons/void/walker.gd").new()
	visitor.name = "PlayerRampCheck";scene.add_child(visitor)
	visitor.set_process_unhandled_input(false);visitor.desktop_pointer.enabled = false
	visitor.desktop_pointer.set_process_input(false);visitor.scripted_input = true
	visitor.position = at(-18,.06,7.7);await tick(8)
	await walk(visitor,[at(-18,1,4.5)],"west wedge reaches one metre box top without jump")
	check("west arrival is supported at plinth height",visitor.is_on_floor() and absf(visitor.position.y-level_y-1)<.08)
	await walk(visitor,[at(-16,1,4.5),at(-14,1,4.5)],"shared west box run reaches all three pickups")
	await tick(15)
	check("walking pickup route collects original three cubes",score.score==3)
	visitor.position = at(15.5,.06,8.1);visitor.velocity = Vector3.ZERO;await tick(8)
	await walk(visitor,[at(15.5,1,5)],"east wedge reaches size dock without jump")
	check("east arrival is supported at plinth height",visitor.is_on_floor() and absf(visitor.position.y-level_y-1)<.08)
	await walk(visitor,[at(13.5,1,5),at(18.7,1,5)],"shared size dock reaches all five cubes")
	await tick(15)
	check("size pickup route collects original five sizes",score.score==8)
	visitor.position = at(-3.8,.06,7.3);visitor.velocity = Vector3.ZERO;await tick(8)
	await walk(visitor,[at(-.6,0,7.3),at(-.6,0,4.6),at(1.35,0,4.6),at(1.35,0,1.8),at(-4.6,0,1.8),at(-4.6,0,4.6)],"wheel approach and shared block bypass remain clear")
	var report := {"passed":failed.is_empty(),"checks":checks,"failed":failed,"observations":observations,"scope":"Main floor59 source geometry, original animated cube clearance sample, actual desktop capsule walking wp ramps without jumps, original body-overlap pickup collection with isolated score, and wheel/bay bypass. Physical XR headset and a new scale/rotate room are outside this check."}
	FileAccess.open(out.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("BLOCK_SUPPORTS_RESULT ",checks.size()," failures:",failed)
	quit(0 if failed.is_empty() else 1)
