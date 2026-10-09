extends SceneTree
var checks: Array=[]
var failures: Array=[]
var measurements: Dictionary={}
func _initialize() -> void: run.call_deferred()
func check(message: String,good: bool) -> void:
	checks.append({"name":message,"passed":good})
	if not good:failures.append(message);push_error(message)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var floor_body=StaticBody3D.new();world.add_child(floor_body)
	var col=CollisionShape3D.new();var shape=BoxShape3D.new();shape.size=Vector3(100,0.1,100);col.shape=shape;col.position.y=-0.05;floor_body.add_child(col)
	for yaw in [0,90,180]:
		var e=load("res://commons/artifacts/human_catapult/human_catapult.tscn").instantiate()
		e.position=Vector3(5,0,-7);e.rotation_degrees.y=yaw;world.add_child(e);await frames(3)
		var b=CharacterBody3D.new();b.name="ProbeWalker";b.add_to_group("em_walker");b.collision_layer=1;b.collision_mask=1|4
		var c=CollisionShape3D.new();var capsule=CapsuleShape3D.new();capsule.radius=0.27;capsule.height=1.6;c.shape=capsule;c.position.y=0.8;b.add_child(c);world.add_child(b)
		b.global_position=e._basket_world_pos()+Vector3.UP*0.065
		var seen: Array=[];var fired_frame=-1;var max_error=0.0;var flight_steps=0;var origin=Vector3.ZERO;var velocity=Vector3.ZERO
		for i in range(400):
			if e._countdown>=0:
				var digit=int(ceil(e._countdown));if digit not in seen:seen.append(digit)
			if is_instance_valid(e._flight_receiver) and e._flight_receiver.flights.has(b.get_instance_id()):
				if fired_frame<0:fired_frame=i;origin=e._shot_origin;velocity=e._shot_velocity
				b.velocity=e._flight_receiver.carry_velocity(b,1.0/60,b.velocity)
				b.move_and_slide();e._flight_receiver.record_carry(b);flight_steps+=1
				if flight_steps<=60:
					var expected=origin+velocity*float(flight_steps)/60+Vector3.DOWN*4.9*pow(float(flight_steps)/60,2)
					max_error=maxf(max_error,b.global_position.distance_to(expected))
			else:
				b.velocity.y-=9.8/60;b.move_and_slide()
			await physics_frame
		check("%d: actual layer-1 overlap starts 3 2 1"%yaw,seen.has(3) and seen.has(2) and seen.has(1))
		check("%d: no early fire, exactly one launch"%yaw,fired_frame>=179 and fired_frame<=190 and e._launch_count==1)
		check("%d: velocity goes over axle toward local -Z"%yaw,(e.global_basis.inverse()*velocity).z < -5 and velocity.y>5)
		check("%d: physical first second follows predicted red arc"%yaw,max_error<0.2 and flight_steps>60)
		check("%d: red path uses solid triangle geometry"%yaw,e._traj_mat.albedo_color.r>0.95 and e._traj_mat.albedo_color.g<0.1 and e._traj_mesh.mesh.surface_get_primitive_type(0)==Mesh.PRIMITIVE_TRIANGLES)
		measurements[str(yaw)]={"countdown":seen,"fire_frame":fired_frame,"preview_error_first_second":max_error,"flight_frames":flight_steps,"displacement":b.global_position.distance_to(origin)}
		b.queue_free();e.queue_free();await frames(3)
	# Actual XR body: leaving during countdown cancels, and reboarding starts afresh.
	var e=load("res://commons/artifacts/human_catapult/human_catapult.tscn").instantiate();world.add_child(e);await frames(3)
	var rig=XROrigin3D.new();rig.current=true
	var head=XRCamera3D.new();head.name="Camera";head.position.y=1.7;rig.add_child(head)
	var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate();body.player_calibrate_height=false;body.eye_forward_offset=0;rig.add_child(body)
	world.add_child(rig);await frames(3);body.set_physics_process(false)
	var pose: Transform3D=body.global_transform;pose.origin=e._basket_world_pos()+Vector3.UP*0.065;body.teleport(pose)
	await frames(65)
	check("XR layer-20 body starts countdown without a button",e._armed and e._countdown>1.5 and e._countdown<2.5)
	pose.origin=Vector3(3,0.1,4);body.teleport(pose);await frames(160)
	check("Stepping out cancels countdown and prevents launch",e._launch_count==0 and e._countdown<0)
	pose.origin=e._basket_world_pos()+Vector3.UP*0.065;body.teleport(pose);await frames(185)
	check("Reboarding completes a fresh countdown",e._launch_count==1 and e._firing)
	var adapter=body.get_node_or_null("FieldCarryAdapter")
	check("Catapult installs XR launch provider before movement",adapter!=null)
	var head_pose=head.transform;var origin=body.global_position;var moved=rig.global_position
	for i in range(65):adapter.physics_movement(1.0/60,body,false);await physics_frame
	check("Launch moves the actual XR collision body and origin away",body.global_position.distance_to(origin)>7 and rig.global_position.distance_to(moved)>7)
	check("Launch leaves tracked head transform intact",head.transform.is_equal_approx(head_pose))
	check("Preview origin stays at release instead of following arm",e.preview_origin_local().distance_to(e.to_local(e._shot_origin))<0.001)
	measurements.xr={"travel":body.global_position.distance_to(origin),"launch_count":e._launch_count}
	rig.queue_free();e.queue_free();await frames(3)
	# The same museum hall exposed an empty-trail render error in the fountain.
	var fountain=load("res://commons/artifacts/firework_burst/live_fountain.gd").new();world.add_child(fountain)
	fountain.simulation_time=4.0;fountain.update_picture()
	check("Fountain can finish with no visible trail segments",fountain.tails.mesh==null)
	fountain.simulation_time=0.5;fountain.update_picture()
	check("Fountain trails return on the next visible flight",fountain.tails.mesh!=null)
	fountain.queue_free();await frames(2)
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"physics_engine":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"Actual Area3D overlaps, layer-1 desktop and layer-20 XR bodies, countdown/cancel, collision-aware ballistic movement and rotated previews. Supplied input; physical headset untested."}
	FileAccess.open("res://ada_run/human_catapult_launch_tests.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("HUMAN CATAPULT ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
