extends SceneTree
const Motion = preload("res://commons/artifacts/random_touch/motion_record.gd")
var failures: Array[String] = []
func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var record := Motion.make_record(435)
	check(Motion.valid(record) and record == Motion.make_record(435),"Retained seed reproduces targets")
	for i in 500:
		var t := i*0.137
		for lane in 4:
			var at := Motion.offset(record,lane,t*0.8/Motion.RATES[lane])
			check(at.is_equal_approx(Motion.offset(record,1,t)),"All four speeds preserve the same X sequence")
			check(at.y==0 and absf(at.x)<=.44,"Four horizontal rows stay inside the rods")
		var planar := Motion.offset(record,4,t)
		check(is_equal_approx(Motion.offset(record,1,t).x,planar.x),"Fifth row adds Y at the baseline speed")
		check(absf(planar.y)<=.12,"Vertical movement stays within its own row")
	var legacy := record.duplicate(true)
	legacy.schema="random-touch/2"
	check(not Motion.valid(legacy),"Old three-line records are not silently reinterpreted")
	var scene = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	check(not scene.is_in_group("ada_museum_carry"),"Touch never registers as a body-carry provider")
	check(scene.points.size()==5 and scene.lines.size()==5,"Five abacus rows")
	for lane in 5:
		check(scene.lines[lane].mesh.size.x==1,"Compact one-metre rods")
		check(scene.points[lane].sphere.radius<.08,"Small abacus beads")
		check(scene.HOMES[lane].z==0,"All rows share one plane")
		if lane>0: check(scene.HOMES[lane].y<scene.HOMES[lane-1].y,"Rows read top to bottom")
	scene.advance(10)
	check(scene.times==[0.0,0.0,0.0,0.0,0.0],"Idle lines wait")
	var body := CharacterBody3D.new()
	body.position=Vector3(4,0,4)
	body.velocity=Vector3(1,2,3)
	root.add_child(body)
	var pointer := Node3D.new()
	body.add_child(pointer)
	scene.points[0].on_desktop_grab(pointer)
	scene._sync_hand()
	scene.advance(.25)
	check(scene.active_lane==0 and scene.offsets[0]!=Vector3.ZERO,"Desktop starts the demonstration")
	check(body.position==Vector3(4,0,4) and body.velocity==Vector3(1,2,3),"Desktop body and velocity untouched")
	var saved: Dictionary = scene.capture()
	check(Motion.valid(saved),"Active hand motion can be retained")
	check(not scene.restore(record),"Active interaction cannot load over hand")
	scene.act(0)
	check(scene.times[0]==.25,"Replay refuses to reset active interaction")
	scene.points[0].on_desktop_drop()
	scene._sync_hand()
	check(scene.active_lane==-1 and body.velocity==Vector3(1,2,3),"Release leaves locomotion alone")
	scene.advance(5)
	check(scene.points[0].position==scene.HOMES[0],"Sphere returns to waiting centre")
	check(scene.restore(JSON.parse_string(JSON.stringify(saved))),"Retained hand motion restores")
	check(scene.paused and scene.times[0]==.25,"Load restores phase paused")
	scene.save_path="user://random-touch-hand-%d.json" % Time.get_ticks_usec()
	scene.act(2); scene.act(0); scene.act(3)
	check(scene.paused and scene.times[0]==.25,"KEEP/LOAD round trip")
	DirAccess.remove_absolute(scene.save_path)
	scene.act(0)
	var five_phases := record.duplicate(true)
	five_phases.seconds=[.3,.7,1.1,1.8,2.4]
	for lane in 5:
		var offset := Motion.offset(five_phases,lane,five_phases.seconds[lane])
		five_phases.offsets[lane]=[offset.x,offset.y]
	check(five_phases.offsets[4][1]<0,"Fifth-row fixture includes motion below the rod")
	check(scene.restore(JSON.parse_string(JSON.stringify(five_phases))),"All five distinct phases restore")
	check(scene.capture().seconds==five_phases.seconds and scene.capture().offsets==five_phases.offsets,"Every row retains its own phase and position")
	scene.act(0)

	# Exercise the actual XR collision/visual hand implementation, not a stub.
	var origin := XROrigin3D.new()
	root.add_child(origin)
	var camera := XRCamera3D.new()
	origin.add_child(camera)
	camera.position.y=1.6
	var controller := XRController3D.new()
	controller.tracker="left_hand"
	origin.add_child(controller)
	var hand = load("res://addons/godot-xr-tools/hands/scenes/collision/collision_hand.tscn").instantiate()
	controller.add_child(hand)
	var visual = load("res://addons/godot-xr-tools/hands/scenes/lowpoly/left_hand_low.tscn").instantiate()
	hand.add_child(visual)
	var other_controller := XRController3D.new()
	other_controller.tracker="right_hand"
	origin.add_child(other_controller)
	other_controller.position=Vector3(2,1.3,0)
	var other_hand = load("res://addons/godot-xr-tools/hands/scenes/collision/collision_hand.tscn").instantiate()
	other_controller.add_child(other_hand)
	controller.global_position=scene.points[4].global_position+Vector3(0,.02,-.05)
	for i in 4: await physics_frame
	scene._sync_hand()
	check(scene.active_lane==4,"Real hand overlap starts fifth-row motion without grip")
	check(scene.follower.installed,"Target override installed on contacting hand")
	var origin_start := origin.global_transform
	var camera_start := camera.global_transform
	var tracked_start := controller.global_transform
	var other_start: Transform3D = other_hand.global_transform
	# Let the override settle before measuring; collision settling is not motion.
	for i in 4: await physics_frame
	await process_frame
	var visual_start: Vector3 = visual.global_position
	var offset_start: Vector3 = scene.offsets[4]
	for i in 90:
		scene.advance(1.0/60.0)
		await physics_frame
		scene._sync_hand()
	await process_frame
	check(scene.active_lane==4,"Virtual displacement does not falsely end contact")
	var expected_displacement: Vector3 = scene.offsets[4]-offset_start
	check(expected_displacement.length()>.001,"Fixture includes nonzero X/Y motion")
	check((visual.global_position-visual_start).is_equal_approx(expected_displacement),"Contacting virtual hand follows the prescribed X/Y displacement")
	check(origin.global_transform==origin_start and camera.global_transform==camera_start,"XR origin and head never move")
	check(controller.global_transform==tracked_start,"Actual controller tracking never changes")
	check(other_hand.global_transform.is_equal_approx(other_start),"Other hand stays tracked normally")
	check(body.position==Vector3(4,0,4) and body.velocity==Vector3(1,2,3),"Player body remains unaffected")
	controller.position.z+=.3
	scene._sync_hand()
	check(scene.active_lane==-1 and not scene.follower.installed,"Physical withdrawal releases virtual hand")
	for i in 3: await physics_frame
	check(hand._target==controller and visual._target==hand,"Release restores ordinary hand targets")
	check(not controller.has_meta("random_touch_owner"),"Hand ownership cleaned up")
	scene.advance(5); scene._sync_hand(); scene.act(0)
	controller.global_position=scene.points[0].global_position+Vector3(0,.02,-.05)
	for i in 4: await physics_frame
	scene._sync_hand()
	check(scene.active_lane==0,"Hand can begin another line")
	scene.act(1)
	check(not scene.follower.installed and hand._target==controller,"Pause releases the hand")
	scene.act(0)
	scene.blocked[0]=false
	check(scene.begin_motion(0,controller),"Reattachment fixture")
	scene.queue_free()
	await process_frame
	check(hand._target==controller and visual._target==hand,"Deleting artifact removes all hand overrides")
	origin.queue_free(); body.queue_free()
	await process_frame
	for failure in failures: push_error(failure)
	print("RANDOM TOUCH HAND: ","PASS" if failures.is_empty() else failures)
	quit(0 if failures.is_empty() else 1)
