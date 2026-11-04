extends "res://tools/probes/void_game_probe.gd"
## PARALLEL BEAMS ON FLOOR 03, POINT LINES (Palle, 2026-11-03: "in point line add three black beams from floor to ceiling
## that are parallel and rotate 15 degrees"), in the actual tower with the desktop walker.
##   --survey   before placing: scans floor 03 for spots where the three beams' footprint (with a walking margin)
##              meets no body of the hall, has real floor under every foot and crosses none of the floor's walked
##              paths; prints and writes survey.json.
##   (default)  after placing: the beams stand from the floor into the ceiling, parallel, leaning 15 degrees, black
##              and solid; the floor's own walk (void_game_probe's lines_checks path) still passes; a visitor walks
##              through the gap between two beams; photographs.
## Run: python tools/test_point_lines_beams.py [--survey]
const FLOOR := 3
const LEVEL := -18.0          # floor 03's level (commons/void/layout.json)
const CEILING := -12.36       # the slab above: level -12 less its 0.36 m
## The floor's walked paths (void_game_probe.lines_checks) and its route (rooms.json floor 03): the beams keep off them.
const PATHS := [[Vector2(0.5, 7.5), Vector2(0.5, 4.5)], [Vector2(0.5, 4.5), Vector2(-3.7, 4.1)], [Vector2(-3.7, 4.1), Vector2(-16.5, 4.2)],
	[Vector2(-16.5, 4.2), Vector2(-19, 4.2)], [Vector2(-19, 4.2), Vector2(-18, -4.3)], [Vector2(-18, -4.3), Vector2(-6, -4.3)]]

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	await start(false)
	game.place_player(game.spawn_for(FLOOR))
	await frames(30)
	if "--survey" in OS.get_cmdline_user_args(): await survey()
	else: await verify()
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[beams] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

## The main tower opened at floor 03, as principal_places.gd opens its hall (the staged runtime has no staging_type_probe).
func start(use_xr: bool) -> void:
	xr = use_xr
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(60)

func route() -> Array:
	var segs: Array = PATHS.duplicate()
	var r: Array = game.building.content.data.floors[FLOOR].get("route", [])
	for i in range(1, r.size()):
		segs.append([Vector2(r[i - 1].position[0], r[i - 1].position[1]), Vector2(r[i].position[0], r[i].position[1])])
	return segs

## The group's footprint at a centre and facing, as a box in the floor's space: the beams' x extent (spacing x 2 +
## the lean's run + a section) by one section, grown by a walking margin.
func footprint(centre: Vector2, facing: float, margin: float) -> Dictionary:
	var run := 5.64 * tan(deg_to_rad(15.0))
	var half := Vector3((2 * 1.8 + run + 0.24) * 0.5 + margin, 2.6, 0.12 + margin)
	var basis := Basis(Vector3.UP, deg_to_rad(facing))
	return {"half": half, "xform": Transform3D(basis, Vector3(centre.x, LEVEL + 0.1 + 2.6 + 0.05, centre.y))}

func blocked(centre: Vector2, facing: float) -> String:
	var fp := footprint(centre, facing, 0.45)
	var q := PhysicsShapeQueryParameters3D.new()
	var box := BoxShape3D.new(); box.size = fp.half * 2.0; q.shape = box; q.transform = fp.xform
	q.collision_mask = 0xFFFFFFFF; q.collide_with_areas = false; q.exclude = [game.body.get_rid()]
	var hits := game.get_world_3d().direct_space_state.intersect_shape(q, 4)
	if not hits.is_empty(): return "body " + str((hits[0].collider as Node).name)
	# real floor under the feet and the tops (no shaft, no hole)
	var b: Basis = fp.xform.basis
	for sx in [-1.0, -0.5, 0.0, 0.5, 1.0]:
		for sz in [-1.0, 1.0]:
			var p: Vector3 = fp.xform.origin + b * Vector3(fp.half.x * sx, 0, fp.half.z * sz)
			var hit := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, LEVEL + 0.5, p.z), Vector3(p.x, LEVEL - 0.5, p.z), 0xFFFFFFFF))
			if hit.is_empty() or absf(hit.position.y - LEVEL) > 0.08: return "no floor at (%.1f, %.1f)" % [p.x, p.z]
			var up := game.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, LEVEL + 0.5, p.z), Vector3(p.x, CEILING + 0.4, p.z), 0xFFFFFFFF))
			if not up.is_empty() and up.position.y < CEILING - 0.05: return "something overhead at %.2f" % (up.position.y - LEVEL)
	# no walked path through the footprint
	var inv: Transform3D = fp.xform.affine_inverse()
	for seg in route():
		for k in 21:
			var p2: Vector2 = (seg[0] as Vector2).lerp(seg[1], k / 20.0)
			var l: Vector3 = inv * Vector3(p2.x, fp.xform.origin.y, p2.y)
			if absf(l.x) < fp.half.x + 0.3 and absf(l.z) < fp.half.z + 0.3: return "on a walked path"
	return ""

func survey() -> void:
	var free: Array = []; var reasons := {}
	for facing in [0.0, 90.0]:
		for xi in range(-40, 41):
			for zi in range(-16, 17):
				var c := Vector2(xi * 0.5, zi * 0.5)
				var why := blocked(c, facing)
				if why.is_empty(): free.append({"x": c.x, "z": c.y, "facing": facing, "to_parallel_lines": c.distance_to(Vector2(-14.62, 1))})
				else: reasons[why.split(" ")[0]] = int(reasons.get(why.split(" ")[0], 0)) + 1
	free.sort_custom(func(a, b): return a.to_parallel_lines < b.to_parallel_lines)
	print("BEAMS_FREE ", free.size(), " reasons ", reasons)
	for f in free.slice(0, 40): print("BEAMS_SPOT ", f)
	FileAccess.open(out.path_join("survey.json"), FileAccess.WRITE).store_string(JSON.stringify({"free": free, "reasons": reasons}, " "))
	check("the survey found spots on floor 03 where the beams fit (%d)" % free.size(), not free.is_empty())

