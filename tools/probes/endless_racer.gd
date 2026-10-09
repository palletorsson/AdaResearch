extends SceneTree
var checks: Array=[]
var failures: Array=[]
func _initialize() -> void:run.call_deferred()
func check(title: String,ok: bool) -> void:
	checks.append({"name":title,"passed":ok});print("RACER ",title," ",ok)
	if not ok:failures.append(title)
func frames(n: int) -> void:
	for i in n:await physics_frame
func run() -> void:
	var model=load("res://commons/artifacts/endless_racer/race_model.gd").new()
	for i in 300:model.advance(1.0/60,0,1,0)
	check("Throttle produces forward motion",model.speed>5 and model.distance>10)
	var speed: float=model.speed
	for i in 30:model.advance(1.0/60,0,0,0)
	check("Releasing throttle coasts with resistance",model.speed>0 and model.speed<speed)
	for i in 150:model.advance(1.0/60,0,0,1)
	check("Brake stops without reversing",is_zero_approx(model.speed))
	model.reset();model.speed=15;model.offset=4.14;model.lateral_speed=6;model.advance(0.05,1,1,0)
	check("Rail collision confines the car and reduces speed",model.crashes==1 and model.speed<10 and absf(model.offset)<=model.EDGE)
	model.reset();model.distance=71.8;model.speed=15;model.offset=model.feature(4).lane;model.advance(0.05,0,0,0)
	check("A swept crossing collects a cube once",model.cubes==1 and model.consumed.has(4))
	model.advance(0.05,0,0,0);check("Pickup does not count again",model.cubes==1)
	model.reset();model.distance=119.8;model.speed=15;model.offset=model.feature(7).lane;model.advance(0.05,0,0,0)
	check("Barrier crossing records a hit and slows the car",model.crashes==1 and model.speed<10)
	var world=Node3D.new();root.add_child(world);current_scene=world
	var racer=load("res://commons/artifacts/endless_racer/endless_racer.tscn").instantiate();world.add_child(racer)
	var walker=CharacterBody3D.new();world.add_child(walker);walker.position=Vector3(0,0,2)
	var camera=Camera3D.new();camera.name="Camera3D";camera.position.y=1.65;walker.add_child(camera)
	var home: Transform3D=walker.global_transform
	check("Nearby desktop visitor can board",racer.board(walker));racer.set_physics_process(false)
	check("Boarding preserves museum stream coordinate",is_equal_approx(walker.global_position.z,racer.global_position.z))
	check("Cockpit stays far from the hall",walker.global_position.distance_to(racer.global_position)>2000)
	check("Road uses a fixed section pool",racer.road.sections.size()==model.POOL)
	var nodes: int=racer.road.find_children("*","Node",true,false).size()
	for i in range(2000):
		racer.model.distance=i*50.0;racer.road.sync(racer.model)
	check("100 km does not grow the road tree",racer.road.find_children("*","Node",true,false).size()==nodes)
	var span:=true
	for s in racer.road.sections:
		if absf(s.position.z)>500 or absf(s.position.x)>100:span=false
	check("Recycled geometry remains close to the cockpit",span)
	racer.model.consumed={4:true,10:true};racer.model.advance(0.01,0,0,0)
	check("Old collectible state is pruned",racer.model.consumed.is_empty())
	check("Desktop locomotion yields to the cockpit",racer.carry_velocity(walker,0.02,Vector3.ONE)==Vector3.ZERO)
	racer.restart();check("Restart returns to a three-second start",racer.countdown==3 and racer.model.distance==0)
	racer.leave();await frames(3)
	check("Exit restores desktop pose",walker.global_transform.is_equal_approx(home))
	check("Exit removes the whole racing pocket",root.get_node_or_null("EndlessDrivePocket")==null)
	walker.queue_free();await frames(2)
	# Use the production XRTools body and grab drivers with supplied poses.
	var origin=XROrigin3D.new();origin.current=true;world.add_child(origin)
	var right_tracker=XRControllerTracker.new();right_tracker.name=&"right_hand";right_tracker.type=XRServer.TRACKER_CONTROLLER;XRServer.add_tracker(right_tracker)
	var left_tracker=XRControllerTracker.new();left_tracker.name=&"left_hand";left_tracker.type=XRServer.TRACKER_CONTROLLER;XRServer.add_tracker(left_tracker)
	var head=XRCamera3D.new();head.name="Camera";head.position=Vector3(0,1.3,0);origin.add_child(head)
	var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate();body.player_calibrate_height=false;body.eye_forward_offset=0;origin.add_child(body)
	var controller=XRController3D.new();controller.tracker=&"right_hand";origin.add_child(controller)
	var left=XRController3D.new();left.tracker=&"left_hand";origin.add_child(left)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	await frames(3);body.set_physics_process(false)
	var xr_home: Transform3D=body.global_transform;var head_home: Transform3D=head.global_transform
	check("The existing XR body can board",racer.board(body));await frames(2)
	check("Seating installs an exclusive movement provider",racer.seat_adapter in body._movement_providers and racer.seat_adapter.order<0)
	right_tracker.set_input("trigger",0.75);left_tracker.set_input("trigger",0.35);await frames(2)
	var trigger_values: Vector3=racer.read_controls(0.02)
	check("Right and left trigger inputs map independently to throttle and brake",is_equal_approx(trigger_values.y,0.75) and is_equal_approx(trigger_values.z,0.35))
	right_tracker.set_input("trigger",0.0);left_tracker.set_input("trigger",0.0)
	var start_seat: Vector3=body.global_position;var start_origin: Transform3D=origin.global_transform
	for i in 10:
		body.ground_control_velocity=Vector2(1,1);body.velocity=Vector3(4,0,4)
		racer.seat_adapter.physics_movement(1.0/60,body,false);await physics_frame
	check("XR thumbstick locomotion cannot drive the collision body out of the car",body.global_position.distance_to(start_seat)<0.01 and origin.global_transform.is_equal_approx(start_origin))
	var grip=racer.grips[1];controller.global_position=grip.global_position;grip.pick_up(hand);await frames(3)
	racer.read_controls(0.02)
	controller.global_position=racer.wheel_frame.to_global(Vector3(cos(-0.7),sin(-0.7),0)*0.27);await frames(4)
	var controls: Vector3=racer.read_controls(0.02)
	check("Moving the held XR wheel handle steers right",grip.is_picked_up() and controls.x>0.4)
	var local_head: Transform3D=head.transform;head.position.x+=0.08
	check("The headset remains free to lean",not head.transform.is_equal_approx(local_head))
	grip.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames(2);racer.read_controls(0.05);racer.sync_grips()
	check("Released grip returns to the wheel",grip.global_position.distance_to(racer.wheel.to_global(Vector3(0.27,0,0)))<0.01)
	head.transform=local_head
	racer.leave();await frames(2)
	check("XR return restores the original rig and head pose",body.global_transform.is_equal_approx(xr_home) and head.global_transform.is_equal_approx(head_home))
	check("Return removes the seat movement override",body._movement_providers.filter(func(p):return p.get_script()==load("res://commons/artifacts/endless_racer/seat_provider.gd")).is_empty())
	XRServer.remove_tracker(right_tracker);XRServer.remove_tracker(left_tracker)
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"scope":"Arcade model, fixed pool over 100 km, desktop transfer, production XRTools body and grab driver with supplied poses. Physical headset feel not tested."}
	FileAccess.open("res://ada_run/endless_racer_tests.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	quit(0 if failures.is_empty() else 1)
