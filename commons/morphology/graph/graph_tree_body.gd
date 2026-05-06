# graph_tree_body.gd — Body recipe that builds a branching tree as an
# explicit graph of bones and emits one capsule per edge. The capsules
# are smooth-unioned by body_recipe, which is our equivalent of Blender's
# Skin modifier + Subdivision Surface — same topology, same output shape.
#
# Algorithm mirrors tools/blender/bone_skin.py line-for-line so the
# Blender prototype and Godot port stay in sync. If the Blender tuning
# looks good, the Godot tuning will too.
#
# DNA used:
#   trunk_length   — initial trunk segment length (default 1.5)
#   branch_count   — children per node (default 3)
#   depth          — recursion depth (default 4)
#   length_decay   — child length = parent * decay (default 0.65)
#   angle_spread   — degrees children splay from parent (default 45)
#   radius_base    — trunk radius (default 0.18)
#   radius_decay   — radius shrinks per depth level (default 0.62)
#   jitter         — random spread noise (default 0.25)
#   seed           — deterministic rebuilds (default 7)

extends "res://commons/morphology/sdf/body_recipe.gd"

const BoneGraph = preload("res://commons/morphology/graph/bone_graph.gd")

# The graph is exposed so downstream ops (pose, retarget) can read it.
var graph: Resource = null


func _build_from_dna() -> void:
	var trunk_length: float = float(dna.get("trunk_length", 1.5))
	var branch_count: int = int(dna.get("branch_count", 3))
	var depth: int = int(dna.get("depth", 4))
	var length_decay: float = float(dna.get("length_decay", 0.65))
	var angle_spread: float = float(dna.get("angle_spread", 45.0))
	var radius_base: float = float(dna.get("radius_base", 0.18))
	var radius_decay: float = float(dna.get("radius_decay", 0.62))
	var jitter: float = float(dna.get("jitter", 0.25))
	var seed_val: int = int(dna.get("seed", 7))

	var rng := RandomNumberGenerator.new()
	rng.seed = seed_val

	graph = BoneGraph.new()
	# Root at origin
	graph.add_node(Vector3.ZERO, radius_base, -1)
	# Grow upward
	_grow(graph, 0, Vector3.UP, trunk_length, radius_base, depth,
		branch_count, length_decay, angle_spread, radius_decay, jitter, rng)

	# Emit one capsule per edge; body_recipe will smooth_union them.
	# Per-edge radius uses the child node's radius (tip shrinks to tip).
	var jk: float = clamp(radius_base * 0.6, 0.05, 0.2)
	joint_k = jk  # rounder joints for thicker bones
	for e in graph.edges:
		var a: Vector3 = graph.nodes[e[0]]
		var b: Vector3 = graph.nodes[e[1]]
		var r: float = graph.radii[e[1]]
		# Capsule radius averaged so it tapers across the edge. The
		# body_recipe smooth_union blurs the step between adjacent edges.
		var r_avg: float = 0.5 * (graph.radii[e[0]] + r)
		var cap := _capsule_helper(a, b, r_avg)
		_add_part(cap, "body")


# Recursive growth — mirrors bone_skin.py::grow(). Adds one node, then
# spawns `branch_count` children with splay + jitter.
func _grow(g: Resource, parent_idx: int, direction: Vector3, length: float,
		radius: float, depth: int, branch_count: int, length_decay: float,
		angle_spread: float, radius_decay: float, jitter: float,
		rng: RandomNumberGenerator) -> void:
	if depth <= 0 or length < 0.05:
		return
	var parent_pos: Vector3 = g.nodes[parent_idx]
	var end_pos: Vector3 = parent_pos + direction * length
	var new_idx: int = g.add_node(end_pos, radius, parent_idx)

	var spread: float = deg_to_rad(angle_spread)
	var child_len: float = length * length_decay
	var child_rad: float = radius * radius_decay
	for i in branch_count:
		# Distribute children around parent direction
		var phi: float = (float(i) / float(branch_count)) * TAU + rng.randf_range(-0.3, 0.3)
		var theta: float = spread + rng.randf_range(-jitter, jitter)
		# Local spherical coordinate around +Z
		var local := Vector3(
			sin(theta) * cos(phi),
			sin(theta) * sin(phi),
			cos(theta),
		)
		# Rotate so +Z aligns with parent direction
		var new_dir: Vector3 = _align_z_to(direction, local).normalized()
		_grow(g, new_idx, new_dir, child_len, child_rad, depth - 1,
			branch_count, length_decay, angle_spread, radius_decay, jitter, rng)


# Rotate a vector so its +Z reference aligns with target direction.
# Equivalent to mathutils' up.rotation_difference(direction).
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