func verify() -> void:
	var content: Node3D = game.building.content
	var mount: Node3D = content.exhibits.get("3/parallel-beams")
	if "--control" in OS.get_cmdline_user_args():
		# the same walk with the beams taken away: is a stuck walk theirs, or the floor's?
		if mount != null: mount.queue_free(); await frames(5)
		var ok_c := true
		game.place_player(Vector3(0.5, -17.94, 7.5)); await frames(12)
		for p in [Vector3(0.5, -18, 4.5), Vector3(-3.7, -18, 4.1), Vector3(-16.5, -18, 4.2), Vector3(-19, -18, 4.2), Vector3(-18, -18, -4.3), Vector3(-6, -18, -4.3)]:
			if not await move_to(p): ok_c = false; print("BEAMS_WALK control stuck before ", p, " at ", game.body.global_position)
		check("control, without the beams: the floor's walked path passes", ok_c)
		return
	check("the beams stand on floor 03 from rooms.json (3/parallel-beams)", mount != null)
	if mount == null: return
	var art: Node3D = mount.get_node("Artifact") if mount.has_node("Artifact") else mount.find_children("*", "Node3D", false, false)[0]
	var beams: Array = art.beams
	check("three beams", beams.size() == 3)
	var dir0: Vector3 = (beams[0] as Node3D).global_basis.y.normalized()
	var parallel := beams.all(func(b): return (b as Node3D).global_basis.y.normalized().dot(dir0) > 0.99999)
	var lean := rad_to_deg(dir0.angle_to(Vector3.UP))
	check("parallel, each leaning %.2f deg from the vertical" % lean, parallel and absf(lean - 15.0) < 0.05)
	var ends: Array = []; var ok_ends := true
	for b in beams:
		var m: MeshInstance3D = (b as Node3D).get_node("Mesh")
		var half: float = (m.mesh as BoxMesh).size.y * 0.5
		var foot: Vector3 = (b as Node3D).global_position - (b as Node3D).global_basis.y.normalized() * half
		var top: Vector3 = (b as Node3D).global_position + (b as Node3D).global_basis.y.normalized() * half
		ends.append([foot.y - LEVEL, top.y - LEVEL])
		if not (foot.y < LEVEL and foot.y > LEVEL - 0.12 and top.y > CEILING and top.y < CEILING + 0.12): ok_ends = false
	check("each runs from the floor into the ceiling (foot/top over the floor: %s; ceiling at %.2f)" % [str(ends), CEILING - LEVEL], ok_ends)
	var col: Color = ((beams[0] as Node3D).get_node("Mesh") as MeshInstance3D).material_override.albedo_color
	check("black (%s)" % col.to_html(false), col.get_luminance() < 0.06)
	var mid: Vector3 = (beams[1] as Node3D).global_position
	var side: Vector3 = mid + art.global_basis.z.normalized() * 1.5
	var hit := ray(side, mid)
	check("solid: a ray from the side stops on the middle beam (%s)" % (str((hit.collider as Node).name) if not hit.is_empty() else "nothing"), not hit.is_empty() and (hit.collider as Node) == beams[1])
	# the floor's own walk still passes
	var ok := true
	game.place_player(Vector3(0.5, -17.94, 7.5)); await frames(12)
	for p in [Vector3(0.5, -18, 4.5), Vector3(-3.7, -18, 4.1), Vector3(-16.5, -18, 4.2), Vector3(-19, -18, 4.2), Vector3(-18, -18, -4.3), Vector3(-6, -18, -4.3)]:
		if not await move_to(p): ok = false; print("BEAMS_WALK stuck before ", p, " at ", game.body.global_position)
	check("the floor's walked path still passes (landing, shaft A, north passage)", ok)
	# walk through the gap between beams 0 and 1, across the group: an upright body clears the lean when it walks the
	# line half a body's run (0.9 m x tan 15) past the middle of the two feet
	var st: Dictionary = art.get_state()
	var foot_local: Vector3 = ((st.feet[0] as Vector3) + (st.feet[1] as Vector3)) * 0.5 + Vector3(0.9 * tan(deg_to_rad(15.0)), 0, 0)
	var foot_gap: Vector3 = art.to_global(foot_local)
	foot_gap.y = LEVEL
	var across: Vector3 = art.global_basis.z.normalized()
	var start_at: Vector3 = foot_gap + Vector3(0, 0.06, 0) + across * 1.6
	game.place_player(start_at); await frames(20)
	var through := await move_to(foot_gap - across * 1.6)
	check("a visitor walks through the gap between two beams (%.2f m wide at the floor)" % art.get_state().gap_m, through)
	if DisplayServer.get_name() != "headless":
		var c: Vector3 = art.global_position
		await photograph("beams_across", c + across * 6.5 + Vector3(0, 1.6, 0), c + Vector3(0, 2.4, 0))
		await photograph("beams_along", c + art.global_basis.x.normalized() * 7.5 + across * 2.0 + Vector3(0, 1.6, 0), c + Vector3(0, 2.6, 0))
		await photograph("beams_between", foot_gap + across * 0.9 + Vector3(0, 1.6, 0), foot_gap + Vector3(0, 4.2, 0) - across * 1.0)

func photograph(id: String, at: Vector3, target: Vector3) -> void:
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 70; camera.environment = game.atmosphere.environment
	camera.global_position = at; camera.look_at(target); camera.make_current()
	game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(8); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(id + ".png"))
	camera.free(); game.camera.make_current()
