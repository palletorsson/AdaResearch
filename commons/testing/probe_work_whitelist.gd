extends SceneTree
## Can a map token actually SET the eleven new works?
##
## The whitelist was a hand-typed list of the original four, so after the axis
## grew every new value was silently rejected. This walks all fifteen through
## apply_grid_config the way the grid does, and asserts each one took.

func _init() -> void:
	var S := load("res://commons/artifacts/wall_abstract/wall_abstract.tscn")
	var works := ["divide_horizontal","divide_vertical","divide_diagonal",
		"divide_off_centre","horizon_soft","point_one","two_points",
		"segment_drawn","grid_regular","trace_once","corner_square",
		"cube_isometric","cube_wire","sphere_raking","chalk"]
	var fails := 0
	for w in works:
		var a = S.instantiate()
		get_root().add_child(a)
		await process_frame
		a.apply_grid_config({"work": w})
		await process_frame
		if a.work != w:
			print("  FAIL %-20s stayed '%s'" % [w, a.work]); fails += 1
		a.queue_free()
	print("%d/%d works settable from a map token" % [works.size() - fails, works.size()])

	# NEGATIVE: a value that is not in the enum must be refused, not accepted.
	var b = S.instantiate()
	get_root().add_child(b)
	await process_frame
	b.apply_grid_config({"work": "not_a_work"})
	await process_frame
	print("bogus value kept '%s' (must not be 'not_a_work')" % b.work)
	if b.work == "not_a_work":
		print("  FAIL the whitelist lets anything through"); fails += 1

	print("")
	print("PROBE OK" if fails == 0 else "PROBE FAILED (%d)" % fails)
	quit(fails)
