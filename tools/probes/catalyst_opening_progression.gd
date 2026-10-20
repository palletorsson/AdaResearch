extends SceneTree
## Real museum, XRTools pickup, recorder and projectile contacts; supplied tracked poses.
const OUT := "res://ada_run/encounter_pilot/Catalyst_Opening_Progression/"
var checks: Array = []
var failures: Array = []
var trial: Node3D
var camera: Camera3D
var scene: Node3D
var hand: Node3D

class SuppliedGrabber extends Node3D:
	var picked_up_ranged := false

func _initialize() -> void: run.call_deferred()

func check(label: String, passed: bool) -> void:
	checks.append({"name":label, "passed":passed})
	if not passed: failures.append(label)
	print("[opening-test] ", "PASS " if passed else "FAIL ", label)

func run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUT))
	create_timer(90.0).timeout.connect(func(): check("probe finished within 90 seconds", false); finish())
	var manager: Node = root.get_node("CatalystCapabilityManager")
	var saved_path: String = manager.progression_file
	var saved := FileAccess.get_file_as_bytes(saved_path) if FileAccess.file_exists(saved_path) else PackedByteArray()
	var unlocked_before: bool = manager.has_first_catalyst()
	var global_ability: Node3D = manager.first_catalyst
	var process_before := global_ability.is_physics_processing()
	var visible_before := global_ability.visible
	var saved_traces: int = root.get_node("TraceData").saved_traces.size()
	scene = load("res://commons/testing/catalyst_opening_progression.tscn").instantiate()
	root.add_child(scene); current_scene = scene
	var began := Time.get_ticks_msec()
	while scene.trial == null and Time.get_ticks_msec() - began < 70000: await process_frame
	trial = scene.trial
	check("new F6 route mounts inside the actual museum", trial != null)
	if trial == null: finish(); return
	var museum: Node3D = scene.get_node("Museum")
	museum.set("_lazy_pending", 0); museum.set_process(false); museum.set_physics_process(false)
	var previous: Camera3D = museum.get("_cam")
	if previous != null:
		var arrival := trial.to_local(previous.global_position)
		print("[opening-test] arrival ", arrival)
		check("museum arrival is before the acquisition plinths", arrival.z > 5 and absf(arrival.x) < 6)
		for timer in previous.find_children("*", "Timer", true, false): timer.stop()
	camera = Camera3D.new(); root.add_child(camera); camera.make_current()
	root.size = Vector2i(1440, 900)
	hand = SuppliedGrabber.new(); scene.add_child(hand)
	var point: RigidBody3D = trial.catalyst
	var point_id := point.get_instance_id()
	var skull: CharacterBody3D = trial.skull
	var head_id := skull.get_instance_id()
	var rod: RigidBody3D = trial.rod
	trial.ability.set_physics_process(false)
	trial.acquisition.set_physics_process(false)
	await create_timer(0.15).timeout
	check("no pre-granted ability or weapon", not trial.power_unlocked and not trial.joined and not point.emission_enabled)
	check("persistent hand ability is suspended only in this trial", not global_ability.is_physics_processing() and not global_ability.visible)
	check("first point rests on entrance plinth", point.global_position.distance_to(trial.to_global(trial.POINT_START)) < 0.01)
	var poses := Transform3D(Basis.IDENTITY, trial.to_global(Vector3(0, 1.35, 5)))
	var left := poses; left.origin.x -= 0.09
	var right := poses; right.origin.x += 0.09
	trial.ability.update_hands(left, right, true, true, 0.2)
	check("joining hands cannot skip acquisition", not trial.ability.formed)
	trial.start_button.pressed.emit()
	check("BEGIN cannot skip opening lessons", trial.stage == trial.Stage.DRAW and not skull.active)
	var fake := Node3D.new(); scene.add_child(fake)
	fake.global_position = trial.acquisition.to_global(trial.acquisition.CENTRE)
	check("field rejects an unrelated object", not trial.acquisition.accepts(fake))
	fake.queue_free()
	# Real aligned pen, put in its actual field before the power exists.
	await grab_rod_at_field()
	rod.advance_charge(0.4)
	check("rod does not charge before the hand ability", not rod.charged)
	rod.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await snapshot("01-the-first-point", Vector3(0, 1.7, 8), Vector3(0, 1.1, 4.5), 70)
	# The same PointBody is picked up and taken into the real acquisition field.
	hand.global_transform = point.global_transform
	point.pick_up(hand); await physics_frame
	point.action_pressed.emit(point)
	check("first pickup cannot fire", point.projectiles.is_empty())
	point.advance(0.5)
	check("first pickup does not prematurely simplify", point.sphere.rings == 16 and point.sphere.radial_segments == 32)
	for i in range(3):
		hand.global_position += trial.acquisition.to_global(trial.acquisition.CENTRE) - point.global_position
		await physics_frame
	trial.acquisition._physics_process(0.10)
	check("acquisition requires sustained field contact", not trial.power_unlocked)
	trial.acquisition._physics_process(0.10)
	check("first point unlocks the local hand ability", trial.power_unlocked and trial.acquisition.activated and trial.ability.unlocked)
	trial.ability.update_hands(left, right, true, false, 0.2)
	check("occupied hands cannot form the sphere", not trial.ability.formed)
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	trial.ability.update_hands(left, right, false, true, 0.2)
	check("untracked hands cannot form the sphere", not trial.ability.formed)
	trial.ability.update_hands(left, right, true, true, 0.1)
	check("summoning has its own short dwell", not trial.ability.formed)
	trial.ability.update_hands(left, right, true, true, 0.1)
	trial._process(0)
	check("joining empty tracked hands forms a point and enables drawing", trial.ability.formed and trial.joined and rod.charge_enabled and trial.field.visible)
	await snapshot("02-form-between-hands", Vector3(0.5, 1.6, 6), Vector3(0, 1.35, 5), 48)
	right.origin.x += 0.5
	trial.ability.update_hands(left, right, true, true, 0.1)
	check("separating hands dismisses the form but retains ability", not trial.ability.formed and trial.ability.left_glow.visible and trial.joined)
	# Carry the existing line recorder through a genuine sampled gesture.
	await grab_rod_at_field()
	rod.advance_charge(0.3)
	check("the acquired ability charges the held rod", rod.charged)
	rod.set_process(true)
	trial.trace.clear_trail()
	for i in range(45):
		hand.global_position = trial.to_global(Vector3(-0.8 + i * 0.037, 1.5 + sin(i * 0.18) * 0.33, -3 + cos(i * 0.12) * 0.22))
		await create_timer(0.025).timeout
	check("real recorder samples the charged hand movement", trial.trace._trail_points.size() > 20)
	await snapshot("03-charge-and-draw", Vector3(1.6, 1.75, -0.6), Vector3(-0.5, 1.5, -3), 68)
	rod.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	await create_timer(0.2).timeout
	check("release keeps the real trace and advances the point", trial.record.size() > 20 and point.get_instance_id() == point_id and point.global_position.distance_to(trial.to_global(trial.POINT_LATER)) < 0.02)
	if trial.record.is_empty() or trial.sculpture.get_child_count() == 0:
		finish(); return
	check("sculpture reuses every recorded interval", trial.sculpture.get_child(0).multimesh.instance_count == trial.record.size() - 1)
	var first: Vector3 = trial.record[0]
	trial.trace._trail_points[0] += Vector3.RIGHT
	check("kept record remains independent of its live source", trial.record[0] == first)
	check("head still waits without attacking beside the kept trace", not skull.active and not skull.is_physics_processing() and skull.collision_layer == 0)
	await snapshot("04-kept-line-waiting-head", Vector3(2.5, 1.85, -8.1), Vector3(-0.3, 1.5, -12.4), 66)
	trial.start_button.pressed.emit()
	check("drawing alone cannot start combat", trial.stage == trial.Stage.REST and not skull.active)
	# Learn the surface and the trigger in a quiet station first.
	hand.global_transform = point.global_transform; point.pick_up(hand)
	await create_timer(0.1).timeout
	check("same point enables resolution at the primitive station", point.resolution_enabled and point.get_instance_id() == point_id)
	point.advance(5.0); await create_timer(0.05).timeout
	check("held surface reaches valid Godot minimum and unlocks emission", point.sphere.rings == 1 and point.sphere.radial_segments == 4 and trial.form_studied and point.emission_enabled)
	await snapshot("05-form-and-quiet-target", Vector3(-1.7, 1.75, -16.8), Vector3(-3.7, 1.5, -20.5), 68)
	hand.global_transform = trial.global_transform * Transform3D(Basis.IDENTITY, Vector3(-3.7, 1.65, -21.9))
	await create_timer(0.1).timeout
	point.action_pressed.emit(point)
	check("trigger sends the actual simplified form", point.projectiles.size() == 1 and point.projectiles[0].form.radial_segments == 4)
	await create_timer(0.55).timeout
	check("physical projectile lights receiver and permits BEGIN", trial.receiver_reached and trial.receiver.lit)
	point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	# All passages retain a floor.
	for at in [Vector3(0, 0, 7), Vector3(0, 0, 0), Vector3(0, 0, -7), Vector3(0, 0, -16), Vector3(0, 0, -26)]:
		var p := trial.to_global(at)
		var hit := trial.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(p + Vector3.UP * 0.1, p + Vector3.DOWN * 0.15, 1))
		check("continuous floor at " + str(at), not hit.is_empty())
	var target := Node3D.new(); trial.arena.add_child(target); target.position = Vector3(0, 1.65, -0.5)
	skull.target_override = target
	for operation in range(1, 4):
		trial.start_button.pressed.emit()
		if operation == 1: await create_timer(2.35).timeout
		check("same head begins operation " + str(operation), skull.get_instance_id() == head_id and skull.active and skull.power == operation and trial.stage == trial.Stage.DEFEND)
		skull.set_physics_process(false)
		skull.advance(2.05, target.global_position)
		check("operation warns before attacking " + str(operation), skull.state == skull.State.TELEGRAPH and skull.cue.visible)
		if operation == 1:
			var lock: Vector3 = skull.destination
			target.position.x = 1.0; skull.advance(0.1, target.global_position)
			check("sidestepping does not retarget the warning", skull.destination.is_equal_approx(lock))
			trial.toggle_rest()
			check("REST stops attack and emission", trial.paused and not skull.active and not point.emission_enabled)
			trial.toggle_rest(); skull.set_physics_process(false)
			check("RESUME keeps round and restores emission", not trial.paused and skull.active and trial.round_number == 1 and point.emission_enabled)
		if operation == 3:
			check("growing head has matching collision size", skull.size_factor > 1 and is_equal_approx(skull.boundary.radius, skull.RADIUS * skull.size_factor))
		await snapshot("06-operation-" + str(operation), Vector3(2, 1.75, -17.6), Vector3(0, 1.5, -21.1), 65)
		skull.position = Vector3(0, 1.65, -3.5)
		hand.global_transform = trial.arena.global_transform * Transform3D(Basis.IDENTITY, Vector3(0, 1.65, -1.5))
		point.global_transform = hand.global_transform; point.pick_up(hand)
		await create_timer(0.1).timeout
		point.action_pressed.emit(point)
		await create_timer(0.65).timeout
		check("real projectile completes round " + str(operation), trial.completed_rounds == operation and not skull.active)
		check("passage opens only after the third operation " + str(operation), gate_hit() == (operation < 3))
		point.let_go(hand, Vector3.ZERO, Vector3.ZERO)
	check("head survives three interrupted operations", is_instance_valid(skull) and skull.interruptions == 3 and trial.stage == trial.Stage.OPEN)
	await snapshot("07-three-operations-a-passage", Vector3(2.7, 1.8, -21.3), Vector3(0, 1.4, -26), 63)
	trial.visitor_override = target
	target.global_position = trial.to_global(Vector3(0, 1.65, -26.5)); trial._process(0)
	check("walking out completes the beginning", trial.stage == trial.Stage.COMPLETE)
	trial.reset_button.pressed.emit(); await create_timer(0.2).timeout
	check("reset removes all local unlocks", not trial.power_unlocked and not trial.joined and not trial.form_studied and not trial.receiver_reached and not point.emission_enabled and not rod.charge_enabled)
	check("reset restores same point and original surface at entrance", point.get_instance_id() == point_id and point.global_position.distance_to(trial.to_global(trial.POINT_START)) < 0.01 and point.sphere.rings == 16)
	check("reset restores same resting head and closed passage", skull.get_instance_id() == head_id and skull.global_position.distance_to(trial.to_global(trial.head_rest)) < 0.01 and gate_hit() and skull.power == 1)
	check("reset clears trace, sculpture, receiver and projectiles", trial.record.is_empty() and trial.sculpture.get_child_count() == 0 and not trial.receiver.lit and point.projectiles.is_empty())
	check("reset clears round state and hand form", trial.completed_rounds == 0 and not trial.ability.formed)
	# Reacquisition works; reset cancels a pending arrival without a late callback.
	trial.unlock_first_catalyst(); trial.joined = true
	var small: Array[Vector3] = [Vector3.ZERO, Vector3.ONE]
	trial.keep_record(small); trial.form_studied = true; trial.receiver_reached = true
	trial.begin_encounter(); await create_timer(0.1).timeout
	trial.reset_trial(); await create_timer(2.3).timeout
	check("reset cancels a head still in transit", trial.stage == trial.Stage.DRAW and not skull.active and trial.completed_rounds == 0)
	check("persistent ability state remains unchanged", manager.has_first_catalyst() == unlocked_before)
	var saved_after := FileAccess.get_file_as_bytes(saved_path) if FileAccess.file_exists(saved_path) else PackedByteArray()
	check("progression save remains byte-for-byte unchanged", saved == saved_after)
	check("museum TraceData remains unchanged", root.get_node("TraceData").saved_traces.size() == saved_traces)
	trial.queue_free(); await process_frame
	check("leaving trial restores persistent ability visibility and processing", global_ability.visible == visible_before and global_ability.is_physics_processing() == process_before)
	finish()

