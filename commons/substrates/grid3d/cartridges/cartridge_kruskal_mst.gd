class_name CartridgeKruskalMST
extends Grid3DCartridge

## Kruskal's MST — greedily add cheapest edge that doesn't form a cycle.
## Uses Union-Find. Edges sorted by weight, considered one at a time.
## Edge states: 0=unconsidered, 1=in-MST(green), 2=considering(yellow), 3=rejected(red)

var _sorted_edge_indices: Array = []
var _cursor: int = 0
var _parent: PackedInt32Array  # Union-Find
var _rank: PackedInt32Array
var _mst_count: int = 0
var _done: bool = false

func get_name() -> String:
	return "Kruskal's MST"

func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.3, 0.4, 0.6)
		1: return Color(0.2, 0.85, 0.4)   # connected to MST
	return Color(0.3, 0.4, 0.6)

func get_node_emission(state: int) -> float:
	return 0.3 if state == 0 else 0.6

func get_edge_color(state: int) -> Color:
	match state:
		0: return Color(0.3, 0.3, 0.4, 0.3)
		1: return Color(0.2, 0.95, 0.4, 0.9)   # MST: bright green
		2: return Color(1.0, 1.0, 0.2, 0.8)    # considering: yellow
		3: return Color(0.5, 0.15, 0.15, 0.2)  # rejected: dim red
	return Color(0.3, 0.3, 0.4, 0.3)

func get_preferred_interval() -> float:
	return 0.5

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var data = super.initialize(node_count, bounds)

	# Sort edges by weight
	_sorted_edge_indices = []
	for i in range(data["edge_weights"].size()):
		_sorted_edge_indices.append(i)
	# Sort by weight
	var weights = data["edge_weights"]
	_sorted_edge_indices.sort_custom(func(a, b): return weights[a] < weights[b])

	# Init Union-Find
	_parent = PackedInt32Array()
	_parent.resize(node_count)
	_rank = PackedInt32Array()
	_rank.resize(node_count)
	for i in range(node_count):
		_parent[i] = i
		_rank[i] = 0

	_cursor = 0
	_mst_count = 0
	_done = false
	return data

func _find(x: int) -> int:
	while _parent[x] != x:
		_parent[x] = _parent[_parent[x]]  # path compression
		x = _parent[x]
	return x

func _union(a: int, b: int) -> bool:
	var ra = _find(a)
	var rb = _find(b)
	if ra == rb:
		return false
	if _rank[ra] < _rank[rb]:
		_parent[ra] = rb
	elif _rank[ra] > _rank[rb]:
		_parent[rb] = ra
	else:
		_parent[rb] = ra
		_rank[ra] += 1
	return true

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	if _done or _cursor >= _sorted_edge_indices.size():
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true,
				"description": "MST complete (%d edges)" % _mst_count}

	# MST needs n-1 edges
	if _mst_count >= positions.size() - 1:
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true,
				"description": "MST complete (%d edges)" % _mst_count}

	var ei = _sorted_edge_indices[_cursor]
	var e = edges[ei]
	var u = e[0]
	var v = e[1]
	_cursor += 1

	var highlights = {}
	var edge_highlights = {}

	edge_highlights[ei] = Color(1.0, 1.0, 0.2, 0.9)  # flash yellow

	if _union(u, v):
		# Accept edge into MST
		edge_states[ei] = 1
		_mst_count += 1
		states[u] = 1
		states[v] = 1
		highlights[u] = Color(0.2, 0.95, 0.4)
		highlights[v] = Color(0.2, 0.95, 0.4)
	else:
		# Reject — would form cycle
		edge_states[ei] = 3

	return {
		"positions": null, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": edge_highlights,
		"done": false, "description": "Edge %d→%d (w=%.2f) — %s" % [u, v, edge_weights[ei], "accepted" if edge_states[ei] == 1 else "rejected"]
	}
