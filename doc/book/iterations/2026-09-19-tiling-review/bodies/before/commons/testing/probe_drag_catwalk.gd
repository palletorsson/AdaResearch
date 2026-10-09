extends SceneTree
const Catwalk := preload("res://commons/artifacts/drag_catwalk/drag_catwalk.gd")
const Looks := preload("res://commons/player/super_drag_outfit.gd")
var failures: Array[String] = []
var checks: int = 0

func _initialize() -> void:
	call_deferred("run")

func check(ok: bool, label: String) -> void:
	checks += 1
	if not ok:
		failures.append(label)
		push_error("CATWALK: " + label)

func press(button: Node3D, pointer: Node3D) -> void:
	var area: Node3D = button.get_node("InteractableAreaButton")
	XRToolsPointerEvent.pressed(pointer, area, area.global_position)
	XRToolsPointerEvent.released(pointer, area, area.global_position)

func run() -> void:
	root.size = Vector2i(1400, 1000)
	var world := Node3D.new()
	root.add_child(world)
	current_scene = world
	var camera := Camera3D.new()
	world.add_child(camera)
	camera.position = Vector3(8, 5.2, 17)
	camera.look_at(Vector3(0, 1.1, 5.8))
	camera.current = true
	camera.set_cull_mask_value(19, false)
	var env := WorldEnvironment.new()
	env.environment = Environment.new()
	env.environment.background_mode = Environment.BG_COLOR
	env.environment.background_color = Color("181223")
	env.environment.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.environment.ambient_light_color = Color("cabddf")
	env.environment.ambient_light_energy = 0.65
	world.add_child(env)
	var key := DirectionalLight3D.new()
	key.rotation_degrees = Vector3(-45, -35, 0)
	key.light_energy = 1.0
	world.add_child(key)
	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(20, 24)
	floor_mesh.mesh = plane
	floor_mesh.position.z = 6
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("504256")
	floor_mesh.material_override = mat
	world.add_child(floor_mesh)
	var walk := Catwalk.new()
	walk.viewer_path = camera.get_path()
	world.add_child(walk)
	walk.set_physics_process(false)
	for frame in range(8):
		await process_frame
	check(walk.agents.size() == 4, "four walking agents")
	var distinct: Dictionary = {}
	for agent in walk.agents:
		distinct[agent.outfit.look_id] = true
		check(agent.outfit.headpiece.get_child(0).layers == 1, "other heads visible while player's head layer is hidden")
	check(distinct.size() == 4, "all four player outfits worn")
	check(get_nodes_in_group("costume_wardrobes").is_empty(), "performers create no player wardrobe or save state")
	var closed_a := walk.route(0.0)
	var closed_b := walk.route(Catwalk.PATH_LENGTH)
	check(closed_a.position.is_equal_approx(closed_b.position), "closed route returns exactly to start")
	for seam in [Catwalk.STRAIGHT, Catwalk.STRAIGHT + PI * Catwalk.RADIUS, 2 * Catwalk.STRAIGHT + PI * Catwalk.RADIUS, Catwalk.PATH_LENGTH]:
		var a := walk.route(seam - 0.0001)
		var b := walk.route(seam + 0.0001)
		check(a.position.distance_to(b.position) < 0.001 and a.direction.dot(b.direction) > 0.999, "continuous route position and tangent")
	var minimum_spacing := 100.0
	var stayed_on_stage := true
	var saw_pose := false
	var saw_walk := false
	for tick in range(7200):
		walk.advance(1.0 / 60.0)
		for i in range(walk.agents.size()):
			var a: Node3D = walk.agents[i]
			stayed_on_stage = stayed_on_stage and absf(a.position.x) <= 1.0 and a.position.z > 1.0 and a.position.z < 10.7
			saw_walk = saw_walk or a.walking
			saw_pose = saw_pose or bool(walk.sample_clock(walk.clocks[i]).posing)
			for j in range(i + 1, walk.agents.size()):
				minimum_spacing = minf(minimum_spacing, a.position.distance_to(walk.agents[j].position))
	check(stayed_on_stage, "two minutes of travel stay inside runway")
	check(minimum_spacing >= 1.20, "agents retain passing separation")
	check(saw_pose and saw_walk, "route includes walking and posed stops")
	for distance in walk.travelled:
		check(distance > 40, "each performer completes repeated circuits")
	var before_hold: Array = walk.clocks.duplicate()
	press(walk.buttons[0], camera)
	walk.advance(1.0)
	check(walk.clocks == before_hold and not walk.running, "pointer control holds every agent's clock")
	press(walk.buttons[1], camera)
	check(walk.agents[0].outfit.look_id == Looks.LOOKS[1], "pointer control swaps worn looks")
	check(walk.clocks == before_hold, "dressing agents preserves their route state")
	press(walk.buttons[0], camera)
	# Put a visitor in front of a moving performer, then move out of the way.
	walk.clocks[0] = 2.0
	walk.agents[0].position = walk.sample_clock(2.0).position
	camera.global_position = walk.to_global(walk.agents[0].position + Vector3.UP * 1.65)
	walk.advance(0.05)
	check(is_equal_approx(walk.clocks[0], 2.0) and walk.agents[0].yielding, "performer yields to visitor")
	camera.position = Vector3(8, 5.2, 17)
	walk.advance(0.05)
	check(walk.clocks[0] > 2.0 and not walk.agents[0].yielding, "performer resumes when visitor clears path")
	var moving_agent: Node3D = walk.agents[0]
	moving_agent.animate(0.1, true)
	var foot_a: Vector3 = moving_agent.feet[0].node.position
	moving_agent.animate(0.6, true)
	check(foot_a.distance_to(moving_agent.feet[0].node.position) > 0.05, "feet step rather than glide as a rigid model")
	var hand_a: Vector3 = moving_agent.left.position
	moving_agent.animate(0.9, true)
	check(hand_a.distance_to(moving_agent.left.position) > 0.04, "hands swing with gait")
	if "--shots" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute("res://ada_run/drag_catwalk_shots")
		# Restore one of each look for the review picture.
		for i in range(4):
			walk.agents[i].set_look(i)
			walk.clocks[i] = walk.period() * i / 4.0 + 1.5
		walk.advance(0.01)
		camera.look_at(Vector3(0, 1.0, 5.8))
		for frame in range(6):
			await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/drag_catwalk_shots/runway.png")
		camera.position = Vector3(2.7, 1.7, 13.2)
		camera.look_at(Vector3(0, 1.1, 5.8))
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://ada_run/drag_catwalk_shots/along_runway.png")
	var report := {"checks": checks, "failures": failures, "minimum_agent_spacing_m": minimum_spacing, "simulated_seconds": 120, "headset_tested": false}
	var file := FileAccess.open("res://ada_run/probe_drag_catwalk.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CATWALK_RESULT ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
