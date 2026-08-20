extends SceneTree
## GATE: THE GROUND IS WHAT YOU STAND ON (2026-08-20).
## Four claims, each with a negative half:
##   1. on flat deck the walker RESTS (is_on_floor, y ~ 0) — and its eye is still 1.65
##   2. dropped over a STAGE it lands ON the stage (y ~ the stage height), not through it
##   3. dropped over a GAP it FALLS (the hole bites) — the old clamp made this impossible
##   4. having fallen, the CATCH sets it down again on the last ground, and reloads nothing
##      (the segment count and the pearl cursor survive)
func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var fails: Array[String] = []
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json")
	m.set("_first_chapter", "primitives")
	m.set("start_map", "Point_Triangle_Context")     # the one pearl with a stage
	get_root().add_child(m)
	await create_timer(4.0).timeout
	var w: CharacterBody3D = m.get("_player")
	if w == null:
		print("EM GROUND: FAIL — no walker"); quit(1); return

	# 1. the flat deck holds, and the eye did not drop
	await _settle(m, w, Vector3(7.5, 0.5, 2.5))
	var rest_y: float = w.position.y
	var cam: Camera3D = m.get("_cam")
	print("[test] flat deck: rests at y %.3f, on_floor %s, eye %.2f" % [rest_y, str(w.is_on_floor()), cam.global_position.y])
	if absf(rest_y) > 0.06:
		fails.append("the flat deck does not hold the walker at 0 (y %.3f)" % rest_y)
	if not w.is_on_floor():
		fails.append("is_on_floor() is false standing on the deck — the capsule is floating again")
	if absf(cam.global_position.y - 1.65) > 0.08:
		fails.append("the eye moved: %.2f, was 1.65" % cam.global_position.y)

	# 2. a stage is a step, not a wall and not a floor to fall through
	# stage rect [2,6,6,4] h 0.4 -> tile z 6..9 == world z VESTIBULE_H+6 ..
	var vest: int = 4
	var sx: float = 4.5
	var sz: float = float(vest + 7) + 0.5
	await _settle(m, w, Vector3(sx, 1.6, sz))
	var stage_y: float = w.position.y
	print("[test] over the stage (%.1f, %.1f): rests at y %.3f (expected ~0.40)" % [sx, sz, stage_y])
	if absf(stage_y - 0.4) > 0.08:
		fails.append("a 0.4 m stage did not hold the walker at 0.4 (y %.3f)" % stage_y)

	# 3. THE NEGATIVE TEST: a hole must bite. Build the gap chapter and drop into it.
	m.queue_free()
	await create_timer(0.5).timeout
	var g: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	g.set("_plan_path", "res://ada_run/em_plan.json")
	g.set("_first_chapter", "transformation")
	g.set("start_map", "Trans_AxisDecomposition")     # the one pearl with a gap
	get_root().add_child(g)
	await create_timer(4.0).timeout
	var w2: CharacterBody3D = g.get("_player")
	var segs0: int = int(g.get("_seg_index"))
	# gap rect [3,8,6,4] -> tile x 3..8, z 8..11 == world z vest+8 ..
	var gx: float = 5.5
	var gz: float = float(vest + 9) + 0.5
	w2.position = Vector3(gx, 0.6, gz)
	w2.velocity = Vector3.ZERO
	var lowest: float = 999.0
	for i in range(90):
		await physics_frame
		lowest = minf(lowest, w2.position.y)
	print("[test] over the hollow (%.1f, %.1f): fell to y %.2f, now at %s, catches %d, segments %d -> %d" % [
		gx, gz, lowest, str(w2.position), int(g.get("_catches")), segs0, int(g.get("_seg_index"))])
	if lowest > -0.5:
		fails.append("THE HOLE DID NOT BITE: the walker never fell below %.2f over a hollow — the clamp is back" % lowest)
	# 4. the catch put it down again, and reloaded nothing
	if int(g.get("_catches")) < 1:
		fails.append("the walker fell but was never caught (catches 0)")
	if w2.position.y < -6.5:
		fails.append("the catch did not hold: still at y %.2f" % w2.position.y)
	if int(g.get("_seg_index")) < segs0:
		fails.append("the catch reloaded the museum: segments %d -> %d" % [segs0, int(g.get("_seg_index"))])
	g.queue_free()

	if fails.is_empty():
		print("EM GROUND: PASS — the deck holds, the stage is a step, the hollow bites, the catch sets you down")
	else:
		print("EM GROUND: FAIL %d" % fails.size())
		for f in fails: print("  - " + f)
	quit(0 if fails.is_empty() else 1)


func _settle(m: Node3D, w: CharacterBody3D, at: Vector3) -> void:
	w.position = at
	w.velocity = Vector3.ZERO
	for i in range(60):
		await physics_frame
