extends "res://commons/testing/probe_physical_console_halls.gd"
## Actual hall: direct manipulation is an interface too.
func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run
	report.room = spec.room
	report.scope = "Actual authored hall; static reach, approach and native grab geometry. Desktop capture, no headset test."
	museum = load(folder + "museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter",spec.sequence)
	museum.set("start_map",spec.room)
	museum.set("plan_file",folder+"em_plan.json")
	root.add_child(museum)
	var started := Time.get_ticks_msec()
	while not museum.get("_museum_core_ready") and Time.get_ticks_msec()-started < 60000: await process_frame
	museum.set("_lazy_pending",0)
	museum.set_process(false)
	museum.set_physics_process(false)
	museum.call("flush_stamps")
	await create_timer(1).timeout
	var hall: Node3D
	for child in museum.get_children():
		if child is Node3D and child.get_meta("em_map","") == spec.room: hall = child; break
	check(hall != null,"Requested polyhedra hall built")
	if hall == null: finish(); return
	origin = hall.global_position
	for entry in museum.get("_edit_records"):
		if entry.get("seg") == hall and entry.get("token") == spec.token and entry.node.get_script() != null:
			if entry.node.get_script().resource_path.ends_with(spec.token+".gd"): artifact = entry.node; break
	check(artifact != null,"Authored artifact found")
	if artifact == null: finish(); return
	walker = museum.get("_player")
	if walker: walker.set_physics_process(false)
	artifact.set_process(false)
	var front := artifact.global_basis.z.normalized()
	front.y = 0
	front = front.normalized()
	feet = artifact.global_position + front*(.65 if spec.case == "pyramid" else .80)
	# The low plinth is the object support, not the visitor's floor.
	var floor_ray := PhysicsRayQueryParameters3D.create(feet+Vector3.UP*2,feet-Vector3.UP*4,1)
	if walker: floor_ray.exclude = [walker.get_rid()]
	var floor_hit := museum.get_world_3d().direct_space_state.intersect_ray(floor_ray)
	feet.y = floor_hit.position.y if not floor_hit.is_empty() else origin.y
	report.floor = {"height":feet.y-origin.y,"collider":str(floor_hit.collider.get_path()) if not floor_hit.is_empty() else "none"}
	var query := PhysicsShapeQueryParameters3D.new()
	query.shape = CapsuleShape3D.new()
	query.shape.radius = .22
	query.shape.height = 1.7
	query.collision_mask = 1
	if walker: query.exclude = [walker.get_rid()]
	query.transform.origin = feet+Vector3.UP*.87
	var state := museum.get_world_3d().direct_space_state
	var obstacles := state.intersect_shape(query)
	report.standing_obstacles = obstacles.map(func(o): return str(o.collider.get_path()))
	check(obstacles.is_empty(),"Standing capsule fits beside the exhibit")
	var approach := Vector3.ZERO
	report.approaches = []
	for direction in [front,front.rotated(Vector3.UP,PI/2),front.rotated(Vector3.UP,-PI/2)]:
		query.transform.origin = feet + direction + Vector3.UP*.87
		query.motion = -direction
		var clear := state.intersect_shape(query).is_empty()
		var travel := state.cast_motion(query)
		var supported := true
		for i in 6:
			var at: Vector3 = feet + direction*float(i)/5
			var ray := PhysicsRayQueryParameters3D.create(at+Vector3.UP*.2,at-Vector3.UP*.25,1)
			if walker: ray.exclude = [walker.get_rid()]
			supported = supported and not state.intersect_ray(ray).is_empty()
		var valid: bool = clear and travel[0]>.99 and supported
		if valid and approach.is_zero_approx(): approach = direction
		report.approaches.append({"direction":arr(direction),"clear":clear,"travel":travel[0],"supported":supported,"passed":valid})
	check(not approach.is_zero_approx(),"A supported clear final metre reaches the object")
	if walker: walker.global_position = feet
	museum.call("_cull_artifacts")
	artifact.set_process(false)
	var handles: Array = artifact.handle_nodes.values() if spec.case == "pyramid" else [artifact]
	for handle: Node3D in handles:
		var target: Vector3 = handle.global_position
		# Large held solids can be gripped on the near hull, not only at its centre.
		if spec.case != "pyramid": target += front*.3
		var horizontal := Vector2(target.x-feet.x,target.z-feet.z).length()
		var height := target.y-feet.y
		var ray := PhysicsRayQueryParameters3D.create(feet+Vector3.UP*1.2,target+(target-feet-Vector3.UP*1.2).normalized()*.02,5)
		if walker: ray.exclude = [walker.get_rid()]
		var hit := state.intersect_ray(ray)
		var clear: bool = not hit.is_empty() and hit.collider == handle
		report.controls.append({"label":str(handle.name),"height":height,"horizontal_distance":horizontal,"clear_ray":clear,"hit":str(hit.collider.get_path()) if not hit.is_empty() else "none"})
		check(height >= .65 and height <= 1.6,str(handle.name)+" in direct-grab working height band")
		# Opposite corners may require stepping around the plinth; report rather than pretending one pose reaches all.
		check(horizontal <= 1.15,str(handle.name)+" within the bounded specimen footprint")
		check(clear,str(handle.name)+" has a clear native grab ray")
	# Each vertex needs an actual near-grab pose; the front camera is not a reach proof.
	if spec.case == "pyramid":
		report.grab_poses = []
		for handle: Node3D in handles:
			var pose := {}
			for i in 8:
				var direction := front.rotated(Vector3.UP,TAU*float(i)/8)
				var candidate := artifact.global_position+direction*.65
				candidate.y = feet.y
				var distance := Vector2(candidate.x-handle.global_position.x,candidate.z-handle.global_position.z).length()
				if distance > .70: continue
				query.motion = Vector3.ZERO
				query.transform.origin = candidate+Vector3.UP*.87
				if not state.intersect_shape(query).is_empty(): continue
				var ground := PhysicsRayQueryParameters3D.create(candidate+Vector3.UP*.2,candidate-Vector3.UP*.25,1)
				if walker: ground.exclude = [walker.get_rid()]
				if state.intersect_ray(ground).is_empty(): continue
				var from := candidate+Vector3.UP*1.2
				var reach_ray := PhysicsRayQueryParameters3D.create(from,handle.global_position+(handle.global_position-from).normalized()*.02,5)
				if walker: reach_ray.exclude = [walker.get_rid()]
				var grab_hit := state.intersect_ray(reach_ray)
				if not grab_hit.is_empty() and grab_hit.collider==handle:
					pose = {"handle":str(handle.name),"feet":arr(candidate-origin),"horizontal_distance":distance}
					break
			check(not pose.is_empty(),str(handle.name)+" has a supported clear near-grab pose within 0.70 m")
			report.grab_poses.append(pose)
	var panel: Node3D = artifact.get_node_or_null("RecoveryPanel")
	if panel:
		panel.call("refresh")
		var button: Node3D = panel.get_node("ResetButton")
		inspect_target(button,button.get_node("InteractableAreaButton/CollisionShape3D").global_position,"Reset",button)
	camera = Camera3D.new()
	root.add_child(camera)
	camera.current = true
	camera.global_position = feet+Vector3.UP*1.65
	camera.fov = 75
	camera.look_at(artifact.global_position+Vector3.UP*.3)
	await capture("reading")
	if panel:
		camera.look_at(panel.global_position)
		camera.fov = 48
		await capture("controls")
	camera.global_position = feet+(approach if not approach.is_zero_approx() else front)*.8+Vector3.UP*1.65
	camera.fov = 78
	camera.look_at(artifact.global_position+Vector3.UP*.3)
	await capture("encounter")
	report.artifact_position = arr(artifact.global_position-origin)
	finish()
