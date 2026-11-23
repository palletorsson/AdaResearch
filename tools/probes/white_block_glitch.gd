extends SceneTree
## The white block on Primitives_Prefab_Test: which way of hiding prefabs in the slabs gives the strangest walk?
## (Palle, 23 November 2026: "in the 10box can you figure out how we can place different hidden thing inside to get
## the most strange glitch effect, use prefabs".)
##
## For each value of the block's `hidden` the eye walks the carpet line through the block, from the pagoda to the far
## wall, 4 cm a step, looking a little to the side and up. Measured per way:
##   jump     how much of the picture changes from one step to the next (mean over the walk, 0..1 of full scale)
##   seen     the share of the picture that is not slab (a prefab showing)
##   still    how much the picture changes in half a second with the eye standing still (ten stops)
##   shimmer  how much it changes when the eye moves ONE millimetre (ten stops): two surfaces at one depth
##   eyes     how much the picture differs between two eyes 63 mm apart (every eighth step): what a headset's
##            two eyes disagree about
##   draws    draw calls in the frame, in the middle of the block
## and three frames of the walk are kept: the ones with the most prefab in them, a metre or more apart.
##
##   python tools/run_floor_probe.py Primitives_Prefab_Test white_block_glitch.gd glitch.json <folder> --no-opening --opera-quiet

const WAYS := ["primitives", "scatter", "giant", "coplanar", "grazing", "lattice", "turning", "sheared", "zones", "layered"]
const STEP := 0.04

var game: Node
var folder := "res://ada_run/white_block_glitch"
var result := {}
var eye: Camera3D
var floor_y := 0.0


func _initialize() -> void:
	run.call_deferred()


## Where the run stands, a line at a time (the engine's own log is written late).
func _note(text: String) -> void:
	var path := folder.path_join("progress.txt")
	var file := FileAccess.open(path, FileAccess.READ_WRITE) if FileAccess.file_exists(path) else FileAccess.open(path, FileAccess.WRITE)
	file.seek_end()
	file.store_line("%d ms  %s" % [Time.get_ticks_msec(), text])
	file.close()


func _frame() -> Image:
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()


## The share of a picture that is not slab: a slab is nearly white and nearly grey.
func _not_slab(picture: Image) -> float:
	var small := picture.duplicate() as Image
	small.resize(96, 60, Image.INTERPOLATE_BILINEAR)
	var n := 0
	for y in 60:
		for x in 96:
			var c := small.get_pixel(x, y)
			if c.s > 0.2 or c.v < 0.62: n += 1
	return n / 5760.0


func _change(a: Image, b: Image) -> float:
	return float(a.compute_image_metrics(b, false).get("mean", 0.0)) / 255.0


