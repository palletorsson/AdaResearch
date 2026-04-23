# graph_state.gd — Core data for graph-topology grammars.
# A graph is a set of 3D nodes with radii and parent→child edges.
# Each node carries tags (Strings) and a depth (int, generations from root).
#
# Mirrors commons/morphology/graph/bone_graph.gd but adds tags per node so
# selectors can match grammar state across rule applications.
extends Resource

var nodes: PackedVector3Array = PackedVector3Array()
var radii: PackedFloat32Array = PackedFloat32Array()
var parents: PackedInt32Array = PackedInt32Array()      # -1 for root
var edges: Array = []                                   # Array of [int, int]
var node_tags: Array = []                               # Array of PackedStringArray
var node_depth: PackedInt32Array = PackedInt32Array()


func add_node(pos: Vector3, radius: float, parent_idx: int = -1,
		tags: PackedStringArray = PackedStringArray()) -> int:
	var idx: int = nodes.size()
	nodes.append(pos)
	radii.append(radius)
	parents.append(parent_idx)
	if parent_idx >= 0:
		edges.append([parent_idx, idx])
		var pd: int = 0
		if parent_idx < node_depth.size():
			pd = node_depth[parent_idx]
		node_depth.append(pd + 1)
	else:
		node_depth.append(0)
	node_tags.append(tags)
	return idx


func node_count() -> int:
	return nodes.size()


func edge_count() -> int:
	return edges.size()


## Compute children for every node. Returns array where children[i] = [child_idx,...]
func compute_children() -> Array:
	var children: Array = []
	children.resize(nodes.size())
	for i in nodes.size():
		children[i] = []
	for e in edges:
		var p: int = e[0]
		var c: int = e[1]
		if p < children.size():
			children[p].append(c)
	return children


## Node indices with no outgoing edges (i.e. no children).
func leaves() -> PackedInt32Array:
	var children := compute_children()
	var out := PackedInt32Array()
	for i in nodes.size():
		if (children[i] as Array).is_empty():
			out.append(i)
	return out


## Node indices that are roots (no parent).
func roots() -> PackedInt32Array:
	var out := PackedInt32Array()
	for i in parents.size():
		if parents[i] < 0:
			out.append(i)
	return out


## The direction vector from parent to node (tangent). For roots: +Y.
func node_direction(idx: int) -> Vector3:
	if idx >= parents.size():
		return Vector3.UP
	var p: int = parents[idx]
	if p < 0 or p >= nodes.size():
		return Vector3.UP
	var d: Vector3 = nodes[idx] - nodes[p]
	if d.length_squared() < 1e-8:
		return Vector3.UP
	return d.normalized()


func has_tag(idx: int, tag: String) -> bool:
	if idx >= node_tags.size():
		return false
	var tags: PackedStringArray = node_tags[idx]
	return tag in tags


func add_tag(idx: int, tag: String) -> void:
	if idx >= node_tags.size():
		return
	var tags: PackedStringArray = node_tags[idx]
	if not (tag in tags):
		tags.append(tag)
		node_tags[idx] = tags


func seed_single_root(pos: Vector3 = Vector3.ZERO, radius: float = 0.18) -> void:
	nodes.clear(); radii.clear(); parents.clear()
	edges.clear(); node_tags.clear(); node_depth.clear()
	add_node(pos, radius, -1, PackedStringArray(["root", "leaf"]))
