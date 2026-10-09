extends "res://tools/probes/transformation_encounters.gd"
## Real museum placement capture. The elevated camera changes only the viewpoint.
func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var data: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/maps/"+map_id+"/map_data.json"))
	var dimensions: Dictionary=data.map_info.dimensions
	var w: float=dimensions.width
	var d: float=dimensions.depth
	var origin=hall.global_position+Vector3(0,0,4)
	# The detached survey camera should not look through the walker's held view model.
	var walker= museum.get("_player")
	if walker is Node3D:walker.visible=false
	var walk_camera=museum.get("_cam")
	if walk_camera is Node3D:walk_camera.visible=false
	observations.artifacts=[]
	if map_id=="VFM_08_Arena":
		var sentry=find_scene("/sentry_turret.gd");var dropper=find_scene("/ball_dropper.gd")
		check("targeting comparison has an actual source",sentry!=null and dropper!=null)
		if sentry!=null and dropper!=null:
			check("sentry selects balls rather than the visitor",not sentry.target_player and sentry.target_balls)
			var acquired=false
			for i in range(60):
				await create_timer(0.1).timeout
				if is_instance_valid(sentry.current_target):acquired=true;break
			check("sentry acquires a pooled ball in its own bay",acquired)
	for record in museum.get("_edit_records"):
		var node=record.get("node")
		if not is_instance_valid(node) or record.get("seg")!=hall:continue
		var bounds: AABB=museum.call("_seat_extent",node)
		observations.artifacts.append({"token":record.get("token"),"position":xyz(node.global_position-origin),"scale":xyz(node.scale),"bounds_position":xyz(bounds.position-origin),"bounds_size":xyz(bounds.size)})
	await snapshot("above",origin+Vector3(w*0.18,15,-2),origin+Vector3(w*0.5,0,d*0.49),68)
	await snapshot("entry",origin+Vector3(w*0.5,1.7,2.6),origin+Vector3(w*0.5,1.25,minf(d-3,18)),76)
	var plan_path="res://commons/artifacts/force_halls/curation.json"
	if not FileAccess.file_exists(plan_path):return
	var plan: Dictionary=JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	for row in plan.halls:
		if row.map!=map_id:continue
		var placed: Array=[]
		for a in observations.artifacts:placed.append(a.token)
		for a in row.placements:check("placed: "+str(a.token),a.token in placed)
		for p in row.get("walk",[]):
			check("supported route "+str(p),not floor_at(origin+Vector3(p[0],0,p[1])).is_empty())
		var walk: Array=row.get("walk",[])
		observations.route_obstructions=[]
		for i in range(walk.size()-1):
			var a=Vector3(walk[i][0],0,walk[i][1]);var b=Vector3(walk[i+1][0],0,walk[i+1][1])
			var supported=true;var clear=true
			var steps=int(ceil(a.distance_to(b)/0.4))
			for s in range(steps+1):
				var at=origin+a.lerp(b,float(s)/maxi(1,steps))
				if floor_at(at).is_empty():supported=false
				var shape=CapsuleShape3D.new();shape.radius=0.26;shape.height=1.6
				var q=PhysicsShapeQueryParameters3D.new();q.shape=shape;q.transform.origin=at+Vector3.UP*0.91;q.collision_mask=1|4
				var hits=hall.get_world_3d().direct_space_state.intersect_shape(q,8)
				for hit in hits:
					if is_instance_valid(walker) and (hit.collider==walker or walker.is_ancestor_of(hit.collider)):continue
					clear=false
					if observations.route_obstructions.size()<10:observations.route_obstructions.append({"at":xyz(at-origin),"collider":str(hit.collider.get_path())})
			check("continuous route floor "+str(i),supported)
			check("standing capsule clearance "+str(i),clear)
		var portal=museum.get("_portal_stream")
		var exit_data: Dictionary=portal.get("_exit")
		observations.exit=exit_data
		check("exit identified and clear",exit_data.has("door") and not exit_data.get("invalid",false))

func finish() -> void:
	var result={"room":map_id,"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Actual museum placement, elevated and eye-height renders, floor support and standing capsule sampled every 0.4 m along the stated perimeter route. Does not test every possible path or headset reach."}
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify(result,"  "))
	print("FORCES LAYOUT ",map_id," ",checks.size()-failures.size(),"/",checks.size());quit(0 if failures.is_empty() else 1)
