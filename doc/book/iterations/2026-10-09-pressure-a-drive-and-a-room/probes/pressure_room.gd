extends "res://tools/probes/transformation_encounters.gd"
const DIR:="res://doc/book/iterations/2026-10-09-pressure-a-drive-and-a-room/"
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
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.3;camera.attributes=attributes
	var desk=find_scene("/timing_machines/soft_workshop.gd")
	check("Workshop binds the existing breathing room and contact gallery",desk!=null and desk.ready_for_input and desk.chapter=="breathing" and desk.model!=null and desk.other!=null)
	if desk==null:return
	var plan:Dictionary=JSON.parse_string(FileAccess.get_file_as_string(folder+"plan.json"));var cell:=Vector2(15,3)
	for room in plan.plans:
		if room.map==map_id:
			for a in room.artifacts:
				if a.token=="soft_workshop_console":cell=Vector2(a.cell[0],a.cell[1])
	map_origin=desk.global_position-hall.global_basis*Vector3(cell.x+.5,0,cell.y+.5)
	observations.desk_cell=[cell.x,cell.y]
	await snapshot("above",map_at(Vector3(15,62,9)),map_at(Vector3(15,0,27)),62)
	await snapshot("entry",map_at(Vector3(15.5,1.65,.2)),map_at(Vector3(15.5,1.2,8)),65)
	observations.entry_colliders=hits(map_at(Vector3(15.5,.01,1.5)))
	check("Centre entry is clear",observations.entry_colliders.is_empty())
	var model:Node3D=desk.model;var walls:Array=model._walls
	check("Installed scene uses authored walls and lesson drive",str(model.get_script().resource_path).ends_with("breathing_room_scene.gd") and model.has_meta("config_lesson") and walls.size()==2)
	var pin_counts:Array=[];var stiffness:Array=[];var shrink:Array=[]
	for sb in walls:
		var count:=0
		for i in sb.mesh.surface_get_arrays(0)[Mesh.ARRAY_VERTEX].size():
			if sb.is_point_pinned(i):count+=1
		pin_counts.append(count);stiffness.append(sb.linear_stiffness);shrink.append(sb.shrinking_factor)
	observations.authored={"pin_counts":pin_counts,"stiffness":stiffness,"shrinking":shrink}
	check("Native walls retain unequal authored material settings",is_equal_approx(stiffness[0],.5) and is_equal_approx(stiffness[1],.02))
	await snapshot("installed-walls",model.to_global(Vector3(1,2.5,8)),model.to_global(Vector3(.5,2,0)),62)
	var approach:Vector3=desk.to_global(Vector3(0,.01,2.9))
	check("Workshop approach is clear and supported",hits(approach).is_empty() and not floor_at(approach).is_empty())
	var driver=load("res://commons/testing/wcn_desktop_driver.gd").new();museum.add_child(driver);driver.spawn(approach,museum);await create_timer(.2).timeout
	observations.buttons=[]
	for id in ["AMPLITUDE","RATE","HOLD DRIVE","STIFFNESS","RESET PHASE","RULE"]:
		var state:=positions(walls[0]);var instance:int=walls[0].get_instance_id()
		var result:Dictionary=await driver.press(desk.buttons[id],approach);await create_timer(.2).timeout;var effect:=false
		match id:
			"AMPLITUDE":effect=is_equal_approx(model.breath_amplitude,.15)
			"RATE":effect=is_equal_approx(model.breath_speed,.4)
			"HOLD DRIVE":effect=desk.drive_held and not model.is_processing()
			"STIFFNESS":effect=is_equal_approx(walls[0].linear_stiffness,.2) and is_equal_approx(walls[1].linear_stiffness,.2)
			"RESET PHASE":effect=is_zero_approx(model._time) and is_equal_approx(walls[0].pressure_coefficient,.075) and walls[0].get_instance_id()==instance
			"RULE":effect=desk.rule_card.visible
		check("Actual pointer reaches "+id,effect and str(result.get("hover","")) not in ["","none","null","nothing"])
		observations.buttons.append({"id":id,"effect":effect,"pointer":result})
		if id=="HOLD DRIVE":
			var phase:float=model._time;var pressure:float=walls[0].pressure_coefficient
			await create_timer(.6).timeout
			check("Installed hold retains phase and pressure, not body identity reset",model._time==phase and walls[0].pressure_coefficient==pressure and walls[0].get_instance_id()==instance)
			observations.installed_motion_held=motion(state,positions(walls[0]))
	await snapshot("desk",desk.to_global(Vector3(0,1.7,3)),desk.to_global(Vector3(0,1.2,0)),55)
	await driver.teardown();driver.queue_free();await tick()
	var study=load(DIR+"printed/study.gd").new();study.transform=Transform3D(desk.global_basis,map_at(Vector3(22,0,27)));root.add_child(study)
	for i in 45:await tick()
	var stand:Vector3=study.to_global(Vector3(0,.01,2.4))
	observations.learner_approach_colliders=hits(stand)
	check("Learner approach is clear and supported",hits(stand).is_empty() and not floor_at(stand).is_empty())
	await snapshot("student-cycle",study.to_global(Vector3(2.2,2.25,3.3)),study.to_global(Vector3(0,1.3,0)),54)
	var origin:=XROrigin3D.new();root.add_child(origin);var hand:=XRController3D.new();origin.add_child(hand)
	var pickup=load("res://addons/godot-xr-tools/functions/function_pickup.tscn").instantiate();hand.add_child(pickup);hand.global_position=study.point.global_position
	study.point.pick_up(pickup);await tick();await tick();check("Learner black point is picked up",study.point.is_picked_up())
	study.point.action();await tick();var held_phase:float=study.phase;var held_pressure:float=study.pressure;var shape:=positions(study.panels[0]);var body:int=study.panels[0].get_instance_id()
	for i in 35:await tick()
	var moved:=motion(shape,positions(study.panels[0]));observations.learner_motion_held=moved
	check("Held trigger retains pressure clock while native surface moves",study.held and study.phase==held_phase and study.pressure==held_pressure and moved>.0005)
	check("Hold retains the same responding panel",study.panels[0].get_instance_id()==body)
	await snapshot("student-held",study.to_global(Vector3(2.2,2.25,3.3)),study.to_global(Vector3(0,1.3,0)),54)
	study.point.action();await tick();check("Second trigger resumes phase",not study.held and study.phase!=held_phase)
	study.point.let_go(pickup,Vector3.ZERO,Vector3.ZERO);await tick();await tick();check("Release returns the point to the opening",study.point.position.is_equal_approx(Vector3(0,1.3,1.2)))
	await snapshot("with-learner-above",map_at(Vector3(15,62,9)),map_at(Vector3(15,0,27)),62)
	study.queue_free();origin.queue_free();await tick()
	var edited=load(DIR+"variation/study.gd").new();edited.transform=Transform3D(desk.global_basis,map_at(Vector3(22,0,27)));root.add_child(edited)
	for i in 45:await tick()
	check("Complete amplitude edit runs inside the hall",is_equal_approx(edited.amplitude,.25) and edited.panels.size()==2)
	await snapshot("student-half-amplitude",edited.to_global(Vector3(2.2,2.25,3.3)),edited.to_global(Vector3(0,1.3,0)),54)
	edited.queue_free();await tick()
	var route:=[Vector3(15.5,0,.5),Vector3(15.5,0,5.5),Vector3(27,0,5.5),Vector3(27,0,53.5),Vector3(15.5,0,53.5),Vector3(15.5,0,54.5)]
	var blocked:Array=[];var gaps:Array=[];var samples:=0
	for j in range(route.size()-1):
		var a:Vector3=route[j];var b:Vector3=route[j+1];var steps:=ceili(a.distance_to(b)/.25)
		for k in steps+1:
			var p:Vector3=a.lerp(b,float(k)/steps);var at:=map_at(p+Vector3.UP*.01);samples+=1;var colliders:=hits(at)
			if not colliders.is_empty():blocked.append({"at":xyz(p),"colliders":colliders})
			if floor_at(at).is_empty():gaps.append(xyz(p))
	observations.route={"samples":samples,"blocked":blocked,"gaps":gaps,"waypoints":route.map(func(p):return xyz(p))}
	check("Outer museum route has capsule clearance",blocked.is_empty())
	check("Outer museum route has continuous support",gaps.is_empty())
	observations.scope="Installed museum controls and temporary exact printed study; simulated XRTools, no physical headset or independent learner. Route goes around pressure specimens."
	completed=true
