extends SceneTree
## Capture the authored Godot scene and its own lighting from three viewpoints.

func _initialize() -> void:
	call_deferred("capture")

func capture() -> void:
	var output := OS.get_cmdline_user_args()[0]
	var viewport := SubViewport.new()
	viewport.size = Vector2i(2000, 1400)
	viewport.own_world_3d = true
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.msaa_3d = Viewport.MSAA_4X
	root.add_child(viewport)
	var scene: Node3D = load("res://commons/artifacts/kapoor_void_studies/boolean_eggs_preview.tscn").instantiate()
	viewport.add_child(scene)
	for i in range(30):
		await process_frame
	var camera := scene.get_node("BooleanEggsPreviewCamera") as Camera3D
	var views := [
		["eggs-front", Vector3(0.0, 3.25, 11.8), Vector3(0.0, 1.35, 0.0)],
		["eggs-oblique", Vector3(6.3, 3.8, 11.5), Vector3(0.0, 1.15, 0.0)],
		["eggs-cavity", Vector3(3.7, 1.9, 3.5), Vector3(2.28, 1.1, 0.0)],
	]
	for view in views:
		# Keep the detail photograph free of cropped billboard captions.
		for label in scene.find_children("*", "Label3D", true, false):
			label.visible = view[0] != "eggs-cavity"
		camera.position = view[1]
		camera.look_at(view[2], Vector3.UP)
		for i in range(8):
			await process_frame
		await RenderingServer.frame_post_draw
		var path: String = output.path_join(view[0] + ".png")
		var error := viewport.get_texture().get_image().save_png(path)
		if error != OK:
			push_error("Failed to save " + path)
			quit(1)
			return
		print("Saved " + path)
	quit(0)
