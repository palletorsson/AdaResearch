extends SceneTree
## Copied to the isolated package root by test_museum_runner_package.py.
var checks: Array[Dictionary] = []
var failures: Array[String] = []

func _initialize() -> void:
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	if not passed: failures.append(label)
	print("[runner-package] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	check("package cannot read the documentation sentinel", not FileAccess.file_exists("res://doc/package-sentinel.txt"))
	check("old lesson preload path is unavailable", not ResourceLoader.exists("res://doc/book/iterations/2026-10-06-starter-one-course/lessons/Point_Lines/point_body.gd"))
	var scene := load("res://commons/museum_runner/museum_runner.tscn") as PackedScene
	check("runner scene loads from exported resources", scene != null)
	if scene == null:
		finish()
		return
	# Match staging's typed assignment: a failed script leaves an ordinary Node3D.
	var instance := scene.instantiate()
	# Load after autoloads are ready, not while --script parses this SceneTree.
	var SceneBase: GDScript = load("res://addons/godot-xr-tools/staging/scene_base.gd")
	check("runner retains the XRToolsSceneBase type required by staging", is_instance_of(instance, SceneBase))
	if not is_instance_of(instance, SceneBase):
		instance.free()
		finish()
		return
	var TypeProbe: GDScript = load("res://staging_type_probe.gd")
	var game: Node3D = TypeProbe.assign_scene(instance)
	game.save_path = "user://museum-runner-package-test/best.cfg"
	if FileAccess.file_exists(game.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(game.save_path))
	root.add_child(game)
	current_scene = game
	for i in range(8): await physics_frame
	game.scene_loaded()
	game.scene_visible()
	check("packaged runner reaches READY", game.is_map_ready() and game.state == game.State.READY)
	check("sphere has its inherited geometry", is_equal_approx(game.skin.mesh.radius, 0.14))
	check("runner settles on the real floor", game.runner.is_on_floor())
	check("controller nodes survive packaging", game.has_node("XROrigin3D/LeftHand") and game.has_node("XROrigin3D/RightHand"))
	# Instantiate every chapter, including FaceBody and its relative LineSkin load.
	var Chunk: GDScript = load("res://commons/museum_runner/chunk.gd")
	for phase in range(4):
		var chunk: Node3D = Chunk.new()
		chunk.index = phase * 3
		chunk.position.z = -250
		root.add_child(chunk)
		check("chapter %d builds its hazards and pickups" % phase, chunk.hazards.size() > 0 and chunk.pickups.size() == 3)
		if phase == 1:
			var FaceBody: GDScript = load("res://commons/museum_runner/forms/face_body.gd")
			var faces := chunk.find_children("*","Node3D",true,false).filter(func(n): return n.get_script() == FaceBody)
			check("packaged face builder creates tetrahedra and their edges", faces.size() == 2 and faces[0].surface.mesh != null and faces[0].edges.get_child_count() == 12)
		chunk.free()
	game.get_node("XROrigin3D/RightHand").button_pressed.emit("ax_button")
	for i in range(8): await physics_frame
	check("controller signal starts the packaged runner", game.state == game.State.RUNNING and game.distance > 0)
	var target: Node3D = game.chunks[0].add_hazard("cube",0,-7)
	var hand: XRController3D = game.get_node("XROrigin3D/RightHand")
	hand.global_position = Vector3(0,2,2)
	hand.look_at(target.global_position,Vector3.UP)
	for i in range(2): await physics_frame
	hand.button_pressed.emit("trigger_click")
	for i in range(2): await physics_frame
	check("packaged controller shooting destroys a real target",target.destroyed and target.collision_layer==0 and game.blaster.broken==1)
	hand.button_released.emit("trigger_click")
	game.get_node("XROrigin3D/LeftHand").button_pressed.emit("by_button")
	check("controller signal pauses the packaged runner", game.state == game.State.PAUSED)
	await load("res://runner_xr_input_probe.gd").run(game,check,90)
	await load("res://runner_levels_probe.gd").run(game,check)
	game.queue_free()
	for i in range(2): await process_frame
	await verify_shadow_encounter()
	finish()

func verify_shadow_encounter() -> void:
	# This is the exact class instantiated by Shadow Game world.gd:44.
	var Encounter: GDScript = load("res://commons/shadow_game/encounter.gd")
	check("Shadow Game encounter can instantiate without documentation", Encounter != null and Encounter.can_instantiate())
	if Encounter == null or not Encounter.can_instantiate(): return
	var encounter: Node3D = Encounter.new()
	# Isolated test record; never read or replace a player's saved world.
	encounter.save_path = ""
	root.add_child(encounter)
	for i in range(8): await physics_frame
	check("packaged Shadow Game creates all three pickable bodies", encounter.objects.size() == 3 and encounter.objects.values().all(func(body): return body.has_method("pick_up") and body.has_method("let_go")))
	check("packaged Shadow Game supplies working button scenes", encounter.menu_button.has_node("PushButton/InteractableAreaButton"))
	var point: Node3D = encounter.objects.sphere
	check("Shadow Game uses the same packaged PointBody", point.get_script().get_base_script() == load("res://commons/museum_runner/forms/point_body.gd"))
	encounter.objects.cube.position = Encounter.CUBE_SOCKET
	encounter.objects.cube.on_desktop_drop(null)
	for i in range(3): await physics_frame
	check("packaged cube placement powers the hinge", encounter.powered and encounter.cube_in_place())
	encounter.objects.stick.on_desktop_grab(null)
	encounter.objects.stick.action_pressed.emit(encounter.objects.stick)
	for i in range(160): await physics_frame
	check("packaged held-stick action opens the physical bridge", encounter.bridge_open() and encounter.bridge.get_child_count() > 0)
	point.on_desktop_grab(null)
	for i in range(6):
		point.position = Vector3(0, 1.12, 3.7 - i * 0.3)
		await physics_frame
	check("packaged point movement leaves visible line segments", encounter.samples.size() >= 5 and encounter.trace_root.get_child_count() >= 4)
	point.position = Encounter.POINT_SOCKET
	point.on_desktop_drop(null)
	for i in range(3): await physics_frame
	check("packaged crossing can complete", encounter.completed)
	encounter.queue_free()
	for i in range(3): await process_frame

func finish() -> void:
	var destination := "user://runner-package-checks.json"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--report="): destination = arg.trim_prefix("--report=")
	var file := FileAccess.open(destination, FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": failures.is_empty(), "checks": checks, "failures": failures}, "\t"))
	file.close()
	print("[runner-package] ", checks.size() - failures.size(), "/", checks.size(), " passed")
	quit(0 if failures.is_empty() else 1)
