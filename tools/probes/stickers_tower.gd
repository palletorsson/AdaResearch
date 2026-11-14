extends SceneTree
## STICKERS IN THE RUNNING TOWER (QFEP_Phi_Term; 2026-11-13). The sticker app's hook, board, bench and pad on the
## floor where they stand, read in the real Void (not a test scene), against a COPY of the truth with posting off -
## this probe never writes commons/data/stickers/ and never posts:
##   T1 the gated line in game.gd made the StickerWorld;
##   T2 the board draws as many stickers as the copy holds for its board; T3 the bench draws its primitives' stickers,
##      the sphere's where the contract puts it (the sphere's centre + r along +Z, 2 mm proud);
##   T4 the pad stands on its plinth (the desktop's way to the pad);
##   T5 a sticker given to a real work of the floor is hosted under that work's mount, at
##      Artifact.global_transform * R_y(-museum_yaw) * at (the frame of the work's exported GLB);
##   T6 the floor's residency carries the stickers: with the body two floors up, floor 199's board stickers are not
##      shown; back on 199 they are again.
## Pictures: arrival.png (the spawn's view), board.png, bench.png.
##
##   godot --path <stage> --script res://tools/probes/stickers_tower.gd -- --no-bridges --void-start-floor=<199's index>
##       --out=<dir>
const StickerData := preload("res://commons/stickers/sticker_data.gd")
const COPY := "user://stickers_tower"
var game: Node3D
var eye: SubViewport
var cam: Camera3D


func _initialize() -> void:
	run.call_deferred()


func _shot(at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	for i in 8: await process_frame
	eye.get_texture().get_image().save_png(path)


func _layers_under(node: Node) -> Array:
	var out := []
	for n in node.find_children("*", "", true, false):
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("sticker_layer.gd"): out.append(n)
	return out


func _copy_truth() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(COPY))
	for name in ["designs.json", "boards.json", "placements.json"]:
		var text := FileAccess.get_file_as_string("res://commons/data/stickers/" + name)
		var f := FileAccess.open(COPY + "/" + name, FileAccess.WRITE)
		f.store_string(text)
		f.close()
	if FileAccess.file_exists(COPY + "/outbox.json"): DirAccess.remove_absolute(ProjectSettings.globalize_path(COPY + "/outbox.json"))


