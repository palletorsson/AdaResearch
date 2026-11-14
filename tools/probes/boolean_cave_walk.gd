extends SceneTree
## THE BOOLEAN CAVES IN THE TOWER (Boolean_Verbs' east side slab; 2026-11-14). The running tower, its own walker, and
## the pointer events the crosshair and the VR pointer send:
##   - both caves mounted from rooms.json, the big one past the 24 m line with the support-based boundary (exterior_walk)
##   - the negative: before any carve, the walker walking at the big block's face is stopped there
##   - a held carve from the slab, then the walker walks in: it reaches 3 m inside the block, stands on the cave's own
##     floor (4 cm), and is not sent back to the spawn (the boundary would, if the cave's floor were not support)
##   - the small one: a stroke painted on its block, its colour in the cave
##   - pictures: the east slab, the small block painted, the big block's mouth, inside the tunnel
##   Strokes are not kept (keep is switched off on the mounted works before painting).
##
##   godot --path <stage> --script res://tools/probes/boolean_cave_walk.gd -- --no-bridges --void-start-floor=<161> --out=<dir>
const PREFIX := "boolean-cave-"
var game: Node3D
var body: CharacterBody3D
var level := 0.0
var works := {}
var eye: SubViewport
var cam: Camera3D
var pointer: Node3D
var checks := []


func _initialize() -> void:
	run.call_deferred()


func _check(name: String, ok: bool, data := {}) -> void:
	checks.append({"check": name, "ok": ok}.merged(data))


func _shot(at: Vector3, target: Vector3, path: String, fov := 70.0) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.fov = fov
	# a brush's preview is drawn over everything while one aims; it is not the cave
	for w in works.values():
		var brush: Node3D = w.get_node_or_null("Brush")
		if brush != null: brush.visible = false
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)
	cam.fov = 70.0


func _place(p: Vector3) -> void:
	game.place_player(Vector3(p.x, level + 0.12, p.z))
	for i in 30: await physics_frame


func _path(points: Array, speed: float = 0.5, ticks_max: int = 2400) -> Dictionary:
	var still := 0
	var last := body.global_position
	var i := 0
	var jumped := false
	for tick in ticks_max:
		if i >= points.size(): break
		var target: Vector3 = points[i]
		var flat := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		if flat < (0.12 if i == points.size() - 1 else 0.22):
			i += 1
			continue
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -speed)
		await physics_frame
		if body.global_position.distance_to(last) > 2.0: jumped = true   # a return to the spawn is not a walk
		if body.global_position.distance_to(last) < 0.002: still += 1
		else: still = 0
		last = body.global_position
		if still > 80: break
	body.drive = Vector2.ZERO
	for t in 12: await physics_frame
	return {"reached": i >= points.size() and not jumped, "jumped": jumped, "end": body.global_position}


func _report(type: int, target: Node3D, at: Vector3) -> void:
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(type, pointer, target, at, at))


func _hit(target: Node3D, from: Vector3, toward: Vector3, mask := 1 << 20) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, from + (toward - from).normalized() * 30.0, mask)
	q.exclude = [body.get_rid()]
	return target.get_world_3d().direct_space_state.intersect_ray(q)


