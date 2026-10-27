extends SceneTree
## Exercise the actual menu signal and staging route without replacing main scene.
class StagingFixture extends Node3D:
	var destination := ""
	var returned := false
	func load_scene(path: String) -> void: destination = path
	func return_to_main_menu() -> void: returned = true

func _initialize() -> void:
	run.call_deferred()

func run() -> void:
	var stuck := root.get_node_or_null("StuckDetector")
	var mushroom := root.get_node_or_null("MushroomHand")
	var stuck_enabled: bool = stuck.enabled if stuck != null else false
	var mushroom_mode: int = mushroom.process_mode if mushroom != null else 0
	var fixture := StagingFixture.new()
	root.add_child(fixture)
	var menu: Node3D = load("res://commons/scenes/main_menu/MainMenu3D.tscn").instantiate()
	fixture.add_child(menu)
	for i in range(5): await process_frame
	if "--void-menu-only" in OS.get_cmdline_user_args():
		# Baseline: same existing menu, never load or instantiate the Void.
		fixture.queue_free()
		for i in range(4): await process_frame
		print("[void-menu] Baseline menu only; no Void scene loaded")
		quit()
		return
	var motion_room := "--void-motion-room" in OS.get_cmdline_user_args()
	var button := menu.get_node("Buttons/VoidMovementButton" if motion_room else "Buttons/VoidButton")
	button.clicked.emit()
	if not motion_room:
		var picker := menu.get_node("VoidTrialPicker")
		# The main Void entry now offers destinations before loading the tower.
		assert(fixture.destination.is_empty())
		assert(not menu.get_node("Buttons").visible)
		picker.buttons[0].clicked.emit() # Start from the beginning.
	var expected := "res://commons/void/motion_room.tscn" if motion_room else "res://commons/void/void.tscn"
	var checks := [{"name": "Actual main-menu button requests the playable scene through staging", "passed": fixture.destination == expected}]
	var game: Node3D = load(fixture.destination).instantiate()
	fixture.add_child(game)
	for i in range(30): await physics_frame
	game.scene_loaded()
	game.scene_visible()
	checks.append({"name": "Playable scene initializes inside the real project", "passed": game.ready_for_play and game.is_map_ready()})
	checks.append({"name": "Global rescue is suspended during intentional falls", "passed": stuck == null or not stuck.enabled})
	if motion_room:
		game.compare_tower()
		checks.append({"name":"Y comparison requests The Void through staging with telemetry", "passed":fixture.destination=="res://commons/void/void.tscn" and game.motion_test_requested})
		game.motion_test_requested = false
	else:
		game.return_to_menu()
		checks.append({"name": "Exit returns through staging", "passed": fixture.returned})
	fixture.queue_free()
	for i in range(4): await process_frame
	checks.append({"name": "Global rescue and hand tools are restored on exit", "passed": (stuck == null or stuck.enabled == stuck_enabled) and (mushroom == null or mushroom.process_mode == mushroom_mode)})
	var passed: bool = checks.all(func(c): return c.passed)
	var output := "res://doc/book/iterations/2026-10-18-the-void-playable"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
	var file := FileAccess.open(output.path_join("menu-checks.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks}, "\t"))
	file.close()
	print("[void-menu] ", JSON.stringify(checks))
	quit(0 if passed else 1)