func grab_rod_at_field() -> void:
	var rod: RigidBody3D = trial.rod
	rod.set_process(false)
	hand.global_transform = rod.global_transform; rod.pick_up(hand)
	await create_timer(0.06).timeout
	for i in range(3):
		hand.global_position += trial.field.global_position - rod.get_node("WritingTip").global_position
		await physics_frame

func gate_hit() -> bool:
	return not trial.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(trial.to_global(Vector3(0, 1.4, -24.5)), trial.to_global(Vector3(0, 1.4, -25.5)), 1)).is_empty()

func snapshot(name: String, eye: Vector3, target: Vector3, fov: float) -> void:
	if DisplayServer.get_name() == "headless": return
	camera.global_position = trial.to_global(eye); camera.look_at(trial.to_global(target)); camera.fov = fov; camera.make_current()
	await create_timer(0.35).timeout; await RenderingServer.frame_post_draw
	check("native screenshot camera retained: " + name, root.get_camera_3d() == camera)
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUT + name + ".png"))

func finish() -> void:
	FileAccess.open(OUT + "report.json", FileAccess.WRITE).store_string(JSON.stringify({"checks":checks, "failures":failures, "passed":failures.is_empty(), "scope":"Actual museum/F6 route, XRTools pickup, recorder and projectile contacts; supplied hand poses. No headset or play-quality claim."}, "  "))
	print("CATALYST OPENING ", checks.size() - failures.size(), "/", checks.size())
	quit(0 if failures.is_empty() else 1)
