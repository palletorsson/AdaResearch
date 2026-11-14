extends SceneTree
## THE WARDROBE, PHOTOGRAPHED IN THE TOWER (boolean_cave on Boolean_Verbs' east slab; 2026-11-14). Every skin worn by a
## real stroke in the tower's own light, so the looks can be judged where they will be seen:
##   - big: seven alcoves carved along the block's face, one skin each, twice (fourteen skins); a close look at three
##   - small: fourteen short grooves, one skin each, on its face
##   - the wardrobe rack itself; the blocks dressed (big in latex, small in rainbow)
##   - checks: every skin's strokes are cut and carry their skin's material; DRESS swaps the block's surfaces only
##   Strokes are not kept; both caves are reset (and undressed) at the end.
##
##   godot --path <stage> --script res://tools/probes/boolean_cave_wardrobe.gd -- --no-bridges --void-start-floor=<161> --out=<dir>
const Cave := preload("res://commons/artifacts/boolean_cave/boolean_cave.gd")
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


func _shot(at: Vector3, target: Vector3, path: String, fov := 60.0) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.fov = fov
	for w in works.values():
		var brush: Node3D = w.get_node_or_null("Brush")
		if brush != null: brush.visible = false
	for i in 10: await process_frame
	eye.get_texture().get_image().save_png(path)


func _settled(work: Node3D) -> void:
	var guard := 0
	while (not work.settled() or work._loading) and guard < 3000:
		await process_frame
		guard += 1
	await physics_frame
	await physics_frame


func _report(type: int, target: Node3D, at: Vector3) -> void:
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(type, pointer, target, at, at))


func _hit(target: Node3D, from: Vector3, toward: Vector3) -> Dictionary:
	var q := PhysicsRayQueryParameters3D.create(from, from + (toward - from).normalized() * 30.0, 1 << 20)
	q.exclude = [body.get_rid()]
	return target.get_world_3d().direct_space_state.intersect_ray(q)


## A held carve at `toward` from `from`, in skin `skin`.
func _alcove(work: Node3D, skin: String, from: Vector3, toward: Vector3, seconds: float) -> void:
	work.press("skin:" + skin)
	var target: Node3D = work.cave()
	pointer.global_position = from
	pointer.look_at(toward, Vector3.UP)
	var first := _hit(target, from, toward)
	if first.is_empty() or first.collider != target: return
	_report(XRToolsPointerEvent.Type.PRESSED, target, first.position)
	await create_timer(seconds).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, target, first.position)
	await _settled(work)


## A short sweep from a to b (points on the face, seen from `from`), in skin `skin`.
func _groove(work: Node3D, skin: String, from: Vector3, a: Vector3, b: Vector3) -> void:
	work.press("skin:" + skin)
	var target: Node3D = work.cave()
	pointer.global_position = from
	pointer.look_at(a, Vector3.UP)
	var first := _hit(target, from, a)
	if first.is_empty() or first.collider != target: return
	_report(XRToolsPointerEvent.Type.PRESSED, target, first.position)
	for i in 16:
		var aim := a.lerp(b, float(i + 1) / 16.0)
		pointer.look_at(aim, Vector3.UP)
		await physics_frame
		var h := _hit(target, from, aim)
		if not h.is_empty(): _report(XRToolsPointerEvent.Type.MOVED, target, h.position)
		await create_timer(0.07).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, target, first.position)
	await _settled(work)


