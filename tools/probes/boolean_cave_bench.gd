extends SceneTree
## THE BOOLEAN CAVE ON A BENCH (commons/artifacts/boolean_cave/; 2026-11-14). Headless, no tower: both sizes on a plain
## floor, painted through the same XRToolsPointerEvent reports the desktop crosshair and the VR pointer send.
##   - a press, held moves across the block and a release paint one stroke; after the flush its colour is in the cave
##   - a press held still DRILLS, at a bounded speed (it used to tunnel 7 m in half a second)
##   - the console's buttons answer the pointer (CARVE / BUILD / shapes / sizes)
##   - big: before any carve a ray along the lane at chest height is stopped at the block's face (the negative); after
##     a held carve and a walk in, the ray runs 4 m into the block, a standing body's capsule meets no surface along
##     it, and the floor is 4 cm over the slab
##   - no operand stays live after a flush; the cost of a flush as the cave grows
##   - undo (to the stroke's snapshot), reset, and a save -> reload round trip
##
##   godot --headless --path . --xr-mode off --script res://tools/probes/boolean_cave_bench.gd -- --out=<dir>
const Cave := preload("res://commons/artifacts/boolean_cave/boolean_cave.gd")
var checks := []
var out_dir := ""
var pointer: Node3D


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, data := {}) -> void:
	checks.append({"check": name, "ok": ok}.merged(data))
	print(("ok   " if ok else "NO   ") + name + "  " + JSON.stringify(data).left(260))


func _report(type: int, target: Node3D, at: Vector3, last := Vector3.ZERO) -> void:
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(type, pointer, target, at, last))


func _hit(cave_node: Node3D, from: Vector3, toward: Vector3, mask := 1 << 20) -> Dictionary:
	var space := cave_node.get_world_3d().direct_space_state
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + (toward - from).normalized() * 30.0, mask))


func _settle() -> void:
	await process_frame
	await physics_frame
	await physics_frame


## A stroke as a person paints it: press where the ray meets the block, move the aim across `targets` (re-reading the
## hit each frame), release.
func _stroke(work: Node3D, from: Vector3, targets: Array, frames_per_target := 6) -> int:
	var cave_node: Node3D = work.cave()
	var before: int = work.state().stamps
	pointer.global_position = from
	var first := _hit(cave_node, from, targets[0])
	if first.is_empty(): return -1
	_report(XRToolsPointerEvent.Type.ENTERED, cave_node, first.position, first.position)
	_report(XRToolsPointerEvent.Type.PRESSED, cave_node, first.position, first.position)
	var last: Vector3 = first.position
	for i in range(1, targets.size()):
		for f in frames_per_target:
			var aim: Vector3 = (targets[i - 1] as Vector3).lerp(targets[i], float(f + 1) / float(frames_per_target))
			await physics_frame
			var h := _hit(cave_node, from, aim)
			if h.is_empty(): continue
			_report(XRToolsPointerEvent.Type.MOVED, cave_node, h.position, last)
			last = h.position
			await create_timer(0.05).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, cave_node, last, last)
	await _settle()
	return int(work.state().stamps) - before


## Press and hold still for `seconds`: the artifact drills on its own between events.
func _hold(work: Node3D, from: Vector3, toward: Vector3, seconds: float) -> int:
	var cave_node: Node3D = work.cave()
	var before: int = work.state().stamps
	pointer.global_position = from
	var first := _hit(cave_node, from, toward)
	if first.is_empty(): return -1
	_report(XRToolsPointerEvent.Type.PRESSED, cave_node, first.position, first.position)
	await create_timer(seconds).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, cave_node, first.position, first.position)
	await _settle()
	return int(work.state().stamps) - before


func _capsule_meets_nothing(work: Node3D, points: Array, floor_y: float) -> Array:
	var space := (work as Node3D).get_world_3d().direct_space_state
	var cap := CapsuleShape3D.new()
	cap.radius = 0.3
	cap.height = 1.8
	var q := PhysicsShapeQueryParameters3D.new()
	q.shape = cap
	q.collision_mask = 1
	var out := []
	for p in points:
		q.transform = Transform3D(Basis.IDENTITY, Vector3(p.x, floor_y + 0.92, p.z))
		out.append(space.intersect_shape(q, 4).is_empty())
	return out


