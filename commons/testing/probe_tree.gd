extends SceneTree
## What a segment IS, as a node tree: children by type, totals, and the cost
## per kind — measured, so "the cycle" can be talked about in numbers.
func _initialize() -> void: call_deferred("_run")
func _count(n: Node, acc: Dictionary) -> int:
	acc[n.get_class()] = int(acc.get(n.get_class(), 0)) + 1
	var total := 1
	for c in n.get_children(): total += _count(c, acc)
	return total
func _run() -> void:
	var t0 := Time.get_ticks_msec()
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	get_root().add_child(m)
	await create_timer(3.0).timeout
	print("[tree] museum children: %s" % str(m.get_children().map(func(c): return c.name)))
	var segs: Array = m.get("_segments")
	for i in range(segs.size()):
		var seg: Node3D = (segs[i] as Dictionary)["node"]
		var acc := {}
		var total := _count(seg, acc)
		var kinds := []
		for k in acc: kinds.append("%s %d" % [k, acc[k]])
		kinds.sort()
		print("[tree] seg %d (%s) z %.0f..%.0f — %d nodes: %s" % [i, seg.name.left(28),
			float((segs[i] as Dictionary)["z0"]), float((segs[i] as Dictionary)["z1"]), total, ", ".join(kinds)])
		var tops := []
		for c in seg.get_children(): tops.append("%s(%s)" % [c.name.left(18), c.get_class()])
		print("       top-level: %s" % ", ".join(tops.slice(0, 14)))
	var t1 := Time.get_ticks_msec()
	print("[tree] boot to two segments: %d ms" % (t1 - t0))
	# time one more segment
	var t2 := Time.get_ticks_msec()
	m.call("_build_segment")
	print("[tree] one more segment: %d ms" % (Time.get_ticks_msec() - t2))
	quit(0)
