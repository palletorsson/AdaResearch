extends SceneTree
var stage: Node3D
var menu: Node3D
var route := "void"
var out := "user://"
var checks: Array[Dictionary] = []
var finished := false
var reveals := 0
const ROUTES := {
	"trial": ["VoidButton", "res://commons/void/trials/transformation/trial.tscn"],
	"void": ["VoidButton", "res://commons/void/void.tscn"],
	"runner": ["MuseumRunnerButton", "res://commons/museum_runner/museum_runner.tscn"],
	"shadow": ["ShadowGameButton", "res://commons/shadow_game/shadow_game.tscn"],
	"ladder": ["BiomeLadderButton", "res://commons/hazards/biome_ladder/ladder_world.tscn"],
	"arena": ["HeadArenaButton", "res://commons/hazards/catalyst_counterpart/biome_arena.tscn"],
	"museum": ["NewGameButton", "res://commons/scenes/endless_museum_staged.tscn"],
	"sequences": ["LoadGameButton", "res://commons/scenes/endless_museum_staged.tscn"],
	"maps": ["BrowseButton", "res://commons/scenes/grid.tscn"]
}

func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--route="): route = arg.trim_prefix("--route=")
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name": label, "passed": passed})
	print("[menu-route] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	check("Test uses separate save data", OS.get_user_data_dir().contains("Ada Menu Integration Test"))
	if not checks.back().passed: await finish(); return
	if route == "boot":
		await create_timer(2.0).timeout
		await finish()
		return
	create_timer(125).timeout.connect(func(): check("Route completes before timeout", false); finish())
	stage = load("res://commons/scenes/vr_staging.tscn").instantiate()
	if route == "menu_cold":
		stage._preload_started = true
		stage._museum_preload_started = true
	if route == "menu_no_csg":
		for shape in stage.find_children("*", "CSGShape3D", true, false):
			if is_instance_valid(shape) and not shape.get_parent() is CSGShape3D:
				shape.free()
	root.add_child(stage)
	current_scene = stage
	stage.scene_visible.connect(func(_scene, _data): reveals += 1)
	menu = stage.get_node("MainMenu3D")
	await create_timer(1.0).timeout
	check("Desktop staging menu is visible with mouse pointer", menu.visible and menu.has_node("DesktopMenuPointer") and Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	await capture("menu")
	if route.begins_with("menu_"):
		await finish()
		return
	await click_node(menu.get_node("Buttons/" + ROUTES[route][0]))
	if route == "void":
		await create_timer(.3).timeout
		check("The Void opens its saved spine picker before loading", menu.has_node("VoidTrialPicker") and stage.current_scene == null)
		if not menu.has_node("VoidTrialPicker"): await finish(); return
		await click_picker("Transformation")
		await capture("selector")
		await click_picker("014 /")
	if route == "trial":
		# Separate drafts are available inside the Void picker on desktop.
		await create_timer(.3).timeout
		check("Trial picker is separate from the tower",menu.has_node("VoidTrialPicker") and not menu.get_node("Buttons").visible)
		if not menu.has_node("VoidTrialPicker"): await finish(); return
		await click_picker("Separate trials")
		await click_picker("Transformation", true)
	if route == "sequences":
		await create_timer(0.6).timeout
		check("Sequences opens its panel", is_instance_valid(menu.sequence_picker_instance))
		if not is_instance_valid(menu.sequence_picker_instance): await finish(); return
		# Scroll to a specific chapter, then click its real embedded Play button.
		var surface: Node3D = menu.sequence_picker_instance.get_node("Screen/Viewport2Din3D")
		var content: Node = surface.get_scene_instance()
		var play: Button
		for card in content._list.get_children():
			if card.find_children("*", "Label", true, false).any(func(label): return label.text.contains("Transformation")):
				play = card.find_children("*", "Button", true, false)[0]
		check("Transformation chapter is listed", play != null)
		if play == null: await finish(); return
		var scroll: ScrollContainer = content.get_node("Margin/Layout/Scroll")
		for step in range(20):
			if scroll.get_global_rect().encloses(play.get_global_rect()): break
			await wheel_at(root.get_camera_3d().unproject_position(surface.global_position))
		check("Mouse wheel reaches the chapter card", scroll.get_global_rect().encloses(play.get_global_rect()))
		await capture("selector")
		await click_control(surface, play)
	elif route == "maps":
		await create_timer(0.6).timeout
		check("Maps opens its browser", is_instance_valid(menu.map_browser_instance))
		if not is_instance_valid(menu.map_browser_instance): await finish(); return
		await capture("selector")
		var browser: Node3D = menu.map_browser_instance
		check("Maps lists destinations", browser._button_instances.size() > 0)
		if browser._button_instances.is_empty(): await finish(); return
		await click_node(browser._button_instances[0])
	var began := Time.get_ticks_msec()
	while reveals < 1 and Time.get_ticks_msec() - began < 65000: await process_frame
	check("Real staging emits scene_visible", reveals == 1)
	check("Destination instantiated", is_instance_valid(stage.current_scene))
	if not is_instance_valid(stage.current_scene): await finish(); return
	check("Expected destination loaded", stage.current_scene_path == ROUTES[route][1])
	# Allow the museum's opening fall and automatic exposure to settle.
	await create_timer(5.0 if route in ["museum", "sequences", "maps"] else 1.5).timeout
	var scene: Node3D = stage.current_scene
	if route == "void":
		check("Selected main-spine map opens at floor 14", scene.trial_id.is_empty() and scene.checkpoint == 14)
	if route == "trial":
		check("Transformation opens at its isolated floor",scene.trial_id=="transformation" and scene.checkpoint==1 and scene.building.spec.levels.size()>=3)
	if route in ["museum", "sequences"]:
		var museum: Node = scene.get_node("Museum")
		check("Requested museum chapter arrived", museum._first_chapter == ("transformation" if route == "sequences" else "primitives"))
	var camera := root.get_camera_3d()
	check("Destination owns the active desktop camera", camera != null and scene.is_ancestor_of(camera))
	check("Menu hidden during play", not menu.visible and not stage.get_node("LoadingScreen").visible)
	if scene.has_method("is_map_ready"): check("Destination reports ready", scene.is_map_ready())
	await capture("game")
	if scene.has_method("return_to_menu"): scene.return_to_menu()
	else: stage.return_to_main_menu()
	await create_timer(1.2).timeout
	check("Return restores visible menu and clears scene", stage.current_scene == null and menu.visible and not stage._returning_to_menu)
	check("Mouse restored after returning", Input.mouse_mode == Input.MOUSE_MODE_VISIBLE)
	await capture("returned-menu")
	print("[menu-route] Return state: guard=", menu._entering_head_arena, " transform=", menu.global_transform, " camera=", root.get_camera_3d().global_transform)
	# A second click detects stale entry guards and stuck pointers after return.
	var before := reveals
	await click_node(menu.get_node("Buttons/VoidButton"))
	if route == "void":
		check("Returned menu reopens the map picker", menu.has_node("VoidTrialPicker"))
		if not menu.has_node("VoidTrialPicker"): await finish(); return
		await click_picker("Transformation")
		await click_picker("Next", true)
		await capture("second-selector")
		await click_picker("019 /")
	else:
		if menu.has_node("VoidTrialPicker"): await click_picker("Start from the beginning")
	began = Time.get_ticks_msec()
	while reveals == before and Time.get_ticks_msec() - began < 65000: await process_frame
	check("Returned menu can start another game", reveals == before + 1 and stage.current_scene_path == "res://commons/void/void.tscn")
	if route == "void" and is_instance_valid(stage.current_scene):
		check("Second-page selection opens floor 19 after returning", stage.current_scene.checkpoint == 19)
		await capture("second-game")
		stage.current_scene.return_to_menu()
		while stage._returning_to_menu: await process_frame
	await finish()

func click_picker(caption: String, exact := false) -> void:
	var picker: Node3D = menu.get_node("VoidTrialPicker")
	for attempt in range(50):
		var next: Node3D = null
		for button in picker.buttons:
			if not button.visible: continue
			if (button.text == caption if exact else button.text.begins_with(caption)):
				await click_node(button)
				await create_timer(.25).timeout
				return
			if button.text == "Next": next = button
		if next == null: break
		await click_node(next)
		await create_timer(.25).timeout
	check("Picker contains " + caption, false)

func click_node(button: Node3D) -> void:
	var position_3d: Vector3 = button.get_node("CollisionShape3D").global_position
	print("[menu-route] Click ", button.text, " at ", root.get_camera_3d().unproject_position(position_3d), " layer=", button.collision_layer)
	await click_at(root.get_camera_3d().unproject_position(position_3d))
	var pointer := menu.get_node_or_null("DesktopMenuPointer")
	if pointer != null: print("[menu-route] Mouse target=", pointer.target, " entry guard=", menu._entering_head_arena)

func click_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion, true)
	await create_timer(0.1).timeout
	for pressed in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.pressed = pressed
		event.position = at
		root.push_input(event, true)
		await create_timer(0.1).timeout

func click_control(surface: Node3D, button: Control) -> void:
	var at: Vector2 = button.get_global_rect().get_center()
	var size: Vector2 = surface.viewport_size
	var screen: Vector2 = surface.screen_size
	var world: Vector3 = surface.to_global(Vector3((at.x / size.x - 0.5) * screen.x, (0.5 - at.y / size.y) * screen.y, 0.01))
	await click_at(root.get_camera_3d().unproject_position(world))

func wheel_at(at: Vector2) -> void:
	var motion := InputEventMouseMotion.new()
	motion.position = at
	root.push_input(motion, true)
	await create_timer(0.05).timeout
	var event := InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_WHEEL_DOWN
	event.position = at
	event.pressed = true
	root.push_input(event, true)
	await create_timer(0.1).timeout

func capture(suffix: String) -> void:
	if DisplayServer.get_name() == "headless": return
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(route + "-" + suffix + ".png"))

func finish() -> void:
	if finished: return
	finished = true
	var passed: bool = checks.all(func(c): return c.passed)
	var file := FileAccess.open(out.path_join(route + ".json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks, "user_data": OS.get_user_data_dir(), "destination": stage.current_scene_path if is_instance_valid(stage) else ""}, "\t"))
	file.close()
	# Drain menu preloads before teardown; never abandon background scene loads.
	for path in ["res://commons/scenes/lab.tscn", "res://commons/scenes/endless_museum_staged.tscn"]:
		while ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_IN_PROGRESS: await process_frame
		if ResourceLoader.load_threaded_get_status(path) == ResourceLoader.THREAD_LOAD_LOADED: ResourceLoader.load_threaded_get(path)
	# Give rendering and scene-owned jobs time to release before engine shutdown.
	await create_timer(.5).timeout
	if is_instance_valid(stage):
		stage.queue_free()
		stage = null
		menu = null
	for frame in range(12): await process_frame
	quit(0 if passed else 1)
