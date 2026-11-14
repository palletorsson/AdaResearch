extends SceneTree
## THE BOOLEAN CAVE ON A BENCH (commons/artifacts/boolean_cave/; 2026-11-14). Headless, no tower: both sizes on a plain
## floor, painted through the same XRToolsPointerEvent reports the desktop crosshair and the VR pointer send.
##   - a press, held moves across the block and a release paint one stroke; once cut, its colour is in the cave
##   - a press held still DRILLS, at a bounded speed (it used to tunnel 7 m in half a second)
##   - a SLOW sweep paints a groove, not one hole (the drill used to move its anchor with every step)
##   - a press held while the pointer has turned off the block does not drill on (the old aim test skipped desktop)
##   - the console's buttons answer the pointer (CARVE / BUILD / shapes / sizes)
##   - big: before any carve a ray along the lane at chest height is stopped at the block's face (the negative); after
##     held carves and a walk in, the ray runs 4 m in, a standing body's capsule meets no surface along it, the floor
##     is 4 cm over the slab
##   - a BUILD aimed at the floor just ahead of the one in the tunnel is refused (it used to close over the legs)
##   - UNDO from inside the big block is refused; from outside it works (it used to shut the visitor in)
##   - one CUT a frame, bounded, as the cave grows (a flush used to cut every chunk at once: 50 - 182 ms)
##   - a save loads ONCE when the work is added and then configured, as the tower does (it used to load twice)
##   - undo (to the stroke's snapshot), reset, and a save -> reload round trip; the save named by the floor's map
##
##   godot --headless --path . --xr-mode off --script res://tools/probes/boolean_cave_bench.gd -- --out=<dir>
const Cave := preload("res://commons/artifacts/boolean_cave/boolean_cave.gd")
var checks := []
var out_dir := ""
var pointer: Node3D
var cam: Camera3D


func _initialize() -> void:
	_run.call_deferred()


func _check(name: String, ok: bool, data := {}) -> void:
	checks.append({"check": name, "ok": ok}.merged(data))
	print(("ok   " if ok else "NO   ") + name + "  " + JSON.stringify(data).left(260))


func _report(type: int, target: Node3D, at: Vector3, last := Vector3.ZERO) -> void:
	XRToolsPointerEvent.report(XRToolsPointerEvent.new(type, pointer, target, at, last))


func _hit(target: Node3D, from: Vector3, toward: Vector3, mask := 1 << 20) -> Dictionary:
	var space := target.get_world_3d().direct_space_state
	return space.intersect_ray(PhysicsRayQueryParameters3D.create(from, from + (toward - from).normalized() * 30.0, mask))


## Until everything painted is cut in, then two physics frames for the shapes to be met.
func _settle(work: Node3D = null) -> void:
	await process_frame
	var guard := 0
	while work != null and (not work.settled() or work._loading) and guard < 2000:
		await process_frame
		guard += 1
	await physics_frame
	await physics_frame


func _aim(from: Vector3, toward: Vector3) -> void:
	pointer.global_position = from
	if from.distance_to(toward) > 0.01: pointer.look_at(toward, Vector3.UP if absf((toward - from).normalized().y) < 0.99 else Vector3.RIGHT)


## A stroke as a person paints it: press where the ray meets the block, move the aim across `targets` (re-reading the
## hit each frame), release.
func _stroke(work: Node3D, from: Vector3, targets: Array, frames_per_target := 6, gap := 0.05) -> int:
	var target: Node3D = work.cave()
	var before: int = work.state().stamps
	_aim(from, targets[0])
	var first := _hit(target, from, targets[0])
	if first.is_empty(): return -1
	_report(XRToolsPointerEvent.Type.ENTERED, target, first.position, first.position)
	_report(XRToolsPointerEvent.Type.PRESSED, target, first.position, first.position)
	var last: Vector3 = first.position
	for i in range(1, targets.size()):
		for f in frames_per_target:
			var toward: Vector3 = (targets[i - 1] as Vector3).lerp(targets[i], float(f + 1) / float(frames_per_target))
			_aim(from, toward)
			await physics_frame
			var h := _hit(target, from, toward)
			if h.is_empty(): continue
			_report(XRToolsPointerEvent.Type.MOVED, target, h.position, last)
			last = h.position
			if gap > 0.0: await create_timer(gap).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, target, last, last)
	await _settle(work)
	return int(work.state().stamps) - before


