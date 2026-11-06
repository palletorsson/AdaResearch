extends "res://tools/probes/void_game_probe.gd"
## THE COLOUR FLOORS, SEEN FROM WHERE A VISITOR STANDS (2026-11-05): hand-placed cameras per floor, where the survey's
## automatic framing went blind (inside the light rooms, at the floor's edges, over the shafts). Floor-local metres;
## the level is added. Output ada_run/color-shots/desktop/<name>.png. Run: python tools/test_color_shots.py
const SHOTS := [
	[30, Vector3(0, 1.6, 8.5), Vector3(0, 2.2, -6), "30_aisle"], [30, Vector3(0, 2.0, -1.0), Vector3(0, 1.8, -4.7), "30_stations"],
	[30, Vector3(0, 3.0, 5.0), Vector3(0, 2.0, 16), "30_landscape_outside"], [30, Vector3(-16, 1.6, -7), Vector3(-19, 2.5, 0), "30_alphabet"],
	[31, Vector3(-10, 1.6, 3), Vector3(-14, 1.5, -2), "31_white_room"], [31, Vector3(-15.5, 1.7, 1.5), Vector3(-18.5, 1.0, 0), "31_lamps"],
	[31, Vector3(0, 1.7, 0.5), Vector3(0, 1.2, 4.6), "31_pink"], [31, Vector3(15.5, 1.8, 0), Vector3(19, 2.3, 0), "31_cube_wall"],
	[31, Vector3(6, 1.6, 4), Vector3(10, 2.5, 0), "31_light_well"],
	[32, Vector3(0, 1.6, -5), Vector3(0, 2.5, 3), "32_salon"], [32, Vector3(-3.5, 1.5, -4), Vector3(-2, 1.3, -2), "32_controller"],
	[33, Vector3(0, 1.6, 8), Vector3(0, 2.5, 0), "33_path"], [33, Vector3(3, 1.6, 2), Vector3(6, 1.4, 5), "33_film"],
	[34, Vector3(-12, 2.0, 8.8), Vector3(-12, 2.0, -6), "34_field_south_edge"], [34, Vector3(-10, 4.5, 6), Vector3(-10, 0, -1), "34_field_over_shaft"],
	# (14, 0) and (-14, -6) are pillars of the field (lanes x -18/-14/-6/0/6/14/18, rows z -6..6): a camera there is blind.
	[34, Vector3(15.5, 1.6, 1.5), Vector3(19.8, 1.8, -0.2), "34_sets_wall"], [34, Vector3(20.8, 1.6, -0.2), Vector3(19.8, 1.8, -0.2), "34_sets_wall_from_edge"], [34, Vector3(-12.5, 1.8, -7.8), Vector3(-17, 1.0, -7.6), "34_mixing"],
	[34, Vector3(-10, 1.6, 3.6), Vector3(-10, -1, 0), "34_shaft_rim_down"],
	[35, Vector3(-10, 1.6, 7), Vector3(-10, 1.5, 0), "35_forest_over_shaft"], [35, Vector3(-10, 1.6, 4), Vector3(-16.5, 2.5, -1), "35_forest_west"], [35, Vector3(0, 1.7, 6.5), Vector3(0, 0.5, -0.5), "35_grid_console"],
	[36, Vector3(-10, 1.6, 5.5), Vector3(-10, 6, 0), "36_shaft_up"],
	[36, Vector3(-4, 1.6, 3.5), Vector3(-4, 2.2, 8), "36_albers"], [36, Vector3(-9.5, 1.6, 2.5), Vector3(-9.5, 2.2, 8), "36_albers_west_bay"], [36, Vector3(0, 1.7, 1), Vector3(-9.5, 2.0, 8), "36_south_wall"], [36, Vector3(3, 1.6, 4), Vector3(3, 1.5, 8), "36_spray"],
	[36, Vector3(-10, 1.6, -2), Vector3(-10, 1.5, -5.6), "36_canvases"],
	[37, Vector3(0, 1.7, -4.5), Vector3(0, 1.5, 3.4), "37_office"], [37, Vector3(-8, 2.2, 10), Vector3(0, 1.5, 6), "37_office_south"], [37, Vector3(-11.5, 1.7, -2), Vector3(-11.5, 2.0, -9.3), "37_wall_studies"],
	[37, Vector3(-17, 1.6, 12), Vector3(-17, 2.5, 0), "37_hallway_mouth"], [37, Vector3(-8, 1.6, 7), Vector3(-17, 2.0, 2), "37_west_end"], [37, Vector3(-17, 1.6, 5.5), Vector3(-17, 2.5, -4), "37_hallway_inside"],
	[37, Vector3(14.6, 1.7, -2), Vector3(14.6, 2.0, -9.5), "37_assembly"], [37, Vector3(0, 1.6, -3.5), Vector3(0, 1.2, -7.6), "37_spaces"],
]

func run() -> void:
	var only: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			for s in arg.trim_prefix("--floors=").split(","): only.append(int(s))
	var shots: Array = SHOTS.filter(func(s): return only.is_empty() or int(s[0]) in only)
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = int(shots[0][0])
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	var current := -1
	for s in shots:
		var f: int = s[0]
		if f != current:
			game.place_player(game.spawn_for(f)); await frames(200); current = f
		var level: float = float(game.building.spec.levels[f])
		var camera := Camera3D.new(); game.add_child(camera); camera.fov = 70; camera.environment = game.atmosphere.environment
		camera.global_position = (s[1] as Vector3) + Vector3(0, level, 0); camera.look_at((s[2] as Vector3) + Vector3(0, level, 0)); camera.make_current()
		game.body.visible = false; game.status.hide(); game.charge_display.hide(); game.notice_time = 0
		if game.desktop_help != null: game.desktop_help.hide()
		await frames(8); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%s.png" % s[3]))
		camera.queue_free()
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(str(s[3]))
		check(str(s[3]), true)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": true, "checks": checks, "failed": failed}, "  "))
	quit(0)