## The skins whose materials the cave's meshes now carry.
func _skins_in(work: Node3D) -> Array:
	var found := {}
	for mesh in work.cave_meshes():
		for s in mesh.get_surface_count():
			var m: Material = mesh.surface_get_material(s)
			if m is ShaderMaterial: found[Cave.SKINS[int(m.get_shader_parameter("mode")) + 1]] = true
	return found.keys()


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
		if str(item.id).begins_with("boolean-cave-"): ids.append(str(item.id))
	for i in 2400:
		var all := true
		for id in ids:
			if not game.building.content.exhibits.has("%d/%s" % [floor_index, id]): all = false
		if all: break
		await physics_frame
	for id in ids:
		var mount: Node3D = game.building.content.exhibits.get("%d/%s" % [floor_index, id])
		var work: Node3D = mount.get_node_or_null("Artifact") if mount != null else null
		if work != null and work.has_method("state"):
			works[str(work.size)] = work
			work.keep = false
	for i in 240: await physics_frame
	level = float(game.building.spec.levels[floor_index]) + game.building.global_position.y
	body = game.body
	game.place_player(Vector3(0, level + 0.3, 7.8))      # the walker out of the way of every picture
	pointer = Node3D.new()
	game.add_child(pointer)
	eye = SubViewport.new()
	eye.size = Vector2i(1600, 1000)
	eye.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(eye)
	cam = Camera3D.new()
	eye.add_child(cam)
	cam.current = true
	if not (works.has("big") and works.has("small")):
		_finish(folder, result)
		return
	var big: Node3D = works["big"]
	var small: Node3D = works["small"]
	for w in [big, small]: await w.reset()

	# ---- the rack ----
	await _shot(small.to_global(Vector3(-2.35, 1.3, 1.2)), small.to_global(Vector3(-2.35, 1.05, 0.35)), folder.path_join("wardrobe_rack.png"), 50.0)

	# ---- big: two sets of seven alcoves ----
	var sets := [["latex", "pvc", "rubber", "leather", "chrome", "glitter", "sequin"], ["holo", "fishnet", "rainbow", "neon", "pearl", "velvet", "drag"]]
	var cut_all := {}
	for n in sets.size():
		await big.reset()
		big.brush = 0.0                                   # the smallest big brush: 0.55 m, seven alcoves fit the 7.6 m face
		for i in 7:
			var x := -3.15 + i * 1.05
			await _alcove(big, sets[n][i], big.to_global(Vector3(x, 1.5, 5.6)), big.to_global(Vector3(x, 1.3, -2.0)), 1.1)
		for s in _skins_in(big): cut_all[s] = true
		await _shot(big.to_global(Vector3(0.0, 2.2, 10.5)), big.to_global(Vector3(0.0, 1.3, 3.0)), folder.path_join("big_alcoves_%d.png" % (n + 1)), 55.0)
		await _shot(big.to_global(Vector3(-2.6, 1.55, 5.2)), big.to_global(Vector3(-2.1, 1.25, 2.8)), folder.path_join("big_close_%d_a.png" % (n + 1)), 55.0)
		await _shot(big.to_global(Vector3(2.4, 1.55, 5.2)), big.to_global(Vector3(2.1, 1.25, 2.8)), folder.path_join("big_close_%d_b.png" % (n + 1)), 55.0)
	_check("every skin of the wardrobe, worn by a carved stroke, is in the big cave's meshes", cut_all.size() == 14, {"skins": cut_all.keys()})

	# ---- small: fourteen grooves ----
	small.press("smaller")
	small.press("smaller")
	var face := 0.5
	var from := small.to_global(Vector3(0, 1.17, 1.6))
	var skins: Array = sets[0] + sets[1]
	for i in skins.size():
		var col := i / 7
		var row := i % 7
		var y := 0.82 + 0.06 + row * 0.095
		var x0 := -0.44 if col == 0 else 0.04
		await _groove(small, skins[i], from, small.to_global(Vector3(x0, y, face)), small.to_global(Vector3(x0 + 0.4, y, face)))
	var small_skins := _skins_in(small)
	_check("the small cave wears all fourteen skins in its grooves", small_skins.size() == 14, {"skins": small_skins})
	await _shot(small.to_global(Vector3(0.0, 1.17, 1.5)), small.to_global(Vector3(0.0, 1.17, 0.4)), folder.path_join("small_grooves.png"), 50.0)

	# ---- dressed blocks ----
	var surfaces_before := 0
	for m in small.cave_meshes(): surfaces_before += m.get_surface_count()
	small.dress_block("rainbow")
	var surfaces_after := 0
	for m in small.cave_meshes(): surfaces_after += m.get_surface_count()
	var block_mode := -2
	for m in small.cave_meshes():
		for s in m.get_surface_count():
			var mat: Material = m.surface_get_material(s)
			if mat == small._block_mat and mat is ShaderMaterial: block_mode = int(mat.get_shader_parameter("mode"))
	_check("DRESS swaps the block's own surfaces and nothing else (no re-cut, the strokes keep their skins)",
		surfaces_after == surfaces_before and block_mode == Cave.SKINS.find("rainbow") - 1 and _skins_in(small).size() >= 14,
		{"surfaces": [surfaces_before, surfaces_after], "block_mode": block_mode})
	await _shot(small.to_global(Vector3(0.9, 1.5, 1.4)), small.to_global(Vector3(0.0, 1.05, 0.0)), folder.path_join("small_dressed_rainbow.png"), 55.0)
	big.dress_block("latex")
	await _shot(big.to_global(Vector3(-4.5, 2.6, 9.0)), big.to_global(Vector3(0.0, 1.6, 0.0)), folder.path_join("big_dressed_latex.png"), 55.0)
	big.dress_block("chrome")
	await _shot(big.to_global(Vector3(4.5, 2.6, 9.0)), big.to_global(Vector3(0.0, 1.6, 0.0)), folder.path_join("big_dressed_chrome.png"), 55.0)

	# leave both as they were
	for w in [big, small]:
		w.dress_block("satin")
		await w.reset()
		w.press("skin:satin")
	result["passed"] = checks.all(func(c): return c.ok)
	_finish(folder, result)


func _finish(folder: String, result: Dictionary) -> void:
	var file := FileAccess.open(folder.path_join("wardrobe.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[boolean_cave_wardrobe] ", "PASSED" if result.passed else "FAILED")
	quit()
