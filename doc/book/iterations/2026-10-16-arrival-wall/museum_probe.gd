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
	finish()
