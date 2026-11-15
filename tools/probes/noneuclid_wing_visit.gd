extends SceneTree
## SEVEN SPACES in the tower (NonEuclidean_Spaces; the pass, 2026-11-15)
## The wing (commons/artifacts/noneuclidean_wing, with its Void adapter) holds seven chambers 60 m above its door
## and shows the first through a stencil doorway. Does a visitor of the tower get in, round and out?
##   the wing stands as its Void adapter, built, with its door clear of the columns;
##   from the floor the door shows a room that is not there (pictures: door.png, door_side.png);
##   the walker goes through the door and stands in the first chamber, 60 m up, without a fall being counted;
##   each of the seven chambers can be visited and the walker stands on its floor;
##   leaving puts the walker back on this floor.
##
##   godot --path <stage> --script res://tools/probes/noneuclid_wing_visit.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## wing.json: checks with what was read. door.png, door_side.png, chamber_1.png ... chamber_7.png, back.png.
const ID := "f2_noneuclidean_wing_13_4"
var game: Node3D
var body: CharacterBody3D
var work: Node3D
var eye: SubViewport


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _go(target: Vector3, ticks_max: int = 900, speed: float = 0.34) -> void:
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if d < 0.1: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame


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
	if work != null and work.has_method("visit"):
		for i in 400:
			if bool(work.built): break
			await physics_frame
		for i in 120: await physics_frame
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
		var front: Vector3 = work.global_transform.basis.z.normalized()
		var side: Vector3 = work.global_transform.basis.x.normalized()
		var door: Vector3 = work.global_position
		# is the way to the door clear? a ray at chest height from 3 m in front to the door plane
		var space := body.get_world_3d().direct_space_state
		var blocked := []
		for off in [-0.6, 0.0, 0.6]:
			var q := PhysicsRayQueryParameters3D.create(door + front * 3.0 + side * off + Vector3(0, 1.0, 0), door + front * 0.15 + side * off + Vector3(0, 1.0, 0))
			var hit := space.intersect_ray(q)
			if not hit.is_empty(): blocked.append("%s at %.2f m from the door" % [str(hit.collider.name), (hit.position - door).dot(front)])
		checks.append({"check": "the wing stands as its Void adapter, built, with the way to its door clear", "ok": str(work.get_script().resource_path).ends_with("noneuclidean_wing_void.gd") and bool(work.built) and blocked.is_empty(),
			"script": str(work.get_script().resource_path).get_file(), "in_the_way": blocked, "door_at": [snappedf(door.x, .01), snappedf(door.z, .01)], "chambers": (work.rooms as Array).size()})
		await _shot(cam, door + front * 4.2 + Vector3(0, 1.6, 0), door + Vector3(0, 1.4, 0), folder.path_join("door.png"))
		await _shot(cam, door + front * 2.5 + side * 5.5 + Vector3(0, 1.8, 0), door - front * 2.0 + Vector3(0, 1.3, 0), folder.path_join("door_side.png"))
		# through the door
		game.place_player(door + front * 2.6 + up)
		for i in 40: await physics_frame
		var before_y: float = body.global_position.y
		await _go(door - front * 1.6, 500)
		for i in 30: await physics_frame
		var inside: bool = int(work.current) == 0
		var lifted: float = body.global_position.y - before_y
		checks.append({"check": "the walker goes through the door and stands in the first chamber, without a fall being counted", "ok": inside and lifted > 40.0 and not bool(game.recovering), "current": int(work.current), "lifted_m": snappedf(lifted, .1),
			"recovering": bool(game.recovering)})
		var stood := []
		var all_stood := true
		for i in 7:
			if int(work.current) != i: work.visit(i)
			for k in 60: await physics_frame
			var room: Node3D = work.rooms[i]
			var local: Vector3 = room.to_local(body.global_position)
			var ok: bool = int(work.current) == i and absf(local.y) < 1.2 and absf(local.x) < 7.5 and absf(local.z) < 7.5 and not bool(game.recovering)
			all_stood = all_stood and ok
			stood.append({"chamber": i + 1, "title": str(work.TITLES[i]), "stands": ok, "at": [snappedf(local.x, .1), snappedf(local.y, .1), snappedf(local.z, .1)]})
			await _shot(cam, room.to_global(Vector3(2.4, 2.2, 5.0)), room.to_global(Vector3(-0.6, 1.6, -3.0)), folder.path_join("chamber_%d.png" % (i + 1)))
		checks.append({"check": "each of the seven chambers can be visited and the walker stands on its floor", "ok": all_stood, "chambers": stood})
		work.leave()
		for k in 90: await physics_frame
		var back: float = body.global_position.y - level
		await _shot(cam, body.global_position + front * 2.5 + side * 1.5 + Vector3(0, 1.5, 0), body.global_position + Vector3(0, 1.0, 0), folder.path_join("back.png"))
		checks.append({"check": "leaving puts the walker back on this floor", "ok": int(work.current) == -1 and absf(back) < 1.5 and not bool(game.recovering), "above_the_floor_m": snappedf(back, .01), "recovering": bool(game.recovering)})
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the wing", "ok": false})
	var file := FileAccess.open(folder.path_join("wing.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[noneuclid_wing_visit] ", "PASSED" if result.passed else "FAILED")
	quit()
