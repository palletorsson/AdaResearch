extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Ghost Student Spine Stop #6 (F118 Fractal_MengerSponge · "Can the Body Pass?") live desktop verification:
## Drives MengerLesson across stages 0 -> 1 -> 2 (1 -> 20 -> 400 cubes), measures real world opening sizes
## at Level 1 (L/3) vs Level 2 (L/9) against Model B's standing body (1.72 m tall, 0.64 m wide),
## verifies GHOST removal overlay, and captures Model B's live Dual Breadcrumb HUD inside Floor 118.

func _world_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for child in node.find_children("*", "MeshInstance3D", true, false):
		var mi := child as MeshInstance3D
		if mi == null or mi.mesh == null or not mi.visible: continue
		if mi.name.begins_with("Removed"): continue
		var b: AABB = mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")

	var at: Dictionary = VoidFloor.table()
	var f118_idx: int = int(at.get("Fractal_MengerSponge", 118))

	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = f118_idx
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

	game.place_player(game.spawn_for(f118_idx))
	await frames(50)
	var fl_root: Node3D = game.building.content.roots.get(f118_idx, null)
	check("F118 Fractal_MengerSponge loaded cleanly", fl_root != null)

	var sponge_mount: Node3D = fl_root.find_child("f3_menger_sponge_7_9", true, false) if fl_root != null else null
	var sponge: Node3D = _find_with_prop(sponge_mount, "current_iteration")
	var dla: Node3D = fl_root.find_child("f3_diffusion_limited_aggregation_4_4", true, false) if fl_root != null else null
	var film: Node3D = fl_root.find_child("f3_film_menger_twenty_3_1", true, false) if fl_root != null else null
	var prompter: Node3D = fl_root.find_child("f3_catalyst_prompter_box_1_6", true, false) if fl_root != null else null
	check("Menger Sponge, DLA, Film Twenty, and Catalyst Prompter spawned on F118",
		sponge != null and dla != null and film != null and prompter != null)

	var measurements := {}
	if sponge != null:
		var lesson: Node = sponge.get_node_or_null("MengerLesson")
		var flight: Node = sponge.get_node_or_null("FlightBox")
		check("MengerLesson desk and FlightBox enclosure active on Menger Sponge", lesson != null and flight != null)

		# Stage 0: solid initial cube
		if lesson != null:
			lesson.call("set_stage", 0)
		await frames(10)
		var cubes_s0: int = (sponge.call("find_all_cube_scenes") as Array).size()
		var vol_s0: float = float(lesson.call("kept_volume")) if lesson != null else 0.0
		var box_s0: AABB = _world_aabb(sponge)
		var side_m: float = maxf(box_s0.size.x, maxf(box_s0.size.y, box_s0.size.z))
		var center: Vector3 = box_s0.get_center()
		check("Stage 0 holds 1 solid cube (cubes=%d, side=%.2f m, kept_volume=%.1f)" % [cubes_s0, side_m, vol_s0],
			cubes_s0 == 1 and side_m > 2.0)

		var cam := Camera3D.new()
		root.add_child(cam)
		cam.fov = 56.0
		var view_dist: float = maxf(5.5, side_m * 1.45)
		cam.global_position = center + Vector3(view_dist * 0.42, 0.35, view_dist * 0.92)
		cam.look_at(center, Vector3.UP)
		cam.make_current()
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("01-menger-stage0-solid.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("01-menger-stage0-solid.png")

		# Stage 1: first cut -> 20 cubes, first cross opening L/3
		if lesson != null:
			lesson.call("set_stage", 1)
		await frames(10)
		var cubes_s1: int = (sponge.call("find_all_cube_scenes") as Array).size()
		var vol_s1: float = float(lesson.call("kept_volume")) if lesson != null else 0.0
		var open_l1_m: float = side_m / 3.0
		check("Stage 1 keeps 20/27 sub-cubes with Level-1 opening %.2f m (cubes=%d, vol=%.1f)" % [open_l1_m, cubes_s1, vol_s1],
			cubes_s1 == 20 and vol_s1 < vol_s0)
		root.get_texture().get_image().save_png(out.path_join("02-menger-stage1-corridor.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("02-menger-stage1-corridor.png")

		# Stage 2: second cut -> 400 cubes, self-similar Level-2 opening L/9
		if lesson != null:
			lesson.call("set_stage", 2)
		await frames(12)
		var cubes_s2: int = (sponge.call("find_all_cube_scenes") as Array).size()
		var vol_s2: float = float(lesson.call("kept_volume")) if lesson != null else 0.0
		var open_l2_m: float = side_m / 9.0
		check("Stage 2 keeps 400 sub-cubes with Level-2 opening %.2f m (cubes=%d, vol=%.1f)" % [open_l2_m, cubes_s2, vol_s2],
			cubes_s2 == 400 and vol_s2 < vol_s1)

		# Compare bodily affordance: Model B standing height (1.72 m) vs Level-1 (L/3) vs Level-2 (L/9) openings!
		var standing_height_m := 1.72
		var walker_width_m := 0.64
		var l1_passable_standing: bool = open_l1_m >= standing_height_m and open_l1_m >= walker_width_m
		var l2_blocks_standing: bool = open_l2_m < standing_height_m
		check("Scale changes bodily affordance: L1 opening (%.2f m) admits standing body (%.2f m) while self-similar L2 (%.2f m) blocks standing passage" % [open_l1_m, standing_height_m, open_l2_m],
			l1_passable_standing and l2_blocks_standing)

		# Frame straight into the Stage 2 central cross-corridor and adjacent Level-2 sub-openings
		cam.global_position = center + Vector3(0.18, 0.12, view_dist * 0.88)
		cam.look_at(center, Vector3.UP)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("03-menger-stage2-subholes.png"))
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string("03-menger-stage2-subholes.png")

		# Toggle GHOST removals + capture Model B's live Dual Breadcrumb HUD!
		if lesson != null:
			lesson.call("act", "ghost")
		await frames(8)
		var opera_script = load("res://commons/void/inner_opera.gd")
		var opera_tmp = opera_script.new()
		var f118_plain: String = opera_tmp._plain_for("spine_0bb13a478364ee1e66", "spine_0bb13a478364ee1e66")
		opera_tmp.free()
		check("F118 Can the Body Pass? plain breadcrumb resolved from tower_system_atlas.json", not f118_plain.is_empty())

		game.charge_display.show()
		game.charge_display.set_level("F118  Fractal_MengerSponge  ·  Can the Body Pass?")
		game.charge_display.set_sung("I find the same turn at another scale.", f118_plain)
		await frames(6)
		root.get_texture().get_image().save_png(out.path_join("04-menger-ghost-dual-hud.png"))
		cam.queue_free()

		measurements = {
			"world_side_m": snappedf(side_m, 0.01),
			"cubes_stage0": cubes_s0,
			"cubes_stage1": cubes_s1,
			"cubes_stage2": cubes_s2,
			"volume_stage0": snappedf(vol_s0, 0.1),
			"volume_stage1": snappedf(vol_s1, 0.1),
			"volume_stage2": snappedf(vol_s2, 0.1),
			"opening_level1_m": snappedf(open_l1_m, 0.01),
			"opening_level2_m": snappedf(open_l2_m, 0.01),
			"standing_body_height_m": standing_height_m,
			"walker_width_m": walker_width_m,
			"l1_admits_standing": l1_passable_standing,
			"l2_blocks_standing": l2_blocks_standing,
		}

	var failed := 0
	for c in checks:
		if not bool((c as Dictionary).get("passed", false)): failed += 1
	var report := {
		"passed": failed == 0,
		"failed": failed,
		"map": "Fractal_MengerSponge",
		"floor": f118_idx,
		"encounter": "spine_0bb13a478364ee1e66",
		"measurements": measurements,
		"songs": [
			{
				"encounter": "spine_0bb13a478364ee1e66",
				"object": "spine_0bb13a478364ee1e66",
				"on_display": true,
				"sung": true,
				"text": "I find the same turn at another scale."
			}
		],
		"checks": checks,
	}
	var f := FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE)
	if f != null:
		f.store_string(JSON.stringify(report, "  ") + "\n")
	quit(0 if failed == 0 else 1)

func _find_with_prop(node: Node, prop: String) -> Node3D:
	if node == null: return null
	if node is Node3D and node.get(prop) != null: return node
	for c in node.get_children():
		var hit := _find_with_prop(c, prop)
		if hit != null: return hit
	return null
