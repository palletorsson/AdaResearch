extends SceneTree
var checks: Array=[]
var failures: Array=[]
var measurements: Dictionary={}
func _initialize() -> void:run.call_deferred()
func check(text: String,ok: bool) -> void:
	checks.append({"name":text,"passed":ok})
	if not ok:failures.append(text);push_error(text)
func frames(n: int) -> void:
	for i in range(n):await physics_frame
func run() -> void:
	var world=Node3D.new();root.add_child(world);current_scene=world
	var floor_body=StaticBody3D.new();world.add_child(floor_body)
	var c=CollisionShape3D.new();var s=BoxShape3D.new();s.size=Vector3(40,0.1,40);c.shape=s;c.position.y=-0.05;floor_body.add_child(c)
	var origin=XROrigin3D.new();origin.current=true;world.add_child(origin)
	var controller=XRController3D.new();origin.add_child(controller)
	var hand=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();controller.add_child(hand)
	var rack=load("res://commons/artifacts/force_play/impact_club_rack.tscn").instantiate();rack.position=Vector3(4,0,0);world.add_child(rack)
	var club=rack.stick
	var ball=load("res://commons/artifacts/force_capability_lab/loose_point.gd").new();ball.position=Vector3(0.60,0.37,0);world.add_child(ball);ball.freeze=false;ball.mass=3
	ball.sphere.radius=0.34;ball.sphere.height=0.68;ball.get_child(1).shape.radius=0.34
	await frames(20)
	controller.global_position=Vector3(0,0.37,0);club.global_transform=controller.global_transform;club.pick_up(hand)
	check("Actual XRTools grab takes the club by its handle",club.is_picked_up())
	await frames(3)
	check("Held club keeps world and loose-body contact",club.collision_layer==4 and club.collision_mask==5)
	check("Held club cannot be recalled",not rack.return_stick())
	var peak=0.0
	for i in range(100):
		controller.position.z=float(i+1)*0.018
		await physics_frame;peak=maxf(peak,ball.linear_velocity.z)
	check("Held club physically sends the existing sphere forward",peak>0.5 and ball.position.z>0.5)
	measurements.club={"ball_peak_speed":peak,"ball_travel_z":ball.position.z}
	print("CLUB ",club.global_transform," head ",club.to_global(club.HEAD)," layer/mask ",club.collision_layer,"/",club.collision_mask," ball ",ball.global_position," freeze ",ball.freeze)
	club.let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames(3)
	check("Released club becomes a dynamic body",not club.freeze)
	check("RETURN CLUB recalls only the unheld club",rack.return_stick())
	await frames(6)
	check("Club returns accurately to its rack",club.global_position.distance_to(rack.home.origin)<0.01)
	var pointer=load("res://commons/scenes/DesktopInteractionPointer.gd").new();world.add_child(pointer);pointer.set_process(false);pointer.set_physics_process(false)
	pointer._grab_held(club);await frames(3)
	check("Desktop carry retains the club's collision",pointer.is_holding() and club.collision_mask==5 and club.collision_layer==4)
	pointer._drop_held();await frames(2)
	check("Desktop release restores a dynamic club",not club.freeze)
	rack.queue_free();ball.queue_free();pointer.queue_free();await frames(3)
	controller.position=Vector3(0,1.55,-1.3)
	var e=load("res://commons/artifacts/force_play/punching_bag.tscn").instantiate();world.add_child(e);await frames(25)
	check("Bag remains dynamic and refuses direct pickup",not e.bag.freeze and not e.bag.can_pick_up(hand) and e.bag.get_meta("force_constraint_body",false))
	check("Tracked hand receives a local collision mitt",e.mitts.has(controller.get_instance_id()))
	var initial: Vector3=e.bag.global_position;var max_speed=0.0;var max_error=0.0
	for i in range(50):
		controller.position.z=-1.3+float(i+1)*0.024
		await physics_frame
		max_speed=maxf(max_speed,e.bag.linear_velocity.length())
		max_error=maxf(max_error,e.bag.to_global(e.bag_anchor).distance_to(e.to_global(e.anchor_point)))
	check("A tracked-hand punch moves the bag through contact",max_speed>0.25 and e.bag.global_position.distance_to(initial)>0.08)
	print("BAG ",e.bag.global_position," freeze ",e.bag.freeze," layers ",e.bag.collision_layer,"/",e.bag.collision_mask," MITT ",e.mitts[controller.get_instance_id()].body.global_position," layer ",e.mitts[controller.get_instance_id()].body.collision_layer," mask ",e.mitts[controller.get_instance_id()].body.collision_mask)
	check("Punch keeps the pin-joint anchor attached",max_error<0.08)
	controller.position=Vector3(0,1.5,-4);await frames(3)
	check("Leaving the bay disables local mitt collision",e.mitts[controller.get_instance_id()].body.collision_mask==0)
	var reverse=false
	for i in range(240):
		await physics_frame
		if e.bag.linear_velocity.z< -0.1:reverse=true
	check("The suspended bag returns after the strike",reverse)
	measurements.bag={"punch_speed":max_speed,"joint_error":max_error}
	check("Bag reset succeeds when released",e.reset());await frames(8)
	check("Reset restores the bag and its joint",e.bag.position.distance_to(e.homes[0].origin)<0.03 and e.bag.to_global(e.bag_anchor).distance_to(e.to_global(e.anchor_point))<0.03)
	controller.global_position=e.grips[0].global_position;e.grips[0].pick_up(hand);await frames(2)
	check("Pull grip refuses a reset while held",not e.reset())
	controller.global_position+=Vector3(1,0,-0.7);await frames(35)
	check("Pulling the separate grip does not detach the bag",e.bag.to_global(e.bag_anchor).distance_to(e.to_global(e.anchor_point))<0.08)
	e.grips[0].let_go(hand,Vector3.ZERO,Vector3.ZERO);await frames(3)
	controller.queue_free();await frames(4)
	check("Removed controller leaves no orphan mitt",e.mitts.is_empty())
	e.queue_free();origin.queue_free();await frames(2)
	var report={"passed":failures.is_empty(),"checks":checks,"failures":failures,"measurements":measurements,"scope":"Jolt contacts and pin joint, actual XRTools grab and tracked-hand proxies with supplied controller poses; physical headset feel untested."}
	FileAccess.open("res://ada_run/force_impact_tools.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("IMPACT TOOLS ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
