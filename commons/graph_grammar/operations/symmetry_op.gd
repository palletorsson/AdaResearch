# symmetry_op.gd — Post-process. Duplicate the ENTIRE current graph N
# times, each rotated around an axis by (i / N) * TAU. Produces mandala
# topologies, radially-symmetric creatures, N-fold snowflakes from any
# base recipe.
#
# This is a grammar modifier in the sense that it operates on the whole
# state, not on a selection. The `selected` argument is ignored.
#
# Params:
#   count       — fold count (default 4 → 4-fold symmetry)
#   axis        — rotation axis, "y" (default) | "x" | "z"
#   include_original — keep the original graph in addition to rotated copies (default true)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, _selected: PackedInt32Array) -> void:
	var count: int = clampi(int(params.get("count", 4)), 1, 24)
	if count <= 1:
		return
	var axis_name: String = str(params.get("axis", "y"))
	var axis: Vector3 = Vector3.UP
	match axis_name:
		"x": axis = Vector3.RIGHT
		"z": axis = Vector3.BACK
		_:   axis = Vector3.UP
	var include_original: bool = bool(params.get("include_original", true))

	# Snapshot the original graph state BEFORE any mutation
	var orig_nodes: Array = []
	var orig_radii: Array = []
	var orig_parents: Array = []
	var orig_edges: Array = []
	var orig_tags: Array = []
	var orig_depth: Array = []
	for i in g.nodes.size():
		orig_nodes.append(g.nodes[i])
		orig_radii.append(g.radii[i])
		orig_parents.append(g.parents[i])
		orig_tags.append(g.node_tags[i])
		orig_depth.append(g.node_depth[i])
	for e in g.edges:
		orig_edges.append([e[0], e[1]])

	# Optionally clear the original (if we want ONLY the rotated copies)
	if not include_original:
		g.nodes.clear(); g.radii.clear(); g.parents.clear()
		g.edges.clear(); g.node_tags.clear(); g.node_depth.clear()

	# For each fold 1..N-1 (or 0..N-1 if not include_original), add a
	# rotated copy. New parent indices are offset by the number of nodes
	# already present before each copy is added.
	var start_copy: int = 1 if include_original else 0
	for k in range(start_copy, count):
		var angle: float = (float(k) / float(count)) * TAU
		var basis := Basis(axis, angle)
		var offset: int = g.nodes.size()
		# Add each node of the snapshot, rotated
		for i in orig_nodes.size():
			var rotated_pos: Vector3 = basis * orig_nodes[i]
			var parent_orig: int = orig_parents[i]
			var parent_new: int = -1 if parent_orig < 0 else parent_orig + offset
			g.nodes.append(rotated_pos)
			g.radii.append(orig_radii[i])
			g.parents.append(parent_new)
			g.node_tags.append(orig_tags[i].duplicate())
			g.node_depth.append(orig_depth[i])
			if parent_new >= 0:
				g.edges.append([parent_new, offset + i])
