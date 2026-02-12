class_name CartridgeBFSGraph
extends Grid3DCartridge

## BFS on a 3D graph — breadth-first wavefront expansion.
## Nodes: 0=unvisited(blue), 1=frontier(yellow), 2=visited(green), 3=source(magenta)
## Edges: 0=default, 1=tree-edge(green), 2=considering(yellow)

var _adj: Dictionary = {}  # node -> [neighbors]
var _queue: Array = []
var _visited: PackedInt32Array
var _source: int = 0
var _done: bool = false

func get_name() -> String:
	return "BFS — Breadth-First Search"

func get_state_count() -> int:
	return 4

func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.2, 0.3, 0.5)    # unvisited: dark blue
		1: return Color(1.0, 0.9, 0.2)    # frontier: yellow
		2: return Color(0.2, 0.85, 0.4)   # visited: green
		3: return Color(0.9, 0.2, 0.8)    # source: magenta
	return Color(0.2, 0.3, 0.5)

func get_node_emission(state: int) -> float:
	match state:
		0: return 0.2
		1: return 1.0
		2: return 0.5
		3: return 1.2
	return 0.2

func get_node_radius(state: int) -> float:
	if state == 3: return 1.4  # source is bigger
	if state == 1: return 1.2  # frontier slightly bigger
	return 1.0

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var data = super.initialize(node_count, bounds)

	# Build adjacency list
	_adj.clear()
	for i in range(node_count):
		_adj[i] = []
	for ei in range(data["edges"].size()):
		var e = data["edges"][ei]
		_adj[e[0]].append(e[1])
		_adj[e[1]].append(e[0])

	# Pick source (highest degree node)
	_source = 0
	var max_deg = 0
	for i in range(node_count):
		if _adj[i].size() > max_deg:
			max_deg = _adj[i].size()
			_source = i

	# Init BFS
	_visited = PackedInt32Array()
	_visited.resize(node_count)
	_visited.fill(0)
	_visited[_source] = 1
	_queue = [_source]
	_done = false

	data["states"][_source] = 3  # source state
	return data

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	if _done or _queue.is_empty():
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "BFS complete"}

	var current = _queue.pop_front()
	var highlights = {}
	var edge_highlights = {}

	# Mark current as visited
	if current != _source:
		states[current] = 2

	# Explore neighbors
	for neighbor in _adj[current]:
		if _visited[neighbor] == 0:
			_visited[neighbor] = 1
			_queue.append(neighbor)
			states[neighbor] = 1  # frontier

			# Find and mark the tree edge
			for ei in range(edges.size()):
				var e = edges[ei]
				if (e[0] == current and e[1] == neighbor) or (e[0] == neighbor and e[1] == current):
					edge_states[ei] = 1  # tree edge
					edge_highlights[ei] = Color(0.2, 0.95, 0.4, 0.9)

	highlights[current] = Color(0.2, 0.85, 0.4)  # flash visited

	return {
		"positions": null, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": edge_highlights,
		"done": false, "description": "Visiting node %d, queue: %d" % [current, _queue.size()]
	}
