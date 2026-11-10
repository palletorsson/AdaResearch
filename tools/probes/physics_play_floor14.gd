extends "res://tools/probes/void_game_probe.gd"
## THE PHYSICS PLAYS BELOW THE SKATEBOARD, ON FLOOR 14 (Trans_Introduction), in the actual tower. Palle, 2026-11-09:
## "Move the pendulum below the skateboard" and then "move the plank on a ball below the skateboard too". The
## skateboard on floor 15 joins its wheels with axles (a tie) and is an assemblage of many kinds of part; the pendulum
## introduces the tie (joint:1) and the plank on a ball the first assemblage (parts:1), so both are met before it.
## They stood on Logic_Event with the other physics plays.
## Per set-up: placed on 14 and on no other floor; numbered before the skateboard; overlaps no other work; on the slab;
## the route not blocked by it; still before RELEASE, moving after it, nothing off the floor, home on RESET.
## Run: python tools/test_physics_play_floor14.py
const FLOOR := 14
const PLAYS := {"physics-play-pendulum": ["physics_play_pendulum", "pendulum"], "physics-play-plank-ball": ["physics_play_plank_ball", "plank_on_ball"]}

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
	var level: float = float(game.building.spec.levels[FLOOR])
	check("the skateboard is still one floor up, on 15", floors[15].artifacts.any(func(a): return a.artifact == "mod_skateboard"))
	var t: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/data/artifact_timeline.json"))
	var keys: Array = t.main.map(func(r): return r.key)
	var plays: Array = []
	var boxes := {}
	for id in PLAYS:
		var artifact: String = PLAYS[id][0]
		check("%s is placed on floor 14 and on no other floor" % artifact, floors[FLOOR].artifacts.filter(func(a): return a.artifact == artifact).size() == 1
			and not range(floors.size()).any(func(i): return i != FLOOR and floors[i].artifacts.any(func(a): return a.artifact == artifact)))
		check("the timeline numbers %s (#%d) before the skateboard (#%d)" % [artifact, keys.find(artifact) + 1, keys.find("mod_skateboard") + 1],
			keys.find(artifact) >= 0 and keys.find(artifact) < keys.find("mod_skateboard"))
		var host: Node3D = ex.get("%d/%s" % [FLOOR, id])
		var found: Array = [] if host == null else host.find_children("*", "Node3D", true, false).filter(func(n): return n.get_script() != null and n.get_script().resource_path.ends_with("physics_play/physics_play.gd"))
		check("%s is built on floor 14 as the %s set-up" % [artifact, PLAYS[id][1]], not found.is_empty() and found[0].setup == PLAYS[id][1])
		if not found.is_empty():
			plays.append(found[0]); boxes[id] = host
	if plays.size() != PLAYS.size():
		_finish(); return
	await frames(60)
	# NO OVERLAP: each set-up's meshes' box against every other work's box on this floor, shrunk 5 cm so touching is no crash
	for id in boxes:
		var mine := _box(boxes[id])
		var hits: Array = []
		for k in ex.keys():
			if not str(k).begins_with("%d/" % FLOOR) or ex[k] == boxes[id] or not (ex[k] is Node3D): continue
			var other := _box(ex[k])
			if other.size != Vector3.ZERO and mine.grow(-.05).intersects(other.grow(-.05)): hits.append(str(k).get_slice("/", 1))
		check("%s: its box %s overlaps no other work on the floor (%s)" % [id, str(mine.size).replace(" ", ""), ",".join(PackedStringArray(hits)) if hits else "none"], hits.is_empty() and mine.size != Vector3.ZERO)
		check("%s stands on the slab of floor 14 (base at %.2f, slab %.2f)" % [id, mine.position.y, level], absf(mine.position.y - level) < .4)
	# THE ROUTE, swept by the visitor's capsule: the moved works stand in nobody's way
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
			if by.any(func(n): return "physics-play" in n): blocked.append("%d->%d at (%.1f, %.1f) %s" % [i, i + 1, at.x, at.z, ",".join(PackedStringArray(by))])
	check("the floor's route is not blocked by the moved plays (%s)" % ("; ".join(PackedStringArray(blocked)) if blocked else "clear"), blocked.is_empty())
	# STILL, MOVING, HOME
	var still := 0.0
	var who := ""
	for p in plays:
		for b in p.bodies:
			var off: float = (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length()
			if off > still:
				still = off; who = "%s/%s at %s, touching %s" % [p.setup, b.name, str(b.global_position), _touching(b)]
	check("before RELEASE nothing moves by itself (worst %.3f m%s)" % [still, (": " + who) if still >= .03 else ""], still < .03)
	await _overview("floor14_plays_before.png", level, Vector3(11.75, level, 6.6))
	for p in plays: p.release()
	var most := {}
	for i in 60:
		await frames(4)
		for p in plays:
			for b in p.bodies:
				var turned := rad_to_deg(b.global_basis.get_rotation_quaternion().angle_to((p.global_basis * (p.homes[b][0] as Transform3D).basis).get_rotation_quaternion()))
				most[p.setup] = maxf(most.get(p.setup, 0.0), maxf((p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length(), turned / 100.0))
	await _overview("floor14_plays_after.png", level, Vector3(11.75, level, 6.6))
	for p in plays:
		check("after RELEASE the %s moves under Jolt (%.2f)" % [p.setup, most.get(p.setup, 0.0)], most.get(p.setup, 0.0) > .3)
	var lost: Array = []
	for p in plays:
		for b in p.bodies:
			if b.global_position.y < level - .5: lost.append(p.setup)
	check("nothing falls off the floor or into a shaft (%s)" % (",".join(PackedStringArray(lost)) if lost else "none lost"), lost.is_empty())
	for p in plays: p.reset()
	await frames(4)
	var home := 0.0
	var away := ""
	for p in plays:
		for b in p.bodies:
			var off: float = (p.to_local(b.global_position) - (p.homes[b][0] as Transform3D).origin).length()
			if off > home:
				home = off; away = "%s/%s" % [p.setup, b.name]
	check("RESET brings both home (worst %.4f m%s)" % [home, (" " + away) if home >= .03 else ""], home < .03)
	_finish()

func _finish() -> void:
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[physics_play_floor14] %d/%d checks pass" % [checks.size() - failed.size(), checks.size()])
	quit(0 if failed.is_empty() else 1)

func _touching(b: RigidBody3D) -> String:
	var names: Array = []
	var space := b.get_world_3d().direct_space_state
	for owner in b.get_shape_owners():
		for i in b.shape_owner_get_shape_count(owner):
			var q := PhysicsShapeQueryParameters3D.new(); q.shape = b.shape_owner_get_shape(owner, i)
			q.transform = b.global_transform * b.shape_owner_get_transform(owner); q.exclude = [b.get_rid()]
			for h in space.intersect_shape(q, 6):
				if h.collider: names.append(str(h.collider.get_path()).replace("/root/", "") + " " + str((h.collider as Node3D).global_position if h.collider is Node3D else ""))
	return ",".join(PackedStringArray(names)) if names else "nothing"

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
	camera.global_position = Vector3(at.x - 5.0, level + 3.6, at.z - 5.0); camera.look_at(Vector3(at.x, level + .7, at.z)); camera.make_current()
	game.status.hide(); game.charge_display.hide(); game.notice_time = 0
	if game.desktop_help != null: game.desktop_help.hide()
	await frames(6); await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(out.path_join(name))
	camera.queue_free()
