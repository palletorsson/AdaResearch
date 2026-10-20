extends SceneTree
const OUT := "res://doc/book/iterations/2026-10-17-shadow-game/"
const GAME := "res://commons/shadow_game/shadow_game.tscn"
var Encounter: GDScript
var checks: Array[Dictionary] = []
var failures: Array[String] = []
var world: Node3D
var finished := false
var rendering := false
var menu_mode := false

class Hand extends Node3D:
	var picked_up_ranged := false

func _initialize() -> void: run.call_deferred()

func check(label: String, result: bool) -> void:
	checks.append({"name":label,"passed":result})
	if not result: failures.append(label)
	print("[shadow-test] ", "PASS " if result else "FAIL ", label)

func ticks(count := 3) -> void:
	for i in range(count): await physics_frame

func run() -> void:
	# Load XR-dependent classes after the project's autoloads are registered.
	Encounter = load("res://commons/shadow_game/encounter.gd")
	rendering = DisplayServer.get_name() != "headless"
	menu_mode = OS.get_cmdline_user_args().has("--shadow-menu-test")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(100).timeout.connect(func(): check("bounded run completes",false); finish())
	if menu_mode:
		await run_menu()
		finish()
		return
	world = load(GAME).instantiate()
	world.save_path = "res://ada_run/shadow-game-test/world.json"
	if FileAccess.file_exists(world.save_path): DirAccess.remove_absolute(ProjectSettings.globalize_path(world.save_path))
	root.add_child(world)
	current_scene = world
	while not world.ready_for_play: await process_frame
	await ticks(12)
	var e: Node3D = world.encounter
	check("uses the museum XR scene base", world.is_xr_class("XRToolsSceneBase"))
	check("both existing XR pickup providers remain", world.find_children("*", "XRToolsFunctionPickup",true,false).size() == 2)
	check("desktop arrival stands on the actual floor", world.walker.is_on_floor())
	check("inactive XR capsule is parked away", world.get_node("XROrigin3D").position.y < -50)
	check("existing biome supplies the surroundings without writing its records", world.habitat.record == "off" and world.habitat._counts.cover > 0)
	check("three stable object identities", e.objects.size() == 3 and e.objects.has("sphere") and e.objects.has("cube") and e.objects.has("stick"))
	check("sphere inherits the tested lesson point", e.objects.sphere.get_script().get_base_script() == load("res://commons/museum_runner/forms/point_body.gd"))
	check("bridge starts closed with no power", not e.powered and not e.bridge_open())
	check("gap really has no crossing collider", gap_hit(e).is_empty())
	check("unheld stick cannot operate bridge", not e.turn_bridge())
	await photograph("entry.png", Vector3(0.4,2.4,6.2), Vector3(0,0.9,-2.5))
	await photograph("before.png", Vector3(9,8,10), Vector3(0,0.1,-2.5))
	var hand := Hand.new()
	e.add_child(hand)
	hand.position = e.objects.sphere.position
	e.objects.sphere.pick_up(hand)
	await ticks()
	check("actual XR pickup is active", e.objects.sphere.is_picked_up())
	for i in range(9):
		hand.position = Vector3(sin(i*0.45)*0.8,1.12,3.7-i*0.22)
		await ticks(2)
	var count: int = e.samples.size()
	check("carried sphere records several real movement samples", count >= 6 and e.trace_root.get_child_count() >= 5)
	await ticks(8)
	check("stationary sphere does not fill the record", e.samples.size() == count)
	hand.position = Encounter.POINT_SOCKET
	await ticks()
	e.objects.sphere.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await ticks()
	check("point alone cannot complete a closed crossing", not e.completed)
	e.recall_button.pressed.emit()
	await ticks()
	check("recall preserves the trace", e.samples.size() >= count)
	e.objects.sphere.position = Encounter.CUBE_SOCKET
	await ticks()
	check("sphere on cube socket does not power hinge", not e.powered)
	e.recall_loose()
	hand.position = e.objects.cube.position
	e.objects.cube.pick_up(hand)
	hand.position = Encounter.CUBE_SOCKET + Vector3(0.1,0.03,0)
	await ticks()
	check("held cube does not count as a placed anchor", not e.cube_in_place())
	e.objects.cube.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	await ticks()
	check("released cube snaps into its physical socket", e.objects.cube.position.is_equal_approx(Encounter.CUBE_SOCKET) and e.powered)
	hand.position = e.objects.stick.position
	e.objects.stick.pick_up(hand)
	e.objects.stick.action()
	await create_timer(0.45).timeout
	check("held stick action rotates actual bridge", e.bridge.rotation.y < 1.5 and e.bridge.rotation.y > 0)
	check("repeated trigger does not reverse mid-turn", not e.turn_bridge())
	# Removing the cube pauses the existing motion; it does not rebuild the bridge.
	var bridge_id: int = e.bridge.get_instance_id()
	var hand2 := Hand.new()
	e.add_child(hand2)
	hand2.position = e.objects.cube.position
	e.objects.cube.pick_up(hand2)
	await ticks()
	var held_angle: float = e.bridge.rotation.y
	await create_timer(0.2).timeout
	check("removing the cube stops the bridge", is_equal_approx(held_angle,e.bridge.rotation.y))
	e.objects.cube.let_go(hand2,Vector3.ZERO,Vector3.ZERO)
	await create_timer(2.8).timeout
	check("restoring cube resumes the same bridge", e.bridge_open() and e.bridge.get_instance_id() == bridge_id)
	check("open bridge supports the actual gap", not gap_hit(e).is_empty() and gap_hit(e).collider == e.bridge)
	e.objects.stick.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	await ticks()
	# Exercise the shared desktop input adapter as well as XRTools' grab driver.
	var pointer: Node3D = world.walker.desktop_pointer
	world.walker.set_physics_process(false)
	world.walker.position = Vector3(0,0.08,0.4)
	world.walker.velocity = Vector3.ZERO
	pointer._grab_held(e.objects.sphere)
	check("desktop uses the same object's pickup hook", e.objects.sphere.is_held())
	var crossed := true
	for i in range(230):
		await physics_frame
		world.walker.velocity = Vector3(0,-1.0,-1.5)
		world.walker.move_and_slide()
		if world.walker.position.y < -0.12: crossed = false
	check("a real character body can walk across the bridge", crossed and world.walker.position.z < -4.5)
	e.objects.sphere.position = Encounter.POINT_SOCKET
	pointer._drop_held()
	await ticks()
	check("release on far plinth completes crossing", e.completed and e.objects.sphere.position.is_equal_approx(Encounter.POINT_SOCKET))
	check("three original objects survive completion", e.objects.size() == 3 and is_instance_valid(e.objects.stick))
	await photograph("after.png", Vector3(9,8,10), Vector3(0,0.1,-2.5))
	await photograph("kept-trace.png", Vector3(3.2,2.6,-3), Vector3(0,0.7,1.9))
	check("arrangement written to isolated save", FileAccess.file_exists(e.save_path))
	var saved: Dictionary = e.snapshot()
	var replay: Node3D = Encounter.new()
	replay.save_path = e.save_path
	replay.position.x = 40
	root.add_child(replay)
	await ticks()
	check("new scene restores completion and bridge", replay.restored and replay.completed and replay.bridge_open())
	check("restoration retains object positions", replay.objects.cube.position.is_equal_approx(e.objects.cube.position) and replay.objects.sphere.position.is_equal_approx(e.objects.sphere.position))
	var trace_same: bool = replay.samples.size() == e.samples.size()
	for i in range(mini(replay.samples.size(),e.samples.size())):
		trace_same = trace_same and Encounter._vector(replay.samples[i].p) == Encounter._vector(e.samples[i].p) and replay.samples[i].start == e.samples[i].start
	check("restoration retains exact ordered trace", trace_same)
	check("restored trace has the same drawn segments", replay.trace_root.get_child_count() == e.trace_root.get_child_count())
	replay.queue_free()
	await ticks()
	var bad := saved.duplicate(true)
	bad.objects.erase("cube")
	check("missing object record is rejected", not Encounter.valid_snapshot(bad))
	bad = saved.duplicate(true)
	bad.schema = 99
	check("unknown save edition is rejected", not Encounter.valid_snapshot(bad))
	bad = saved.duplicate(true)
	bad.objects.sphere.position[0] = NAN
	check("nonfinite coordinates are rejected", not Encounter.valid_snapshot(bad))
	bad = saved.duplicate(true)
	bad.trace.resize(Encounter.MAX_SAMPLES+1)
	check("unbounded trace save is rejected", not Encounter.valid_snapshot(bad))
	var before_recovery: int = e.samples.size()
	var stick_before: Transform3D = e.objects.stick.transform
	world.walker.position.y = -2
	world._physics_process(0)
	check("fall recovers player without erasing work", world.walker.position.is_equal_approx(world.spawn) and e.samples.size() == before_recovery and e.completed)
	check("fall preserves unrelated object placements", e.objects.stick.transform.is_equal_approx(stick_before))
	hand.position = e.objects.stick.position
	e.objects.stick.pick_up(hand)
	hand.position = Vector3(0,-2,0)
	await ticks()
	e.objects.stick.let_go(hand,Vector3.ZERO,Vector3.ZERO)
	await ticks()
	check("a dropped lost object returns to its last placed pose", e.objects.stick.transform.is_equal_approx(stick_before))
	e.reset_button.pressed.emit()
	check("one reset press preserves work", e.completed and e.samples.size() == before_recovery)
	e.reset_button.pressed.emit()
	await ticks()
	check("second reset explicitly starts a clean arrangement", not e.completed and e.samples.is_empty() and not e.bridge_open())
	hand.queue_free()
	hand2.queue_free()
	finish()

