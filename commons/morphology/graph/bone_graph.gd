# bone_graph.gd — A skeleton as explicit graph data.
#
# Nodes carry world position + radius. Edges connect node indices.
# This is the Godot twin of what Blender's Skin modifier consumes:
# (verts, edges, radii). Once a BoneGraph exists, many things can
# build off it — graph_sdf renders it as capsules, pose_op rotates
# bones at their parents, retarget_op transplants DNA between rigs.
#
# Keep this class flat and data-only. Algorithms live in other files.

extends Resource

var nodes: PackedVector3Array = PackedVector3Array()
var radii: PackedFloat32Array = PackedFloat32Array()
var edges: Array = []  # Array of [int, int] — parent-index, child-index
var parents: PackedInt32Array = PackedInt32Array()  # parent index per node (-1 for root)


## Append a node and return its index.
func add_node(pos: Vector3, radius: float, parent_idx: int = -1) -> int:
	var idx: int = nodes.size()
	nodes.append(pos)
	radii.append(radius)
	parents.append(parent_idx)
	if parent_idx >= 0:
		edges.append([parent_idx, idx])
	return idx


func node_count() -> int:
	return nodes.size()


func edge_count() -> int:
	return edges.size()


## Root node's AABB grown by all node radii.
func compute_aabb() -> AABB:
	if nodes.is_empty():
		return AABB(Vector3(-1, -1, -1), Vector3(2, 2, 2))
	var r0: float = radii[0]
	var total := AABB(nodes[0] - Vector3.ONE * r0, Vector3.ONE * r0 * 2.0)
	for i in range(1, nodes.size()):
		var r: float = radii[i]
		var n_aabb := AABB(nodes[i] - Vector3.ONE * r, Vector3.ONE * r * 2.0)
		total = total.merge(n_aabb)
	return total
