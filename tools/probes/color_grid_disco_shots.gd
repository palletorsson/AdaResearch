extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Floor 33 (Color_Grid_Pallet) before/after + live disco stage, music, disco ball,
## and Care Unit Model B dance-mirror verification.
const SHOTS := [
	[Vector3(0.0, 2.3, 8.2), Vector3(0.0, 1.8, -2.5), 78.0, "01_disco_stage_front"],
	[Vector3(-6.2, 2.4, 6.8), Vector3(0.8, 1.9, -2.0), 76.0, "02_stage_angle_sw"],
	[Vector3(6.2, 2.4, 6.8), Vector3(-0.8, 1.9, -2.0), 76.0, "03_stage_angle_se"],
	[Vector3(-4.5, 1.5, 5.2), Vector3(0.0, 4.1, -0.5), 76.0, "04_ceiling_disco_ball"],
	[Vector3(-1.9, 1.85, 2.8), Vector3(0.0, 1.55, -5.2), 74.0, "05_mirror_dance_floor"],
	[Vector3(4.8, 2.8, -5.8), Vector3(-0.5, 1.2, 2.0), 76.0, "06_stage_overview_north"],
]

func run() -> void:
	var expect_new := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg == "--expect-new":
			expect_new = true
	var at: Dictionary = VoidFloor.table()
	var floor_idx: int = int(at.get("Color_Grid_Pallet", 33))
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
	check("Color_Grid_Pallet floor loaded", floor_root != null)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()

	if expect_new and floor_root != null:
		await _verify_disco_extravaganza(floor_root, level)

	for s in SHOTS:
		await _snap(s[0], s[1], float(s[2]), level, str(s[3]))

	if expect_new and floor_root != null:
		await _capture_care_unit_mirror_dance(floor_root, level)

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
	await frames(12)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join("%s.png" % label))
	camera.queue_free()
	FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(label)
	check("shot:" + label, true)

func _verify_disco_extravaganza(floor_root: Node3D, level: float) -> void:
	var mount := floor_root.get_node_or_null("f2_gridcolorizer_6_5")
	check("gridcolorizer disco mount exists", mount != null)
	if mount == null:
		return
	var disco := mount.find_child("DiscoExtravaganza", true, false)
	check("DiscoExtravaganza module attached", disco != null)
	if disco == null:
		return
	var ball := disco.find_child("GiantDiscoBall", true, false) as Node3D
	check("giant ceiling disco ball built", ball != null)
	if ball != null:
		var ball_aabb := AABB()
		var first := true
		for mi in ball.find_children("*", "MeshInstance3D", true, false):
			if mi.mesh == null:
				continue
			var b: AABB = mi.global_transform * mi.get_aabb()
			ball_aabb = b if first else ball_aabb.merge(b)
			first = false
		check("disco ball is super large (diameter >= 2.0m)", ball_aabb.size.x >= 2.0)
		print("[void] GiantDiscoBall diameter: %.2f m at y=%.2f" % [ball_aabb.size.x, ball.global_position.y - level])

	var mirror := disco.find_child("DiscoDanceMirror", true, false) as Node3D
	check("full-wall DiscoDanceMirror built", mirror != null)
	var mirror_vp := disco.find_child("MirrorViewport", true, false) as SubViewport
	check("mirror has live SubViewport reflection", mirror_vp != null)

	var music := disco.find_child("HardDiscoMusic", true, false) as AudioStreamPlayer
	check("hard disco music synth attached and loaded", music != null and music.stream != null)

	# Verify stage is raised and walkable (physics raycast onto dance floor centre)
	var space := floor_root.get_world_3d().direct_space_state
	var q := PhysicsRayQueryParameters3D.create(
		Vector3(0.0, level + 2.5, -0.5),
		Vector3(0.0, level - 0.5, -0.5),
		1
	)
	var hit := space.intersect_ray(q)
	var stage_top: float = (hit.position.y - level) if not hit.is_empty() else -1.0
	check("disco stage is raised above floor slab (>= 0.30m)", stage_top >= 0.30)
	print("[void] Disco stage surface height: %.3f m" % stage_top)

	# Verify tiles actively blink / animate over time!
	var grid_mm := mount.find_child("GridMultiMesh", true, false) as MultiMeshInstance3D
	check("GridMultiMesh exists", grid_mm != null and grid_mm.multimesh != null)
	if grid_mm != null and grid_mm.multimesh != null and grid_mm.multimesh.instance_count > 4:
		var c0 := grid_mm.multimesh.get_instance_color(0)
		var c1 := grid_mm.multimesh.get_instance_color(3)
		await frames(55)
		var c0_after := grid_mm.multimesh.get_instance_color(0)
		var c1_after := grid_mm.multimesh.get_instance_color(3)
		check("disco floor tiles actively blink/pulse", c0 != c0_after or c1 != c1_after)

func _capture_care_unit_mirror_dance(floor_root: Node3D, level: float) -> void:
	var mount := floor_root.get_node_or_null("f2_gridcolorizer_6_5")
	if mount == null:
		return
	var disco := mount.find_child("DiscoExtravaganza", true, false)
	# Stand Care Unit Model B right in front of the full-wall Disco Dance Mirror!
	game.body.visible = true
	game.place_player(Vector3(-0.25, level + 0.55, -3.15))
	game.body.rotation_degrees.y = 0.0  # facing -Z (toward North mirror!)
	if disco != null and disco.has_method("set_dance_move"):
		disco.call("set_dance_move", "fever")
	await frames(45)
	var care_bodies := get_nodes_in_group("void_care_bodies")
	var dancing := false
	for cb in care_bodies:
		if cb.has_method("get_dance_mode") and str(cb.call("get_dance_mode")) == "fever":
			dancing = true
	check("Care Unit Model B enters disco dance mode on stage", dancing)
	await _snap(Vector3(-1.75, 1.85, -1.10), Vector3(0.20, 1.75, -5.75), 72.0, level, "07_care_unit_mirror_dance_fever")

	if disco != null and disco.has_method("set_dance_move"):
		disco.call("set_dance_move", "hustle")
	await frames(45)
	await _snap(Vector3(1.65, 1.85, -1.15), Vector3(-0.25, 1.75, -5.75), 72.0, level, "08_care_unit_mirror_dance_hustle")
