extends "res://tools/probes/abm_table_before.gd"
func landing_checks()->void:
	await super.landing_checks()
	var h:=find_scene("/abm_state_table.gd")
	check("Exact printed study has a permanent museum table",h!=null)
	if h==null:return
	var s=h.study
	check("The table instantiates the exportable printed study scene",s.scene_file_path=="res://commons/artifacts/abm_state_table/lesson/study.tscn")
	check("Six familiar points and 256 shared cells",s.points.size()==6 and s.tiles.size()==256)
	check("Original navigator and full-size listening court remain",find_scene("/NavigatorNoise.gd")!=null and find_scene("/listening_horde.gd")!=null)
	var stream=museum.get("_portal_stream")
	check("Authored entry and exit are valid",not stream.get("_entry").get("invalid",false) and not stream.get("_exit").get("invalid",false))
	var routes={
		"entry to controls":[Vector2(6.5,1.5),Vector2(6.5,5.8),Vector2(9.5,5.8)],
		"all front buttons":[Vector2(8.3,5.8),Vector2(10.7,5.8)],
		"table sides and back":[Vector2(7.75,5.8),Vector2(7.75,1.6),Vector2(11.3,1.6),Vector2(11.3,5.8)],
		"listening court":[Vector2(6.5,5.8),Vector2(14,5.8)],
		"exit":[Vector2(6.5,5.8),Vector2(6.5,8.5)]}
	var shape:=CapsuleShape3D.new();shape.radius=.24;shape.height=1.7
	observations.routes={}
	for name in routes:
		var blocked:Array=[];var unsupported:Array=[];var count:=0;var points:Array=routes[name]
		for i in range(points.size()-1):
			var a:Vector2=points[i];var b:Vector2=points[i+1];var steps:=ceili(a.distance_to(b)/.12)
			for j in range(steps+1):
				var xy:=a.lerp(b,float(j)/maxi(steps,1));var p:=at(Vector3(xy.x,0,xy.y));count+=1
				if floor_at(p).is_empty():unsupported.append([xy.x,xy.y])
				var q:=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.collision_mask=1;q.transform.origin=p+Vector3.UP*.9
				var hits:=hall.get_world_3d().direct_space_state.intersect_shape(q)
				if not hits.is_empty():blocked.append({"at":[xy.x,xy.y],"body":str(hits[0].collider.get_path())})
		check(name+": floor",unsupported.is_empty());check(name+": clearance",blocked.is_empty())
		observations.routes[name]={"samples":count,"unsupported":unsupported,"blocked":blocked}
	var identities:Array=[]
	for p in s.points:identities.append(p.get_instance_id())
	var pointer:=Node3D.new();root.add_child(pointer)
	var point=s.points[0]
	point.on_desktop_grab(pointer);await create_timer(.1).timeout
	point.global_position=s.to_global(s.place(s.Foragers.FOOD));s.playing=true;await create_timer(.1).timeout
	point.action();await create_timer(.1).timeout
	check("Holding pauses all ticks and records the hand in model coordinates",s.model.steps==0 and s.model.positions[0].distance_to(s.Foragers.FOOD)<.001 and s.model.velocities[0]==Vector2.ZERO)
	check("Held action selects the same point",s.witness==0)
	s.get_node("Step").pressed.emit();s.get_node("Replace").pressed.emit();s.get_node("Reset").pressed.emit()
	check("Held point blocks stepping and destructive resets",s.model.steps==0 and s.model.positions[0].distance_to(s.Foragers.FOOD)<.001)
	point.on_desktop_drop(pointer);await create_timer(.15).timeout
	s.get_node("Step").pressed.emit();await create_timer(.15).timeout
	check("Release and one tick change SEARCH to RETURN on that point",s.model.steps==1 and s.model.carrying[0] and s.cargo[0].visible and not s.sensors[0].visible)
	check("Pickup deposits a mark at the new position",s.model.values[s.model.index_at(s.model.positions[0])]>0)
	check("Selection ring follows the actual sphere",h.selected.global_position.distance_to(point.global_position-Vector3.UP*.065)<.001)
	await state_photo("carrying",h)
	point.on_desktop_grab(pointer);await create_timer(.1).timeout
	point.global_position=s.to_global(s.place(s.Foragers.HOME));await create_timer(.15).timeout
	check("Returning state survives moving the point by hand",s.model.carrying[0] and s.cargo[0].visible)
	point.on_desktop_drop(pointer);await create_timer(.15).timeout
	s.get_node("Step").pressed.emit();await create_timer(.15).timeout
	check("Home contact delivers once and restores search sensors",s.model.delivered==1 and not s.model.carrying[0] and not s.cargo[0].visible and s.sensors[0].visible)
	s.get_node("Step").pressed.emit();check("Remaining at home does not deliver again",s.model.delivered==1)
	await state_photo("delivered",h)
	s.get_node("Reset").pressed.emit()
	for i in range(300):s.single_step()
	check("Unassisted museum points complete the foraging cycle",s.model.delivered>0 and Array(s.model.values).max()>0)
	await state_photo("shared-trace",h)
	var kept=s.model.values.duplicate();var count:int=s.model.delivered;var ticks:int=s.model.steps
	s.get_node("Replace").pressed.emit()
	check("Replace keeps the shared trace, count and time",s.model.values==kept and s.model.delivered==count and s.model.steps==ticks and not s.playing and s.model.carrying.count(false)==6)
	await state_photo("new-agents",h)
	s.get_node("Reset").pressed.emit()
	check("Clear All resets the field, deliveries and clock",s.model.values.count(0.0)==256 and s.model.delivered==0 and s.model.steps==0)
	var same:=true
	for i in range(6):same=same and s.points[i].get_instance_id()==identities[i]
	check("All operations reuse the original six point instances",same)
	await state_photo("clear-all",h)
	s.get_node("Run").pressed.emit();await create_timer(.35).timeout
	check("Run resumes the original fixed-step model",s.playing and s.model.steps>0)
	s.get_node("Run").pressed.emit();var stopped:int=s.model.steps;await create_timer(.2).timeout
	check("Nearby control pauses the model again",not s.playing and s.model.steps==stopped)
	observations.natural_cycle={"ticks":ticks,"deliveries":count,"highest_trace_value":Array(kept).max()}
	observations.headset_tested=false;pointer.queue_free()
func state_photo(name:String,h:Node3D)->void:
	await snapshot(name,h.to_global(Vector3(.15,2.4,3)),h.to_global(Vector3(0,1.3,0)),68)
