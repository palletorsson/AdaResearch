extends "res://tools/probes/void_game_probe.gd"
## THE PENDULUM ON FLOOR 14 (Trans_Introduction), in the actual tower. Palle, 2026-11-09: "Move the pendulum below the
## skateboard" - the skateboard on floor 15 joins its wheels with axles, a tie, and the tie's card is the pendulum's
## (tie(cube, sphere) = pendulum), so the pendulum has to be met first. It stood on floor 21 with the other physics plays.
## Checks: built on 14 and gone from 21; the timeline numbers it before the skateboard; it overlaps no other work on the
## floor; it hangs still, swings after RELEASE, comes home on RESET; the floor's route is still clear for a body.
## Run: python tools/test_pendulum_floor14.py
const FLOOR := 14

func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
	Engine.physics_ticks_per_second = 90
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = FLOOR
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(90)
	var content: Node3D = game.building.content
	var ex: Dictionary = content.exhibits
	var floors: Array = content.data.floors
	check("the pendulum is placed on floor 14 and on no other floor", floors[FLOOR].artifacts.filter(func(a): return a.artifact == "physics_play_pendulum").size() == 1
		and not range(floors.size()).any(func(i): return i != FLOOR and floors[i].artifacts.any(func(a): return a.artifact == "physics_play_pendulum")))
	check("the skateboard is still one floor up, on 15", floors[15].artifacts.any(func(a): return a.artifact == "mod_skateboard"))
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/artifact_timeline.json"))
	var keys: Array = t.main.map(func(r): return r.key)
	check("the timeline numbers the pendulum (#%d) before the skateboard (#%d)" % [keys.find("physics_play_pendulum") + 1, keys.find("mod_skateboard") + 1],
		keys.find("physics_play_pendulum") >= 0 and keys.find("physics_play_pendulum") < keys.find("mod_skateboard"))
	var host: Node3D = ex.get("%d/physics-play-pendulum" % FLOOR)
	check("it is built on floor 14", host != null)
	if host == null:
		_finish(); return
	var found: Array = host.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("physics_play/physics_play.gd"))
	check("it is the pendulum set-up", not found.is_empty() and found[0].setup == "pendulum")
	if found.is_empty():
		_finish(); return
	var p: Node3D = found[0]
	await frames(60)
	# NO OVERLAP: its meshes' box against every other work's box on this floor, shrunk 5 cm so touching is not a crash
	var mine := _box(host)
	var hits: Array = []
	for k in ex.keys():
		if not str(k).begins_with("%d/" % FLOOR) or ex[k] == host or not (ex[k] is Node3D): continue
		var other := _box(ex[k])
		if other.size != Vector3.ZERO and mine.grow(-.05).intersects(other.grow(-.05)): hits.append(str(k).get_slice("/", 1))
	check("its box %s overlaps no other work on the floor (%s)" % [str(mine.size).replace(" ", ""), ",".join(PackedStringArray(hits)) if hits else "none"], hits.is_empty() and mine.size != Vector3.ZERO)
	var level: float = float(game.building.spec.levels[FLOOR])
	check("it stands on the slab of floor 14 (base at %.2f, slab %.2f)" % [mine.position.y, level], absf(mine.position.y - level) < .4)
	# THE ROUTE, swept by the visitor's capsule: the new work stands in nobody's way
	var route: Array = floors[FLOOR].route
	var space := game.get_world_3d().direct_space_state
	var blocked: Array = []
	var capsule := CapsuleShape3D.new(); capsule.radius = .3; capsule.height = 1.5
	for i in range(1, route.size()):
		var a := Vector3(route[i - 1].position[0], level + 1.0, route[i - 1].position[1])
		var b := Vector3(route[i].position[0], level + 1.0, route[i].position[1])
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.transform = Transform3D(Basis(), a); q.motion = b - a
		q.exclude = [game.body.get_rid()]
		var free: PackedFloat32Array = space.cast_motion(q)
		if free.size() > 0 and free[0] < 1.0:
			var at := a.lerp(b, free[1]); q.transform = Transform3D(Basis(), at); q.motion = Vector3.ZERO
			var by := space.intersect_shape(q, 4).map(func(h): return str(h.collider.get_path()).get_slice("/", 6) if h.collider else "?")
			if by.any(func(n): return "pendulum" in n): blocked.append("%d->%d at (%.1f, %.1f) %s" % [i, i + 1, at.x, at.z, ",".join(PackedStringArray(by))])
	check("the floor's route is not blocked by the pendulum (%s)" % ("; ".join(PackedStringArray(blocked)) if blocked else "clear"), blocked.is_empty())
	# STILL, SWING, HOME
	var still := 0.0
	for b in p.bodies: still = maxf(still, (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length())
	check("before RELEASE it hangs still (worst %.3f m)" % still, still < .03)
	await _overview("floor14_pendulum_before.png", level, p.global_position)
	p.release()
	var most := 0.0
	for i in 40:
		await frames(4)
		for b in p.bodies: most = maxf(most, (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length())
	await _overview("floor14_pendulum_swinging.png", level, p.global_position)
	check("after RELEASE it swings under Jolt (bob travels %.2f m)" % most, most > .3)
	var lost: Array = p.bodies.filter(func(b): return b.global_position.y < level - .5)
	check("nothing falls off the floor (%d lost)" % lost.size(), lost.is_empty())
	p.reset()
	await frames(4)
	var home := 0.0
	for b in p.bodies: home = maxf(home, (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length())
	check("RESET brings it home (worst %.4f m)" % home, home < .03)
	_finish()

func _finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[pendulum_floor14] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func _box(node: Node) -> AABB:
	var box := AABB()
	var first := true
	for m in node.find_children("*", "MeshInstance3D", true, false):
		var mi := m as MeshInstance3D
		if mi.mesh == null or not mi.is_visible_in_tree() or mi.layers == 0: continue
		var b := mi.global_transform * mi.get_aabb()
		box = b if first else box.merge(b)
		first = false
	return box

func _overview(name: String, level: float, at: Vector3) -> void:
	if DisplayServer.get_name() == "headless": return
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 70; camera.environment = game.atmosphere.environment
	camera.global_position = Vector3(at.x - 4.5, level + 3.2, at.z - 4.0); camera.look_at(Vector3(at.x, level + .9, at.z)); camera.make_current()
	game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(6); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name))
	camera.queue_free()
