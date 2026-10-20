extends "res://tools/probes/transformation_encounters.gd"
var completed := false
func clear_at(p:Vector3) -> bool:
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.65
	var query:=PhysicsShapeQueryParameters3D.new();query.shape=shape;query.collision_mask=1;query.transform.origin=p+Vector3.UP*.9
	var bodies:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	if not bodies.is_empty():
		if not observations.has("blocked"):observations.blocked=[]
		for body in bodies:observations.blocked.append(str(body.collider.get_path()))
	return bodies.is_empty()
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream=museum.get("_portal_stream")
	if stream!=null:stream.process_mode=Node.PROCESS_MODE_DISABLED
	var player=museum.get("_player")
	if player is Node3D:
		player.hide();player.process_mode=Node.PROCESS_MODE_DISABLED;player.global_position=Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var attributes:=CameraAttributesPractical.new();attributes.exposure_multiplier=.35;camera.attributes=attributes
	var s=find_scene("/particle_swarm_walk.gd")
	check("Permanent full-size PSO loads from saved hall",s!=null)
	if s==null:return
	s.playing=false;s.change(0);s.restart()
	var origin:Vector3=s.global_position-hall.global_basis*Vector3(8.5,0,9.5);origin.y=hall.global_position.y
	observations.origin=xyz(origin);observations.artifact=xyz(s.global_position)
	check("Museum inherits exact exportable learner host",s.get_script().get_base_script().resource_path.ends_with("/particle_swarm_walk/study.gd"))
	check("Full-size unscaled24 half-metre bodies",s.global_basis.get_scale().is_equal_approx(Vector3.ONE) and s.points.size()==24 and is_equal_approx(s.points[0].get_child(1).shape.radius,.255))
	check("Field renders256 scored cells",s.field.multimesh.instance_count==256)
	var supported:=true
	for z in range(1,22):
		var at:Vector3=origin+hall.global_basis*Vector3(8.5,.02,z+.5)
		supported=supported and not floor_at(at).is_empty() and clear_at(at)
	check("Central walk from entrance to exit has floor and clearance",supported)
	var controls:=true
	for side in [-1,1]:
		for i in range(6):
			var at:Vector3=s.to_global(Vector3(-side*3.2+(i-2.5)*.82,.02,side*7.3))
			var good:bool=not floor_at(at).is_empty() and clear_at(at)
			if not good: observations["control_"+str(side)+"_"+str(i)]=xyz(at)
			controls=controls and good
	check("All12 control approaches supported and clear",controls)
	var floor:Dictionary=floor_at(s.to_global(Vector3(2,.04,2)))
	check("Display sits above museum floor",not floor.is_empty() and s.to_global(Vector3(0,.035,0)).y>float(floor.position.y)+.01)
	s.get_node("Run1").emit_signal("pressed");await create_timer(.35).timeout;s.get_node("Run-1").emit_signal("pressed")
	check("Both ends operate same running model",s.model.steps>=3 and not s.playing)
	s.restart()
	for i in range(6):s.model.step()
	s.paint();await tick()
	check("Native memories hold scored positions",is_equal_approx(s.model.shared_score,s.model.score(s.model.shared_position)))
	await snapshot("eye-level",s.to_global(Vector3(1,1.7,5.6)),s.to_global(Vector3(-.7,.65,0)),80)
	await snapshot("above-after",origin+hall.global_basis*Vector3(8.5,30,28),origin+hall.global_basis*Vector3(8.5,0,10.5),61)
	# A deliberate hand-placement equivalent; actual XR is exercised by the code test.
	var remembered:Vector2=s.model.best_positions[0]
	s.model.positions[0]=Vector2(4,1);s.model.velocities[0]=Vector2.ZERO;s.paint();await create_timer(.2).timeout
	check("Relocated rendered sphere retains old best marker",s.model.best_positions[0]==remembered and s.points[0].position.distance_to(s.place(Vector2(4,1)))<.001)
	await snapshot("memory",s.to_global(Vector3(5.8,4,4)),s.to_global(Vector3(1,.25,0)),75)
	var p=s.model.positions.duplicate();var v=s.model.velocities.duplicate()
	s.get_node("Edge-1").emit_signal("pressed")
	check("Native objective switch preserves movement and resets memories",s.model.positions==p and s.model.velocities==v and s.model.best_positions==p)
	await tick()
	check("EDGE floor gives corners a brighter value",s.field.multimesh.get_instance_color(0).r>s.field.multimesh.get_instance_color(136).r)
	for i in range(35):s.model.step()
	s.paint();await tick()
	await snapshot("edge",s.to_global(Vector3(8,12,9)),s.to_global(Vector3(0,0,0)),66)
	s.get_node("Ridge1").emit_signal("pressed");s.restart()
	for i in range(30):s.model.step()
	s.paint();await tick()
	check("RIDGE has equal score at different diagonal positions",s.model.score(Vector2(-3,-3))==s.model.score(Vector2(4,4)))
	await snapshot("ridge",s.to_global(Vector3(8,12,9)),s.to_global(Vector3(0,0,0)),66)
	await snapshot("controls",s.to_global(Vector3(-3.2,1.7,7.7)),s.to_global(Vector3(-3.2,1.5,6.7)),105)
	var comparison=find_scene("/fitness_landscape_politics.gd")
	check("Original novelty comparison retained",comparison!=null)
	var self_org=find_scene("/self_organization_principles.gd")
	check("Self-organization comparison retained",self_org!=null)
	await snapshot("comparisons",origin+hall.global_basis*Vector3(8.5,1.7,17),origin+hall.global_basis*Vector3(7.5,1.1,19.5),88)
	s.change(0);s.restart()
	observations.permanent=true;observations.headset_tested=false
	completed=true
func finish() -> void:
	var result={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Saved museum, control/clearance checks and rendered images. No headset comfort/performance or actual player portal-crossing claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
