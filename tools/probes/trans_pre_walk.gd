extends "res://tools/probes/void_game_probe.gd"
## TRANS_PRE (Void floor 13) AS REBUILT (Palle, 2026-11-03), in the actual tower with the desktop walker:
## four stand-alone one-cell islands (a cube between two wedges) for the still, translate, rotate and scale cubes, each
## with its demo cube over it and its marker beside it; then two cubes and a wedge, three cubes and a wedge, and two
## parallel rows of four cubes with one wedge; step boxes on the later cubes - health, and random solids that fall onto
## their box. Walks the floor's own route from the arrival to the next-floor exit, jumping to the parallel row.
## Layout: python tools/trans_pre_layout.py. Run: python tools/test_trans_pre.py
const FLOOR := 13
const ZI := 0.5   # the islands' cell row (tools/trans_pre_layout.py ZI)
var level := 0.0

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(60)
	level = float(game.building.spec.levels[FLOOR])
	await structure()
	await walk()
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[trans_pre] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func g(x: float, y: float, z: float) -> Vector3: return Vector3(x, level + y, z)

func surface(x: float, z: float) -> float:
	var hit := ray(g(x, 3.0, z), g(x, -0.5, z))
	return (hit.position.y - level) if not hit.is_empty() else -99.0

func structure() -> void:
	var data: Dictionary = game.building.content.data.floors[FLOOR]
	check("floor 13 is Trans_Pre", data.map == "Trans_Pre")
	var ok_islands := true; var notes: Array = []
	for x in [-5.5, -1.5, 1.5, 5.5]:   # on the cell grid: the cubes at z 0.5, the wedges' runs ending on whole metres
		var top := surface(x, ZI); var ramp_s := surface(x, ZI + 1.5); var ramp_n := surface(x, ZI - 1.5); var foot := surface(x, ZI + 2.6)
		var gap_w := surface(x - 1.0, ZI)
		notes.append("x %.2f: top %.2f, ramps %.2f/%.2f, foot %.2f, beside %.2f" % [x, top, ramp_s, ramp_n, foot, gap_w])
		if not (absf(top - 1.0) < .03 and absf(ramp_s - .5) < .08 and absf(ramp_n - .5) < .08 and absf(foot) < .05 and absf(gap_w) < .05): ok_islands = false
	check("four stand-alone one-cell islands, a cube between two wedges (%s)" % "; ".join(notes), ok_islands)
	var ex: Dictionary = game.building.content.exhibits
	# no support rod stands under a pick-up cube (rooms.json config "support": false), while a raised marker keeps its own
	var cubes: Array = ["still", "rise", "turn", "swell", "pickup-1", "pickup-2", "pickup-3", "pickup-4"].map(func(id): return ex.get("13/" + id)).filter(func(m): return m != null)
	var rods: Array = game.building.content.find_children("ArtifactSupport*", "MeshInstance3D", true, false).filter(func(r): return absf(r.global_position.y - level) < 3.0 and absf(r.global_position.x) < 21.5)
	var under := 0
	for r in rods:
		for m in cubes:
			if Vector2(r.global_position.x - m.global_position.x, r.global_position.z - m.global_position.z).length() < .5: under += 1
	var marker: Node3D = ex.get("13/translation-marker")
	var marker_rod := rods.any(func(r): return marker != null and Vector2(r.global_position.x - marker.global_position.x, r.global_position.z - marker.global_position.z).length() < .5)
	check("no support rod under the %d pick-up cubes (%d rods on the floor, %d under a cube; the translation marker keeps its rod: %s)" % [cubes.size(), rods.size(), under, str(marker_rod)], cubes.size() == 8 and under == 0 and marker_rod)
	var demos_ok := true
	for pair in [["still", -5.5], ["rise", -1.5], ["turn", 1.5], ["swell", 5.5]]:
		var m: Node3D = ex.get("13/" + pair[0])
		if m == null or Vector2(m.global_position.x - pair[1], m.global_position.z - ZI).length() > .05: demos_ok = false
	check("the still, translate, rotate and scale cubes stand over their islands", demos_ok)
	check("the three markers are kept, beside their islands", ["translation-marker", "rotation-marker", "scale-marker"].all(func(id): return ex.has("13/" + id)))
	var rows_ok := true; var rnotes: Array = []
	for row in [[5.5, [16.5, 17.5]], [2.5, [16.5, 17.5, 18.5]], [-0.5, [16.5, 17.5, 18.5, 19.5]], [-2.5, [16.5, 17.5, 18.5, 19.5]]]:
		var tops: Array = row[1].map(func(x): return snappedf(surface(x, row[0]), .01))
		var after := surface(float(row[1].back()) + 1.0, row[0])
		rnotes.append("z %.0f: %s" % [row[0], str(tops)])
		if not tops.all(func(t): return absf(t - 1.0) < .04) or absf(after) > .05: rows_ok = false
	check("the configurations: two cubes, three cubes, two parallel rows of four (%s)" % "; ".join(rnotes), rows_ok)
	check("the parallel rows stand apart: the floor between them (%.2f)" % surface(18.0, -1.5), absf(surface(18.0, -1.5)) < .05)
	check("each configuration but the parallel row has its wedge (%.2f, %.2f, %.2f; the parallel row's foot %.2f)" % [surface(15.0, 5.5), surface(15.0, 2.5), surface(15.0, -0.5), surface(15.0, -2.5)],
		[5.5, 2.5, -0.5].all(func(z): return absf(surface(15.0, z) - .5) < .08) and absf(surface(15.0, -2.5)) < .05)

