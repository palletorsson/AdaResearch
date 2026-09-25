extends SceneTree
## Script cost per frame of one configured work: after --settle frames, call every
## script-defined _process / _physics_process in its subtree once and time it,
## five times; report the median sum. Engine physics and rendering are not included.
## usage: -- --spec=<abs json: [{label, scene, config}]> --only=a,b [--settle=60]

var _args := {}

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1]
	_run.call_deferred()

func _walk(n: Node, out: Array) -> void:
	var s: Script = n.get_script()
	if s != null:
		for m in s.get_script_method_list():
			if m.name == "_process" or m.name == "_physics_process":
				out.append([n, m.name])
	for c in n.get_children():
		_walk(c, out)

func _run() -> void:
	var only: Array = str(_args.get("only", "")).split(",")
	var spec: Array = JSON.parse_string(FileAccess.get_file_as_string(str(_args.get("spec"))))
	for item: Dictionary in spec:
		var hit := false
		for o in only:
			if o != "" and str(item.label).contains(o):
				hit = true
		if not hit:
			continue
		var n: Node = (load(str(item.scene)) as PackedScene).instantiate()
		if n.has_method("apply_grid_config") and not (item.config as Dictionary).is_empty():
			n.call("apply_grid_config", item.config)
		root.add_child(n)
		for f in int(_args.get("settle", "60")):
			await process_frame
		var calls: Array = []
		_walk(n, calls)
		var sums: Array = []
		for k in 5:
			var t0 := Time.get_ticks_usec()
			for c in calls:
				if is_instance_valid(c[0]) and (c[0] as Node).is_processing() if c[1] == "_process" else (c[0] as Node).is_physics_processing():
					(c[0] as Node).call(c[1], 1.0 / 60.0)
			sums.append(Time.get_ticks_usec() - t0)
			await process_frame
		sums.sort()
		print("SC %s callbacks=%d median_us=%d" % [str(item.label).left(90), calls.size(), sums[2]])
		n.queue_free()
		await process_frame
	print("SC DONE")
	quit(0)
