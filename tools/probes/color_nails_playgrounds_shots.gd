extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Floor 30 (Color_Nails) before/after capture for the Shaft A & Shaft B
## Colour Balls playgrounds, plus reference shots of Color_Rainbow's Colour Plate.
const NAILS_SHOTS := [
	[Vector3(-5.6, 2.8, 5.2), Vector3(-10.0, 0.9, 0.0), 74.0, "01_shaft_a_south_east"],
	[Vector3(-17.5, 2.4, 5.8), Vector3(-10.0, 1.2, 0.0), 74.0, "02_shaft_a_west_bay"],
	[Vector3(5.6, 2.8, 5.2), Vector3(10.0, 0.9, 0.0), 74.0, "03_shaft_b_south_west"],
	[Vector3(17.5, 2.4, 5.8), Vector3(10.0, 1.2, 0.0), 74.0, "04_shaft_b_east_bay"],
	[Vector3(0.0, 2.5, 8.3), Vector3(0.0, 1.8, -4.0), 82.0, "05_wide_hall_from_south"],
	[Vector3(-10.0, 1.7, 5.6), Vector3(-10.0, 1.1, 0.0), 74.0, "06_shaft_a_entry"],
	[Vector3(10.0, 1.7, 5.6), Vector3(10.0, 1.1, 0.0), 74.0, "07_shaft_b_entry"],
	[Vector3(-10.0, 2.6, 3.6), Vector3(-10.0, 0.5, -1.0), 76.0, "08_shaft_a_rim_inward"],
	[Vector3(10.0, 2.6, 3.6), Vector3(10.0, 0.5, -1.0), 76.0, "09_shaft_b_rim_inward"],
]

const RAINBOW_REF_SHOTS := [
	[Vector3(-6.5, 2.6, 7.2), Vector3(0.0, 0.8, 0.0), 76.0, "ref_rainbow_colour_plate"],
]

func run() -> void:
	var expect_playgrounds := false
	var include_ref := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg == "--expect-playgrounds":
			expect_playgrounds = true
		if arg == "--include-ref":
			include_ref = true
	var at: Dictionary = VoidFloor.table()
	var nails_idx: int = int(at.get("Color_Nails", 30))
	var rainbow_idx: int = int(at.get("Color_Rainbow", 31))
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = nails_idx
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
	game.place_player(game.spawn_for(nails_idx))
	# Let colorballs spawn (one ball per process frame) and bounce into place.
	await frames(220)
	var nails_level: float = float(game.building.spec.levels[nails_idx])
	var floor_root: Node3D = game.building.content.roots.get(nails_idx, null)
	check("Color_Nails floor loaded", floor_root != null)
	if expect_playgrounds and floor_root != null:
		_verify_playgrounds(floor_root, nails_level)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()
	for s in NAILS_SHOTS:
		await _snap(s[0], s[1], float(s[2]), nails_level, str(s[3]))
	if include_ref:
		game.place_player(game.spawn_for(rainbow_idx))
		await frames(160)
		var rainbow_level: float = float(game.building.spec.levels[rainbow_idx])
		game.body.visible = false
		for s in RAINBOW_REF_SHOTS:
			await _snap(s[0], s[1], float(s[2]), rainbow_level, str(s[3]))
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

func _verify_playgrounds(floor_root: Node3D, level: float) -> void:
	var ball_nodes: Array[Node3D] = []
	var plate_nodes: Array[Node3D] = []
	for child in floor_root.get_children():
		if not (child is Node3D):
			continue
		var art := child.get_node_or_null("Artifact")
		if art == null:
			continue
		if str(child.name).contains("colorballs"):
			ball_nodes.append(art)
		if str(child.name).contains("balls-playground"):
			plate_nodes.append(art)
	check("two colorballs studies installed (Shaft A and Shaft B)", ball_nodes.size() == 2)
	check("two playground_spec_hall decks/plates installed over Shaft A and Shaft B", plate_nodes.size() == 2)
	var specs_ok := true
	for p in plate_nodes:
		if p.get("spec_errors") is Array and not p.spec_errors.is_empty():
			specs_ok = false
			print("SPEC_ERRORS ", p.get_parent().name, " ", p.spec_errors)
	check("both playground specs compiled with zero errors", specs_ok)
	var balls_ok := true
	var report := []
	for b in ball_nodes:
		var count: int = b.ball_bodies.size()
		var inside := 0
		for rb in b.ball_bodies:
			if is_instance_valid(rb):
				var loc: Vector3 = b.to_local(rb.global_position)
				if absf(loc.x) <= 3.2 and absf(loc.z) <= 3.2 and loc.y >= -0.5 and loc.y <= 5.0:
					inside += 1
		var ok := count >= 40 and inside >= int(count * 0.9)
		if not ok:
			balls_ok = false
		report.append({
			"id": str(b.get_parent().name),
			"pos": [b.get_parent().position.x, b.get_parent().position.z],
			"ball_count": count,
			"inside_bounds": inside,
			"ball_radius": b._ball_radius,
		})
	check("enlarged colorballs spawned and stay contained on both shafts", balls_ok)
	# Verify walkable floor collision directly over both shaft centres (-10, 0) and (10, 0).
	var space := game.get_world_3d().direct_space_state
	var walkable_ok := true
	for sx in [-10.0, 10.0]:
		for pt in [Vector2(0, 0), Vector2(-1.8, 0), Vector2(1.8, 0), Vector2(0, -1.8), Vector2(0, 1.8)]:
			var from := Vector3(sx + pt.x, level + 2.0, pt.y)
			var to := Vector3(sx + pt.x, level - 0.5, pt.y)
			var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(from, to))
			if hit.is_empty() or hit.position.y < level - 0.2:
				walkable_ok = false
				print("UNSUPPORTED ", sx + pt.x, " ", pt.y, " hit=", hit)
	check("both 6x6 shaft centres have walkable floor support", walkable_ok)
	FileAccess.open(out.path_join("playgrounds-report.json"), FileAccess.WRITE).store_string(
		JSON.stringify({"balls": report}, "  ")
	)
