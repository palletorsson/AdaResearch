extends "res://commons/testing/probe_color_recovery.gd"
## Real museum placement, entrance clearance, controls and shared mirror.
func run() -> void:
	await museum("Pattern_Foundry")
	var walk: Node3D
	var mirror: Node3D
	for node in current_scene.find_children("*", "Node3D", true, false):
		if node.has_method("sample_clock") and node.has_method("next_looks"):
			walk = node
		if node.has_method("update_reflection") and node.has_method("cycle_outfit"):
			mirror = node
	check(walk != null and mirror != null, "runway and dressing mirror instantiate in museum")
	if walk != null and mirror != null:
		var head: Camera3D = current_scene.get("_cam")
		var player: CharacterBody3D = current_scene.get("_player")
		var wardrobe: Node = current_scene.get("_wardrobe")
		var feel: Node = current_scene.get("_feel")
		if feel != null:
			feel.set_process(false)
		wardrobe.appearance_save_path = ""
		player.set_physics_process(false)
		player.global_position += walk.to_global(Vector3(2.65, 1.65, 12.7)) - head.global_position
		head.look_at(walk.to_global(Vector3(0, 1.1, 5.6)))
		for frame in range(15):
			current_scene.call("_cull_artifacts")
			await process_frame
		check(walk.agents.size() == 4, "four live performers in museum")
		check(walk.is_visible_in_tree() and walk.can_process(), "nearby runway wakes through museum culling")
		check(walk.to_local(mirror.global_position).is_equal_approx(Vector3(0, 0, 14)), "mirror stands at dressing end on same floor")
		var space: PhysicsDirectSpaceState3D = current_scene.get_world_3d().direct_space_state
		var floor_ok := true
		for local in [Vector3(-6, 2, 9), Vector3(-4, 2, 9), Vector3(-2.5, 2, 9), Vector3(0, 2, 5), Vector3(0, 2, 12.5)]:
			var from: Vector3 = walk.to_global(local)
			var ray := PhysicsRayQueryParameters3D.create(from, from - Vector3.UP * 3, 1)
			ray.exclude = [player.get_rid()]
			var hit := space.intersect_ray(ray)
			floor_ok = floor_ok and not hit.is_empty() and absf(hit.position.y - walk.global_position.y) < 0.05
		check(floor_ok, "doorway, runway and dressing approach have continuous level floor")
		var capsule := CapsuleShape3D.new()
		capsule.radius = 0.25
		capsule.height = 1.7
		var query := PhysicsShapeQueryParameters3D.new()
		query.shape = capsule
		query.collision_mask = 1
		query.exclude = [player.get_rid()]
		query.transform.origin = walk.to_global(Vector3(-7, 0.9, 9))
		query.motion = walk.global_basis * Vector3(5, 0, 0)
		check(space.cast_motion(query)[0] > 0.99, "visitor capsule passes through annex entrance")
		query.transform.origin = walk.to_global(Vector3(0, 0.9, 0.5))
		query.motion = walk.global_basis * Vector3(0, 0, 12)
		var travel := space.cast_motion(query)
		if travel[0] <= 0.99:
			query.transform.origin += query.motion * travel[1]
			query.motion = Vector3.ZERO
			print("RUNWAY_BLOCK ", travel, " ", space.intersect_shape(query))
			for hit in space.intersect_shape(query):
				print("BLOCK_PATH ", hit.collider.get_path(), " point=", walk.to_local(query.transform.origin))
			print("WALK_ORIGIN ", walk.global_position, " ", walk.global_basis)
		check(travel[0] > 0.99, "runway admits a visitor along its full length")
		var before: Array = walk.clocks.duplicate()
		for frame in range(15):
			await physics_frame
		check(walk.clocks != before, "performers advance under actual museum physics")
		var button: Node3D = walk.buttons[0].get_node("InteractableAreaButton")
		XRToolsPointerEvent.pressed(head, button, button.global_position)
		XRToolsPointerEvent.released(head, button, button.global_position)
		check(not walk.running, "museum pointer holds runway")
		walk.toggle_show()
		mirror.viewer = head
		wardrobe.choose_outfit("holo_fan", false)
		check(walk.agents.all(func(agent): return agent.outfit.headpiece.get_child(0).layers == 1), "performer heads stay visible when player dresses")
		check(get_nodes_in_group("costume_wardrobes").size() == 1, "only actual player owns a wardrobe")
		if "--shots" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute("res://ada_run/drag_catwalk_shots")
			for frame in range(8):
				await process_frame
			head.look_at(walk.to_global(Vector3(0, 1.1, 5.6)))
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/drag_catwalk_shots/museum.png")
		player.global_position += mirror.to_global(Vector3(0, 1.65, 2)) - head.global_position
		head.global_basis = mirror.global_basis.orthonormalized()
		for frame in range(12):
			current_scene.call("_cull_artifacts")
			await process_frame
		mirror.update_reflection()
		check(mirror.reflection.current and mirror.viewport.render_target_update_mode != SubViewport.UPDATE_DISABLED, "relocated mirror renders actual wearer and runway")
		if "--shots" in OS.get_cmdline_user_args():
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png("res://ada_run/drag_catwalk_shots/dressing_end.png")
	var report := {"checks": checks, "failures": failures, "headset_tested": false}
	var file := FileAccess.open("res://ada_run/probe_drag_catwalk_museum.json", FileAccess.WRITE)
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("CATWALK_MUSEUM ", JSON.stringify(report))
	quit(0 if failures.is_empty() else 1)
