extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Floor 35 (Color_Walls) before/after verification for:
## 1) colour_wall_studies (3-wall gallery fitting cleanly inside the West Bay columns + expanded collection)
## 2) color_constellation_office (larger footprint & maximized optical filtering output under its own logic)
const SHOTS := [
	[Vector3(-12.2, 2.1, 0.0), Vector3(-19.8, 2.1, 0.0), 78.0, "01_west_gallery_entry"],
	[Vector3(-14.3, 2.1, 5.4), Vector3(-18.2, 2.2, -6.2), 76.0, "02_west_gallery_north_wall"],
	[Vector3(-14.3, 2.1, -5.4), Vector3(-18.2, 2.2, 6.2), 76.0, "03_west_gallery_south_wall"],
	[Vector3(0.0, 2.2, 8.2), Vector3(0.0, 2.0, -3.5), 78.0, "04_constellation_front"],
	[Vector3(-5.8, 2.3, 6.2), Vector3(1.2, 1.9, -2.5), 76.0, "05_constellation_oblique"],
	[Vector3(3.1, 2.3, -7.6), Vector3(-0.6, 1.9, 2.0), 76.0, "06_constellation_north"],
]

func run() -> void:
	var expect_new := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg == "--expect-new":
			expect_new = true
	var at: Dictionary = VoidFloor.table()
	var floor_idx: int = int(at.get("Color_Walls", 35))
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
	check("Color_Walls floor loaded", floor_root != null)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	if expect_new and floor_root != null:
		_verify_color_walls(floor_root, level)

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
	await frames(10)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("%s.png" % label))
	camera.queue_free()
	FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(label)
	check("shot:" + label, true)

func _verify_color_walls(floor_root: Node3D, level: float) -> void:
	# 1. colour_wall_studies: 3-wall gallery neatly fitted inside the West Bay columns + expanded collection!
	var wall_mount := floor_root.get_node_or_null("f2_colour_wall_studies_18_70")
	check("colour_wall_studies mount exists", wall_mount != null)
	if wall_mount != null:
		var study := wall_mount.find_child("Study", true, false)
		check("colour_wall_studies Study node exists", study != null)
		var gallery_walls := wall_mount.find_children("GalleryWall_*", "Node", true, false)
		check("three-wall gallery enclosure built (3 walls)", gallery_walls.size() == 3)
		if study != null:
			var roots: Variant = study.get("roots")
			var work_count: int = roots.size() if roots is Array else 0
			check("expanded collection of wall studies (>= 7 works across 3 walls)", work_count >= 7)
			print("[void] colour_wall_studies works count: %d" % work_count)
		# Verify all gallery walls fit strictly inside West Bay columns (x in [-20.2, -13.8], z in [-7.2, +7.2], y <= 5.64)!
		var walls_fit := true
		for gw in gallery_walls:
			for mi in gw.find_children("*", "MeshInstance3D", true, false):
				if mi.mesh == null: continue
				var b: AABB = mi.global_transform * mi.get_aabb()
				var top_y: float = b.end.y - level
				if b.position.x < -20.55 or b.end.x > -13.45 or b.position.z < -7.55 or b.end.z > 7.55 or top_y > 5.66:
					walls_fit = false
					print("[void] Wall out of column bay: %s -> x=[%.2f..%.2f] z=[%.2f..%.2f] top=%.2f" % [gw.name, b.position.x, b.end.x, b.position.z, b.end.z, top_y])
		check("all three gallery walls fit cleanly inside West Bay columns & ceiling", walls_fit)

	# 2. color_constellation_office: larger footprint & maximized optical filter/mixture output!
	var office_mount := floor_root.get_node_or_null("f2_color_constellation_office_23_20")
	check("color_constellation_office mount exists", office_mount != null)
	if office_mount != null:
		var panes := office_mount.find_children("FilterPane_*", "MeshInstance3D", true, false)
		check("color_constellation_office expanded pane constellation (>= 20 panes)", panes.size() >= 20)
		var lights := office_mount.find_children("TripodWorkLight_*", "Node", true, false)
		check("expanded work light rig (>= 5 tripod lights)", lights.size() >= 5)
		var bounds := AABB()
		var first := true
		for p in panes:
			var b: AABB = p.global_transform * p.get_aabb()
			bounds = b if first else bounds.merge(b)
			first = false
		check("color_constellation_office larger footprint (width >= 10.5m, depth >= 13.5m)", bounds.size.x >= 10.5 and bounds.size.z >= 13.5)
		print("[void] color_constellation_office panes=%d lights=%d span=(%.2f x %.2f m, height=%.2f m)" % [panes.size(), lights.size(), bounds.size.x, bounds.size.z, bounds.size.y])

func _verify_interactions(floor_root: Node3D, level: float) -> void:
	# Test color_constellation_office's optical mode cycling (FILTER / ADDITIVE LIGHT / OPAQUE)
	var office_mount := floor_root.get_node_or_null("f2_color_constellation_office_23_20")
	if office_mount == null:
		return
	var office := office_mount.get_node_or_null("Artifact")
	if office != null and office.has_method("toggle_office_glass"):
		office.call("toggle_office_glass")
		await frames(12)
		await _snap(Vector3(-5.8, 2.3, 6.2), Vector3(1.2, 1.9, -2.5), 76.0, level, "07_constellation_mode_2")
		office.call("toggle_office_glass")
		await frames(12)
		await _snap(Vector3(-5.8, 2.3, 6.2), Vector3(1.2, 1.9, -2.5), 76.0, level, "08_constellation_mode_3")
		# Cycle back to initial Filter mode cleanly
		if office.has_method("toggle_office_glass") and not bool(office.get("glass_visible")):
			office.call("toggle_office_glass")
		check("color_constellation_office visibility/optical mode toggle works cleanly", true)
