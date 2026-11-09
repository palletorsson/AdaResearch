extends "res://tools/probes/void_game_probe.gd"
## PHYSICS PLAY ON FLOOR 21 (Logic_Event, "event and consequence"), in the actual tower. First stood on floor 14
## (Trans_Introduction) in place of the logic gates; Palle moved it on 2026-11-03 to open Logic, with the five
## tipping-point thresholds beside it (threshold_descent went to Form Finding). Built by the floor from
## commons/void/rooms.json: still before RELEASE, moving after it, home after RESET, nothing lost off the floor, and a
## route a body can walk. Run: python tools/test_physics_play_floor.py
## The PENDULUM went down to floor 14 on 2026-11-09 (Palle: "Move the pendulum below the skateboard") - the tie is met
## before the skateboard's axles on 15; tools/probes/pendulum_floor14.gd checks it there. Eleven set-ups stay here.
const FLOOR := 21
const THRESHOLDS := ["again", "almost", "just", "barely", "still"]

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
	var on14: Array = content.data.floors[14].artifacts.filter(func(a): return (str(a.artifact).begins_with("physics_play") and a.artifact != "physics_play_pendulum") or str(a.artifact).begins_with("threshold_"))
	check("floor 14 is the Introduction again: no physics play but the pendulum, no threshold, no gate (%d left)" % on14.size(), on14.is_empty() and not content.data.floors[14].artifacts.any(func(a): return str(a.artifact).begins_with("matter_spring")))
	check("they stand on the Logic floors (22 AND, 23 OR and NOT)", content.data.floors[22].artifacts.any(func(a): return a.artifact == "matter_spring_and") and content.data.floors[23].artifacts.filter(func(a): return a.artifact in ["matter_spring_or", "matter_spring_not"]).size() == 2)
	var plays: Array = []
	for k in ex.keys():
		if str(k).begins_with("%d/physics-play-" % FLOOR):
			var found: Array = (ex[k] as Node).find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("physics_play/physics_play.gd"))
			if not found.is_empty(): plays.append(found[0])
	check("eleven physics play set-ups are built on floor %d (the pendulum is on 14), none with a button (%d)" % [FLOOR, plays.size()], plays.size() == 11 and not plays.any(func(p): return p.setup == "pendulum") and not plays.any(func(p): return p.find_children("*", "Node3D", true, false).any(func(n): return n.has_signal("pressed"))))
	var built: Array = THRESHOLDS.filter(func(t): return ex.has("%d/threshold-workshop-%s" % [FLOOR, t]))
	check("the five tipping points stand beside them (%s)" % ",".join(PackedStringArray(built)), built.size() == 5)
	check("threshold_descent cools on Form Finding, floor 62", content.data.floors[62].artifacts.any(func(a): return a.artifact == "threshold_descent"))
	check("the tyre chain still opens the floor", ex.has("%d/logic-event" % FLOOR))
	# THE ROUTE, swept by the visitor's own capsule from label to label: nothing stands in the way
	var level: float = float(game.building.spec.levels[FLOOR])
	var route: Array = content.data.floors[FLOOR].route
	var space := game.get_world_3d().direct_space_state
	var blocked: Array = []
	var capsule := CapsuleShape3D.new(); capsule.radius = .3; capsule.height = 1.5
	for i in range(1, route.size()):
		var a := Vector3(route[i - 1].position[0], level + .25 + .75, route[i - 1].position[1])
		var b := Vector3(route[i].position[0], level + .25 + .75, route[i].position[1])
		var q := PhysicsShapeQueryParameters3D.new(); q.shape = capsule; q.transform = Transform3D(Basis(), a); q.motion = b - a
		q.exclude = [game.body.get_rid()]
		# a shaft is a hole, not a body: a sweep cannot see it, so every half metre must also stand on the slab
		for k in int(ceil(a.distance_to(b) / .5)) + 1:
			var at := a.lerp(b, minf(k * .5 / maxf(a.distance_to(b), .001), 1.0))
			var ground := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(at.x, level + .5, at.z), Vector3(at.x, level - .5, at.z)))
			if ground.is_empty() or absf(ground.position.y - level) > .1:
				blocked.append("%d->%d no floor at (%.1f, %.1f)" % [i, i + 1, at.x, at.z]);break
		var free: PackedFloat32Array = space.cast_motion(q)
		if free.size() > 0 and free[0] < 1.0:
			var at := a.lerp(b, free[1]); q.transform = Transform3D(Basis(), at); q.motion = Vector3.ZERO
			var hits := space.intersect_shape(q, 4).map(func(h): return str(h.collider.get_path()).get_slice("/", 6) if h.collider else "?")
			blocked.append("%d->%d at (%.1f, %.1f) %s" % [i, i + 1, at.x, at.z, ",".join(PackedStringArray(hits))])
	var hole := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(-10, level + .5, 0), Vector3(-10, level - .5, 0)))
	check("the floor rays bite: the middle of shaft A reads as no floor", hole.is_empty() or absf(hole.position.y - level) > .1)
	check("the route's %d legs are clear for a body (%s)" % [route.size() - 1, "; ".join(PackedStringArray(blocked)) if blocked else "all clear"], route.size() >= 4 and blocked.is_empty())
	await frames(180)
	await _overview("floor21_before.png", level)
	var still := 0.0
	for p in plays:
		for b in p.bodies: still = maxf(still, (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length())
	check("before RELEASE nothing moves by itself in the tower (worst %.3f m)" % still, still < .03)
	for p in plays: p.release()
	await frames(360)
	await _overview("floor21_after.png", level)
	var moved: Array = []
	for p in plays:
		var most := 0.0
		var turned := 0.0
		for b in p.bodies:
			most = maxf(most, (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length())
			# a domino tile's origin is its base: it barely travels when it topples, so a turn counts as moving too
			turned = maxf(turned, rad_to_deg(b.global_basis.get_rotation_quaternion().angle_to((p.global_basis * (p.homes[b][0] as Transform3D).basis).get_rotation_quaternion())))
		moved.append("%s %.2f m / %.0f deg" % [p.setup, most, turned])
		if most < .1 and turned < 30: check("after RELEASE %s moved (%.3f m, %.0f deg)" % [p.setup, most, turned], false)
	check("after RELEASE every set-up moves under Jolt (%s)" % ", ".join(moved), true)
	var lost: Array = []
	for p in plays:
		for b in p.bodies:
			if b.global_position.y < level - .5 or absf(b.global_position.x) > 21.5 or absf(b.global_position.z) > 9.5: lost.append(p.setup)
	check("nothing rolls off the floor or into a shaft (%s)" % (",".join(PackedStringArray(lost)) if lost else "none lost"), lost.is_empty())
	# THE RESET PLATE, stepped on by the visitor's own body: the tyre and boxes go home
	var tb: Node3D = plays.filter(func(p): return p.setup == "tyre_and_boxes").front()
	var away := 0.0
	for b in tb.bodies: away = maxf(away, (tb.to_local(b.global_position) - (tb.homes[b][0] as Transform3D).origin).length())
	game.place_player(tb.to_global(tb._plate_at + Vector3(0, .1, 0))); await frames(40)
	var back := 0.0
	for b in tb.bodies: back = maxf(back, (tb.to_local(b.global_position) - (tb.homes[b][0] as Transform3D).origin).length())
	check("standing on the reset plate puts the tyre and boxes back (%.2f m out before, %.4f m after)" % [away, back], away > .3 and back < .03)
	for p in plays: p.reset()
	await frames(4)
	var home := 0.0
	for p in plays:
		for b in p.bodies: home = maxf(home, (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length())
	check("RESET brings every body home in the tower (worst %.4f m)" % home, home < .03)
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[physics_play_floor] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func _overview(name: String, level: float) -> void:
	if DisplayServer.get_name() == "headless": return
	var camera := Camera3D.new(); game.add_child(camera); camera.fov = 78; camera.environment = game.atmosphere.environment
	camera.global_position = Vector3(1.0, level + 4.6, 8.7); camera.look_at(Vector3(-1.5, level + .2, 0.0)); camera.make_current()
	game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(6); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name))
	camera.queue_free()