## Press and hold still for `seconds`: the artifact drills on its own between events.
func _hold(work: Node3D, from: Vector3, toward: Vector3, seconds: float) -> int:
	var target: Node3D = work.cave()
	var before: int = work.state().stamps
	_aim(from, toward)
	var first := _hit(target, from, toward)
	if first.is_empty(): return -1
	_report(XRToolsPointerEvent.Type.PRESSED, target, first.position, first.position)
	await create_timer(seconds).timeout
	_report(XRToolsPointerEvent.Type.RELEASED, target, first.position, first.position)
	await _settle(work)
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


func _spread_x(work: Node3D, from_index: int) -> float:
	var xs := []
	for i in range(from_index, work._stamps.size()): xs.append(float(work._stamps[i].c[0]))
	return (xs.max() - xs.min()) if xs.size() > 1 else 0.0


func _run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): out_dir = arg.trim_prefix("--out=")
	DirAccess.make_dir_recursive_absolute(out_dir)
	var world := Node3D.new()
	root.add_child(world)
	var ground := StaticBody3D.new()
	var gshape := CollisionShape3D.new()
	var gbox := BoxShape3D.new()
	gbox.size = Vector3(120, 0.4, 120)
	gshape.shape = gbox
	ground.add_child(gshape)
	ground.position = Vector3(0, -0.2, 0)
	world.add_child(ground)
	pointer = Node3D.new()
	world.add_child(pointer)
	cam = Camera3D.new()
	world.add_child(cam)
	cam.global_position = Vector3(0, 60, 60)          # far from every work until a test stands it somewhere
	cam.current = true

	# ---- SMALL ----
	var small: Node3D = Cave.new()
	small.keep = false
	small.size = "small"
	small.position = Vector3(-6, 0, 0)
	world.add_child(small)
	await _settle(small)
	var mid := small.to_global(Vector3(0, 0.82 + 0.35, 0))
	var eye := small.to_global(Vector3(0, 1.45, 1.6))
	var n := await _stroke(small, eye, [mid + Vector3(-0.32, 0.1, 0.5), mid + Vector3(0.0, -0.05, 0.5), mid + Vector3(0.3, 0.12, 0.5)])
	var s1: Dictionary = small.state()
	_check("small: a press, held moves and a release paint one stroke of stamps", n >= 4 and int(s1.strokes) == 1, {"stamps": n, "state": s1})
	_check("small: once cut, the stroke's colour is in the cave and nothing waits", _colours(small).size() == 1 and int(s1.live) == 0 and small.settled(),
		{"colours": _colours(small)})
	var aim_at := mid + Vector3(0.05, 0.02, 0.5)
	var front_before := _hit(small.cave(), eye, aim_at)
	var zb: float = small.cave().to_local(front_before.position).z if not front_before.is_empty() else 9.0
	var t0 := Time.get_ticks_msec()
	n = await _hold(small, eye, aim_at, 1.5)
	var held := (Time.get_ticks_msec() - t0) / 1000.0
	var front_after := _hit(small.cave(), eye, aim_at)
	var za: float = small.cave().to_local(front_after.position).z if not front_after.is_empty() else -9.0
	var drilled := zb - za
	var r_small: float = small.radius()
	_check("small: held still, a carve drills - deeper, and no faster than DRILL radii per step at the brush's rate",
		drilled > 0.05 and drilled < r_small * (1.6 + Cave.DRILL * Cave.SPEC.small.rate * held), {"stamps": n, "drilled_m": snappedf(drilled, 0.001), "held_s": snappedf(held, 0.01)})

	# a SLOW sweep: 0.3 m across the face in 2.5 s, a MOVED every physics frame, as a VR ray reports
	var k0: int = small.state().stamps
	var sweep := []
	for i in 2: sweep.append(mid + Vector3(-0.2 + 0.3 * i, -0.15, 0.5))
	await _stroke(small, eye, sweep, 150, 0.0)
	var spread := _spread_x(small, k0)
	_check("small: a SLOW sweep paints a groove, not one hole (the drill keeps its anchor)", spread > 0.15, {"spread_m": snappedf(spread, 0.001), "stamps": int(small.state().stamps) - k0})

	# a press held while the pointer has turned OFF the block: no drilling on the old spot
	var k1: int = small.state().stamps
	var press_at := mid + Vector3(-0.25, 0.2, 0.5)
	_aim(eye, press_at)
	var ph := _hit(small.cave(), eye, press_at)
	_report(XRToolsPointerEvent.Type.PRESSED, small.cave(), ph.position, ph.position)
	_aim(eye, eye + Vector3(5, 0, 0))                   # the crosshair swung away, the button still down
	_report(XRToolsPointerEvent.Type.MOVED, small.cave(), eye + Vector3(1, 0, 0), ph.position)   # a camera-plane point
	await create_timer(1.2).timeout
	var drilled_away: int = int(small.state().stamps) - k1
	_report(XRToolsPointerEvent.Type.RELEASED, small.cave(), ph.position, ph.position)
	await _settle(small)
	_check("small: a press held while the pointer has turned off the block does not drill on", drilled_away <= 1, {"stamps_while_away": drilled_away})

	# ---- the console answers the pointer ----
	var after_each := {}
	for key in ["build", "cube", "bigger", "carve", "sphere"]:
		var b: Node3D = small.find_child("Button_" + key, true, false)
		if b == null: continue
		_report(XRToolsPointerEvent.Type.PRESSED, b, b.global_position, b.global_position)
		after_each[key] = [small.verb, small.shape, snappedf(small.radius(), 0.001)]
	_check("the console's buttons answer the pointer (verb, shape, brush)", after_each.get("build", [""])[0] == "build" and after_each.get("cube", ["", ""])[1] == "cube"
		and float(after_each.get("bigger", [0, 0, 0])[2]) > r_small and small.verb == "carve" and small.shape == "sphere", {"after_each": after_each})

	# ---- BIG: the negative, then held carves and a walk in ----
	var big: Node3D = Cave.new()
	big.keep = false
	big.size = "big"
	big.position = Vector3(12, 0, 0)
	world.add_child(big)
	await _settle(big)
	var lane_from := big.to_global(Vector3(0.0, 1.3, 5.5))
	var lane_to := big.to_global(Vector3(0.0, 1.3, -5.0))
	var face := _hit(big.cave(), lane_from, lane_to, 1)
	var face_z: float = big.cave().to_local(face.position).z if not face.is_empty() else -99.0
	var face_at: float = (Cave.SPEC.big.block as Vector3).z * 0.5
	_check("big, before any carve: a ray along the lane at chest height stops at the block's face (the check bites)", absf(face_z - face_at) < 0.05, {"stopped_at_z": snappedf(face_z, 0.001), "face_at": face_at})
	big.press("bigger")
	big.press("bigger")
	var stamps := 0
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
	_check("big: held carves walked in open a tunnel - the lane ray now runs past 4 m into the block", reach_z < -0.5, {"ray_stops_at_z": snappedf(reach_z, 0.001), "stamps": stamps, "state": big.state()})
	_check("big: and a standing body's capsule meets no surface along the first 3.2 m of it", clear.slice(0, 5).all(func(f): return f), {"clear": clear})
	_check("big: the carved floor is block material 4 cm over the slab", absf(floor_y - Cave.FLOOR) < 0.02, {"floor_y": snappedf(floor_y, 0.001)})

	# a BUILD aimed at the floor just ahead of the one standing in the tunnel: refused
	cam.global_position = big.to_global(Vector3(0, 1.6, 2.0))
	big.press("build")
	big.begin_stroke()
	var kb: int = big.state().stamps
	var floor_ahead := big.to_global(Vector3(0, Cave.FLOOR, 1.1))
	big._paint(floor_ahead, (floor_ahead - cam.global_position).normalized(), cam.global_position)
	var built: int = int(big.state().stamps) - kb
	big.end_stroke()
	big.press("carve")
	await _settle(big)
	_check("big: a BUILD on the floor just ahead of the one in the tunnel is refused (it would close over the legs)", built == 0, {"built": built})

	# UNDO from inside the block: refused; from outside: done
	var ku: int = big.state().stamps
	cam.global_position = big.to_global(Vector3(0, 1.6, 1.5))
	await big.undo()
	var inside_after: int = big.state().stamps
	var notice: String = big._notice
	cam.global_position = big.to_global(Vector3(0, 1.6, 6.5))
	await big.undo()
	var outside_after: int = big.state().stamps
	cam.global_position = Vector3(0, 60, 60)
	_check("big: UNDO from inside the block is refused (the solid would shut the visitor in); from outside it works",
		inside_after == ku and notice != "" and outside_after < ku, {"before": ku, "inside": inside_after, "outside": outside_after, "notice": notice})

	# ---- one cut a frame, bounded, as the cave grows ----
	var probe: Node3D = Cave.new()
	probe.keep = false
	probe.size = "big"
	probe.position = Vector3(45, 0, 0)
	world.add_child(probe)
	await _settle(probe)
	var rng := RandomNumberGenerator.new()
	rng.seed = 161
	var worst := 0.0
	var cuts := 0
	var samples := []
	for i in 160:
		var c := Vector3(rng.randf_range(-3.2, 3.2), rng.randf_range(0.8, 3.4), rng.randf_range(-3.0, 3.0))
		probe.stamp(c, "carve" if i % 7 else "build", ["sphere", "cube", "cylinder"][i % 3], rng.randf_range(0.55, 1.2), i / 8)
		if i % 6 == 5:
			probe._flush()
			while probe._pending() > 0:
				var t1 := Time.get_ticks_usec()
				probe._cut_one()
				var ms := (Time.get_ticks_usec() - t1) / 1000.0
				worst = maxf(worst, ms)
				cuts += 1
			if i in [5, 41, 83, 125, 155]: samples.append({"stamps": i + 1, "worst_cut_ms": snappedf(worst, 0.1), "triangles": probe.state().triangles})
			await process_frame
	_check("one cut a frame stays bounded as the cave grows to 160 stamps (six stamps per flush, as a stroke makes)", worst < 45.0 and int(probe.state().live) == 0,
		{"worst_cut_ms": snappedf(worst, 0.1), "cuts": cuts, "samples": samples})

	# ---- a save loads ONCE when the work is added and then configured, as the tower does ----
	var content := Node3D.new()
	content.name = "FloorContent"
	world.add_child(content)
	var floor_root := Node3D.new()
	floor_root.name = "Content999"
	floor_root.set_meta("map", "BenchMap")
	content.add_child(floor_root)
	var mount := Node3D.new()
	mount.name = "bench-cave"
	floor_root.add_child(mount)
	mount.position = Vector3(0, 0, 40)
	var recs := []
	for i in 30: recs.append({"c": [-3.0 + i * 0.2, 1.2, 2.0 - (i % 3) * 1.5], "a": [0, 0, -1], "v": "carve", "s": "sphere", "r": 0.7, "k": i / 10})
	DirAccess.make_dir_recursive_absolute("user://boolean_cave")
	var path := "user://boolean_cave/FloorContent_BenchMap_bench-cave_big.json"
	var f := FileAccess.open(path, FileAccess.WRITE)
	f.store_string(JSON.stringify({"size": "big", "stamps": recs}))
	f.close()
	var placed: Node3D = Cave.new()
	mount.add_child(placed)                                  # the tower: added (default size) ...
	placed.apply_grid_config({"size": "big", "keep": true})   # ... then configured
	for i in 10: await process_frame
	await _settle(placed)
	_check("a save loads ONCE when the work is added and then configured, and its key names the floor's map",
		int(placed.state().stamps) == 30 and placed.state().key == "FloorContent_BenchMap_bench-cave_big", {"stamps": placed.state().stamps, "key": placed.state().key})
	placed.keep = false
	DirAccess.remove_absolute(ProjectSettings.globalize_path(path))

	# ---- undo, reset, save and reload ----
	var before_undo: int = small.state().stamps
	await small.undo()
	_check("undo takes the last stroke back, to its snapshot", int(small.state().stamps) < before_undo, {"before": before_undo, "after": small.state().stamps})
	var kept: Node3D = Cave.new()
	kept.keep = true
	kept.size = "small"
	world.add_child(kept)
	await _settle(kept)
	await kept.reset()
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
	for i in 6: await process_frame
	await _settle(again)
	_check("what is painted is kept: saved, then replayed on load", saved > 0 and int(again.state().stamps) == saved and again.state().key == key, {"saved": saved, "reloaded": again.state().stamps, "key": key})
	await again.reset()
	_check("reset gives the block back", int(again.state().stamps) == 0 and int(again.state().strokes) == 0, {"state": again.state()})

	var passed := checks.all(func(c): return c.ok)
	var file := FileAccess.open(out_dir.path_join("bench.json"), FileAccess.WRITE)
	file.store_string(JSON.stringify({"passed": passed, "checks": checks}, "\t"))
	file.close()
	print("[boolean_cave_bench] ", "PASSED" if passed else "FAILED")
	quit()
