class_name CartridgeRandomGraph
extends Grid3DCartridge

## Random graph — Erdos-Renyi model. Static display with degree coloring.
## Edges appear one at a time, coloring nodes by their accumulated degree.
## A gentle introduction to graph structure.

var _all_possible_edges: Array = []
var _cursor: int = 0
var _degrees: PackedInt32Array
var _done: bool = false

func get_name() -> String:
	return "Random Graph (Erdős–Rényi)"

func get_state_count() -> int:
	return 5

func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.25, 0.3, 0.5)   # isolated: dark
		1: return Color(0.3, 0.6, 0.8)    # deg 1-2: blue
		2: return Color(0.3, 0.8, 0.5)    # deg 3-4: green
		3: return Color(0.9, 0.7, 0.2)    # deg 5-6: yellow
		4: return Color(0.9, 0.2, 0.3)    # deg 7+: red (hub)
	return Color(0.25, 0.3, 0.5)

func get_node_radius(state: int) -> float:
	return 0.7 + state * 0.25

func get_preferred_interval() -> float:
	return 0.15

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	# Start with positions but NO edges
	var positions = PackedVector3Array()
	positions.resize(node_count)
	var states = PackedInt32Array()
	states.resize(node_count)
	states.fill(0)

	for i in range(node_count):
		positions[i] = Vector3(
			randf_range(-bounds.x * 0.5, bounds.x * 0.5),
			randf_range(-bounds.y * 0.5, bounds.y * 0.5),
			randf_range(-bounds.z * 0.5, bounds.z * 0.5)
		)

	# Pre-generate all potential edges (shuffled)
	_all_possible_edges = []
	for i in range(node_count):
		for j in range(i + 1, node_count):
			if randf() < 0.25:  # 25% edge probability
				_all_possible_edges.append([i, j])
	# Shuffle
	for i in range(_all_possible_edges.size() - 1, 0, -1):
		var j = randi() % (i + 1)
		var tmp = _all_possible_edges[i]
		_all_possible_edges[i] = _all_possible_edges[j]
		_all_possible_edges[j] = tmp

	_cursor = 0
	_degrees = PackedInt32Array()
	_degrees.resize(node_count)
	_degrees.fill(0)
	_done = false

	return {
		"positions": positions,
		"states": states,
		"edges": [],
		"edge_states": PackedInt32Array(),
		"edge_weights": PackedFloat32Array(),
	}

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	if _done or _cursor >= _all_possible_edges.size():
		_done = true
		return {"positions": null, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true,
				"description": "Graph complete (%d edges)" % edges.size()}

	# Add one edge
	var new_edge = _all_possible_edges[_cursor]
	_cursor += 1
	edges.append(new_edge)
	edge_states.append(1)  # visible
	edge_weights.append(positions[new_edge[0]].distance_to(positions[new_edge[1]]))

	# Update degrees and node colors
	_degrees[new_edge[0]] += 1
	_degrees[new_edge[1]] += 1
	for v in [new_edge[0], new_edge[1]]:
		var deg = _degrees[v]
		if deg == 0: states[v] = 0
		elif deg <= 2: states[v] = 1
		elif deg <= 4: states[v] = 2
		elif deg <= 6: states[v] = 3
		else: states[v] = 4

	var highlights = {}
	highlights[new_edge[0]] = Color(1.0, 1.0, 0.3)
	highlights[new_edge[1]] = Color(1.0, 1.0, 0.3)

	return {
		"positions": null, "states": states, "edges": edges, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": {},
		"done": false, "description": "Edge %d→%d added (%d total)" % [new_edge[0], new_edge[1], edges.size()]
	}
