extends RefCounted

var positions: Array[Vector3] = [
	Vector3(0, 2.3, 0),
	Vector3(-0.6, 1.8, 0), Vector3(0.6, 1.8, 0),
	Vector3(-0.9, 1.3, 0), Vector3(-0.3, 1.3, 0),
	Vector3(0.3, 1.3, 0), Vector3(0.9, 1.3, 0),
]
var velocities: Array[Vector3] = []
var spring := 2.0
var rest_length := 0.65
var repulsion := 0.03
var damping := 3.0

func _init() -> void:
	for unused in positions:
		velocities.append(Vector3.ZERO)

func forces(neighbours: Array) -> Array[Vector3]:
	var result: Array[Vector3] = []
	for unused in positions:
		result.append(Vector3.ZERO)
	# Every pair repels. A minimum distance limits near-contact force.
	for a in range(positions.size()):
		for b in range(a + 1, positions.size()):
			var offset := positions[b] - positions[a]
			var distance := maxf(offset.length(), 0.1)
			var push := offset.normalized() * repulsion / (distance * distance)
			result[a] -= push
			result[b] += push
	# Only listed connections act as springs; count each undirected edge once.
	for a in range(neighbours.size()):
		for b: int in neighbours[a]:
			if a < b:
				var offset := positions[b] - positions[a]
				var pull := offset.normalized() * spring * (offset.length() - rest_length)
				result[a] += pull
				result[b] -= pull
	return result

func step(delta: float, neighbours: Array, pinned: int = -1) -> void:
	# All forces read the same positions before any position is advanced.
	var current := forces(neighbours)
	for vertex in range(positions.size()):
		if vertex == pinned:
			velocities[vertex] = Vector3.ZERO
			continue
		velocities[vertex] += current[vertex] * delta
		velocities[vertex] *= exp(-damping * delta)
		velocities[vertex] = velocities[vertex].limit_length(2.0)
		positions[vertex] += velocities[vertex] * delta