func _colours(work: Node3D) -> Array:
	var found := []
	for mesh in work.cave_meshes():
		for s in mesh.get_surface_count():
			var m: Material = mesh.surface_get_material(s)
			if m is StandardMaterial3D and not (m as StandardMaterial3D).albedo_color.is_equal_approx(Cave.SATIN):
				var key := str((m as StandardMaterial3D).albedo_color)
				if not key in found: found.append(key)
	return found


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(90, 0.4, 90)
	gshape.shape = gbox
	ground.add_child(gshape)
	ground.position = Vector3(0, -0.2, 0)
	world.add_child(ground)
	pointer = Node3D.new()
	world.add_child(pointer)

	# ---- SMALL ----
	var small: Node3D = Cave.new()
	small.keep = false
	small.size = "small"
	small.position = Vector3(-6, 0, 0)
	world.add_child(small)
	for i in 6: await process_frame
	await _settle()
	var mid := small.to_global(Vector3(0, 0.82 + 0.35, 0))
	var eye := small.to_global(Vector3(0, 1.45, 1.6))
	var n := await _stroke(small, eye, [mid + Vector3(-0.32, 0.1, 0.5), mid + Vector3(0.0, -0.05, 0.5), mid + Vector3(0.3, 0.12, 0.5)])
	var s1: Dictionary = small.state()
	_check("small: a press, held moves and a release paint one stroke of stamps", n >= 4 and int(s1.strokes) == 1, {"stamps": n, "state": s1})
	_check("small: after the flush, the stroke's colour is in the cave and no operand is left live", _colours(small).size() == 1 and int(s1.live) == 0 and int(s1.queued) == 0,
		{"colours": _colours(small)})
	var front_before := _hit(small.cave(), eye, mid + Vector3(0.05, 0.02, 0.5))
	var zb: float = small.cave().to_local(front_before.position).z if not front_before.is_empty() else 9.0
	var t0 := Time.get_ticks_msec()
	n = await _hold(small, eye, mid + Vector3(0.05, 0.02, 0.5), 1.5)
	var held := (Time.get_ticks_msec() - t0) / 1000.0
	var front_after := _hit(small.cave(), eye, mid + Vector3(0.05, 0.02, 0.5))
	var za: float = small.cave().to_local(front_after.position).z if not front_after.is_empty() else -9.0
	var drilled := zb - za
	var r_small: float = small.radius()
	_check("small: held still, a carve drills - deeper, and no faster than DRILL radii per step at the brush's rate",
		drilled > 0.05 and drilled < r_small * (1.6 + Cave.DRILL * Cave.SPEC.small.rate * held), {"stamps": n, "drilled_m": snappedf(drilled, 0.001), "held_s": snappedf(held, 0.01)})

	# ---- the console answers the pointer ----
	var after_each := {}
	for key in ["build", "cube", "bigger", "carve", "sphere"]:
		var b: Node3D = small.find_child("Button_" + key, true, false)
		if b == null: continue
		_report(XRToolsPointerEvent.Type.PRESSED, b, b.global_position, b.global_position)
		after_each[key] = [small.verb, small.shape, snappedf(small.radius(), 0.001)]
	_check("the console's buttons answer the pointer (verb, shape, brush)", after_each.get("build", [""])[0] == "build" and after_each.get("cube", ["", ""])[1] == "cube"
		and float(after_each.get("bigger", [0, 0, 0])[2]) > r_small and small.verb == "carve" and small.shape == "sphere", {"after_each": after_each})

	# ---- BIG: the negative, then a held carve and a walk in ----
	var big: Node3D = Cave.new()
	big.keep = false
	big.size = "big"
	big.position = Vector3(10, 0, 0)
	world.add_child(big)
	for i in 6: await process_frame
	await _settle()
	var lane_from := big.to_global(Vector3(0.0, 1.3, 5.5))
	var lane_to := big.to_global(Vector3(0.0, 1.3, -5.0))
	var face := _hit(big.cave(), lane_from, lane_to, 1)
	var face_z: float = big.cave().to_local(face.position).z if not face.is_empty() else -99.0
	_check("big, before any carve: a ray along the lane at chest height stops at the block's face (the check bites)", absf(face_z - 3.5) < 0.05, {"stopped_at_z": snappedf(face_z, 0.001)})
	big.press("bigger")
	big.press("bigger")
	var r_big: float = big.radius()
	var stamps := 0
	# hold at the face, then walk in twice and hold again, as a person carves their way in
	for step in 3:
		var from := big.to_global(Vector3(0, 1.6, 5.5 - step * 1.6))
		stamps += await _hold(big, from, big.to_global(Vector3(0.0, 1.35, -3.0)), 1.6)
	var reach := _hit(big.cave(), lane_from, lane_to, 1)
	var reach_z: float = big.cave().to_local(reach.position).z if not reach.is_empty() else -99.0
	var lane := []
	for i in 5: lane.append(big.to_global(Vector3(0.0, 0, 3.2 - i * 0.8)))
	var clear := _capsule_meets_nothing(big, lane, 0.04)
	var floor_hit := _hit(big.cave(), big.to_global(Vector3(0, 1.0, 1.5)), big.to_global(Vector3(0, -1.0, 1.5)), 1)
	var floor_y: float = big.cave().to_local(floor_hit.position).y if not floor_hit.is_empty() else -1.0
	_check("big: held carves walked in open a tunnel - the lane ray now runs past 4 m into the block", reach_z < -0.5, {"ray_stops_at_z": snappedf(reach_z, 0.001), "stamps": stamps, "radius": r_big, "state": big.state()})
	_check("big: and a standing body's capsule meets no surface along the first 3.2 m of it", clear.slice(0, 5).all(func(f): return f), {"clear": clear})
	_check("big: the carved floor is block material 4 cm over the slab", absf(floor_y - Cave.FLOOR) < 0.02, {"floor_y": snappedf(floor_y, 0.001)})

	# ---- the cost of a flush as the cave grows ----
	var probe: Node3D = Cave.new()
	probe.keep = false
	probe.size = "big"
	probe.position = Vector3(40, 0, 0)
	world.add_child(probe)
	for i in 4: await process_frame
	var rng := RandomNumberGenerator.new()
	rng.seed = 161
	var costs := []
	var worst := 0.0
	var worst_frame := 0.0
	var live_after := 0
	for i in 160:
		var c := Vector3(rng.randf_range(-3.2, 3.2), rng.randf_range(0.8, 3.4), rng.randf_range(-3.0, 3.0))
		probe.stamp(c, "carve" if i % 7 else "build", ["sphere", "cube", "cylinder"][i % 3], rng.randf_range(0.55, 1.2), i / 8)
		if i % 2 == 1:
			var t1 := Time.get_ticks_usec()
			probe._flush()
			var ms := (Time.get_ticks_usec() - t1) / 1000.0
			worst = maxf(worst, ms)
			live_after = maxi(live_after, int(probe.state().live))
			await process_frame
			var t3 := Time.get_ticks_usec()
			await process_frame
			var frame_ms := (Time.get_ticks_usec() - t3) / 1000.0
			worst_frame = maxf(worst_frame, frame_ms)
			if i in [1, 21, 41, 81, 121, 159]: costs.append({"stamps": i + 1, "flush_ms": snappedf(ms, 0.1), "next_frame_ms": snappedf(frame_ms, 0.1), "triangles": probe.state().triangles})
	_check("no operand stays live after a flush, and the frame after a flush pays nothing more (no deferred pass)", live_after == 0 and worst < 120.0 and worst_frame < 20.0,
		{"worst_flush_ms": snappedf(worst, 0.1), "worst_next_frame_ms": snappedf(worst_frame, 0.1), "costs": costs})

	# ---- undo, reset, save and reload ----
	var before_undo: int = small.state().stamps
	var t2 := Time.get_ticks_usec()
	await small.undo()
	var undo_ms := (Time.get_ticks_usec() - t2) / 1000.0
	_check("undo takes the last stroke back, to its snapshot", int(small.state().stamps) < before_undo and int(small.state().strokes) == 1, {"before": before_undo, "after": small.state().stamps, "undo_ms": snappedf(undo_ms, 0.1)})
	var kept: Node3D = Cave.new()
	kept.keep = true
	kept.size = "small"
	world.add_child(kept)
	for i in 4: await process_frame
	await kept.reset()
	await _settle()
	var kmid := kept.to_global(Vector3(0, 1.17, 0))
	var keye := kept.to_global(Vector3(0, 1.45, 1.6))
	await _stroke(kept, keye, [kmid + Vector3(-0.2, 0, 0.5), kmid + Vector3(0.2, 0.05, 0.5)])
	var saved: int = kept.state().stamps
	var key: String = kept.state().key
	world.remove_child(kept)
	kept.free()
	var again: Node3D = Cave.new()
	again.keep = true
	again.size = "small"
	world.add_child(again)
	for i in 20: await process_frame
	_check("what is painted is kept: saved, then replayed on load", saved > 0 and int(again.state().stamps) == saved and again.state().key == key, {"saved": saved, "reloaded": again.state().stamps, "key": key})
	await again.reset()
	_check("reset gives the block back", int(again.state().stamps) == 0 and int(again.state().strokes) == 0, {"state": again.state()})

	var passed := checks.all(func(c): return c.ok)
	var file := FileAccess.open(out_dir.path_join("bench.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks}, "\t"))
	file.close()
	print("[boolean_cave_bench] ", "PASSED" if passed else "FAILED")
	quit()
