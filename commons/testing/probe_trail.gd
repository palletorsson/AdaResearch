extends SceneTree
## Does the trail engine keep stepping in the game, after its warm steps? Builds each trail term through the
## composite, runs it for about two seconds of frames and reads every trail_field: steps must grow beyond
## warm, the field must change, and the ant colony must keep delivering. A still shows only the warm state.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_trail.gd
## Writes ada_run/trail_probe.json; exit code = failures.

const COMPOSITE := "res://commons/modular/composite.tscn"
const Composite := preload("res://commons/modular/composite.gd")
const OUT := "res://ada_run/trail_probe.json"
const TERMS := ["pheromone_mark", "physarum", "ant_colony"]


func _init() -> void:
	call_deferred("_run")


func _fields(n: Node, out: Array) -> Array:
	if n.name == "trail_field" and n.get("steps") != null:
		out.append(n)
	for c in n.get_children():
		_fields(c, out)
	return out


func _run() -> void:
	var packed: PackedScene = load(COMPOSITE)
	var terms: Dictionary = Composite.terms()
	var report := {"terms": {}, "fails": 0}
	for tid in TERMS:
		if not terms.has(tid):
			report["terms"][tid] = {"error": "no such term"}
			report["fails"] += 1
			continue
		var c: Node = packed.instantiate()
		c.term = tid
		root.add_child(c)
		await process_frame
		var fs := _fields(c, [])
		var r := {"fields": fs.size()}
		if fs.is_empty():
			r["error"] = "no trail_field"
			report["fails"] += 1
		else:
			var f: Node = fs[0]
			var warm: int = int((terms[tid]["build"] as Dictionary).get("warm", 300))
			var s0: int = f.steps
			var d0: int = f.delivered
			var sum0: float = 0.0
			for v in f.f0:
				sum0 += v
			var t0 := Time.get_ticks_msec()
			while Time.get_ticks_msec() - t0 < 2000:
				await process_frame
			var sum1: float = 0.0
			for v in f.f0:
				sum1 += v
			r.merge({"warm": warm, "steps_before": s0, "steps_after": f.steps, "delivered_before": d0, "delivered_after": f.delivered,
				"field_sum_before": snappedf(sum0, 0.01), "field_sum_after": snappedf(sum1, 0.01)})
			var bad: Array = []
			if s0 < warm:
				bad.append("warm steps not run")
			if f.steps <= s0:
				bad.append("no steps in the game")
			if is_equal_approx(sum0, sum1):
				bad.append("field did not change")
			if tid == "ant_colony" and f.delivered <= d0:
				bad.append("no deliveries while running")
			r["problems"] = bad
			report["fails"] += int(not bad.is_empty())
		report["terms"][tid] = r
		print("TRAIL %s %s" % [tid, JSON.stringify(r)])
		c.queue_free()
		await process_frame
	var fh := FileAccess.open(OUT, FileAccess.WRITE)
	if fh != null:
		fh.store_string(JSON.stringify(report, "  "))
	print("TRAIL_PROBE fails=%d" % report["fails"])
	quit(int(report["fails"]))
