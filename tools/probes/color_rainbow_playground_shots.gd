extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Floor 31 (Color_Rainbow) before/after + interactive world-tinting verification.
const SHOTS := [
	[Vector3(0.0, 2.2, 8.2), Vector3(0.0, 1.8, -4.0), 80.0, "01_center_promenade"],
	[Vector3(-7.0, 2.5, 7.6), Vector3(-15.0, 1.5, -1.5), 76.0, "02_west_playground_shaft_a"],
	[Vector3(7.0, 2.5, 7.6), Vector3(15.0, 1.5, -1.5), 76.0, "03_east_playground_shaft_b"],
	[Vector3(-18.5, 2.8, 6.2), Vector3(4.0, 1.8, 1.0), 80.0, "04_full_floor_from_west"],
	[Vector3(18.5, 2.8, 6.2), Vector3(-4.0, 1.8, 1.0), 80.0, "05_full_floor_from_east"],
	[Vector3(-3.8, 1.8, 7.4), Vector3(0.0, 0.8, 3.6), 76.0, "06_crossroad_and_baskets"],
]

func run() -> void:
	var expect_new := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg == "--expect-new":
			expect_new = true
	var at: Dictionary = VoidFloor.table()
	var floor_idx: int = int(at.get("Color_Rainbow", 31))
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = floor_idx
	game = load("res://commons/void/void.tscn").instantiate()
	game.force_xr = false
	root.add_child(game)
	current_scene = game
	game.scene_loaded()
	game.scene_visible()
	game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	await frames(90)
	game.place_player(game.spawn_for(floor_idx))
	await frames(140)
	var level: float = float(game.building.spec.levels[floor_idx])
	var floor_root: Node3D = game.building.content.roots.get(floor_idx, null)
	check("Color_Rainbow floor loaded", floor_root != null)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	if expect_new and floor_root != null:
		_verify_layout(floor_root)

	for s in SHOTS:
		await _snap(s[0], s[1], float(s[2]), level, str(s[3]))

	if expect_new and floor_root != null:
		await _verify_interactions(floor_root, level)

	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(
		JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  ")
	)
	quit(0 if failed.is_empty() else 1)

func _snap(eye: Vector3, target: Vector3, fov: float, level: float, label: String) -> void:
	var camera := Camera3D.new()
	game.add_child(camera)
	camera.fov = fov
	camera.environment = game.atmosphere.environment
	camera.global_position = eye + Vector3(0, level, 0)
	camera.look_at(target + Vector3(0, level, 0))
	camera.make_current()
	await frames(8)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("%s.png" % label))
	camera.queue_free()
	FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(label)
	check("shot:" + label, true)

func _verify_layout(floor_root: Node3D) -> void:
	var rainbow_mount := floor_root.get_node_or_null("f2_rainbow_7_13")
	check("rainbow playground mount exists", rainbow_mount != null)
	if rainbow_mount == null:
		return
	var banners := rainbow_mount.find_children("PartyBanner*", "Node", true, false)
	var poles := rainbow_mount.find_children("BannerPole*", "Node", true, false)
	var finish_flags := rainbow_mount.find_children("FinishBannerStripe*", "Node", true, false)
	check("explicit pole flags and flat finish flag removed", banners.is_empty() and poles.is_empty() and finish_flags.is_empty())

	var baskets := 0
	for child in floor_root.get_children():
		if str(child.name).contains("mushroom-basket"):
			baskets += 1
	check("three colour mushroom baskets installed", baskets >= 3)

	var bounds := AABB()
	var first := true
	for mi in rainbow_mount.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible or mi.mesh == null:
			continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		bounds = box if first else bounds.merge(box)
		first = false
	var width_x := bounds.size.x
	check("rainbow playground spans across the floor (width >= 32m)", width_x >= 32.0)
	print("[void] Rainbow Playground X span: %.2f m (%.2f .. %.2f)" % [width_x, bounds.position.x, bounds.end.x])

func _verify_interactions(floor_root: Node3D, level: float) -> void:
	var rainbow_mount := floor_root.get_node_or_null("f2_rainbow_7_13")
	var wash := get_first_node_in_group("rainbow_world_wash")
	check("WorldColorWash controller registered", wash != null)
	if wash == null or rainbow_mount == null:
		return
	# 1. Step onto a Crimson Red tile on the Color Crossroad and verify world tint activates!
	var red_tile_pos := Vector3(-6.0, level + 0.1, 4.6)
	var celebration := rainbow_mount.find_child("RainbowCelebration", true, false)
	if celebration != null and celebration.has_method("sample_crosswalk_point"):
		var sampled: Dictionary = celebration.sample_crosswalk_point(Vector3(-5.0, 0.1, 4.6))
		if sampled.has("pos"):
			red_tile_pos = sampled.pos + Vector3(0, level, 0)
	game.place_player(red_tile_pos)
	await frames(45)
	var red_state: Dictionary = wash.get_state()
	check("stepping on crosswalk colour tile tints the world", bool(red_state.get("active", false)) and float(red_state.get("strength", 0.0)) > 0.3)
	await _snap(Vector3(-4.0, 2.0, 7.8), Vector3(0.0, 1.5, -2.0), 78.0, level, "07_tinted_crosswalk_step")

	# 2. Eat an Emerald/Turquoise colour mushroom from the east cool basket so
	#    shot 08 clearly showcases a distinct mushroom world-colour flood vs red shot 07!
	var eaten_ok := false
	var target_basket := floor_root.get_node_or_null("rainbow-mushroom-basket-east")
	if target_basket != null:
		for m in target_basket.find_children("*", "RigidBody3D", true, false):
			if m.has_method("eat"):
				m.eat()
				eaten_ok = true
				break
	await frames(45)
	var mush_state: Dictionary = wash.get_state()
	check("eating a basket colour mushroom colours the world", eaten_ok and bool(mush_state.get("active", false)) and float(mush_state.get("dream_wave", 0.0)) > 0.01)
	await _snap(Vector3(3.1, 2.0, 7.6), Vector3(-2.0, 1.5, -2.0), 78.0, level, "08_tinted_mushroom_eaten")

	# 2b. Verify existing Floor 31 edible mushroom (aqua-mushroom) also colours the world!
	var aqua_mount := floor_root.get_node_or_null("aqua-mushroom")
	var aqua_ok := false
	if aqua_mount != null:
		var aqua_m := aqua_mount.get_node_or_null("Artifact")
		if aqua_m != null and aqua_m.has_method("eat"):
			aqua_m.eat()
			aqua_ok = true
	await frames(35)
	var aqua_state: Dictionary = wash.get_state()
	check("existing Floor 31 aqua-mushroom colours the world aqua", aqua_ok and str(aqua_state.get("color", "")) == "41d5eb")

	# 3. Clear tint and verify restore works cleanly.
	wash.clear_tint()
	await frames(45)
	var cleared_state: Dictionary = wash.get_state()
	check("world tint clears cleanly back to neutral", not bool(cleared_state.get("active", false)))
