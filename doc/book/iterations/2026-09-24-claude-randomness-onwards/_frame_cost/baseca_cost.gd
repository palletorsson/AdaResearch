extends SceneTree
## Per-frame script cost of BaseCA works after they have settled: time one
## update_simulation + update_visualization, as BaseCA._process runs them every frame.
## usage: -- --scenes=res://a.tscn,res://b.tscn [--frames=120]

var _args := {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1]
	_run.call_deferred()

func _find_ca(n: Node) -> Array:
	var out: Array = []
	if n.has_method("update_visualization") and n.get("is_running") != null:
		out.append(n)
	for c in n.get_children():
		out.append_array(_find_ca(c))
	return out

func _run() -> void:
	var frames := int(_args.get("frames", "120"))
	for path in str(_args.get("scenes", "")).split(","):
		var n: Node = load(path).instantiate()
		root.add_child(n)
		for f in frames:
			await process_frame
		for ca in _find_ca(n):
			var costs: Array = []
			for k in 5:
				var t0 := Time.get_ticks_usec()
				if bool(ca.get("is_running")):
					ca.call("update_simulation", 0.016)
					ca.call("update_visualization")
				costs.append(Time.get_ticks_usec() - t0)
			costs.sort()
			print("BCC %s :: %s running=%s iter=%s median_us=%d" % [path.get_file(), ca.name, str(ca.get("is_running")), str(ca.get("iteration_count")), costs[2]])
		n.queue_free()
		await process_frame
	print("BCC DONE")
	quit(0)
