extends SceneTree
## A JOINT MORE on its floor (AdvancedLaboratory_Lab_Equipment_Simulation; the pass, 2026-11-16)
## The workshop's body drawn on the floor; the visitor's feet add joints and connections. Read in the running
## tower with its own walker:
##   at rest: thirteen joints, twelve connections, one connected part, no loop;
##   the walker stands still on bare floor: a joint more, joined by the rule to the nearest joint (r_shoulder);
##   it stands on the head (held, a line follows it), then on bare floor: a joint more, joined to the head;
##   it holds l_hand and stands on the head: the two are neighbours, no point moved, one loop;
##   it holds the chest and stands on the head: that connection is authored and stays; nothing is counted;
##   CLEAR WHAT I ADDED: thirteen and twelve again, no loop;
##   the axis: `limb` is found with 14 joints and 13 connections, `loop` with 13 and 13 and one loop; `authored`
##     restores.
##
##   godot --path <stage> --script res://tools/probes/joint_more_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## joints.json: checks with what was read (written after every check). arrival.png, wing.png, drawn.png.
const ID := "joint-more"
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
	var file := FileAccess.open(folder.path_join("joints.json"), FileAccess.WRITE)
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


## To a place, and still there for a second and a quarter.
func _stand(target: Vector3) -> Dictionary:
	await _go(target)
	for i in 75: await physics_frame
	return work.state()


func _counts(s: Dictionary) -> Array:
	return [int(s.joints), int(s.connections), int(s.parts), int(s.loops)]


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
	var record: Dictionary = game.building.content.data.floors[floor]
	var checks := []
	result = {"floor": floor, "map": str(record.map), "checks": checks, "passed": false}
	for i in 1500:
		if game.building.content.exhibits.has("%d/%s" % [floor, ID]): break
		await physics_frame
	var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor, ID])
	work = mount.get_node_or_null("Artifact") if mount != null else null
	if work != null and work.has_method("joint_point"):
		for i in 200: await physics_frame
		level = float(game.building.spec.levels[floor]) + game.building.global_position.y
		body = game.body
		eye = SubViewport.new()
		eye.size = Vector2i(1280, 800)
		eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
		root.add_child(eye)
		cam = Camera3D.new()
		cam.fov = 80
		eye.add_child(cam)
		cam.current = true
		game.place_player(Vector3(13.5, level + 0.3, 7.6))        # out of its own arrival picture
		for i in 30: await physics_frame
		await _shot(Vector3(0, level + 1.65, 7.8), Vector3(0, level + 1.5, 0), "arrival.png")
		await _shot(Vector3(-13.3, level + 1.65, 8.0), Vector3(-17.0, level + 0.6, -1.0), "wing.png")
		work.apply_grid_config({"figure": "limb"})
		work.apply_grid_config({"figure": "authored"})
		var s: Dictionary = work.state()
		checks.append({"check": "at rest: thirteen joints, twelve connections, one connected part, no loop", "ok": _counts(s) == [13, 12, 1, 0] and str(s.held) == "", "counts": _counts(s), "build_ms": int(s.build_ms)})
		_save()
		game.place_player(work.local_point(2.4, 4.0) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		var planted: Dictionary = await _stand(work.local_point(2.4, -3.4))
		checks.append({"check": "the walker stands still on bare floor: a joint more, joined by the rule to the nearest joint (r_shoulder)", "ok": _counts(planted) == [14, 13, 1, 0] and str(planted.last_event) == "planted_nearest:r_shoulder"
			and Array(planted.added) == ["r_shoulder-joint_14"], "counts": _counts(planted), "added": planted.added, "status": str(planted.status)})
		_save()
		var held: Dictionary = await _stand(work.joint_point("head"))
		await _go(work.local_point(-1.2, -3.2))
		var leading: bool = bool(work.state().lead_shown)
		var chosen: Dictionary = await _stand(work.local_point(-2.4, -3.8))
		checks.append({"check": "it stands on the head (held, a line follows it), then on bare floor: a joint more, joined to the head", "ok": str(held.held) == "head" and leading and _counts(chosen) == [15, 14, 1, 0]
			and str(chosen.last_event) == "planted_chosen:head" and Array(chosen.added).has("head-joint_15") and str(chosen.held) == "", "counts": _counts(chosen), "added": chosen.added, "status": str(chosen.status)})
		_save()
		await _stand(work.joint_point("l_hand"))
		var loop: Dictionary = await _stand(work.joint_point("head"))
		await _shot(work.local_point(0.0, 7.6) + Vector3(0, 3.4, 0), work.local_point(0.0, -1.6) + Vector3(0, 0.3, 0), "drawn.png")
		checks.append({"check": "it holds l_hand and stands on the head: the two are neighbours, no point moved, one loop", "ok": _counts(loop) == [15, 15, 1, 1] and Array(loop.added).has("l_hand-head")
			and str(loop.status).contains("NO POINT MOVED"), "counts": _counts(loop), "added": loop.added, "status": str(loop.status)})
		_save()
		await _stand(work.joint_point("chest"))
		var authored: Dictionary = await _stand(work.joint_point("head"))
		checks.append({"check": "it holds the chest and stands on the head: that connection is authored and stays; nothing is counted", "ok": _counts(authored) == [15, 15, 1, 1] and str(authored.last_event) == "authored:chest:head"
			and str(authored.status).contains("NOT YOURS TO TAKE AWAY"), "status": str(authored.status)})
		_save()
		var cleared: Dictionary = await _stand(work.plate_point())
		checks.append({"check": "CLEAR WHAT I ADDED: thirteen and twelve again, no loop", "ok": _counts(cleared) == [13, 12, 1, 0] and Array(cleared.added).is_empty(), "counts": _counts(cleared)})
		_save()
		work.apply_grid_config({"figure": "limb"})
		var limb: Dictionary = work.state()
		work.apply_grid_config({"figure": "loop"})
		var looped: Dictionary = work.state()
		work.apply_grid_config({"figure": "authored"})
		var back: Dictionary = work.state()
		checks.append({"check": "the axis: `limb` is found with 14 joints and 13 connections, `loop` with 13 and 13 and one loop; `authored` restores", "ok": _counts(limb) == [14, 13, 1, 0] and _counts(looped) == [13, 13, 1, 1]
			and _counts(back) == [13, 12, 1, 0], "limb": _counts(limb), "loop": _counts(looped)})
		_save()
		game.place_player(Vector3(0, level + 0.3, 8.6))
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the floor holds the work", "ok": false})
	_save()
	print("[joint_more_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