func gap_hit(e: Node3D) -> Dictionary:
	return e.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(0,1,-2.5),Vector3(0,-0.5,-2.5),1))

func photograph(filename: String, at: Vector3, target: Vector3) -> void:
	if not rendering: return
	world.walker.set_physics_process(false)
	var visible_layers: Array[CanvasLayer] = []
	for layer in root.find_children("*", "CanvasLayer", true, false):
		if layer.visible:
			visible_layers.append(layer)
			layer.hide()
	var camera := Camera3D.new()
	camera.environment = world.environment
	camera.fov = 60
	world.add_child(camera)
	camera.position = at
	camera.look_at(target)
	camera.make_current()
	for i in range(5): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUT+filename)
	camera.queue_free()
	await process_frame
	world.walker.camera.make_current()
	for layer in visible_layers:
		if is_instance_valid(layer): layer.show()
	world.walker.set_physics_process(true)

func run_menu() -> void:
	var staging: Node3D = load("res://commons/scenes/vr_staging.tscn").instantiate()
	# Supply a single deliberate pointer in this synthetic menu test. Untracked
	# controller rays otherwise hover another button at their default origin.
	for pointer in staging.find_children("*", "XRToolsFunctionPointer",true,false):
		pointer.enabled = false
	root.add_child(staging)
	current_scene = staging
	await create_timer(0.7).timeout
	var menu: Node3D = staging.get_node("MainMenu3D")
	var button: Node3D = menu.get_node("Buttons/ShadowGameButton")
	for other in menu.get_node("Buttons").get_children():
		other.pointer_exited()
		other.clicked.connect(func(): print("[shadow-menu-click] ",other.name))
	check("real menu exposes Shadow Game", button.is_visible_in_tree() and button.get_node("Label3D").text == "Shadow Game")
	button.pointer_entered()
	var start := Time.get_ticks_msec()
	while (staging.current_scene == null or not staging.current_scene.is_map_ready()) and Time.get_ticks_msec()-start < 65000: await process_frame
	check("normal menu dwell reaches the playable scene", staging.current_scene_path == GAME and staging.current_scene != null and staging.current_scene.is_map_ready())
	if staging.current_scene == null or staging.current_scene_path != GAME: return
	world = staging.current_scene
	await create_timer(1.0).timeout
	check("staging entry uses the scene environment and player", root.get_camera_3d() == world.walker.camera and world.walker.camera.environment == world.environment)
	check("staging starts the same three-object encounter", world.encounter.objects.size() == 3)
	world.encounter.menu_button.pressed.emit()
	await create_timer(1.0).timeout
	check("return preserves staging and restores menu", current_scene == staging and staging.current_scene == null and menu.visible)
	check("menu can launch another visit", not menu._entering_head_arena)
	# Release the staged scene while rendering and autoloads are still alive.
	# The existing staging test otherwise hits a Windows shutdown crash.
	current_scene = null
	staging.queue_free()
	for i in range(5): await process_frame

func finish() -> void:
	if finished: return
	finished = true
	var output := FileAccess.open(OUT + ("menu-checks.json" if menu_mode else "checks.json"), FileAccess.WRITE)
	output.store_string(JSON.stringify({"checks":checks,"failures":failures,"passed":failures.is_empty(),"rendered":rendering,"scope":"Native synthetic input; no physical headset or human learning trial."},"\t"))
	output.close()
	print("[shadow-test] ",checks.size()-failures.size(),"/",checks.size()," passed")
	quit(0 if failures.is_empty() else 1)
