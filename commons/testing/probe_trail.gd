extends SceneTree
## Do the time engines keep working in the game? Builds each term through the composite and runs it for about
## two seconds of frames. trail and pso: steps must grow beyond warm; a trail field must change and the ant colony
## keep delivering; a pso global best may only rise. A still shows only the warm state. A driven constraint
## (carousel): the hub must have turned and the free balls swung out beyond their resting radius.
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_trail.gd
## Writes ada_run/trail_probe.json; exit code = failures.

const COMPOSITE := "res://commons/modular/composite.tscn"
const Composite := preload("res://commons/modular/composite.gd")
const OUT := "res://ada_run/trail_probe.json"
const TERMS := ["pheromone_mark", "physarum", "ant_colony", "particle_swarm", "carousel"]


func _init() -> void:
	call_deferred("_run")


func _fields(n: Node, out: Array) -> Array:
	if (n.name == "trail_field" or n.name == "pso_field") and n.get("steps") != null:
		out.append(n)
	for c in n.get_children():
		_fields(c, out)
	return out


func _bodies_of(n: Node, cls: String, out: Array) -> Array:
	if n.is_class(cls):
		out.append(n)
	for k in n.get_children():
		_bodies_of(k, cls, out)
	return out


## the free balls' mean distance from the mast, at rest and after 2.5 s of the drive
func _carousel(c: Node) -> Dictionary:
	await process_frame
	await process_frame
	var balls: Array = _bodies_of(c, "RigidBody3D", [])
	var hubs: Array = _bodies_of(c, "AnimatableBody3D", [])
	var radius := func() -> float:
		var s := 0.0
		for b in balls:
			var p: Vector3 = (b as Node3D).global_position - (c as Node3D).global_position
			s += Vector2(p.x, p.z).length()
		return s / maxf(1.0, balls.size())
	var r0: float = radius.call()
	var a0: Vector3 = (hubs[0] as Node3D).global_position if not hubs.is_empty() else Vector3.ZERO
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < 2500:
		await physics_frame
	var r1: float = radius.call()
	var a1: Vector3 = (hubs[-1] as Node3D).global_position if not hubs.is_empty() else Vector3.ZERO
	var bad: Array = []
	if balls.size() != 4:
		bad.append("expected 4 free balls, found %d" % balls.size())
	if hubs.size() < 2:
		bad.append("expected the hub's cubes driven, found %d" % hubs.size())
	if r1 < r0 + 0.08:
		bad.append("the balls did not swing out")
	return {"balls": balls.size(), "driven": hubs.size(), "radius_rest": snappedf(r0, 0.001), "radius_driven": snappedf(r1, 0.001),
		"hub_moved": snappedf(a0.distance_to(a1), 0.001), "problems": bad}


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
		if tid == "carousel":
			var rr := await _carousel(c)
			report["fails"] += int(not (rr["problems"] as Array).is_empty())
			report["terms"][tid] = rr
			print("TRAIL %s %s" % [tid, JSON.stringify(rr)])
			c.queue_free()
			await process_frame
			continue
		var fs := _fields(c, [])
		var r := {"fields": fs.size()}
		if fs.is_empty():
			r["error"] = "no trail_field"
			report["fails"] += 1
		else:
			var f: Node = fs[0]
			var warm: int = int((terms[tid]["build"] as Dictionary).get("warm", 300))
			if f.name == "pso_field":
				var g0: float = f.gs
				var k0: int = f.steps
				var t1 := Time.get_ticks_msec()
				while Time.get_ticks_msec() - t1 < 2000:
					await process_frame
				r.merge({"warm": warm, "steps_before": k0, "steps_after": f.steps, "global_best_before": snappedf(g0, 0.0001), "global_best_after": snappedf(f.gs, 0.0001)})
				var pbad: Array = []
				if k0 < warm:
					pbad.append("warm steps not run")
				if f.steps <= k0:
					pbad.append("no steps in the game")
				if f.gs < g0 - 1e-6:
					pbad.append("global best fell")
				r["problems"] = pbad
				report["fails"] += int(not pbad.is_empty())
				report["terms"][tid] = r
				print("TRAIL %s %s" % [tid, JSON.stringify(r)])
				c.queue_free()
				await process_frame
				continue
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
