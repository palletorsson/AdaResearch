extends "res://tools/probes/void_game_probe.gd"
## THE INVARIANTS, MEASURED (Palle, 2026-11-03 - "make the invariants measurable"): on floor 13 (Trans_Pre) a printed
## tape is pinned edge to edge across each demo cube, in the cube's own frame. Sampled for four seconds of the cubes'
## own motion: the still, the bobbing (moved) and the spinning (turned) cube keep their tape's length; the pulsing
## (scaled) one does not. The scaled cube is the negative test - if its tape held still too, the tapes would be
## reading nothing.
## Run: python tools/test_invariant_tape.py
const FLOOR := 13
const CUBES := ["still", "rise", "turn", "swell"]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(150)
	var ex: Dictionary = game.building.content.exhibits
	var tapes := {}; var cubes := {}
	for id in CUBES:
		var mount: Node3D = ex.get("%d/tape-%s" % [FLOOR, id])
		var tape: Node = mount.get_node_or_null("Artifact") if mount else null
		if tape and tape.has_method("measure") and not tape.measure().is_empty(): tapes[id] = tape; cubes[id] = tape.get("cube")
	check("four tapes stand on floor 13 and each is laid across its cube (%s)" % ",".join(PackedStringArray(tapes.keys())), tapes.size() == 4)
	if tapes.size() < 4: return finish()
	var named := CUBES.all(func(id): return cubes[id] != null and str(cubes[id].get_parent().name) == id)
	check("each tape found the cube it names (target = still / rise / turn / swell)", named)
	var lo := {}; var hi := {}; var heads := {}; var moved := {}; var turned := {}
	var start_pos := {}; var start_yaw := {}
	for id in CUBES:
		lo[id] = INF; hi[id] = 0.0; heads[id] = {}; start_pos[id] = cubes[id].global_position; start_yaw[id] = cubes[id].global_rotation.y
		moved[id] = 0.0; turned[id] = 0.0
	for step in 60:
		await frames(6)
		for id in CUBES:
			var m: Dictionary = tapes[id].measure()
			if m.is_empty(): continue
			lo[id] = minf(lo[id], m.length); hi[id] = maxf(hi[id], m.length)
			var words: String = m.reading
			var at := words.find("HEADING ")
			if at >= 0: heads[id][words.substr(at + 8).get_slice(" ", 0)] = true
			moved[id] = maxf(moved[id], cubes[id].global_position.distance_to(start_pos[id]))
			turned[id] = maxf(turned[id], absf(angle_difference(cubes[id].global_rotation.y, start_yaw[id])))
	var report := {}
	for id in CUBES:
		report[id] = {"min": lo[id], "max": hi[id], "rest": tapes[id].rest_length, "spread": (hi[id] - lo[id]) / maxf(tapes[id].rest_length, .001),
			"headings": heads[id].keys(), "moved_m": moved[id], "turned_rad": turned[id], "printed": tapes[id].label.text,
			"strip": _strip_state(tapes[id].strip, cubes[id])}
	FileAccess.open(out.path_join("samples.json"), FileAccess.WRITE).store_string(JSON.stringify(report, "  "))
	var s: Dictionary = report.still
	check("still: the tape reads its laid length, %.3f m, and keeps it (spread %.2f%%)" % [s.rest, s.spread * 100], absf(s.rest - .5) < .02 and s.spread < .005)
	var r: Dictionary = report.rise
	check("moved: the cube travels %.2f m and its tape keeps %.3f m (spread %.2f%%)" % [r.moved_m, r.rest, r.spread * 100], r.moved_m > .05 and r.spread < .005)
	var t: Dictionary = report.turn
	check("turned: the cube turns %.2f rad, the tape keeps its length (spread %.2f%%) and its heading changes (%s)" % [t.turned_rad, t.spread * 100, ",".join(PackedStringArray(t.headings))], t.turned_rad > .5 and t.spread < .005 and t.headings.size() >= 2)
	var w: Dictionary = report.swell
	check("scaled: the tape does NOT keep its length - %.3f..%.3f m (spread %.1f%%), the one operation it does not survive" % [w.min, w.max, w.spread * 100], w.spread > .2)
	var rods := game.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.is_visible_in_tree() and m.mesh is CylinderMesh and CUBES.any(func(id): return Vector2(m.global_position.x - cubes[id].global_position.x, m.global_position.z - cubes[id].global_position.z).length() < .45))
	check("no support rod stands under a demo cube or its tape (%d)" % rods.size(), rods.is_empty())
	check("every tape prints what it reads (\"%s\")" % str(report.swell.printed).left(60), CUBES.all(func(id): return str(report[id].printed).contains(" M")))
	if DisplayServer.get_name() != "headless":
		var level: float = float(game.building.spec.levels[FLOOR])
		var c: Vector3 = cubes.swell.global_position
		var camera := Camera3D.new(); game.add_child(camera); camera.fov = 50; camera.environment = game.atmosphere.environment
		camera.global_position = c + Vector3(-.5, 1.75, 1.0); camera.look_at(c + Vector3(0, .5, 0)); camera.make_current()
		game.status.hide(); game.charge_display.hide(); game.notice_time = 0
		if game.desktop_help != null: game.desktop_help.hide()
		await frames(8); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("swell.png"))
		var near := []
		for m in game.find_children("*", "VisualInstance3D", true, false):
			if not (m as Node3D).is_visible_in_tree(): continue
			var bb: AABB = (m as VisualInstance3D).global_transform * (m as VisualInstance3D).get_aabb()
			if bb.get_center().distance_to(c + Vector3(0, .5, 0)) < 1.2:
				near.append({"path": str(m.get_path()).right(110), "class": m.get_class(), "aabb": str(bb), "layers": (m as VisualInstance3D).layers})
		var mid: Vector3 = tapes.swell.label.global_position
		var px := camera.unproject_position(mid)
		var img := root.get_texture().get_image()
		FileAccess.open(out.path_join("debug.json"), FileAccess.WRITE).store_string(JSON.stringify({"near": near, "label_at": str(mid), "pixel": str(px),
			"colour": str(img.get_pixelv(Vector2i(px)) if Rect2i(Vector2i.ZERO, img.get_size()).has_point(Vector2i(px)) else "off"), "supports": game.building.content.find_children("*Support*", "", true, false).map(func(x): return str(x.get_path()).right(90)), "rods_near": game.find_children("*", "MeshInstance3D", true, false).filter(func(m): return m.is_visible_in_tree() and m.mesh is CylinderMesh and Vector2(m.global_position.x - c.x, m.global_position.z - c.z).length() < .5).map(func(m): return str(m.get_path()).right(110) + " " + str(m.global_position)), "camera": str(camera.global_position), "cull_mask": camera.cull_mask, "root": str(c)}, "  "))
		c = cubes.turn.global_position
		camera.global_position = c + Vector3(-.5, 1.75, 1.0); camera.look_at(c + Vector3(0, .5, 0))
		await frames(8); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("turn.png"))
		c = cubes.still.global_position
		camera.global_position = c + Vector3(-.5, 1.75, 1.0); camera.look_at(c + Vector3(0, .5, 0))
		await frames(8); await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(out.path_join("still.png"))
	finish()

func _strip_state(strip: MeshInstance3D, cube: Node3D) -> Dictionary:
	var box: AABB = strip.global_transform * strip.get_aabb() if strip.mesh else AABB()
	var body: MeshInstance3D = cube.find_child("CubeBaseMesh", true, false)
	var top: AABB = body.global_transform * body.get_aabb() if body else AABB()
	var mat: Material = strip.material_override
	return {"visible_in_tree": strip.is_visible_in_tree(), "mesh": strip.mesh != null, "strip_aabb": str(box), "cube_aabb": str(top),
		"material": str(mat), "texture": str(mat.get("albedo_texture")) if mat else "", "cull": int(mat.get("cull_mode")) if mat else -1,
		"layers": strip.layers, "top_level": strip.top_level, "faces": strip.mesh.get_faces().size() if strip.mesh else 0,
		"face_normal": str(strip.global_basis * strip.mesh.surface_get_arrays(0)[Mesh.ARRAY_NORMAL][0]) if strip.mesh else ""}

func finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[invariant_tape] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)