func walk() -> void:
	var route: Array = game.building.content.data.floors[FLOOR].route
	game.place_player(g(route[0].position[0], .06, route[0].position[1])); await frames(20)
	var ok := true; var stuck := ""
	for i in range(1, route.size()):
		var p: Array = route[i].position
		var jump: bool = str(route[i].label).begins_with("jump")
		# aim at the standing surface under the waypoint (a cube top is 1 m up); the ray starts under the demo cubes
		var under := ray(g(p[0], 1.6, p[1]), g(p[0], -0.5, p[1]))
		var stand: float = (under.position.y - level) if not under.is_empty() else 0.0
		var reached := await move_to(g(p[0], stand, p[1]), jump)
		if not reached:
			ok = false; stuck = "%s (%s) at %s" % [route[i].label, str(p), str(game.body.global_position - Vector3(0, level, 0))]
			print("TRANS_PRE_WALK stuck: ", stuck)
			break
		print("TRANS_PRE_WALK reached ", route[i].label, " at ", game.body.global_position - Vector3(0, level, 0))
	check("the walk follows the floor's route from the arrival over every island and configuration to the exit%s" % (": stuck before " + stuck if not ok else ""), ok)
	var ex: Dictionary = game.building.content.exhibits
	var opened: Array = []
	for id in ["first-health", "found-solid", "found-solid-2", "last-health"]:
		var m: Node3D = ex.get("13/" + id)
		var box = m.get_node_or_null("Artifact") if m != null else null
		if box == null and m != null: box = m.find_children("*", "Node3D", false, false)[0] if m.get_child_count() > 0 else null
		opened.append("%s %s" % [id, str(box.opened) if box != null and "opened" in box else "?"])
	print("TRANS_PRE_BOXES ", opened)
	# the walk crosses first-health (three cubes) and found-solid (first parallel row): both open; the solid fell
	var solid_node: Node3D = ex.get("13/found-solid")
	var solid = solid_node.get_node_or_null("Artifact") if solid_node != null else null
	if solid != null and solid.opened and solid.reward != null:
		await frames(150)
		var rest: float = solid.reward.global_position.y - solid.global_position.y
		check("stepping on the falling-solid box: a %s fell from 2.2 m onto the box (resting %.2f m over its foot)" % [solid.selected_kind, rest], rest > .95 and rest < 1.4)
	else:
		check("the walk over the first parallel row opened the falling-solid box (%s)" % ", ".join(opened), false)
	if DisplayServer.get_name() != "headless":
		await shot("islands", g(0, 4.9, 8.4), g(0, .4, -1.0))
		await shot("configurations", g(10.5, 4.9, 7.8), g(17.5, .4, 0.5))

func shot(id: String, at: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 70; camera.environment = game.atmosphere.environment
	camera.global_position = at; camera.look_at(target); camera.make_current()
	game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(id + ".png"))
	camera.free(); game.camera.make_current()
