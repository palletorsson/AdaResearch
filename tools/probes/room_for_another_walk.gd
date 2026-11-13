extends SceneTree
## ROOM FOR ANOTHER on its floor (GT_Flow; the pass, 2026-11-13)
## The hall's harbour at the size of a body: every crate slot a bridge, the body the delivery. Read in the running
## tower with its own walker, against the bench (tools/probes/room_for_another_bench.py):
##   nine bridges from the hall model's links, built from the tower's prefabs; the hall model's first allocation
##   stands (0>1 1>3 3>5 5>6), and its search finds the second over six bridges, one of them against a promise;
##   a gate holds a body off an empty bridge's head (nothing was promised there);
##   the second delivery walks in at depot B, reaches yard 3 and waits: a crate fills the bridge to the dock;
##   the body walks the bridge from depot A backwards: the crate is taken back and the slot is free;
##   through yard 4 to the ship's side: two arrived, the crates stand as the hall model's second step, and the
##   harbour is closed by the two slots out of the south bank - as many as arrived; the mats, green while another
##   delivery could reach their quay, are all grey;
##   a delivery left under way by a body that vanished: the harbour is again what its row says.
##
##   godot --path <stage> --script res://tools/probes/room_for_another_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## harbour.json: checks with what was read. arrival.png, above.png, waits.png, taken_back.png, both.png.
const ID := "room-for-another"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 6: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 900, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 14: await physics_frame


func _cross(a: int, b: int, n: int = 0, backwards: bool = false) -> void:
	var e: Array = work.ends(work.slot_of(a, b, n))
	await _go(e[1] if backwards else e[0])
	await _go(e[0] if backwards else e[1])


