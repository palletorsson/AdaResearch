extends SceneTree
## THE OTHER THREE, in the one box (Point_Zero; Palle, 2026-11-16)
## The visitor wakes in the arrival crate; against its back wall stand four bays, three with bodies of the same
## model that did not wake, one empty with its straps open. Read in the running tower with its own walker (which
## lifts the opening's veil at once: a scripted body):
##   the row has no crate of its own: four bays, the second empty, three bodies, and they are the visitor's own
##     body, not stand-ins;
##   the three stand inside the ARRIVAL crate (asked of that crate), behind the place where the visitor wakes,
##     facing the panel that is struck;
##   the visitor wakes a step in front of the empty bay, inside the crate, and is not caught in the row: aimed
##     at the row, the walker is held off it;
##   the crate is still left the same way: the walker goes from the spawn out through the struck panel.
##
##   godot --path <stage> --script res://tools/probes/care_unit_crate_look.gd -- --no-bridges
##       --void-start-floor=0 --out=<dir>
##
## crate.json: checks with what was read. waking.png (what is ahead at the spawn), behind.png (turned round at the
## spawn), empty_bay.png, from_outside.png (through the fallen side).
const ID := "care-units-crate"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport
var cam: Camera3D
var folder := ""
var result := {}
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _save() -> void:
	var file := FileAccess.open(folder.path_join("crate.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()


func _shot(at: Vector3, target: Vector3, name: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 12: await physics_frame
	for i in 8: await process_frame
	await RenderingServer.frame_post_draw
	eye.get_texture().get_image().save_png(folder.path_join(name))


func _go(target: Vector3, ticks: int = 1200) -> void:
	for i in ticks:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.07: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -(0.5 if d > 0.5 else 0.25))
		await physics_frame
	body.drive = Vector2.ZERO


func _at(x: float, z: float) -> Vector3:
	return work.local_point(x, z)


func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var floor: int = game.checkpoint
	var checks := []
	result = {"floor": floor, "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	var crate: Node3D = null
	var props: Dictionary = game.building.content.props
	for key in props:
		if str(key).begins_with("0/") and props[key] != null:
			var found := (props[key] as Node).get_node_or_null("Prefab") as Node3D
			if found != null and found.has_method("break_panel"): crate = found
	if work != null and work.has_method("state") and crate != null:
		for i in 200: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 90
		eye.add_child(cam)
		cam.current = true
		var s: Dictionary = work.state()
		checks.append({"check": "the row has no crate of its own: four bays, the second empty, three bodies, and they are the visitor's own body, not stand-ins",
			"ok": not bool(s.shell) and int(s.bays) == 4 and int(s.empty) == 1 and int(s.units) == 3 and str(s.kind) == "android" and work.has_node("Bay1") and not work.get_node("Bay1").has_node("Unit")
			and not game.has_meta("opening"), "kind": str(s.kind), "build_ms": int(s.build_ms)})
		_save()
		var all_inside := true
		var in_crate := []
		for place in s.unit_places:
			var at := Vector3(place[0], place[1], place[2])
			all_inside = all_inside and bool(crate.inside(at + Vector3(0, 0.9, 0)))
			var p: Vector3 = crate.to_local(at)
			in_crate.append([snappedf(p.x, 0.01), snappedf(p.z, 0.01)])
		var spawn: Vector3 = game.spawn_for(0)
		var spawn_in_crate: Vector3 = crate.to_local(spawn)
		var facing: Vector3 = (work.get_node("Bay2/Unit") as Node3D).global_transform.basis.z
		var to_panel: Vector3 = crate.global_transform.basis.z * -1.0
		checks.append({"check": "the three stand inside the ARRIVAL crate (asked of that crate), behind the place where the visitor wakes, facing the panel that is struck",
			"ok": all_inside and in_crate.all(func(p): return float(p[1]) > spawn_in_crate.z + 0.8) and facing.dot(to_panel) < -0.99, "bodies_in_the_crate_x_z": in_crate,
			"spawn_in_the_crate_x_z": [snappedf(spawn_in_crate.x, 0.01), snappedf(spawn_in_crate.z, 0.01)]})
		_save()
		game.place_player_at_spawn(0)
		for i in 40: await physics_frame
		var woke_inside: bool = bool(crate.inside(body.global_position + Vector3(0, 0.9, 0)))
		var here: Vector3 = body.global_position
		var eye_at := Vector3(here.x, level + 1.62, here.z)
		game.place_player(Vector3(13.5, level + 0.3, 7.6))            # out of its own pictures
		for i in 20: await physics_frame
		await _shot(eye_at, eye_at + to_panel * 1.2, "waking.png")
		await _shot(eye_at, eye_at - to_panel * 1.0 + Vector3(0, -0.25, 0), "behind.png")
		var vacant: Vector3 = (work.get_node("Bay1") as Node3D).global_position
		await _shot(eye_at + to_panel * 0.35, vacant + Vector3(0, 1.0, 0), "empty_bay.png")
		game.place_player_at_spawn(0)
		for i in 40: await physics_frame
		var row: Vector3 = work.global_position
		await _go(Vector3(row.x + 0.4, body.global_position.y, row.z), 300)
		var short: float = crate.to_local(body.global_position).z
		var row_z: float = crate.to_local(row).z
		checks.append({"check": "the visitor wakes a step in front of the empty bay, inside the crate, and is not caught in the row: aimed at the row, the walker is held off it",
			"ok": woke_inside and absf(crate.to_local(here).x - crate.to_local(vacant).x) < 0.6 and short < row_z - 0.3 and short > spawn_in_crate.z + 0.2,
			"woke_x_z": [snappedf(crate.to_local(here).x, 0.01), snappedf(crate.to_local(here).z, 0.01)], "empty_bay_x": snappedf(crate.to_local(vacant).x, 0.01), "held_at_z": snappedf(short, 0.01), "row_z": snappedf(row_z, 0.01)})
		_save()
		game.place_player_at_spawn(0)
		for i in 40: await physics_frame
		crate.break_panel(false)
		for i in 20: await physics_frame
		var out: Vector3 = crate.to_global(Vector3(0, 0, -4.4))
		await _go(Vector3(out.x, body.global_position.y, out.z), 900)
		var left: float = Vector2(body.global_position.x - out.x, body.global_position.z - out.z).length()
		game.place_player(Vector3(13.5, level + 0.3, 7.6))
		for i in 20: await physics_frame
		await _shot(crate.to_global(Vector3(0.5, 1.62, -4.6)), crate.to_global(Vector3(0, 1.2, 1.0)), "from_outside.png")
		checks.append({"check": "the crate is still left the same way: the walker goes from the spawn out through the struck panel", "ok": left < 0.2, "short_of_the_place_outside_m": snappedf(left, 0.01)})
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the roof holds the row and the arrival crate", "ok": false})
	_save()
	print("[care_unit_crate_look] ", "PASSED" if result.passed else "FAILED")
	quit()
