extends "res://commons/testing/probe_color_recovery.gd"
## Real Foundry capture at fixed loom-relative eye positions. No user save writes.
const OUT := "res://doc/reports/interfaces-2026-09-20/compact-pilot/"

func run() -> void:
	var variant := "before"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--variant="): variant = arg.trim_prefix("--variant=")
	await museum("Pattern_Foundry")
	var study := current_scene.find_child("RecipeStudy", true, false) as Node3D
	check(study != null, "Foundry recipe study instantiated")
	if study == null: quit(1); return
	var loom: Node3D = study.get_parent()
	loom.set_process(false)
	var wardrobe: Node = current_scene.get("_wardrobe")
	wardrobe.appearance_save_path = ""
	if is_instance_valid(wardrobe.costume): wardrobe.costume.visible = false
	var player: CharacterBody3D = current_scene.get("_player")
	var camera: Camera3D = current_scene.get("_cam")
	player.set_physics_process(false)
	current_scene.get("_feel").set_process(false)
	var views := {
		"approach": [Vector3(-3.1, 1.65, -1.4), Vector3(-3.1, 1.22, 0.6)],
		"controls": [Vector3(-3.1, 1.65, -0.65), Vector3(-3.1, 1.12, 0.1)]
	}
	var centres: Array = []
	for button in study.buttons:
		var centre: Vector3 = loom.to_local(button.global_position)
		centres.append([centre.x, centre.y, centre.z])
	for view in views:
		player.global_position += loom.to_global(views[view][0]) - camera.global_position
		camera.look_at(loom.to_global(views[view][1]))
		for frame in 8:
			current_scene.call("_cull_artifacts")
			await process_frame
		loom.set_process(false)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUT + variant + "-" + view + ".png")
	var report := {"variant": variant, "checks": checks, "failures": failures,
		"button_centres_in_loom": centres, "headset_tested": false,
		"camera": "Fixed loom-relative poses, same field of view; actual museum geometry"}
	FileAccess.open(OUT + variant + "-capture.json", FileAccess.WRITE).store_string(JSON.stringify(report, "\t"))
	print("COMPACT_CAPTURE ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
