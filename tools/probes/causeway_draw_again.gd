extends SceneTree
## DOES THE PLATE DRAW AGAIN, AND DO THE HELD POSTS STAY? (bounded_plank_causeway; Palle, 2026-11-12)
## The work says: a body that steps on DRAW AGAIN draws a new table; both lanes change; the held posts do not.
## The Void's own walker is put south of the plate and driven onto it. Read before and after: the work's seed, both
## lanes' heights (profile()), and where every held post stands.
##
##   godot --path <stage> --script res://tools/probes/causeway_draw_again.gd -- --no-bridges --void-start-floor=82
##       --out=<dir>
##
## draw_again.json: checks (each with what was read) and `passed`.
var game: Node3D


func _initialize() -> void:
	run.call_deferred()      # after the autoloads: the game's body exists only then


func _held_posts(work: Node) -> Array:
	var out := []
	for n in work.find_children("*", "MeshInstance3D", true, false):
		if n.is_queued_for_deletion() or not n.get_meta("held", false): continue
		var p: Vector3 = (n as Node3D).global_position
		out.append("%.2f,%.2f,%.2f" % [p.x, p.y, p.z])
	out.sort()
	return out


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "bounded_plank_causeway": item = a
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 900:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		for i in 240: await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work == null or not work.has_method("profile"):
			for n in mount.find_children("*", "Node3D", true, false):
				if n.has_method("profile"): work = n; break
		var held: String = str(work.held)
		var before := {"seed": int(work.seed_value), "profile": work.profile(), "posts": _held_posts(work)}
		var plate: Vector3 = work.to_global(Vector3(0, 0, float(work.ramp_length) - .5))
		var start: Vector3 = work.to_global(Vector3(0, .3, float(work.ramp_length) + .9))
		var body: CharacterBody3D = game.body
		game.place_player(start)
		for i in 60: await physics_frame
		var ticks := 0
		while ticks < 300 and int(work.seed_value) == before.seed:
			body.look_at(Vector3(plate.x, body.global_position.y, plate.z), Vector3.UP)
			body.drive = Vector2(0, -1)
			await physics_frame
			ticks += 1
		body.drive = Vector2.ZERO
		for i in 40: await physics_frame
		var after := {"seed": int(work.seed_value), "profile": work.profile(), "posts": _held_posts(work)}
		var e: float = float(work.edge_height)
		var ends_level := true
		for snapshot in [before, after]:
			for row in snapshot.profile[held]:
				if absf(float(row[0]) - e) > .001 or absf(float(row[row.size() - 1]) - e) > .001: ends_level = false
		checks.append({"check": "stepping on the plate draws again", "ok": after.seed == before.seed + 1, "seed": [before.seed, after.seed], "ticks": ticks})
		checks.append({"check": "the lane where nothing is refused changed", "ok": before.profile["nothing"] != after.profile["nothing"]})
		checks.append({"check": "the held lane's interior changed", "ok": before.profile[held] != after.profile[held]})
		checks.append({"check": "every span of the held lane ends at the agreed height, before and after", "ok": ends_level, "agreed": e})
		checks.append({"check": "the held posts did not move", "ok": before.posts == after.posts and before.posts.size() > 0, "posts": before.posts.size()})
		result["before"] = before; result["after"] = after
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the work stands on this floor", "ok": false})
	var file := FileAccess.open(folder.path_join("draw_again.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[causeway_draw_again] ", "PASSED" if result.passed else "FAILED", " ", checks.size(), " checks")
	quit()
