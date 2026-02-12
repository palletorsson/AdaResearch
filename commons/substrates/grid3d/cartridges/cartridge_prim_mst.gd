class_name CartridgePrimMST
extends Grid3DCartridge

## Prim's MST — grow MST from a single source, always adding cheapest edge to tree.
## Nodes: 0=unreached, 1=in-tree(green), 2=frontier(cyan)
## Edges: 0=default, 1=in-MST(green), 2=considering(yellow)

var _adj: Dictionary = {}
var _in_tree: PackedInt32Array
var _source: int = 0
var _done: bool = false

func get_name() -> String:
	return "Prim's MST"

func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.2, 0.3, 0.5)
		1: return Color(0.2, 0.85, 0.4)   # in tree
		2: return Color(0.2, 0.85, 0.95)  # frontier
	return Color(0.2, 0.3, 0.5)

func get_preferred_interval() -> float:
	return 0.5

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var data = super.initialize(node_count, bounds)

	_adj.clear()
	for i in range(node_count):
		_adj[i] = []
	for ei in range(data["edges"].size()):
		var e = data["edges"][ei]
		var w = data["edge_weights"][ei]
		_adj[e[0]].append({"neighbor": e[1], "edge_idx": ei, "weight": w})
		_adj[e[1]].append({"neighbor": e[0], "edge_idx": ei, "weight": w})

	_source = 0
	_in_tree = PackedInt32Array()
	_in_tree.resize(node_count)
	_in_tree.fill(0)
	_in_tree[_source] = 1
	_done = false

	data["states"][_source] = 1
	# Mark frontier
	for entry in _adj[_source]:
		data["states"][entry["neighbor"]] = 2
	return data

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	if _done:
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "Prim's MST complete"}

	# Find cheapest edge from tree to non-tree
	var best_ei = -1
	var best_w = INF
	var best_v = -1
	for ei in range(edges.size()):
		if edge_states[ei] == 1:
			continue  # already in MST
		var e = edges[ei]
		var u_in = _in_tree[e[0]] == 1
		var v_in = _in_tree[e[1]] == 1
		if u_in != v_in:  # exactly one endpoint in tree
			if edge_weights[ei] < best_w:
				best_w = edge_weights[ei]
				best_ei = ei
				best_v = e[1] if u_in else e[0]

	if best_ei == -1:
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "Prim's MST complete"}

	# Add edge and node to tree
	edge_states[best_ei] = 1
	_in_tree[best_v] = 1
	states[best_v] = 1

	var highlights = {}
	var edge_highlights = {}
	highlights[best_v] = Color(0.2, 0.95, 0.4)
	edge_highlights[best_ei] = Color(0.2, 0.95, 0.4, 0.9)

	# Update frontier
	for entry in _adj[best_v]:
		if _in_tree[entry["neighbor"]] == 0 and states[entry["neighbor"]] == 0:
			states[entry["neighbor"]] = 2

	return {
		"positions": null, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": edge_highlights,
		"done": false, "description": "Adding node %d (w=%.2f)" % [best_v, best_w]
	}
