class_name Grid3DCartridge
extends RefCounted

## Base class for Grid3D algorithm cartridges.
## Manages a set of 3D nodes and edges that evolve over time.
## Nodes have positions + states. Edges connect node pairs.

## --- Override these ---

## Return the algorithm's display name.
func get_name() -> String:
	return "Unknown"

## How many nodes to create.
func get_node_count() -> int:
	return 20

## How many distinct node states (including 0=default).
func get_state_count() -> int:
	return 3

## Color for a node in given state. State 0 = default/unvisited.
func get_node_color(state: int) -> Color:
	match state:
		0: return Color(0.3, 0.4, 0.6)    # default: muted blue
		1: return Color(0.2, 0.9, 0.4)    # visited/active: green
		2: return Color(0.9, 0.2, 0.3)    # highlighted: red
	return Color(0.3, 0.4, 0.6)

## Emission energy for a node state.
func get_node_emission(state: int) -> float:
	match state:
		0: return 0.3
		1: return 0.8
		2: return 1.2
	return 0.3

## Node radius for a given state (can vary for emphasis).
func get_node_radius(state: int) -> float:
	return 1.0  # multiplier on base radius

## Color for an edge in given state.
## Edge states: 0=default, 1=active/in-tree, 2=considering, 3=rejected
func get_edge_color(state: int) -> Color:
	match state:
		0: return Color(0.3, 0.3, 0.4, 0.4)   # default: dim
		1: return Color(0.2, 0.9, 0.4, 0.9)   # in-tree: green
		2: return Color(1.0, 1.0, 0.2, 0.8)   # considering: yellow
		3: return Color(0.5, 0.15, 0.15, 0.3) # rejected: dark red
	return Color(0.3, 0.3, 0.4, 0.4)

## Edge emission for a given state.
func get_edge_emission(state: int) -> float:
	match state:
		0: return 0.1
		1: return 0.6
		2: return 1.0
		3: return 0.0
	return 0.1

## Called once. Set up initial node positions, states, and edges.
## Return a dictionary:
## {
##   "positions": PackedVector3Array,  — node positions
##   "states": PackedInt32Array,       — node states (0=default)
##   "edges": Array[Array],            — [[from, to], ...] index pairs
##   "edge_states": PackedInt32Array,  — edge states (0=default)
##   "edge_weights": PackedFloat32Array — optional weights (for MST, Dijkstra)
## }
func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var positions = PackedVector3Array()
	var states = PackedInt32Array()
	positions.resize(node_count)
	states.resize(node_count)
	states.fill(0)

	# Random positions within bounds
	for i in range(node_count):
		positions[i] = Vector3(
			randf_range(-bounds.x * 0.5, bounds.x * 0.5),
			randf_range(-bounds.y * 0.5, bounds.y * 0.5),
			randf_range(-bounds.z * 0.5, bounds.z * 0.5)
		)

	# Random edges (Erdos-Renyi)
	var edges: Array = []
	var edge_states = PackedInt32Array()
	var edge_weights = PackedFloat32Array()
	for i in range(node_count):
		for j in range(i + 1, node_count):
			if randf() < 0.2:
				edges.append([i, j])
				edge_states.append(0)
				edge_weights.append(positions[i].distance_to(positions[j]))

	return {
		"positions": positions,
		"states": states,
		"edges": edges,
		"edge_states": edge_states,
		"edge_weights": edge_weights,
	}

## Advance one step. Return a StepResult dictionary:
## {
##   "positions": PackedVector3Array,  — updated positions (or null if unchanged)
##   "states": PackedInt32Array,       — updated node states
##   "edges": Array[Array],            — updated edges (or null if unchanged)
##   "edge_states": PackedInt32Array,  — updated edge states
##   "highlights": Dictionary,         — {node_index: Color} for per-node overrides
##   "edge_highlights": Dictionary,    — {edge_index: Color} for per-edge overrides
##   "done": bool,
##   "description": String
## }
func step(positions: PackedVector3Array, states: PackedInt32Array,
		edges: Array, edge_states: PackedInt32Array,
		edge_weights: PackedFloat32Array) -> Dictionary:
	return {
		"positions": null,
		"states": states,
		"edges": null,
		"edge_states": edge_states,
		"highlights": {},
		"edge_highlights": {},
		"done": true,
		"description": ""
	}

## Called when player touches node at index.
func on_node_touch(index: int, positions: PackedVector3Array, states: PackedInt32Array) -> PackedInt32Array:
	states[index] = (states[index] + 1) % get_state_count()
	return states

## Preferred node count (0 = use substrate default).
func get_preferred_node_count() -> int:
	return 0

## Preferred step interval.
func get_preferred_interval() -> float:
	return 0.0

## Pre-compute steps.
func get_warmup_steps() -> int:
	return 0

## Whether positions change over time (force-directed) or are static.
func has_dynamic_positions() -> bool:
	return false

## Preferred bounds size.
func get_preferred_bounds() -> Vector3:
	return Vector3.ZERO
