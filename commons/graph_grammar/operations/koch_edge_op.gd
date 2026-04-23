# koch_edge_op.gd — Recursively subdivide each selected edge into a Koch
# bump (or the straight middle third, or a triangular spike) at depth N.
# Each edge becomes 4 smaller edges per subdivision level, with a
# triangular displacement at the middle.
#
# Puts the Koch fractal INSIDE the grammar: instead of being a standalone
# body recipe, it's an op you can chain — "grow a tree, then fractalize
# every branch edge." The depth is a DNA knob.
#
# Params:
#   depth       — recursion depth per edge (default 2, capped at 4)
#   bump_height — fraction of edge length for the bump (default 0.33)
#   axis        — "xy" (flat) | "xz" (flat ground) | "random" (default "random")
#   preserve_root_edge — don't subdivide edges touching the root (default false)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, _selected: PackedInt32Array) -> void:
	var depth: int = clampi(int(params.get("depth", 2)), 1, 4)
	var bump: float = float(params.get("bump_height", 0.33))
	var axis: String = str(params.get("axis", "random"))
	var preserve_root_edge: bool = bool(params.get("preserve_root_edge", false))

	# We process all edges at start, then repeat for each depth pass.
	for _pass in depth:
		var edges_snapshot: Array = []
		for e in g.edges:
			edges_snapshot.append([e[0], e[1]])
		g.edges.clear()
		for e in edges_snapshot:
			var a_idx: int = e[0]
			var b_idx: int = e[1]
			if preserve_root_edge and g.parents[a_idx] < 0:
				g.edges.append([a_idx, b_idx])
				continue
			if a_idx >= g.nodes.size() or b_idx >= g.nodes.size():
				g.edges.append([a_idx, b_idx])
				continue
			_koch_subdivide(g, a_idx, b_idx, bump, axis)


static func _koch_subdivide(g, a_idx: int, b_idx: int, bump_height: float, axis: String) -> void:
	var a: Vector3 = g.nodes[a_idx]
	var b: Vector3 = g.nodes[b_idx]
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 0.01:
		g.edges.append([a_idx, b_idx])
		return
	var edge_dir: Vector3 = dir / length
	# Third-points p1 and p3 — at 1/3 and 2/3 along the edge
	var p1: Vector3 = a + dir * (1.0 / 3.0)
	var p3: Vector3 = a + dir * (2.0 / 3.0)
	# The tip p2 is perpendicular to the edge by bump_height * length
	var perp: Vector3 = _perpendicular(edge_dir, axis)
	var p2: Vector3 = (a + dir * 0.5) + perp * (bump_height * length)

	var radius: float = (g.radii[a_idx] + g.radii[b_idx]) * 0.5
	var depth_val: int = g.node_depth[a_idx]
	# Add the three new nodes, keeping the original a and b
	var i1: int = g.add_node(p1, radius, a_idx, PackedStringArray(["koch"]))
	var i2: int = g.add_node(p2, radius, i1,    PackedStringArray(["koch"]))
	var i3: int = g.add_node(p3, radius, i2,    PackedStringArray(["koch"]))
	# Reparent b to i3
	g.parents[b_idx] = i3
	# Re-emit edges: a -> i1 -> i2 -> i3 -> b (i1, i2, i3 edges come from add_node)
	g.edges.append([i3, b_idx])


static func _perpendicular(edge_dir: Vector3, axis: String) -> Vector3:
	match axis:
		"xy":
			# Rotate 90° around Z — always lies in XY plane
			return Vector3(-edge_dir.y, edge_dir.x, 0.0).normalized()
		"xz":
			# Rotate 90° around Y — lies in XZ plane
			return Vector3(-edge_dir.z, 0.0, edge_dir.x).normalized()
		_:
			# "random": pick any perpendicular (via cross with an arbitrary axis)
			var any: Vector3 = Vector3.UP if abs(edge_dir.y) < 0.9 else Vector3.RIGHT
			return edge_dir.cross(any).normalized()
