extends "res://tools/probes/transformation_encounters.gd"
## Uses an isolated snapshot prepared by launch.py; the museum supplies the walker.
func landing_checks() -> void:
	var study = load("res://doc/book/experiments/random-definition/seed-bench-001/runtime/seed_study.tscn").instantiate()
	study.position = Vector3(10.5,0,18.5); study.rotation_degrees.y = -90
	hall.add_child(study)
	var walker: Node3D = museum.get("_player")
	var eye: Camera3D = museum.get("_cam")
	walker.global_position = study.to_global(Vector3(0,0,1.7))
	var yaw: float = study.global_rotation.y
	var pitch := -0.28
	walker.rotation.y = yaw; eye.rotation = Vector3(pitch,0,0)
	museum.set("_yaw",yaw); museum.set("_pitch",pitch)
	var feel: Node = museum.get("_feel")
	if feel != null and feel.has_method("resync_view"): feel.call("resync_view",yaw,pitch)
	camera.queue_free(); eye.make_current()
	museum.set_process(true); museum.set_physics_process(true)
	print("SEED BENCH READY: F1/F2 compare; F3 keep; F5 export; F8 next seed; F4 replay; F7 clear; F6 import.")

func finish() -> void:
	if hall == null: quit(1)
	elif "--pilot-smoke" in OS.get_cmdline_user_args():
		await create_timer(1.0).timeout
		var file := FileAccess.open(folder + "visit-smoke.json", FileAccess.WRITE)
		file.store_string(JSON.stringify({"passed": true, "kind": "launcher_smoke_only",
			"camera_is_museum_camera": root.get_camera_3d() == museum.get("_cam"),
			"physical_VR": "not_tested", "human_visit": "not_tested"}, "\t"))
		quit()
	# A human visit stays open. Closing the window ends it; no observation is inferred.
