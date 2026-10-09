extends SceneTree
## Integration checks in the standalone project, using real physics and XR Tools.
## Synthetic controller trackers test wiring; they do not certify a headset.

var checks: Array = []
var failed := false
var destination := ""

func _initialize() -> void:
	destination = OS.get_cmdline_user_args()[0]
	call_deferred("run")

func check(label: String, result: bool) -> void:
	checks.append({"check": label, "passed": result})
	if not result:
		failed = true
		push_error(label)

func frames(count: int) -> void:
	for i in count:
		await physics_frame
	await process_frame

func pose(tracker: XRPositionalTracker, at: Vector3) -> void:
	tracker.set_pose("grip", Transform3D(Basis.IDENTITY, at), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func run() -> void:
	var room = load("res://main.tscn").instantiate()
	root.add_child(room)
	await frames(40)
	check("No headset selects desktop", not room.xr_active)
	var player = room.player
	var cube = room.test_cube
	check("Prepared floor supports desktop player", absf(player.position.y) < 0.05)
	check("Cube rests on plinth", absf(cube.position.y - 1.175) < 0.025)
	var study = room.get_node("Study")
	var before: int = study.count
	await frames(4)
	check("Unchanged Point Zero script creates one display", study.get_child_count() == 1 and study.get_child(0) is Label3D)
	check("Point Zero counter progresses in shared room", study.count > before and study.display.text == str(study.count))
	check("Desktop view is the active camera", root.get_camera_3d() == player.camera)
	if DisplayServer.get_name() != "headless":
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(destination.path_join("room.png"))
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	var start: Vector3 = player.position
	Input.action_press("move_forward")
	await frames(40)
	Input.action_release("move_forward")
	check("Walk input moves through room", player.position.z < start.z - 0.5)
	player.position = Vector3(3.5, 0, 2.5)
	Input.action_press("move_right")
	await frames(45)
	Input.action_release("move_right")
	check("Walls stop the desktop body", player.position.x < 3.7)
	player.position = Vector3(-1.65, 0, 1.45)
	player.rotation = Vector3.ZERO
	player.camera.look_at(cube.global_position)
	await frames(3)
	player.interact()
	await frames(4)
	check("Desktop ray can pick up cube", cube.is_picked_up() and player.grabber.picked_up_object == cube)
	check("Pickup freezes rigid body", cube.freeze)
	var held_position: Vector3 = cube.position
	player.position.x += 0.6
	await frames(4)
	check("Held object follows desktop holder", cube.position.x > held_position.x + 0.4)
	player.interact()
	await frames(4)
	check("Drop restores gravity and pickable layer", not cube.is_picked_up() and not cube.freeze and cube.collision_layer == 4)
	room.reset_cube()
	await frames(40)
	check("Reset returns dropped cube to plinth", cube.position.distance_to(Vector3(-1.65, 1.175, -0.2)) < 0.04)
	player.position = Vector3(-1.65, 0, 1.45)
	player.camera.look_at(cube.global_position)
	player.interact()
	await frames(3)
	room.reset_cube()
	await frames(3)
	check("Reset also clears held state", not cube.is_picked_up() and player.grabber.picked_up_object == null)
	# Put the cube behind the side wall and aim at it from within reach.
	cube.freeze = true
	cube.position = Vector3(4.3, 1.5, 2)
	player.position = Vector3(3.5, 0, 2)
	player.camera.look_at(cube.global_position)
	await frames(3)
	player.interact()
	check("Desktop cannot pick up through architecture", not cube.is_picked_up())
	cube.freeze = false
	room.reset_cube()
	player.set_physics_process(false)
	player.set_process_unhandled_input(false)

	# Register synthetic controllers with the same action names as OpenXR.
	var left := XRControllerTracker.new()
	left.name = "left_hand"
	left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	var right := XRControllerTracker.new()
	right.name = "right_hand"
	right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	pose(left, Vector3(-0.4, 1.3, -0.5))
	pose(right, Vector3(0.4, 1.3, -0.5))
	left.set_input("primary", Vector2.ZERO)
	right.set_input("primary", Vector2.ZERO)
	left.set_input("grip", 0.0)
	right.set_input("grip", 0.0)
	XRServer.add_tracker(left)
	XRServer.add_tracker(right)
	var rig = load("res://prepared/xr_player.gd").new()
	rig.position = Vector3(1, 0, 0)
	rig.camera.position.y = 1.65 # Synthetic eye height, not a tracked-head test.
	room.add_child(rig)
	await frames(5)
	check("XR camera and controllers share one origin", rig.camera.get_parent() == rig and rig.left.get_parent() == rig and rig.right.get_parent() == rig)
	check("Both XR controllers receive synthetic grip poses", rig.left.get_is_active() and rig.right.get_is_active())
	check("XR Tools discovers both locomotion providers", rig.body._movement_providers.size() == 2)
	check("XR rig uses near grip on both hands", rig.pickups.size() == 2 and not rig.pickups[0].ranged_enable and not rig.pickups[1].ranged_enable)
	for hand in 2:
		var tracker = left if hand == 0 else right
		var pickup = rig.pickups[hand]
		cube.freeze = true
		cube.global_position = pickup.global_position
		await frames(5)
		tracker.set_input("grip", 1.0)
		await frames(5)
		check("Synthetic hand %d picks up through grip input" % hand, pickup.picked_up_object == cube and cube.is_picked_up())
		var was: Vector3 = cube.global_position
		pose(tracker, Vector3(-0.4 if hand == 0 else 0.4, 1.6, -0.5))
		await frames(5)
		check("Synthetic hand %d carries cube with tracked pose" % hand, cube.global_position.y > was.y + 0.2)
		tracker.set_input("grip", 0.0)
		await frames(5)
		check("Synthetic hand %d releases cube" % hand, not cube.is_picked_up() and pickup.picked_up_object == null)
		cube.freeze = false
		room.reset_cube()
	left.set_input("primary", Vector2(0, 1))
	var rig_start: Vector3 = rig.global_position
	await frames(30)
	left.set_input("primary", Vector2.ZERO)
	check("Synthetic left stick moves XR body", rig.global_position.z < rig_start.z - 0.2)
	var basis_before: Basis = rig.basis
	right.set_input("primary", Vector2(1, 0))
	await frames(5)
	right.set_input("primary", Vector2.ZERO)
	check("Synthetic right stick snap turns", not rig.basis.is_equal_approx(basis_before))
	rig.set_input_active(false)
	check("Focus loss disables body and pickups", not rig.body.enabled and not rig.pickups[0].enabled and not rig.pickups[1].enabled)
	rig.set_input_active(true)
	check("Focus return enables body and pickups", rig.body.enabled and rig.pickups[0].enabled and rig.pickups[1].enabled)
	var reset_calls := [0]
	rig.reset_requested.connect(func(): reset_calls[0] += 1)
	right.set_input("by_button", true)
	await frames(2)
	check("B/Y action reaches reset signal", reset_calls[0] == 1)
	rig.queue_free()
	await frames(3)
	XRServer.remove_tracker(left)
	XRServer.remove_tracker(right)
	room.queue_free()
	await frames(3)
	FileAccess.open(destination.path_join("verification.json"), FileAccess.WRITE).store_string(JSON.stringify({
		"godot": Engine.get_version_info().string,
		"checks": checks, "passed": not failed,
		"headset_tested": false, "standalone_quest_tested": false,
		"xr_input": "Synthetic XRControllerTrackers; no physical headset or tracked head"
	}, "\t"))
	print("Starter checks: ", checks.size(), " / passed: ", not failed)
	quit(1 if failed else 0)
