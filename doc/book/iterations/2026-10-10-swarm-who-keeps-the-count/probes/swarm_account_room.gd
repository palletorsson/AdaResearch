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
	var s=find_scene("/population_account_walk.gd")
	check("Permanent full-size population account loads",s!=null)
	if s==null:return
	s.restart()
	var origin:Vector3=s.global_position-hall.global_basis*Vector3(8.5,0,10.5);origin.y=hall.global_position.y
	observations.origin=xyz(origin);observations.artifact=xyz(s.global_position)
	check("Museum uses exportable printed host",s.get_script().get_base_script().resource_path.ends_with("/population_account_walk/study.gd"))
	check("55 unscaled carried points with matching51cm grab shapes",s.points.size()==55 and s.global_basis.get_scale().is_equal_approx(Vector3.ONE) and is_equal_approx(s.points.values()[0].get_child(1).shape.radius,.255))
	var supported:=true
	for z in range(1,20):
		var at:Vector3=origin+hall.global_basis*Vector3(8.5,.02,z+.5)
		var good:bool=not floor_at(at).is_empty() and clear_at(at)
		supported=supported and good
	check("19 central walk samples have floor and capsule clearance",supported)
	var controls:=true
	for side in [-1,1]:
		for i in range(4):
			var at:Vector3=s.to_global(Vector3(-side*3.1+(i-1.5)*1.05,.02,side*7.5))
			var good:bool=not floor_at(at).is_empty() and clear_at(at)
			if not good:observations["control_"+str(side)+"_"+str(i)]=xyz(at)
			controls=controls and good
	check("All eight control approaches supported and clear",controls)
	var floor:Dictionary=floor_at(s.to_global(Vector3(2,.04,2)))
	check("Display above actual museum floor",not floor.is_empty() and s.to_global(Vector3(0,.035,0)).y>float(floor.position.y)+.01)
	s.get_node("Run1").emit_signal("pressed");await create_timer(.15).timeout;s.get_node("Run-1").emit_signal("pressed")
	check("Both control banks operate same live model",s.model.tick>0 and not s.playing)
	s.restart()
	await snapshot("eye-level",s.to_global(Vector3(2,1.7,5.8)),s.to_global(Vector3(-1,1.3,-1)),82)
	await snapshot("above-after",origin+hall.global_basis*Vector3(8.5,30,28),origin+hall.global_basis*Vector3(8.5,0,10.5),60)
	# Fast-forward the actual model, not an invented presentation state.
	for step in range(1800):
		s.model.advance(s.PERIOD)
		if step%60==0:await tick()
	s.paint();await tick()
	check("Native population reconciles to both actual arrays",s.account.expected("prey")==s.model.prey_list.size() and s.account.expected("predator")==s.model.predator_list.size())
	check("Actual later run contains supplied bodies",s.account.total("prey","supplied")>0)
	var gold:=0
	for body in s.bodies():
		if body.get_meta("arrival")=="supplied":
			gold+=1
			check("Supplied body has gold provenance ring",s.points[body.get_instance_id()].get_child_count()>=3)
	check("There are surviving supplied bodies to inspect",gold>0)
	await snapshot("support",s.to_global(Vector3(3.8,1.7,4.8)),s.to_global(Vector3(0,1.2,-1)),83)
	await snapshot("account",s.to_global(Vector3(0,2.2,11.4)),s.to_global(Vector3(0,2.3,6.9)),85)
	var counts:Vector2i=Vector2i(s.model.prey_list.size(),s.model.predator_list.size());var events:int=s.account.events.size()
	s.get_node("Record1").emit_signal("pressed")
	check("Filtering leaves bodies and actual event stream intact",counts==Vector2i(s.model.prey_list.size(),s.model.predator_list.size()) and events==s.account.events.size())
	check("Missing row exposes correct unexplained amount",s.account.difference("prey",counts.x,false)==s.account.total("prey","supplied") and "FILTERED" in s.captions[0].text)
	await snapshot("filtered",s.to_global(Vector3(0,2.2,11.4)),s.to_global(Vector3(0,2.3,6.9)),85)
	s.get_node("Record-1").emit_signal("pressed")
	check("Other bank restores full account",s.show_supply and "FULL RECORD" in s.captions[0].text)
	s.restart()
	check("Saved encounter can restart at50 plus5",s.points.size()==55 and s.model.tick==0 and s.account.events.is_empty())
	observations.permanent=true;observations.headset_tested=false;observations.walk_samples=19;observations.control_samples=8
	completed=true
func finish() -> void:
	var result={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Saved museum, floor/clearance/control checks and native images. No physical headset or portal-crossing claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
