# hull_shell_op.gd — Compute the convex hull of all node positions,
# scale it by `shell_scale` > 1.0 (making it wrap the original graph
# with some gap), and add the hull edges as "shell" tagged geometry.
# The original graph is untouched — this ADDS a surrounding wire mesh.
#
# Use case: "organism inside a cage", "nucleus within membrane", or
# (with shell_scale < 1.0) "organism wearing a mesh suit close to skin".
#
# Godot's Geometry3D.convex_hull gives us the hull vertices + triangle
# indices. We add each hull vertex as a new node tagged "shell_node"
# and each hull edge as an edge tagged "shell".
#
# Params:
#   shell_scale  — how much bigger than graph AABB (default 1.25)
#   shell_radius — radius of hull edge capsules (default 0.04)
#   tag          — tag for the shell geometry (default "shell")
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, _selected: PackedInt32Array) -> void:
	if g.node_count() < 4:
		return
	var shell_scale: float = float(params.get("shell_scale", 1.25))
	var shell_radius: float = float(params.get("shell_radius", 0.04))
	var tag: String = str(params.get("tag", "shell"))

	# Compute centroid of all nodes (graph center, not AABB center)
	var centroid := Vector3.ZERO
	for i in g.node_count():
		centroid += g.nodes[i]
	centroid /= float(g.node_count())

	# Scale all node positions around centroid by shell_scale, that's the
	# point cloud we'll hull. This gives the hull natural gap.
	var scaled_points := PackedVector3Array()
	scaled_points.resize(g.node_count())
	for i in g.node_count():
		scaled_points[i] = centroid + (g.nodes[i] - centroid) * shell_scale

	var hull_mesh: Array = Geometry3D.build_convex_mesh(scaled_points)
	# Geometry3D.build_convex_mesh returns an Array of Vector3 triangle corners.
	# Each group of 3 Vector3s is one triangle.
	if hull_mesh.size() < 9 or hull_mesh.size() % 3 != 0:
		push_warning("hull_shell: hull returned insufficient triangles")
		return

	# Deduplicate vertices (same Vector3 appears in multiple triangles)
	var vert_to_idx: Dictionary = {}
	var hull_indices: Array = []
	for p in hull_mesh:
		var key: String = "%.4f,%.4f,%.4f" % [p.x, p.y, p.z]
		if not vert_to_idx.has(key):
			var new_node_idx: int = g.add_node(p, shell_radius, -1, PackedStringArray([tag, "shell_node"]))
			vert_to_idx[key] = new_node_idx
		hull_indices.append(vert_to_idx[key])

	# Each triangle has 3 edges. Add each unique edge.
	var seen_edges: Dictionary = {}
	for i in range(0, hull_indices.size(), 3):
		var a: int = hull_indices[i]
		var b: int = hull_indices[i + 1]
		var c: int = hull_indices[i + 2]
		_add_edge(g, a, b, seen_edges)
		_add_edge(g, b, c, seen_edges)
		_add_edge(g, c, a, seen_edges)


static func _add_edge(g, a: int, b: int, seen: Dictionary) -> void:
	if a == b: return
	var key: String = "%d_%d" % [mini(a, b), maxi(a, b)]
	if seen.has(key): return
	seen[key] = true
	g.edges.append([a, b])
