# graph_to_mesh.gd — Render a GraphState as a Node3D of capsule meshes,
# one per edge. Parent/child radii blended for a soft taper.
#
# Accepts an optional materials dict keyed by tag. Each edge uses the
# material whose tag matches the child node's first tag, falling back to
# "default". This lets a single graph grow bark on branches and plant on
# leaves from the same render.
#
# Usage:
#   var node := GraphToMesh.to_node3d(graph, {"default": bark_mat, "leaf": leaf_mat})
#   add_child(node)
extends RefCounted


static func to_node3d(g, materials = null) -> Node3D:
	var root := Node3D.new()
	root.name = "GraphMesh"
	# Normalize materials input — either a Material or a Dictionary {tag: mat}
	var mat_dict: Dictionary
	if materials is Material:
		mat_dict = {"default": materials}
	elif materials is Dictionary:
		mat_dict = materials
	else:
		mat_dict = {"default": _default_material()}
	if not mat_dict.has("default"):
		mat_dict["default"] = _default_material()

	for e in g.edges:
		var a_idx: int = e[0]
		var b_idx: int = e[1]
		if a_idx >= g.nodes.size() or b_idx >= g.nodes.size():
			continue
		var a: Vector3 = g.nodes[a_idx]
		var b: Vector3 = g.nodes[b_idx]
		var ra: float = g.radii[a_idx]
		var rb: float = g.radii[b_idx]
		var r_avg: float = maxf(0.01, (ra + rb) * 0.5)
		var mi := _capsule_between(a, b, r_avg)
		# Resolve material from the child node's tags (first matching)
		var chosen: Material = mat_dict["default"]
		if b_idx < g.node_tags.size():
			var tags: PackedStringArray = g.node_tags[b_idx]
			for t in tags:
				if mat_dict.has(t):
					chosen = mat_dict[t]
					break
		mi.material_override = chosen
		root.add_child(mi)
	return root


static func _capsule_between(a: Vector3, b: Vector3, radius: float) -> MeshInstance3D:
	var dir: Vector3 = b - a
	var length: float = dir.length()
	if length < 1e-6:
		length = 0.01
	var mesh := CapsuleMesh.new()
	mesh.radius = radius
	mesh.height = length
	mesh.radial_segments = 8
	mesh.rings = 2
	var mi := MeshInstance3D.new()
	mi.mesh = mesh
	# CapsuleMesh is along +Y by default. Place midpoint at a+b, orient +Y to dir.
	var mid: Vector3 = (a + b) * 0.5
	var t := Transform3D.IDENTITY
	t.origin = mid
	if length > 1e-6:
		var n: Vector3 = dir.normalized()
		var up := Vector3(0, 1, 0)
		if (n - up).length_squared() > 1e-6 and (n + up).length_squared() > 1e-6:
			var axis: Vector3 = up.cross(n).normalized()
			var angle: float = acos(clamp(up.dot(n), -1.0, 1.0))
			t.basis = Basis(axis, angle)
		elif (n + up).length_squared() <= 1e-6:
			t.basis = Basis(Vector3(1, 0, 0), PI)
	mi.transform = t
	return mi


static func _default_material() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.72, 0.55, 0.38)
	m.roughness = 0.8
	m.metallic = 0.05
	return m
