# fractal_prune_op.gd — Selector as pruning via escape-time fractal.
# For each node, projects (x, z) to complex plane and iterates the chosen
# fractal function. Nodes whose iteration escapes (|z| > bailout) BEFORE
# max_iter are considered OUTSIDE the set and pruned. Nodes that stay
# bounded survive.
#
# Conceptually identical to CA_prune but with the "rule" being an
# iterated complex function instead of a neighbour count. The filter
# preserves the fractal's self-similar boundary in the surviving graph.
#
# Params:
#   fractal    — "mandelbrot" | "julia" | "burning_ship" | "tricorn"
#   julia_c    — [re, im] constant for julia (default [-0.7, 0.27])
#   max_iter   — bail-out iterations (default 40)
#   bailout    — escape threshold (default 4.0)
#   scale      — maps node XZ to complex plane. A position of (scale, 0)
#                becomes complex (scale, 0). Controls zoom. (default 1.5)
#   offset     — [re, im] offset applied to the complex mapping (default [0, 0])
#   invert     — if true, prune INSIDE the set instead of outside (default false)
#   preserve_root — root is kept regardless (default true)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var fractal: String = str(params.get("fractal", "mandelbrot"))
	var julia_c_arr = params.get("julia_c", [-0.7, 0.27])
	var julia_cr: float = float(julia_c_arr[0])
	var julia_ci: float = float(julia_c_arr[1]) if julia_c_arr.size() > 1 else 0.0
	var max_iter: int = int(params.get("max_iter", 40))
	var bailout: float = float(params.get("bailout", 4.0))
	var scale: float = float(params.get("scale", 1.5))
	var offset_arr = params.get("offset", [0.0, 0.0])
	var offset_r: float = float(offset_arr[0])
	var offset_i: float = float(offset_arr[1]) if offset_arr.size() > 1 else 0.0
	var invert: bool = bool(params.get("invert", false))
	var preserve_root: bool = bool(params.get("preserve_root", true))

	var should_keep: Array = []
	should_keep.resize(g.node_count())
	for i in g.node_count():
		should_keep[i] = true

	for idx in selected:
		if idx >= g.nodes.size():
			continue
		if preserve_root and idx < g.node_depth.size() and g.node_depth[idx] == 0:
			continue
		var p: Vector3 = g.nodes[idx]
		var cr: float = p.x / scale + offset_r
		var ci: float = p.z / scale + offset_i
		var in_set: bool = _in_set(fractal, cr, ci, julia_cr, julia_ci, max_iter, bailout)
		var prune: bool = (not in_set) if not invert else in_set
		if prune:
			should_keep[idx] = false

	_compact(g, should_keep)


static func _in_set(fractal: String, cr: float, ci: float, jr: float, ji: float,
		max_iter: int, bailout: float) -> bool:
	# Returns true if the point stays bounded for max_iter iterations.
	var zr: float = 0.0
	var zi: float = 0.0
	match fractal:
		"mandelbrot":
			zr = 0.0; zi = 0.0
			for _i in max_iter:
				var zr2: float = zr * zr - zi * zi + cr
				var zi2: float = 2.0 * zr * zi + ci
				zr = zr2; zi = zi2
				if zr * zr + zi * zi > bailout:
					return false
			return true
		"julia":
			zr = cr; zi = ci
			for _i in max_iter:
				var zr2: float = zr * zr - zi * zi + jr
				var zi2: float = 2.0 * zr * zi + ji
				zr = zr2; zi = zi2
				if zr * zr + zi * zi > bailout:
					return false
			return true
		"burning_ship":
			zr = 0.0; zi = 0.0
			for _i in max_iter:
				var zr2: float = zr * zr - zi * zi + cr
				var zi2: float = 2.0 * abs(zr * zi) + ci
				zr = zr2; zi = zi2
				if zr * zr + zi * zi > bailout:
					return false
			return true
		"tricorn":
			# Mandelbar — conjugate of Mandelbrot
			zr = 0.0; zi = 0.0
			for _i in max_iter:
				var zr2: float = zr * zr - zi * zi + cr
				var zi2: float = -2.0 * zr * zi + ci
				zr = zr2; zi = zi2
				if zr * zr + zi * zi > bailout:
					return false
			return true
	return true


static func _compact(g, keep: Array) -> void:
	var changed := true
	while changed:
		changed = false
		for i in g.parents.size():
			if keep[i] and g.parents[i] >= 0 and not keep[g.parents[i]]:
				keep[i] = false
				changed = true
	var mapping: PackedInt32Array = PackedInt32Array()
	mapping.resize(g.node_count())
	var new_idx: int = 0
	for i in g.node_count():
		if keep[i]:
			mapping[i] = new_idx
			new_idx += 1
		else:
			mapping[i] = -1

	var new_nodes: PackedVector3Array = PackedVector3Array()
	var new_radii: PackedFloat32Array = PackedFloat32Array()
	var new_parents: PackedInt32Array = PackedInt32Array()
	var new_tags: Array = []
	var new_depth: PackedInt32Array = PackedInt32Array()
	for i in g.node_count():
		if not keep[i]: continue
		new_nodes.append(g.nodes[i])
		new_radii.append(g.radii[i])
		new_tags.append(g.node_tags[i])
		new_depth.append(g.node_depth[i])
		var p: int = g.parents[i]
		new_parents.append(-1 if p < 0 else mapping[p])

	var new_edges: Array = []
	for e in g.edges:
		if keep[e[0]] and keep[e[1]]:
			new_edges.append([mapping[e[0]], mapping[e[1]]])

	g.nodes = new_nodes
	g.radii = new_radii
	g.parents = new_parents
	g.edges = new_edges
	g.node_tags = new_tags
	g.node_depth = new_depth
