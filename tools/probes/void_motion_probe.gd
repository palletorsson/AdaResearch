# Actual Void controller and artifact room, exercised with both synthetic sticks.
extends Node

var game: Node3D
var head: XRPositionalTracker
var left: XRControllerTracker
var right: XRControllerTracker
var checks: Array[Dictionary] = []
var trials: Array[Dictionary] = []
var output := "user://"
var capture := false
var old_hz := 60
var room_signature: Dictionary
var measuring := false
var measured_speeds: Array[float] = []
var previous_body := Vector3.ZERO
var jump_events := 0

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output = arg.trim_prefix("--out=")
		if arg == "--capture": capture = true
	old_hz = Engine.physics_ticks_per_second
	process_physics_priority = 300 # Sample after the actual body, on every physics tick.
	head = tracker("head", XRServer.TRACKER_HEAD, "default", Vector3(0,1.65,0))
	left = tracker("left_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(-0.3,1.2,-0.4))
	right = tracker("right_hand", XRServer.TRACKER_CONTROLLER, "aim", Vector3(0.3,1.2,-0.4))
	left.set_input("primary", Vector2.ZERO)
	right.set_input("primary", Vector2.ZERO)
	run.call_deferred()

func _physics_process(delta: float) -> void:
	if not measuring: return
	var after: Vector3 = game.body.global_position
	measured_speeds.append(Vector2(after.x-previous_body.x,after.z-previous_body.z).length()/delta)
	previous_body = after

func tracker(id: String, type: int, pose: String, at: Vector3) -> XRPositionalTracker:
	var item: XRPositionalTracker = XRControllerTracker.new() if type == XRServer.TRACKER_CONTROLLER else XRPositionalTracker.new()
	item.name = id
	item.type = type
	item.set_pose(pose, Transform3D(Basis.IDENTITY,at),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(item)
	return item

func frames(count: int) -> void:
	for i in range(count):
		await get_tree().physics_frame
		await get_tree().process_frame

func check(title: String, okay: bool) -> void:
	checks.append({"name":title, "passed":okay})
	print("[void-motion] ", "PASS " if okay else "FAIL ", title)

func count_jump() -> void:
	jump_events += 1

func start(path: String) -> void:
	game = load(path).instantiate()
	game.force_xr = true
	add_child(game)
	if game.has_node("MotionMeter"): game.get_node("MotionMeter").report_directory = output
	game.scene_loaded()
	game.scene_visible()
	await get_tree().create_timer(3.5).timeout

func signature() -> Dictionary:
	var origin: Node3D = game.get_node("XROrigin3D")
	var move: Node = origin.get_node("LeftHand/XRToolsCollisionHand/MovementDirect")
	var right_move: Node = origin.get_node("RightHand/XRToolsCollisionHand/MovementDirect")
	var turn: Node = origin.get_node("RightHand/XRToolsCollisionHand/MovementTurn")
	return {"move_script":move.get_script().resource_path, "max_speed":move.max_speed, "strafe":move.strafe,
		"right_move_script":right_move.get_script().resource_path, "right_max_speed":right_move.max_speed, "right_strafe":right_move.strafe,
		"body_script":game.body.get_script().resource_path, "jump_script":game.jump.get_script().resource_path,
		"hand_script":origin.get_node("LeftHand/XRToolsCollisionHand/LeftHand").get_script().resource_path,
		"pickup_script":game.pickups[0].get_script().resource_path, "turn_mode":turn.turn_mode,
		"turn_angle":turn.step_turn_angle, "air_control":game.body.ground_control}

func walk(where: String, at: Vector3, input: Vector2, title: String, right_input: Vector2 = Vector2.ZERO) -> void:
	left.set_input("primary",Vector2.ZERO)
	right.set_input("primary",Vector2.ZERO)
	game.place_player(at)
	await frames(15)
	left.set_input("primary",input)
	right.set_input("primary",right_input)
	await frames(30) # Let traction settle before measuring the steady segment.
	measured_speeds.clear()
	previous_body = game.body.global_position
	var measure_from: Vector3 = previous_body
	measuring = true
	await frames(40)
	measuring = false
	var speeds := measured_speeds.duplicate()
	var left_adjusted: Vector2 = XRToolsUserSettings.get_adjusted_vector2(game.get_node("XROrigin3D/LeftHand"),"primary")
	var right_adjusted: Vector2 = XRToolsUserSettings.get_adjusted_vector2(game.get_node("XROrigin3D/RightHand"),"primary")
	var combined := (left_adjusted+Vector2(0,right_adjusted.y)).limit_length(1.0)
	var expected: float = combined.length()*float(signature().max_speed)
	var average := 0.0
	var deviation := 0.0
	for speed in speeds: average += speed / speeds.size()
	for speed in speeds: deviation = maxf(deviation,absf(speed-average))
	trials.append({"place":where,"case":title,"hz":Engine.physics_ticks_per_second,"raw":[input.x,input.y],"raw_right":[right_input.x,right_input.y],"expected_m_s":expected,"mean_m_s":average,"max_deviation_m_s":deviation,"min_m_s":speeds.min(),"max_m_s":speeds.max()})
	# PlayerBody intentionally ignores speeds below 0.1 m/s. Record that edge.
	if expected >= 0.1:
		check("%s / %s at %d Hz: steady speed, no stalls" % [where,title,Engine.physics_ticks_per_second],absf(average-expected)<0.04 and deviation<0.04)
		var travelled: Vector3 = game.body.global_position-measure_from
		var requested: Vector3 = game.camera.global_basis * Vector3(combined.x,0,-combined.y)
		check("%s / %s: correct travel direction" % [where,title],travelled.slide(Vector3.UP).normalized().dot(requested.slide(Vector3.UP).normalized())>0.99)
	else:
		check("%s / %s: neutral deadband stays still" % [where,title],average<0.01)
	left.set_input("primary",Vector2.ZERO)
	right.set_input("primary",Vector2.ZERO)
	await frames(ceili(1.25*Engine.physics_ticks_per_second))
	check("%s / %s: release stops walking" % [where,title],Vector2(game.body.velocity.x,game.body.velocity.z).length()<0.04)

func test_turning(where: String, at: Vector3) -> void:
	var turn: Node = game.get_node("XROrigin3D/RightHand/XRToolsCollisionHand/MovementTurn")
	var saved_snap: bool = XRToolsUserSettings.snap_turning
	XRToolsUserSettings.snap_turning = true
	left.set_input("primary",Vector2.ZERO)
	right.set_input("primary",Vector2.ZERO)
	game.place_player(at)
	await frames(15)
	var heading: float = game.camera.global_rotation.y
	# Snap turning pivots around the eye; the offset capsule moves under it.
	# Test the visitor's position and requested velocity, not capsule rotation.
	var position_before: Vector3 = game.camera.global_position
	right.set_input("primary",Vector2(1,0))
	await frames(3)
	var turned: float = game.camera.global_rotation.y
	check(where+" / right horizontal input uses the museum snap angle",absf(absf(wrapf(turned-heading,-PI,PI))-deg_to_rad(turn.step_turn_angle))<0.001)
	var displacement: Vector3 = game.camera.global_position-position_before
	check(where+" / right horizontal input does not strafe",displacement.slide(Vector3.UP).length()<0.002 and game.body.ground_control_velocity.length()<0.001)
	right.set_input("primary",Vector2.ZERO)
	await frames(8)
	check(where+" / releasing turn stops rotation",absf(wrapf(game.camera.global_rotation.y-turned,-PI,PI))<0.001)
	right.set_input("primary",Vector2(-1,1))
	await frames(3)
	check(where+" / opposite turn works while walking forward",absf(wrapf(game.camera.global_rotation.y-heading,-PI,PI))<0.001 and game.body.velocity.z < -0.5)
	right.set_input("primary",Vector2.ZERO)
	await frames(100)
	XRToolsUserSettings.snap_turning = saved_snap

func run() -> void:
	await start("res://commons/void/motion_room.tscn")
	room_signature = signature()
	check("room reuses the production Void player builder through inheritance", game.get_script().get_base_script().resource_path == "res://commons/void/game.gd")
	check("room has one body and four movement providers",game.get_node("XROrigin3D").find_children("*","CharacterBody3D",true,false).size()==1 and game.body._movement_providers.size()==4)
	check("right walks without strafing and retains the museum speed cap",not room_signature.right_strafe and room_signature.right_max_speed==3.0)
	check("museum drift protection is shared with the movement room",game.find_children("VelocityDeadzone","",true,false).size()==1 and game.find_children("JoystickDeadzoneFix","",true,false).size()==1)
	check("room uses actual coordinate point and line artifacts",game.held_study.scene_file_path.ends_with("point_held.tscn") and game.line_study.get_script().resource_path.ends_with("line_black_box.gd"))
	check("room has no tower loading or floor stream",game.building==null and game.floor_stream==null)
	for hz in [60,90]:
		Engine.physics_ticks_per_second = hz
		await walk("room",Vector3(0,0.06,7),Vector2(0,1),"forward")
		await walk("room",Vector3(0,0.06,7),Vector2(0,0.3),"slow forward")
		await walk("room",Vector3(0,0.06,7),Vector2(0.65,0.65),"diagonal")
		await walk("room",Vector3(0,0.06,7),Vector2.ZERO,"right forward",Vector2(0,1))
		await walk("room",Vector3(0,0.06,-5),Vector2.ZERO,"right backward",Vector2(0,-1))
		await walk("room",Vector3(0,0.06,7),Vector2.ZERO,"right gentle forward",Vector2(0,0.3))
	Engine.physics_ticks_per_second = 90
	await walk("room",Vector3(0,0.06,7),Vector2(0,0.05),"near neutral")
	await walk("room",Vector3(0,0.06,7),Vector2.ZERO,"right near neutral",Vector2(0,0.05))
	await walk("room",Vector3(0,0.06,7),Vector2(0,1),"both forward: speed capped",Vector2(0,1))
	await walk("room",Vector3(0,0.06,7),Vector2(0,1),"opposing sticks cancel",Vector2(0,-1))
	await walk("room",Vector3(0,0.06,4),Vector2(1,0),"left strafe")
	await test_turning("room",Vector3(0,0.06,4))
	game.place_player(Vector3(-4,0.06,2))
	await frames(10)
	var point: Node3D = game.held_study.point
	var local: Vector3 = game.get_node("XROrigin3D").to_local(point.global_position)
	right.set_pose("aim",Transform3D(Basis.IDENTITY,local),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	await frames(6)
	right.set_input("grip",1.0)
	await frames(12)
	check("same rig grips the existing point",game.pickups[1].picked_up_object==point)
	await walk("room",Vector3(0,0.06,7),Vector2(0,0.65),"carrying point")
	await walk("room",Vector3(0,0.06,7),Vector2.ZERO,"right walking while carrying point",Vector2(0,0.65))
	check("walking preserves pickup ownership",game.pickups[1].picked_up_object==point)
	right.set_input("grip",0.0)
	await frames(10)
	check("grip release still drops the point",game.pickups[1].picked_up_object==null)
	game.die("Test reset")
	# Reset places the body above the floor. Wait for actual settled contact,
	# not a fixed delay: XRTools rejects a jump while landing velocity remains.
	var settled_ticks := 0
	for i in range(90):
		await frames(1)
		var vertical_speed: float = (game.body.velocity-game.body.ground_velocity).dot(game.body.ground_vector)
		if game.body.on_ground and game.body.is_on_floor() and absf(vertical_speed)<=0.01:
			settled_ticks += 1
		else:
			settled_ticks = 0
		if settled_ticks >= 3: break
	check("reset settles on the floor before jumping",settled_ticks>=3)
	game.body.player_jumped.connect(count_jump)
	right.set_input("ax_button",true)
	var jump_peak := 0.0
	for i in range(30):
		await frames(1)
		jump_peak = maxf(jump_peak,game.body.global_position.y)
	check("A still jumps",jump_events==1 and jump_peak>0.2)
	await frames(110) # Keep A held through landing: it must not queue another jump.
	check("room has solid landing and does not retrigger jump",game.body.is_on_floor() and jump_events==1)
	right.set_input("ax_button",false)
	game.meter.save_report()
	check("frame and per-tick stick range telemetry exists",game.meter.latest.has("raw_left") and game.meter.latest.has("raw_min") and game.meter.latest.has("frame_p95_ms"))
	check("diagnostic records both sticks and live filter settings",game.meter.latest.has("raw_right") and game.meter.latest.has("raw_right_min") and game.meter.latest.has("stick_rest_offsets") and game.meter.latest.has("snap_turn_deadzone"))
	var room_stats: Dictionary = game.meter.latest.duplicate(true)
	if capture: await picture()
	game.queue_free()
	await frames(5)
	var script := load("res://commons/void/game.gd")
	script.motion_test_requested = true
	await start("res://commons/void/void.tscn")
	check("tower and room have identical movement and grip settings",signature()==room_signature)
	check("comparison request enables tower telemetry once",game.has_node("MotionMeter") and not script.motion_test_requested)
	for hz in [60,90]:
		Engine.physics_ticks_per_second=hz
		await walk("tower",Vector3(2,0.06,6),Vector2(0,1),"forward")
		await walk("tower",Vector3(2,0.06,6),Vector2(0,0.3),"slow forward")
		await walk("tower",Vector3(2,0.06,6),Vector2.ZERO,"right forward",Vector2(0,1))
		await walk("tower",Vector3(2,0.06,0),Vector2.ZERO,"right backward",Vector2(0,-1))
		await walk("tower",Vector3(2,0.06,6),Vector2.ZERO,"right gentle forward",Vector2(0,0.3))
	await test_turning("tower",Vector3(2,0.06,4))
	var tower_stats: Dictionary = game.get_node("MotionMeter").latest.duplicate(true)
	game.queue_free()
	await frames(5)
	for item in [head,left,right]: XRServer.remove_tracker(item)
	Engine.physics_ticks_per_second=old_hz
	var receipt := {"passed":checks.all(func(c):return c.passed),"checks":checks,"trials":trials,"rig":room_signature,"room_sample":room_stats,"tower_sample":tower_stats,"scope":"Real project and real XRTools with synthetic trackers. Desktop rendering timings are not headset performance or worn-stick measurements."}
	FileAccess.open(output.path_join("checks.json"),FileAccess.WRITE).store_string(JSON.stringify(receipt,"\t"))
	get_tree().quit(0 if receipt.passed else 1)

func picture() -> void:
	var camera := Camera3D.new()
	add_child(camera)
	camera.environment=game.atmosphere.environment
	camera.position=Vector3(0,3.4,10)
	camera.look_at(Vector3(0,1,-3))
	camera.make_current()
	await frames(10)
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(output.path_join("room.png"))
	camera.queue_free()
	game.camera.make_current()
