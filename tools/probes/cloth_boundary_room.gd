extends "res://tools/probes/transformation_encounters.gd"
const DIR:="res://doc/book/iterations/2026-10-09-cloth-which-points-stay/"
var map_origin:Vector3
func map_at(p:Vector3)->Vector3:return map_origin+hall.global_basis*p
func clear_body(at:Vector3)->bool:
	var shape:=CapsuleShape3D.new();shape.radius=.28;shape.height=1.7
	var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*.88;q.collision_mask=1|4
	return hall.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
func pin_count(body:SoftBody3D)->int:
	var n:=0
	for i in body.get_meta("lesson_rest").size():
		if body.is_point_pinned(i):n+=1
	return n
func counts(desk:Node3D)->Array:
	var result:Array=[]
	for b in desk._bodies(desk.model):result.append(pin_count(b))
	return result
func landing_checks()->void:
	museum.call("flush_stamps");await create_timer(1).timeout
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.set_process(false);stream.set_physics_process(false)
	var player=museum.get("_player")
	if player is Node3D:player.hide();player.set_process(false);player.set_physics_process(false);player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.45;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Cloth desk binds existing strips and falling samples",desk!=null and desk.ready_for_input and desk.chapter=="cloth" and desk.model!=null and desk.other!=null)
	if desk==null:return
	# Read the actual placement so this probe also records the baseline before a fix.
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	await snapshot("above",map_at(Vector3(15,73,16)),map_at(Vector3(15,0,34)),61)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(15.5,1.3,5)),65)
	check("Eight visible strips start with eight top pins",counts(desk)==[8,8,8,8,8,8,8,8])
	await snapshot("installed-row",desk.model.to_global(Vector3(2.5,2.7,4.8)),desk.model.to_global(Vector3(0,2,0)),52)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Workshop approach is clear and supported",clear_body(approach) and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["PINS","SUPPORT","RELEASE","REBUILD","STIFFNESS","LANDING","RULE"]:
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.4).timeout;var effect:=false
		match id:
			"PINS":effect=counts(desk)==[2,2,2,2,2,2,2,2]
			"SUPPORT":effect=desk.model.suspension=="none" and counts(desk)==[2,2,2,2,2,2,2,2]
			"RELEASE":effect=counts(desk)==[0,0,0,0,0,0,0,0]
			"REBUILD":effect=counts(desk)==[8,8,8,8,8,8,8,8]
			"STIFFNESS":effect=is_equal_approx(desk._bodies(desk.model)[0].linear_stiffness,.1)
			"LANDING":effect=desk.other.landing=="pan"
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer reaches "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
		if id=="SUPPORT":await snapshot("installed-corners",desk.model.to_global(Vector3(2.5,2.7,4.8)),desk.model.to_global(Vector3(0,2,0)),52)
	await driver.teardown();driver.queue_free();await tick()
	await snapshot("landing-samples",desk.other.to_global(Vector3(4,3,6)),desk.other.to_global(Vector3(0,1,0)),62)
	await snapshot("membrane",map_at(Vector3(18,2.1,53)),map_at(Vector3(15.5,1.2,57.5)),65)
	var study=load(DIR+"printed/study.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(12.5,0,10.5)));root.add_child(study);await tick();await tick()
	var stand:Vector3=study.to_global(Vector3(0,.01,2))
	check("Learner approach has floor and capsule clearance",clear_body(stand) and not floor_at(stand).is_empty())
	await snapshot("student-row",study.to_global(Vector3(1.7,2.3,3)),study.to_global(Vector3(.1,1.5,0)),47)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await tick();await tick();check("Same point is held in the actual hall",study.point.is_picked_up())
	var from:Vector3=hand.global_position;var target:Vector3=study.to_global(Vector3(.085714,1.5,-.15))
	for i in 70:hand.global_position=from.lerp(target,float(i+1)/70.0);await tick()
	var row_positions:=PackedVector3Array()
	var row_indices:Array=study.sheet.pins.duplicate()
	for i in row_indices:row_positions.append(study.sheet.get_point_transform(i))
	study.point.action()
	for i in 75:await tick()
	check("Held trigger selects the two learner corners",study.sheet.pins.size()==2)
	var edge_motion:=0.0
	for j in row_indices.size():
		if row_indices[j] not in study.sheet.pins:edge_motion=maxf(edge_motion,row_positions[j].distance_to(study.sheet.get_point_transform(row_indices[j])))
	observations.learner_edge_motion=edge_motion
	check("Released learner edge actually moves inside the museum",edge_motion>.002)
	await snapshot("student-corners",study.to_global(Vector3(1.7,2.3,3)),study.to_global(Vector3(.1,1.5,0)),47)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick()
	check("Released point parks beside the sheet",study.point.position.is_equal_approx(Vector3(.85,1.3,.3)))
	study.act("REBUILD");await tick();await tick();check("Rebuild restores the row in the museum",study.sheet.pins.size()==8)
	await snapshot("with-learner-above",map_at(Vector3(15,73,16)),map_at(Vector3(15,0,34)),61)
	study.queue_free();origin.queue_free();await tick()
	var edited=load(DIR+"variation/study.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(12.5,0,10.5)));root.add_child(edited);await tick();await tick()
	check("Complete edit has 168 entries and 12 row attachments in museum",edited.sheet.rest_points.size()==168 and edited.sheet.pins.size()==12)
	await snapshot("student-more-columns",edited.to_global(Vector3(1.7,2.3,3)),edited.to_global(Vector3(.1,1.5,0)),47)
	edited.queue_free();await tick()
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,5.5),Vector3(26,0,5.5),Vector3(26,0,44),Vector3(15.5,0,44),Vector3(15.5,0,49),Vector3(26,0,49),Vector3(26,0,63.5),Vector3(15.5,0,63.5),Vector3(15.5,0,66.5)]
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1
			if not clear_body(at):blocked.append(xyz(p))
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps}
	check("Centre arrival and side route have capsule clearance",blocked.is_empty())
	check("Sampled route has continuous floor",gaps.is_empty())
	observations.scope="Actual installed seven pointer controls; exact printed learner scene temporarily mounted in hall. Native eye-level and above captures. Optional membrane retained, not independently revalidated. No headset, Quest or independent student claim."
