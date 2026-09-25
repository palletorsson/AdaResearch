extends "res://tools/probes/transformation_encounters.gd"
## Uses the isolated production museum. Hand displacements are supplied test inputs.

func landing_checks() -> void:
	var demos: Dictionary = {}
	for n in hall.find_children("*", "Node3D", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("/translation_cube_demo.gd"):
			demos[n.course] = n
	check("both existing door mechanisms loaded", demos.has("lift_lateral") and demos.has("free"))
	if demos.size() != 2: return
	for key in ["lift_lateral", "free"]:
		var demo: Node3D = demos[key]
		check(key+" trace opt-in reached scene", demo.trace_motion)
		check(key+" placement yaw retained", is_equal_approx(absf(demo.rotation_degrees.y),180))
		var approach := demo.to_global(Vector3(0,-0.8,1))
		var floor := floor_at(approach)
		check(key+" approach has standing floor",not floor.is_empty() and absf(floor.position.y-approach.y)<0.05)
		observations[key+"_handle_height"] = demo._left_door._knob.global_position.y-approach.y
		for door: Node3D in [demo._left_door,demo._right_door]:
			door._knob.freeze=true
			door.set_physics_process(false)
			door.reset()
			door._knob.picked_up.emit(door._knob)
			var start: Vector3 = door._knob_start()
			var proposal: Vector3 = start + door.phase1_dir*0.10 + door.phase2_dir*0.20
			door._knob.position=proposal
			door._physics_process(1.0/60)
			check(key+" accepts pickup event "+door.name,door._is_grabbed)
			if key == "lift_lateral":
				check("guided diagonal retains only lift "+door.name,door._knob.position.is_equal_approx(start+door.phase1_dir*0.10))
			else:
				check("free diagonal retains both components "+door.name,door._knob.position.is_equal_approx(proposal))
			check(key+" trace records constrained result "+door.name,door.motion_trace.points[-1].is_equal_approx(door._knob.position))
			check(key+" trace adds no collider "+door.name,door.motion_trace.get_child_count()==0)
		await snapshot(key+"-first-gesture",demo.to_global(Vector3(0,1.0,2.6)),demo.to_global(Vector3(0,0.63,0.03)),46)
		for door: Node3D in [demo._left_door,demo._right_door]:
			door.reset()
			check(key+" reset clears trace "+door.name,door.motion_trace.points.size()==1 and door.motion_trace.mesh.get_surface_count()==0)
			var start: Vector3=door._knob_start()
			if key == "lift_lateral":
				for i in range(1,26): move_handle(door,start+door.phase1_dir*door.target_y*float(i)/25)
				check("lift unlocks second leg "+door.name,door.get_phase()==2)
				for i in range(1,41): move_handle(door,start+door.phase1_dir*door.target_y+door.phase2_dir*door.target_x*float(i)/40)
			else:
				for i in range(1,51): move_handle(door,start+(door.phase1_dir*door.target_y+door.phase2_dir*door.target_x)*float(i)/50)
			var target: Vector3=start+door.phase1_dir*door.target_y+door.phase2_dir*door.target_x
			check(key+" reaches shared displacement "+door.name,door.is_goal_reached() and door._knob.position.is_equal_approx(target))
			check(key+" records a visible trail "+door.name,door.motion_trace.points.size()>10 and door.motion_trace.mesh.get_surface_count()==1)
			door._knob.dropped.emit(door._knob)
			var point_count: int=door.motion_trace.points.size()
			move_handle(door,target-door.phase2_dir*0.03)
			check(key+" released movement is not a hand trace "+door.name,not door._is_grabbed and door.motion_trace.points.size()==point_count)
			move_handle(door,target)
		await snapshot(key+"-completed",demo.to_global(Vector3(0,1.0,2.6)),demo.to_global(Vector3(0,0.63,0.03)),46)
	var free: Node3D=demos.free
	for door: Node3D in [free._left_door,free._right_door]:
		door.reset();door._knob.picked_up.emit(door._knob)
		var start: Vector3=door._knob_start()
		for i in range(1,81):
			var t:=float(i)/80
			move_handle(door,start+door.phase2_dir*door.target_x*t+door.phase1_dir*(door.target_y*t+0.075*sin(PI*t)))
		check("free curved route also reaches the goal "+door.name,door.is_goal_reached())
		door._knob.dropped.emit(door._knob)
	await snapshot("free-curved",free.to_global(Vector3(0,1.0,2.6)),free.to_global(Vector3(0,0.63,0.03)),46)
	var legacy: Node3D=load("res://commons/primitives/translation/translation_cube_demo.tscn").instantiate()
	root.add_child(legacy)
	check("unconfigured legacy scene has no added trace",not legacy.trace_motion and legacy._left_door.motion_trace==null)
	legacy.queue_free()
	var bounded:=preload("res://commons/primitives/translation/accepted_motion_trace.gd").new()
	root.add_child(bounded);bounded.reset(Vector3.ZERO)
	for i in range(1,280): bounded.record(Vector3(float(i)*0.007,0,0))
	check("long traces stay bounded",bounded.points.size()==bounded.MAX_POINTS)
	var count:int=bounded.points.size();bounded.record(Vector3(NAN,0,0))
	check("invalid sample does not corrupt trace",bounded.points.size()==count)
	bounded.queue_free()
	var mid:Vector3=(demos.free.global_position+demos.lift_lateral.global_position)*0.5
	await snapshot("translation-exit-terrace",mid+Vector3(0,1.8,-5),mid+Vector3(0,0.3,0),62)
	# Finish calls the shared reporter. This is supplied motion, not a headset drag test.

func move_handle(door:Node3D,requested:Vector3) -> void:
	door._knob.position=requested
	door._physics_process(1.0/60)
