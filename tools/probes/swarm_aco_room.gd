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
	var s=find_scene("/ant_colony_walk.gd")
	check("Permanent room-scale colony loads from saved map",s!=null)
	if s==null:return
	s.playing=false;s.restart()
	var origin:Vector3=s.global_position-hall.global_basis*Vector3(8.5,0,8.5)
	origin.y=hall.global_position.y
	observations.origin=xyz(origin);observations.colony=xyz(s.global_position)
	check("Permanent host inherits exportable copy of printed lesson",s.get_script().get_base_script().resource_path.ends_with("/ant_colony_walk/study.gd"))
	check("Unscaled room has24 bodies and12m field",s.global_basis.get_scale().is_equal_approx(Vector3.ONE) and s.points.size()==24 and is_equal_approx(s.CELL*16,12))
	check("Two channels render as two batches",s.home_tiles.multimesh.instance_count==256 and s.food_tiles.multimesh.instance_count==256)
	check("Both ends have reachable buttons",is_equal_approx(s.get_node("Step1").position.y,.95) and is_equal_approx(s.get_node("Step-1").position.y,.95))
	var supported:=true
	for z in range(-7,8):
		var at:Vector3=s.to_global(Vector3(0,.02,z))
		supported=supported and not floor_at(at).is_empty() and clear_at(at)
	check("Walk through centre of field has support and clearance",supported)
	var control_approaches:=true
	for side in [-1,1]:
		for x in [-1.5,-.5,.5,1.5]:
			var at:Vector3=s.to_global(Vector3(x-side*3.5,.02,side*7.15))
			control_approaches=control_approaches and not floor_at(at).is_empty() and clear_at(at)
	check("All eight control approaches have support and clearance",control_approaches)
	var floor:Dictionary=floor_at(s.to_global(Vector3(2,.04,2)))
	check("Rendered field sits above real museum floor",not floor.is_empty() and s.to_global(Vector3(0,.035,0)).y>float(floor.position.y)+.01)
	var initial:int=s.model.steps
	s.get_node("Run1").emit_signal("pressed");await create_timer(.3).timeout;s.get_node("Run-1").emit_signal("pressed")
	check("Either end controls the same running model",s.model.steps>initial and not s.playing)
	s.restart()
	for i in range(260):s.model.step()
	s.paint();await tick()
	check("Unassisted native colony produces deliveries and both traces",s.model.delivered>0 and s.model.home.count(0.0)<250 and s.model.food.count(0.0)<250)
	observations.deliveries=s.model.delivered;observations.tick=s.model.steps
	await snapshot("eye-level",s.to_global(Vector3(1,1.7,5.8)),s.to_global(Vector3(-.5,.65,0)),78)
	await snapshot("among-points",s.to_global(Vector3(-1.8,1.65,1.8)),s.to_global(Vector3(-3.6,.7,0)),72)
	await snapshot("above-after",origin+hall.global_basis*Vector3(8.5,25,23),origin+hall.global_basis*Vector3(8.5,0,8.5),60)
	var h:PackedFloat32Array=s.model.home.duplicate();var f:PackedFloat32Array=s.model.food.duplicate()
	s.get_node("Replace1").emit_signal("pressed")
	check("Native Replace keeps both exact fields",s.model.home==h and s.model.food==f and s.model.carrying.count(false)==24)
	await snapshot("trails-kept",s.to_global(Vector3(7,10,7)),s.to_global(Vector3(0,0,0)),64)
	s.restart()
	s.model.positions[0]=s.Colony.FOOD;s.model.velocities[0]=Vector2.ZERO;s.paint()
	s.get_node("Step1").emit_signal("pressed")
	check("Food contact shows cargo and changed channels",s.cargo[0].visible and "READ HOME  /  LEAVE FOOD" in s.captions[0].text)
	await create_timer(.2).timeout
	check("Rendered frozen sphere follows model across physics frames",s.points[0].position.distance_to(s.place(s.model.positions[0]))<.001)
	await snapshot("carrying-close",s.to_global(Vector3(4.8,1.7,2.8)),s.to_global(Vector3(3,.8,0)),66)
	await snapshot("controls",s.to_global(Vector3(-3.5,1.7,8.2)),s.to_global(Vector3(-3.5,1.5,6.5)),85)
	s.get_node("Reset-1").emit_signal("pressed")
	check("Opposite-end Clear empties both channels",s.model.home.count(0.0)==256 and s.model.food.count(0.0)==256 and s.model.steps==0)
	await snapshot("clear-all",s.to_global(Vector3(7,10,7)),s.to_global(Vector3(0,0,0)),64)
	observations.permanent=true;observations.headset_tested=false
	completed=true
func finish() -> void:
	var result={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":completed and failures.is_empty(),"completed":completed,"scope":"Permanent native museum artifact, code/control/clearance checks and rendered images. No headset comfort/performance or actual player portal-crossing claim."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	quit(0 if result.passed else 1)
