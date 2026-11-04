extends "res://tools/probes/void_game_probe.gd"
## CANDIDATES ON THEIR FLOORS (Palle, 2026-11-03: "add the rest of the artifacts so I can see them in three editor and
## decide what will stay"). For each {floor, token} of a plan (doc/plans/spine-placement worklist rows that stand
## nowhere), in the actual tower: go to the floor, measure the artifact standing alone (its meshes' AABB after a
## settle), then find a spot on the floor where that footprint, grown by a walking margin, meets no body of the hall,
## stands over real floor under the ceiling, and keeps off the floor's route - preferring the spot nearest the route,
## so it is seen. Each spot chosen becomes an obstacle for the next. Writes placements.json; places nothing itself.
## Run: python tools/place_void_candidates.py --plan=<json>
const MARGIN := 0.5

var placed_boxes: Array = []   # StaticBody3D blockers for the spots already chosen

func run() -> void:
	var plan_path := ""
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out = arg.trim_prefix("--out=")
		if arg.begins_with("--plan="): plan_path = arg.trim_prefix("--plan=")
	Engine.physics_ticks_per_second = 90
	var plan: Array = JSON.parse_string(FileAccess.get_file_as_string(plan_path))
	var floors := {}
	for row in plan: floors[int(row.floor)] = true
	var first: int = int(plan[0].floor)
	preload("res://commons/void/room_source.gd").use_main_tower = true
	load("res://commons/void/game.gd").requested_floor = first
	game = load("res://commons/void/void.tscn").instantiate(); game.force_xr = false
	root.add_child(game); current_scene = game; game.scene_loaded(); game.scene_visible(); game.set_process_unhandled_key_input(false)
	game.body.scripted_input = true; game.body.set_process_unhandled_input(false)
	await frames(60)
	var levels: Array = game.building.spec.levels
	var results: Array = []
	for f in floors.keys():
		game.place_player(game.spawn_for(f)); await frames(90)
		var level: float = float(levels[f])
		var last := {}
		for row in plan:
			if int(row.floor) != f: continue
			var size := await measure(str(row.token))
			# a measured size (tools/probes/measure_true_aabb.gd: CSG, Label3D and slow builds counted) overrides the 30-frame read
			if row.has("size"): size = AABB(Vector3(-float(row.size[0]) * .5 + float(row.get("centre", [0, 0, 0])[0]), 0, -float(row.size[2]) * .5 + float(row.get("centre", [0, 0, 0])[2])), Vector3(float(row.size[0]), float(row.size[1]), float(row.size[2])))
			# near_previous: beside the spot chosen for the row before (a tape beside its object)
			var near: Array = [last.x, last.z] if row.get("near_previous", false) and not last.is_empty() else row.get("near", [])
			var spot := find_spot(f, level, size, near)
			if not spot.is_empty(): last = spot
			var res := {"row": row, "floor": f, "token": row.token, "footprint": [size.size.x, size.size.z, size.size.y], "origin_offset": [size.get_center().x, size.get_center().z], "spot": spot}
			results.append(res)
			print("CANDIDATE ", JSON.stringify(res))
			check("%s on floor %d: %s" % [row.token, f, ("(%.1f, %.1f) facing %d" % [spot.x, spot.z, spot.facing]) if not spot.is_empty() else "no spot (footprint %.1f x %.1f m)" % [size.size.x, size.size.z]], not spot.is_empty())
	FileAccess.open(out.path_join("placements.json"), FileAccess.WRITE).store_string(JSON.stringify(results, "  "))
	FileAccess.open(out.path_join("checks.json"), FileAccess.WRITE).store_string(JSON.stringify({"passed": failed.is_empty(), "checks": checks, "failed": failed}, "  "))
	print("[candidates] %d/%d placed" % [checks.size() - failed.size(), checks.size()])
	quit(0)

## The artifact standing alone far above the tower, its meshes' bounds in its own space after a settle.
func measure(token: String) -> AABB:
	var scene := registry_scene(token)
	if scene.is_empty() or not ResourceLoader.exists(scene): return AABB(Vector3(-0.5, 0, -0.5), Vector3(1, 1, 1))
	var packed: PackedScene = load(scene)
	var art: Node3D = packed.instantiate()
	var holder := Node3D.new(); holder.position = Vector3(0, 900, 0); game.add_child(holder); holder.add_child(art)
	await frames(30)
	var box := mesh_bounds(art)
	holder.queue_free(); await frames(2)
	if box.size.length() < 0.02: box = AABB(Vector3(-0.25, 0, -0.25), Vector3(0.5, 0.5, 0.5))
	return box

