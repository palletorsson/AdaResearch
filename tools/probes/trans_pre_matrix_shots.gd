extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Live Godot verification, walkability test & screenshots for F13 Shaft A Arena
## (West Coin Scaffold + Center Sunken Bomb Basin + East Package Scaffold + Warburton Wall).

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var pre_idx: int = int(at.get("Trans_Pre", 13))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = pre_idx
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = false
	root.add_child(game)
	current_scene = game
	game.scene_loaded()
	game.scene_visible()
	game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	if game.get("soundscape") != null:
		game.soundscape.process_mode = Node.PROCESS_MODE_DISABLED
	await frames(60)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	game.place_player(game.spawn_for(pre_idx))
	await frames(70)
	var lvl: float = float(game.building.spec.levels[pre_idx])
	var fl_root: Node3D = game.building.content.roots.get(pre_idx, null)
	check("F13 Trans_Pre loaded cleanly", fl_root != null)

	if fl_root != null:
		var gallery: Node3D = fl_root.find_child("motion-vocabulary-gallery", true, false)
		check("MotionVocabularyGallery mounted", gallery != null)
		if gallery != null:
			var south_sc := gallery.find_child("SouthCoinScaffold", true, false)
			var north_sc := gallery.find_child("NorthPackageScaffold", true, false)
			var basin := gallery.find_child("ShaftABombBasin", true, false)
			var wall := gallery.find_child("WarburtonCuratorialWall", true, false)
			check("South Coin Scaffold, North Package Scaffold, Shaft A Bomb Basin & Warburton Wall built", south_sc != null and north_sc != null and basin != null and wall != null)

		var stages := ["static", "translate", "rotate", "scale", "archetype"]
		var coin_nodes: Array = []
		var bomb_nodes: Array = []
		var pkg_nodes: Array = []
		for st in stages:
			coin_nodes.append(_find_with_prop(fl_root.find_child("matrix-coin-" + st, true, false), "motion_curve"))
			bomb_nodes.append(_find_with_prop(fl_root.find_child("matrix-bomb-" + st, true, false), "elbow_travel"))
			pkg_nodes.append(_find_with_prop(fl_root.find_child("matrix-package-" + st, true, false), "_ribbon_holder"))
		check("All 15 monochrome specimens spawned (5 Coin, 5 Bomb, 5 Package)", not coin_nodes.has(null) and not bomb_nodes.has(null) and not pkg_nodes.has(null))

		if not coin_nodes.has(null) and not bomb_nodes.has(null) and not pkg_nodes.has(null):
			var c_static_y0: float = coin_nodes[0].global_position.y
			var c_tr_y0: float = coin_nodes[1].global_position.y
			var c_rot_r0: float = coin_nodes[2].rotation.y
			var c_arch_y0: float = coin_nodes[4].global_position.y
			var c_arch_r0: float = coin_nodes[4].rotation.y

			var b_static_p0: Vector3 = bomb_nodes[0].get("body").position
			var b_tr_p0: Vector3 = bomb_nodes[1].get("body").position
			var b_rot_r0: float = bomb_nodes[2].get("visual").rotation_degrees.y
			var b_sc_s0: float = bomb_nodes[3].get("visual").scale.x
			var b_arch_p0: Vector3 = bomb_nodes[4].get("body").position

			var p_static_s0: float = pkg_nodes[0].get("_ribbon_holder").scale.x
			var p_sc_s0: float = pkg_nodes[3].get("_ribbon_holder").scale.x
			var p_arch_y0: float = pkg_nodes[4].global_position.y
			var p_arch_s0: float = pkg_nodes[4].get("_ribbon_holder").scale.x

			await frames(40)

			check("Coin 01 STATIC frozen & 02/03/05 animate live", is_equal_approx(coin_nodes[0].global_position.y, c_static_y0) and absf(coin_nodes[1].global_position.y - c_tr_y0) > 0.01 and absf(coin_nodes[2].rotation.y - c_rot_r0) > 0.05 and absf(coin_nodes[4].global_position.y - c_arch_y0) > 0.01 and absf(coin_nodes[4].rotation.y - c_arch_r0) > 0.05)
			check("Bomb basin 01 STATIC frozen & 02/03/04/05 animate live inside Shaft A", bomb_nodes[0].get("body").position.distance_to(b_static_p0) < 0.001 and bomb_nodes[1].get("body").position.distance_to(b_tr_p0) > 0.05 and absf(bomb_nodes[2].get("visual").rotation_degrees.y - b_rot_r0) > 5.0 and absf(bomb_nodes[3].get("visual").scale.x - b_sc_s0) > 0.02 and bomb_nodes[4].get("body").position.distance_to(b_arch_p0) > 0.05)
			check("Package 01 STATIC frozen & 04/05 pulse ribbon+box live", is_equal_approx(pkg_nodes[0].get("_ribbon_holder").scale.x, p_static_s0) and absf(pkg_nodes[3].get("_ribbon_holder").scale.x - p_sc_s0) > 0.02 and absf(pkg_nodes[4].global_position.y - p_arch_y0) > 0.01 and absf(pkg_nodes[4].get("_ribbon_holder").scale.x - p_arch_s0) > 0.01)

		# Real DesktopWalker walkability test: climb South Coin Scaffold West Ramp -> top deck (y = +0.58 m)!
		game.place_player(Vector3(-16.7, lvl + 0.08, 4.9))
		game.body.rotation.y = -PI * 0.5 # facing +X (East, straight up the West ramp!)
		await frames(8)
		var y_start: float = game.body.global_position.y - lvl
		game.body.drive = Vector2(0.0, -1.0)
		await frames(85)
		game.body.drive = Vector2.ZERO
		await frames(8)
		var y_south_top: float = game.body.global_position.y - lvl
		check("DesktopWalker walks smoothly UP South Coin Scaffold West ramp onto deck (y=%.2f -> %.2f)" % [y_start, y_south_top], y_south_top > 0.50 and y_south_top < 0.70)
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("walk_south")

		# Climb North Package Scaffold West Ramp -> top deck (y = +0.58 m)!
		game.place_player(Vector3(-16.7, lvl + 0.08, -4.9))
		game.body.rotation.y = -PI * 0.5
		await frames(8)
		game.body.drive = Vector2(0.0, -1.0)
		await frames(85)
		game.body.drive = Vector2.ZERO
		await frames(8)
		var y_north_top: float = game.body.global_position.y - lvl
		check("DesktopWalker walks smoothly UP North Package Scaffold West ramp onto deck (y=%.2f)" % y_north_top, y_north_top > 0.50 and y_north_top < 0.70)
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("walk_north")

		# Walk OUT of the recessed Shaft A Bomb Basin up the West white walk-out ramp (y = -0.82 -> 0.0 m)!
		game.place_player(Vector3(-11.0, lvl - 0.74, 0.0))
		game.body.rotation.y = PI * 0.5 # facing -X (West, up the West walk-out ramp!)
		await frames(8)
		game.body.drive = Vector2(0.0, -1.0)
		await frames(85)
		game.body.drive = Vector2.ZERO
		await frames(8)
		var y_out_basin: float = game.body.global_position.y - lvl
		check("DesktopWalker walks cleanly OUT of Shaft A Bomb Basin back to floor (y=%.2f)" % y_out_basin, y_out_basin > -0.08 and y_out_basin < 0.16)
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("walk_basin")

		# Verify Static Monochrome Object Play Path replaced movement-circuit (zero moving architectural platforms!)
		check("Old movement-circuit removed (no architectural transitions on F13)", fl_root.find_child("movement-circuit", true, false) == null)
		var play_path := fl_root.find_child("monochrome-object-path", true, false)
		check("Static MonochromeObjectPath mounted around Shaft B", play_path != null)
		var pc1 := _find_with_prop(fl_root.find_child("path-coin-1", true, false), "motion_curve")
		var pb1 := _find_with_prop(fl_root.find_child("path-bomb-east-n", true, false), "elbow_travel")
		var pp0 := _find_with_prop(fl_root.find_child("path-package-start", true, false), "_ribbon_holder")
		var pp1 := _find_with_prop(fl_root.find_child("path-package-detour", true, false), "_ribbon_holder")
		var pp2 := _find_with_prop(fl_root.find_child("path-package-finale", true, false), "_ribbon_holder")
		check("Static Play Path objects spawned (Coins, active Bombs, 3 Random Packages)", pc1 != null and pb1 != null and pp0 != null and pp1 != null and pp2 != null and not bool(pb1.get("demonstration")))

		# End-to-end live physics test: collect path-package-start -> drops RANDOM throwable object -> throw into active Bomb -> DETONATES!
		var pkg_mount: Node3D = fl_root.find_child("path-package-start", true, false)
		game.place_player(Vector3(12.6, lvl + 0.62, -5.5))
		await frames(20)
		var dropped: RigidBody3D = null
		if pkg_mount != null:
			for c in pkg_mount.get_children():
				if c is RigidBody3D and c.has_meta("gift_cube_reward"):
					dropped = c
					break
		var reward_id := str(dropped.get_meta("gift_cube_reward", "")) if dropped != null else ""
		check("Collecting Package drops a random physical throwable object (%s)" % reward_id, dropped != null and not reward_id.is_empty())
		if dropped != null and pb1 != null:
			# Ensure bomb arm_delay elapsed, then position player looking right at the bomb with HUD visible!
			await frames(60)
			var target_pt: Vector3 = pb1.get("body").global_position
			game.place_player(Vector3(target_pt.x - 4.2, lvl + 0.62, target_pt.z - 2.4))
			game.body.look_at(Vector3(target_pt.x, game.body.global_position.y, target_pt.z), Vector3.UP)
			game.camera.rotation = Vector3(-0.08, 0.0, 0.0)
			game.camera.make_current()
			game.charge_display.show()
			await frames(4)
			dropped.freeze = false
			dropped.global_position = target_pt + Vector3(0.0, 0.15, -1.5)
			dropped.linear_velocity = (target_pt - dropped.global_position).normalized() * 8.0
			var hit_boom := false
			for _f in 40:
				await frames(1)
				if bool(pb1.get("spent")):
					hit_boom = true
					break
			check("Throwing random Package object (%s) detonates active Play Path Bomb live!" % reward_id, hit_boom)
			await frames(3)
			var boom_fx_ok: bool = (pb1.get("shock_ring") != null and pb1.get("shock_ring").visible and pb1.get("boom_light") != null and pb1.get("boom_light").visible and pb1.get("boom_shards").size() >= 20)
			var flash_vis: bool = (game.impact_flash_rect != null and game.impact_flash_rect.visible) if not game.vr else game.fade.visible
			var flash_ok: bool = float(game.get("impact_flash_time")) > 0.0 and flash_vis
			var shake_ok: bool = float(game.get("shake_time")) > 0.0 and (absf(game.camera.h_offset) > 0.001 or absf(game.camera.v_offset) > 0.001 or absf(game.camera.rotation.z) > 0.001)
			var blink_ok: bool = float(game.charge_display.get("_charge_blink_time")) > 0.0
			check("Stronger 3D Boom active (shockwave ring + OmniLight3D + 22 shrapnel shards)", boom_fx_ok)
			check("Boom triggers full-screen flash + Desktop camera shake + blinking charge bar", flash_ok and shake_ok and blink_ok)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("boom_01_live_impact.png"))
			check("shot:boom_01_live_impact", true)
			await frames(20)
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("boom_02_aftershock.png"))
			check("shot:boom_02_aftershock", true)

			# Reset impact timers, wait a beat, then verify non-mine hazard impact fires IDENTICAL flash + shake + blinking charge bar!
			game.impact_flash_time = 0.0
			if game.impact_flash_rect != null: game.impact_flash_rect.visible = false
			game.shake_time = 0.0
			game.shake_strength = 0.0
			game.camera.h_offset = 0.0
			game.camera.v_offset = 0.0
			game.camera.rotation.z = 0.0
			game.charge_display.set("_charge_blink_time", 0.0)
			await frames(3)
			game.charge.discharge(10.0, "ceiling laser")
			await frames(4)
			var any_flash_vis: bool = (game.impact_flash_rect != null and game.impact_flash_rect.visible) if not game.vr else game.fade.visible
			var any_flash: bool = float(game.get("impact_flash_time")) > 0.0 and any_flash_vis
			var any_shake: bool = float(game.get("shake_time")) > 0.0 and (absf(game.camera.h_offset) > 0.001 or absf(game.camera.v_offset) > 0.001 or absf(game.camera.rotation.z) > 0.001)
			var any_blink: bool = float(game.charge_display.get("_charge_blink_time")) > 0.0
			check("Generic non-mine impact (ceiling laser) triggers IDENTICAL flash + shake + blinking charge bar", any_flash and any_shake and any_blink)
			game.charge.reset()
			game.impact_flash_time = 0.0
			if game.impact_flash_rect != null: game.impact_flash_rect.visible = false
			game.hurt_time = 0.0
			game.shake_time = 0.0
			game.camera.h_offset = 0.0
			game.camera.v_offset = 0.0
			game.camera.rotation.z = 0.0
			game.charge_display.hide()

		# Walk UP the Static Play Path Entry Ramp (x: -1.5 -> +1.5, y: 0 -> +0.58 m)!
		game.place_player(Vector3(-1.5, lvl + 0.08, -5.5))
		game.body.rotation.y = -PI * 0.5 # facing +X (East, up the Entry Ramp!)
		await frames(8)
		game.body.drive = Vector2(0.0, -1.0)
		await frames(85)
		game.body.drive = Vector2.ZERO
		await frames(8)
		var y_path_top: float = game.body.global_position.y - lvl
		check("DesktopWalker walks smoothly UP Static Play Path Entry Ramp onto North deck (y=%.2f)" % y_path_top, y_path_top > 0.50 and y_path_top < 0.70)
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("walk_path_entry")

		# Walk DOWN the Static Play Path Exit Ramp (x: 6.8 -> 3.6, y: +0.58 -> 0.0 m)!
		game.place_player(Vector3(6.8, lvl + 0.66, 4.8))
		game.body.rotation.y = PI * 0.5 # facing -X (West, down the Exit Ramp!)
		await frames(8)
		game.body.drive = Vector2(0.0, -1.0)
		await frames(85)
		game.body.drive = Vector2.ZERO
		await frames(8)
		var y_path_exit: float = game.body.global_position.y - lvl
		check("DesktopWalker walks smoothly DOWN Static Play Path Exit Ramp to floor (y=%.2f)" % y_path_exit, y_path_exit > -0.08 and y_path_exit < 0.16)
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("walk_path_exit")

	# Panoramic pillar-free West->East screenshots + Shaft A Basin + Static Play Path!
	await _snap(Vector3(-19.5, 3.0, 0.0), Vector3(-6.0, 1.0, 0.0), 86.0, lvl, "arena_01_west_portal_pillar_free")
	await _snap(Vector3(-14.2, 2.25, 4.9), Vector3(-5.0, 0.4, -2.5), 84.0, lvl, "arena_02_from_south_coin_scaffold")
	await _snap(Vector3(-14.2, 2.25, -4.9), Vector3(-5.0, 0.4, 2.5), 84.0, lvl, "arena_03_from_north_package_scaffold")
	await _snap(Vector3(-14.2, 3.0, 0.0), Vector3(-8.5, -0.5, 0.0), 86.0, lvl, "arena_04_shaft_a_bomb_basin_east")
	await _snap(Vector3(-3.2, 2.7, -5.5), Vector3(11.0, 0.9, -5.5), 82.0, lvl, "path_01_entry_north_leg")

	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(
		JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  ")
	)
	quit(0 if failed.is_empty() else 1)

func _find_with_prop(root_n: Node, prop: String) -> Node:
	if root_n == null: return null
	if prop in root_n: return root_n
	for c in root_n.find_children("*", "", true, false):
		if prop in c:
			return c
	return null

func _snap(eye: Vector3, look_at_pt: Vector3, fov: float, lvl: float, label: String) -> void:
	var cam := Camera3D.new()
	cam.fov = fov
	cam.near = 0.08
	cam.far = 160.0
	cam.environment = game.atmosphere.environment
	game.add_child(cam)
	cam.global_position = Vector3(eye.x, lvl + eye.y, eye.z)
	cam.look_at(Vector3(look_at_pt.x, lvl + look_at_pt.y, look_at_pt.z), Vector3.UP)
	cam.make_current()
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("%s.png" % label))
	cam.queue_free()
	FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(label)
	check("shot:" + label, true)
