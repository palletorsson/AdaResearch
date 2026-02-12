class_name CartridgeDFSGraph
extends Grid3DCartridge

## DFS on a 3D graph — depth-first exploration with backtracking.
## Nodes: 0=unvisited, 1=on-stack(orange), 2=visited(green), 3=source(magenta)
## Edges: 0=default, 1=tree-edge(green), 2=back-edge(red)

var _adj: Dictionary = {}
var _stack: Array = []
var _visited: PackedInt32Array
var _source: int = 0
var _done: bool = false

func get_name() -> String:
	return "DFS — Depth-First Search"

func get_state_count() -> int:
	return 4

func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.2, 0.3, 0.5)
		1: return Color(1.0, 0.6, 0.15)   # on-stack: orange
		2: return Color(0.2, 0.85, 0.4)
		3: return Color(0.9, 0.2, 0.8)
	return Color(0.2, 0.3, 0.5)

func get_node_emission(state: int) -> float:
	match state:
		0: return 0.2
		1: return 0.9
		2: return 0.5
		3: return 1.2
	return 0.2

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var data = super.initialize(node_count, bounds)

	_adj.clear()
	for i in range(node_count):
		_adj[i] = []
	for e in data["edges"]:
		_adj[e[0]].append(e[1])
		_adj[e[1]].append(e[0])

	_source = 0
	var max_deg = 0
	for i in range(node_count):
		if _adj[i].size() > max_deg:
			max_deg = _adj[i].size()
			_source = i

	_visited = PackedInt32Array()
	_visited.resize(node_count)
	_visited.fill(0)
	_visited[_source] = 1
	_stack = [{"node": _source, "neighbor_idx": 0}]
	_done = false

	data["states"][_source] = 3
	return data

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	if _done or _stack.is_empty():
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "DFS complete"}

	var top = _stack.back()
	var current = top["node"]
	var highlights = {}
	var edge_highlights = {}

	# Find next unvisited neighbor
	var found = false
	var neighbors = _adj[current]
	while top["neighbor_idx"] < neighbors.size():
		var neighbor = neighbors[top["neighbor_idx"]]
		top["neighbor_idx"] += 1

		if _visited[neighbor] == 0:
			# Explore deeper
			_visited[neighbor] = 1
			states[neighbor] = 1  # on-stack
			_stack.append({"node": neighbor, "neighbor_idx": 0})

			# Mark tree edge
			for ei in range(edges.size()):
				var e = edges[ei]
				if (e[0] == current and e[1] == neighbor) or (e[0] == neighbor and e[1] == current):
					edge_states[ei] = 1
					edge_highlights[ei] = Color(0.2, 0.95, 0.4, 0.9)

			highlights[neighbor] = Color(1.0, 0.6, 0.15)
			found = true
			break

	if not found:
		# Backtrack
		_stack.pop_back()
		if current != _source:
			states[current] = 2  # visited (off stack)
		highlights[current] = Color(0.2, 0.85, 0.4)

	return {
		"positions": null, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": edge_highlights,
		"done": false, "description": "DFS at node %d, stack: %d" % [current, _stack.size()]
	}