func registry_scene(token: String) -> String:
	for file in DirAccess.get_files_at("res://commons/artifacts/registry"):
		if not file.ends_with(".json"): continue
		var reg = JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry".path_join(file)))
		if reg is Dictionary:
			var arts = reg.get("artifacts", reg)
			if arts is Dictionary and arts.has(token) and arts[token] is Dictionary: return str(arts[token].get("scene", ""))
	return ""

func route_segments(f: int) -> Array:
	var segs: Array = []
	var r: Array = game.building.content.data.floors[f].get("route", [])
	for i in range(1, r.size()):
		segs.append([Vector2(r[i - 1].position[0], r[i - 1].position[1]), Vector2(r[i].position[0], r[i].position[1])])
	return segs

## near (optional [x, z]): prefer the clear spot closest to that point (a form's first encounter) over the route
func find_spot(f: int, level: float, box: AABB, near: Array = []) -> Dictionary:
	var space := game.get_world_3d().direct_space_state
	var ceiling := level + 6.0 - 0.36
	var height := minf(maxf(box.size.y, 0.3), ceiling - level - 0.15)
	var best := {}; var best_d := INF
	var segs := route_segments(f)
	for facing in [0, 90]:
		var basis := Basis(Vector3.UP, deg_to_rad(facing))
		var half := Vector3(box.size.x * 0.5 + MARGIN, height * 0.5, box.size.z * 0.5 + MARGIN)
		for xi in range(-40, 41):
			for zi in range(-17, 18):
				var origin := Vector3(xi * 0.5, level, zi * 0.5)
				var c: Vector3 = origin + basis * Vector3(box.get_center().x, 0, box.get_center().z)
				var centre := Vector3(c.x, level + 0.08 + height * 0.5, c.z)
				var q := PhysicsShapeQueryParameters3D.new(); var s := BoxShape3D.new(); s.size = half * 2.0
				q.shape = s; q.transform = Transform3D(basis, centre); q.collision_mask = 0xFFFFFFFF; q.exclude = [game.body.get_rid()]
				if not space.intersect_shape(q, 1).is_empty(): continue
				var ok := true
				for sx in [-1.0, 0.0, 1.0]:
					for sz in [-1.0, 0.0, 1.0]:
						var p: Vector3 = centre + basis * Vector3(half.x * sx, 0, half.z * sz)
						var hit := space.intersect_ray(PhysicsRayQueryParameters3D.create(Vector3(p.x, level + 0.4, p.z), Vector3(p.x, level - 0.4, p.z), 0xFFFFFFFF))
						if hit.is_empty() or absf(hit.position.y - level) > 0.08: ok = false; break
					if not ok: break
				if not ok: continue
				# off the route, and how near it (to be seen)
				var d := INF; var inv := Transform3D(basis, centre).affine_inverse()
				for seg in segs:
					for k in 21:
						var p2: Vector2 = (seg[0] as Vector2).lerp(seg[1], k / 20.0)
						var l: Vector3 = inv * Vector3(p2.x, centre.y, p2.y)
						var dx := maxf(absf(l.x) - half.x, 0.0); var dz := maxf(absf(l.z) - half.z, 0.0)
						d = minf(d, Vector2(dx, dz).length())
				if d < 0.35: continue
				var score := d if near.is_empty() else Vector2(origin.x - float(near[0]), origin.z - float(near[1])).length()
				if score < best_d: best_d = score; best = {"x": origin.x, "z": origin.z, "facing": facing, "to_route": d}
	if not best.is_empty():
		var blocker := StaticBody3D.new(); var cs := CollisionShape3D.new(); var bs := BoxShape3D.new()
		var basis2 := Basis(Vector3.UP, deg_to_rad(best.facing))
		bs.size = Vector3(box.size.x, height, box.size.z); cs.shape = bs; blocker.add_child(cs)
		var o := Vector3(best.x, level, best.z) + basis2 * Vector3(box.get_center().x, 0, box.get_center().z)
		blocker.transform = Transform3D(basis2, Vector3(o.x, level + 0.08 + height * 0.5, o.z))
		game.add_child(blocker); placed_boxes.append(blocker)
	return best
