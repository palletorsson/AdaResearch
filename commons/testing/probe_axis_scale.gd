extends SceneTree
## DOES uniform_scale SURVIVE apply_grid_config?
##
## axis_line REBUILDS itself when config arrives (`if _bar: _build()`), and
## _build() frees every child. The scale from `name:rot:y:SCALE` is applied to
## the ROOT, so it should survive a child rebuild — but "should" is what this
## checks, because the order (instantiate -> overrides -> deferred config) is
## exactly where a rebuild can eat a transform.

func _init() -> void:
	var S := load("res://commons/artifacts/axis_line/axis_line.tscn")
	var fails := 0

	# 1. plain
	var a = S.instantiate()
	get_root().add_child(a)
	await process_frame
	print("1  no scale set: root scale = %s" % a.scale)

	# 2. scale applied the way the grid applies it (to the root), THEN config —
	#    the same order GridInteractablesComponent uses.
	var b = S.instantiate()
	get_root().add_child(b)
	await process_frame
	b.scale = Vector3(4, 4, 4)
	b.apply_grid_config({"orientation": "diagonal_2"})
	await process_frame
	await process_frame
	print("2  scale 4 then config: root scale = %s  orientation = %s"
		% [b.scale, b.orientation])
	if absf(b.scale.x - 4.0) > 0.001:
		print("   FAIL the rebuild ate the scale"); fails += 1
	if b.orientation != "diagonal_2":
		print("   FAIL orientation did not take"); fails += 1

	# 3. and the mesh really is 4x longer in world terms
	var mesh: MeshInstance3D = null
	for c in b.get_children():
		if c is MeshInstance3D:
			mesh = c
	var world_len: float = mesh.mesh.size.x * b.scale.x if mesh else 0.0
	print("3  bar length in world = %.2f m (1.6 x 4 = 6.4)" % world_len)
	if absf(world_len - 6.4) > 0.01:
		print("   FAIL scale is not reaching the geometry"); fails += 1

	# 4. and the angle is still the diagonal, not reset by the rebuild
	var deg: float = rad_to_deg(mesh.rotation.z) if mesh else 0.0
	print("4  stroke angle = %.0f degrees (diagonal_2 = -45)" % deg)
	if absf(deg + 45.0) > 1.0:
		print("   FAIL orientation lost in the rebuild"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
