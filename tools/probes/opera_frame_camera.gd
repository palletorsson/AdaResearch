extends "res://tools/probes/void_game_probe.gd"
## Measure the actual streamed frames. Expose the same floor and view in desktop Godot.
func xyz(v: Vector3) -> Array:
	return [v.x, v.y, v.z]

func run() -> void:
	var index := 0
	var capture := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--void-start-floor="): index = int(arg.get_slice("=",1))
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--frame-song="): capture = arg.trim_prefix("--frame-song=")
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.scene_loaded()
	game.scene_visible()
	await frames(100)
	game.body.set_physics_process(false)
	var host: Node3D = game.building.content.roots[index]
	var measured := {}
	for node in get_nodes_in_group("opera_view_frames"):
		if not host.is_ancestor_of(node): continue
		var frame: Node3D = node
		var field := frame.get_parent()
		var id := str(field.get_meta("song_id", "")) if field.has_meta("song_id") else ""
		if frame.has_meta("encounter_id"): id = str(frame.get_meta("encounter_id"))
		if id.is_empty() and frame.name == &"OperaFrame06": id = preload("res://commons/void/opening_opera_trail.gd").WHEEL
		if id.is_empty(): continue
		var pose := host.global_transform.affine_inverse() * frame.global_transform
		var planar: Vector2 = frame.get("aperture") * 2
		var width := planar.x * pose.basis.x.length()
		var height := planar.y * pose.basis.y.length()
		measured[id] = {"position":xyz(pose.origin), "rotation":xyz(pose.basis.orthonormalized().get_euler()*180/PI),
			"width":width, "height":height, "title":frame.get("caption"), "visible":frame.is_visible_in_tree()}
		if id == capture:
			var lens := SubViewport.new()
			var aspect := width/height
			lens.size = Vector2i(roundi(960*minf(1,aspect)), roundi(960*minf(1,1/aspect))).max(Vector2i.ONE)
			lens.world_3d = game.camera.get_world_3d()
			root.add_child(lens)
			var eye := Camera3D.new()
			lens.add_child(eye)
			var axes := frame.global_basis.orthonormalized()
			eye.global_transform = Transform3D(axes,frame.global_position+axes.z*1.1)
			eye.keep_aspect = Camera3D.KEEP_HEIGHT
			eye.fov = rad_to_deg(2*atan(height/2.0/1.1))
			eye.near = .035
			eye.cull_mask = game.camera.cull_mask & ~preload("res://commons/void/camcorder_hud.gd").VIEWFINDER_LAYER
			eye.environment = game.camera.environment
			eye.current = true
			var target: Node3D
			var aim: Vector3
			if frame.name == &"OperaFrame06":
				target = field.get_node("RailMark")
				aim = target.global_position
			elif frame.has_meta("encounter_id"):
				aim = frame.to_global(Vector3.FORWARD * 0.1)
			else:
				var path: NodePath = field.get("target_path")
				target = host.get_node_or_null(path) if not path.is_empty() else null
				aim = target.to_global(field.get("target_offset")) if target != null else frame.to_global(Vector3.FORWARD*.1)
			measured[id]["aligned"] = frame.is_visible_in_tree() and frame.call("sees",eye,aim,target)
			lens.render_target_update_mode = SubViewport.UPDATE_ALWAYS
			await RenderingServer.frame_post_draw
			await RenderingServer.frame_post_draw
			var image := lens.get_texture().get_image()
			if image == null or image.save_png(out.path_join("view.png")) != OK:
				quit(2)
				return
			lens.queue_free()
	FileAccess.open(out.path_join("measured.json"),FileAccess.WRITE).store_string(JSON.stringify(measured))
	quit(0 if capture.is_empty() or measured.has(capture) else 2)
