# subdivide_edge_op.gd — Insert a midpoint node on edges longer than threshold.
# Selection is over nodes, but we cut the edge (parent → selected_node).
#
# Params:
#   min_length — only subdivide edges at least this long (default 1.0)
#   tag       — tag for the inserted node (default "segment")
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var min_length: float = float(params.get("min_length", 1.0))
	var tag: String = str(params.get("tag", "segment"))

	# We'll rebuild edges because splitting needs to redirect parent refs.
	# Work on a snapshot of indices to subdivide.
	var to_split := PackedInt32Array()
	for idx in selected:
		var p: int = g.parents[idx]
		if p < 0: continue
		var parent_pos: Vector3 = g.nodes[p]
		var child_pos: Vector3 = g.nodes[idx]
		if parent_pos.distance_to(child_pos) >= min_length:
			to_split.append(idx)
	# Process from highest index downward so indices stay valid
	var split_list: Array = Array(to_split)
	split_list.sort()
	split_list.reverse()
	for child_idx in split_list:
		var p: int = g.parents[child_idx]
		if p < 0: continue
		var midpoint: Vector3 = (g.nodes[p] + g.nodes[child_idx]) * 0.5
		var mid_radius: float = (g.radii[p] + g.radii[child_idx]) * 0.5
		# Insert new node as child of p
		var new_idx: int = g.add_node(midpoint, mid_radius, p, PackedStringArray([tag]))
		# Redirect the original child_idx to have new_idx as its parent
		g.parents[child_idx] = new_idx
		# Remove the old (p, child_idx) edge and add (new_idx, child_idx)
		for i in range(g.edges.size() - 1, -1, -1):
			var e: Array = g.edges[i]
			if e[0] == p and e[1] == child_idx:
				g.edges.remove_at(i)
				break
		g.edges.append([new_idx, child_idx])