func _sorted(list: Array) -> Array:
	var out := list.duplicate()
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
	var checks := []
	var result := {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("slot_of"):
		for i in 300: await physics_frame
		var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var up := Vector3(0, 0.3, 0)
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		var cam := Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		var at: Vector3 = work.global_position
		var s: Dictionary = work.state()
		var kinds := {}
		for n in work.find_children("*", "Node3D", true, false):
			if n.has_meta("prefab") and n.has_meta("source_scene"): kinds[str(n.get_meta("prefab"))] = int(kinds.get(str(n.get_meta("prefab")), 0)) + 1
		checks.append({"check": "nine bridges from the hall model's links, built from the tower's prefabs; the model's first allocation stands and its search finds the second over six bridges, one against a promise",
			"ok": int(s.slots) == 9 and _sorted(s.full) == ["0>1", "1>3", "3>5", "5>6"] and int(s.arrived) == 1 and Array(s.way) == [0, 2, 3, 1, 4, 5, 6] and int(s.against) == 1
				and int(kinds.get("timber_panel_1x1", 0)) == 9 and int(kinds.get("timber_plank_1m", 0)) == 16 and int(kinds.get("timber_plank_2m", 0)) == 20 and int(kinds.get("crate", 0)) == 6
				and kinds.has("barrier") and kinds.has("work_light") and kinds.has("pink_triangle_sign"),
			"slots": int(s.slots), "full": s.full, "arrived": int(s.arrived), "way": s.way, "against": int(s.against), "kinds": kinds, "build_ms": int(s.build_ms)})
		await _shot(cam, Vector3(0, level + 1.6, 7.8), at + Vector3(0, 0.3, 0), folder.path_join("arrival.png"))
		await _shot(cam, at + Vector3(1.8, 5.0, 9.3), at + Vector3(0.0, 0, -1.5), folder.path_join("above.png"))
		# a gate holds: nothing was promised on the second gangway
		var spare: int = work.slot_of(5, 6, 1)
		var gang: Array = work.ends(spare)
		game.place_player(gang[1] + up)
		for i in 40: await physics_frame
		await _go(gang[0], 240, 0.5)
		var held: Vector3 = work.to_local(body.global_position)
		checks.append({"check": "a gate holds a body off an empty bridge's head: nothing was promised there", "ok": held.z < -6.05 and not work.is_full(spare) and int(work.state().land) == -1,
			"stopped_at_z": snappedf(held.z, .01), "the_gate_stands_at_z": -5.94})
		# the second delivery: in at depot B, on to yard 3, and there it waits
		var entry: Array = work.ends(work.slot_of(0, 2))
		game.place_player(entry[0] + up)
		for i in 40: await physics_frame
		await _cross(0, 2)
		await _cross(2, 3)
		var on: Array = work.ends(work.slot_of(3, 5))
		await _go(on[0])
		await _go(on[1], 240, 0.5)
		var waits: Vector3 = work.to_local(body.global_position)
		var w: Dictionary = work.state()
		await _shot(cam, body.global_position + Vector3(1.6, 1.5, 1.4), work.to_global(Vector3(1.6, 0.3, -2.0)), folder.path_join("waits.png"))
		checks.append({"check": "the second delivery walks in at depot B, reaches yard 3 and waits: a crate fills the bridge to the dock", "ok": waits.z > -1.0 and int(w.land) == 3 and (w.full as Array).has("0>2") and (w.full as Array).has("2>3")
			and int(w.arrived) == 1 and int((w.under_way as Dictionary).get(3, 0)) == 1, "stopped_at_z": snappedf(waits.z, .01), "the_crate_begins_at_z": -1.07, "full": w.full, "under_way": w.under_way})
		# take it back: the bridge from depot A, walked backwards
		await _cross(1, 3, 0, true)
		var t: Dictionary = work.state()
		await _shot(cam, at + Vector3(1.8, 5.0, 9.3), at + Vector3(0.0, 0, -1.5), folder.path_join("taken_back.png"))
		checks.append({"check": "the body walks the bridge from depot A backwards: the crate is taken back and the slot is free", "ok": not work.is_full(work.slot_of(1, 3)) and int(t.land) == 1
			and int((t.under_way as Dictionary).get(1, 0)) == 1, "land": int(t.land), "full": t.full, "under_way": t.under_way})
		# through yard 4 to the ship's side
		await _cross(1, 4)
		await _cross(4, 5)
		await _cross(5, 6, 1)
		var b: Dictionary = work.state()
		await _shot(cam, at + Vector3(1.8, 5.0, 9.3), at + Vector3(0.0, 0, -1.5), folder.path_join("both.png"))
		checks.append({"check": "through yard 4 to the ship's side: two arrived, the crates stand as the hall model's second step, and what closes the harbour is the two slots out of the south bank - as many as arrived",
			"ok": int(b.arrived) == 2 and int(b.land) == -1 and _sorted(b.full) == ["0>1", "0>2", "1>4", "2>3", "3>5", "4>5", "5>6", "5>6"] and (b.way as Array).is_empty()
				and _sorted(b.closes) == ["0>1", "0>2"] and (b.under_way as Dictionary).is_empty() and Array(b.reach) == [0] and (s.reach as Array).size() == 7,
			"arrived": int(b.arrived), "full": b.full, "closes": b.closes, "walked": int(b.walked), "another_delivery_reaches_before": s.reach, "and_now": b.reach})
		# left under way
		await _cross(5, 6, 0, true)
		var mid: Dictionary = work.state()
		game.place_player(Vector3(16.5, level + 0.3, 5.0))
		for i in 330: await physics_frame
		var again: Dictionary = work.state()
		checks.append({"check": "a delivery left under way by a body that vanished: the harbour is again what its row says", "ok": int(mid.arrived) == 1 and int((mid.under_way as Dictionary).get(5, 0)) == 1
			and int(again.restored) >= 1 and _sorted(again.full) == ["0>1", "1>3", "3>5", "5>6"], "under_way_before": mid.under_way, "restored": int(again.restored), "full": again.full})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	var file := FileAccess.open(folder.path_join("harbour.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[room_for_another_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
