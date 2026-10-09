class_name CartridgeForceDirected
extends Grid3DCartridge

## Force-directed graph layout — nodes repel, edges attract.
## Positions change every step. Watch the graph self-organize.
## No "done" — runs continuously until convergence.

var _velocities: PackedVector3Array
var _adj: Dictionary = {}
var _repulsion: float = 0.8
var _attraction: float = 0.02
var _damping: float = 0.9
var _rest_length: float = 0.6
var _temperature: float = 1.0
var _iterations: int = 0

func get_name() -> String:
	return "Force-Directed Layout"

func has_dynamic_positions() -> bool:
	return true

func get_node_color(state: int) -> Color:
	# Color by degree (set during initialize)
	match state:
		0: return Color(0.3, 0.5, 0.8)    # low degree: blue
		1: return Color(0.3, 0.8, 0.5)    # medium: green
		2: return Color(0.9, 0.6, 0.2)    # high: orange
		3: return Color(0.9, 0.2, 0.3)    # highest: red
	return Color(0.3, 0.5, 0.8)

func get_node_radius(state: int) -> float:
	return 0.8 + state * 0.3

func get_preferred_interval() -> float:
	return 0.016  # 60fps — continuous simulation

func get_preferred_node_count() -> int:
	return 25

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var data = super.initialize(node_count, bounds)

	_velocities = PackedVector3Array()
	_velocities.resize(node_count)
	for i in range(node_count):
		_velocities[i] = Vector3.ZERO

	# Build adjacency
	_adj.clear()
	for i in range(node_count):
		_adj[i] = []
	for e in data["edges"]:
		_adj[e[0]].append(e[1])
		_adj[e[1]].append(e[0])

	# Color by degree
	for i in range(node_count):
		var deg = _adj[i].size()
		if deg <= 1:
			data["states"][i] = 0
		elif deg <= 3:
			data["states"][i] = 1
		elif deg <= 5:
			data["states"][i] = 2
		else:
			data["states"][i] = 3

	# All edges start as "in-tree" (visible)
	for i in range(data["edge_states"].size()):
		data["edge_states"][i] = 1

	_temperature = 1.0
	_iterations = 0
	return data

func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	var n = positions.size()
	_iterations += 1

	# Repulsion between all pairs (O(n²) — fine for n<100)
	var forces = PackedVector3Array()
	forces.resize(n)
	for i in range(n):
		forces[i] = Vector3.ZERO

	for i in range(n):
		for j in range(i + 1, n):
			var delta = positions[i] - positions[j]
			var dist = delta.length()
			if dist < 0.01:
				delta = Vector3(randf() - 0.5, randf() - 0.5, randf() - 0.5).normalized() * 0.01
				dist = 0.01
			var repel = _repulsion / (dist * dist)
			var force = delta.normalized() * repel * _temperature
			forces[i] += force
			forces[j] -= force

	# Attraction along edges
	for e in edges:
		var delta = positions[e[1]] - positions[e[0]]
		var dist = delta.length()
		var attract = _attraction * (dist - _rest_length)
		var force = delta.normalized() * attract
		forces[e[0]] += force
		forces[e[1]] -= force

	# Apply forces
	for i in range(n):
		_velocities[i] = (_velocities[i] + forces[i]) * _damping
		# Clamp velocity
		var speed = _velocities[i].length()
		if speed > 0.5:
			_velocities[i] = _velocities[i].normalized() * 0.5
		positions[i] += _velocities[i]

	# Cool temperature
	_temperature *= 0.999

	return {
		"positions": positions, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": {}, "edge_highlights": {},
		"done": false, "description": "Iteration %d (T=%.3f)" % [_iterations, _temperature]
	}
