extends "res://tools/probes/void_game_probe.gd"
const VoidFloor = preload("res://tools/probes/void_floor.gd")

## Floor 28 (Color_Context_Placed) before/after verification for pillar-covering
## forms sourced from color-stacks-gallery.
const SHOTS := [
	[Vector3(0.0, 1.7, 8.2), Vector3(0.0, 2.5, -7.0), 74.0, "01_central_aisle"],
	[Vector3(0.0, 1.7, -0.8), Vector3(0.0, 2.6, -7.0), 76.0, "02_north_stations_pillars"],
	[Vector3(-12.2, 1.7, 4.2), Vector3(-17.8, 2.6, -5.5), 74.0, "03_west_wing"],
	[Vector3(12.2, 1.7, -3.5), Vector3(17.8, 2.6, 5.5), 74.0, "04_east_wing"],
	[Vector3(-9.0, 1.7, 2.2), Vector3(2.0, 2.6, 7.0), 74.0, "05_south_row_pair"],
	[Vector3(-1.4, 1.7, -3.4), Vector3(-5.0, 2.8, -7.0), 74.0, "06_pillar_closeup"],
	[Vector3(-12.5, 1.7, 2.0), Vector3(-18.0, 2.6, 7.0), 74.0, "07_west_south_corner"],
	[Vector3(16.5, 1.7, -2.2), Vector3(17.0, 2.7, -7.0), 76.0, "08_east_north_wing"],
	[Vector3(16.2, 1.7, 2.4), Vector3(17.0, 2.7, 7.0), 76.0, "09_east_south_wing"],
	[Vector3(-7.0, 1.7, -3.8), Vector3(-5.0, 2.8, -7.0), 76.0, "10_pillar_closeup_open"],
	[Vector3(-19.5, 1.7, -8.5), Vector3(12.0, 2.7, -6.7), 74.0, "11_north_colonnade"],
	[Vector3(-19.5, 1.7, 8.5), Vector3(12.0, 2.7, 6.7), 74.0, "12_south_colonnade"],
	[Vector3(0.5, 1.7, -6.1), Vector3(-14.0, 2.7, -7.0), 74.0, "13_north_row_walkway"],
]

func run() -> void:
	var expect_covers := false
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):
			out = arg.trim_prefix("--out=")
		if arg == "--expect-covers":
			expect_covers = true
	var at: Dictionary = VoidFloor.table()
	var floor_idx: int = int(at.get("Color_Context_Placed", 28))
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
	await frames(200)
	var level: float = float(game.building.spec.levels[floor_idx])
	var floor_root: Node3D = game.building.content.roots.get(floor_idx, null)
	check("Color_Context_Placed floor loaded", floor_root != null)
	if expect_covers and floor_root != null:
		_verify_covers(floor_root, level)
	game.body.visible = false
	game.status.hide()
	game.charge_display.hide()
	game.notice_time = 0
	if game.desktop_help != null:
		game.desktop_help.hide()
	for s in SHOTS:
		var camera := Camera3D.new()
		game.add_child(camera)
		camera.fov = float(s[2])
		camera.environment = game.atmosphere.environment
		camera.global_position = (s[0] as Vector3) + Vector3(0, level, 0)
		camera.look_at((s[1] as Vector3) + Vector3(0, level, 0))
		camera.make_current()
		await frames(8)
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("%s.png" % s[3]))
		camera.queue_free()
		FileAccess.open(out.path_join("progress.json"), FileAccess.WRITE).store_string(str(s[3]))
		check("shot:" + str(s[3]), true)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(
		JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  ")
	)
	quit(0 if failed.is_empty() else 1)

func _verify_covers(floor_root: Node3D, level: float) -> void:
	var covers: Array[Dictionary] = []
	var exhibits: Array[Dictionary] = []
	for child in floor_root.get_children():
		if not (child is Node3D):
			continue
		var art := child.get_node_or_null("Artifact")
		if art == null:
			continue
		var aabb := _world_aabb(art)
		if aabb.size == Vector3.ZERO:
			continue
		var local_box := AABB(aabb.position - Vector3(0, level, 0), aabb.size)
		if str(child.name).begins_with("pillar-cover-"):
			covers.append({"id": str(child.name), "pos": child.position, "aabb": local_box})
		else:
			exhibits.append({"id": str(child.name), "pos": child.position, "aabb": local_box})
	check("all 12 structural pillars covered", covers.size() == 12)
	var all_enclose := true
	var all_within_slab := true
	var overlaps: Array[String] = []
	var report := {}
	for c in covers:
		var b: AABB = c.aabb
		var p: Vector3 = c.pos
		var encloses := b.position.x <= p.x - 0.48 and b.end.x >= p.x + 0.48 \
			and b.position.z <= p.z - 0.48 and b.end.z >= p.z + 0.48 \
			and b.position.y <= 0.01 and b.end.y >= 5.45
		if not encloses:
			all_enclose = false
		var in_slab := b.position.x >= -21.0 and b.end.x <= 21.0 and b.position.z >= -9.0 and b.end.z <= 9.0
		if not in_slab:
			all_within_slab = false
		for e in exhibits:
			var eb: AABB = e.aabb
			if b.intersects(eb):
				overlaps.append("%s <-> %s" % [c.id, e.id])
		report[c.id] = {
			"min": [snappedf(b.position.x, 0.001), snappedf(b.position.y, 0.001), snappedf(b.position.z, 0.001)],
			"max": [snappedf(b.end.x, 0.001), snappedf(b.end.y, 0.001), snappedf(b.end.z, 0.001)],
			"encloses_pillar": encloses,
			"within_slab": in_slab,
		}
	FileAccess.open(out.path_join("cover-bounds.json"), FileAccess.WRITE).store_string(
		JSON.stringify({"covers": report, "overlaps": overlaps}, "  ")
	)
	check("every cover encloses 0.9m pillar + guards to 5.45m", all_enclose)
	check("every cover fits within 42x18 slab", all_within_slab)
	check("zero AABB overlap with existing 23 exhibits", overlaps.is_empty())

func _world_aabb(node: Node3D) -> AABB:
	var total := AABB()
	var first := true
	for mi in node.find_children("*", "MeshInstance3D", true, false):
		if not mi.visible:
			continue
		var box: AABB = mi.global_transform * mi.get_aabb()
		total = box if first else total.merge(box)
		first = false
	return total
