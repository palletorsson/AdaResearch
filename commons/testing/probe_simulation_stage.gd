extends SceneTree
const Stage = preload("res://commons/scenes/em/em_simulation_stage.gd")
var failures: Array = []
var checks := 0

func _initialize() -> void:
	_run.call_deferred()

func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok:
		failures.append(message)
	print("[stage] ", "PASS " if ok else "FAIL ", message)

func _run() -> void:
	var map_name := "Trans_Translation"
	var source_only := false
	var shot := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--map="): map_name = arg.trim_prefix("--map=")
		if arg == "--source": source_only = true
		if arg == "--shot": shot = true
	var sequence: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/sequences/transformation.json"))
	for name: String in sequence.sequences.transformation.maps:
		var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % name))
		if not doc.map_info.get("museum",{}).get("simulation",{}).get("staged",false): continue
		var before: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://doc/space/transformation-staging-2026-09-09/before/%s/map_data.json" % name))
		# These maps were deliberately redesigned after the restoration. Their
		# source snapshots stay immutable; dedicated route probes cover the edits.
		if name not in ["Trans_Pre", "Trans_Translation", "Trans_Rotation"]:
			var expected: Dictionary = before.layers.duplicate(true)
			if name == "Trans_Introduction":
				expected.utilities[12][4] = "sc:3:0.5:1:0#seat:deck"
				expected.utilities[17][5] = "rc:90:y:4:-0.05#profile:bridge#seat:deck"
			check(doc.layers == expected, name + " source layers preserved except reviewed crossing configuration")
			check(doc.map_info.dimensions == before.map_info.dimensions, name + " source dimensions preserved")
		var p := Stage.plan(doc)
		check(p.entry.width > 0 and p.exit.width > 0, name + " bridges meet existing edge openings")
		check(p.w == p.source_w + 2*p.pad and p.d == p.source_d + 2*p.pad, name + " padding surrounds all four sides")
	var doc: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/%s/map_data.json" % map_name))
	var p := Stage.plan(doc)
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var environment := WorldEnvironment.new()
	environment.environment = Environment.new()
	environment.environment.background_mode = Environment.BG_COLOR
	environment.environment.background_color = Color(0.12,0.14,0.17)
	environment.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	environment.environment.ambient_light_color = Color.WHITE
	environment.environment.ambient_light_energy = 0.7
	world.add_child(environment)
	var light := DirectionalLight3D.new()
	light.rotation_degrees = Vector3(-55,-25,0)
	light.light_energy = 1.3
	world.add_child(light)
	if not source_only:
		var frame: Dictionary = Stage.build(world,p,0)
		var solid := StaticBody3D.new()
		world.add_child(solid)
		var deck := Stage._material(Color(0.77,0.76,0.72))
		for r: Rect2 in [Rect2(0,0,p.w,p.margin),Rect2(0,p.d-p.margin,p.w,p.margin),Rect2(0,p.margin,p.margin,p.d-2*p.margin),Rect2(p.w-p.margin,p.margin,p.margin,p.d-2*p.margin)]:
			Stage._slab(world,solid,r,deck,"MuseumWalk")
		Stage._box(world,solid,Vector3(p.w/2.0,-p.depth-0.1,p.d/2.0),Vector3(p.w,0.2,p.d),Stage._material(Color(0.055,0.065,0.08)),"PitFloor")
		await physics_frame
		await physics_frame
		var state := world.get_world_3d().direct_space_state
		check(is_zero_approx(_floor(state,Vector3(0.5,0,5))),"outer museum walkway at y=0")
		check(is_zero_approx(_floor(state,Vector3(p.pad-0.5,0,p.pad+2))),"inner apron at y=0")
		check(is_equal_approx(_floor(state,Vector3(p.margin+0.5,0,p.pad+2)),-float(p.depth)),"moat remains a recessed pit")
		var cx: float = p.pad+p.entry.x
		check(is_zero_approx(_floor(state,Vector3(cx,0,p.margin+0.5))),"entry bridge has level collision")
		var ray := PhysicsRayQueryParameters3D.create(Vector3(cx,1,p.margin-0.2),Vector3(cx,1,p.pad-0.2))
		check(state.intersect_ray(ray).is_empty(),"entry crosses the pit and glass opening unobstructed")
		ray = PhysicsRayQueryParameters3D.create(Vector3(p.margin+0.2,1,p.pad+2),Vector3(p.pad+0.2,1,p.pad+2))
		check(not state.intersect_ray(ray).is_empty(),"glass side has physical collision")
		check(not frame.walk_cells.has(Vector2i(p.margin,p.pad+2)),"moat is not advertised as level walking space")
	var grid: Node3D = load("res://commons/grid/grid_system.tscn").instantiate()
	grid.set("bare_world",true)
	grid.set("skip_player_spawn",true)
	grid.set("map_name",map_name)
	grid.position = Vector3(0,-0.5,0) if source_only else Vector3(p.pad+0.5,-0.5,p.pad+0.5)
	var built := [false]
	grid.connect("build_finished",func(): built[0]=true,CONNECT_ONE_SHOT)
	world.add_child(grid)
	for i in range(1200):
		if built[0]: break
		await process_frame
	check(built[0],map_name + " real GridSystem completed")
	check(grid.scale.is_equal_approx(Vector3.ONE),"source grid remains at full scale")
	if shot:
		var camera := Camera3D.new()
		world.add_child(camera)
		camera.current = true
		var width: float = p.source_w if source_only else p.w
		var depth: float = p.source_d if source_only else p.d
		var centre := Vector3(width/2,0,depth/2)
		camera.position = centre+Vector3(-width*0.85,depth*0.9,-depth*0.75)
		camera.look_at(centre)
		camera.fov = 55
		for i in range(20): await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/simulation_stage/%s_%s.png" % [map_name,"source" if source_only else "stage"])
	var report := {"map":map_name,"checks":checks,"failures":failures,"plan":p}
	var f := FileAccess.open("res://ada_run/simulation_stage/%s_checks.json" % map_name,FileAccess.WRITE)
	f.store_string(JSON.stringify(report,"  "))
	print("[stage] ",checks," checks; ",failures.size()," failures")
	quit(0 if failures.is_empty() else 1)

func _floor(state: PhysicsDirectSpaceState3D, p: Vector3) -> float:
	var ray := PhysicsRayQueryParameters3D.create(p+Vector3.UP*0.3,p-Vector3.UP*10)
	var hit := state.intersect_ray(ray)
	return hit.position.y if not hit.is_empty() else -999.0
