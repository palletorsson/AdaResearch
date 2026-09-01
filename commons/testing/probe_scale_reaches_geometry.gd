extends SceneTree
## DOES uniform_scale ACTUALLY MAKE THE THING BIGGER?
##
## Palle: "scale does not apply and the scale does not work for
## walk_this_line_marking either."
##
## The grid log says otherwise — "Applied uniform scale: 4.0" prints for BOTH
## artifacts — so either the log is lying or the geometry is not following the
## root. This measures the merged world AABB of every MeshInstance3D at scale 1
## and at scale 4 and divides. Nothing here trusts a print statement.

func _init() -> void:
	var fails := 0
	for path in ["res://commons/artifacts/axis_line/axis_line.tscn",
				 "res://commons/artifacts/walk_this_line_marking/walk_this_line_marking.tscn"]:
		var S := load(path)
		var a = S.instantiate()
		get_root().add_child(a)
		await process_frame
		await process_frame
		var s1: Vector3 = _extent(a)

		var b = S.instantiate()
		get_root().add_child(b)
		b.scale = Vector3(4, 4, 4)
		await process_frame
		await process_frame
		var s4: Vector3 = _extent(b)

		var nm: String = path.get_file()
		if s1.length() < 0.0001:
			print("%-34s NO MESHES to measure" % nm)
			continue
		var ratio: float = s4.length() / s1.length()
		print("%-34s  x1 = %s" % [nm, s1])
		print("%-34s  x4 = %s   ratio = %.2f" % ["", s4, ratio])
		if absf(ratio - 4.0) > 0.05:
			print("   FAIL scale is not reaching the geometry (want 4.00)")
			fails += 1
		a.queue_free()
		b.queue_free()
		await process_frame

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)


## Merged world-space size of every MeshInstance3D under n.
func _extent(n: Node) -> Vector3:
	var have := false
	var lo := Vector3.ZERO
	var hi := Vector3.ZERO
	var stack: Array = [n]
	while not stack.is_empty():
		var m = stack.pop_back()
		for c in m.get_children():
			stack.append(c)
		if m is MeshInstance3D and m.mesh != null:
			var ab: AABB = (m as MeshInstance3D).global_transform * m.mesh.get_aabb()
			if not have:
				lo = ab.position
				hi = ab.position + ab.size
				have = true
			else:
				lo = Vector3(minf(lo.x, ab.position.x), minf(lo.y, ab.position.y), minf(lo.z, ab.position.z))
				hi = Vector3(maxf(hi.x, ab.end.x), maxf(hi.y, ab.end.y), maxf(hi.z, ab.end.z))
	return (hi - lo) if have else Vector3.ZERO
