extends "res://tools/probes/void_game_probe.gd"
## Verifies the Color-sequence 6-Palette Chooser on F33 Color_Grid_Pallet (and strict pre-Color gating on F7):
##   - Pre-Color (F7): PaletteChooserStrip absent, active_palette locked to "monochrome"
##   - Color (F33 Color_Grid_Pallet): 6 swatch tiles (MONO, BAUHAUS, QUEER, ALBERS, MONDRIAN, MEMPHIS),
##     single-trigger swatch picking live-repaints both the 1:16 miniature and 1:4 glass-box playground.

const RoomSource = preload("res://commons/void/room_source.gd")


func run() -> void:
	out = ProjectSettings.globalize_path("res://doc/book/iterations/2026-11-22-bauhaus-studio-workstation")
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out)

	Engine.physics_ticks_per_second = 90
	RoomSource.use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = 33
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
	await frames(50)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	# 1. Verify Color floor F33 Color_Grid_Pallet Studio Workstation + 6-Palette Chooser!
	game.place_player(game.spawn_for(33))
	await frames(45)
	var f33_root: Node3D = game.building.content.roots.get(33, null)
	var mount33: Node3D = f33_root.find_child("scaffold-workstation", true, false) if f33_root != null else null
	var ws33: Node3D = _find_with_prop(mount33, "studio_ctrl")
	var st33: Node3D = ws33.get("studio_ctrl") if ws33 != null else null

	var pal_nodes: Dictionary = st33.get("palette_nodes") if st33 != null else {}
	check("C1 F33 Color_Grid_Pallet Studio Workstation spawned with 6 curated Color palettes (%d swatches)" % pal_nodes.size(),
		ws33 != null and st33 != null and bool(st33.call("color_unlocked")) and pal_nodes.size() == 6 and str(st33.get("active_palette")) == "bauhaus")

	var cam := Camera3D.new()
	root.add_child(cam)
	cam.make_current()

	if ws33 != null and st33 != null:
		# Shot 10: F33 overview in default Bauhaus Triad
		cam.fov = 56.0
		cam.global_position = ws33.to_global(Vector3(-2.4, 2.25, 2.65))
		cam.look_at(ws33.to_global(Vector3(-0.1, 1.15, -1.75)), Vector3.UP)
		await frames(10)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("10-f33-color-grid-pallet-bauhaus.png"))

		# Aim directly at the QUEER swatch tile on the far-edge Palette Chooser Strip and click trigger once!
		var aim := Node3D.new()
		root.add_child(aim)
		var queer_tile: Node3D = pal_nodes["queer"].root
		var q_pos: Vector3 = queer_tile.global_position
		aim.global_position = ws33.to_global(Vector3(-0.24, 1.55, 0.25))
		aim.look_at(q_pos, Vector3.UP)
		var res_q: String = ws33.call("space_press", aim, null)
		check("C2 Single trigger on QUEER palette swatch switches playground live (res=%s, active=%s)" % [res_q, str(st33.get("active_palette"))],
			res_q == "palette" and str(st33.get("active_palette")) == "queer")

		# Shot 11: Close-up of the console + 6-palette swatch bar + live QUEER playground!
		cam.fov = 52.0
		cam.global_position = ws33.to_global(Vector3(-0.15, 2.02, 1.48))
		cam.look_at(ws33.to_global(Vector3(-0.18, 1.00, -0.35)), Vector3.UP)
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("11-f33-palette-chooser-queer.png"))

		# Aim directly at the ALBERS swatch tile and click trigger once!
		var albers_tile: Node3D = pal_nodes["albers"].root
		aim.look_at(albers_tile.global_position, Vector3.UP)
		var res_a: String = ws33.call("space_press", aim, null)
		check("C3 Single trigger on ALBERS palette swatch switches playground live (res=%s, active=%s)" % [res_a, str(st33.get("active_palette"))],
			res_a == "palette" and str(st33.get("active_palette")) == "albers")

		# Shot 12: Same F33 playground transformed into Josef Albers warm ochre/sage/terracotta!
		cam.fov = 54.0
		cam.global_position = ws33.to_global(Vector3(-2.1, 2.15, 2.35))
		cam.look_at(ws33.to_global(Vector3(-0.15, 1.10, -1.65)), Vector3.UP)
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("12-f33-palette-chooser-albers.png"))

		# Test cycle_palette through MONDRIAN -> MEMPHIS -> MONO
		st33.call("cycle_palette")
		var after_m: String = str(st33.get("active_palette"))
		st33.call("cycle_palette")
		var after_mem: String = str(st33.get("active_palette"))
		st33.call("cycle_palette")
		var after_mono: String = str(st33.get("active_palette"))
		check("C4 cycle_palette steps cleanly ALBERS -> %s -> %s -> %s" % [after_m, after_mem, after_mono],
			after_m == "mondrian" and after_mem == "memphis" and after_mono == "monochrome")
		aim.queue_free()

	# 2. Verify strict pre-Color gating on F7 Point_Animatedcube (NO Palette Chooser before Color F28!)
	game.place_player(game.spawn_for(7))
	await frames(40)
	var f7_root: Node3D = game.building.content.roots.get(7, null)
	var mount7: Node3D = f7_root.find_child("scaffold-workstation", true, false) if f7_root != null else null
	var ws7: Node3D = _find_with_prop(mount7, "studio_ctrl")
	var st7: Node3D = ws7.get("studio_ctrl") if ws7 != null else null
	var pal7: Dictionary = st7.get("palette_nodes") if st7 != null else {}
	var refused_f7: bool = not bool(st7.call("select_palette", "queer")) if st7 != null else false
	check("C5 Pre-Color F7 Point_Animatedcube keeps Palette Chooser hidden and stays strictly monochrome (swatches=%d, refused=%s)" % [pal7.size(), str(refused_f7)],
		st7 != null and not bool(st7.call("color_unlocked")) and pal7.is_empty() and refused_f7 and str(st7.get("active_palette")) == "monochrome")

	cam.queue_free()

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)):
			failed += 1
	var report := {"passed": failed == 0, "failed": failed, "total": checks.size(), "checks": checks}
	var f := FileAccess.open(out.path_join("color_palette_report.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	print("[color_palette_chooser_probe] %d/%d passed" % [checks.size() - failed, checks.size()])
	quit(0 if failed == 0 else 1)


func _find_with_prop(node: Node, prop: String) -> Node3D:
	if node == null:
		return null
	if node is Node3D and node.get(prop) != null:
		return node
	for c in node.get_children():
		var hit := _find_with_prop(c, prop)
		if hit != null:
			return hit
	return null
