# space_colonize_op.gd — Runions-style attractor-driven growth.
# Each iteration:
#   1. For each attractor point, find the nearest leaf within influence_radius.
#   2. Sum the normalized (node → attractor) direction vectors across all
#      attractors that chose this leaf.
#   3. Spawn a new child node from the leaf along that summed direction, at
#      step distance. Tag it "leaf", parent loses "leaf" tag.
#   4. Remove any attractor within kill_radius of an existing node.
#   5. Repeat for `iterations` passes.
#
# Attractors are distributed in a cloud/box around the origin. Shape the
# cloud to sculpt the resulting growth — ellipsoid = canopy, cone = spire,
# torus = ring of roots, etc.
#
# Params:
#   iterations        — growth passes (default 30)
#   attractor_count   — how many attractors (default 200)
#   cloud_shape       — "sphere", "ellipsoid", "cone", "torus" (default "ellipsoid")
#   cloud_size        — Vector3 scale of the attractor cloud (default [2, 2, 2])
#   cloud_center      — Vector3 (default [0, 2, 0])
#   influence_radius  — attractors within this range pull a node (default 1.2)
#   kill_radius       — attractors within this of any node are removed (default 0.35)
#   step              — new child distance from parent (default 0.2)
#   radius_decay      — radius decay per new node (default 0.94)
#   seed              — deterministic (default 13)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, _selected: PackedInt32Array) -> void:
	var iters: int = int(params.get("iterations", 30))
	var att_count: int = int(params.get("attractor_count", 200))
	var cloud_shape: String = str(params.get("cloud_shape", "ellipsoid"))
	var cloud_size: Vector3 = _as_vec3(params.get("cloud_size", [2.0, 2.0, 2.0]))
	var cloud_center: Vector3 = _as_vec3(params.get("cloud_center", [0.0, 2.0, 0.0]))
	var infl: float = float(params.get("influence_radius", 1.2))
	var kill: float = float(params.get("kill_radius", 0.35))
	var step: float = float(params.get("step", 0.2))
	var radius_decay: float = float(params.get("radius_decay", 0.94))
	var seed_val: int = int(params.get("seed", 13))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	# Generate attractor cloud
	var attractors: Array[Vector3] = []
	var attempts: int = 0
	while attractors.size() < att_count and attempts < att_count * 10:
		attempts += 1
		var u := rng.randf_range(-1.0, 1.0)
		var v := rng.randf_range(-1.0, 1.0)
		var w := rng.randf_range(-1.0, 1.0)
		var p := Vector3(u, v, w)
		var keep := true
		match cloud_shape:
			"sphere", "ellipsoid":
				keep = p.length() <= 1.0
			"cone":
				# Tighter at -Y, wider at +Y
				var h: float = (v + 1.0) * 0.5  # 0..1
				keep = Vector2(u, w).length() <= h
			"torus":
				var ring: float = Vector2(u, w).length()
				keep = abs(ring - 0.6) <= 0.25 and abs(v) <= 0.25
			_:
				keep = p.length() <= 1.0
		if keep:
			attractors.append(cloud_center + p * cloud_size)

	# Growth loop
	for _pass in iters:
		if attractors.is_empty() or g.node_count() == 0:
			break
		# For each attractor, find its nearest node within influence
		var leaf_influences: Dictionary = {}  # node_idx → Array of attractor indices
		for a_idx in attractors.size():
			var a_pos: Vector3 = attractors[a_idx]
			var nearest: int = -1
			var nearest_d: float = infl
			for n_idx in g.node_count():
				var d: float = g.nodes[n_idx].distance_to(a_pos)
				if d < nearest_d:
					nearest_d = d
					nearest = n_idx
			if nearest >= 0:
				if not leaf_influences.has(nearest):
					leaf_influences[nearest] = []
				(leaf_influences[nearest] as Array).append(a_idx)
		if leaf_influences.is_empty():
			break
		# Spawn one new child per influenced node
		for n_idx in leaf_influences.keys():
			var dir := Vector3.ZERO
			for a_idx in leaf_influences[n_idx]:
				dir += (attractors[a_idx] - g.nodes[n_idx]).normalized()
			if dir.length_squared() < 1e-6:
				continue
			dir = dir.normalized()
			var new_pos: Vector3 = g.nodes[n_idx] + dir * step
			var new_rad: float = g.radii[n_idx] * radius_decay
			# Old node loses 'leaf' tag
			var tags: PackedStringArray = g.node_tags[n_idx]
			var new_tags := PackedStringArray()
			for t in tags:
				if t != "leaf": new_tags.append(t)
			g.node_tags[n_idx] = new_tags
			g.add_node(new_pos, new_rad, n_idx, PackedStringArray(["leaf"]))
		# Cull attractors within kill radius of any node
		var surviving: Array[Vector3] = []
		for a_pos in attractors:
			var culled := false
			for n_idx in g.node_count():
				if g.nodes[n_idx].distance_to(a_pos) < kill:
					culled = true
					break
			if not culled:
				surviving.append(a_pos)
		attractors = surviving


static func _as_vec3(v) -> Vector3:
	if v is Vector3:
		return v
	if v is Array and v.size() >= 3:
		return Vector3(float(v[0]), float(v[1]), float(v[2]))
	return Vector3.ZERO
