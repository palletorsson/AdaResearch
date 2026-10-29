extends Node3D
## THE VOID with left X (Palle, 2026-10-29: "remove the reset menu on x button and add the menu there instead").
## The real Void (commons/void/void.tscn) in forced-XR mode on synthetic trackers, as its own physics tests run
## it; the left palm stays DOWN so only the button can show the prism. (A) the Void arrives with the museum
## rig carrying InventoryPrism, hidden; (B) left X: the prism is up over the left hand and the game did NOT
## return to the menu; (C) left X again: down, still in the game. Pictures of both.
## Writes <out>/{void_x_up.png, void_x_down.png, void_x.json}. Run it from the isolated mirror so the Void's
## checkpoint lands in the test app's user://, never in the real save:
##   godot --path ada_run/menu-integration-test/run-<id> --xr-mode off --resolution 1280x800
##         res://commons/testing/probe_void_x_prism.tscn -- --out=<abs dir>

var _left: XRControllerTracker
var _right: XRControllerTracker
var out_dir := ""

func _ready() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out_dir = arg.trim_prefix("--out=")
	if out_dir == "":out_dir = ProjectSettings.globalize_path("user://void_x")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var report := {"checks": [], "user_dir": OS.get_user_data_dir()}
	_check(report, "0 isolation: the Void's saves go to the test app's user://, not the real game's", OS.get_user_data_dir().contains("Ada Menu Integration Test"), {"user_dir": OS.get_user_data_dir()})
	if not report.checks[0].ok:
		_finish(report);return
	_left = XRControllerTracker.new();_left.name = &"left_hand";_left.type = XRServer.TRACKER_CONTROLLER;_left.hand = XRPositionalTracker.TRACKER_HAND_LEFT
	_right = XRControllerTracker.new();_right.name = &"right_hand";_right.type = XRServer.TRACKER_CONTROLLER;_right.hand = XRPositionalTracker.TRACKER_HAND_RIGHT
	_pose(_left, Vector3(-0.25, 1.0, -0.25));_pose(_right, Vector3(0.25, 1.0, -0.25))
	XRServer.add_tracker(_left);XRServer.add_tracker(_right)
	var game: Node = load("res://commons/void/void.tscn").instantiate()
	game.set("force_xr", true)
	add_child(game)
	# arrival: the tower streams in; give it a while
	for i in 240:
		await get_tree().process_frame
	var origin: Node = game.find_child("XROrigin3D", true, false)
	var prism: Node = origin.get_node_or_null("InventoryPrism") if origin else null
	var left: Node3D = origin.get_node_or_null("LeftHand") if origin else null
	_check(report, "A arrival: the Void runs in VR mode with the museum rig; InventoryPrism on it, enabled, hidden", bool(game.get("vr")) and prism != null and prism.enabled and not prism.showing and not bool(game.get("returning")), {"vr": game.get("vr"), "prism": prism != null, "showing": prism.showing if prism else null})
	if prism == null or left == null:
		_finish(report);return
	# the eye, off to the left front of the hands
	var cam := Camera3D.new();add_child(cam);cam.fov = 60
	var look := func():cam.global_transform = Transform3D(Basis(), left.global_position + Vector3(-0.9, 0.45, 0.75)).looking_at(left.global_position + Vector3(0.1, 0.1, -0.1));cam.current = true
	# B - left X
	left.button_pressed.emit("ax_button")
	for i in 30:
		await get_tree().process_frame
	look.call()
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("void_x_up.png"))
	var up: bool = prism.showing and prism.prism.visible and (prism.prism.global_position - left.global_position).y > .1
	_check(report, "B left X: the prism is up over the left hand; the game stays (no return to the menu)", up and not bool(game.get("returning")) and game.is_inside_tree(), {"showing": prism.showing, "returning": game.get("returning"), "lift": (prism.prism.global_position - left.global_position).y})
	# C - left X again
	left.button_pressed.emit("ax_button")
	for i in 20:
		await get_tree().process_frame
	look.call()
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("void_x_down.png"))
	_check(report, "C left X again: the prism is down; still in the game", not prism.showing and not prism.prism.visible and not bool(game.get("returning")) and game.is_inside_tree(), {"showing": prism.showing, "returning": game.get("returning")})
	_finish(report)

func _pose(t: XRControllerTracker, p: Vector3) -> void:
	t.set_pose(&"aim", Transform3D(Basis(), p), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)

func _check(report: Dictionary, what: String, ok: bool, data: Dictionary) -> void:
	report.checks.append({"what": what, "ok": ok, "data": data})
	print("[probe_void_x_prism] %s  %s" % ["ok  " if ok else "FAIL", what])

func _finish(report: Dictionary) -> void:
	var passed := 0
	for ch in report.checks:
		if ch.ok:passed += 1
	report["passed"] = passed;report["of"] = report.checks.size()
	var o := FileAccess.open(out_dir.path_join("void_x.json"), FileAccess.WRITE);o.store_string(JSON.stringify(report, "  "));o.close()
	print("[probe_void_x_prism] %d/%d" % [passed, report.checks.size()])
	get_tree().quit(0 if passed == report.checks.size() else 1)
