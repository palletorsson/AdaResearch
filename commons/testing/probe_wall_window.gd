extends SceneTree
## IS THE PICTURE ACTUALLY A WINDOW?
##
## cube_isometric photographed as a flat grey panel twice. The sweep runs
## --no-window (not --headless), so get_texture() should be live. This asks the
## viewport itself: does it exist, does its texture have a size, and does the
## rendered image contain more than one colour?

func _init() -> void:
	var S := load("res://commons/artifacts/wall_abstract/wall_abstract.tscn")
	var a = S.instantiate()
	a.work = "cube_isometric"
	get_root().add_child(a)
	for i in 12:
		await process_frame
	var fails := 0

	var vp: SubViewport = a._viewport
	print("1  viewport: %s" % [vp])
	if vp == null:
		print("   FAIL no viewport built"); fails += 1
		print("PROBE FAILED"); quit(1); return
	print("2  size=%s own_world=%s update=%d children=%d"
		% [vp.size, vp.own_world_3d, vp.render_target_update_mode, vp.get_child_count()])

	var tex := vp.get_texture()
	print("3  texture: %s  size=%s" % [tex, tex.get_size() if tex else "-"])
	if tex == null:
		print("   FAIL no texture"); fails += 1

	# does the panel's material actually carry it?
	var win: MeshInstance3D = null
	for c in a.get_node("Face").get_children():
		if c is MeshInstance3D:
			win = c
	print("4  panel albedo_texture: %s" % [win.material_override.albedo_texture if win else "-"])
	if win == null or win.material_override.albedo_texture == null:
		print("   FAIL the panel is not showing the viewport"); fails += 1

	# THE REAL QUESTION: is anything drawn in it?
	var img: Image = tex.get_image() if tex else null
	if img == null:
		print("5  get_image() returned null — the render target has no data")
		fails += 1
	else:
		var seen := {}
		var w: int = img.get_width()
		var h: int = img.get_height()
		for y in range(0, h, max(1, h / 24)):
			for x in range(0, w, max(1, w / 24)):
				seen[img.get_pixel(x, y).to_rgba32()] = true
		print("5  distinct colours sampled in the render: %d (1 = nothing drawn)" % seen.size())
		if seen.size() < 3:
			print("   FAIL the viewport rendered a flat field — no cube"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
