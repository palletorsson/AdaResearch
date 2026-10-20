extends "res://tools/probes/transformation_encounters.gd"
const DIR:="res://doc/book/iterations/2026-10-09-contact-the-same-start/"
var map_origin:Vector3
var completed:=false
func finish()->void:
	check("All planned checks completed",completed)
	super.finish()
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func hits(at:Vector3)->Array:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*.88;q.collision_mask=1|4
	var out:Array=[]
	for h in hall.get_world_3d().direct_space_state.intersect_shape(q):
		var path:=str(h.collider.get_path())
		if path not in out:out.append(path)
	return out
func positions(sb:SoftBody3D)->PackedVector3Array:
	var out:=PackedVector3Array()
	for i in sb.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size():out.append(sb.get_point_transform(i))
	return out
func motion(a:PackedVector3Array,b:PackedVector3Array)->float:
	var value:=0.0
	for i in a.size():value=maxf(value,a[i].distance_to(b[i]))
	return value
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.28;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Contact desk binds the twelve existing gallery cases",desk!=null and desk.ready_for_input and desk.chapter=="contact" and desk.model!=null and desk.model.active_soft_bodies.size()==12)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	await snapshot("above",map_at(Vector3(15,78,12)),map_at(Vector3(15,0,34)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(15.5,1.3,7)),65)
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	var model:Node3D=desk.model
	await snapshot("gallery",model.to_global(Vector3(12,8,-5)),model.to_global(Vector3(4,1.5,5)),65)
	observations.cases=[]
	for item in model.active_soft_bodies:
		var body:SoftBody3D=item.node
		observations.cases.append({"name":str(body.get_parent().name),"stiffness":body.linear_stiffness,"damping":body.damping_coefficient,"pressure":body.pressure_coefficient,"precision":body.simulation_precision})
	check("Declared setup disables jitter, respawning and ongoing deflation",not model.lesson_variation and not model.respawn and not model.is_processing() and model.seed_value==1337)
	var spec:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	if spec.get("baseline",false):completed=true;return
	check("Arrival is clear",observations.entry_colliders.is_empty())
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Desk approach is clear and supported",hits(approach).is_empty() and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["REPLAY","HOLD","RELEASE","VARIATION","GROUP","RULE"]:
		var identity:int=model.active_soft_bodies[0].node.get_instance_id()
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.15).timeout;var effect:=false
		match id:
			"REPLAY":effect=model.active_soft_bodies[0].node.get_instance_id()!=identity and model.seed_value==1337 and not model.respawn
			"HOLD":effect=desk.drive_held
			"RELEASE":effect=not desk.drive_held
			"VARIATION":effect=model.lesson_variation
			"GROUP":effect=model.gallery_part==3 and model.active_soft_bodies.size()==12
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer reaches "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
		if id=="HOLD":
			var body:SoftBody3D=model.active_soft_bodies[0].node
			var before:=positions(body);var pinned:=0
			for i in before.size():
				if body.is_point_pinned(i):pinned+=1
			await create_timer(.5).timeout
			observations.hold={"pinned":pinned,"entries":before.size(),"motion":motion(before,positions(body))}
			check("HOLD fixes the current surface",observations.hold.motion<.002 and pinned>0)
		if id=="RELEASE":
			var body:SoftBody3D=model.active_soft_bodies[0].node;var pinned:=0
			for i in body.mesh.surface_get_array_len(0):
				if body.is_point_pinned(i):pinned+=1
			check("RELEASE restores this unpinned gallery body",pinned==0 and body.get_instance_id()==identity)
	await snapshot("desk",desk.to_global(Vector3(0,1.7,3)),desk.to_global(Vector3(0,1.2,0)),55)
	await driver.teardown();driver.queue_free();await tick()
	# Keep the installed gallery visible; mount the exact learner program temporarily.
	model.lesson_variation=false;model.apply_grid_config({"gallery_part":2,"seed_value":1337,"respawn":false})
	desk.act("HOLD");await tick();desk.act("REPLAY");await tick()
	check("Replay releases old hold anchors and hold state",not desk.drive_held and desk.saved_pins.is_empty())
	var study=load(DIR+"printed/study.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(23,0,26)));root.add_child(study)
	var stand:Vector3=study.to_global(Vector3(0,.01,2.4))
	observations.learner_approach_colliders=hits(stand)
	check("Learner approach is clear and supported",hits(stand).is_empty() and not floor_at(stand).is_empty())
	await snapshot("student-drop",study.to_global(Vector3(2.9,2.4,3.5)),study.to_global(Vector3(0,1.2,0)),57)
	for i in 105:await tick()
	check("Printed comparison runs in the real museum",study.results.size()==2 and not study.running)
	observations.learner_heights=study.results.duplicate()
	await snapshot("student-reading",study.to_global(Vector3(2.9,2.4,3.5)),study.to_global(Vector3(0,1.2,0)),57)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.points[0].global_position
	study.points[0].pick_up(pickup);await tick();await tick();hand.global_position+=Vector3(.3,.3,0);await tick();await tick()
	check("Hand interruption clears the readings",study.points[0].is_picked_up() and study.results.is_empty() and not study.running)
	var id:int=study.panels[0].get_instance_id();study.points[0].action();await tick();await tick()
	check("Trigger queues replay while retaining the held point",study.armed and study.panels[0].get_instance_id()==id)
	await snapshot("student-interrupted",study.to_global(Vector3(2.9,2.4,3.5)),study.to_global(Vector3(0,1.2,0)),57)
	study.points[0].let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Release rebuilds the panels in the museum",study.panels[0].get_instance_id()!=id and study.running and not study.armed)
	# Send the lesson key through the actual input pipeline (R reloads the gallery).
	id=study.panels[0].get_instance_id();var event:=InputEventKey.new();event.keycode=KEY_1;event.pressed=true;Input.parse_input_event(event);await tick();await tick()
	check("Real keyboard 1 replays without reloading the museum",study.panels[0].get_instance_id()!=id and is_instance_valid(museum) and is_instance_valid(desk))
	event=InputEventKey.new();event.keycode=KEY_1;event.pressed=false;Input.parse_input_event(event)
	await snapshot("with-learner-above",map_at(Vector3(15,78,12)),map_at(Vector3(15,0,34)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load(DIR+"variation/study.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(23,0,26)));root.add_child(edited)
	for i in 105:await tick()
	check("Equal damping edit runs inside the museum",edited.results.size()==2 and edited.panels[0].damping_coefficient==edited.panels[1].damping_coefficient)
	observations.equal_damping_heights=edited.results.duplicate()
	await snapshot("student-equal-damping",edited.to_global(Vector3(2.9,2.4,3.5)),edited.to_global(Vector3(0,1.2,0)),57)
	edited.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,4.5),Vector3(27,0,4.5),Vector3(27,0,65.5),Vector3(15.5,0,65.5),Vector3(15.5,0,66.5)]
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1;var colliders:=hits(at)
			if not colliders.is_empty():blocked.append({"at":xyz(p),"colliders":colliders})
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps,"waypoints":route.map(func(p):return xyz(p))}
	check("Outer route has capsule clearance",blocked.is_empty())
	check("Outer route has continuous floor support",gaps.is_empty())
	observations.scope="Existing museum controls and temporary exact learner program; synthetic XRTools, no physical headset or independent learner."
	completed=true