func run() -> void:
	var only := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): folder = arg.trim_prefix("--out=")
		if arg.begins_with("--only="): only = arg.trim_prefix("--only=")
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game); current_scene = game
	if game.body.get("scripted_input") != null:
		game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	game.scene_loaded(); game.scene_visible()
	var index := int(game.checkpoint)
	result = {"floor": index, "checks": [], "passed": false, "ways": {}}
	for i in 900: await physics_frame
	_note("booted")
	eye = root.get_camera_3d()
	var arrival := eye.global_position
	var ground := eye.get_world_3d().direct_space_state.intersect_ray(PhysicsRayQueryParameters3D.create(arrival, arrival + Vector3.DOWN * 4.0, 1))
	floor_y = float(ground.position.y) if not ground.is_empty() else arrival.y - 1.6
	var mount := game.building.content.exhibits.get("%d/white-block" % index) as Node3D
	var block := mount.get_node_or_null("Artifact") as Node3D if is_instance_valid(mount) else null
	if block == null:
		(result.checks as Array).append({"check": "the block stands on the floor", "ok": false})
		_done(); return
	game.body.set_physics_process(false)
	game.body.set_process(false)
	var side: float = block.get("side")
	var here := Vector3(block.global_position.x, floor_y + 1.65, block.global_position.z)
	var south := block.global_basis.z.normalized()
	var east := block.global_basis.x.normalized()
	var gaze := (-south * 1.0 + east * 0.55 + Vector3.UP * 0.2).normalized()
	var steps := int((side - 0.1) / STEP)          # inside the block only
	for way: String in WAYS:
		if only != "" and not only.split(",").has(way): continue
		_note("way %s" % way)
		block.call("apply_grid_config", {"hidden": way})
		for i in 900:
			await process_frame
			if bool(block.get("built")): break
		for i in 30: await process_frame
		_note("built %s" % block.get("built"))
		var record := {"things": (block.get("things") as Array).size(), "lattices": (block.get("grids") as Array).size(), "built": block.get("built")}
		# ------------------------------------------------------------ the walk
		var jump := 0.0
		var hardest := 0.0
		var seen := 0.0
		var eyes := 0.0
		var pairs := 0
		var before: Image = null
		var kept: Array = []           # [share, step, picture]
		for n in steps:
			var at := here + south * (side * 0.5 - 0.05 - n * STEP) + east * 0.3
			eye.global_position = at
			eye.look_at(at + gaze, Vector3.UP)
			var now: Image = await _frame()
			if n % 40 == 0: _note("step %d" % n)
			var share := _not_slab(now)
			seen += share
			if before != null:
				var d := _change(before, now)
				jump += d
				hardest = maxf(hardest, d)
			before = now
			if n % 8 == 4:
				# the other eye
				eye.global_position = at + eye.global_basis.x * 0.063
				eyes += _change(now, await _frame())
				pairs += 1
			# the three fullest frames, a metre or more apart
			var near := -1
			for k in kept.size():
				if absi(int(kept[k][1]) - n) * STEP < 1.0: near = k
			if near >= 0:
				if share > float(kept[near][0]): kept[near] = [share, n, now]
			elif kept.size() < 3: kept.append([share, n, now])
			else:
				var least := 0
				for k in kept.size():
					if float(kept[k][0]) < float(kept[least][0]): least = k
				if share > float(kept[least][0]): kept[least] = [share, n, now]
		record["jump"] = snappedf(jump / (steps - 1), 0.0001)
		record["hardest_step"] = snappedf(hardest, 0.0001)
		record["seen"] = snappedf(seen / steps, 0.0001)
		record["eyes"] = snappedf(eyes / maxi(pairs, 1), 0.0001)
		kept.sort_custom(func(a, b): return int(a[1]) < int(b[1]))
		for k in kept.size():
			(kept[k][2] as Image).save_png(folder.path_join("%s_%d.png" % [way, k + 1]))
		record["kept_at_m"] = kept.map(func(k): return snappedf(side * 0.5 - 0.05 - int(k[1]) * STEP, 0.01))
		# ------------------------------------------------------------ six stops: standing still, and one millimetre
		var still := 0.0
		var shimmer := 0.0
		for stop in 10:
			var at := here + south * (side * 0.5 - 0.9 - stop * (side - 1.8) / 9.0) + east * 0.3
			eye.global_position = at
			eye.look_at(at + gaze, Vector3.UP)
			var first: Image = await _frame()
			for i in 30: await process_frame
			var later: Image = await _frame()
			still += _change(first, later)
			eye.global_position = at - south * 0.001
			var moved: Image = await _frame()
			shimmer += _change(later, moved)
		record["still"] = snappedf(still / 10.0, 0.0001)
		record["shimmer"] = snappedf(shimmer / 10.0, 0.0001)
		# ------------------------------------------------------------ what it costs, and two fixed looks
		eye.global_position = here + east * 0.3
		eye.look_at(here + east * 0.3 + gaze, Vector3.UP)
		for i in 6: await process_frame
		record["draws"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME))
		record["primitives"] = int(Performance.get_monitor(Performance.RENDER_TOTAL_PRIMITIVES_IN_FRAME))
		# along a slab, looking up: the slab as a thin shaft with what crosses it
		eye.global_position = here + south * 1.31 - east * 2.6
		eye.look_at(eye.global_position + east * 1.0 + Vector3.UP * 0.55 - south * 0.03, Vector3.UP)
		(await _frame() as Image).save_png(folder.path_join("%s_along.png" % way))
		# from above, the slabs taken away: what stands in the block
		var slabs := block.get("walls") as Node3D
		slabs.visible = false
		eye.global_position = Vector3(here.x, floor_y, here.z) - south * 8.2 + east * 6.4 + Vector3.UP * 4.9
		eye.look_at(Vector3(here.x, floor_y + 2.0, here.z), Vector3.UP)
		for i in 4: await process_frame
		(await _frame() as Image).save_png(folder.path_join("%s_plan.png" % way))
		slabs.visible = true
		# nothing hidden reaches out of the block (the block tidies while somebody is near: stand in it a second first)
		eye.global_position = here
		for i in 70: await process_frame
		var out := 0.0
		var worst := {}
		for thing: Node3D in block.get("things"):
			var box: AABB = block.call("_local_box", thing)
			var past := maxf(maxf(-box.position.x, box.end.x) - side * 0.5, maxf(maxf(-box.position.z, box.end.z) - side * 0.5, maxf(box.end.y - float(block.get("height")), -box.position.y)))
			if past > out:
				out = past
				var parts := []
				for g in thing.find_children("*", "GeometryInstance3D", true, false):
					parts.append("%s:%s:%s" % [g.get_class(), g.name, (g as Node3D).is_visible_in_tree()])
				worst = {"name": str(thing.name), "plan": str(thing.get_meta("plan_id", "")), "box": [box.position.snappedf(0.01), box.end.snappedf(0.01)], "origin": thing.position.snappedf(0.01), "scale": thing.basis.get_scale().snappedf(0.01),
					"reach_now": snappedf(float(block.call("_own_reach", thing)), 0.01), "parts": parts.slice(0, 12)}
		record["furthest_outside_m"] = snappedf(out, 0.001)
		if out > 0.0: record["worst"] = str(worst)
		(result.ways as Dictionary)[way] = record
		(result.checks as Array).append({"check": "%s: built, and nothing reaches out of the block" % way, "ok": bool(block.get("built")) and out <= 0.02, "record": record})
		print("GLITCH ", way, " ", record)
		_save()          # a way at a time: the watchdog reads the file's age as progress
	_done()


func _save() -> void:
	result.passed = (result.checks as Array).all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("glitch.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "  "))
	file.close()


func _done() -> void:
	_save()
	quit()
