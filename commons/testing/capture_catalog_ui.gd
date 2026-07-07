extends SceneTree
## Headless screenshot of DressingRoomCatalog3D WITH its UI, to diagnose
## layout / fit. Renders the root viewport (CanvasLayer UI included).
##   godot --path . --script res://commons/testing/capture_catalog_ui.gd -- --room=<name>
func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var err := change_scene_to_file("res://commons/artifacts/catalog/DressingRoomCatalog3D.tscn")
	if err != OK:
		push_error("failed to load catalog scene"); quit(1); return
	await process_frame
	await process_frame
	await create_timer(3.5).timeout
	await process_frame
	await process_frame
	var img: Image = root.get_texture().get_image()
	if img == null:
		push_error("no viewport image"); quit(2); return
	var win: Vector2i = root.get_visible_rect().size
	print("catalog_ui: window size = %s" % str(win))
	var out := "user://catalog_ui.png"
	img.save_png(out)
	print("catalog_ui: saved %s" % ProjectSettings.globalize_path(out))
	quit(0)
