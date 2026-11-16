extends SceneTree
## The sung line on the headset's viewfinder, without a headset: the roof is built with the XR rig (so the
## viewfinder mounts as the plane in front of the camera, not as the desktop overlay), the visitor wakes in
## the crate facing its panel, and after the dwell the thought for the crate comes. Checked: the plane is
## there at the size the headset gets; while the voice sounds the line is on the plane's own picture, where a
## headset shows it; when the voice ends the line is gone from it. Nothing is played aloud (--opera-quiet).
##
##   godot --path . --xr-mode off --script res://tools/probes/opera_hud_xr.gd -- --void-start-floor=0 --opera-quiet --out=<dir>
##
## <dir>/hud_xr.json, hud_while_sung.png and hud_after.png (the plane's picture), window_while_sung.png.

var game: Node
var folder := "res://ada_run/opera_hud_xr"
var result := {}


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("hud_xr.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


# How much of the middle band of the plane's picture, where the sung line is drawn, is inked.
func _ink(image: Image) -> int:
	var count := 0
	var w := image.get_width()
	var h := image.get_height()
	for y in range(int(h * 0.68), int(h * 0.76)):
		for x in range(int(w * 0.30), int(w * 0.70)):
			if image.get_pixel(x, y).a > 0.3: count += 1
	return count


func _picture(display: Object) -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return (display.get("_target") as SubViewport).get_texture().get_image()


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = true
	root.add_child(game); current_scene = game
	game.scene_loaded(); game.scene_visible()
	var checks := []
	result = {"floor": int(game.checkpoint), "checks": checks, "passed": false}
	var opera: Node = null
	var waited := 0.0
	while waited < 40.0:
		await process_frame
		waited += root.get_process_delta_time()
		opera = game.get_node_or_null("InnerOpera") if opera == null else opera
		if opera == null:
			for child in game.get_children():
				if child.get_script() != null and str(child.get_script().resource_path).ends_with("inner_opera.gd"): opera = child
		if opera != null and bool(opera.call("state").listening): break
	var display: Variant = game.get("charge_display")
	var frame: Variant = display.get("_xr_frame") if display is Object else null
	var plane_ok := frame is MeshInstance3D and (frame as MeshInstance3D).mesh is QuadMesh and display.get("_target") is SubViewport
	var plane := {}
	if plane_ok:
		var quad := (frame as MeshInstance3D).mesh as QuadMesh
		var depth := -(frame as MeshInstance3D).position.z
		plane = {"metres": [quad.size.x, quad.size.y], "metres_ahead": depth, "pixels": [(display.get("_target") as SubViewport).size.x, (display.get("_target") as SubViewport).size.y],
			"degrees_out_to_the_side": snappedf(rad_to_deg(atan(quad.size.x * 0.5 / depth)), 0.1), "on_the_camera": (frame as MeshInstance3D).get_parent() == root.get_camera_3d()}
	checks.append({"check": "built with the XR rig, the viewfinder is the plane in front of the camera (not the desktop overlay), and the inner opera listens", "ok": plane_ok and opera != null
		and bool(opera.call("state").listening) and bool(plane.get("on_the_camera", false)), "plane": plane, "waited_s": snappedf(waited, 0.1)})
	_save()
	if not plane_ok or opera == null:
		quit(1)
		return
	# the visitor wakes facing the panel: the thought for the crate comes after the dwell
	waited = 0.0
	while waited < 12.0 and Array(opera.call("state").heard).is_empty():
		await process_frame
		waited += root.get_process_delta_time()
	var heard: Array = opera.call("state").heard
	var line := str(display.get("sung"))
	var while_sung: Image = await _picture(display)
	while_sung.save_png(folder.path_join("hud_while_sung.png"))
	root.get_texture().get_image().save_png(folder.path_join("window_while_sung.png"))
	var ink_sung := _ink(while_sung)
	checks.append({"check": "the thought for the crate comes, and while it sounds its words are on the plane's picture, in the band below the middle", "ok": heard.size() >= 1
		and bool(heard[0].get("on_display", false)) and line == str(heard[0].text) and line != "" and ink_sung > 2000, "heard": heard, "line_on_the_plane": line, "inked_pixels_in_the_band": ink_sung,
		"came_after_s": snappedf(waited, 0.1)})
	_save()
	waited = 0.0
	while waited < 12.0 and str(display.get("sung")) != "":
		await process_frame
		waited += root.get_process_delta_time()
	var after: Image = await _picture(display)
	after.save_png(folder.path_join("hud_after.png"))
	var ink_after := _ink(after)
	checks.append({"check": "THE NEGATIVE: when the voice has ended the line is off the plane's picture: the band is empty again", "ok": str(display.get("sung")) == "" and ink_after == 0,
		"inked_pixels_in_the_band": ink_after, "cleared_after_s": snappedf(waited, 0.1)})
	result["passed"] = checks.all(func(c): return c.ok)
	_save()
	print("[opera_hud_xr] ", "PASSED" if result.passed else "FAILED")
	quit(0 if result.passed else 1)
