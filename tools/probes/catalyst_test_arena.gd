extends SceneTree
const OUT := "res://ada_run/encounter_pilot/Catalyst_Test_Arena/"
var checks: Array = []
var failures: Array = []
var arena: Node3D
var camera: Camera3D

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label, "passed":passed})
	if not passed: failures.append(label)
	print("[arena] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(90).timeout.connect(func(): check("probe completes before timeout", false); finish())
	var scene: Node3D = load("res://commons/testing/catalyst_test_arena.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	var start := Time.get_ticks_msec()
	while scene.trial == null and Time.get_ticks_msec() - start < 65000: await process_frame
	arena = scene.trial
	check("arena F6 scene mounts in the actual museum", arena != null)
	if arena == null: finish(); return
	var museum: Node3D = scene.get_node("Museum")
	museum.set("_lazy_pending", 0); museum.set_process(false); museum.set_physics_process(false)
	var old: Camera3D = museum.get("_cam")
	if old != null:
		for timer in old.find_children("*", "Timer", true, false): timer.stop()
	camera = Camera3D.new(); root.add_child(camera); camera.make_current(); root.size = Vector2i(1440, 900)
	var head: CharacterBody3D = arena.skull
	var identity := head.get_instance_id()
	check("arrival is safe and needs no drawing prerequisite", not arena.running and not head.active)
	check("three operation controls are present", arena.buttons.size() == 3)
	check("catalyst is immediately within reach", arena.catalyst.position.y > 1 and arena.catalyst.position.y < 1.4)
	for p in [Vector3(0,0,3), Vector3(0,0,0), Vector3(0,0,-5), Vector3(-4.6,0,1.3), Vector3(4.7,0,1.7)]:
		var at := arena.to_global(p)
		var hit := arena.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(at + Vector3.UP * 0.1, at + Vector3.DOWN * 0.15, 1))
		check("floor supports approach " + str(p), not hit.is_empty())
	await snapshot("arena-overview", Vector3(0, 1.8, 5.0), Vector3(0, 1.5, -2.5), 76)
	await snapshot("arena-controls", Vector3(5.0, 1.75, 2.7), Vector3(4.7, 1.3, 0.6), 62)
	head.set_physics_process(false)
	var target := Node3D.new(); arena.add_child(target); target.position = Vector3(0, 1.65, 0)
	head.target_override = target
	arena.buttons[1].pressed.emit()
	check("TURN selects rotation", head.power == 2 and not arena.running)
	var before: Vector3 = head.position
	for i in range(20): head.advance(0.1, target.global_position)
	check("TURN moves the same body around an orbit", absf(head.position.x - before.x) > 0.25)
	arena.buttons[2].pressed.emit(); head.advance(0.2, target.global_position)
	check("SCALE changes visible body and collision together", head.power == 3 and head.size_factor > 1 and is_equal_approx(head.boundary.radius, head.RADIUS * head.visual.scale.x))
	arena.buttons[0].pressed.emit()
	check("MOVE restores the initial resolution of the encounter", head.power == 1 and is_equal_approx(head.boundary.radius, head.RADIUS))
	arena.start_button.pressed.emit()
	check("START begins immediately without an unlock", arena.running and head.active)
	head.advance(2.01, target.global_position)
	check("charge is announced by a visible line", head.state == head.State.TELEGRAPH and head.cue.visible)
	var destination: Vector3 = head.destination
	target.position.x = 1.2; head.advance(0.1, target.global_position)
	check("head cannot retarget the announced charge", head.destination.is_equal_approx(destination))
	await snapshot("arena-warning", Vector3(1.8, 1.8, 0.7), Vector3(0, 1.6, -3), 59)
	arena.rest_button.pressed.emit()
	check("REST cancels attack and its cue immediately", not head.active and not arena.running and not head.cue.visible)
	arena.start_button.pressed.emit()
	var point: RigidBody3D = arena.catalyst
	var hand := SuppliedGrabber.new(); arena.add_child(hand)
	hand.position = Vector3(0, 1.65, -1.5)
	point.global_transform = hand.global_transform; point.pick_up(hand)
	await create_timer(0.1).timeout
	check("point uses actual XRTools pickup", point.is_picked_up())
	for i in range(3):
		head.position = arena.HEAD_HOME
		if head.state == head.State.INTERRUPTED: head.advance(2.6, target.global_position)
		point.action_pressed.emit(point)
		await create_timer(0.7).timeout
		check("real projectile scores interruption " + str(i + 1), arena.round_hits == i + 1)
		if i == 0:
			arena.start_button.pressed.emit()
			check("repeated START does not erase an active round", arena.round_hits == 1)
	check("three interruptions finish the round", arena.completed and not arena.running and not head.active)
	check("counterpart survives with the same identity", head.get_instance_id() == identity)
	check("score lamps display all three hits", arena.score_lights[2].material_override.albedo_color.r > 0.9)
	await snapshot("arena-complete", Vector3(0.8, 1.8, -0.3), Vector3(0, 2, -5), 62)
	arena.reset_button.pressed.emit()
	check("RESET never tears a held point out of the hand", point.is_picked_up())
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	arena.reset_button.pressed.emit(); await create_timer(0.2).timeout
	check("RESET clears score and completion", arena.round_hits == 0 and not arena.completed)
	check("RESET clears all live projectiles", point.projectiles.is_empty())
	check("RESET returns released point to its plinth", point.global_position.distance_to(point.home.origin) < 0.001)
	check("RESET restores the same head", head.position.is_equal_approx(arena.HEAD_HOME) and head.get_instance_id() == identity)
	arena.start_button.pressed.emit()
	check("another round starts without replaying other rooms", arena.running and head.active)
	arena.rest_button.pressed.emit(); hand.queue_free(); target.queue_free()
	finish()

func snapshot(name: String, eye: Vector3, target: Vector3, fov: float) -> void:
	if DisplayServer.get_name() == "headless": return
	camera.global_position = arena.to_global(eye); camera.look_at(arena.to_global(target)); camera.fov = fov; camera.make_current()
	await create_timer(0.3).timeout; await RenderingServer.frame_post_draw
	check("capture camera retained " + name, root.get_camera_3d() == camera)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))

func finish() -> void:
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(), "checks":checks, "failures":failures, "scope":"Actual museum entry point and XRTools/projectile paths; supplied hand poses. Headset feel untested."}, "  "))
	print("CATALYST ARENA ", checks.size() - failures.size(), "/", checks.size())
	quit(0 if failures.is_empty() else 1)
