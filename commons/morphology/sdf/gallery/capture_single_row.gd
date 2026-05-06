# capture_single_row.gd
# Verifies that single-row rendering works — loads the gallery with
# visible_rows=["primitives"] and screenshots it. If only primitives
# appear, the row filter is functioning correctly.

extends SceneTree

const SDFGalleryBody = preload("res://commons/morphology/sdf/gallery/sdf_gallery.gd")

const DEMO_SCENE := "res://commons/morphology/sdf/sdf_blend_demo.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== SINGLE-ROW CAPTURE ===")
	var out_dir := "user://single_rows"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(DEMO_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame

	var demo: Node = current_scene
	if "_preview" in demo and demo._preview != null:
		demo._preview.queue_free()
		demo._preview = null

	var rows: Array = ["primitives", "kingdoms", "transition", "modulor", "operators", "dna_variance", "stacked_ops"]

	for row in rows:
		# Clean previous gallery
		for child in demo.get_children():
			if child.name == "IsolatedGallery":
				child.queue_free()
		await process_frame

		var gallery := Node3D.new()
		gallery.name = "IsolatedGallery"
		gallery.set_script(SDFGalleryBody)
		gallery.set("include_chrome", true)
		gallery.set("visible_rows", PackedStringArray([row]))
		demo.add_child(gallery)

		# Point camera at the row (rows are at ROW_SPACING * index, z axis)
		var idx: int = rows.find(row)
		var cam: Camera3D = null
		for child in demo.get_children():
			if child is Camera3D:
				cam = child
				break
		if cam:
			cam.position = Vector3(0, 4.0, float(idx) * 6.0 - 6.0)
			cam.look_at(Vector3(0, 1.0, float(idx) * 6.0), Vector3.UP)

		await process_frame
		await process_frame
		await process_frame
		await process_frame

		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/row_%s.png" % row
			img.save_png(path)
			print("  Saved %s" % path)

	print("=== DONE — %d single-row captures in %s ===" % [rows.size(), out_dir])
	quit(0)