func _hold(work: Node3D, from: Vector3, toward: Vector3, seconds: float) -> int:
	var target: Node3D = work.cave()
	var before: int = work.state().stamps
	pointer.global_position = from
	var first := _hit(target, from, toward)
	if first.is_empty() or first.collider != target: return -1
	_report(XRToolsPointerEvent.Type.PRESSED, target, first.position)
	await create_timer(seconds).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, target, first.position)
	for i in 3: await physics_frame
	return int(work.state().stamps) - before


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	var floor_index: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor_index]
	var result := {"floor": floor_index, "map": str(record.map), "checks": checks, "passed": false}
	var ids := []
	for item in record.artifacts:
		if str(item.id).begins_with(PREFIX): ids.append(str(item.id))
	for i in 2400:
		var all := true
		for id in ids:
			if not game.building.content.exhibits.has("%d/%s" % [floor_index, id]): all = false
		if all: break
		await physics_frame
	var mounts := {}
	for id in ids:
		var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor_index, id])
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work != null and work.has_method("state"):
			works[str(work.size)] = work
			mounts[str(work.size)] = mount
			work.keep = false
	for i in 240: await physics_frame
	level = float(game.building.spec.levels[floor_index]) + game.building.global_position.y
	body = game.body
	pointer = Node3D.new()
	game.add_child(pointer)
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	cam.fov = 70
	eye.add_child(cam)
	cam.current = true
	_check("both caves mounted, the big one in the support-based boundary (exterior_walk)", works.has("big") and works.has("small")
		and mounts.get("big") != null and (mounts["big"] as Node).is_in_group("void_exterior_walk"),
		{"sizes": works.keys(), "big_at": (works["big"] as Node3D).global_position if works.has("big") else Vector3.ZERO})
	if not (works.has("big") and works.has("small")):
		_finish(folder, result)
		return
	var big: Node3D = works["big"]
	var small: Node3D = works["small"]
	await _shot(Vector3(19.0, level + 5.5, -9.5), big.to_global(Vector3(0, 1.0, 2.0)), folder.path_join("east_slab.png"))

	# ---- the negative: the uncarved block stops the walker at its face ----
	await _place(big.to_global(Vector3(0.0, 0, 5.4)))
	var r := await _path([big.to_global(Vector3(0.0, 0, 1.0))], 0.5, 600)
	var stopped_z: float = big.to_local(r.end).z
	_check("before any carve, the walker is stopped at the big block's face", not r.reached and stopped_z > 3.4, {"stopped_at_local_z": snappedf(stopped_z, 0.01)})

	# ---- carve from the slab, walk in, carve again, walk on ----
	big.press("bigger")
	big.press("bigger")
	var stamps := 0
	stamps += await _hold(big, big.to_global(Vector3(0, 1.6, 5.4)), big.to_global(Vector3(0.0, 1.4, -3.0)), 2.2)
	await _place(big.to_global(Vector3(0.0, 0, 4.6)))
	r = await _path([big.to_global(Vector3(0.0, 0, 3.0)), big.to_global(Vector3(0.0, 0, 1.8))])
	stamps += await _hold(big, body.global_position + Vector3(0, 1.6, 0), big.to_global(Vector3(0.0, 1.4, -3.0)), 2.2)
	await _shot(big.to_global(Vector3(-1.6, 1.7, 6.6)), big.to_global(Vector3(0.0, 1.2, 1.0)), folder.path_join("big_mouth.png"))
	var r2 := await _path([big.to_global(Vector3(0.0, 0, 0.5))])
	var inside := big.to_local(r2.end)
	var feet_y: float = r2.end.y - level
	_check("after held carves, the walker walks 3 m into the big block, on the cave's own floor, and is not sent back",
		r.reached and r2.reached and inside.z < 0.8 and absf(feet_y - 0.04) < 0.03 and absf(r2.end.x) > 24.0,
		{"stamps": stamps, "inside_local": inside, "feet_y": snappedf(feet_y, 0.003), "world_x": snappedf(r2.end.x, 0.01), "first_leg": r.reached, "jumped": r2.jumped})
	await _shot(big.to_global(Vector3(0.6, 1.6, 2.6)), big.to_global(Vector3(0.0, 1.3, -1.0)), folder.path_join("big_inside.png"))

	# ---- the small one: a stroke on its block ----
	await _place(small.to_global(Vector3(0.9, 0, 1.9)))
	small.press("bigger")
	var mid := small.to_global(Vector3(0, 1.17, 0))
	var from := small.to_global(Vector3(0, 1.5, 1.7))
	var target: Node3D = small.cave()
	pointer.global_position = from
	var first := _hit(target, from, mid + small.global_basis * Vector3(-0.3, 0.1, 0.5))
	var painted := 0
	if not first.is_empty():
		_report(XRToolsPointerEvent.Type.PRESSED, target, first.position)
		for i in 30:
			var aim: Vector3 = mid + small.global_basis * Vector3(-0.3 + i * 0.02, 0.1 - 0.14 * sin(i * 0.35), 0.5)
			await physics_frame
			var h := _hit(target, from, aim)
			if not h.is_empty(): _report(XRToolsPointerEvent.Type.MOVED, target, h.position)
			await create_timer(0.06).timeout
		_report(XRToolsPointerEvent.Type.RELEASED, target, first.position)
		for i in 3: await physics_frame
		painted = int(small.state().stamps)
	await _shot(small.to_global(Vector3(0.3, 1.32, 1.25)), small.to_global(Vector3(0.0, 1.15, 0.4)), folder.path_join("small_painted.png"), 42.0)
	# the groove reads as one: the stamps' centres spread across the face, not stacked in one place
	var xs := []
	for rec in small._stamps: xs.append(float(rec.c[0]))
	var spread: float = (xs.max() - xs.min()) if xs.size() > 1 else 0.0
	_check("the small block takes a painted stroke - a groove across its face, not one hole", painted >= 6 and bool(small.state().carved) and spread > 0.35,
		{"state": small.state(), "spread_m": snappedf(spread, 0.001)})
	# leave the works as they were
	await small.reset()
	await big.reset()
	game.place_player(Vector3(0, level + 0.3, 7.8))
	result["passed"] = checks.all(func(c): return c.ok)
	_finish(folder, result)


func _finish(folder: String, result: Dictionary) -> void:
	var file := FileAccess.open(folder.path_join("cave.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[boolean_cave_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
