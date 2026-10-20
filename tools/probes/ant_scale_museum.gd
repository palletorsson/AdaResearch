extends "res://tools/probes/transformation_encounters.gd"
var complete := false
func landing_checks() -> void:
	museum.call("flush_stamps")
	var stream = museum.get("_portal_stream")
	if stream != null: stream.process_mode = Node.PROCESS_MODE_DISABLED
	var player = museum.get("_player")
	if player is Node3D:
		player.hide(); player.process_mode = Node.PROCESS_MODE_DISABLED; player.global_position = Vector3(0,-100,0)
	camera.set_cull_mask_value(19,false)
	var exposure := CameraAttributesPractical.new(); exposure.exposure_multiplier = .55; camera.attributes = exposure
	var atlas := find_scene("/ant_scale_atlas.gd")
	check("Three-scale comparison is installed in ACO hall", atlas != null)
	check("Existing colony lesson remains in the same hall", find_scene("/ant_colony_walk.gd") != null)
	if atlas == null: return
	var path: Array[Vector3] = []
	var corners: Array[Vector3] = [Vector3(-12,0,0),Vector3(-8,0,0),Vector3(-8,0,-1.25),Vector3(-4,0,-1.25),Vector3(0,0,-1.25)]
	for i in range(corners.size()-1):
		var count := ceili(corners[i].distance_to(corners[i+1])/.15)
		for j in range(count+1): path.append(corners[i].lerp(corners[i+1],float(j)/count))
	for x in [-3.8,0.0,3.8]:
		for i in range(41): path.append(Vector3(x,0,-4+i*.2))
	var supported := true; var clear := true
	var capsule := CapsuleShape3D.new(); capsule.radius = .24; capsule.height = 1.7
	for p in path:
		var world := atlas.to_global(p)
		if floor_at(world).is_empty(): supported = false
		var query := PhysicsShapeQueryParameters3D.new(); query.shape = capsule; query.collision_mask = 1
		query.transform.origin = world + Vector3.UP*.9
		var hits := hall.get_world_3d().direct_space_state.intersect_shape(query)
		if not hits.is_empty():
			clear = false; print("ATLAS BLOCK ", p, " ", hits[0].collider.get_path())
	check("Opening and entire walk-in field have floor", supported)
	check("Opening and floor field are clear of walls", clear)
	# Physical approach to each side of the three podiums.
	var controls_clear := true
	for z in [-2.6,0,2.5]:
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.collision_mask = 1
		q.transform.origin = atlas.to_global(Vector3(-7.25,.9,z))
		controls_clear = controls_clear and hall.get_world_3d().direct_space_state.intersect_shape(q).is_empty()
	check("All controls can be approached from the hall side", controls_clear)
	var floor := floor_at(atlas.to_global(atlas.HOME+Vector3(-.75,-1.18,0)))
	check("Carried tile is docked at reachable height", not floor.is_empty() and atlas.point.global_position.y-floor.position.y>1.05 and atlas.point.global_position.y-floor.position.y<1.35)
	atlas.select(0); atlas.restart(); atlas.model.playing = true
	await create_timer(15).timeout
	check("Trail engine advances in the actual museum", atlas.model.steps[0] >= 100)
	atlas.toggle_play()
	await snapshot("trails-above", atlas.to_global(Vector3(-3.5,13,8)), atlas.to_global(Vector3(-2,0,0)), 72)
	await snapshot("trails-walk-in", atlas.to_global(Vector3(-3.5,1.7,4.8)), atlas.to_global(Vector3(.4,.05,-.8)), 86)
	atlas.select(1); atlas.model.playing = true
	await create_timer(20).timeout
	check("Turmites also advance in the actual museum", atlas.model.steps[1] >= 1200)
	atlas.toggle_play()
	await snapshot("turmites-above", atlas.to_global(Vector3(-3.5,13,8)), atlas.to_global(Vector3(-2,0,0)), 72)
	await snapshot("hall-above", atlas.to_global(Vector3(-9,36,17)), atlas.to_global(Vector3(-9,0,0)), 64)
	await snapshot("table", atlas.to_global(Vector3(-7.5,2.2,4.1)), atlas.to_global(Vector3(-6,.96,2.5)), 64)
	await snapshot("controls", atlas.to_global(Vector3(-7.1,1.9,1)), atlas.to_global(Vector3(-6,1.12,0)), 64)
	var pointer := Node3D.new(); root.add_child(pointer); atlas.point.on_desktop_grab(pointer)
	atlas.point.global_position = atlas.to_global(Vector3(-5.5,1.55,-2.1))
	atlas.point.rotation.x = .35
	await create_timer(.15).timeout
	check("Actual pickup moves the handheld copy", atlas.point.held() and atlas.point.position.distance_to(atlas.HOME)>.3)
	check("Handheld and floor still share one displayed texture", atlas.views[0].plane.material_override == atlas.views[2].plane.material_override)
	await snapshot("hand", atlas.to_global(Vector3(-5.4,2.15,-1.3)), atlas.point.to_global(Vector3(0,.06,-.31)), 65)
	var stopped: String = atlas.model.digest()
	await create_timer(.3).timeout
	check("Pause preserves both model histories", atlas.model.digest() == stopped)
	atlas.point.action(); await create_timer(.2).timeout
	check("Held trigger resumes the pattern", atlas.model.playing and atlas.model.digest() != stopped)
	atlas.point.action(); atlas.point.on_desktop_drop(pointer); await create_timer(5.3).timeout
	check("Released point returns to its dock without changing the pattern", atlas.point.position.distance_to(atlas.HOME)<.01 and not atlas.model.playing)
	observations.steps = atlas.model.steps; observations.headset_tested = false; complete = true
	pointer.queue_free()
func finish() -> void:
	FileAccess.open(folder+"report.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":complete and failures.is_empty(),"checks":checks,"failures":failures,"observations":observations},"  "))
	quit(0 if complete and failures.is_empty() else 1)
