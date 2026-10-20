extends SceneTree
const Motion = preload("res://commons/artifacts/random_touch/motion_record.gd")
var failures: Array[String] = []
func check(ok: bool, reason: String) -> void:
	if not ok: failures.append(reason)
func _initialize() -> void: call_deferred("run")
func run() -> void:
	var r := Motion.make_record(435)
	check(Motion.valid(r),"Default ride record valid")
	check(r == Motion.make_record(435),"Seed repeats targets")
	check(r.points != Motion.make_record(436).points,"New seed changes targets")
	for i in 500:
		var t := i * 0.137
		var slow := Motion.offset(r,0,t)
		var fast := Motion.offset(r,1,t/2)
		var xy := Motion.offset(r,2,t)
		check(slow.is_equal_approx(fast),"Speed changes timing, not sideways path")
		check(is_equal_approx(slow.x,xy.x),"Adding Y preserves X at equal ride time")
		check(absf(slow.x)<=1 and slow.y==0 and slow.z==0 and xy.y>=0 and xy.y<=1,"Two-metre X and upward Y bounds")
	check(Motion.offset(r,0,0)==Vector3.ZERO,"Ride starts on the line centre")
	check(Motion.offset(r,0,0).is_equal_approx(Motion.offset(r,0,60)),"Loop seam repeats")
	var bad := r.duplicate(true)
	bad.points[0][0] = 100
	check(not Motion.valid(bad),"Reject out-of-bounds path")
	bad = r.duplicate(true)
	bad.schema = "random-touch/1"
	check(not Motion.valid(bad),"Old autonomous study is not silently reinterpreted")

	var scene = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	root.add_child(scene)
	scene.set_physics_process(false)
	check(scene.points.size()==3 and scene.areas.size()==3 and scene.lines.size()==3,"Three interactive lines")
	for lane in 3:
		check(scene.lines[lane].mesh.size==Vector3(2,.012,.012),"Bare two-metre line")
		check(scene.points[lane].position==scene.HOMES[lane],"Sphere rests on line centre")
		if lane>0: check(is_equal_approx(scene.HOMES[lane].distance_to(scene.HOMES[lane-1]),1),"Lines one metre apart")
	var direct_meshes := 0
	for child in scene.get_children():
		if child is MeshInstance3D: direct_meshes += 1
	check(direct_meshes==3,"No plates behind the lines")
	scene.advance(20)
	check(scene.times==[0.0,0.0,0.0] and scene.active_lane==-1,"Idle never runs the rides")

	var body := CharacterBody3D.new()
	var shape := CollisionShape3D.new()
	var capsule := CapsuleShape3D.new()
	capsule.radius=.15; capsule.height=.6; shape.shape=capsule
	body.add_child(shape)
	body.position=Vector3(0,.31,1.3)
	root.add_child(body)
	var pointer := Node3D.new()
	body.add_child(pointer)
	scene.points[0].on_desktop_grab(pointer)
	scene._sync_rider()
	check(scene.active_lane==0 and scene.rider==body,"Desktop grab activates receiver")
	var start := body.position
	scene.advance(.25)
	var v: Vector3 = scene.carry_velocity(body,.25,Vector3.ZERO)
	check(absf(v.x)>0 and v.z==0,"First ride supplies X movement")
	check(body.position==start,"Artifact never teleports the player")
	check(scene.times[1]==0 and scene.times[2]==0,"Other lines remain waiting")
	var captured: Dictionary = scene.capture()
	check(Motion.valid(captured),"Active ride capture valid")
	scene.act(0)
	check(scene.active_lane==0 and scene.times[0]==.25,"Replay cannot reset a held rider")
	check(not scene.restore(r),"Load cannot reset a held rider")
	scene.points[0].on_desktop_drop()
	scene._sync_rider()
	check(scene.active_lane==-1 and not scene._point_inside(body.global_position),"Drop immediately releases carry")
	check(scene.carry_velocity(body,.1,Vector3(2,-1,3))==Vector3(2,-1,3),"Released controller owns locomotion")
	scene.advance(5)
	scene._sync_rider()
	check(scene.points[0].position==scene.HOMES[0] and scene.times[0]==0,"Unridden sphere returns to its reachable wait position")
	check(scene.restore(JSON.parse_string(JSON.stringify(captured))),"Recorded ride restores")
	check(scene.paused and scene.times[0]==.25,"Load pauses at saved phase")
	check(scene.points[0].position.is_equal_approx(scene.HOMES[0]+Motion.offset(r,0,.25)),"Saved pose restored")
	check(not scene.restore(bad) and scene.times[0]==.25,"Invalid load retains state")
	scene.save_path="user://random-touch-test-%d.json" % Time.get_ticks_usec()
	scene.act(2)
	scene.act(0)
	scene.advance(4)
	check(scene.times==[0.0,0.0,0.0],"Replay arms stationary spheres; still needs touch")
	scene.act(3)
	check(scene.paused and scene.times[0]==.25,"KEEP/LOAD preserves per-line phase")
	DirAccess.remove_absolute(scene.save_path)

	# Real touch overlap, with a controller-associated body in the same XR origin.
	scene.act(0)
	var origin := XROrigin3D.new()
	root.add_child(origin)
	var camera := XRCamera3D.new()
	origin.add_child(camera)
	camera.position.y=1.6
	var xr_receiver = load("res://addons/godot-xr-tools/player/player_body.gd").new()
	origin.add_child(xr_receiver)
	xr_receiver.add_to_group("player_body")
	xr_receiver.set_physics_process(false)
	scene.install_adapter()
	scene.install_adapter()
	var adapter = xr_receiver.get_node_or_null("FieldCarryAdapter")
	check(adapter!=null and xr_receiver._movement_providers.count(adapter)==1,"XR carry adapter installed exactly once")
	var controller := XRController3D.new()
	origin.add_child(controller)
	var hand := StaticBody3D.new()
	hand.collision_layer=131072
	hand.collision_mask=0
	var hand_shape := CollisionShape3D.new()
	var hand_ball := SphereShape3D.new()
	hand_ball.radius=.04; hand_shape.shape=hand_ball
	hand.add_child(hand_shape)
	controller.add_child(hand)
	hand.global_position=scene.points[0].global_position
	await physics_frame
	await physics_frame
	check(scene._controller(hand)==controller and scene._touch_receiver(hand)==xr_receiver,"Touch resolves its own XR receiver")
	scene._sync_rider()
	check(scene.active_lane==0 and scene.contact==hand,"Physical hand overlap starts ride without grip")
	hand.position=Vector3(10,10,10)
	await physics_frame
	await physics_frame
	scene._sync_rider()
	check(scene.active_lane==-1,"Withdrawing hand stops ride")
	scene.advance(5)
	scene._sync_rider()
	hand.global_position=scene.points[2].global_position
	await physics_frame
	await physics_frame
	scene._sync_rider()
	var origin_start := origin.global_position
	for i in 20:
		await physics_frame
		scene.advance(1.0/60)
		adapter.physics_movement(1.0/60,xr_receiver,false)
		scene._sync_rider()
	check(scene.active_lane==2 and origin.global_position.y>origin_start.y,"XR adapter moves origin and retains touch during vertical ride")
	hand.position=Vector3(10,10,10)
	await physics_frame
	await physics_frame
	scene._sync_rider()
	origin.queue_free()
	await process_frame
	scene.advance(5)
	scene._sync_rider()
	scene.act(0)

	# The same velocity contract moves a real colliding CharacterBody, including Y.
	var floor_body := StaticBody3D.new()
	var floor_shape := CollisionShape3D.new()
	var floor_box := BoxShape3D.new()
	floor_box.size=Vector3(20,.2,20); floor_shape.shape=floor_box
	floor_body.add_child(floor_shape); floor_body.position.y=-.1
	root.add_child(floor_body)
	body.position=Vector3(0,.31,-.7)
	scene.points[2].on_desktop_grab(pointer)
	scene._sync_rider()
	var max_height := body.position.y
	for i in 100:
		await physics_frame
		scene.advance(1.0/60)
		body.velocity=scene.carry_velocity(body,1.0/60,body.velocity)
		body.move_and_slide()
		scene._sync_rider()
		max_height=maxf(max_height,body.position.y)
	check(scene.active_lane==2 and max_height>.4,"Third ride actually lifts a colliding body")
	check(body.position.y>=.29,"Floor remains solid")
	scene.points[2].on_desktop_drop()
	scene._sync_rider()
	check(scene.active_lane==-1 and body.velocity.y<=0,"Release cancels upward carry")
	scene.advance(5)
	scene._sync_rider()
	scene.act(0)

	# Put a wall between an active rider and a prescribed target.
	var wall := StaticBody3D.new()
	var wall_shape := CollisionShape3D.new()
	var wall_box := BoxShape3D.new()
	wall_box.size=Vector3(.1,3,3); wall_shape.shape=wall_box
	wall.add_child(wall_shape); wall.position=Vector3(.4,1.5,1)
	root.add_child(wall)
	body.position=Vector3(0,.31,1.3)
	scene.points[0].on_desktop_grab(pointer)
	scene._sync_rider()
	scene.offsets[0]=Vector3(.9,0,0)
	scene._update_pose()
	for i in 20:
		await physics_frame
		body.velocity=scene.carry_velocity(body,1.0/60,body.velocity)
		body.move_and_slide()
	check(body.position.x<.23,"Carry respects a wall, without teleportation")
	scene._sync_rider()
	check(scene.active_lane==-1,"Blocked rider detaches when prescribed path leaves reach")

	scene.queue_free(); body.queue_free(); floor_body.queue_free(); wall.queue_free()
	await process_frame
	if failures.is_empty(): print("PASS: random touch idle, geometry, contact, carry, collision, release, replay and recording")
	else:
		for failure in failures: push_error(failure)
	quit(0 if failures.is_empty() else 1)
