extends SceneTree
## Diagnostic: does a freed sphere land on a block? One knot (sphere_collider at scale 0.3) is
## dropped from 0.8 m onto a 1.2 m block under the physics engine; then two knots tied by a
## rope; then a 3 × 3 net. Where each ends up tells whether falling bodies collide with the
## block at all, and whether the pins are what drives a net through it.

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


func _case(label: String, inner: Dictionary, block_scale: float = 2.4) -> String:
	var expr := {"op": "engine", "kind": "physics", "of": {"op": "compose", "parts": [
		{"op": "transform", "of": {"t": "cube"}, "scale": block_scale}, inner]}}
	var scene: PackedScene = load("res://commons/modular/composite.tscn")
	var thing: Node = scene.instantiate()
	thing.set("expression", JSON.stringify(expr))
	root.add_child(thing)
	await process_frame
	await process_frame
	var bodies: Array = _bodies(thing)
	var shapes := 0
	for b in bodies:
		for c in b.get_children():
			if c is CollisionShape3D and (c as CollisionShape3D).shape != null:
				shapes += 1
	var y0 := 0.0
	for b in bodies:
		y0 += b.global_position.y
	y0 /= max(1, bodies.size())
	for i in range(240):
		await physics_frame
	var y1 := 0.0
	var lowest := 99.0
	var half: float = 0.5 * block_scale / 2.0 + 0.05
	var y_in := 0.0
	var n_in := 0
	var y_out := 0.0
	var n_out := 0
	for b in bodies:
		var q: Vector3 = b.global_position
		y1 += q.y
		lowest = min(lowest, q.y)
		if abs(q.x) <= half and abs(q.z) <= half:
			y_in += q.y
			n_in += 1
		else:
			y_out += q.y
			n_out += 1
	y1 /= max(1, bodies.size())
	label += " [in %d: %.2f | out %d: %.2f]" % [n_in, y_in / max(1, n_in), n_out, y_out / max(1, n_out)]
	var lm := "%s/%s" % [str(bodies[0].collision_layer), str(bodies[0].collision_mask)] if bodies.size() else "-"
	var line := "%s: bodies=%d shapes=%d y %.2f -> %.2f (lowest %.2f) layer/mask=%s" % [label, bodies.size(), shapes, y0, y1, lowest, lm]
	thing.queue_free()
	await process_frame
	return line


func _run() -> void:
	var one := {"op": "transform", "of": {"t": "sphere_collider"}, "at": [0, 2.0, 0], "scale": 0.3}
	var pair := {"op": "connect", "a": 0, "b": 1, "kind": "rope", "of": {"op": "compose", "parts": [
		{"op": "transform", "of": {"t": "sphere_collider"}, "at": [-0.12, 2.0, 0], "scale": 0.3},
		{"op": "transform", "of": {"t": "sphere_collider"}, "at": [0.12, 2.0, 0], "scale": 0.3}]}}
	var parts: Array = []
	var ties: Array = []
	for i in range(3):
		for j in range(3):
			parts.append({"op": "transform", "of": {"t": "sphere_collider"}, "at": [(i - 1) * 0.25, 2.0, (j - 1) * 0.25], "scale": 0.3})
			if i < 2:
				ties.append([i * 3 + j, (i + 1) * 3 + j, "rope"])
			if j < 2:
				ties.append([i * 3 + j, i * 3 + j + 1, "rope"])
	var net := {"op": "connect", "ties": ties, "of": {"op": "compose", "parts": parts}}
	var grid := func(n: int, spacing: float, y: float) -> Dictionary:
		var ps: Array = []
		var ts: Array = []
		for i in range(n):
			for j in range(n):
				ps.append({"op": "transform", "of": {"t": "sphere_collider"}, "at": [(i - (n - 1) / 2.0) * spacing, y, (j - (n - 1) / 2.0) * spacing], "scale": 0.3})
				if i < n - 1:
					ts.append([i * n + j, (i + 1) * n + j, "rope"])
				if j < n - 1:
					ts.append([i * n + j, i * n + j + 1, "rope"])
		return {"op": "connect", "ties": ts, "of": {"op": "compose", "parts": ps}}
	print("DROP ", await _case("one knot", one))
	print("DROP ", await _case("two knots, rope", pair))
	print("DROP ", await _case("3x3 net, ropes", net))
	print("DROP ", await _case("6x6 net from 0.2 m over 1.2 m block", grid.call(6, 0.25, 1.65), 2.4))
	print("DROP ", await _case("6x6 net from 0.8 m over 1.2 m block", grid.call(6, 0.25, 2.25), 2.4))
	print("DROP ", await _case("6x6 net from 0.2 m over 0.8 m block", grid.call(6, 0.25, 1.25), 1.6))
	print("DROP ", await _case("the net TERM from 0.2 m over 1.2 m block", {"op": "transform", "of": {"t": "net"}, "at": [0, 1.65, 0]}, 2.4))
	quit(0)
