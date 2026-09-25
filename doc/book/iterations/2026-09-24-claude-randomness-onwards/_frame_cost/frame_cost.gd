extends SceneTree
## Wall-clock per process frame with one scene in the tree, headless (no rendering),
## so the number is script + physics cost. Frames 0-2 are skipped (build), then the
## median of the next --frames deltas. An empty tree is measured first as the floor.
## Each result line is flushed to --out as it lands, so a hang still leaves the rest.
## usage: -- --spec=<abs json: [{label, scene, config}]> --out=<abs path> [--frames=6]

var _args := {}
var _out: FileAccess

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		if a.begins_with("--") and "=" in a:
			var kv := a.substr(2).split("=", true, 1)
			_args[kv[0]] = kv[1]
	_out = FileAccess.open(str(_args.get("out")), FileAccess.WRITE)
	_run.call_deferred()

func _line(s: String) -> void:
	print(s)
	_out.store_line(s)
	_out.flush()

## Godot's own monitors: seconds spent in _process and in _physics_process callbacks
## on the last frame, so frame pacing does not quantise the number.
func _measure(frames: int) -> int:
	var costs: Array = []
	for f in frames + 3:
		await process_frame
		if f >= 3:
			costs.append(int(1e6 * (Performance.get_monitor(Performance.TIME_PROCESS)
				+ Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS))))
	costs.sort()
	return costs[costs.size() / 2]

func _run() -> void:
	var frames := int(_args.get("frames", "6"))
	_line("FC floor median_us=%d" % await _measure(frames))
	var spec: Array = JSON.parse_string(FileAccess.get_file_as_string(str(_args.get("spec"))))
	for item: Dictionary in spec:
		var ps: PackedScene = load(str(item.scene))
		if ps == null:
			_line("FC %s LOAD_FAILED" % item.label)
			continue
		var n: Node = ps.instantiate()
		# the museum configures a body before _ready, with every #key of its token
		if n.has_method("apply_grid_config") and not (item.config as Dictionary).is_empty():
			n.call("apply_grid_config", item.config)
		root.add_child(n)
		var cost := await _measure(frames)
		_line("FC %s median_us=%d" % [item.label, cost])
		n.queue_free()
		await process_frame
		await process_frame
	_line("FC DONE")
	quit(0)
