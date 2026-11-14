extends SceneTree
## THE WARDROBE AS ROOMS, IN THE TOWER (Shader_11_QueerRubber, floor 105; 2026-11-14). Fourteen wardrobe tunnels, seven
## on each side slab, mounted from rooms.json:
##   - every tunnel mounted in its configured skin, and in the support-based boundary (exterior_walk): its far half is
##     past the 24 m line, where the game sends a body back to the spawn unless what is under its feet says otherwise
##   - the walker walks from the hall into a tunnel on each side, 6 m in, and stays there (is not sent back)
##   - inside, a walk sideways stops at the tunnel's wall (no way into the next one)
##   - pictures: each block from the hall; every tunnel from its mouth at a headset's density (22 px a degree);
##     the hall seen from deep inside one; the arrival view (the blocks stand at the sides, not in the face)
##
##   godot --path <stage> --script res://tools/probes/wardrobe_tunnel_walk.gd -- --no-bridges --void-start-floor=<105> --out=<dir>
const PREFIX := "wardrobe-tunnel-"
var game: Node3D
var body: CharacterBody3D
var level := 0.0
var eye: SubViewport
var cam: Camera3D
var checks := []


func _initialize() -> void:
	run.call_deferred()


func _check(name: String, ok: bool, data := {}) -> void:
	checks.append({"check": name, "ok": ok}.merged(data))


func _shot(at: Vector3, target: Vector3, path: String, fov := 70.0) -> void:
	cam.global_position = Vector3(at.x, level + at.y, at.z)
	cam.look_at(Vector3(target.x, level + target.y, target.z), Vector3.UP)
	cam.fov = fov
	for i in 10: await process_frame
	eye.get_texture().get_image().save_png(path)


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


## Walk from the hall into a tunnel and stand there two seconds: the end, and whether it was ever sent back.
func _walk_in(from: Vector3, mouth: Vector3, deep: Vector3) -> Dictionary:
	await _place(from)
	var walk := await _path([mouth, deep])
	var stayed := true
	var at := body.global_position
	for t in 120:
		await physics_frame
		if body.global_position.distance_to(at) > 1.0: stayed = false
	return {"reached": walk.reached, "jumped": walk.jumped, "stayed": stayed,
		"end": [snappedf(body.global_position.x, 0.01), snappedf(body.global_position.z, 0.01)]}


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
	var rows := {}
	for item in record.artifacts:
		if str(item.id).begins_with(PREFIX): rows[str(item.id)] = item
	for i in 2400:
		var all := true
		for id in rows:
			if not game.building.content.exhibits.has("%d/%s" % [floor_index, id]): all = false
		if all: break
		await physics_frame
	for i in 240: await physics_frame
	# the tower adds a work, then configures it; the tunnel builds at the end of that frame - so look after the settle
	var mounted := []
	var wrong := []
	for id in rows:
		var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor_index, id])
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work == null or not work.has_method("worn_hue"): continue
		var why := []
		if work.skin != str(rows[id].config.skin): why.append("skin %s" % work.skin)
		if not mount.is_in_group("void_exterior_walk"): why.append("not exterior_walk")
		if work.get_node_or_null("Tunnel") == null: why.append("not built")
		if not why.is_empty():
			wrong.append("%s: %s" % [id, ", ".join(why)])
		else:
			mounted.append(str(work.skin))
	_check("all fourteen tunnels mounted in their skins, in the support-based boundary (exterior_walk)",
		rows.size() == 14 and mounted.size() == 14 and wrong.is_empty(), {"rows": rows.size(), "mounted": mounted.size(), "wrong": wrong})
	level = float(game.building.spec.levels[floor_index]) + game.building.global_position.y
	body = game.body
	eye = SubViewport.new()
	eye.size = Vector2i(1600, 1000)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	eye.add_child(cam)
	cam.current = true

	var east := await _walk_in(Vector3(16.0, 0, 0.6), Vector3(21.6, 0, 0.0), Vector3(28.5, 0, 0.0))
	_check("east: the walker walks from the hall 6 m into the leather tunnel, past the 24 m line, and stays", east.reached and east.stayed and east.end[0] > 27.5, east)
	var west := await _walk_in(Vector3(-16.0, 0, 0.6), Vector3(-21.6, 0, 0.0), Vector3(-28.5, 0, 0.0))
	_check("west: the walker walks from the hall 6 m into the neon tunnel, past the 24 m line, and stays", west.reached and west.stayed and west.end[0] < -27.5, west)
	await _place(Vector3(26.0, 0, 0.0))
	var side := await _path([Vector3(26.0, 0, 3.5)], 0.5, 600)
	var side_z: float = side.end.z
	_check("inside, a walk sideways stops at the tunnel's wall (1.2 m out, less a body's radius)", side_z < 1.2 and side_z > 0.5, {"stopped_at_z": snappedf(side_z, 0.01)})

	await _place(Vector3(0.0, 0, 7.8))                 # out of every picture
	await _shot(Vector3(9.0, 2.2, 7.0), Vector3(25.0, 1.4, -1.0), folder.path_join("east_block.png"), 70.0)
	await _shot(Vector3(-9.0, 2.2, 7.0), Vector3(-25.0, 1.4, -1.0), folder.path_join("west_block.png"), 70.0)
	await _shot(Vector3(0.0, 1.6, 7.8), Vector3(0.0, 1.4, -10.0), folder.path_join("arrival.png"), 80.0)
	for item in rows.values():
		var p: Array = item.position
		var side_sign := 1.0 if float(p[0]) > 0.0 else -1.0
		var mouth := Vector3(float(p[0]), 0.0, float(p[1]))
		await _shot(mouth - Vector3(side_sign * 1.6, -1.6, 0.0), mouth + Vector3(side_sign * 8.0, 1.3, 0.0),
			folder.path_join("inside_%s.png" % str(item.config.skin)), 45.0)
	await _shot(Vector3(29.2, 1.6, 0.0), Vector3(10.0, 1.4, 0.0), folder.path_join("looking_out_leather.png"), 60.0)

	result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("walk.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[wardrobe_tunnel_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
