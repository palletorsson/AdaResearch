extends SceneTree
## WHEN CAN A WORK BE A PLAYGROUND? (Palle, 2026-11-11: "know when we can make a playground, for instance if we have
## a walkable surface that can scaffold with a playground structure.")
## One tower floor, each work (and each prop) rayed straight down on a 0.25 m grid: how much of it is ground to stand
## on, how high the first step from the slab is, how big the steps between neighbouring cells are. Then, optionally,
## the Void's own desktop walker is driven along waypoints - a ray is not a walk (a thin bar stops a body a ray misses).
##
##   godot --path <stage> --script res://tools/probes/void_standable.gd -- --no-bridges --void-start-floor=N
##       --out=<dir> [--step=0.25] [--settle=300] [--walk=x,z;x,z;x,z]
##
## standable.json per work: standable_m2 (near the slab 0.03-0.6 m, raised 0.6-2.6 m, high), steep_m2 (hit, but the
## surface is steeper than 45 degrees), entry_step (the lowest standable cell on the work's edge, metres over the slab),
## step_median / step_p90 (height change between neighbouring standable cells) and a verdict:
##   not ground      under 6 m2 to stand on - stage it, do not scaffold it
##   walkable        6 m2 or more, the first step is 0.35 m or less and neighbouring steps stay small - invite the visitor on
##   out of reach    6 m2 or more, but the first step is over 0.35 m - it needs a way up
##   rough           6 m2 or more and reachable, but neighbouring steps are large or over 8 % of it is steeper than 45
##                   degrees - coarsen it, or lay a deck across it
const NEAR := 0.6
const RAISED := 2.6
const STEP_OK := 0.35
const MIN_GROUND := 6.0
const STEEP_SHARE := 0.08
var game: Node3D

func _initialize() -> void:
	run.call_deferred()

func _visual_aabb(node: Node3D) -> AABB:
	var box := AABB()
	var first := true
	for n in node.find_children("*", "GeometryInstance3D", true, false):
		var g := n as GeometryInstance3D
		if not g.is_visible_in_tree() or g is Label3D or g.layers == 0:
			continue
		var local := g.get_aabb()
		if local.size.length() < 0.001 or local.size.length() > 80.0:
			continue
		var world := g.global_transform * local
		if first:
			box = world;first = false
		else:
			box = box.merge(world)
	return box

## The first hit that belongs to `owner_node`, casting down from the ceiling and stepping past anything else above it.
func _ray_down(space: PhysicsDirectSpaceState3D, x: float, z: float, top: float, bottom: float, owner_node: Node) -> Dictionary:
	var exclude: Array[RID] = []
	for _i in 8:
		var q := PhysicsRayQueryParameters3D.create(Vector3(x, top, z), Vector3(x, bottom, z), 1)
		q.exclude = exclude
		var hit := space.intersect_ray(q)
		if hit.is_empty():
			return {}
		var collider: Node = hit.collider
		if collider == owner_node or owner_node.is_ancestor_of(collider):
			return hit
		exclude.append(hit.rid)
	return {}

func _measure(space: PhysicsDirectSpaceState3D, node: Node3D, level: float, step: float, hw: float, hd: float) -> Dictionary:
	var box := _visual_aabb(node)
	if box.size.length() < 0.05:
		return {"verdict": "no mesh"}
	var x0 := maxf(box.position.x, -hw);var x1 := minf(box.end.x, hw)
	var z0 := maxf(box.position.z, -hd);var z1 := minf(box.end.z, hd)
	var nx := int(ceil((x1 - x0) / step));var nz := int(ceil((z1 - z0) / step))
	if nx <= 0 or nz <= 0 or nx * nz > 40000:
		return {"verdict": "outside the slab" if nx <= 0 or nz <= 0 else "too large to ray"}
	var heights := {}   # Vector2i -> height over the slab, standable cells only
	var steep := 0
	var near := 0;var raised := 0;var high := 0
	for iz in nz:
		for ix in nx:
			var hit := _ray_down(space, x0 + (ix + .5) * step, z0 + (iz + .5) * step, level + 5.4, level + 0.03, node)
			if hit.is_empty():
				continue
			var h: float = float(hit.position.y) - level
			if float(hit.normal.y) < 0.70:
				steep += 1
				continue
			heights[Vector2i(ix, iz)] = h
			if h <= NEAR: near += 1
			elif h <= RAISED: raised += 1
			else: high += 1
	var cell := step * step
	var steps: Array[float] = []
	var entry := INF
	for key in heights:
		var h: float = heights[key]
		var on_edge := false
		for d in [Vector2i(1, 0), Vector2i(-1, 0), Vector2i(0, 1), Vector2i(0, -1)]:
			var other: Vector2i = key + d
			if heights.has(other):
				if d.x > 0 or d.y > 0:
					steps.append(absf(float(heights[other]) - h))
			else:
				on_edge = true
		if on_edge:
			entry = minf(entry, h)
	steps.sort()
	var total := heights.size() * cell
	var median := steps[steps.size() / 2] if not steps.is_empty() else 0.0
	var p90 := steps[int(steps.size() * 0.9)] if not steps.is_empty() else 0.0
	var verdict := "not ground"
	if total >= MIN_GROUND:
		if entry > STEP_OK: verdict = "out of reach: the first step is %.2f m" % entry
		elif p90 > STEP_OK: verdict = "rough: nine in ten neighbouring steps are under %.2f m" % p90
		# a ray lands on a slope a body cannot climb: floor 90's fitted relief measured 'walkable' with 22 % of it steeper
		# than 45 degrees, and the walker stuck in a pocket after eight metres
		elif steep * cell > STEEP_SHARE * (total + steep * cell): verdict = "rough: %d %% of it is steeper than 45 degrees" % roundi(100.0 * steep * cell / (total + steep * cell))
		else: verdict = "walkable"
	return {"standable_m2": snappedf(total, .1), "near_m2": snappedf(near * cell, .1), "raised_m2": snappedf(raised * cell, .1), "high_m2": snappedf(high * cell, .1),
		"steep_m2": snappedf(steep * cell, .1), "entry_step": snappedf(entry, .01) if entry < INF else null, "step_median": snappedf(median, .01), "step_p90": snappedf(p90, .01),
		"box": [snappedf(x0, .01), snappedf(z0, .01), snappedf(x1, .01), snappedf(z1, .01)], "top": snappedf(box.end.y - level, .01), "verdict": verdict}

