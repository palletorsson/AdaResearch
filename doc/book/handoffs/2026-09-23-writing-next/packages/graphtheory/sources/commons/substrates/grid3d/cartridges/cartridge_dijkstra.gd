class_name CartridgeDijkstra
extends Grid3DCartridge

## Dijkstra's shortest path — greedy expansion by distance.
## Nodes: 0=unvisited, 1=frontier(cyan), 2=settled(green), 3=source(magenta)
## Edge colors encode weight (shorter=brighter).

var _adj: Dictionary = {}  # node -> [{neighbor, edge_idx, weight}]
var _dist: PackedFloat32Array
var _settled: PackedInt32Array
var _source: int = 0
var _done: bool = false

func get_name() -> String:
	return "Dijkstra's Algorithm"

func get_state_count() -> int:
	return 4

func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.2, 0.3, 0.5)
		1: return Color(0.2, 0.85, 0.95)   # frontier: cyan
		2: return Color(0.2, 0.85, 0.4)    # settled: green
		3: return Color(0.9, 0.2, 0.8)     # source: magenta
	return Color(0.2, 0.3, 0.5)

func get_node_emission(state: int) -> float:
	match state:
		0: return 0.2
		1: return 0.9
		2: return 0.5
		3: return 1.2
	return 0.2

func get_preferred_interval() -> float:
	return 0.4

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var data = super.initialize(node_count, bounds)

	# Build adjacency with weights
	_adj.clear()
	for i in range(node_count):
		_adj[i] = []
	for ei in range(data["edges"].size()):
		var e = data["edges"][ei]
		var w = data["edge_weights"][ei]
		_adj[e[0]].append({"neighbor": e[1], "edge_idx": ei, "weight": w})
		_adj[e[1]].append({"neighbor": e[0], "edge_idx": ei, "weight": w})

	# Source = node 0
	_source = 0
	_dist = PackedFloat32Array()
	_dist.resize(node_count)
	for i in range(node_count):
		_dist[i] = INF
	_dist[_source] = 0.0

	_settled = PackedInt32Array()
	_settled.resize(node_count)
	_settled.fill(0)

	_done = false
	data["states"][_source] = 3
	return data

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	if _done:
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "Dijkstra complete"}

	# Find unsettled node with minimum distance
	var u = -1
	var min_d = INF
	for i in range(_dist.size()):
		if _settled[i] == 0 and _dist[i] < min_d:
			min_d = _dist[i]
			u = i

	if u == -1 or min_d == INF:
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "Dijkstra complete — unreachable nodes remain"}

	# Settle u
	_settled[u] = 1
	if u != _source:
		states[u] = 2

	var highlights = {}
	var edge_highlights = {}
	highlights[u] = Color(0.2, 0.95, 0.4)

	# Relax neighbors
	for entry in _adj[u]:
		var v = entry["neighbor"]
		var ei = entry["edge_idx"]
		var w = entry["weight"]

		if _settled[v] == 0:
			var new_dist = _dist[u] + w
			if new_dist < _dist[v]:
				_dist[v] = new_dist
				states[v] = 1  # frontier
				edge_states[ei] = 2  # considering
				edge_highlights[ei] = Color(0.2, 0.9, 0.95, 0.8)
			# Mark tree edge for settled connection
			if _dist[v] == _dist[u] + w:
				edge_states[ei] = 1

	return {
		"positions": null, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": edge_highlights,
		"done": false, "description": "Settling node %d (dist=%.2f)" % [u, min_d]
	}
