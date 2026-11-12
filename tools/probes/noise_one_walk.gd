extends SceneTree
## NOISE_ONE: A LARGER TORUS, THE TERRAIN IN A PLAYGROUND BASIN, THE RING TO WALK (the Void, 2026-11-12)
## Palle: "make torus larger and make the walkable noise fit inside a playground scaffolding over shaft B". With
## the terrain over shaft B the ground by shaft A is free, and the bench ring lies flat round it as a walk.
## Read in the running tower, with its own walker:
##   the two bench rings are larger, clear of each other and under the ceiling;
##   the layered terrain is the activity of a kit pool over shaft B, fitted to the slot, lying on the pool's floor;
##     a body walks up the ramp, down into the basin and over the terrain;
##   the ring walk samples the same field as the bench rings (its own reader against the stand's field_value);
##     a body standing on the south half is lifted and set down by it; a body walks the whole ring;
##     FREEZE on the bench console holds the ground; the north half is flat; what a frame costs.
##
##   godot --path <stage> --script res://tools/probes/noise_one_walk.gd -- --no-bridges
##       --void-start-floor=<floor> --out=<dir>
##
## noise_one.json: checks with what was read. arrival.png, torus.png, basin.png, in_basin.png, ring.png, seam.png.
var game: Node3D
var level := 0.0


func _initialize() -> void:
	run.call_deferred()


func _go(body: CharacterBody3D, target: Vector3, ticks_max: int = 600) -> float:
	var best := INF
	var stuck := 0
	var last := body.global_position
	for i in ticks_max:
		var d := Vector2(body.global_position.x, body.global_position.z).distance_to(Vector2(target.x, target.z))
		best = minf(best, d)
		if d < 0.25: break
		body.look_at(Vector3(target.x, body.global_position.y, target.z), Vector3.UP)
		body.drive = Vector2(0, -1)
		await physics_frame
		if i % 20 == 19:
			stuck = stuck + 1 if body.global_position.distance_to(last) < 0.15 else 0
			last = body.global_position
			if stuck >= 2: body.jump_queued = true; stuck = 0
	body.drive = Vector2.ZERO
	for i in 20: await physics_frame
	return best


func _shot(cam: Camera3D, at: Vector3, target: Vector3, path: String) -> void:
	cam.global_position = at
	cam.look_at(target, Vector3.UP)
	cam.current = true
	for i in 4: await process_frame
	root.get_viewport().get_texture().get_image().save_png(path)
	cam.current = false


