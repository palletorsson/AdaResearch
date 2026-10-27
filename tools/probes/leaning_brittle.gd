extends "res://tools/probes/leaning_brittle_calibrate.gd"
func arr(value: Vector3) -> Array:return [value.x,value.y,value.z]
func stable(work: Node3D) -> bool:
	var state: Dictionary = work.observations()
	return state.angles.LeftPlank>45 and state.angles.RightPlank>45 and work.bodies.Cube.position.y>1.6 and state.contacts.has("Cube + LeftPlank") and state.contacts.has("Cube + RightPlank")

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out=" ):out = arg.trim_prefix("--out=")
	scene = Node3D.new();root.add_child(scene);current_scene = scene
	var ground := StaticBody3D.new();ground.position.y = -18.1;scene.add_child(ground);var shape := CollisionShape3D.new();shape.shape = BoxShape3D.new();shape.shape.size = Vector3(20,.2,20);ground.add_child(shape)
	var rows: Array = []
	for yaw in [0.0,.37,PI]:
		var work := fixture();work.rotation.y = yaw;work.reset_take();await tick(1800)
		check("untouched stack stays standing for 30 seconds at yaw "+str(yaw),stable(work))
		check("gravity is live on every loose part at yaw "+str(yaw),work.bodies.values().all(func(body):return not body.freeze and body.gravity_scale==1 and not body.lock_rotation))
		check("loose ball remains in the physical tray",work.bodies.Ball.position.y>.65 and absf(work.bodies.Ball.position.x)<1.3 and absf(work.bodies.Ball.position.z)<.66)
		rows.append({"case":"idle","yaw":yaw,"state":work.observations()});work.queue_free();await tick(5)
	for id in ["LeftPlank","RightPlank","Cube","LeftWedge","RightWedge"]:
		var work := fixture();await tick(300);check(id+" starts in actual equilibrium",stable(work))
		var body: Node3D = work.bodies[id];var at: Vector3 = body.global_position
		if "Wedge" in id:at += Vector3.UP*.08
		var pointer := Node3D.new();scene.add_child(pointer);pointer.global_position = at+work.global_basis.z*2+Vector3.UP*.15
		var ray := PhysicsRayQueryParameters3D.create(pointer.global_position,at,1<<20);var hit := scene.get_world_3d().direct_space_state.intersect_ray(ray)
		check(id+" actual pointer ray reaches the intended surface",not hit.is_empty() and hit.collider==body)
		var impulses: Array = [];body.tapped.connect(func(impulse):impulses.append(impulse))
		if not hit.is_empty() and hit.collider==body:
			body.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.MOVED,pointer,body,hit.position,hit.position));await tick(120);check(id+" hover alone does not release anything",stable(work) and impulses.is_empty())
			body.pointer_event(XRToolsPointerEvent.new(XRToolsPointerEvent.Type.PRESSED,pointer,body,hit.position,hit.position));await tick(480)
			check(id+" gets exactly one finite contact impulse",impulses.size()==1 and absf(impulses[0].length()-body.mass*.25)<.0001)
			var state: Dictionary = work.observations();check(id+" light tap dismantles the stack",state.angles.LeftPlank<25 and state.angles.RightPlank<25 and work.bodies.Cube.position.y<1.3)
			rows.append({"case":id,"state":state,"cube":arr(work.bodies.Cube.position),"impulse":arr(impulses[0]) if not impulses.is_empty() else null})
		work.reset_take();await tick(300);check(id+" reset restores a live precarious stack",stable(work) and work.bodies.values().all(func(item):return not item.freeze))
		work.queue_free();pointer.queue_free();await tick(5)
	var report := {"passed":failed.is_empty(),"checks":checks,"failures":failed,"rows":rows,"scope":"Untouched gravity equilibrium for 30 seconds at three rotations and negative height. Real pointer-ray surface and native one-impulse tap on both planks, cube and both chocks; hover alone never releases anything. This does not claim every possible infinitesimal touch or force direction causes collapse."}
	FileAccess.open(out.path_join("leaning-brittle-physics-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(report,"  "));print("MATTER_REFERENCE_RESULT ",JSON.stringify(report));quit(0 if failed.is_empty() else 1)
