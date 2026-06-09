# Render the TabbedEditorPanel (a 2D Control) per tab and screenshot each.
extends SceneTree

func _initialize() -> void:
	_run()

func _run() -> void:
	var root := get_root()
	DisplayServer.window_set_size(Vector2i(580, 540))
	root.transparent_bg = false
	var panel = load("res://commons/hazards/becoming_catalyst/tabbed_editor_panel.gd").new()
	root.add_child(panel)
	panel.position = Vector2(20, 20)
	await process_frame
	await process_frame
	for tab in ["GRID", "ARTIFACTS", "UTILITY", "BIOME"]:
		panel.set_active_tab(tab)
		await process_frame
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		var img: Image = root.get_texture().get_image()
		img.save_png("user://panel_%s.png" % str(tab).to_lower())
		print("[panel] saved ", tab)
	print("[panel] DONE")
	quit()
