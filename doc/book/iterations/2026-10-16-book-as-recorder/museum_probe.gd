extends "res://tools/probes/transformation_encounters.gd"

func run() -> void:
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	folder = spec.run; map_id = spec.room
	root.size = Vector2i(1600,1200)
	museum = load(folder+"museum_snapshot.tscn").instantiate()
	museum.set("EM_CONTROL",folder+"control.json")
	museum.set("_hand_path",folder+"necklace_hand.json")
	museum.set("_overrides_path",folder+"em_overrides.json")
	museum.set("start_chapter",spec.sequence);museum.set("start_map",map_id)
	museum.set("plan_file",folder+"plan.json")
	root.add_child(museum);current_scene=museum
	var started := Time.get_ticks_msec()
	var wall: Node3D
	while Time.get_ticks_msec()-started < 90000:
		for child in museum.get_children():
			if child is Node3D and str(child.get_meta("em_map",""))==map_id:
				hall=child; wall=hall.get_node_or_null("BookArrivalWall");break
		if wall != null and wall.finished: break
		await process_frame
	check("actual portal arrival creates the wall works",wall != null and wall.finished)
	if wall == null or not wall.finished: finish();return
	check("all three installations captured at their requested moment",wall.record.images.size()==3 and wall.record.errors.is_empty())
	observations["capture"] = wall.record
	for item in wall.record.images:
		if item.id=="page":
			check("page captured only when full and settled",item.state.full_and_settled)
			check("hall starts with ten seeded rows",item.state.initial_rows==10)
			check("page capture follows arrival after natural filling",item.capture_when=="page_full" and item.after_arrival_ms>1000)
	museum.set_process(false);museum.set_physics_process(false)
	if museum.get("_portal_stream") != null: museum.get("_portal_stream").set_process(false)
	camera=Camera3D.new();root.add_child(camera)
	var previous: Camera3D = museum.get("_cam")
	if previous != null:
		for timer in previous.find_children("*","Timer",true,false): timer.stop()
	for frame in 3: await process_frame
	check("capture worlds released in actual hall",wall.find_children("*","SubViewport",true,false).is_empty())
	for item in wall.record.images:
		var picture: MeshInstance3D=wall.frames[item.id]
		var mount: Node3D=picture.get_parent()
		var front: Vector3=mount.global_basis.z
		var ray:=PhysicsRayQueryParameters3D.create(mount.global_position+front*0.3,mount.global_position-front*0.3,1)
		check("frame backed by a wall: "+str(item.id),not hall.get_world_3d().direct_space_state.intersect_ray(ray).is_empty())
		check("frame image agrees with archive: "+str(item.id),picture.get_meta("book_image_sha256")==item.sha256)
		var path: String=wall.record.folder.path_join(item.image)
		DirAccess.copy_absolute(ProjectSettings.globalize_path(path),ProjectSettings.globalize_path(folder+item.id+"-arrival.png"))
		await snapshot(item.id+"-on-wall",mount.global_position+front*2.5+Vector3.UP*0.1,mount.global_position,55)
	var geiger: Node3D=wall.find_artifact(hall,"geiger_counter")
	await snapshot("geiger-radial-dial",geiger.to_global(Vector3(0.62,2.5,1.5)),geiger.to_global(Vector3(0.62,2.45,0)),30)
	observations["scope"]="Real desktop arrival; page starts with ten seeded rows then fills naturally before capture; no staged interaction; actual wall positions and identical book PNG. Headset performance and physical readability not tested."
	var window: Node3D = wall.find_artifact(hall,"seed_replay_demo")
	var sampler: Node3D = window.get("_movement_sampler")
	check("restored sampler exists and is visible",sampler != null and sampler.is_visible_in_tree())
	check("restored sampler has active interactions",not sampler.get_meta("editor_removed",false) and sampler.get("point").collision_layer != 0)
	check("sampler remains connected to the hall seed",sampler.received.is_connected(window._receive_movement_seed))
	var map_frame: Transform3D = window.get_parent().global_transform * window.get_meta("artifact_map_frame")
	check("sampler keeps its authored position",sampler.global_position.distance_to(map_frame * Vector3(9.5,0,18.5)) < 0.001)
	var approach: Vector3 = sampler.global_position + sampler.global_basis.z * 0.85
	var ground := PhysicsRayQueryParameters3D.create(approach+Vector3.UP*0.7,approach-Vector3.UP,1)
	check("sampler approach has a floor",not hall.get_world_3d().direct_space_state.intersect_ray(ground).is_empty())
	await snapshot("move-keep-restored",sampler.global_position+sampler.global_basis.z*2.8+Vector3.UP*1.65,sampler.to_global(Vector3(0,1.45,0)),50)
	var ride: Node3D = wall.find_artifact(hall,"random_return")
	ride.enabled_motion = false
	ride.restart(435)
	ride.advance(2.7)
	var pointer := Node3D.new();hall.add_child(pointer)
	var body := CharacterBody3D.new();hall.add_child(body)
	body.global_position = ride.point.global_position - Vector3.UP
	ride.point.on_desktop_grab(pointer)
	ride.rider = body
	ride.rider_offset = body.global_position - ride.point.global_position
	check("grab opts into ride",ride.point.held())
	var release_at: Vector3 = ride.point.position
	var body_at: Vector3 = body.global_position
	ride.point.on_desktop_drop()
	ride._physics_process(0.0)
	check("release disconnects rider immediately",ride.rider == null and not ride.point.held())
	var incoming := Vector3(0.3,-0.1,0.4)
	check("released body receives no carry correction",ride.carry_velocity(body,0.016,incoming)==incoming)
	ride.advance(2.3)
	check("sphere continues after release",ride.point.position.distance_to(release_at)>0.1)
	ride.advance(3.5)
	check("sphere returns to its centre",ride.point.position.distance_to(ride.CENTRE)<0.0001)
	check("return does not transport released body",body.global_position==body_at)
	observations["release_scope"]="Synthetic desktop grab/drop and carry adapter state in the actual loaded hall. Not a physical VR trial. Schematic positions are authored; the continued motion and disconnection rule are tested."
	body.queue_free();pointer.queue_free()

	finish()
