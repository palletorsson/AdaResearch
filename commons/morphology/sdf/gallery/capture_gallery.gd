# capture_gallery.gd
# Loads the SDF Gallery scene and captures it from several camera angles
# so you can see all five rows (primitives, kingdoms, transitions, modulor,
# operators) without having to walk there.

extends SceneTree

const GALLERY_SCENE := "res://commons/morphology/sdf/gallery/sdf_gallery.tscn"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	print("=== GALLERY CAPTURE ===")
	var out_dir := "user://gallery"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))

	var err := change_scene_to_file(GALLERY_SCENE)
	if err != OK: push_error("load failed"); quit(1); return
	await process_frame
	await process_frame
	await process_frame

	var gallery: Node3D = current_scene
	var cam: Camera3D = null
	for child in gallery.get_children():
		if child is Camera3D:
			cam = child
			break
	if cam == null:
		push_error("no camera")
		quit(1)
		return

	# Angles: each row gets its own close-up + one overview
	var views: Array = [
		{"name": "00_overview",    "pos": Vector3(0, 18, -12),  "look": Vector3(0, 0, 18)},
		{"name": "01_primitives",  "pos": Vector3(0, 2.5, -4),  "look": Vector3(0, 1, 0)},
		{"name": "02_kingdoms",    "pos": Vector3(0, 2.8, 2),   "look": Vector3(0, 1.2, 6)},
		{"name": "03_transition",  "pos": Vector3(0, 2.5, 8),   "look": Vector3(0, 1.0, 13)},
		{"name": "04_modulor",     "pos": Vector3(0, 2.5, 14),  "look": Vector3(0, 1.0, 18)},
		{"name": "05_operators",   "pos": Vector3(0, 2.5, 20),  "look": Vector3(0, 1.0, 24)},
		{"name": "06_dna_variance","pos": Vector3(0, 2.5, 26),  "look": Vector3(0, 1.0, 30)},
		{"name": "07_stacked_ops", "pos": Vector3(0, 2.5, 32),  "look": Vector3(0, 1.0, 36)},
	]

	for v in views:
		cam.position = v.pos
		cam.look_at(v.look, Vector3.UP)
		await process_frame
		await process_frame
		await process_frame
		await process_frame
		var img := root.get_viewport().get_texture().get_image()
		if img:
			var path: String = out_dir + "/%s.png" % v.name
			img.save_png(path)
			print("  Saved %s" % path)

	print("=== DONE — gallery captures in %s ===" % out_dir)
	quit(0)
