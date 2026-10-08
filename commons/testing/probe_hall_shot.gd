extends SceneTree

## TOOL — one evidence photograph of one museum hall, with every artifact's own Camera3D
## taken out first. Some artifact scenes ship a demo camera marked current (the decay
## stacks in Random_Rotate_Random_XYZ do), and a museum proof shot then photographs
## from THAT camera. This boots the real museum at the hall, frees those cameras, and
## shoots from a camera it owns.
##
##   godot --path . --xr-mode off --script res://commons/testing/probe_hall_shot.gd --
##       --chapter=randomness --map=Random_Rotate_Random_XYZ --out=user://shot.png
##       --x=6 --y=20 --z=10 --yaw=0 --pitch=-89 [--wait=3.0] [--fov=70]
##
## Coordinates are the hall segment's own (x across, z along the walk, y up).
## yaw 180 looks along +z, into the hall.

var _args := {}


func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1]
	_run.call_deferred()


func _f(k: String, d: float) -> float:
	return float(_args.get(k, str(d)))


func _run() -> void:
	var out_dir := "user://hall_shot/"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(out_dir))
	var ctl := out_dir + "control.json"
	var f := FileAccess.open(ctl, FileAccess.WRITE)
	f.store_string(JSON.stringify({"first_chapter": str(_args.get("chapter", "randomness")), "dollhouse": 0, "grid_pack": 1}))
	f.close()
	var em: Node3D = load("res://commons/scenes/endless_museum.tscn").instantiate()
	em.set("EM_CONTROL", ctl)
	em.set("_overrides_path", ctl + ".unused")
	em.set("start_chapter", str(_args.get("chapter", "randomness")))
	em.set("start_map", str(_args.get("map", "")))
	root.add_child(em)
	current_scene = em
	await create_timer(_f("wait", 3.0)).timeout
	var seg: Node3D = null
	for rec: Dictionary in em.get("_segments"):
		if rec.node.get_meta("em_map", "") == str(_args.get("map", "")):
			seg = rec.node
	if seg == null:
		print("[hall-shot] no segment for ", _args.get("map", ""))
		quit(1)
		return
	var freed := 0
	for c in seg.find_children("*", "Camera3D", true, false):
		(c as Camera3D).current = false
		c.queue_free()
		freed += 1
	var cam := Camera3D.new()
	cam.fov = _f("fov", 70.0)
	seg.add_child(cam)
	cam.position = Vector3(_f("x", 6.0), _f("y", 1.62), _f("z", 2.0))
	cam.rotation_degrees = Vector3(_f("pitch", 0.0), _f("yaw", 180.0), 0.0)
	cam.make_current()
	# keep it current against any guard for the frames before the grab
	for i in 20:
		cam.make_current()
		await process_frame
	await RenderingServer.frame_post_draw
	var img: Image = root.get_viewport().get_texture().get_image()
	var path := str(_args.get("out", "user://hall_shot/shot.png"))
	img.save_png(path)
	print("[hall-shot] %s: freed %d artifact camera(s); saved %s (%dx%d)" % [_args.get("map", ""), freed, path, img.get_width(), img.get_height()])
	quit(0)
