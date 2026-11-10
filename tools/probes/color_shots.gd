extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")
## THE COLOUR FLOORS, SEEN FROM WHERE A VISITOR STANDS (2026-11-05): hand-placed cameras per floor, where the survey's
## automatic framing went blind (inside the light rooms, at the floor's edges, over the shafts). Floor-local metres;
## the level is added. Output ada_run/color-shots/desktop/<name>.png. Run: python tools/test_color_shots.py
const SHOTS := [
	["Color_Context_Placed", Vector3(0, 1.6, 8.5), Vector3(0, 2.2, -6), "30_aisle"], ["Color_Context_Placed", Vector3(0, 2.0, -1.0), Vector3(0, 1.8, -4.7), "30_stations"],
	["Color_Context_Placed", Vector3(0, 3.0, 5.0), Vector3(0, 2.0, 16), "30_landscape_outside"], ["Color_Context_Placed", Vector3(-16, 1.6, -7), Vector3(-19, 2.5, 0), "30_alphabet"],
	["Color_Flashlight", Vector3(-10, 1.6, 3), Vector3(-14, 1.5, -2), "31_white_room"], ["Color_Flashlight", Vector3(-15.5, 1.7, 1.5), Vector3(-18.5, 1.0, 0), "31_lamps"],
	["Color_Flashlight", Vector3(0, 1.7, 0.5), Vector3(0, 1.2, 4.6), "31_pink"], ["Color_Flashlight", Vector3(15.5, 1.8, 0), Vector3(19, 2.3, 0), "31_cube_wall"],
	["Color_Flashlight", Vector3(6, 1.6, 4), Vector3(10, 2.5, 0), "31_light_well"],
	["Color_Nails", Vector3(0, 1.6, -5), Vector3(0, 2.5, 3), "32_salon"], ["Color_Nails", Vector3(-3.5, 1.5, -4), Vector3(-2, 1.3, -2), "32_controller"],
	["Color_Rainbow", Vector3(0, 1.6, 8), Vector3(0, 2.5, 0), "33_path"], ["Color_Rainbow", Vector3(3, 1.6, 2), Vector3(6, 1.4, 5), "33_film"],
	["Color_Pillar", Vector3(-12, 2.0, 8.8), Vector3(-12, 2.0, -6), "34_field_south_edge"], ["Color_Pillar", Vector3(-10, 4.5, 6), Vector3(-10, 0, -1), "34_field_over_shaft"],
	# (14, 0) and (-14, -6) are pillars of the field (lanes x -18/-14/-6/0/6/14/18, rows z -6..6): a camera there is blind.
	["Color_Pillar", Vector3(15.5, 1.6, 1.5), Vector3(19.8, 1.8, -0.2), "34_sets_wall"], ["Color_Pillar", Vector3(20.8, 1.6, -0.2), Vector3(19.8, 1.8, -0.2), "34_sets_wall_from_edge"], ["Color_Pillar", Vector3(-12.5, 1.8, -7.8), Vector3(-17, 1.0, -7.6), "34_mixing"],
	["Color_Pillar", Vector3(-10, 1.6, 3.6), Vector3(-10, -1, 0), "34_shaft_rim_down"],
	["Color_Grid_Pallet", Vector3(-10, 1.6, 7), Vector3(-10, 1.5, 0), "35_forest_over_shaft"], ["Color_Grid_Pallet", Vector3(-10, 1.6, 4), Vector3(-16.5, 2.5, -1), "35_forest_west"], ["Color_Grid_Pallet", Vector3(0, 1.7, 6.5), Vector3(0, 0.5, -0.5), "35_grid_console"],
	["Color_Paint", Vector3(-10, 1.6, 5.5), Vector3(-10, 6, 0), "36_shaft_up"],
	["Color_Paint", Vector3(-4, 1.6, 3.5), Vector3(-4, 2.2, 8), "36_albers"], ["Color_Paint", Vector3(-9.5, 1.6, 2.5), Vector3(-9.5, 2.2, 8), "36_albers_west_bay"], ["Color_Paint", Vector3(0, 1.7, 1), Vector3(-9.5, 2.0, 8), "36_south_wall"], ["Color_Paint", Vector3(3, 1.6, 4), Vector3(3, 1.5, 8), "36_spray"],
	["Color_Paint", Vector3(-10, 1.6, -2), Vector3(-10, 1.5, -5.6), "36_canvases"],
	["Color_Walls", Vector3(0, 1.7, -4.5), Vector3(0, 1.5, 3.4), "37_office"], ["Color_Walls", Vector3(-8, 2.2, 10), Vector3(0, 1.5, 6), "37_office_south"], ["Color_Walls", Vector3(-11.5, 1.7, -2), Vector3(-11.5, 2.0, -9.3), "37_wall_studies"],
	["Color_Walls", Vector3(-17, 1.6, 12), Vector3(-17, 2.5, 0), "37_hallway_mouth"], ["Color_Walls", Vector3(-8, 1.6, 7), Vector3(-17, 2.0, 2), "37_west_end"], ["Color_Walls", Vector3(-17, 1.6, 5.5), Vector3(-17, 2.5, -4), "37_hallway_inside"],
	["Color_Walls", Vector3(14.6, 1.7, -2), Vector3(14.6, 2.0, -9.5), "37_assembly"], ["Color_Walls", Vector3(0, 1.6, -3.5), Vector3(0, 1.2, -7.6), "37_spaces"],
]

func run() -> void:
	var only: Array = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			for s in arg.trim_prefix("--floors=").split(","): only.append(int(s))
	var at: Dictionary = VoidFloor.table() # SHOTS name their floor by MAP; --floors= still takes indices
	var shots: Array = SHOTS.map(func(s): return [int(at.get(s[0], -1))] + s.slice(1)).filter(func(s): return only.is_empty() or int(s[0]) in only)
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
