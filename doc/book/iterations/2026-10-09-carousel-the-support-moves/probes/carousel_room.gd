extends "res://tools/probes/transformation_encounters.gd"
const DIR:="res://doc/book/iterations/2026-10-09-carousel-the-support-moves/"
var map_origin:Vector3
var completed:=false
func finish()->void:
	check("All planned museum and learner checks completed",completed)
	super.finish()
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func hits(at:Vector3)->Array:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*.88;q.collision_mask=1|4
	var result:Array=[]
	for h in hall.get_world_3d().direct_space_state.intersect_shape(q):result.append(str(h.collider.get_path()))
	return result
func positions(body:SoftBody3D)->PackedVector3Array:
	var result:=PackedVector3Array()
	for i in body.rest_points.size():result.append(body.get_point_transform(i))
	return result
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.18;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Carousel desk binds existing ride and fixed-support strips",desk!=null and desk.ready_for_input and desk.chapter=="carousel" and desk.model!=null and desk.other!=null)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	await snapshot("above",map_at(Vector3(15,62,9)),map_at(Vector3(15,0,27)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(15.5,1.3,7)),65)
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	var ride:Node3D=desk.model;var hub:RigidBody3D=ride.ride_hub
	check("Installed hub is kinematically frozen",hub.freeze and hub.freeze_mode==RigidBody3D.FREEZE_MODE_KINEMATIC)
	check("Installed chains use eight pin joints",ride.find_children("*","PinJoint3D",true,false).size()==8)
	check("Installed ride retains four soft bodies",desk._bodies(ride).size()==4)
	await snapshot("installed-ride",ride.to_global(Vector3(8,5.5,9)),ride.to_global(Vector3(0,2.2,0)),63)
	await snapshot("fixed-curtain",desk.other.to_global(Vector3(2,2.6,4.5)),desk.other.to_global(Vector3(0,1.7,0)),55)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Workshop approach is clear and supported",hits(approach).is_empty() and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["SPEED","REVERSE","STOP","STIFFNESS","PRESSURE","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.3).timeout;var effect:=false
		match id:
			"SPEED":effect=is_equal_approx(ride.ride_speed,.4)
			"REVERSE":effect=is_equal_approx(ride.ride_speed,-.4)
			"STOP":effect=is_zero_approx(ride.ride_speed)
			"STIFFNESS":effect=is_equal_approx(desk._bodies(ride)[0].linear_stiffness,.5)
			"PRESSURE":effect=is_equal_approx(desk._bodies(ride)[0].pressure_coefficient,.5)
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer reaches "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
		if id=="STOP":
			var angle:float=hub.rotation.y;var link:RigidBody3D=ride.get_node("Link2_0");var at:Vector3=link.global_position
			for i in 35:await tick()
			check("Installed STOP holds hub angle",absf(wrapf(hub.rotation.y-angle,-PI,PI))<.00001)
			observations.link_motion_after_stop=at.distance_to(link.global_position)
			check("Installed links remain dynamic after STOP",not link.freeze and link.get_rid().is_valid())
	await snapshot("desk",desk.to_global(Vector3(0,1.7,3)),desk.to_global(Vector3(0,1.2,0)),55)
	await driver.teardown();driver.queue_free();await tick()
	var study=load(DIR+"printed/study.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(9.5,0,8.5)));root.add_child(study)
	for i in 45:await tick()
	var stand:Vector3=study.to_global(Vector3(0,.01,2))
	check("Learner approach has support and capsule clearance",hits(stand).is_empty() and not floor_at(stand).is_empty())
	await snapshot("student-turning",study.to_global(Vector3(1.7,2.3,3.3)),study.to_global(Vector3(.1,1.5,0)),49)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await tick();await tick();check("Familiar black ball is actually picked up",study.point.is_picked_up())
	study.point.action();await tick();check("Held trigger stops only the learner drive",is_zero_approx(study.rate))
	var stopped:float=study.phase;var before:=positions(study.sheet);var identity:int=study.sheet.get_instance_id()
	for i in 50:await tick()
	var after:=positions(study.sheet);var motion:=0.0
	for i in before.size():
		if i not in study.sheet.pins:motion=maxf(motion,before[i].distance_to(after[i]))
	observations.learner_motion_after_stop=motion
	check("Learner support stays still while free cloth entries move",absf(study.phase-stopped)<.00001 and motion>.002)
	check("Learner STOP retains the same sheet",study.sheet.get_instance_id()==identity)
	await snapshot("student-stopped",study.to_global(Vector3(1.7,2.3,3.3)),study.to_global(Vector3(.1,1.5,0)),49)
	study.point.action();await tick();check("Held trigger resumes the drive",is_equal_approx(study.rate,.4))
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();check("Released ball parks clear of the sheet",study.point.position.is_equal_approx(Vector3(1.15,1.3,.6)))
	await snapshot("with-learner-above",map_at(Vector3(15,62,9)),map_at(Vector3(15,0,27)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load(DIR+"variation/study.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(9.5,0,8.5)));root.add_child(edited)
	for i in 45:await tick()
	check("Complete RATE edit runs at .8 radians per second in hall",is_equal_approx(edited.rate,.8) and edited.sheet.rest_points.size()==112)
	await snapshot("student-faster",edited.to_global(Vector3(1.7,2.3,3.3)),edited.to_global(Vector3(.1,1.5,0)),49)
	edited.queue_free();await tick()
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,5.5),Vector3(3.5,0,5.5),Vector3(3.5,0,26.5),Vector3(1.5,0,26.5),Vector3(1.5,0,53.5),Vector3(15.5,0,53.5),Vector3(15.5,0,54.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1
			var colliders:=hits(at)
			if not colliders.is_empty():blocked.append({"at":xyz(p),"colliders":colliders})
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps,"waypoints":route.map(func(p):return xyz(p))}
	check("Centre arrival and left-side route have capsule clearance",blocked.is_empty())
	check("Sampled route has continuous floor",gaps.is_empty())
	observations.scope="Native museum, six installed pointer controls, temporary exact printed learner study, supplied XRTools, preserved dynamic state and route samples. No headset, Quest or independent student claim."
	completed=true
