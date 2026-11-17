extends "res://tools/probes/void_game_probe.gd"

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	var capture := DisplayServer.get_name() != "headless"
	var game_script: GDScript = load("res://commons/void/game.gd")
	var hand_script: GDScript = load("res://commons/player/inventory_hand.gd")
	hand_script.keep_default = out.path_join("probe-placements.json")
	for use_xr in [false, true]:
		game_script.requested_floor = 3
		await start(use_xr)
		var mode := "XR" if use_xr else "Desktop"
		var hud: Control = game.charge_display
		check(mode + " uses the authored title at startup", hud.level == "FLOOR 03 / POINT LINES")
		check(mode + " reads the full body battery", hud.percent == 100 and is_equal_approx(hud.battery_fill, 1.0))
		check(mode + " viewfinder ignores mouse input", hud.mouse_filter == Control.MOUSE_FILTER_IGNORE)
		if use_xr:
			var plane := game.camera.get_node("Viewfinder") as MeshInstance3D
			var texture := game.camera.get_node("ViewfinderTexture") as SubViewport
			check("XR viewfinder follows the stereo camera and uses the shared drawing",
				plane.position.is_equal_approx(Vector3(0, -.095, -1.2)) and hud.get_parent() == texture
				and (plane.material_override as StandardMaterial3D).albedo_texture == texture.get_texture())
			check("XR markings span a wider field without moving the stereo plane closer",
				is_equal_approx(plane.mesh.size.x, 1.66) and is_equal_approx(plane.mesh.size.y, .9545)
				and texture.size == Vector2i(1280, 736))
			var original_scale := XRServer.world_scale
			XRServer.world_scale = original_scale * .25
			await frames(2)
			check("XR viewfinder keeps its angular size at quarter scale",
				is_equal_approx(plane.position.z, -.3 * original_scale)
				and is_equal_approx(plane.position.y, -.02375 * original_scale)
				and plane.scale.is_equal_approx(Vector3.ONE * original_scale * .25))
			XRServer.world_scale = original_scale
			await frames(2)
			hud.hide()
			check("hiding the HUD hides the XR plane too", not plane.visible)
			hud.show()
		else:
			check("desktop viewfinder fills the display", hud.size.is_equal_approx(root.get_visible_rect().size))
			check("controls are tucked away initially", not game.desktop_controls.visible)
			var f1 := InputEventKey.new()
			f1.keycode = KEY_F1
			f1.pressed = true
			game._unhandled_key_input(f1)
			check("F1 opens the existing desktop controls", game.desktop_controls.visible)
			game._unhandled_key_input(f1)
			check("F1 closes the desktop controls", not game.desktop_controls.visible)

		game.charge.travel(18.0)
		check(mode + " follows movement drain from the existing battery", hud.percent == 99 and hud.battery_fill < 1.0 and hud.flow == "DRAIN")
		game.charge.set_charge(16.0, "ceiling laser")
		check(mode + " displays the low battery level", hud.percent == 16 and is_equal_approx(hud.battery_fill, .16))
		game.charge.set_charge(64.0, "charger")
		check(mode + " updates during recharge", hud.percent == 64 and hud.flow == "CHG" and is_equal_approx(hud.battery_fill, .64))
		await create_timer(1.3).timeout
		check(mode + " clears the direction cue after charge stabilizes", hud.flow.is_empty())
		game.checkpoint = 7
		check(mode + " updates the bottom caption when the checkpoint changes", hud.level == "FLOOR 07 / CUBE")
		game.checkpoint = 3
		game.charge.reset()
		check(mode + " reset restores the meter", hud.percent == 100 and hud.flow.is_empty())

		if capture:
			if not use_xr:
				game.place_player(game.spawn_for(3))
				game.body.set_physics_process(false)
				var level: float = game.building.spec.levels[3]
				game.camera.global_position = Vector3(11.9, level + 1.72, 3.4)
				game.camera.look_at(Vector3(7.9, level + 1.35, 6.85))
				game.status.hide()
				game.notice_time = 0
				await frames(40)
			game.charge.set_charge(18.0, "movement")
			await frames(4)
			await RenderingServer.frame_post_draw
			var target: Viewport = hud.get_viewport() if use_xr else root
			var image := target.get_texture().get_image()
			check(mode + " rendered a capture", image.save_png(out.path_join("viewfinder-xr.png" if use_xr else "camcorder-point-lines.png")) == OK)
		game.queue_free()
		await frames(5)
		if use_xr:
			for tracker_node in [head, left, right]:
				XRServer.remove_tracker(tracker_node)
	var report := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	report.store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks}, "\t"))
	quit(0 if failed.is_empty() else 1)
