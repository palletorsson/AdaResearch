extends SceneTree
func _initialize() -> void: call_deferred("run")
func run() -> void:
	root.size=Vector2i(1400,900)
	var preview=load("res://doc/book/studies/randomness-shelf/preview.tscn").instantiate()
	root.add_child(preview)
	preview.get_node("Shelf").next_sample()
	preview.get_node("Shelf").next_sample()
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	var image=root.get_texture().get_image()
	image.save_png("res://doc/book/iterations/2026-10-15-randomness-tutorial-shelf/shelf-preview.png")
	print("SHELF PREVIEW RENDERED")
	quit()
