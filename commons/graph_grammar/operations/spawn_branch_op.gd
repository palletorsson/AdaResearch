# spawn_branch_op.gd — At each selected node, spawn `count` children.
# New children are placed along the parent direction with some splay angle
# and radius decay. After spawning, the parent loses its "leaf" tag if it had
# one, and new children get "leaf".
#
# Params:
#   count        — children per selected node (default 3)
#   length       — distance to new children from parent (default 0.6)
#   spread_deg   — half-angle splay (default 35)
#   radius_decay — child radius = parent radius * decay (default 0.65)
#   jitter       — random perturbation on direction 0..1 (default 0.2)
#   seed         — deterministic seed (default 7)
#   tag_children — tag to add to new children (default "leaf")
extends "res://commons/graph_grammar/graph_rule.gd"


func _execute(g, selected: PackedInt32Array) -> void:
	var count: int = int(params.get("count", 3))
	var length: float = float(params.get("length", 0.6))
	var spread_deg: float = float(params.get("spread_deg", 35.0))
	var radius_decay: float = float(params.get("radius_decay", 0.65))
	var jitter: float = float(params.get("jitter", 0.2))
	var seed_val: int = int(params.get("seed", 7))
	var child_tag: String = str(params.get("tag_children", "leaf"))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	var spread: float = deg_to_rad(spread_deg)

	for idx in selected:
		var parent_pos: Vector3 = g.nodes[idx]
		var parent_rad: float = g.radii[idx]
		var parent_dir: Vector3 = g.node_direction(idx)
		# This node is no longer a leaf
		var tags: PackedStringArray = g.node_tags[idx]
		var new_tags := PackedStringArray()
		for t in tags:
			if t != "leaf":
				new_tags.append(t)
		g.node_tags[idx] = new_tags
		# Spawn children
		for i in count:
			var phi: float = (float(i) / float(count)) * TAU + rng.randf_range(-0.2, 0.2)
			var theta: float = spread + rng.randf_range(-jitter * spread, jitter * spread)
			# Local direction around +Z
			var local := Vector3(sin(theta) * cos(phi), sin(theta) * sin(phi), cos(theta))
			# Rotate so +Z aligns with parent_dir
			var child_dir := _align_z_to(parent_dir, local).normalized()
			var child_pos: Vector3 = parent_pos + child_dir * length
			g.add_node(child_pos, parent_rad * radius_decay, idx,
				PackedStringArray([child_tag]))


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
