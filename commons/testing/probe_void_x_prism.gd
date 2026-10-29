extends Node3D
## THE VOID with left X (Palle, 2026-10-29: "remove the reset menu on x button and add the menu there instead").
## The real Void (commons/void/void.tscn) in forced-XR mode on synthetic trackers, as its own physics tests run
## it; the left palm stays DOWN so only the button can show the prism. (A) the Void arrives with the museum
## rig carrying InventoryPrism, hidden; (B) left X: the prism is up over the left hand and the game did NOT
## return to the menu; (S) the right pointer on the Tape card and the trigger through the tracker: the tape chosen
## and worn; (T) the ▶ ear the same way turns it; (C) left X again: down, still in the game. Pictures.
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
	var look := func():cam.global_transform = Transform3D(Basis(), left.global_position + Vector3(-0.55, 0.55, 0.45)).looking_at(left.global_position + Vector3(0, 0.03, -0.12));cam.current = true
	# B - left X
	left.button_pressed.emit("ax_button")
	for i in 30:
		await get_tree().process_frame
	look.call()
	for i in 10:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("void_x_up.png"))
	var ahead: float = (prism.prism.global_position - left.global_position).dot(-left.global_basis.z)
	var up: bool = prism.showing and prism.prism.visible and absf(ahead - .12) < .01
	_check(report, "B left X: the prism is up on the left controller, 12 cm ahead; the game stays (no return to the menu)", up and not bool(game.get("returning")) and game.is_inside_tree(), {"showing": prism.showing, "returning": game.get("returning"), "ahead": ahead})
	# S - SELECT with the real pointer: the right hand aims at the HAND face's Tape card, 35 cm off the face along
	# its normal, and the trigger is pressed through the tracker; the pointer presses the card, the roll is worn
	var ui: Node = prism.uis[0];var card: Control = ui.buttons["item:tape"]
	var c: Vector2 = card.get_global_rect().get_center();var vp_size: Vector2 = prism.faces[0].get("viewport_size");var scr: Vector2 = prism.faces[0].get("screen_size")
	var face: Node3D = prism.faces[0]
	var on_face: Vector3 = face.to_global(Vector3((c.x / vp_size.x - .5) * scr.x, (.5 - c.y / vp_size.y) * scr.y, 0))
	var normal: Vector3 = face.global_basis.z.normalized()
	var eye_pos: Vector3 = on_face + normal * .35
	# the pointer's ray starts y_offset (-1.3 cm) below the controller: aim that much above the card, or the
	# ray lands one card down (it did: the Ball)
	# the HAND face lies on TOP of the drum, so its normal is near vertical: an up hint that is not parallel to
	# the look direction, and the y_offset compensation along the controller's own +Y, not the world's
	var up_hint: Vector3 = Vector3.UP if absf(normal.dot(Vector3.UP)) < .9 else Vector3.FORWARD
	var y_off: float = absf(float(prism._right_pointer().get("y_offset")))
	var aim0 := Transform3D(Basis(), eye_pos).looking_at(on_face, up_hint)
	var lift: Vector3 = aim0.basis.y * y_off
	var aim := Transform3D(Basis(), eye_pos).looking_at(on_face + lift, up_hint)   # -Z toward the card
	# a pose is in the ORIGIN's space, and the Void has carried the origin to its arrival crate
	var to_origin: Transform3D = (origin as Node3D).global_transform.affine_inverse()
	_right.set_pose(&"aim", to_origin * aim, Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	for i in 12:
		await get_tree().process_frame
	var pointer: Node = prism._right_pointer();var target_before: Node = pointer.get("target")
	var ray: RayCast3D = pointer.get_node("RayCast");var sup: Area3D = pointer.get_node("SuppressArea")
	var diag := {"enabled": pointer.get("enabled"), "last_target": str(pointer.get("last_target").name) if pointer.get("last_target") else "", "ray_colliding": ray.is_colliding(), "collider": str(ray.get_collider().name) if ray.get_collider() else "", "ray_mask": ray.collision_mask, "ray_enabled": ray.enabled, "ray_origin": ray.global_position, "ray_dir": -ray.global_basis.z, "face_pos": on_face, "card_pos": on_face, "suppress_bodies": sup.has_overlapping_bodies(), "suppress_areas": sup.has_overlapping_areas(), "face_body_layer": face.get("collision_layer"), "face_enabled": face.get("enabled"), "ptr_pos": pointer.global_position, "ctrl_pos": _rt(origin).global_position, "ptr_active": str(pointer.get("_active_controller").name) if pointer.get("_active_controller") else ""}
	print("[probe_void_x_prism] diag ", JSON.stringify(diag))
	_right.set_input(&"trigger_click", true)
	for i in 6:
		await get_tree().process_frame
	_right.set_input(&"trigger_click", false)
	for i in 12:
		await get_tree().process_frame
	var roll: Node = prism.hand.worn_node()
	look.call()
	for i in 6:
		await get_tree().process_frame
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(out_dir.path_join("void_x_select.png"))
	_check(report, "S select: the right pointer on the Tape card, trigger through the tracker: tape chosen, the roll worn on the right hand, no tape laid", prism.hand.current == "tape" and roll != null and roll.get_parent().name == "RightHand" and roll.segments.is_empty() and roll.start_anchor.is_empty(), {"current": prism.hand.current, "pointer_target_before_press": str(target_before.name) if target_before else "", "worn": roll != null})
	# T - the ▶ ear, the same way
	var ear: Control = ui.buttons["ear+1"];var ec: Vector2 = ear.get_global_rect().get_center()
	var on_ear: Vector3 = face.to_global(Vector3((ec.x / vp_size.x - .5) * scr.x, (.5 - ec.y / vp_size.y) * scr.y, 0))
	var ear0 := Transform3D(Basis(), on_ear + normal * .35).looking_at(on_ear, up_hint)
	_right.set_pose(&"aim", to_origin * Transform3D(Basis(), on_ear + normal * .35).looking_at(on_ear + ear0.basis.y * y_off, up_hint), Vector3.ZERO, Vector3.ZERO, XRPose.XR_TRACKING_CONFIDENCE_HIGH)
	for i in 12:
		await get_tree().process_frame
	_right.set_input(&"trigger_click", true)
	for i in 6:
		await get_tree().process_frame
	_right.set_input(&"trigger_click", false)
	for i in 30:
		await get_tree().process_frame
	_check(report, "T turn: the ▶ ear pressed by the pointer turns the prism to KNOBS", prism.active == 1, {"active": prism.active})
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

func _rt(origin: Node) -> Node3D:return origin.get_node("RightHand")

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
