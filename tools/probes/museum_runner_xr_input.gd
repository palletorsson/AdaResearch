extends RefCounted
## Exercise XRServer -> XRController3D -> the live runner physics loop.
## Synthetic controller values; no call to steer_axis and no physical HMD claim.

static func run(game: Node3D, check: Callable, physics_rate := 0) -> void:
	var tree := game.get_tree()
	var original_rate := Engine.physics_ticks_per_second
	if physics_rate>0: Engine.physics_ticks_per_second = physics_rate
	var original_vr: bool = game.vr
	# The real menu already owns an origin when it opens the runner.
	var staging_origin := XROrigin3D.new()
	tree.root.add_child(staging_origin)
	staging_origin.current = true
	game.vr = true
	game.scene_loaded()
	check.call("XR entry transfers current origin from staging to runner",game.get_node("XROrigin3D").current and not staging_origin.current)
	staging_origin.free()
	game.vr = original_vr
	var trackers: Array[XRControllerTracker] = []
	for side in ["left_hand", "right_hand"]:
		var tracker := XRControllerTracker.new()
		tracker.type = XRServer.TRACKER_CONTROLLER
		tracker.name = side
		tracker.set_pose("aim",Transform3D.IDENTITY,Vector3.ZERO,Vector3.ZERO,2)
		tracker.set_input("primary",Vector2.ZERO)
		tracker.set_input("ax_button",false)
		XRServer.add_tracker(tracker)
		trackers.append(tracker)
	var left: XRController3D = game.get_node("XROrigin3D/LeftHand")
	var right: XRController3D = game.get_node("XROrigin3D/RightHand")
	var original_probe: RefCounted = game.input_probe
	var probe_path := "user://museum-runner/test-input-debug.json"
	game.input_probe = load("res://commons/museum_runner/input_probe.gd").new(game,probe_path)
	game.reset_run(false)
	trackers[1].set_input("ax_button",true)
	trackers[1].set_input("ax_button",false)
	await tree.physics_frame
	check.call("XR tracker button starts through XRController3D",game.state==game.State.RUNNING)
	# Exercise both render-mode branches with exactly the same XR input path.
	for vr_mode in [true,false]:
		game.vr = vr_mode
		for index in range(2):
			game.reset_run()
			for chunk in game.chunks:
				for obstacle in chunk.hazards: obstacle.collision_layer = 0
			trackers[0].set_input("primary",Vector2.ZERO)
			trackers[1].set_input("primary",Vector2.ZERO)
			trackers[index].set_input("primary",Vector2(0.9,0))
			await frames(tree,20)
			var controller := left if index==0 else right
			var label := "%s stick / VR=%s" % ["left" if index==0 else "right",vr_mode]
			check.call(label+": controller receives the action",is_equal_approx(controller.get_vector2("primary").x,0.9))
			var observation: Dictionary = game.input_probe.snapshot()
			check.call(label+": diagnostics preserve raw action and running state",observation.state=="RUNNING" and is_equal_approx(observation.hands[index].raw[0],0.9) and observation.lane==1)
			check.call(label+": live physics moves the sphere right",game.lane==1 and game.runner.position.x>2.0)
			trackers[index].set_input("primary",Vector2(-0.9,0))
			await frames(tree,38)
			check.call(label+": held reversal crosses to the left lane",game.lane==-1 and game.runner.position.x < -2.0)
			trackers[index].set_input("primary",Vector2.ZERO)
			await frames(tree,3)
			check.call(label+": release rearms steering",game.axis_armed)
	game.reset_run()
	for chunk in game.chunks:
		for obstacle in chunk.hazards: obstacle.collision_layer = 0
	trackers[0].set_input("primary",Vector2(0.2,0.95))
	await frames(tree,5)
	check.call("XR vertical input and horizontal drift do not change lanes",game.lane==0)
	trackers[0].set_input("primary",Vector2(-0.9,0))
	trackers[1].set_input("primary",Vector2(0.9,0))
	await frames(tree,20)
	check.call("opposing sticks choose one direction without fighting",game.lane==-1 and game.runner.position.x < -2.0)
	game.toggle_pause()
	var before: Vector3 = game.runner.position
	trackers[0].set_input("primary",Vector2.ZERO)
	await frames(tree,20)
	check.call("paused XR input cannot move the runner",game.runner.position==before and game.lane==-1)
	trackers[1].set_input("primary",Vector2.ZERO)
	game.primary_action()
	XRServer.remove_tracker(trackers[0])
	trackers[1].set_input("primary",Vector2(0.9,0))
	await frames(tree,38)
	check.call("right stick works when the left controller is disconnected",game.lane==1 and game.runner.position.x>2.0)
	XRServer.remove_tracker(trackers[1])
	await frames(tree,3)
	check.call("disconnecting the active controller clears its steering value",is_zero_approx(game._steering_input()) and game.axis_armed)
	var recorded: Variant = JSON.parse_string(FileAccess.get_file_as_string(probe_path))
	check.call("input diagnostics persist version, samples and button evidence",recorded is Dictionary and recorded.get("revision")==game.INPUT_REVISION and not recorded.get("samples",[]).is_empty() and recorded.samples[-1].buttons==1)
	game.input_probe = original_probe
	DirAccess.remove_absolute(ProjectSettings.globalize_path(probe_path))
	game.vr = original_vr
	game.reset_run(false)
	Engine.physics_ticks_per_second = original_rate

static func frames(tree: SceneTree, frames_at_60hz: int) -> void:
	# Keep the input held for the same time at desktop 60 Hz and Quest 90 Hz.
	for frame in range(ceili(frames_at_60hz*Engine.physics_ticks_per_second/60.0)):
		await tree.physics_frame
