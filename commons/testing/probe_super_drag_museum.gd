extends "res://commons/testing/probe_color_recovery.gd"
## Exercise the actual museum loader, including its camera suppression path.
func run() -> void:
	await museum("Pattern_Foundry")
	var station: Node3D
	for n in current_scene.find_children("*", "Node3D", true, false):
		if n.has_method("cycle_outfit") and n.has_method("update_reflection"):
			station = n
			break
	check(station != null, "museum instantiated Super Drag Looking Glass from registry")
	if station != null:
		var head: Camera3D = current_scene.get("_cam")
		var wardrobe: Node = current_scene.get("_wardrobe")
		check(head != null and wardrobe != null, "museum has actual player camera and wardrobe")
		if head != null and wardrobe != null:
			# Test without writing the player's preference.
			wardrobe.appearance_save_path = ""
			station.viewer = head
			var player: CharacterBody3D = current_scene.get("_player")
			player.set_physics_process(false)
			player.global_position += station.to_global(Vector3(0, 1.65, 2.0)) - head.global_position
			head.global_basis = station.global_basis.orthonormalized()
			for f in range(12):
				current_scene.call("_cull_artifacts")
				await process_frame
			var ray := PhysicsRayQueryParameters3D.create(head.global_position, head.global_position - Vector3.UP * 3.0, 1)
			ray.exclude = [player.get_rid()]
			var ground: Dictionary = current_scene.get_world_3d().direct_space_state.intersect_ray(ray)
			check(not ground.is_empty() and absf(float(ground.position.y) - station.global_position.y) < 0.12, "standing area is level with mirror foot, revealing full outfit")
			station.cycle_outfit(1)
			for f in range(5):
				await process_frame
			check(wardrobe.costume.outfit_id != "", "museum control dresses its player")
			check(station.reflection.current, "reflection camera active in its own viewport after loading")
			check(station.viewport.world_3d == current_scene.get_world_3d(), "reflection shares the actual museum world")
			check(station.viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED, "mirror updates before player")
			print("MIRROR_STATE ", station.to_local(head.global_position), " visible=", station.is_visible_in_tree(), " process=", station.can_process())
			if "--capture" in OS.get_cmdline_user_args():
				await RenderingServer.frame_post_draw
				root.get_texture().get_image().save_png("res://ada_run/super_drag_shots/museum.png")
	var file := FileAccess.open("res://ada_run/probe_super_drag_museum.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"checks": checks, "failures": failures}, "\t"))
	file.close()
	print("SUPER_DRAG_MUSEUM ", checks, " checks; ", failures.size(), " failures")
	quit(0 if failures.is_empty() else 1)
