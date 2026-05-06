# leaf_tuft_op.gd — At selected nodes (usually leaves), spawn many short
# bristles in all directions. Unlike spawn_branch (a few deliberate children),
# leaf_tuft produces foliage — a burst of 6-16 tiny children at varied angles.
#
# Children get the "leaf" tag so they can receive the plant shader.
#
# Params:
#   count        — bristles per node (default 10)
#   length       — bristle length (default 0.25)
#   radius       — bristle radius (default 0.025)
#   splay        — full splay (0=axial, 1=spherical) (default 0.7)
#   seed         — deterministic (default 17)
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var count: int = int(params.get("count", 10))
	var length: float = float(params.get("length", 0.25))
	var radius: float = float(params.get("radius", 0.025))
	var splay: float = clamp(float(params.get("splay", 0.7)), 0.0, 1.0)
	var seed_val: int = int(params.get("seed", 17))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	for idx in selected:
		var parent_pos: Vector3 = g.nodes[idx]
		var parent_dir: Vector3 = g.node_direction(idx)
		# Parent loses 'leaf' tag (but keeps others)
		var tags: PackedStringArray = g.node_tags[idx]
		var new_tags := PackedStringArray()
		for t in tags:
			if t != "leaf":
				new_tags.append(t)
		g.node_tags[idx] = new_tags
		# Spawn bristles in a tuft pattern
		for i in count:
			# Uniform-ish points on a sphere (Fibonacci spiral)
			var fi: float = float(i) + 0.5
			var phi: float = acos(1.0 - 2.0 * fi / float(count))
			var theta: float = PI * (1.0 + sqrt(5.0)) * fi
			var local := Vector3(
				sin(phi) * cos(theta),
				sin(phi) * sin(theta),
				cos(phi),
			)
			# Bias toward parent direction: lerp(parent_dir, local, splay)
			var final_dir: Vector3 = (parent_dir.lerp(_align_z_to(parent_dir, local), splay)).normalized()
			var jitter_offset := Vector3(
				rng.randf_range(-0.1, 0.1),
				rng.randf_range(-0.1, 0.1),
				rng.randf_range(-0.1, 0.1),
			) * length * 0.3
			var child_pos: Vector3 = parent_pos + final_dir * length + jitter_offset
			g.add_node(child_pos, radius, idx, PackedStringArray(["leaf"]))


static func _align_z_to(target_dir: Vector3, local: Vector3) -> Vector3:
	var up := Vector3(0, 0, 1)
	var td: Vector3 = target_dir.normalized()
	if td.is_equal_approx(up):
		return local
	if td.is_equal_approx(-up):
		return Vector3(local.x, local.y, -local.z)
	var axis: Vector3 = up.cross(td).normalized()
	var angle: float = acos(clamp(up.dot(td), -1.0, 1.0))
	return local.rotated(axis, angle)