func _work(mount: Node3D, method: String) -> Node3D:
	for n in [mount] + mount.find_children("*", "Node3D", true, false):
		if n.has_method(method): return n
	return null


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
	var rows := {}
	var place = null
	for a in record.artifacts:
		if str(a.artifact) == "noisetorus": rows["torus"] = a
		if str(a.artifact) == "noise_ring_walk": rows["ring"] = a
		if str(a.artifact) == "playground_spec_hall" and a.config.has("place_spec"):
			for p in a.config.place_spec.get("places", []):
				if float(p.get("depth", 0)) > 0 and p.has("activity") and str(p.activity.artifact) == "noiselayers": rows["basin"] = a; place = p
	checks.append({"check": "the floor holds the pair of rings, the terrain as the activity of a kit pool, and the ring walk", "ok": rows.size() == 3, "found": rows.keys()})
	if rows.size() == 3:
		var mounts := {}
		for k in rows:
			var key := str(floor) + "/" + str(rows[k].id)
			for i in 900:
				if game.building.content.exhibits.has(key): break
				await physics_frame
			mounts[k] = game.building.content.exhibits.get(key)
		var pair: Node3D = _work(mounts.torus, "field_value")
		var ring: Node3D = _work(mounts.ring, "read_at")
		var stage: Node3D = null
		for i in 900:
			stage = _work(mounts.basin, "choose_layer")
			if stage != null and ring.following(): break
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
		var pool := Vector3(float(rows.basin.position[0]) + float(place.at[0]), level, float(rows.basin.position[1]) + float(place.at[1]))
		var hub: Vector3 = ring.global_position
		await _shot(cam, Vector3(0, level + 1.6, 7.8), Vector3(0, level + 2.0, 0), folder.path_join("arrival.png"))
		await _shot(cam, Vector3(0.6, level + 1.6, 4.6), Vector3(0, level + 3.0, -2.1), folder.path_join("torus.png"))
		await _shot(cam, pool + Vector3(6.6, 3.0, 7.4), pool + Vector3(-0.3, 0.6, 0.4), folder.path_join("basin.png"))
		await _shot(cam, pool + Vector3(0.4, 1.9, 2.4), pool + Vector3(-0.2, 0.3, -2.2), folder.path_join("in_basin.png"))
		await _shot(cam, hub + Vector3(1.6, 5.0, 8.5), hub + Vector3(0.0, 0.0, -0.8), folder.path_join("ring.png"))
		await _shot(cam, hub + Vector3(7.4, 1.6, 1.6), hub + Vector3(4.4, 0.1, -0.6), folder.path_join("seam.png"))

		# 1 the torus, larger
		var tops := []
		var spans := []
		var xs := []
		for r in pair.get("_rings"):
			var mesh: MeshInstance3D = r.mesh
			var box: AABB = mesh.global_transform * mesh.get_aabb()
			tops.append(box.end.y - level)
			spans.append(maxf(box.size.x, box.size.y))
			xs.append(box.get_center().x)
		var apart: float = absf(float(xs[1]) - float(xs[0]))
		checks.append({"check": "the two rings are larger, clear of each other and under the ceiling", "ok": float(spans.min()) >= 2.8 and apart > float(spans.max()) and float(tops.max()) < 5.3,
			"ring_across_m": snappedf(float(spans.min()), .01), "centres_apart_m": snappedf(apart, .01), "top_m": snappedf(float(tops.max()), .01)})

		# 2 the terrain in the kit pool
		var y: float = float(place.y)
		var depth: float = float(place.depth)
		var hz: float = float(place.size[1]) / 2.0
		var terrain: MeshInstance3D = stage.get("terrain") if stage != null else null
		var fitted := false
		var read := {}
		if terrain != null and terrain.mesh != null:
			var box: AABB = terrain.global_transform * terrain.mesh.get_aabb()
			read = {"across_m": snappedf(maxf(box.size.x, box.size.z), .01), "lowest_m": snappedf(box.position.y - level, .01), "highest_m": snappedf(box.end.y - level, .01),
				"off_middle_m": snappedf(Vector2(box.get_center().x - pool.x, box.get_center().z - pool.z).length(), .01)}
			fitted = float(read.across_m) <= float(place.size[0]) - 0.2 and float(read.across_m) >= float(place.size[0]) - 1.2 and absf(float(read.lowest_m) - (y - depth)) < 0.12 and float(read.highest_m) < y and float(read.off_middle_m) < 0.2
		checks.append({"check": "the terrain is fitted to the slot: as wide as the pool allows, its lowest valley on the pool's floor, its peaks under the rim", "ok": fitted, "terrain": read, "slot_m": place.size})
		var entry := pool + Vector3(-2.0 * y - 2.5, 0, hz + 2.0)
		var landing := pool + Vector3(0, y, hz + 2.0)
		game.place_player(Vector3(entry.x, entry.y + 0.3, entry.z))
		for i in 40: await physics_frame
		var reach := await _go(body, landing)
		var up: float = body.global_position.y - level
		checks.append({"check": "a body walks up the outer ramp to the rim", "ok": reach < 0.4 and absf(up - y) < 0.2, "feet_m": snappedf(up, .01)})
		reach = await _go(body, pool + Vector3(0, 0, 0.6))
		var low := INF
		var high := -INF
		var worst := 0.0
		for target in [Vector3(1.9, 0, 1.2), Vector3(1.6, 0, -1.9), Vector3(-1.8, 0, -1.6), Vector3(-1.9, 0, 1.4), Vector3(0, 0, 0)]:
			var got: float = await _go(body, pool + target, 360)
			worst = maxf(worst, got)
			low = minf(low, body.global_position.y - level)
			high = maxf(high, body.global_position.y - level)
		checks.append({"check": "and down into the basin and over the terrain, on ground that rises and falls", "ok": worst < 0.5 and high - low > 0.05 and low > (y - depth) - 0.05 and high < y and int(game.checkpoint) == floor,
			"furthest_from_a_goal_m": snappedf(worst, .01), "feet_m": [snappedf(low, .01), snappedf(high, .01)]})

		# 3 the ring walk
		checks.append({"check": "the ring walk takes its clock from the stand of two rings", "ok": ring.following()})
		var differ := 0.0
		var rng := RandomNumberGenerator.new()
		rng.seed = 94
		for i in 40:
			var sx: float = rng.randf_range(-0.4, 0.4)
			var sz: float = rng.randf_range(-0.4, 0.4)
			differ = maxf(differ, absf(float(ring.value_at(sx, sz)) - float(pair.field_value(sx, sz, float(pair.get("_pair_time"))))))
		checks.append({"check": "its reader gives the stand's own field at 40 points", "ok": differ < 0.0005, "largest_difference": snappedf(differ, .000001)})
		# stand still on the south half
		var south := hub + Vector3(0, 0, 5.2)
		game.place_player(south + Vector3(0, 0.6, 0))
		for i in 60: await physics_frame
		var feet_low := INF
		var feet_high := -INF
		var off := 0.0
		for tick in 480:
			await physics_frame
			var here: Vector3 = ring.to_local(body.global_position)
			var should: float = float(ring.read_at(here.x, here.z).get("height", 0.0))
			var feet: float = body.global_position.y - level
			feet_low = minf(feet_low, feet)
			feet_high = maxf(feet_high, feet)
			off = maxf(off, absf(feet - should))
		checks.append({"check": "a body standing still on the south half is lifted and set down by the field", "ok": feet_high - feet_low > 0.08 and off < 0.12 and int(game.checkpoint) == floor,
			"feet_m": [snappedf(feet_low, .01), snappedf(feet_high, .01)], "furthest_from_the_surface_m": snappedf(off, .01)})
		var ms_on: float = ring.frame_ms()
		for i in 240: await physics_frame
		ms_on = ring.frame_ms()
		# FREEZE holds the ground
		pair.toggle_pair_freeze()
		for i in 40: await physics_frame
		var held_a: float = body.global_position.y
		for i in 120: await physics_frame
		var held_b: float = body.global_position.y
		pair.toggle_pair_freeze()
		checks.append({"check": "FREEZE on the bench console holds the ground under the body", "ok": absf(held_b - held_a) < 0.004, "moved_m": snappedf(absf(held_b - held_a), .0001)})
		# the whole round
		var round_worst := 0.0
		var fell := false
		for step in range(1, 25):
			var angle: float = PI / 2.0 + TAU * float(step) / 24.0
			var got: float = await _go(body, hub + Vector3(cos(angle) * 5.2, 0, sin(angle) * 5.2), 300)
			round_worst = maxf(round_worst, got)
			if body.global_position.y < level - 0.4: fell = true
		checks.append({"check": "a body walks the whole ring, over the swells and across both seams", "ok": round_worst < 0.6 and not fell and int(game.checkpoint) == floor, "furthest_from_a_waypoint_m": snappedf(round_worst, .01)})
		# the north half is flat
		game.place_player(hub + Vector3(0, 0.5, -5.2))
		for i in 90: await physics_frame
		var flat: float = body.global_position.y - level
		var north: Dictionary = ring.read_at(0.0, -5.2)
		checks.append({"check": "the north half is flat: there the value is light", "ok": absf(flat) < 0.04 and bool(north.colour) and not bool(north.relief), "feet_m": snappedf(flat, .01), "light": snappedf(float(north.light), .01)})
		game.place_player(Vector3(-3.6, level + 0.3, 8.6))
		for i in 60: await physics_frame
		ring.frame_ms()
		for i in 240: await process_frame
		var ms_off: float = ring.frame_ms()
		checks.append({"check": "the ring costs little: next to nothing empty, about a millisecond with a body on it", "ok": ms_off < 0.15 and ms_on < 2.5,
			"ms_a_frame_empty": snappedf(ms_off, .001), "ms_a_frame_with_a_body": snappedf(ms_on, .001)})
		result["passed"] = checks.all(func(c): return c.ok)
	var file := FileAccess.open(folder.path_join("noise_one.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(result, "\t"))
	file.close()
	print("[noise_one_walk] ", "PASSED" if result.passed else "FAILED")
	quit()
