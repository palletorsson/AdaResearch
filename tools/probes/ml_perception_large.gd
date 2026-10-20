extends "res://tools/probes/transformation_encounters.gd"

func body_clear(p: Vector3) -> bool:
	var shape := CapsuleShape3D.new()
	shape.radius = 0.25
	shape.height = 1.75
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = shape
	query.transform.origin = p + Vector3.UP * 0.94
	query.collision_mask = 1
	# Probe the player's clearance against the room, not against their own body.
	var walker:=museum.get_node_or_null("Walker") as CollisionObject3D
	if walker!=null:query.exclude=[walker.get_rid()]
	var hits:=hall.get_world_3d().direct_space_state.intersect_shape(query)
	for hit in hits:
		print("[space-blocked] ",p," ",hit.collider.get_path())
	return hits.is_empty()

func standing_zone(label: String, owner: Node3D, xs: Array, zs: Array) -> void:
	var supported := true
	var clear := true
	for x: float in xs:
		for z: float in zs:
			var p := owner.to_global(Vector3(x,0,z))
			supported = supported and not floor_at(p).is_empty()
			clear = clear and body_clear(p)
	check(label + " has continuous floor", supported)
	check(label + " clears a standing body", clear)

func landing_checks() -> void:
	var stage := find_scene("/vogue_timeline.gd")
	check("actual museum contains dance stage", stage != null)
	if stage == null:return
	stage.set_process(false);stage.render_pose(8.0)
	var station := stage.get_node("PoseLearningStation") as Node3D
	station.set_process(false)
	check("learning station occupies its map-authored bay", station.position.is_equal_approx(Vector3(11,0,-1)) and is_zero_approx(station.rotation.y))
	check("activity centres are more than eleven metres apart", stage.global_position.distance_to(station.global_position)>11.0)
	check("separate learning bay built only once", station.find_children("LearningBay","Node3D",false,false).size()==1)
	check("museum arrives without invented training", station.model.examples.is_empty() and not station.model.trained)
	standing_zone("learning movement area",station,[-1.0,-0.5,0.0,0.5,1.0],[1.4,1.9,2.4])
	standing_zone("dance approach",stage,[-1.0,0.0,1.0],[2.0,2.5])
	# Across the front passage, then into the learning bay. Three parallel lanes.
	var walk_floor:=true;var walk_clear:=true
	for lane: float in [-0.45,0.0,0.45]:
		for i in 45:
			var p:Vector3=stage.to_global(Vector3(float(i)*0.25,0,6.0+lane))
			walk_floor=walk_floor and not floor_at(p).is_empty()
			walk_clear=walk_clear and body_clear(p)
		for i in 21:
			var p:Vector3=stage.to_global(Vector3(11+lane,0,6.0-float(i)*0.25))
			walk_floor=walk_floor and not floor_at(p).is_empty()
			walk_clear=walk_clear and body_clear(p)
	check("passage between activities has floor throughout",walk_floor)
	check("three sampled walking lanes avoid walls and controls",walk_clear)
	var exit_clear:=true
	var exit_floor:=true
	for i in 33:
		var p:Vector3=stage.to_global(Vector3(-float(i)*0.25,0,6.0))
		exit_clear=exit_clear and body_clear(p)
		exit_floor=exit_floor and not floor_at(p).is_empty()
	for i in 6:
		var p:Vector3=stage.to_global(Vector3(-8,0,6.0+float(i)*0.25))
		exit_clear=exit_clear and body_clear(p)
		exit_floor=exit_floor and not floor_at(p).is_empty()
	check("forecourt route to next-hall portal is supported",exit_floor)
	check("forecourt route to next-hall portal is unobstructed",exit_clear)
	var wall_a:Vector3=stage.to_global(Vector3(5,1.4,0))
	var wall_b:Vector3=stage.to_global(Vector3(7,1.4,0))
	check("native partition separates the bays",not hall.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(wall_a,wall_b,1)).is_empty())
	# Positioning can be reapplied without replacing the sphere or its lesson objects.
	var sphere_id:int=station.sphere.get_instance_id()
	var model_id:int=station.model.get_instance_id()
	stage.apply_grid_config({"learning_x":"11","learning_z":"-1","learning_yaw":"0","learning_bay":"1"})
	check("reapplying placement keeps sphere and learner identity",station.sphere.get_instance_id()==sphere_id and station.model.get_instance_id()==model_id)
	check("reapplying placement does not duplicate the bay",station.find_children("LearningBay","Node3D",false,false).size()==1)
	await snapshot("passage",stage.to_global(Vector3(5,1.7,7.0)),stage.to_global(Vector3(5,1.45,0)),76)
	await snapshot("overview",stage.to_global(Vector3(4,22,12)),stage.to_global(Vector3(3,0,2)),58)
	await snapshot("dance",stage.to_global(Vector3(0.5,1.7,2.8)),stage.to_global(Vector3(0,1.4,-1.1)),69)
	await snapshot("learning",station.to_global(Vector3(0.35,1.75,3.05)),station.to_global(Vector3(0.25,1.45,-0.2)),60)
	station.command("HEIGHT")
	check("height lesson still opens in the separate bay",station.lesson=="HEIGHT")
	station.command("PHRASE")
	check("phrase lesson still opens in the separate bay",station.lesson=="PHRASE")
	await snapshot("phrase",station.to_global(Vector3(0.35,1.75,3.05)),station.to_global(Vector3(0.25,1.45,-0.2)),60)
	station.command("POSE")
	check("all modes keep the same sphere",station.sphere.get_instance_id()==sphere_id)
	check("phrase exit restores the shared label width",is_equal_approx(station.status.width,690.0))
	# Supplied tracker data at the NEW location, exercising the production near gate.
	var origin:=XROrigin3D.new();root.add_child(origin)
	var head_pos:=station.to_global(Vector3(0,1.6,1.4))
	var ht:=XRPositionalTracker.new();ht.name=&"head";ht.type=XRServer.TRACKER_HEAD
	ht.set_pose(&"default",Transform3D(Basis.IDENTITY,head_pos),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	XRServer.add_tracker(ht)
	var xr_camera:=XRCamera3D.new();origin.add_child(xr_camera);stage.head=xr_camera
	var trackers:Array=[ht]
	for side in [&"left_hand",&"right_hand"]:
		var tr:=XRControllerTracker.new();tr.name=side;tr.type=XRServer.TRACKER_CONTROLLER
		var at:=head_pos+Vector3(-0.4 if side==&"left_hand" else 0.4,-0.1,-0.6)
		tr.set_pose(&"default",Transform3D(Basis.IDENTITY,at),Vector3.ZERO,Vector3.ZERO,XRPose.XR_TRACKING_CONFIDENCE_HIGH)
		XRServer.add_tracker(tr);trackers.append(tr)
		var controller:=XRController3D.new();controller.tracker=side;origin.add_child(controller)
		if side==&"left_hand":stage.left=controller
		else:stage.right=controller
	await tick();await tick()
	check("tracked visitor can teach outside dance proximity",station.tracked_here() and stage.head.global_position.distance_to(stage.global_position)>5.0)
	var button=station.controls.find_child("Btn_0",true,false).get_node("InteractableAreaButton")
	button.button_pressed.emit(button)
	check("real button starts capture in new bay",station.capture_label==0)
	for i in 76:station._process(0.05)
	check("whole pose captured at relocated station",station.model.examples.size()==1 and station.capture_label==-1)
	if station.model.examples.size()==1:
		var row:Array=station.model.examples[0].x
		check("movement remains head-relative after relocation",absf(row[0]+0.4/0.65)<0.001 and absf(row[2]+0.6/0.65)<0.001)
	for tracker in trackers:XRServer.remove_tracker(tracker)
	origin.queue_free()
	observations={"scope":"Actual museum floor, collision, controls and rendered images. Body clearance uses a 0.5 m diameter, 1.75 m capsule. No headset comfort claim.","dance_world":xyz(stage.global_position),"learning_world":xyz(station.global_position),"centre_distance_m":stage.global_position.distance_to(station.global_position)}

func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if failures.is_empty() else 1)