func run() -> void:
	var folder := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(folder)
	var checks := []
	var result := {"checks": checks, "passed": false}
	# the data node first, pointed at a copy with posting off: the game's StickerWorld then finds this one
	_copy_truth()
	var data: Node = StickerData.get_or_create(self)
	data.configure({"data_dir": COPY, "outbox": COPY + "/outbox.json", "post": false})
	result["data_dir"] = data.data_dir
	result["posting"] = data.post_enabled
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.body.scripted_input = true
	game.body.set_process_unhandled_input(false)
	game.scene_loaded()
	game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	result["floor"] = floor
	result["map"] = str(record.map)
	var content = game.building.content
	for i in 1500:
		if content.exhibits.has("%d/stickers-board" % floor) and content.exhibits.has("%d/stickers-bench" % floor): break
		await physics_frame
	for i in 240: await physics_frame
	var level: float = float(game.building.spec.levels[floor]) + game.building.global_position.y
	# T1 the hook
	var world: Node = null
	for n in game.get_children():
		if n.get_script() != null and str(n.get_script().resource_path).ends_with("sticker_world.gd"): world = n
	checks.append({"check": "T1 the gated line in game.gd made the StickerWorld, and it uses the probe's copy with posting off", "ok": world != null and data.data_dir == COPY and not data.post_enabled,
		"world": world != null, "data_dir": data.data_dir, "posting": data.post_enabled})
	# T2 the board
	var board_mount: Node3D = content.exhibits.get("%d/stickers-board" % floor)
	var on_board := 0
	for s in data.stickers_on("board:visitors"):
		if str(s.get("state", "on")) == "on": on_board += 1
	var drawn_board := 0
	if board_mount != null:
		for layer in _layers_under(board_mount): drawn_board += (layer.world_positions() as Dictionary).size()
	checks.append({"check": "T2 the board draws as many stickers as the copy holds for board 'visitors'", "ok": board_mount != null and on_board > 0 and drawn_board >= on_board,
		"in_copy": on_board, "drawn": drawn_board})
	# T2b the research board: one sticker per spine sequence
	var research_mount: Node3D = content.exhibits.get("%d/stickers-research" % floor)
	var on_research := 0
	for s in data.stickers_on("board:research"):
		if str(s.get("state", "on")) == "on": on_research += 1
	var drawn_research := 0
	if research_mount != null:
		for layer in _layers_under(research_mount): drawn_research += (layer.world_positions() as Dictionary).size()
	checks.append({"check": "T2b the research board draws every research sticker the copy holds (one per spine sequence)", "ok": research_mount != null and on_research >= 26 and drawn_research == on_research,
		"in_copy": on_research, "drawn": drawn_research})
	# T3 the bench
	var bench_mount: Node3D = content.exhibits.get("%d/stickers-bench" % floor)
	var per_host := {}
	var sphere_error := -1.0
	if bench_mount != null:
		for layer in _layers_under(bench_mount):
			var pos: Dictionary = layer.world_positions()
			per_host[layer.host_key()] = pos.size()
			if layer.host_key() == "primitive:sphere":
				for id in pos:
					var s: Dictionary = data.sticker(id)
					if s.is_empty(): continue
					var centre: Vector3 = (layer.get_parent() as Node3D).global_transform * Vector3.ZERO
					var expect: Vector3 = (layer.get_parent() as Node3D).global_transform * (StickerData.v3(s.at) + StickerData.v3(s.n) * 0.002)
					sphere_error = (pos[id] as Vector3).distance_to(expect)
					result["sphere_centre"] = [snappedf(centre.x, 0.001), snappedf(centre.y, 0.001), snappedf(centre.z, 0.001)]
	checks.append({"check": "T3 the bench draws the box, sphere and slab stickers; the sphere's where the contract puts it (within 1 cm)", "ok": int(per_host.get("primitive:box", 0)) >= 1 and int(per_host.get("primitive:sphere", 0)) >= 1
		and int(per_host.get("primitive:slab", 0)) >= 1 and sphere_error >= 0.0 and sphere_error < 0.01, "per_host": per_host, "sphere_error_m": snappedf(sphere_error, 0.0001)})
	# T4 the pad on its plinth
	checks.append({"check": "T4 the pad stands on its plinth beside the board", "ok": content.exhibits.has("%d/stickers-pad" % floor) and content.exhibits.has("%d/stickers-pad-plinth" % floor)})
	# T5 a sticker on a real work of the floor
	var work_id := ""
	for a in record.artifacts:
		if str(a.id).begins_with("f2_phi_slider"): work_id = str(a.id)
	var work_mount: Node3D = content.exhibits.get("%d/%s" % [floor, work_id])
	var t5 := {"check": "T5 a sticker given to a real work is hosted under its mount, at Artifact * R_y(-museum_yaw) * at (within 1 cm)", "ok": false, "work": work_id}
	if work_mount != null and world != null:
		var artifact: Node3D = work_mount.get_node_or_null("Artifact")
		var yaw := 0.0
		for a in record.artifacts:
			if str(a.id) == work_id: yaw = float(a.get("config", {}).get("museum_yaw", 0))
		var at := [0.0, 0.6, 0.15]
		var made: Dictionary = data.stick("here_pink_triangle", {"kind": "void_work", "floor": str(record.map), "work": work_id}, at, [0, 0, 1], [0, 1, 0], 0.15)
		for i in 30: await physics_frame
		var found := false
		var err := -1.0
		for layer in _layers_under(work_mount):
			var pos: Dictionary = layer.world_positions()
			if pos.has(str(made.get("id", ""))):
				found = true
				var frame: Transform3D = artifact.global_transform * Transform3D(Basis(Vector3.UP, deg_to_rad(-yaw)), Vector3.ZERO)
				var s: Dictionary = data.sticker(str(made.id))
				err = (pos[made.id] as Vector3).distance_to(frame * (StickerData.v3(s.at) + StickerData.v3(s.n) * 0.002))
		t5["ok"] = found and err >= 0.0 and err < 0.01
		t5["hosted_under_mount"] = found
		t5["error_m"] = snappedf(err, 0.0001)
		t5["museum_yaw"] = yaw
		t5["outbox_ops"] = (JSON.parse_string(FileAccess.get_file_as_string(COPY + "/outbox.json")) as Dictionary).get("pending", []).size() if FileAccess.file_exists(COPY + "/outbox.json") else 0
	checks.append(t5)
	# pictures while the floor is live
	eye = SubViewport.new()
	eye.size = Vector2i(1280, 800)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	cam.fov = 70
	eye.add_child(cam)
	cam.current = true
	await _shot(Vector3(0, level + 1.6, 7.8), Vector3(0, level + 1.0, -2.0), folder.path_join("arrival.png"))
	if board_mount != null:
		var face: Vector3 = board_mount.global_transform * Vector3(0, 1.35, 0)
		await _shot(face + Vector3(0.3, 0.2, 2.2), face, folder.path_join("board.png"))
	if bench_mount != null:
		var top: Vector3 = bench_mount.global_transform * Vector3(0, 1.0, 0)
		await _shot(top + Vector3(0.0, 0.9, 3.0), top, folder.path_join("bench.png"))
	if research_mount != null:
		var face2: Vector3 = research_mount.global_transform * Vector3(0, 1.35, 0)
		await _shot(face2 + Vector3(0.0, 0.05, 2.35), face2, folder.path_join("research.png"))
	# T6 residency: the body two floors up, then back
	var shown_before := false
	if board_mount != null:
		for layer in _layers_under(board_mount): shown_before = shown_before or (layer as Node3D).is_visible_in_tree()
	var up_floor := maxi(floor - 2, 0)
	var up_level: float = float(game.building.spec.levels[up_floor]) + game.building.global_position.y
	game.place_player(Vector3(0, up_level + 0.3, 7.8))
	for i in 400: await physics_frame
	var shown_away := false
	var board_alive := is_instance_valid(board_mount)
	if board_alive:
		for layer in _layers_under(board_mount): shown_away = shown_away or (layer as Node3D).is_visible_in_tree()
	game.place_player(Vector3(0, level + 0.3, 7.8))
	for i in 400: await physics_frame
	var shown_back := false
	board_mount = content.exhibits.get("%d/stickers-board" % floor)
	if board_mount != null:
		for layer in _layers_under(board_mount): shown_back = shown_back or (layer as Node3D).is_visible_in_tree()
	checks.append({"check": "T6 the floor's residency carries the stickers: shown on 199, not shown with the body two floors up, shown again back on 199", "ok": shown_before and not shown_away and shown_back,
		"shown_on_199": shown_before, "shown_from_two_up": shown_away, "board_kept_while_away": board_alive, "shown_back": shown_back, "away_floor": up_floor})
	result["passed"] = checks.all(func(c): return c.ok)
	var real := FileAccess.get_file_as_string("res://commons/data/stickers/placements.json")
	result["real_truth_untouched"] = not real.contains("here_pink_triangle\",\"host\":{\"kind\":\"void_work\"")
	var file := FileAccess.open(folder.path_join("tower.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[stickers_tower] ", "PASSED" if result.passed else "FAILED")
	quit()
