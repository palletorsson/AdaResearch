extends SceneTree
## Live Godot verification probe for Model B's Dual Breadcrumbs (Poetic Song + Plain Breadcrumb).

const HUD_SCRIPT := preload("res://commons/void/camcorder_hud.gd")
const OPERA_SCRIPT := preload("res://commons/void/inner_opera.gd")

func _init() -> void:
	call_deferred("_run")

func _run() -> void:
	var out_dir := "C:/Users/palle/.gemini/antigravity/brain/ef284424-7080-4c67-9c80-149143f5ba12/screenshots"
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)

	var opera = OPERA_SCRIPT.new()
	var ids := [
		"keeps_door",
		"keeps_trace",
		"keeps_weight",
		"keeps_bank",
		"keeps_order",
		"keeps_threshold",
		"keeps_supports",
		"crate",
	]
	var checks: Array = []
	var failed := 0
	for id in ids:
		var plain: String = opera._plain_for(id, id)
		var ok := not plain.is_empty()
		if not ok: failed += 1
		checks.append({"id": id, "ok": ok, "plain": plain})
		print("[dual_hud] %s -> %s" % [id, plain])

	# Mount live CamcorderHUD and render both default + placed HUD modes
	var cam := Camera3D.new()
	var env := WorldEnvironment.new()
	var e := Environment.new()
	e.background_mode = Environment.BG_COLOR
	e.background_color = Color(0.14, 0.16, 0.19)
	env.environment = e
	root.add_child(env)
	root.add_child(cam)
	cam.current = true

	var hud = HUD_SCRIPT.new()
	hud.mount(cam, false)
	hud.set_level("F03  Point_Lines  ·  The door remembers")
	var door_plain: String = opera._plain_for("keeps_door", "keeps_door")
	hud.set_sung("The number goes. The door stays open.", door_plain)

	for _i in 6:
		await process_frame

	var shot_default := out_dir.path_join("dual_breadcrumb_hud_default.png")
	var err1 := root.get_texture().get_image().save_png(shot_default)
	var ok_default: bool = (err1 == OK and str(hud.sung) == "The number goes. The door stays open." and str(hud.sung_plain) == door_plain)
	if not ok_default: failed += 1
	checks.append({"id": "hud_default_render", "ok": ok_default, "shot": shot_default})

	# Also test clearing song clears sung_plain cleanly
	hud.set_sung("")
	await process_frame
	var ok_clear: bool = str(hud.sung).is_empty() and str(hud.sung_plain).is_empty()
	if not ok_clear: failed += 1
	checks.append({"id": "hud_clear_plain", "ok": ok_clear})

	var report := {"passed": failed == 0, "failed": failed, "checks": checks}
	var f := FileAccess.open(out_dir.path_join("dual_hud_checks.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	print("[dual_hud] DONE passed=%s failed=%d" % [str(failed == 0), failed])
	opera.free()
	quit(0 if failed == 0 else 1)
