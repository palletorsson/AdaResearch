extends SceneTree
## Real F6 entry point, supplied tracked-hand poses, real XRTools grab and projectile.
const OUT := "res://ada_run/encounter_pilot/Catalyst_First_Abilities/"
var checks: Array = []
var failures: Array = []
var trial: Node3D
var camera: Camera3D
var scene: Node3D

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func _initialize() -> void: run.call_deferred()
func check(label: String, passed: bool) -> void:
	checks.append({"name":label, "passed":passed})
	if not passed: failures.append(label)
	print("[catalyst-test] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(90.0).timeout.connect(func(): check("probe finished within 90 seconds", false); finish())
	scene = load("res://commons/testing/catalyst_first_abilities.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	var started := Time.get_ticks_msec()
	while scene.trial == null and Time.get_ticks_msec() - started < 70000: await process_frame
	trial = scene.trial
	check("dedicated F6 test scene mounts in real museum", trial != null)
	if trial == null: finish(); return
	var museum: Node3D = scene.get_node("Museum")
	museum.set("_lazy_pending", 0); museum.set_process(false); museum.set_physics_process(false)
	var previous: Camera3D = museum.get("_cam")
	if previous != null:
		for timer in previous.find_children("*", "Timer", true, false): timer.stop()
	camera = Camera3D.new(); root.add_child(camera); camera.make_current()
	root.size = Vector2i(1440, 900)
	var rod: RigidBody3D = trial.rod
	var trace: Node3D = trial.trace
	var skull: CharacterBody3D = trial.skull
	var identity := skull.get_instance_id()
	var saved_before: int = root.get_node("TraceData").saved_traces.size()
	check("head waits in the Durer tableau", not skull.is_physics_processing() and skull.collision_layer == 0)
	trial.start_button.pressed.emit()
	check("BEGIN waits for a kept drawing", trial.stage == trial.Stage.DRAW)
	check("gate initially blocks the passage", gate_hit())
	await snapshot("01-charge-and-draw", Vector3(3, 1.7, -0.7), Vector3(-1.8, 1.35, -3.1), 65)
	# A free rod lying inside the field cannot unlock drawing.
	rod.rotation = Vector3.ZERO
	rod.global_position = trial.field.global_position + Vector3(0, 0, 0.405)
	rod.advance_charge(0.4)
	check("charge requires a held rod", not rod.charged)
	var hand := SuppliedGrabber.new(); scene.add_child(hand)
	hand.global_transform = rod.global_transform
	rod.pick_up(hand)
	await create_timer(0.06).timeout
	check("existing pen uses an aligned XRTools grip", rod.is_picked_up() and rod.held() and rod.has_node("WritingGrip"))
	rod.set_process(false)
	# Align the supplied hand using the real grip's resulting tip offset.
	for i in range(3):
		hand.global_position += trial.field.global_position - rod.get_node("WritingTip").global_position
		await physics_frame
	print("[catalyst-test] charge distance ", rod.get_node("WritingTip").global_position.distance_to(trial.field.global_position))
	rod.dwell = 0; rod.advance_charge(0.10)
	check("field contact needs a short dwell", not rod.charged)
	rod.advance_charge(0.20)
	check("held tip in field becomes charged", rod.charged and rod.tip_glow.visible)
	rod.set_process(true)
	trace.clear_trail()
	# Move the real grabbed rod, letting the actual trace process sample each pose.
	for i in range(50):
		hand.global_position = trial.to_global(Vector3(-0.8 + i * 0.034, 1.5 + sin(i * 0.18) * 0.33, -3 + cos(i * 0.12) * 0.22))
		await create_timer(0.025).timeout
	check("charged hand movement records a line", trace._trail_points.size() > 20)
	await snapshot("01b-a-line-in-the-air", Vector3(1.6, 1.75, -0.7), Vector3(-0.2, 1.5, -3), 55)
	var count: int = trace._trail_points.size()
	await create_timer(0.1).timeout
	check("a still hand adds no duplicate samples", trace._trail_points.size() == count)
	rod.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await process_frame
	check("release carries the record to the next room", trial.stage == trial.Stage.REST and trial.record.size() == trace._trail_points.size())
	check("sculpture uses the recorded intervals", trial.sculpture.get_child_count() == 1 and trial.sculpture.get_child(0).multimesh.instance_count == trial.record.size() - 1)
	if trial.record.is_empty():
		rod.let_go(hand, Vector3.ZERO, Vector3.ZERO)
		finish(); return
	var kept_first: Vector3 = trial.record[0]
	trace._trail_points[0] += Vector3.RIGHT
	check("kept record is independent from live trace", trial.record[0].is_equal_approx(kept_first))
	check("test does not append to museum TraceData", root.get_node("TraceData").saved_traces.size() == saved_before)
	await snapshot("02-line-kept-head-waiting", Vector3(2.5, 1.85, -8.1), Vector3(-0.3, 1.5, -12.4), 66)
	await snapshot("02b-your-kept-line", Vector3(4.6, 1.8, -9.1), Vector3(3.6, 1.5, -11.2), 55)
	# Check the entire route has floor, including controls and the exit.
	for at in [Vector3(0, 0, -1), Vector3(0, 0, -7), Vector3(0, 0, -16), Vector3(-3.7, 0, -17.4), Vector3(0, 0, -26)]:
		var p := trial.to_global(at)
		var hit := trial.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.1, p + Vector3.DOWN * 0.15, 1))
		check("continuous floor at " + str(at), not hit.is_empty())
	var target := Node3D.new(); trial.arena.add_child(target); target.position = Vector3(0, 1.65, -0.5)
	skull.target_override = target
	trial.start_button.pressed.emit()
	check("BEGIN moves the waiting head", trial.stage == trial.Stage.ARRIVING)
	await create_timer(2.35).timeout
	check("same head arrives active in arena", skull.get_instance_id() == identity and skull.active and trial.stage == trial.Stage.DEFEND)
	skull.set_physics_process(false)
	skull.advance(2.05, target.global_position)
	check("attack warns before moving", skull.state == skull.State.TELEGRAPH and skull.cue.visible)
	var locked: Vector3 = skull.destination
	target.position.x = 1.1; skull.advance(0.1, target.global_position)
	check("warning line stays locked when visitor dodges", skull.destination.is_equal_approx(locked))
	await snapshot("03-head-and-locked-line", Vector3(2, 1.75, -17.6), Vector3(0, 1.5, -21.1), 65)
	# Reset mid-transit cancels the delayed activation callback.
	trial.reset_button.pressed.emit()
	var short_record: Array[Vector3] = [trial.to_global(Vector3(0, 1, -3)), trial.to_global(Vector3(1, 1, -3))]
	trial.keep_record(short_record)
	trial.begin_encounter(); await create_timer(0.1).timeout
	trial.reset_button.pressed.emit(); await create_timer(2.3).timeout
	check("reset cancels an in-progress arrival", trial.stage == trial.Stage.DRAW and not skull.active)
	trial.keep_record(short_record)
	trial.begin_encounter(); await create_timer(2.35).timeout
	skull.set_physics_process(false)
	skull.position = Vector3(0, 1.65, -3.5)
	var point: RigidBody3D = trial.catalyst
	hand.global_transform = trial.arena.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.65, -1.5))
	point.global_transform = hand.global_transform; point.pick_up(hand)
	await create_timer(0.1).timeout
	var rings: int = point.sphere.rings; point.advance(0.3)
	check("held sphere keeps its resolution behaviour", point.is_picked_up() and point.sphere.rings < rings)
	point.action_pressed.emit(point)
	check("XR trigger sends one actual form", point.projectiles.size() == 1)
	await create_timer(0.65).timeout
	check("projectile collision interrupts the head", skull.interruptions == 1)
	check("interruption opens a usable passage", trial.stage == trial.Stage.OPEN and not gate_hit())
	check("head survives and stops attacking", is_instance_valid(skull) and not skull.active)
	await snapshot("04-the-way-opens", Vector3(2.7, 1.8, -21.3), Vector3(0, 1.4, -26), 63)
	trial.visitor_override = target
	target.global_position = trial.to_global(Vector3(0, 1.65, -26.5)); trial._process(0)
	check("walking through completes the trial", trial.stage == trial.Stage.COMPLETE)
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	trial.reset_button.pressed.emit(); await create_timer(0.2).timeout
	check("reset closes collision as well as the visible gate", gate_hit() and trial.gate_leaf.visible)
	check("reset clears charge, trace and sculpture", not rod.charged and trace._trail_points.is_empty() and trial.record.is_empty())
	check("reset restores the original head without replacement", skull.get_instance_id() == identity and skull.global_position.is_equal_approx(trial.to_global(trial.head_rest)))
	check("reset clears projectiles and counters", point.projectiles.is_empty() and skull.tags == 0 and skull.interruptions == 0)
	print("[catalyst-test] reset point ", point.global_transform, " home ", point.home)
	check("reset returns the released catalyst", point.global_position.distance_to(point.home.origin) < 0.001 and point.global_basis.get_rotation_quaternion().angle_to(point.home.basis.get_rotation_quaternion()) < 0.001)
	check("released rod returns to its wall mount", rod.global_position.distance_to(rod.home.origin) < 0.001)
	check("museum trace store still untouched", root.get_node("TraceData").saved_traces.size() == saved_before)
	hand.queue_free(); target.queue_free()
	finish()

func gate_hit() -> bool:
	var from := trial.to_global(Vector3(0, 1.4, -24.5))
	var to := trial.to_global(Vector3(0, 1.4, -25.5))
	return not trial.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(from, to, 1)).is_empty()

func snapshot(name: String, eye: Vector3, target: Vector3, fov: float) -> void:
	if DisplayServer.get_name() == "headless": return
	camera.global_position = trial.to_global(eye)
	camera.look_at(trial.to_global(target)); camera.fov = fov; camera.make_current()
	await create_timer(0.35).timeout; await RenderingServer.frame_post_draw
	check("native screenshot camera retained: " + name, root.get_camera_3d() == camera)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))

func finish() -> void:
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"checks":checks, "failures":failures, "passed":failures.is_empty(), "scope":"Actual museum/F6 entry; real XRTools pickup and projectile, supplied hand poses. No headset or play-quality claim."}, "  "))
	print("CATALYST FIRST ABILITIES ", checks.size() - failures.size(), "/", checks.size())
	quit(0 if failures.is_empty() else 1)
