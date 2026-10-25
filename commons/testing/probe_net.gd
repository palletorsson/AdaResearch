extends SceneTree
## Does the net drape? `net_over_cube` is a 6 × 6 net of sphere colliders tied by springs,
## 0.2 m above a 0.8 m block, under the physics engine. After the run the knots over the cube's
## footprint must sit higher than the knots outside it (the net follows the outline), the net
## must have fallen, and no knot may have flown off (a spring that exploded). Report:
## ada_run/net_trace.json.
##
##   godot --headless --path . --xr-mode off --script res://commons/testing/probe_net.gd

const TICKS := 360

func _init() -> void:
	call_deferred("_run")


func _bodies(root: Node) -> Array:
	var out: Array = []
	var stack: Array = [root]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is RigidBody3D:
			out.append(n)
		for c in n.get_children():
			stack.append(c)
	return out


func _run() -> void:
	var scene: PackedScene = load("res://commons/modular/composite.tscn")
	var thing: Node = scene.instantiate()
	thing.set("term", "net_over_cube")
	root.add_child(thing)
	await process_frame
	await process_frame
	var knots: Array = _bodies(thing)
	var joints := 0
	var stack: Array = [thing]
	while not stack.is_empty():
		var n: Node = stack.pop_front()
		if n is Joint3D:
			joints += 1
		for c in n.get_children():
			stack.append(c)
	var y0: float = 0.0
	for k in knots:
		y0 += k.global_position.y
	y0 /= max(1, knots.size())
	for i in range(TICKS):
		await physics_frame
	var half := 0.5 * 1.6 / 2.0 + 0.05   # the cube is 0.5 m at scale 1.6 (a 0.8 m block), plus a knot's radius
	var inside: Array = []
	var outside: Array = []
	var flown := 0
	for k in knots:
		var p: Vector3 = k.global_position
		if p.length() > 6.0 or p.y < -2.0:
			flown += 1
		if abs(p.x) <= half and abs(p.z) <= half:
			inside.append(p.y)
		else:
			outside.append(p.y)
	var avg := func(a: Array) -> float:
		var s := 0.0
		for v in a:
			s += v
		return s / max(1, a.size())
	var y_in: float = avg.call(inside)
	var y_out: float = avg.call(outside)
	var y1: float = avg.call(inside + outside)
	var ok: bool = knots.size() == 36 and joints == 60 and flown == 0 and inside.size() > 0 and outside.size() > 0 and y1 < y0 - 0.1 and y_in > y_out + 0.1
	var report := {"probe": "net", "ticks": TICKS, "knots": knots.size(), "joints": joints, "flown": flown,
		"y_start": snapped(y0, 0.001), "y_end": snapped(y1, 0.001), "y_inside": snapped(y_in, 0.001), "y_outside": snapped(y_out, 0.001),
		"inside_count": inside.size(), "outside_count": outside.size(), "ok": ok,
		"claim": "the net falls, no knot flies off, and the knots over the cube stay higher than the knots beside it"}
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://ada_run"))
	var f := FileAccess.open("res://ada_run/net_trace.json", FileAccess.WRITE)
	f.store_string(JSON.stringify(report, "  "))
	f.close()
	print("NET ok=%s knots=%d joints=%d flown=%d y %.2f->%.2f inside %.2f outside %.2f (%d/%d)" % [ok, knots.size(), joints, flown, y0, y1, y_in, y_out, inside.size(), outside.size()])
	quit(0 if ok else 1)
