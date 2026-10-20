extends SceneTree
## Playable roof view, starting beside the origin rather than inside the crate.
func _initialize() -> void:
	show_grid.call_deferred()

func show_grid() -> void:
	var game: Node3D = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for i in range(30): await physics_frame
	game.scene_loaded()
	game.scene_visible()
	game.place_player(Vector3(1.9,0.06,2.65))
	game.camera.look_at(Vector3(0,0,0))
	game.notice_time = 0.0
	game.status.hide()
	game.desktop_help.hide()
	var grid: MeshInstance3D = game.building.floors[0].get_node("OriginFloorGrid")
	var sphere: Node3D = game.building.content.roots[0].get_node("WorldZero/OriginSphere")
	var checks := {
		"grid_centred_at_world_zero": grid.global_position.is_equal_approx(Vector3(0,0.008,0)),
		"sphere_centred_at_world_zero": sphere.global_position.is_equal_approx(Vector3.ZERO),
		"grid_faces_up": grid.global_basis.z.dot(Vector3.UP)>0.999,
		"grid_texture_loaded": grid.material_override.albedo_texture!=null
	}
	print("ORIGIN_GRID_CHECKS ",JSON.stringify(checks))
	var out := "res://doc/book/iterations/2026-10-20-roof-arrival-crate"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out=arg.trim_prefix("--out=")
	FileAccess.open(out.path_join("origin-grid-checks.json"),FileAccess.WRITE).store_string(JSON.stringify(checks,"\t"))
	for i in range(12): await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("point-zero-grid.png"))
	# Keep the real walker and interaction running for the author to explore.
