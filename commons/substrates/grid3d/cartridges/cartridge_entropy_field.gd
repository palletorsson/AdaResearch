class_name CartridgeEntropyField
extends Grid3DCartridge

## Entropy field — order→chaos gradient. No edges. Pure point cloud.
## Nodes arranged in a grid, displaced by increasing randomness along Z.
## Color shifts from blue (ordered) through magenta to red (chaotic).
## Static — builds incrementally then done.

var _grid_x: int = 8
var _grid_y: int = 8
var _grid_z: int = 20
var _current_z: int = 0
var _spacing: float = 0.15
var _done: bool = false

func get_name() -> String:
	return "Entropy Field"

func get_state_count() -> int:
	return 1  # no state changes, just static colors

func get_node_color(state: int) -> Color:
	return Color(0.3, 0.4, 0.8)  # overridden per-node via highlights

func get_preferred_node_count() -> int:
	return _grid_x * _grid_y * _grid_z

func get_preferred_bounds() -> Vector3:
	return Vector3(_grid_x * _spacing, _grid_y * _spacing, _grid_z * _spacing)

func get_preferred_interval() -> float:
	return 0.05  # fast build

func initialize(node_count: int, bounds: Vector3) -> Dictionary:
	var total = _grid_x * _grid_y * _grid_z
	var positions = PackedVector3Array()
	positions.resize(total)
	var states = PackedInt32Array()
	states.resize(total)
	states.fill(0)

	# Place all nodes in grid positions (no displacement yet)
	var idx = 0
	for z in range(_grid_z):
		for y in range(_grid_y):
			for x in range(_grid_x):
				positions[idx] = Vector3(
					(x - _grid_x * 0.5) * _spacing,
					(y - _grid_y * 0.5) * _spacing,
					z * _spacing
				)
				idx += 1

	_current_z = 0
	_done = false

	# No edges
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
	if _done or _current_z >= _grid_z:
		_done = true
		return {"positions": positions, "states": states, "edges": null, "edge_states": edge_states,
				"highlights": {}, "edge_highlights": {}, "done": true, "description": "Entropy field complete"}

	var highlights = {}

	# Displace the current Z-layer with increasing randomness
	var entropy = float(_current_z) / float(_grid_z - 1)
	var curved = entropy * entropy  # exponential curve
	var max_displacement = 0.4

	for y in range(_grid_y):
		for x in range(_grid_x):
			var idx = _current_z * (_grid_x * _grid_y) + y * _grid_x + x
			var base_pos = Vector3(
				(x - _grid_x * 0.5) * _spacing,
				(y - _grid_y * 0.5) * _spacing,
				_current_z * _spacing
			)
			var displacement = curved * max_displacement
			positions[idx] = base_pos + Vector3(
				randf_range(-displacement, displacement),
				randf_range(-displacement, displacement),
				0.0
			)

			# Color: blue → magenta → red
			var hue = lerpf(0.66, 0.0, entropy)
			highlights[idx] = Color.from_hsv(hue, 1.0, 1.0)

	_current_z += 1

	return {
		"positions": positions, "states": states, "edges": null, "edge_states": edge_states,
		"highlights": highlights, "edge_highlights": {},
		"done": false, "description": "Layer %d/%d (entropy=%.2f)" % [_current_z, _grid_z, entropy]
	}
