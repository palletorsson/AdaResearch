extends SceneTree

## PROBE — how high off the floor is the cloth_straps hem, and would auto-ground move it?
##
## SoftBodies_Cloth_Physics/final.md says "The hem, a hand above the floor". A checker
## called that unsupported on two grounds:
##   (1) rest arithmetic gives 0.15 m, but a 3.5 m sheet at linear_stiffness 0.34 keeps
##       stretching, so the settled hem might reach the floor;
##   (2) SoftBody3D IS a MeshInstance3D, and Godot resets its local transform to identity
##       (set_as_top_level(true); set_transform(Transform3D())) on the first transform
##       notification. If GridInteractablesComponent._compute_local_aabb then reads
##       child.transform * mesh.get_aabb() it would see y -1.75..1.75, min_y -1.75, and
##       _auto_ground_artifact would LIFT the whole artifact 1.75 m — hem at chest height.
##
## Both are measurable. This probe measures them.

const STRAPS := "res://algorithms/softbodies/cloth_straps/cloth_straps.tscn"


func _initialize() -> void:
	await _run()
	quit(0)


func _strips(n: Node) -> Array:
	var out: Array = []
	for c in n.find_children("*", "SoftBody3D", true, false):
		if c.visible:
			out.append(c)
	return out


## The lowest point of every strip, in WORLD space, read back from the physics server
## (the mesh resource is not written by the solver).
func _hem(strips: Array) -> float:
	var lowest: float = INF
	for sb in strips:
		var rid: RID = (sb as SoftBody3D).get_physics_rid()
		for i in (sb as SoftBody3D).mesh.surface_get_array_len(0):
			var p: Vector3 = PhysicsServer3D.soft_body_get_point_global_position(rid, i)
			lowest = minf(lowest, p.y)
	return lowest


func _top(strips: Array) -> float:
	var highest: float = -INF
	for sb in strips:
		var rid: RID = (sb as SoftBody3D).get_physics_rid()
		for i in (sb as SoftBody3D).mesh.surface_get_array_len(0):
			var p: Vector3 = PhysicsServer3D.soft_body_get_point_global_position(rid, i)
			highest = maxf(highest, p.y)
	return highest


## A byte-for-byte copy of GridInteractablesComponent._compute_local_aabb (line 2250),
## so what this prints is what auto-ground would actually see.
func _compute_local_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true
	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false
		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)
		if child is Node3D:
			var sub_aabb: AABB = _compute_local_aabb(child)
			if sub_aabb.size.length() > 0:
				sub_aabb = child.transform * sub_aabb
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)
	return result


func _report_aabb(label: String, straps: Node3D) -> void:
	var a: AABB = _compute_local_aabb(straps)
	var min_y: float = a.position.y
	var correction: float = -min_y
	var verdict: String = "no lift (already grounded, |min_y| < 0.01)"
	if absf(min_y) >= 0.01:
		if absf(correction) > 5.0:
			verdict = "SKIPPED by the 5.0 m cap"
		else:
			verdict = "WOULD SHIFT the artifact by %+.3f m" % correction
	print("  %-22s aabb min_y %+.3f  size.y %.3f  ->  %s" % [label, min_y, a.size.y, verdict])


## Stands exactly where GridInteractablesComponent._auto_ground_artifact stands: the
## first deferred flush after the artifact was parented.
func _grid_lane_deferred(straps: Node3D) -> void:
	var sb: SoftBody3D = null
	for c in straps.find_children("*", "SoftBody3D", true, false):
		if c.visible:
			sb = c
			break
	print("  >> AT THE GRID LANE'S DEFERRED CALL (first MessageQueue flush):")
	if sb != null:
		print("     strip[0].transform.origin = %s  top_level=%s"
			% [str(sb.transform.origin), str(sb.is_set_as_top_level())])
	_report_aabb("grid-lane deferred", straps)


func _run() -> void:
	print("probe_cloth_hem — SoftBodies_Cloth_Physics, token `cloth_straps#lesson:true`")
	print("")

	var straps: Node3D = load(STRAPS).instantiate()
	straps.set_meta("config_lesson", "true")   # exactly what the map token sets
	root.add_child(straps)
	straps.position = Vector3.ZERO             # the museum stamps the origin on the cell

	# THE GRID LANE'S EXACT TIMING. GridInteractablesComponent line 1337 does
	# `call_deferred("_auto_ground_artifact", ...)` immediately after add_child, so
	# what matters is what the AABB looks like at the FIRST MessageQueue flush —
	# not a frame later. Queue the same way and measure there.
	_grid_lane_deferred.call_deferred(straps)

	# ---- 1. the SoftBody3D local transform, which is what auto-ground reads ----
	print("1. WHAT _compute_local_aabb SEES (the auto-ground question)")
	await process_frame
	var strips: Array = _strips(straps)
	print("  strips built: %d" % strips.size())
	if strips.is_empty():
		print("  ABORT — no strips")
		return
	var sb0: SoftBody3D = strips[0]
	print("  strip[0].position as set in code : %s" % str(Vector3(0, 1.9, 0)))
	print("  strip[0].transform.origin frame 1: %s   top_level=%s"
		% [str(sb0.transform.origin), str(sb0.is_set_as_top_level())])
	_report_aabb("frame 1", straps)
	await process_frame
	print("  strip[0].transform.origin frame 2: %s   top_level=%s"
		% [str(sb0.transform.origin), str(sb0.is_set_as_top_level())])
	_report_aabb("frame 2 (deferred)", straps)
	await process_frame
	await process_frame
	print("  strip[0].transform.origin frame 4: %s   top_level=%s"
		% [str(sb0.transform.origin), str(sb0.is_set_as_top_level())])
	_report_aabb("frame 4", straps)
	print("")

	# ---- 2. where the hem actually settles ----
	print("2. WHERE THE HEM ACTUALLY IS (world y of the lowest point of any strip)")
	print("  rest arithmetic: centre 1.90 - half-height 1.75 = 0.150")
	var checkpoints := [1, 30, 60, 120, 300, 600, 1200, 2400]
	var frame: int = 0
	for target in checkpoints:
		while frame < int(target):
			await physics_frame
			frame += 1
		var h: float = _hem(strips)
		var t: float = _top(strips)
		print("  after %5d physics frames (%6.2f s):  hem y = %+.4f   top y = %+.4f   drop = %.4f"
			% [frame, float(frame) / 60.0, h, t, 0.15 - h])

	print("")
	var final_hem: float = _hem(strips)
	print("3. VERDICT")
	print("  settled hem  : %.4f m above the artifact origin" % final_hem)
	print("  artifact origin in the museum (ada_run/em_built.json bodies[8]): world y 0.0")
	print("  so the hem stands %.1f cm above the hall floor" % (final_hem * 100.0))
