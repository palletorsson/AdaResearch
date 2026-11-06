extends "res://tools/probes/void_game_probe.gd"
## THE SPACE EDITOR ON FLOOR 20 (Trans_Playground), the display workstation in `space` mode from rooms.json, built
## in the actual tower: the box with its base plane 1 m over the slab, panes without colliders, the table dark, the
## sockets lit, the visor docked - and photographed. Nothing is fired here: the station persists Palle's own
## construction. Run: python tools/test_space_editor.py
var floors: Array = [20]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--floors="):
			floors = []
			for s in arg.trim_prefix("--floors=").split(","): floors.append(int(s))
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = int(floors[0])
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(120)
	for f in floors:
		game.place_player(game.spawn_for(int(f))); await frames(220)
		await check_floor(int(f))
	finish()

func check_floor(f: int) -> void:
	var level: float = float(game.building.spec.levels[f])
	var mount: Node3D = game.building.content.exhibits.get("%d/scaffold-workstation" % f)
	var art: Node = mount.get_node_or_null("Artifact") if mount else null
	check("floor %d: the workstation stands (rooms.json)" % f, art != null)
	if art == null: return
	check("floor %d: space mode, tier %d" % [f, int(art.get("tier"))], bool(art.get("space")) and art.is_in_group("space_editors"))
	var base_y: float = art.output.global_position.y - level
	var bay: Node3D = art.output.get_node("Bay"); var pane_bodies := 0
	for pane in bay.find_children("GlassPane*", "MeshInstance3D", false, false): pane_bodies += pane.find_children("*", "StaticBody3D", true, false).size()
	var top: float = base_y + float(art.get("chamber_height"))
	check("floor %d: the box stands on the slab (%.2f m), top %.2f m, panes free (%d), table and visor dark" % [f, base_y, top, pane_bodies], absf(base_y) < .05 and pane_bodies == 0 and not art.support.visible and not art.visit.headset.enabled and (f == 20 or top < float(game.building.spec.storey_height) - float(game.building.spec.slab_thickness)))
	var open: Array = art.space_tools.filter(func(x): return int(x.get("from_floor", 0)) <= f).map(func(x): return str(x.label))
	var jt: float = art.jumbotron.global_position.y - level
	check("floor %d: the jumbotron hangs at %.2f m with %d tiles; open here: %s" % [f, jt, art.tiles.size(), ", ".join(open)], art.tiles.size() == (art.space_tools.size() + 2) * 4 and jt > 3.0 and jt < top - .3 and int(art.space_floor) == f)
	var dots: int = art.space_grid.multimesh.instance_count if art.space_grid and art.space_grid.multimesh else 0
	check("floor %d: the grid is on (%d node dots)" % [f, dots], dots > 100)
	if DisplayServer.get_name() != "headless":
		var box: Vector3 = art.output.global_position
		var shots := [[box + Vector3(-5.5, 1.8, 7.5), box + Vector3(0, 2.2, 0), 70.0, "floor%02d_space_hall" % f], [box + Vector3(1.4, 1.65, 1.8), art.jumbotron.global_position + Vector3(0, -.2, 0), 78.0, "floor%02d_space_jumbotron" % f]]
		for s in shots:
			var camera := Camera3D.new(); game.add_child(camera); camera.fov = float(s[2]); camera.environment = game.atmosphere.environment
			camera.global_position = s[0]; camera.look_at(s[1]); camera.make_current()
			game.body.visible = false; game.status.hide(); game.charge_display.hide(); game.notice_time = 0
			if game.desktop_help != null: game.desktop_help.hide()
			await frames(8); await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(out.path_join("%s.png" % s[3]))
			camera.queue_free()

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[space_editor_floor] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