func run() -> void:
	var folder := ""
	var step := 0.25
	var settle := 300
	var walk: Array[Vector2] = []
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):folder = arg.trim_prefix("--out=")
		if arg.begins_with("--step="):step = float(arg.trim_prefix("--step="))
		if arg.begins_with("--settle="):settle = int(arg.trim_prefix("--settle="))
		if arg.begins_with("--walk="):
			for pair in arg.trim_prefix("--walk=").split(";", false):
				var xz := pair.split(",")
				walk.append(Vector2(float(xz[0]), float(xz[1])))
	DirAccess.make_dir_recursive_absolute(folder)
	load("res://commons/void/room_source.gd").use_main_tower = true
	game = load("res://commons/void/void.tscn").instantiate()
	root.add_child(game);current_scene = game
	game.body.scripted_input = true;game.body.set_process_unhandled_input(false)
	game.scene_loaded();game.scene_visible()
	var floor: int = game.checkpoint
	var record: Dictionary = game.building.content.data.floors[floor]
	for i in 900:
		if record.artifacts.all(func(a):return game.building.content.exhibits.has(str(floor) + "/" + a.id)):break
		await physics_frame
	for i in settle:await physics_frame
	var spec = game.building.spec
	var level: float = float(spec.levels[floor]) + game.building.global_position.y
	var hw: float = float(spec.width) / 2.0;var hd: float = float(spec.depth) / 2.0
	var space := game.get_world_3d().direct_space_state
	var works := {}
	for item in record.artifacts:
		var mount: Node3D = game.building.content.exhibits.get(str(floor) + "/" + str(item.id))
		if mount == null:continue
		var row := _measure(space, mount, level, step, hw, hd)
		row["artifact"] = str(item.artifact)
		works[str(item.id)] = row
	var props := {}
	for item in record.get("props", []):
		var found := game.find_children("Prop_" + str(item.id), "StaticBody3D", true, false)
		if found.is_empty():continue
		var row := _measure(space, found[0], level, step, hw, hd)
		row["kind"] = str(item.kind)
		props[str(item.id)] = row
	var out := {"floor": floor, "map": str(record.map), "step": step, "works": works, "props": props}
	# THE WALK: the desktop walker itself, driven forward at each waypoint in turn
	if walk.size() >= 2:
		var body: CharacterBody3D = game.body
		game.place_player(Vector3(walk[0].x, level + 0.3, walk[0].y))
		for i in 60:await physics_frame
		var legs := []
		for n in range(1, walk.size()):
			var target := walk[n]
			var best := INF;var ticks := 0;var highest := -INF;var lowest := INF
			while ticks < 900:
				var here := Vector2(body.global_position.x, body.global_position.z)
				var d := here.distance_to(target)
				best = minf(best, d)
				highest = maxf(highest, body.global_position.y - level);lowest = minf(lowest, body.global_position.y - level)
				if d < 0.35:break
				body.look_at(Vector3(target.x, body.global_position.y, target.y), Vector3.UP)
				body.drive = Vector2(0, -1)
				await physics_frame
				ticks += 1
			body.drive = Vector2.ZERO
			legs.append({"to": [target.x, target.y], "arrived": best < 0.35, "closest_m": snappedf(best, .01), "seconds": snappedf(ticks / float(Engine.physics_ticks_per_second), .1),
				"feet_from": snappedf(lowest, .01), "feet_to": snappedf(highest, .01), "stopped_at": [snappedf(body.global_position.x, .01), snappedf(body.global_position.y - level, .01), snappedf(body.global_position.z, .01)]})
			if best >= 0.35:break
		out["walk"] = legs
	var file := FileAccess.open(folder.path_join("standable.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify(out, "\t"))
	file.close()
	print("[standable] floor ", floor, " ", record.map, ": ", works.size(), " works, ", props.size(), " props")
	quit()
