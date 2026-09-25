extends SceneTree
## Measure LineNetworkCA as shipped: per-frame cost after growth ends, and where its
## line endpoints fall relative to the node origin (the deck in CA_Introduction).
## usage: godot --headless --path . --script <this> -- [--runs=10] [--fit=...]

var _args := {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1]
	_run.call_deferred()

func _run() -> void:
	var runs := int(_args.get("runs", "10"))
	var below := 0
	var total := 0
	var ext_min := Vector3(INF, INF, INF)
	var ext_max := Vector3(-INF, -INF, -INF)
	var costs: Array = []
	for r in runs:
		seed(1000 + r)
		var n: Node3D = load("res://algorithms/cellularautomata/ca_showcase/LineNetworkCA.tscn").instantiate()
		if _args.has("fit"):
			n.call("apply_grid_config", {"fit": _args["fit"]})
		root.add_child(n)
		for f in 40:
			await process_frame
		# cost of one more frame's work, after growth has ended
		var t0 := Time.get_ticks_usec()
		if bool(n.get("is_running")):
			n.call("update_simulation", 0.016)
			n.call("update_visualization")
		costs.append(Time.get_ticks_usec() - t0)
		var lines: MeshInstance3D = n.get("mesh_instance_lines")
		var xf: Transform3D = n.global_transform.affine_inverse() * lines.global_transform
		for c in n.get("connections"):
			for p in [c[0], c[1]]:
				var q: Vector3 = xf * (p as Vector3)
				total += 1
				if q.y < 0.0:
					below += 1
				ext_min = ext_min.min(q)
				ext_max = ext_max.max(q)
		print("LNM run %d: gen %d running %s connections %d frame_cost_us %d" % [r, int(n.get("iteration_count")), str(n.get("is_running")), (n.get("connections") as Array).size(), costs[-1]])
		n.queue_free()
		await process_frame
	costs.sort()
	print("LNM endpoints %d, below origin %.1f%%, extent min %s max %s, median frame cost %d us" % [total, 100.0 * below / maxf(1, total), str(ext_min), str(ext_max), costs[costs.size() / 2]])
	print("LNM DONE")
	quit(0)
