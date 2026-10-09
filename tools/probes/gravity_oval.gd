extends SceneTree
var checks: Array = []
var failures: Array = []
var measurements: Dictionary = {}
func _initialize() -> void: run.call_deferred()
func check(message: String, good: bool) -> void:
	checks.append({"name": message, "passed": good})
	if not good: failures.append(message); push_error(message)
func frames(n: int) -> void:
	for i in range(n): await physics_frame
func run() -> void:
	var world = Node3D.new(); root.add_child(world); current_scene = world
	var e = load("res://commons/artifacts/gravity_oval/gravity_oval.tscn").instantiate(); world.add_child(e)
	await frames(3)
	check("24 existing prefab and point bodies", e.bodies.size() == 24 and e.bodies[0].get_script().resource_path.ends_with("loose_point.gd"))
	check("Field turns up, over, down and back", e.acceleration(Vector3(-2.8,5.7,0),Vector3.ZERO).y > 0 and e.acceleration(Vector3(0,10.2,0),Vector3.ZERO).x > 0 and e.acceleration(Vector3(2.8,5.7,0),Vector3.ZERO).y < 0 and e.acceleration(Vector3(0,1.2,0),Vector3.ZERO).x < 0)
	check("Field excludes the surrounding aisle", not e._point_inside(Vector3(6,0,0)) and not e._point_inside(Vector3(0,0,-3)))
	var prop = e.bodies[12]
	var previous = Vector2((prop.position.x)/2.8,(prop.position.y-5.7)/4.5).angle()
	var turn = 0.0; var peak = 0.0; var low = 99.0
	for i in range(1200):
		await physics_frame
		var angle = Vector2(prop.position.x/2.8,(prop.position.y-5.7)/4.5).angle()
		turn += wrapf(angle-previous,-PI,PI); previous=angle
		peak=maxf(peak,prop.position.y); low=minf(low,prop.position.y)
	measurements.prop={"turns":-turn/TAU,"highest":peak,"lowest":low,"recoveries":e.recovered}
	check("Free rigid prefab completes at least two physical circuits", -turn > TAU*2)
	check("Prop passes over the top and returns low", peak > 9 and low < 2)
	check("All bodies remain finite and no recovery substitutes a loop", e.recovered == 0 and e.bodies.all(func(b): return b.position.is_finite() and b.linear_velocity.is_finite()))
	var rig=XROrigin3D.new();rig.current=true
	var head=XRCamera3D.new();head.name="Camera";head.position=Vector3(0,1.7,0);rig.add_child(head)
	var body=load("res://addons/godot-xr-tools/player/player_body.tscn").instantiate();body.player_calibrate_height=false;body.eye_forward_offset=0.0;rig.add_child(body)
	var controller=XRController3D.new();rig.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	root.add_child(rig);await frames(3);body.set_physics_process(false)
	var pose: Transform3D=body.global_transform;pose.origin=e.to_global(Vector3(-2.6,0.2,-1.2));body.teleport(pose)
	var adapter=body.get_node_or_null("FieldCarryAdapter")
	check("Real XR body has the museum field adapter", adapter != null)
	var head_pose=head.transform; var started=rig.global_position
	peak=0; low=99;previous=atan2((body.global_position.y+0.7-5.7)/4.5,body.global_position.x/2.8);turn=0
	for i in range(1200):
		adapter.physics_movement(1.0/60,body,false)
		await physics_frame
		var angle=atan2((body.global_position.y+0.7-5.7)/4.5,body.global_position.x/2.8)
		turn+=wrapf(angle-previous,-PI,PI);previous=angle
		peak=maxf(peak,body.global_position.y)
		if i>500:low=minf(low,body.global_position.y)
	measurements.xr={"turns":-turn/TAU,"highest":peak,"returned_to":low,"origin_travel":rig.global_position.distance_to(started)}
	check("Player rises, crosses and cycles with actual XR collision movement", -turn > TAU*1.5 and peak > 8 and low < 2)
	check("Tracked head keeps its own orientation and local pose", head.transform.is_equal_approx(head_pose))
	check("XR origin follows the collision body", rig.global_position.distance_to(started)>0.5)
	# A real movement input must overcome centring; the next normal provider takes over.
	body.ground_control_velocity=Vector2(0,-3)
	for i in range(180):
		adapter.physics_movement(1.0/60,body,false);await physics_frame
	check("Thumbstick movement can leave the stream", not e._point_inside(body.global_position))
	adapter.physics_movement(1.0/60,body,false)
	check("Leaving relinquishes carry ownership", not e._carry.has(body.get_instance_id()))
	# Move back to the floor for the supplied-hand pickup; no alteration to camera basis.
	body.ground_control_velocity=Vector2.ZERO
	pose.origin=Vector3(-5,0.2,-4);body.teleport(pose)
	controller.global_position=prop.global_position;prop.pick_up(hand);await frames(2)
	check("Floating furniture can be picked up", prop.is_picked_up())
	check("Reset refuses held floating furniture", not e.reset())
	controller.global_position=Vector3(-5,1.5,-4);await frames(3)
	prop.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames(4)
	check("Taken-out object returns to ordinary gravity", is_equal_approx(prop.gravity_scale,1.0) and prop.linear_velocity.y<0)
	check("Reset accepts after release", e.reset())
	await frames(4)
	check("Reset restores the circulating launch and finite pool", e.bodies.size()==24 and prop.linear_velocity.length()>1 and prop.position.distance_to(e.homes[12].origin)<0.5)
	rig.queue_free();await frames(2)
	var result={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"physics_engine":ProjectSettings.get_setting("physics/3d/physics_engine"),"scope":"Real Jolt cargo and XRTools player/adapter with supplied head and controller poses. No headset or Quest performance claim."}
	FileAccess.open("res://ada_run/gravity_oval_tests.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("GRAVITY OVAL ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
