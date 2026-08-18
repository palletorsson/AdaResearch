extends SceneTree
## What stands across the corridor at a given z? Lists every collision shape
## whose world AABB crosses z=Z (world), with its owner chain and x-span.
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	var Z := 120.5
	for a in OS.get_cmdline_user_args():
		if String(a).begins_with("--z="): Z = float(String(a).substr(4))
	var m: Node3D = (load("res://commons/scenes/endless_museum.tscn") as PackedScene).instantiate() as Node3D
	m.set("_plan_path", "res://ada_run/em_plan.json"); m.set("_first_chapter", "primitives")
	get_root().add_child(m); await create_timer(0.8).timeout
	m.call("_build_segment"); await create_timer(0.3).timeout
	var stack: Array = [m]; var hits: Array = []
	while not stack.is_empty():
		var n: Node = stack.pop_back()
		for c in n.get_children(): stack.append(c)
		if n is CollisionShape3D and (n as CollisionShape3D).shape != null:
			var cs := n as CollisionShape3D
			var dm := cs.shape.get_debug_mesh()
			if dm == null: continue
			var b: AABB = cs.global_transform * dm.get_aabb()
			if b.position.z <= Z and b.position.z + b.size.z >= Z and b.position.y < 2.0 and b.position.y + b.size.y > 0.3:
				var chain := ""; var p: Node = n
				for i in range(4):
					if p == null: break
					chain = p.name + "/" + chain; p = p.get_parent()
				hits.append("x %5.1f..%5.1f  y %4.1f..%4.1f  z %6.1f..%6.1f  %s" % [b.position.x, b.position.x + b.size.x, b.position.y, b.position.y + b.size.y, b.position.z, b.position.z + b.size.z, chain])
	hits.sort()
	print("== colliders crossing z=%.1f: %d" % [Z, hits.size()])
	for h in hits: print("   ", h)
	var wc: Dictionary = m.get("_walk_cells"); var row := []
	for x in range(-2, 20): if wc.has(Vector2i(x, int(Z))): row.append(x)
	print("== walk cells at row %d: %s" % [int(Z), str(row)])
	quit(0)
