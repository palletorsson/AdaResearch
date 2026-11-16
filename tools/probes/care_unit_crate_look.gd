extends SceneTree
## THE OTHER THREE on the roof (Point_Zero; Palle, 2026-11-16)
## A transport crate beside the arrival crate with three more Model B bodies that did not wake. Read in the
## running tower with its own walker (which lifts the opening's veil at once: a scripted body):
##   the crate stands on the roof with three bodies in it, and they are the visitor's own body, not stand-ins;
##   the three stand inside the crate's boards, on its floor, a bay apart, facing its front;
##   the crate holds a body off: the walker aimed at the middle bay stops at the boards;
##   the axis: `closed` shows boards and no slats, `open` neither, `slatted` restores;
##   it does not stand in the arrival crate's way: the walker goes from the spawn out through the struck panel.
##
##   godot --path <stage> --script res://tools/probes/care_unit_crate_look.gd -- --no-bridges
##       --void-start-floor=0 --out=<dir>
##
## crate.json: checks with what was read. beside.png (from the south side of the arrival crate, where its
## lettering is read), front.png, near.png, closed.png, open.png.
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
	if work != null and work.has_method("state"):
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
		var s: Dictionary = work.state()
		checks.append({"check": "the crate stands on the roof with three bodies in it, and they are the visitor's own body, not stand-ins", "ok": int(s.units) == 3 and str(s.kind) == "android" and str(s.face) == "slatted"
			and bool(s.slats_shown) and not game.has_meta("opening"), "kind": str(s.kind), "build_ms": int(s.build_ms)})
		_save()
		var places: Array = s.unit_places
		var inside := true
		var locals := []
		for place in places:
			var p: Vector3 = work.to_local(Vector3(place[0], place[1], place[2]))
			locals.append([snappedf(p.x, 0.01), snappedf(p.y, 0.01), snappedf(p.z, 0.01)])
			inside = inside and absf(p.x) < 1.3 and absf(p.z) < 0.5 and absf(p.y - 0.12) < 0.02
		var facing: Vector3 = (work.get_node("Bay2/Unit") as Node3D).global_transform.basis.z
		var front: Vector3 = work.global_transform.basis.z
		checks.append({"check": "the three stand inside the crate's boards, on its floor, a bay apart, facing its front", "ok": inside and absf(float(locals[1][0]) - float(locals[0][0]) - 0.95) < 0.01
			and facing.dot(front) < -0.99, "places_in_the_crate": locals})
		_save()
		await _shot(Vector3(-5.0, level + 1.65, 4.6), Vector3(-2.2, level + 1.3, 3.2), "beside.png")
		await _shot(_at(0.0, 3.4) + Vector3(0, 1.6, 0), _at(0.0, 0.0) + Vector3(0, 1.25, 0), "front.png")
		await _shot(_at(0.5, 1.5) + Vector3(0, 1.6, 0), _at(-0.1, 0.0) + Vector3(0, 1.45, 0), "near.png")
		game.place_player(_at(0.0, 3.0) + Vector3(0, 0.3, 0))
		for i in 30: await physics_frame
		await _go(_at(0.0, 0.0), 300)
		var stopped: float = work.to_local(body.global_position).z
		checks.append({"check": "the crate holds a body off: the walker aimed at the middle bay stops at the boards", "ok": stopped > 0.7 and stopped < 1.1, "stopped_m_from_its_middle": snappedf(stopped, 0.01)})
		_save()
		work.apply_grid_config({"face": "closed"})
		var closed: Dictionary = work.state()
		await _shot(_at(0.0, 3.4) + Vector3(0, 1.6, 0), _at(0.0, 0.0) + Vector3(0, 1.25, 0), "closed.png")
		work.apply_grid_config({"face": "open"})
		var open: Dictionary = work.state()
		await _shot(_at(0.0, 3.4) + Vector3(0, 1.6, 0), _at(0.0, 0.0) + Vector3(0, 1.25, 0), "open.png")
		work.apply_grid_config({"face": "slatted"})
		var back: Dictionary = work.state()
		checks.append({"check": "the axis: `closed` shows boards and no slats, `open` neither, `slatted` restores", "ok": bool(closed.planks_shown) and not bool(closed.slats_shown) and not bool(open.planks_shown)
			and not bool(open.slats_shown) and bool(back.slats_shown) and not bool(back.planks_shown)})
		_save()
		var crate: Node3D = null
		var props: Dictionary = game.building.content.props
		for key in props:
			if str(key).begins_with("0/") and props[key] != null:
				var found := (props[key] as Node).get_node_or_null("Prefab") as Node3D
				if found != null and found.has_method("break_panel"): crate = found
		game.place_player_at_spawn(0)
		for i in 40: await physics_frame
		var started_inside: bool = crate != null and bool(crate.inside(body.global_position + Vector3(0, 0.9, 0)))
		if crate != null: crate.break_panel(false)
		for i in 20: await physics_frame
		var out: Vector3 = crate.to_global(Vector3(0, 0, -4.4)) if crate != null else Vector3.ZERO
		await _go(Vector3(out.x, body.global_position.y, out.z), 900)
		var left: float = Vector2(body.global_position.x - out.x, body.global_position.z - out.z).length()
		checks.append({"check": "it does not stand in the arrival crate's way: the walker goes from the spawn out through the struck panel", "ok": started_inside and left < 0.2, "short_of_the_place_outside_m": snappedf(left, 0.01)})
		result["passed"] = checks.all(func(c): return c.ok)
	else:
		checks.append({"check": "the roof holds the crate", "ok": false})
	_save()
	print("[care_unit_crate_look] ", "PASSED" if result.passed else "FAILED")
	quit()
