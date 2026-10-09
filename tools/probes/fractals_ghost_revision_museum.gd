extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var stream = museum.get("_portal_stream")
	if stream != null:
		stream.set_process(false)
		stream.set_physics_process(false)
	var walker = museum.get("_player")
	if walker is Node3D:
		walker.hide()
		walker.set_process(false)
		walker.set_physics_process(false)
		walker.global_position = Vector3(0, -100, 0)
	var old_camera = museum.get("_cam")
	if old_camera is Node3D:
		old_camera.hide()
	camera.set_cull_mask_value(19, false)
	var wardrobe = museum.get("_wardrobe")
	if wardrobe != null and is_instance_valid(wardrobe.get("costume")):
		wardrobe.get("costume").hide()
	var spec: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OS.get_cmdline_user_args()[0]))
	var study = load(spec.composition).new()
	study.position = Vector3(9.5, 0, 5.5)
	hall.add_child(study)
	await create_timer(0.3).timeout
	check("Student revision instantiates fifteen branches, witness and two grips", study.segment_count == 15 and study.witness != null and study.points.size() == 2)
	check("Temporary study has museum floor below", not floor_at(study.global_position).is_empty())
	await snapshot("witness", study.to_global(Vector3(1.4, 1.30, 1.05)), study.to_global(Vector3(1.4, 1.25, 0)), 58)
	await snapshot("overview", study.to_global(Vector3(0.55, 1.65, 1.7)), study.to_global(Vector3(0.55, 1.4, 0)), 95)
	observations.scope = "Student's unedited observation-led witness temporarily mounted in the real Synthesis hall. Captures view its +Z face. No permanent placement or physical VR testing."
	study.queue_free()
