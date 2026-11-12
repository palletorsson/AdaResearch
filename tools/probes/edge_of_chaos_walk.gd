extends SceneTree
## THE DIFFERENCE STUDY IS MET FROM ITS FRONT (floor CA_EdgeOfChaos; the Void, 2026-11-12)
## The study (self_organization_ca, study:difference, slice:walk) is read from its own -Z side: console, readout and
## floor words face that way, and a body walks between the two volumes toward the two slice cases, its position
## selecting the spatial slice. In the tower it stood with that side to the north: the arrival met the backs of the
## slice cases and mirrored words. Read in the running tower, with its own walker:
##   the readout faces the arrival point; nothing stands within 2.5 m of the arrival;
##   a body walks from the arrival into the lane between the volumes, and its position there selects the slice.
##
##   godot --path <stage> --script res://tools/probes/edge_of_chaos_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## edge.json: checks with what was read. arrival.png from the spawn point, lane.png in the lane.
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 500) -> float:
	var best := INF
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.12: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -0.5)
		await physics_frame
	body.drive = Vector2.ZERO
	for i in 30: await physics_frame
	return best


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
	var item = null
	for a in record.artifacts:
		if str(a.artifact) == "self_organization_ca": item = a
	checks.append({"check": "the difference study is on this floor", "ok": item != null})
	if item != null:
		var key := str(floor) + "/" + str(item.id)
		for i in 1200:
			if game.building.content.exhibits.has(key): break
			await physics_frame
		var mount: Node3D = game.building.content.exhibits.get(key)
		var study: Node3D = null
		for i in 900:
			for n in mount.find_children("DifferenceStudy", "Node3D", true, false): study = n
			if study != null and is_instance_valid(study.get("slice_walker")): break
			await physics_frame
		for i in 300: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		var body: CharacterBody3D = game.body
		for layer in root.find_children("*", "CanvasLayer", true, false):      # the game's overlays, not a work's own layers
			if layer.get_viewport() == root: layer.hide()
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 30: await physics_frame
		var cam := Camera3D.new()
		cam.fov = 80
		root.add_child(cam)
		var spawn := Vector3(0, level, 7.8)
		await _shot(cam, spawn + Vector3(0, 1.6, 0), Vector3(-0.8, level + 1.8, 0), folder.path_join("arrival.png"))
		checks.append({"check": "the study has its walking slice", "ok": study != null and is_instance_valid(study.get("slice_walker"))})
		if study != null:
			var reading: Label3D = study.get("reading")
			var front: Vector3 = reading.global_transform.basis.z.normalized()
			var to_spawn: Vector3 = (spawn - reading.global_position)
			to_spawn.y = 0
			checks.append({"check": "the readout faces the arrival point", "ok": front.dot(to_spawn.normalized()) > 0.5, "cosine": snappedf(front.dot(to_spawn.normalized()), .01)})
			# nothing of the study in the arrival's face
			var eye := spawn + Vector3(0, 1.6, 0)
			var lane := AABB(Vector3(-0.6, level + 0.3, 7.8 - 2.5), Vector3(1.2, 1.9, 2.3))
			var near := ""
			for m in mount.find_children("*", "MeshInstance3D", true, false):
				var mi := m as MeshInstance3D
				if mi.mesh == null or not mi.is_visible_in_tree(): continue
				var box: AABB = mi.global_transform * mi.mesh.get_aabb()
				if not box.has_point(eye) and box.intersects(lane) and box.size.y >= 0.3: near = str(mi.name)
			checks.append({"check": "no mesh of the study stands within 2.5 m straight ahead of the arrival", "ok": near == "", "mesh": near})
			# into the lane: the body's position selects the slice
			var entry: Vector3 = study.to_global(Vector3(0, 0, 0.3))
			var deep: Vector3 = study.to_global(Vector3(0, 0, 2.9))
			game.place_player(spawn + Vector3(0, 0.3, 0))
			for i in 40: await physics_frame
			var reach_a: float = await _go(body, entry)
			var slice_a: int = int(study.slice_z)
			await _shot(cam, entry + Vector3(0, 1.6, 0) + (entry - deep).normalized() * 1.2, deep + Vector3(0, 1.9, 0) + (deep - entry).normalized() * 3.0, folder.path_join("lane.png"))
			var reach_b: float = await _go(body, deep)
			var slice_b: int = int(study.slice_z)
			checks.append({"check": "a body walks from the arrival into the lane between the volumes, and where it stands selects the slice",
				"ok": reach_a < 0.3 and reach_b < 0.3 and slice_b - slice_a >= 6 and int(game.checkpoint) == floor,
				"slice_at_the_entry": slice_a, "slice_at_the_far_end": slice_b, "came_within_m": [snappedf(reach_a, .01), snappedf(reach_b, .01)]})
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("edge.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[edge_of_chaos_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
